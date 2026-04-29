class Bid {
  final String bidderName;
  final double amount;
  final DateTime timestamp;

  Bid({
    required this.bidderName,
    required this.amount,
    required this.timestamp,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      bidderName: json['bidderName'] as String,
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'bidderName': bidderName,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
  };
}

class Artwork {
  Artwork({
    required this.id,
    required this.title,
    required this.artistName,
    required this.price,
    this.description,
    this.category = 'other',
    this.medium,
    this.size,
    this.imageUrl,
    this.images = const [],
    this.isFeatured = false,
    this.avgRating = 0,
    this.status = 'For Sale',
    this.isAuction = false,
    this.auctionEndTime,
    this.startingPrice,
    this.highestBid,
    this.bidCount = 0,
    this.bidHistory = const [],
  });

  final String id;
  final String title;
  final String artistName;
  final double price;
  final String? description;
  final String category;
  final String? medium;
  final String? size;
  final String? imageUrl;
  final List<String> images;
  final bool isFeatured;
  final double avgRating;
  final String status;
  final bool isAuction;
  final DateTime? auctionEndTime;
  final double? startingPrice;
  final double? highestBid;
  final int bidCount;
  final List<Bid> bidHistory;

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      id: json['id'] as String,
      title: json['title'] as String,
      artistName: json['artistName'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      category: (json['category'] as String?) ?? 'other',
      medium: json['medium'] as String?,
      size: json['size'] as String?,
      imageUrl: json['imageUrl'] as String?,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList() ??
          const [],
      isFeatured: (json['isFeatured'] as bool?) ?? false,
      avgRating: ((json['avgRating'] as num?) ?? 0).toDouble(),
      status: (json['status'] as String?) ?? 'For Sale',
      isAuction: (json['isAuction'] as bool?) ?? false,
      auctionEndTime: json['auctionEndTime'] != null ? DateTime.parse(json['auctionEndTime'] as String) : null,
      startingPrice: json['startingPrice'] != null ? (json['startingPrice'] as num).toDouble() : null,
      highestBid: json['highestBid'] != null ? (json['highestBid'] as num).toDouble() : null,
      bidCount: (json['bidCount'] as int?) ?? 0,
      bidHistory: (json['bidHistory'] as List<dynamic>?)
              ?.map((item) => Bid.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artistName': artistName,
    'price': price,
    'description': description,
    'category': category,
    'medium': medium,
    'size': size,
    'imageUrl': imageUrl,
    'images': images,
    'isFeatured': isFeatured,
    'avgRating': avgRating,
    'status': status,
    'isAuction': isAuction,
    'auctionEndTime': auctionEndTime?.toIso8601String(),
    'startingPrice': startingPrice,
    'highestBid': highestBid,
    'bidCount': bidCount,
    'bidHistory': bidHistory.map((item) => item.toJson()).toList(),
  };

  Artwork copyWith({
    String? id,
    String? title,
    String? artistName,
    double? price,
    String? description,
    String? category,
    String? medium,
    String? size,
    String? imageUrl,
    List<String>? images,
    bool? isFeatured,
    double? avgRating,
    String? status,
    bool? isAuction,
    DateTime? auctionEndTime,
    double? startingPrice,
    double? highestBid,
    int? bidCount,
    List<Bid>? bidHistory,
  }) {
    return Artwork(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      medium: medium ?? this.medium,
      size: size ?? this.size,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      isFeatured: isFeatured ?? this.isFeatured,
      avgRating: avgRating ?? this.avgRating,
      status: status ?? this.status,
      isAuction: isAuction ?? this.isAuction,
      auctionEndTime: auctionEndTime ?? this.auctionEndTime,
      startingPrice: startingPrice ?? this.startingPrice,
      highestBid: highestBid ?? this.highestBid,
      bidCount: bidCount ?? this.bidCount,
      bidHistory: bidHistory ?? this.bidHistory,
    );
  }
}
