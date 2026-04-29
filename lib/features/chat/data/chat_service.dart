import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../domain/chat_models.dart';

class ChatService {
  ChatService({FirebaseDatabase? database}) : _database = database;

  static const _threadsPath = 'chat_threads';
  static const _messagesPath = 'chat_messages';
  static const _userThreadsPath = 'chat_user_threads';

  FirebaseDatabase? _database;

  bool get isAvailable => Firebase.apps.isNotEmpty;

  static FirebaseDatabase _buildDatabase() {
    final app = Firebase.app();
    final databaseUrl = app.options.databaseURL?.trim();
    if (databaseUrl != null && databaseUrl.isNotEmpty) {
      return FirebaseDatabase.instanceFor(app: app, databaseURL: databaseUrl);
    }

    final projectId = app.options.projectId;
    final fallbackUrl = 'https://$projectId-default-rtdb.firebaseio.com';
    return FirebaseDatabase.instanceFor(app: app, databaseURL: fallbackUrl);
  }

  static String conversationIdForUsers(String firstUserId, String secondUserId) {
    final sorted = [firstUserId, secondUserId]..sort();
    return sorted.join('__');
  }

  FirebaseDatabase get _resolvedDatabase {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    if (!isAvailable) {
      throw StateError('Firebase has not been initialized for chat.');
    }
    final created = _buildDatabase();
    _database = created;
    return created;
  }

  DatabaseReference _threadRef(String conversationId) =>
      _resolvedDatabase.ref('$_threadsPath/$conversationId');

  DatabaseReference _messagesRef(String conversationId) =>
      _resolvedDatabase.ref('$_messagesPath/$conversationId');

  DatabaseReference _userThreadsRef(String userId) =>
      _resolvedDatabase.ref('$_userThreadsPath/$userId');

  Future<String> ensureConversation({
    required String currentUserId,
    required String currentUserName,
    required String currentUserRole,
    required ChatContact otherUser,
  }) async {
    final conversationId =
        conversationIdForUsers(currentUserId, otherUser.userId);
    final updates = <String, Object?>{
      'participants/$currentUserId': true,
      'participants/${otherUser.userId}': true,
      'participantNames/$currentUserId': currentUserName,
      'participantNames/${otherUser.userId}': otherUser.displayName,
      'participantRoles/$currentUserId': currentUserRole,
      'participantRoles/${otherUser.userId}': otherUser.role,
      'updatedAt': ServerValue.timestamp,
      'lastMessage': 'Start your conversation...',
      'lastSenderId': '',
    };

    await _threadRef(conversationId).update(updates);
    await _userThreadsRef(currentUserId).child(conversationId).update({
      'conversationId': conversationId,
      'otherUserId': otherUser.userId,
      'otherName': otherUser.displayName,
      'otherRole': otherUser.role,
      'lastMessage': 'Start your conversation...',
      'updatedAt': ServerValue.timestamp,
      'lastSenderId': '',
      'unreadCount': 0,
    });

    await _userThreadsRef(otherUser.userId).child(conversationId).update({
      'conversationId': conversationId,
      'otherUserId': currentUserId,
      'otherName': currentUserName,
      'otherRole': currentUserRole,
      'lastMessage': 'Start your conversation...',
      'updatedAt': ServerValue.timestamp,
      'lastSenderId': '',
      'unreadCount': 0,
    });

    return conversationId;
  }

  Stream<List<ChatConversationPreview>> watchConversationsForUser(String userId) {
    return _userThreadsRef(userId).onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map<Object?, Object?>) {
        return const <ChatConversationPreview>[];
      }

