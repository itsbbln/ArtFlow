class Commission {
  Commission({
    required this.id,
    required this.title,
    required this.status,
    required this.budget,
    this.clientId = '',
    this.clientName = '',
    this.artistId = '',
    this.artistName = '',
    this.conversationId = '',
    this.artworkId = '',
    this.artworkTitle = '',
    this.brief = '',
    this.timeline = '',
    this.requestType = 'commission',
    this.dueDate,
    this.lastReminderAt,
    this.createdAt,
    this.updatedAt,
    this.reminderCount = 0,
  });

  final String id;
  final String title;
  final String status;
  final double budget;
  final String clientId;
  final String clientName;
  final String artistId;
  final String artistName;
  final String conversationId;
  final String artworkId;
  final String artworkTitle;
  final String brief;
  final String timeline;
  final String requestType;
  final DateTime? dueDate;
  final DateTime? lastReminderAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int reminderCount;

  bool get isOngoing {
    final normalized = status.toLowerCase();
    return normalized == 'accepted' ||
        normalized == 'sketch' ||
        normalized == 'in progress' ||
        normalized == 'revision';
  }

  factory Commission.fromJson(Map<String, dynamic> json) {
    return Commission(
      id: json['id'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      budget: (json['budget'] as num).toDouble(),
      clientId: (json['clientId'] as String?) ?? '',
      clientName: (json['clientName'] as String?) ?? '',
      artistId: (json['artistId'] as String?) ?? '',
      artistName: (json['artistName'] as String?) ?? '',
      conversationId: (json['conversationId'] as String?) ?? '',
      artworkId: (json['artworkId'] as String?) ?? '',
      artworkTitle: (json['artworkTitle'] as String?) ?? '',
      brief: (json['brief'] as String?) ?? '',
      timeline: (json['timeline'] as String?) ?? '',
      requestType: (json['requestType'] as String?) ?? 'commission',
      dueDate: _parseDateTime(json['dueDate']),
      lastReminderAt: _parseDateTime(json['lastReminderAt']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      reminderCount: (json['reminderCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'budget': budget,
    'clientId': clientId,
    'clientName': clientName,
    'artistId': artistId,
    'artistName': artistName,
    'conversationId': conversationId,
    'artworkId': artworkId,
    'artworkTitle': artworkTitle,
    'brief': brief,
    'timeline': timeline,
    'requestType': requestType,
    'dueDate': dueDate?.toIso8601String(),
    'lastReminderAt': lastReminderAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'reminderCount': reminderCount,
  };
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value.runtimeType.toString() == 'Timestamp') {
    return (value as dynamic).toDate() as DateTime;
  }
  return null;
}
