class Review {
  Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.authorId,
  });

  final String id;
  final int rating;
  final String comment;
  final String authorId;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      authorId: json['authorId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rating': rating,
    'comment': comment,
    'authorId': authorId,
  };
}
