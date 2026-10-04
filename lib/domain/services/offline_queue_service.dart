import 'dart:async';
import 'dart:typed_data';
import '../../data/local/database.dart';
import '../../data/models/message.dart';
import '../../data/models/attachment.dart';
import '../../network/api_client.dart';

/// Service that manages the offline message queue.
/// When network is unavailable, messages are stored locally and retried later.
class OfflineQueueService {
  final ApiClient _api;
  final _queueController = StreamController<QueueEvent>.broadcast();
  Timer? _retryTimer;
  bool _isProcessing = false;
  bool _hasNetwork = true;

  Stream<QueueEvent> get events => _queueController.stream;
  bool get hasNetwork => _hasNetwork;

  OfflineQueueService(this._api);

  void setNetworkAvailable(bool available) {
    final wasOffline = !_hasNetwork;
    _hasNetwork = available;
    if (available && wasOffline) {
      // Network restored - trigger retry
      _scheduleRetry(immediate: true);
    }
  }

  /// Enqueue a message for sending when network is available.
  Future<String> enqueue({
    required String channelId,
    String? content,
    List<Attachment>? attachments,
    List<String>? replyIds,
  }) async {
    final id = 'pending_${DateTime.now().millisecondsSinceEpoch}_${_randomSuffix()}';
    await LocalDatabase.insertPendingMessage(
      id: id,
      channelId: channelId,
      content: content,
      attachments: attachments,
      replyIds: replyIds,
    );
    _queueController.add(QueueEvent.enqueued(id));

    // If online, try to send immediately
    if (_hasNetwork) {
      _scheduleRetry(immediate: true);
    }

    return id;
  }

  /// Remove a pending message from the queue.
  Future<void> dequeue(String id) async {
    await LocalDatabase.removePendingMessage(id);
    _queueController.add(QueueEvent.removed(id));
  }

  /// Retry a specific pending message.
  Future<void> retryMessage(String id) async {
    final pending = await LocalDatabase.getAllPendingMessages();
    final item = pending.firstWhere((m) => m['id'] == id, orElse: () => <String, dynamic>{});
    if (item.isEmpty) return;
    await _sendPendingMessage(item);
  }

  /// Process all pending messages.
  Future<void> processQueue() async {
    if (_isProcessing || !_hasNetwork) return;
    _isProcessing = true;

    try {
      final pending = await LocalDatabase.getAllPendingMessages();
      for (final item in pending) {
        if (!_hasNetwork) break;
        await _sendPendingMessage(item);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _sendPendingMessage(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final channelId = item['channel_id'] as String;
    final content = item['content'] as String?;
    final retryCount = (item['retry_count'] as int?) ?? 0;

    if (retryCount >= 3) {
      _queueController.add(QueueEvent.maxRetries(id));
      return;
    }

    // Mark as sending
    await LocalDatabase.updatePendingMessageSending(id, true);
    _queueController.add(QueueEvent.sending(id));

    try {
      // Parse attachments
      List<Map<String, dynamic>>? attachmentPayload;
      final attachmentData = item['attachment_data'] as String?;
      if (attachmentData != null && attachmentData.isNotEmpty) {
        attachmentPayload = attachmentData.split(';;').map((part) {
          final parts = part.split('|');
          return {
            'id': parts[0],
            'filename': parts.length > 1 ? parts[1] : 'file',
            'content_type': parts.length > 2 ? parts[2] : null,
            'size': parts.length > 3 ? int.tryParse(parts[3]) : null,
          };
        }).toList();
      }

      // Parse reply IDs
      final replyIdsData = item['reply_ids'] as String?;
      final replyIds = replyIdsData?.split(',').where((s) => s.isNotEmpty).toList();

      await _api.sendMessage(channelId, {
        'content': content ?? '',
        if (replyIds != null && replyIds.isNotEmpty)
          'replies': replyIds.map((id) => {'_id': id, 'mention': false}).toList(),
        if (attachmentPayload != null && attachmentPayload.isNotEmpty)
          'attachments': attachmentPayload,
      });

      // Success - remove from queue
      await LocalDatabase.removePendingMessage(id);
      _queueController.add(QueueEvent.sent(id));
    } catch (e) {
      await LocalDatabase.updatePendingMessageSending(id, false);
      await LocalDatabase.incrementPendingRetry(id);
      _queueController.add(QueueEvent.failed(id, retryCount + 1));
    }
  }

  void _scheduleRetry({bool immediate = false}) {
    _retryTimer?.cancel();
    _retryTimer = Timer(
      immediate ? Duration.zero : const Duration(seconds: 5),
      processQueue,
    );
  }

  String _randomSuffix() {
    return '${DateTime.now().microsecond % 10000}';
  }

  void dispose() {
    _retryTimer?.cancel();
    _queueController.close();
  }
}

/// Events emitted by the offline queue.
sealed class QueueEvent {
  final String messageId;

  const QueueEvent(this.messageId);

  factory QueueEvent.enqueued(String id) = EnqueuedEvent;
  factory QueueEvent.sending(String id) = SendingEvent;
  factory QueueEvent.sent(String id) = SentEvent;
  factory QueueEvent.failed(String id, int retryCount) = FailedEvent;
  factory QueueEvent.maxRetries(String id) = MaxRetriesEvent;
  factory QueueEvent.removed(String id) = RemovedEvent;
}

class EnqueuedEvent extends QueueEvent {
  const EnqueuedEvent(super.messageId);
}

class SendingEvent extends QueueEvent {
  const SendingEvent(super.messageId);
}

class SentEvent extends QueueEvent {
  const SentEvent(super.messageId);
}

class FailedEvent extends QueueEvent {
  final int retryCount;
  const FailedEvent(super.messageId, this.retryCount);
}

class MaxRetriesEvent extends QueueEvent {
  const MaxRetriesEvent(super.messageId);
}

class RemovedEvent extends QueueEvent {
  const RemovedEvent(super.messageId);
}
