class Order {
  Order({
    required this.id,
    required this.artworkId,
    required this.status,
    required this.total,
  });

  final String id;
  final String artworkId;
  final String status;
  final double total;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      artworkId: json['artworkId'] as String,
      status: json['status'] as String,
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'artworkId': artworkId,
    'status': status,
    'total': total,
  };
}
