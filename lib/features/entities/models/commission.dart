class Commission {
  Commission({
    required this.id,
    required this.title,
    required this.status,
    required this.budget,
  });

  final String id;
  final String title;
  final String status;
  final double budget;

  factory Commission.fromJson(Map<String, dynamic> json) {
    return Commission(
      id: json['id'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      budget: (json['budget'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'budget': budget,
  };
}
