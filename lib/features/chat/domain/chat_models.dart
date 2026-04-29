class ChatContact {
  ChatContact({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  final String userId;
  final String displayName;
  final String role;

  String get initial =>
      displayName.trim().isEmpty ? '?' : displayName.trim()[0].toUpperCase();

  bool get isAliasUser => userId.startsWith('alias_');

  static String aliasUserIdForName(String name) {
    final normalized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'alias_${normalized.isEmpty ? 'artist' : normalized}';
  }
}

class ChatConversationPreview {
  ChatConversationPreview({
    required this.conversationId,
    required this.otherUserId,
    required this.otherName,
    required this.otherRole,
    required this.lastMessage,
    required this.updatedAt,
    required this.unreadCount,
  });

  final String conversationId;
  final String otherUserId;
  final String otherName;
  final String otherRole;
  final String lastMessage;
  final DateTime updatedAt;
  final int unreadCount;

  bool get hasUnread => unreadCount > 0;
  String get initial =>
      otherName.trim().isEmpty ? '?' : otherName.trim()[0].toUpperCase();

  factory ChatConversationPreview.fromMap(
    String conversationId,
    Map<Object?, Object?> map,
  ) {
    return ChatConversationPreview(
      conversationId: conversationId,
      otherUserId: (map['otherUserId'] ?? '') as String,
      otherName: (map['otherName'] ?? 'Artist') as String,
      otherRole: (map['otherRole'] ?? 'Artist') as String,
      lastMessage: (map['lastMessage'] ?? 'Start your conversation...') as String,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        _asInt(map['updatedAt']) ?? 0,
      ),
      unreadCount: _asInt(map['unreadCount']) ?? 0,
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String text;
  final DateTime sentAt;

  bool get isSystemNotification => senderId == 'system_notifications';

  factory ChatMessage.fromMap(
    String conversationId,
    String id,
    Map<Object?, Object?> map,
  ) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: (map['senderId'] ?? '') as String,
      senderName: (map['senderName'] ?? 'User') as String,
      senderRole: (map['senderRole'] ?? '') as String,
      text: (map['text'] ?? '') as String,
      sentAt: DateTime.fromMillisecondsSinceEpoch(
        _asInt(map['sentAt']) ?? 0,
      ),
    );
  }
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}
