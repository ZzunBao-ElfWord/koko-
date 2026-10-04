import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';

/// WebSocket connection state
enum WSConnectionState {
  disconnected,
  connecting,
  authenticating,
  syncing,
  live,
  reconnecting,
}

/// Bonfire WebSocket client with state machine, heartbeat, reconnect, and event dispatch.
class WebSocketClient {
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _pongTimer;
  Timer? _reconnectTimer;

  WSConnectionState _state = WSConnectionState.disconnected;
  String? _token;

  int _retryCount = 0;
  DateTime? _lastDisconnectTime;
  DateTime? _lastPongTime;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  final _stateController = StreamController<WSConnectionState>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;
  Stream<WSConnectionState> get stateChanges => _stateController.stream;
  WSConnectionState get state => _state;

  bool get isConnected => _state == WSConnectionState.live;

  void _setState(WSConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  Future<void> connect(String token) async {
    if (_state == WSConnectionState.connecting || _state == WSConnectionState.live) {
      return;
    }

    _token = token;
    _setState(WSConnectionState.connecting);

    final wsUri = Uri.parse(AppConstants.wsUrl);
    developer.log('WebSocket connecting to: $wsUri (scheme=${wsUri.scheme})', name: 'WebSocketClient');

    try {
      _channel = WebSocketChannel.connect(wsUri);
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // Wait a moment for handshake, then authenticate
      await Future.delayed(const Duration(milliseconds: 500));
      _authenticate();
    } catch (e) {
      developer.log('WebSocket connection error: $e', name: 'WebSocketClient');
      _onError(e);
    }
  }

  void _authenticate() {
    if (_channel == null || _token == null) return;
    _setState(WSConnectionState.authenticating);
    _send({'type': 'Authenticate', 'token': _token});
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _pingTimer = Timer.periodic(
      const Duration(seconds: AppConstants.wsPingIntervalSec),
      (_) => _sendPing(),
    );
  }

  void _sendPing() {
    if (_channel == null) return;
    _send({'type': 'Ping', 'data': DateTime.now().millisecondsSinceEpoch});
    _pongTimer?.cancel();
    _pongTimer = Timer(
      const Duration(seconds: AppConstants.wsPongTimeoutSec),
      () {
        // Pong timeout - connection likely dead
        _lastDisconnectTime ??= DateTime.now();
        _channel?.sink.close();
        _scheduleReconnect();
      },
    );
  }

  void _stopHeartbeat() {
    _pingTimer?.cancel();
    _pongTimer?.cancel();
    _pingTimer = null;
    _pongTimer = null;
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'Authenticated':
          _setState(WSConnectionState.syncing);
          _retryCount = 0;
          break;
        case 'Ready':
          _setState(WSConnectionState.live);
          _startHeartbeat();
          _eventController.add(data);
          break;
        case 'Pong':
          _lastPongTime = DateTime.now();
          _pongTimer?.cancel();
          break;
        case 'Error':
          // Authentication error, don't reconnect
          if (data['error'] == 'LabelMe') {
            disconnect();
            return;
          }
          break;
        default:
          // Forward all other events
          _eventController.add(data);
          break;
      }
    } catch (e) {
      // Ignore malformed messages
    }
  }

  void _onError(dynamic error) {
    _lastDisconnectTime ??= DateTime.now();
    _setState(WSConnectionState.disconnected);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _onDone() {
    _lastDisconnectTime ??= DateTime.now();
    _setState(WSConnectionState.disconnected);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_retryCount >= AppConstants.maxRetryAttempts) {
      return;
    }

    _reconnectTimer?.cancel();
    final delay = min(
      AppConstants.initialRetryDelayMs * pow(2, _retryCount),
      AppConstants.maxRetryDelayMs,
    );
    _retryCount++;

    _reconnectTimer = Timer(Duration(milliseconds: delay.toInt()), () {
      if (_token != null) {
        connect(_token!);
      }
    });
  }

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      // Channel closed
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _channel?.sink.close();
    _channel = null;
    _token = null;
    _retryCount = 0;
    _setState(WSConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _stateController.close();
  }

  /// Get the timestamp of last disconnect for event compensation
  DateTime? get lastDisconnectTime => _lastDisconnectTime;

  void clearDisconnectTime() {
    _lastDisconnectTime = null;
  }
}
