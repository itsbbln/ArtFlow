class Commission {
  Commission({
    required this.id,
    required this.title,
    required this.status,
    required this.budget,
    this.artistName = '',
    this.buyerName = '',
    this.description = '',
    this.deadline,
    this.progress = 'Sketch',
    this.notes = '',
  });

  final String id;
  final String title;
  final String status; // Pending, Accepted, Rejected, Completed
  final double budget;
  final String artistName;
  final String buyerName;
  final String description;
  final DateTime? deadline;
  final String progress; // Sketch, In Progress, Completed
  final String notes;

  factory Commission.fromJson(Map<String, dynamic> json) {
    return Commission(
      id: json['id'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      budget: (json['budget'] as num).toDouble(),
      artistName: (json['artistName'] as String?) ?? '',
      buyerName: (json['buyerName'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      progress: (json['progress'] as String?) ?? 'Sketch',
      notes: (json['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'budget': budget,
    'artistName': artistName,
    'buyerName': buyerName,
    'description': description,
    'deadline': deadline?.toIso8601String(),
    'progress': progress,
    'notes': notes,
  };

  Commission copyWith({
    String? status,
    String? progress,
    String? notes,
  }) {
    return Commission(
      id: id,
      title: title,
      status: status ?? this.status,
      budget: budget,
      artistName: artistName,
      buyerName: buyerName,
      description: description,
      deadline: deadline,
      progress: progress ?? this.progress,
      notes: notes ?? this.notes,
    );
  }
}
