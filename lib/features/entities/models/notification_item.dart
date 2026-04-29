class NotificationItem {
  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.type = 'general',
    this.source = '',
    this.conversationId = '',
    this.commissionId = '',
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String type;
  final String source;
  final String conversationId;
  final String commissionId;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      read: json['read'] as bool,
      type: (json['type'] as String?) ?? 'general',
      source: (json['source'] as String?) ?? '',
      conversationId: (json['conversationId'] as String?) ?? '',
      commissionId: (json['commissionId'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
    'type': type,
    'source': source,
    'conversationId': conversationId,
    'commissionId': commissionId,
  };
}
