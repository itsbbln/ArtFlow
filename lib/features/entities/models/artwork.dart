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
  };
}
