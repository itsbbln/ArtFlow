class Order {
  Order({
    required this.id,
    required this.artworkId,
    required this.status,
    required this.total,
    this.artworkTitle = '',
    this.buyerId = '',
    this.buyerName = '',
    this.artistId = '',
    this.artistName = '',
    this.paymentMethod = 'GCash',
    this.paymentStatus = 'Held',
    this.payoutStatus = 'Pending',
  });

  final String id;
  final String artworkId;
  final String status;
  final double total;
  final String artworkTitle;
  final String buyerId;
  final String buyerName;
  final String artistId;
  final String artistName;
  final String paymentMethod;
  final String paymentStatus;
  final String payoutStatus;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      artworkId: json['artworkId'] as String,
      status: json['status'] as String,
      total: (json['total'] as num).toDouble(),
      artworkTitle: (json['artworkTitle'] as String?) ?? '',
      buyerId: (json['buyerId'] as String?) ?? '',
      buyerName: (json['buyerName'] as String?) ?? '',
      artistId: (json['artistId'] as String?) ?? '',
      artistName: (json['artistName'] as String?) ?? '',
      paymentMethod: (json['paymentMethod'] as String?) ?? 'GCash',
      paymentStatus: (json['paymentStatus'] as String?) ?? 'Held',
      payoutStatus: (json['payoutStatus'] as String?) ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'artworkId': artworkId,
    'status': status,
    'total': total,
    'artworkTitle': artworkTitle,
    'buyerId': buyerId,
    'buyerName': buyerName,
    'artistId': artistId,
    'artistName': artistName,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'payoutStatus': payoutStatus,
  };
}
