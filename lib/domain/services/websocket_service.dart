import 'dart:async';
import '../../network/websocket_client.dart';
import '../../data/local/database.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/models/message.dart';
import '../../data/models/user.dart';
import '../../data/models/server.dart';
import '../../data/models/channel.dart';
import '../../data/models/reaction.dart';

/// High-level WebSocket service that handles event parsing,
/// local cache updates, and event compensation.
class WebSocketService {
  final WebSocketClient _client = WebSocketClient();
  final MessageRepository _messageRepo;

  StreamSubscription? _eventSub;
  final _messageController = StreamController<Message>.broadcast();
  final _userController = StreamController<User>.broadcast();
  final _serverController = StreamController<Server>.broadcast();
  final _channelController = StreamController<Channel>.broadcast();
  final _unreadController = StreamController<Map<String, dynamic>>.broadcast();
  final _reactionController = StreamController<ReactionEvent>.broadcast();
  final _messageUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeleteController = StreamController<String>.broadcast();
  final _relationshipController = StreamController<RelationshipEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<Message> get newMessages => _messageController.stream;
  Stream<User> get userUpdates => _userController.stream;
  Stream<Server> get serverUpdates => _serverController.stream;
  Stream<Channel> get channelUpdates => _channelController.stream;
  Stream<Map<String, dynamic>> get unreadUpdates => _unreadController.stream;
  Stream<ReactionEvent> get reactionUpdates => _reactionController.stream;
  Stream<Map<String, dynamic>> get messageUpdates => _messageUpdateController.stream;
  Stream<String> get messageDeletes => _messageDeleteController.stream;
  Stream<RelationshipEvent> get relationshipUpdates => _relationshipController.stream;
  Stream<bool> get connectionChanges => _connectionController.stream;

  bool get isConnected => _client.isConnected;

  WebSocketService(this._messageRepo);

  Future<void> connect(String token) async {
    await _client.connect(token);
    _eventSub?.cancel();
    _eventSub = _client.events.listen(_handleEvent);

    // After connection, check if we need event compensation
    _client.stateChanges.listen((state) async {
      if (state == WSConnectionState.live) {
        _connectionController.add(true);
        final disconnectTime = _client.lastDisconnectTime;
        if (disconnectTime != null) {
          await _compensateEvents(disconnectTime);
          _client.clearDisconnectTime();
        }
      } else if (state == WSConnectionState.disconnected) {
        _connectionController.add(false);
      }
    });
  }

  void disconnect() {
    _eventSub?.cancel();
    _client.disconnect();
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;

    switch (type) {
      case 'Ready':
        _handleReady(event);
        break;
      case 'Message':
        _handleMessageEvent(event);
        break;
      case 'MessageUpdate':
        _handleMessageUpdate(event);
        break;
      case 'MessageDelete':
        _handleMessageDelete(event);
        break;
      case 'MessageReact':
        _handleMessageReact(event);
        break;
      case 'MessageUnreact':
        _handleMessageUnreact(event);
        break;
      case 'UserUpdate':
        _handleUserUpdate(event);
        break;
      case 'UserRelationship':
        _handleUserRelationship(event);
        break;
      case 'ServerUpdate':
        _handleServerUpdate(event);
        break;
      case 'ChannelCreate':
      case 'ChannelUpdate':
        _handleChannelUpdate(event);
        break;
      case 'ChannelDelete':
        _handleChannelDelete(event);
        break;
      case 'ChannelAck':
        _handleChannelAck(event);
        break;
      case 'ServerMemberJoin':
      case 'ServerMemberLeave':
      case 'ServerRoleUpdate':
        // Handle as needed
        break;
      default:
        break;
    }
  }

  void _handleReady(Map<String, dynamic> event) {
    try {
      // Populate users cache from Ready event
      final users = event['users'] as List<dynamic>?;
      if (users != null && users.isNotEmpty) {
        final userList = users.map((u) => User.fromJson(u as Map<String, dynamic>)).toList();
        LocalDatabase.insertUsers(userList);
        for (final user in userList) {
          _userController.add(user);
        }
      }

      // Populate servers cache
      final servers = event['servers'] as List<dynamic>?;
      if (servers != null && servers.isNotEmpty) {
        final serverList = servers.map((s) => Server.fromJson(s as Map<String, dynamic>)).toList();
        LocalDatabase.insertServers(serverList);
        for (final server in serverList) {
          _serverController.add(server);
        }
      }

      // Populate channels cache
      final channels = event['channels'] as List<dynamic>?;
      if (channels != null && channels.isNotEmpty) {
        final channelList = channels.map((c) => Channel.fromJson(c as Map<String, dynamic>)).toList();
        LocalDatabase.insertChannels(channelList);
        for (final channel in channelList) {
          _channelController.add(channel);
        }
      }
    } catch (_) {
      // Best-effort cache population
    }
  }

  void _handleMessageEvent(Map<String, dynamic> event) {
    try {
      final message = Message.fromJson(event);
      LocalDatabase.insertMessage(message);
      _messageController.add(message);
    } catch (_) {}
  }

