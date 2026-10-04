import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../network/api_client.dart';
import '../../network/websocket_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/server_repository.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/dm_repository.dart';
import '../../data/repositories/friends_repository.dart';
import '../../domain/services/websocket_service.dart';
import '../../domain/services/voice_service.dart';
import '../../domain/services/push_notification_service.dart';
import '../../domain/services/offline_queue_service.dart';

// Network
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider));
});

final serverRepositoryProvider = Provider<ServerRepository>((ref) {
  return ServerRepository(ref.read(apiClientProvider));
});

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final repo = MessageRepository(ref.read(apiClientProvider));
  // Wire up offline queue after creation
  Future.microtask(() {
    final queue = ref.read(offlineQueueServiceProvider);
    repo.setOfflineQueue(queue);
  });
  return repo;
});

final dmRepositoryProvider = Provider<DmRepository>((ref) {
  return DmRepository(ref.read(apiClientProvider));
});

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(ref.read(apiClientProvider));
});

// WebSocket
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService(ref.read(messageRepositoryProvider));
});

// Voice
final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService(ref.read(apiClientProvider));
});

// Push Notifications
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

// Offline Queue
final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  return OfflineQueueService(ref.read(apiClientProvider));
});
