import 'dart:typed_data';
import '../../network/api_client.dart';
import '../local/database.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../../domain/services/offline_queue_service.dart';

class MessageRepository {
  final ApiClient _api;
  OfflineQueueService? _offlineQueue;

  MessageRepository(this._api);

  void setOfflineQueue(OfflineQueueService queue) {
    _offlineQueue = queue;
  }

  Future<List<Message>> fetchMessages(String channelId, {String? before, String? after, int limit = 50}) async {
    final raw = await _api.fetchMessages(channelId, before: before, after: after, limit: limit);
    final messages = raw.map((m) => Message.fromJson(m as Map<String, dynamic>)).toList();
    await LocalDatabase.insertMessages(messages);
    return messages;
  }

  Future<List<Message>> getCachedMessages(String channelId) async {
    return LocalDatabase.getMessages(channelId);
  }

  Future<Message> sendMessage(String channelId, String content, {
    List<String>? replies,
    List<Attachment>? attachments,
  }) async {
    final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    final pending = Message(
      id: tempId,
      channel: channelId,
      author: 'me',
      content: content,
      replies: replies,
      attachments: attachments,
      isPending: true,
    );
    await LocalDatabase.insertMessage(pending);

    try {
      final attachmentPayload = attachments?.map((a) => {
        'id': a.id,
        'filename': a.filename,
        'content_type': a.contentType,
        'size': a.size,
      }).toList();

      final data = await _api.sendMessage(channelId, {
        'content': content,
        if (replies != null && replies.isNotEmpty) 'replies': replies.map((id) => {'_id': id, 'mention': false}).toList(),
        if (attachmentPayload != null && attachmentPayload.isNotEmpty) 'attachments': attachmentPayload,
      });
      final message = Message.fromJson(data);
      await LocalDatabase.deleteMessage(tempId);
      await LocalDatabase.insertMessage(message);
      return message;
    } catch (e) {
      await LocalDatabase.updateMessageFailed(tempId, true);
      // If network error, enqueue to offline queue
      if (_offlineQueue != null && !_offlineQueue!.hasNetwork) {
        await _offlineQueue!.enqueue(
          channelId: channelId,
          content: content,
          attachments: attachments,
          replyIds: replies,
        );
      }
      rethrow;
    }
  }

  Future<void> editMessage(String channelId, String messageId, String content) async {
    await _api.editMessage(channelId, messageId, {'content': content});
  }

  Future<void> deleteMessage(String channelId, String messageId) async {
    await _api.deleteMessage(channelId, messageId);
    await LocalDatabase.deleteMessage(messageId);
  }

  Future<void> ackChannel(String channelId, String messageId) async {
    await _api.ackChannel(channelId, messageId);
  }

  Future<void> retryFailedMessage(String tempId, String channelId, String content) async {
    await sendMessage(channelId, content);
    await LocalDatabase.deleteMessage(tempId);
  }

  // ========== SEARCH ==========

  Future<List<Message>> searchMessages(String channelId, {required String query, int limit = 50}) async {
    final raw = await _api.searchMessages(channelId, query: query, limit: limit);
    return raw.map((m) => Message.fromJson(m as Map<String, dynamic>)).toList();
  }

  // ========== REACTIONS ==========

  Future<void> addReaction(String channelId, String messageId, String emoji) async {
    await _api.addReaction(channelId, messageId, emoji);
  }

  Future<void> removeReaction(String channelId, String messageId, String emoji) async {
    await _api.removeReaction(channelId, messageId, emoji);
  }

  // ========== ATTACHMENTS ==========

  Future<Attachment> uploadAttachment(String filename, Uint8List bytes, {String? contentType, void Function(int, int)? onSendProgress}) async {
    return _api.uploadAttachment(filename, bytes, contentType: contentType, onSendProgress: onSendProgress);
  }
}