  void _handleMessageUpdate(Map<String, dynamic> event) {
    try {
      final id = event['id'] as String?;
      final data = event['data'] as Map<String, dynamic>?;
      if (id != null && data != null) {
        if (data.containsKey('content')) {
          LocalDatabase.updateMessageContent(id, data['content'] as String);
        }
        if (data.containsKey('edited')) {
          LocalDatabase.updateMessageEdited(id, data['edited'] as String?);
        }
        _messageUpdateController.add({
          'id': id,
          'content': data['content'],
          'edited': data['edited'],
        });
      }
    } catch (_) {}
  }

  void _handleMessageDelete(Map<String, dynamic> event) {
    try {
      final id = event['id'] as String?;
      if (id != null) {
        LocalDatabase.deleteMessage(id);
        _messageDeleteController.add(id);
      }
    } catch (_) {}
  }

  void _handleMessageReact(Map<String, dynamic> event) {
    try {
      final id = event['id'] as String?;
      final channelId = event['channel_id'] as String?;
      final userId = event['user_id'] as String?;
      final emoji = event['emoji_id'] as String? ?? event['emoji'] as String?;
      if (id != null && channelId != null && userId != null && emoji != null) {
        LocalDatabase.addReactionToMessage(id, emoji, userId);
        _reactionController.add(ReactionEvent(
          messageId: id,
          channelId: channelId,
          emoji: emoji,
          userId: userId,
          isAdd: true,
        ));
      }
    } catch (_) {}
  }

  void _handleMessageUnreact(Map<String, dynamic> event) {
    try {
      final id = event['id'] as String?;
      final channelId = event['channel_id'] as String?;
      final userId = event['user_id'] as String?;
      final emoji = event['emoji_id'] as String? ?? event['emoji'] as String?;
      if (id != null && channelId != null && userId != null && emoji != null) {
        LocalDatabase.removeReactionFromMessage(id, emoji, userId);
        _reactionController.add(ReactionEvent(
          messageId: id,
          channelId: channelId,
          emoji: emoji,
          userId: userId,
          isAdd: false,
        ));
      }
    } catch (_) {}
  }

  void _handleUserUpdate(Map<String, dynamic> event) {
    try {
      final id = event['id'] as String?;
      final data = event['data'] as Map<String, dynamic>?;
      if (id != null && data != null) {
        final user = User.fromJson({'id': id, ...data});
        LocalDatabase.insertUser(user);
        _userController.add(user);
      }
    } catch (_) {}
  }

  void _handleUserRelationship(Map<String, dynamic> event) {
    try {
      final id = event['id'] as String?;
      final user = event['user'] as Map<String, dynamic>?;
      final status = event['status'] as String?;
      if (id != null) {
        // Update local cache
        if (user != null) {
          final userModel = User.fromJson({...user, 'relationship': status});
          LocalDatabase.insertUser(userModel);
          _userController.add(userModel);
        } else {
          LocalDatabase.updateUserRelationship(id, status ?? 'None');
        }
        _relationshipController.add(RelationshipEvent(
          userId: id,
          status: status ?? 'None',
        ));
      }
    } catch (_) {}
  }

  void _handleServerUpdate(Map<String, dynamic> event) {
    try {
      final id = event['id'] as String?;
      final data = event['data'] as Map<String, dynamic>?;
      if (id != null && data != null) {
        final server = Server.fromJson({'id': id, ...data});
        LocalDatabase.insertServer(server);
        _serverController.add(server);
      }
    } catch (_) {}
  }

  void _handleChannelUpdate(Map<String, dynamic> event) {
    try {
      final channel = Channel.fromJson(event);
      LocalDatabase.insertChannel(channel);
      _channelController.add(channel);
    } catch (_) {}
  }

  void _handleChannelDelete(Map<String, dynamic> event) {
    // Notified but local cache handles gracefully
  }

  void _handleChannelAck(Map<String, dynamic> event) {
    try {
      _unreadController.add(event);
    } catch (_) {}
  }

  /// Event compensation: fetch missing messages after reconnection.
  Future<void> _compensateEvents(DateTime since) async {
    final channels = await LocalDatabase.getChannels();
    for (final channel in channels) {
      try {
        final localMessages = await LocalDatabase.getMessages(channel.id, limit: 1);
        final lastKnownId = localMessages.isNotEmpty ? localMessages.last.id : null;

        if (lastKnownId != null) {
          final messages = await _messageRepo.fetchMessages(
            channel.id,
            after: lastKnownId,
            limit: 100,
          );

          if (messages.isNotEmpty) {
            await LocalDatabase.insertMessages(messages);
            for (final msg in messages) {
              _messageController.add(msg);
            }
          }
        }
      } catch (_) {
        // Compensation best-effort
      }
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _userController.close();
    _serverController.close();
    _channelController.close();
    _unreadController.close();
    _reactionController.close();
    _messageUpdateController.close();
    _messageDeleteController.close();
    _relationshipController.close();
    _connectionController.close();
  }
}

class ReactionEvent {
  final String messageId;
  final String channelId;
  final String emoji;
  final String userId;
  final bool isAdd;

  ReactionEvent({
    required this.messageId,
    required this.channelId,
    required this.emoji,
    required this.userId,
    required this.isAdd,
  });
}

class RelationshipEvent {
  final String userId;
  final String status;

  RelationshipEvent({
    required this.userId,
    required this.status,
  });
}
