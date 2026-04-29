class Artwork {
  Artwork({
    required this.id,
    required this.title,
    this.artistId = '',
    required this.artistName,
    required this.price,
    this.description,
    this.category = 'other',
    this.medium,
    this.size,
    this.imageUrl,
    this.images = const [],
    this.tags = const [],
    this.isFeatured = false,
    this.avgRating = 0,
    this.sold = false,
    this.views = 0,
    this.inquiries = 0,
    this.inventoryType = 'one_of_a_kind',
    this.stockCount = 1,
    this.saleType = 'direct_sale',
    this.auctionStatus = 'inactive',
    this.auctionEndAt,
    this.acceptingCommissions = true,
  });

  final String id;
  final String title;
  final String artistId;
  final String artistName;
  final double price;
  final String? description;
  final String category;
  final String? medium;
  final String? size;
  final String? imageUrl;
  final List<String> images;
  final List<String> tags;
  final bool isFeatured;
  final double avgRating;
  final bool sold;
  final int views;
  final int inquiries;
  final String inventoryType;
  final int stockCount;
  final String saleType;
  final String auctionStatus;
  final DateTime? auctionEndAt;
  final bool acceptingCommissions;

  bool get isAuction => saleType == 'auction';
  bool get isOneOfAKind => inventoryType == 'one_of_a_kind';

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      id: json['id'] as String,
      title: json['title'] as String,
      artistId: (json['artistId'] as String?) ?? '',
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
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList() ??
          const [],
      isFeatured: (json['isFeatured'] as bool?) ?? false,
      avgRating: ((json['avgRating'] as num?) ?? 0).toDouble(),
      sold: (json['sold'] as bool?) ?? false,
      views: (json['views'] as num?)?.toInt() ?? 0,
      inquiries: (json['inquiries'] as num?)?.toInt() ?? 0,
      inventoryType:
          (json['inventoryType'] as String?) ?? 'one_of_a_kind',
      stockCount: (json['stockCount'] as num?)?.toInt() ?? 1,
      saleType: (json['saleType'] as String?) ?? 'direct_sale',
      auctionStatus: (json['auctionStatus'] as String?) ?? 'inactive',
      auctionEndAt: _parseDateTime(json['auctionEndAt']),
      acceptingCommissions:
          (json['acceptingCommissions'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artistId': artistId,
    'artistName': artistName,
    'price': price,
    'description': description,
    'category': category,
    'medium': medium,
    'size': size,
    'imageUrl': imageUrl,
    'images': images,
    'tags': tags,
    'isFeatured': isFeatured,
    'avgRating': avgRating,
    'sold': sold,
    'views': views,
    'inquiries': inquiries,
    'inventoryType': inventoryType,
    'stockCount': stockCount,
    'saleType': saleType,
    'auctionStatus': auctionStatus,
    'auctionEndAt': auctionEndAt?.toIso8601String(),
    'acceptingCommissions': acceptingCommissions,
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
