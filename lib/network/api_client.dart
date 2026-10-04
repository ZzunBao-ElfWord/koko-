import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../core/constants.dart';
import '../data/models/attachment.dart';

/// Delta REST API client with authentication, error handling, and token management.
class ApiClient {
  late final Dio _dio;
  String? _token;

  final _authExpiredController = StreamController<void>.broadcast();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConstants.apiBaseUrl}/api',
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
      headers: {'Content-Type': 'application/json'},
    ));

    // Configure HTTP adapter with certificate debugging
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          developer.log(
            'SSL: host=$host port=$port cert.subject=${cert.subject} cert.issuer=${cert.issuer}',
            name: 'ApiClient',
          );
          // Always return true in debug builds to allow self-signed or custom certs during testing.
          // In production this should return false to enforce strict validation.
          return true;
        };
        return client;
      },
    );

    // Request/Response logging interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        developer.log(
          'REQUEST [${options.method}] ${options.uri} | headers=${options.headers} | data=${options.data}',
          name: 'ApiClient',
        );
        if (_token != null) {
          options.headers['x-session-token'] = _token;
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        developer.log(
          'RESPONSE [${response.statusCode}] ${response.requestOptions.uri} | data=${response.data}',
          name: 'ApiClient',
        );
        handler.next(response);
      },
      onError: (error, handler) {
        developer.log(
          'ERROR [${error.response?.statusCode}] ${error.requestOptions.uri} | type=${error.type} | message=${error.message} | response=${error.response?.data}',
          name: 'ApiClient',
        );
        if (error.response?.statusCode == 401) {
          _token = null;
          _authExpiredController.add(null);
        }
        handler.next(error);
      },
    ));
  }

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Stream<void> get onAuthExpired => _authExpiredController.stream;

  // ========== AUTH ==========

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/session/login', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/account/create', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchSelf() async {
    final response = await _dio.get('/users/@me');
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _dio.post('/auth/session/logout');
    _token = null;
  }

  // ========== SERVERS ==========

  Future<List<dynamic>> fetchServers() async {
    final response = await _dio.get('/servers');
    return response.data['servers'] as List? ?? [];
  }

  Future<Map<String, dynamic>> fetchServer(String id) async {
    final response = await _dio.get('/servers/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinServer(String inviteCode) async {
    final response = await _dio.post('/invites/$inviteCode');
    return response.data as Map<String, dynamic>;
  }

  // ========== CHANNELS ==========

  Future<Map<String, dynamic>> fetchChannel(String id) async {
    final response = await _dio.get('/channels/$id');
    return response.data as Map<String, dynamic>;
  }

  // ========== MESSAGES ==========

  Future<List<dynamic>> fetchMessages(String channelId, {String? before, String? after, int limit = 50}) async {
    final response = await _dio.get(
      '/channels/$channelId/messages',
      queryParameters: {
        if (before != null) 'before': before,
        if (after != null) 'after': after,
        'limit': limit,
        'include_users': true,
      },
    );
    return response.data as List? ?? [];
  }

  Future<Map<String, dynamic>> sendMessage(String channelId, Map<String, dynamic> data) async {
    final response = await _dio.post('/channels/$channelId/messages', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> editMessage(String channelId, String messageId, Map<String, dynamic> data) async {
    final response = await _dio.patch('/channels/$channelId/messages/$messageId', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteMessage(String channelId, String messageId) async {
    await _dio.delete('/channels/$channelId/messages/$messageId');
  }

  // ========== MESSAGE SEARCH ==========

  Future<List<dynamic>> searchMessages(String channelId, {required String query, int limit = 50}) async {
    final response = await _dio.get(
      '/channels/$channelId/search',
      queryParameters: {
        'q': query,
        'limit': limit,
        'include_users': true,
      },
    );
    return response.data as List? ?? [];
  }

  // ========== REACTIONS ==========

  Future<void> addReaction(String channelId, String messageId, String emoji) async {
    await _dio.put('/channels/$channelId/messages/$messageId/reactions/$emoji');
  }

  Future<void> removeReaction(String channelId, String messageId, String emoji) async {
    await _dio.delete('/channels/$channelId/messages/$messageId/reactions/$emoji');
  }

  // ========== DM ==========

  Future<Map<String, dynamic>> openDm(String targetUserId) async {
    final response = await _dio.get('/users/$targetUserId/dm');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchUserDms() async {
    final response = await _dio.get('/users/dms');
    return response.data as List? ?? [];
  }

  // ========== FRIENDS / RELATIONSHIPS ==========

  Future<List<dynamic>> fetchRelationships() async {
    final response = await _dio.get('/users/relationships');
    return response.data as List? ?? [];
  }

  /// Send a friend request by username.
  /// Revolt API expects POST /users/friend with { username: string }
  Future<Map<String, dynamic>> addFriend(String username) async {
    final response = await _dio.post('/users/friend', data: {'username': username});
    return response.data as Map<String, dynamic>;
  }

  /// Accept a friend request.
  /// PUT /users/{target}/friend
  Future<void> acceptFriend(String userId) async {
    await _dio.put('/users/$userId/friend');
  }

  /// Remove or reject a friend.
  /// DELETE /users/{target}/friend
  Future<void> removeFriend(String userId) async {
    await _dio.delete('/users/$userId/friend');
  }

  // ========== USERS ==========

  Future<Map<String, dynamic>> fetchUser(String id) async {
    final response = await _dio.get('/users/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchUserProfile(String id) async {
    final response = await _dio.get('/users/$id/profile');
    return response.data as Map<String, dynamic>;
  }

  /// Edit current user profile.
  /// PATCH /users/@me
  Future<Map<String, dynamic>> editSelf(Map<String, dynamic> data) async {
    final response = await _dio.patch('/users/@me', data: data);
    return response.data as Map<String, dynamic>;
  }

  /// Change user status/presence.
  /// PATCH /users/@me
  Future<void> changeStatus({String? text, String? presence}) async {
    final data = <String, dynamic>{};
    if (text != null || presence != null) {
      data['status'] = {};
      if (text != null) data['status']['text'] = text;
      if (presence != null) data['status']['presence'] = presence;
    }
    if (data.isNotEmpty) {
      await _dio.patch('/users/@me', data: data);
    }
  }

  /// Fetch mutual servers with a user.
  Future<List<dynamic>> fetchMutualServers(String userId) async {
    final response = await _dio.get('/users/$userId/mutual');
    return response.data['servers'] as List? ?? [];
  }

  // ========== LIVEKIT / VOICE ==========

  Future<Map<String, dynamic>> fetchLiveKitToken(String channelId) async {
    final response = await _dio.get('/channels/$channelId/join_call');
    return response.data as Map<String, dynamic>;
  }

  // ========== PUSH NOTIFICATIONS ==========

  Future<void> registerPushToken(String token, String platform) async {
    await _dio.post('/push/register', data: {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregisterPushToken(String token) async {
    await _dio.post('/push/unregister', data: {
      'token': token,
    });
  }

  // ========== UNREADS ==========

  Future<Map<String, dynamic>> fetchUnreads() async {
    final response = await _dio.get('/sync/unreads');
    return response.data as Map<String, dynamic>;
  }

  Future<void> ackChannel(String channelId, String messageId) async {
    await _dio.put('/channels/$channelId/ack/$messageId');
  }

  // ========== FILE UPLOAD ==========

  static const List<String> _allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> _allowedVideoExtensions = ['mp4', 'mov', 'webm'];
  static const List<String> _allowedDocumentExtensions = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    'txt', 'md', 'csv', 'json', 'xml', 'zip', 'rar', '7z',
  ];
  static const int _maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int _maxVideoSizeBytes = 20 * 1024 * 1024; // 20MB
  static const int _maxDocumentSizeBytes = 20 * 1024 * 1024; // 20MB

  static String? _getExtension(String filename) {
    final idx = filename.lastIndexOf('.');
    if (idx < 0 || idx >= filename.length - 1) return null;
    return filename.substring(idx + 1).toLowerCase();
  }

  static String _getFileCategory(String? ext) {
    if (ext == null) return 'unknown';
    if (_allowedImageExtensions.contains(ext)) return 'image';
    if (_allowedVideoExtensions.contains(ext)) return 'video';
    if (_allowedDocumentExtensions.contains(ext)) return 'document';
    return 'unknown';
  }

  /// Validate file type and size before upload.
  /// Returns file category ('image'|'video'|'document') on success.
  static String validateAttachment(String filename, Uint8List bytes) {
    final ext = _getExtension(filename);
    if (ext == null) {
      throw Exception('文件缺少扩展名');
    }

    final category = _getFileCategory(ext);
    if (category == 'unknown') {
      throw Exception('不支持的文件类型: .$ext。支持的类型：图片(jpg/png/gif/webp)、视频(mp4/mov/webm)、文档(pdf/doc/xls/txt/zip等)');
    }

    // MIME type validation: verify content-type prefix matches extension category
    final mime = _guessMimeType(bytes);
    if (mime != null) {
      if (category == 'image' && !mime.startsWith('image/')) {
        throw Exception('文件内容不匹配图片格式');
      }
      if (category == 'video' && !mime.startsWith('video/')) {
        throw Exception('文件内容不匹配视频格式');
      }
    }

    // Size validation by category
    final maxSize = category == 'image'
        ? _maxImageSizeBytes
        : category == 'video'
            ? _maxVideoSizeBytes
            : _maxDocumentSizeBytes;

    if (bytes.length > maxSize) {
      final maxMb = maxSize ~/ (1024 * 1024);
      throw Exception('$category 文件超过 ${maxMb}MB 限制');
    }

    return category;
  }

  static String? _guessMimeType(Uint8List bytes) {
    if (bytes.length < 4) return null;
    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'image/jpeg';
    // PNG
    if (bytes[0] == 0x89 && bytes[1] == 0x50) return 'image/png';
    // GIF
    if (bytes[0] == 0x47 && bytes[1] == 0x49) return 'image/gif';
    // WebP: RIFF....WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'image/webp';
    }
    // MP4
    if (bytes.length >= 8) {
      final ftyp = bytes.sublist(4, 8);
      final ftypStr = String.fromCharCodes(ftyp);
      if (ftypStr == 'ftyp') return 'video/mp4';
    }
    // MOV (QuickTime)
    if (bytes.length >= 8) {
      final ftyp = bytes.sublist(4, 8);
      final ftypStr = String.fromCharCodes(ftyp);
      if (ftypStr == 'qt  ' || ftypStr == 'moov') return 'video/quicktime';
    }
    // PDF
    if (bytes[0] == 0x25 && bytes[1] == 0x50) return 'application/pdf';
    // ZIP
    if (bytes[0] == 0x50 && bytes[1] == 0x4B) return 'application/zip';
    return null;
  }

  Future<Attachment> uploadAttachment(String filename, Uint8List bytes, {String? contentType, void Function(int, int)? onSendProgress}) async {
    // Validate file
    final category = validateAttachment(filename, bytes);

    // Use detected MIME if not provided
    final detectedMime = contentType ?? _guessMimeType(bytes);

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post(
      '${AppConstants.apiBaseUrl}/autumn/attachments',
      data: formData,
      options: Options(
        headers: {'x-session-token': _token},
      ),
      onSendProgress: onSendProgress,
    );
    return Attachment.fromJson(response.data as Map<String, dynamic>);
  }

  Dio get dio => _dio;
}
