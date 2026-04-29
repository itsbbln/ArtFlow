class Order {
  Order({
    required this.id,
    required this.artworkId,
    required this.status,
    required this.total,
    this.paymentStatus = 'pending',
    this.paymentMethod,
    this.reportedAmount,
    this.paymentProofName,
    this.artistConfirmedPayment = false,
  });

  final String id;
  final String artworkId;
  final String status;
  final double total;
  final String paymentStatus;
  final String? paymentMethod;
  final double? reportedAmount;
  final String? paymentProofName;
  final bool artistConfirmedPayment;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      artworkId: json['artworkId'] as String,
      status: json['status'] as String,
      total: (json['total'] as num).toDouble(),
      paymentStatus: (json['paymentStatus'] as String?) ?? 'pending',
      paymentMethod: json['paymentMethod'] as String?,
      reportedAmount: (json['reportedAmount'] as num?)?.toDouble(),
      paymentProofName: json['paymentProofName'] as String?,
      artistConfirmedPayment:
          (json['artistConfirmedPayment'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'artworkId': artworkId,
    'status': status,
    'total': total,
    'paymentStatus': paymentStatus,
    'paymentMethod': paymentMethod,
    'reportedAmount': reportedAmount,
    'paymentProofName': paymentProofName,
    'artistConfirmedPayment': artistConfirmedPayment,
  };
}