      final items = raw.entries
          .where((entry) => entry.value is Map<Object?, Object?>)
          .map((entry) {
            return ChatConversationPreview.fromMap(
              entry.key as String,
              entry.value as Map<Object?, Object?>,
            );
          })
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return items;
    });
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _messagesRef(conversationId).onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map<Object?, Object?>) {
        return const <ChatMessage>[];
      }

      final items = raw.entries
          .where((entry) => entry.value is Map<Object?, Object?>)
          .map((entry) {
            return ChatMessage.fromMap(
              conversationId,
              entry.key as String,
              entry.value as Map<Object?, Object?>,
            );
          })
          .toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return items;
    });
  }

  Future<ChatContact?> getConversationContact({
    required String currentUserId,
    required String conversationId,
  }) async {
    final snapshot = await _threadRef(conversationId).get();
    final raw = snapshot.value;
    if (raw is! Map<Object?, Object?>) {
      return null;
    }

    final names =
        raw['participantNames'] as Map<Object?, Object?>? ?? const <Object?, Object?>{};
    final roles =
        raw['participantRoles'] as Map<Object?, Object?>? ?? const <Object?, Object?>{};
    final participants =
        raw['participants'] as Map<Object?, Object?>? ?? const <Object?, Object?>{};

    for (final entry in participants.entries) {
      final userId = entry.key as String;
      if (userId == currentUserId) {
        continue;
      }

      return ChatContact(
        userId: userId,
        displayName: (names[userId] ?? 'Artist') as String,
        role: (roles[userId] ?? 'Artist') as String,
      );
    }

    return null;
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required ChatContact recipient,
    required String text,
  }) async {
    final messageRef = _messagesRef(conversationId).push();
    final payload = <String, Object?>{
      'id': messageRef.key ?? '',
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'sentAt': ServerValue.timestamp,
    };

    await messageRef.set(payload);
    await _threadRef(conversationId).update({
      'lastMessage': text,
      'lastSenderId': senderId,
      'updatedAt': ServerValue.timestamp,
      'participantNames/$senderId': senderName,
      'participantNames/${recipient.userId}': recipient.displayName,
      'participantRoles/$senderId': senderRole,
      'participantRoles/${recipient.userId}': recipient.role,
      'participants/$senderId': true,
      'participants/${recipient.userId}': true,
    });

    await _userThreadsRef(senderId).child(conversationId).update({
      'conversationId': conversationId,
      'otherUserId': recipient.userId,
      'otherName': recipient.displayName,
      'otherRole': recipient.role,
      'lastMessage': text,
      'updatedAt': ServerValue.timestamp,
      'lastSenderId': senderId,
      'unreadCount': 0,
    });

    await _userThreadsRef(recipient.userId).child(conversationId).update({
      'conversationId': conversationId,
      'otherUserId': senderId,
      'otherName': senderName,
      'otherRole': senderRole,
      'lastMessage': text,
      'updatedAt': ServerValue.timestamp,
      'lastSenderId': senderId,
    });

    await _userThreadsRef(recipient.userId)
        .child(conversationId)
        .child('unreadCount')
        .runTransaction((currentValue) {
      final currentUnread = currentValue is int
          ? currentValue
          : (currentValue is num ? currentValue.toInt() : 0);
      return Transaction.success(currentUnread + 1);
    });
  }

  Future<void> sendSystemMessage({
    required String conversationId,
    required String text,
  }) async {
    final messageRef = _messagesRef(conversationId).push();
    await messageRef.set({
      'id': messageRef.key ?? '',
      'conversationId': conversationId,
      'senderId': 'system_notifications',
      'senderName': 'System Notifications',
      'senderRole': 'System',
      'text': text,
      'sentAt': ServerValue.timestamp,
    });

    final threadRef = _threadRef(conversationId);
    final threadSnapshot = await threadRef.get();
    final raw = threadSnapshot.value as Map<Object?, Object?>? ??
        const <Object?, Object?>{};
    final participants =
        raw['participants'] as Map<Object?, Object?>? ?? const <Object?, Object?>{};

    await threadRef.update({
      'lastMessage': text,
      'lastSenderId': 'system_notifications',
      'updatedAt': ServerValue.timestamp,
    });

    for (final entry in participants.entries) {
      final userId = entry.key as String;
      await _userThreadsRef(userId).child(conversationId).update({
        'conversationId': conversationId,
        'lastMessage': text,
        'updatedAt': ServerValue.timestamp,
        'lastSenderId': 'system_notifications',
      });
      await _userThreadsRef(userId)
          .child(conversationId)
          .child('unreadCount')
          .runTransaction((currentValue) {
        final currentUnread = currentValue is int
            ? currentValue
            : (currentValue is num ? currentValue.toInt() : 0);
        return Transaction.success(currentUnread + 1);
      });
    }
  }

  Future<void> markConversationRead({
    required String userId,
    required String conversationId,
  }) async {
    await _userThreadsRef(userId).child(conversationId).update({
      'unreadCount': 0,
      'lastReadAt': ServerValue.timestamp,
    });
  }
}
