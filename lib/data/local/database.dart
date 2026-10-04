import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message.dart';
import '../models/server.dart';
import '../models/channel.dart';
import '../models/user.dart';
import '../models/attachment.dart';
import '../models/reaction.dart';

/// SQLite local cache for messages, servers, channels, users, and offline queue.
class LocalDatabase {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'stoat_cache.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE messages ADD COLUMN reactions TEXT');
          await db.execute('ALTER TABLE messages ADD COLUMN attachment_data TEXT');
        }
        if (oldVersion < 3) {
          // Phase 3: Enhanced pending messages + user fields
          await db.execute('ALTER TABLE pending_messages ADD COLUMN retry_count INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE pending_messages ADD COLUMN is_sending INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE pending_messages ADD COLUMN attachment_data TEXT');
          await db.execute('ALTER TABLE pending_messages ADD COLUMN reply_ids TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN presence TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN relationship TEXT');
        }
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        channel_id TEXT NOT NULL,
        author_id TEXT NOT NULL,
        content TEXT,
        created_at INTEGER NOT NULL,
        edited_at INTEGER,
        reply_ids TEXT,
        attachment_ids TEXT,
        attachment_data TEXT,
        embeds TEXT,
        reactions TEXT,
        is_pending INTEGER DEFAULT 0,
        is_failed INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_msg_channel ON messages(channel_id, created_at DESC)');
    await db.execute('CREATE INDEX idx_msg_author ON messages(author_id)');

    await db.execute('''
      CREATE TABLE channels (
        id TEXT PRIMARY KEY,
        server_id TEXT,
        name TEXT NOT NULL,
        channel_type TEXT NOT NULL,
        last_message_id TEXT,
        unread_count INTEGER DEFAULT 0,
        mention_count INTEGER DEFAULT 0,
        updated_at INTEGER
      )
    ''');
    await db.execute('CREATE INDEX idx_channel_server ON channels(server_id)');

    await db.execute('''
      CREATE TABLE servers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        owner_id TEXT NOT NULL,
        icon_id TEXT,
        banner_id TEXT,
        description TEXT,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        display_name TEXT,
        avatar_id TEXT,
        status TEXT,
        presence TEXT,
        relationship TEXT,
        updated_at INTEGER
      )
    ''');
    await db.execute('CREATE INDEX idx_user_username ON users(username)');

    await db.execute('''
      CREATE TABLE pending_messages (
        id TEXT PRIMARY KEY,
        channel_id TEXT NOT NULL,
        content TEXT,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        is_sending INTEGER DEFAULT 0,
        attachment_data TEXT,
        reply_ids TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_pending_channel ON pending_messages(channel_id, created_at ASC)');
  }

  // ========== MESSAGES ==========

  static Future<void> insertMessage(Message message) async {
    final db = await database;
    await db.insert(
      'messages',
      _messageToMap(message),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> insertMessages(List<Message> messages) async {
    final db = await database;
    final batch = db.batch();
    for (final message in messages) {
      batch.insert('messages', _messageToMap(message), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Map<String, dynamic> _messageToMap(Message message) {
    return {
      'id': message.id,
      'channel_id': message.channel,
      'author_id': message.author,
      'content': message.content,
      'created_at': message.createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'edited_at': message.edited != null ? DateTime.parse(message.edited!).millisecondsSinceEpoch : null,
      'reply_ids': message.replies?.join(','),
      'attachment_ids': message.attachments?.map((a) => a.id).join(','),
      'attachment_data': message.attachments != null && message.attachments!.isNotEmpty
          ? message.attachments!.map((a) => '${a.id}|${a.filename}|${a.contentType ?? ''}|${a.size ?? 0}').join(';;')
          : null,
      'embeds': null,
      'reactions': message.reactions?.entries.map((e) => '${e.key}:${e.value.userIds.join('|')}').join(';;'),
      'is_pending': message.isPending ? 1 : 0,
      'is_failed': message.isFailed ? 1 : 0,
    };
  }

  static Future<List<Message>> getMessages(String channelId, {int limit = 50, String? before}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    if (before != null) {
      final beforeTime = Message(id: before, channel: '', author: '').createdAt?.millisecondsSinceEpoch ?? 0;
      maps = await db.query(
        'messages',
        where: 'channel_id = ? AND created_at < ?',
        whereArgs: [channelId, beforeTime],
        orderBy: 'created_at DESC',
        limit: limit,
      );
    } else {
      maps = await db.query(
        'messages',
        where: 'channel_id = ?',
        whereArgs: [channelId],
        orderBy: 'created_at DESC',
        limit: limit,
      );
    }
    return maps.map((m) => _mapToMessage(m)).toList().reversed.toList();
  }

  static Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [messageId]);
  }

  static Future<void> updateMessageContent(String messageId, String content) async {
    final db = await database;
    await db.update('messages', {'content': content}, where: 'id = ?', whereArgs: [messageId]);
  }

  static Future<void> updateMessageEdited(String messageId, String? edited) async {
    final db = await database;
    await db.update('messages', {
      'edited_at': edited != null ? DateTime.parse(edited).millisecondsSinceEpoch : null,
    }, where: 'id = ?', whereArgs: [messageId]);
  }

  static Future<void> updateMessageFailed(String messageId, bool failed) async {
    final db = await database;
    await db.update('messages', {'is_failed': failed ? 1 : 0}, where: 'id = ?', whereArgs: [messageId]);
  }

  static Future<void> clearChannelMessages(String channelId) async {
    final db = await database;
    await db.delete('messages', where: 'channel_id = ?', whereArgs: [channelId]);
  }

  static Future<void> pruneOldMessages(int days) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    await db.delete('messages', where: 'created_at < ?', whereArgs: [cutoff]);
  }

  static Future<int> getMessageCount(String channelId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE channel_id = ?',
      [channelId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  static Message _mapToMessage(Map<String, dynamic> m) {
    List<Attachment>? attachments;
    final attachmentData = m['attachment_data'] as String?;
    if (attachmentData != null && attachmentData.isNotEmpty) {
      attachments = attachmentData.split(';;').map((part) {
        final parts = part.split('|');
        return Attachment(
          id: parts.isNotEmpty ? parts[0] : '',
          filename: parts.length > 1 ? parts[1] : 'file',
          contentType: parts.length > 2 ? (parts[2].isEmpty ? null : parts[2]) : null,
          size: parts.length > 3 ? int.tryParse(parts[3]) : null,
        );
      }).toList();
    }

    Map<String, Reaction>? reactions;
    final reactionsData = m['reactions'] as String?;
    if (reactionsData != null && reactionsData.isNotEmpty) {
      reactions = {};
      for (final part in reactionsData.split(';;')) {
        final colonIdx = part.indexOf(':');
        if (colonIdx > 0) {
          final emoji = part.substring(0, colonIdx);
          final userIds = part.substring(colonIdx + 1).split('|').where((s) => s.isNotEmpty).toList();
          reactions[emoji] = Reaction(emoji: emoji, userIds: userIds);
        }
      }
    }

    return Message(
      id: m["id"] as String,
      channel: m['channel_id'] as String,
      author: m['author_id'] as String,
      content: m['content'] as String?,
      edited: m['edited_at'] != null ? DateTime.fromMillisecondsSinceEpoch(m['edited_at']).toIso8601String() : null,
      replies: m['reply_ids']?.toString().split(',').where((s) => s.isNotEmpty).toList(),
      attachments: attachments,
      reactions: reactions,
      isPending: m['is_pending'] == 1,
      isFailed: m['is_failed'] == 1,
    );
  }

  // ========== REACTIONS ==========

  static Future<void> addReactionToMessage(String messageId, String emoji, String userId) async {
    final db = await database;
    final maps = await db.query('messages', where: 'id = ?', whereArgs: [messageId]);
    if (maps.isEmpty) return;

    final m = maps.first;
    final reactionsData = m['reactions'] as String?;
    final reactions = <String, List<String>>{};

    if (reactionsData != null && reactionsData.isNotEmpty) {
      for (final part in reactionsData.split(';;')) {
        final colonIdx = part.indexOf(':');
        if (colonIdx > 0) {
          final key = part.substring(0, colonIdx);
          final users = part.substring(colonIdx + 1).split('|').where((s) => s.isNotEmpty).toList();
          reactions[key] = users;
        }
      }
    }

    reactions.putIfAbsent(emoji, () => []);
    if (!reactions[emoji]!.contains(userId)) {
      reactions[emoji]!.add(userId);
    }

    final newReactions = reactions.entries.map((e) => '${e.key}:${e.value.join('|')}').join(';;');
    await db.update('messages', {'reactions': newReactions}, where: 'id = ?', whereArgs: [messageId]);
  }

  static Future<void> removeReactionFromMessage(String messageId, String emoji, String userId) async {
    final db = await database;
    final maps = await db.query('messages', where: 'id = ?', whereArgs: [messageId]);
    if (maps.isEmpty) return;

    final m = maps.first;
    final reactionsData = m['reactions'] as String?;
    final reactions = <String, List<String>>{};

    if (reactionsData != null && reactionsData.isNotEmpty) {
      for (final part in reactionsData.split(';;')) {
        final colonIdx = part.indexOf(':');
        if (colonIdx > 0) {
          final key = part.substring(0, colonIdx);
          final users = part.substring(colonIdx + 1).split('|').where((s) => s.isNotEmpty).toList();
          reactions[key] = users;
        }
      }
    }

    if (reactions.containsKey(emoji)) {
      reactions[emoji]!.remove(userId);
      if (reactions[emoji]!.isEmpty) {
        reactions.remove(emoji);
      }
    }

    final newReactions = reactions.isEmpty
        ? null
        : reactions.entries.map((e) => '${e.key}:${e.value.join('|')}').join(';;');
    await db.update('messages', {'reactions': newReactions}, where: 'id = ?', whereArgs: [messageId]);
  }

  // ========== CHANNELS ==========

  static Future<void> insertChannel(Channel channel) async {
    final db = await database;
    await db.insert('channels', {
      'id': channel.id,
      'server_id': channel.server,
      'name': channel.name,
      'channel_type': channel.channelType,
      'last_message_id': channel.lastMessageId,
      'unread_count': channel.unreadCount,
      'mention_count': channel.mentionCount,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> insertChannels(List<Channel> channels) async {
    final db = await database;
    final batch = db.batch();
    for (final c in channels) {
      batch.insert('channels', {
        'id': c.id,
        'server_id': c.server,
        'name': c.name,
        'channel_type': c.channelType,
        'last_message_id': c.lastMessageId,
        'unread_count': c.unreadCount,
        'mention_count': c.mentionCount,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Channel>> getChannels({String? serverId}) async {
    final db = await database;
    final maps = serverId != null
        ? await db.query('channels', where: 'server_id = ?', whereArgs: [serverId])
        : await db.query('channels');
    return maps.map((m) => Channel(
          id: m["id"] as String,
          server: m['server_id'] as String?,
          name: m["name"] as String?,
          channelType: m['channel_type'] as String,
          lastMessageId: m['last_message_id'] as String?,
          unreadCount: (m["unread_count"] as int?) ?? 0,
          mentionCount: (m["mention_count"] as int?) ?? 0,
        )).toList();
  }

  static Future<void> updateChannelUnread(String channelId, int unread, int mentions) async {
    final db = await database;
    await db.update('channels', {'unread_count': unread, 'mention_count': mentions},
        where: 'id = ?', whereArgs: [channelId]);
  }

  // ========== SERVERS ==========

  static Future<void> insertServer(Server server) async {
    final db = await database;
    await db.insert('servers', {
      'id': server.id,
      'name': server.name,
      'owner_id': server.owner,
      'icon_id': server.icon,
      'banner_id': server.banner,
      'description': server.description,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> insertServers(List<Server> servers) async {
    final db = await database;
    final batch = db.batch();
    for (final s in servers) {
      batch.insert('servers', {
        'id': s.id,
        'name': s.name,
        'owner_id': s.owner,
        'icon_id': s.icon,
        'banner_id': s.banner,
        'description': s.description,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Server>> getServers() async {
    final db = await database;
    final maps = await db.query('servers');
    return maps.map((m) => Server(
          id: m["id"] as String,
          owner: m["owner_id"] as String?,
          name: m["name"] as String?,
          icon: m["icon_id"] as String?,
          banner: m["banner_id"] as String?,
          description: m["description"] as String?,
        )).toList();
  }

  // ========== USERS ==========

  static Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', {
      'id': user.id,
      'username': user.username,
      'display_name': user.displayName,
      'avatar_id': user.avatar,
      'status': user.status?.toJson().toString(),
      'presence': user.status?.presence,
      'relationship': user.relationship,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> insertUsers(List<User> users) async {
    final db = await database;
    final batch = db.batch();
    for (final u in users) {
      batch.insert('users', {
        'id': u.id,
        'username': u.username,
        'display_name': u.displayName,
        'avatar_id': u.avatar,
        'presence': u.status?.presence,
        'relationship': u.relationship,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<User?> getUser(String id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _mapToUser(maps.first);
  }

  static Future<List<User>> getUsersByRelationship(String relationship) async {
    final db = await database;
    final maps = await db.query('users', where: 'relationship = ?', whereArgs: [relationship]);
    return maps.map((m) => _mapToUser(m)).toList();
  }

  static Future<void> updateUserRelationship(String userId, String relationship) async {
    final db = await database;
    await db.update('users', {'relationship': relationship}, where: 'id = ?', whereArgs: [userId]);
  }

  static User _mapToUser(Map<String, dynamic> m) {
    final statusText = m['status']?.toString();
    return User(
      id: m["id"] as String,
      username: m['username'] as String,
      displayName: m['display_name'] as String?,
      avatar: m['avatar_id'] as String?,
      status: statusText != null && statusText.isNotEmpty
          ? UserStatus(text: statusText, presence: m['presence'] ?? 'unknown')
          : null,
      relationship: m['relationship'] as String?,
    );
  }

  // ========== PENDING MESSAGES (Offline Queue) ==========

  static Future<void> insertPendingMessage({
    required String id,
    required String channelId,
    String? content,
    List<Attachment>? attachments,
    List<String>? replyIds,
  }) async {
    final db = await database;
    await db.insert('pending_messages', {
      'id': id,
      'channel_id': channelId,
      'content': content,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'retry_count': 0,
      'is_sending': 0,
      'attachment_data': attachments?.map((a) => '${a.id}|${a.filename}|${a.contentType ?? ''}|${a.size ?? 0}').join(';;'),
      'reply_ids': replyIds?.join(','),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> removePendingMessage(String id) async {
    final db = await database;
    await db.delete('pending_messages', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updatePendingMessageSending(String id, bool isSending) async {
    final db = await database;
    await db.update('pending_messages', {'is_sending': isSending ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> incrementPendingRetry(String id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_messages SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingMessages(String channelId) async {
    final db = await database;
    return db.query(
      'pending_messages',
      where: 'channel_id = ?',
      whereArgs: [channelId],
      orderBy: 'created_at ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> getAllPendingMessages() async {
    final db = await database;
    return db.query('pending_messages', orderBy: 'created_at ASC');
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('channels');
    await db.delete('servers');
    await db.delete('users');
    await db.delete('pending_messages');
  }
}
