class Auction {
  Auction({
    required this.id,
    required this.artworkId,
    required this.title,
    required this.artistName,
    required this.currentBid,
    required this.highestBidder,
    required this.endAt,
    this.completed = false,
  });

  final String id;
  final String artworkId;
  final String title;
  final String artistName;
  final double currentBid;
  final String highestBidder;
  final DateTime endAt;
  final bool completed;

  Auction copyWith({
    String? id,
    String? artworkId,
    String? title,
    String? artistName,
    double? currentBid,
    String? highestBidder,
    DateTime? endAt,
    bool? completed,
  }) {
    return Auction(
      id: id ?? this.id,
      artworkId: artworkId ?? this.artworkId,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      currentBid: currentBid ?? this.currentBid,
      highestBidder: highestBidder ?? this.highestBidder,
      endAt: endAt ?? this.endAt,
      completed: completed ?? this.completed,
    );
  }
}
