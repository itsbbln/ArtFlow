import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../entities/models/artwork.dart';

class AuctionSnapshot {
  const AuctionSnapshot({
    required this.artworkId,
    required this.currentBid,
    required this.currentBidderId,
    required this.currentBidderName,
    required this.bidCount,
    required this.endsAt,
    required this.status,
  });

  final String artworkId;
  final double currentBid;
  final String currentBidderId;
  final String currentBidderName;
  final int bidCount;
  final DateTime? endsAt;
  final String status;

  bool get isActive =>
      status == 'active' &&
      (endsAt == null || endsAt!.isAfter(DateTime.now()));
}

class AuctionService {
  AuctionService({FirebaseDatabase? database}) : _database = database;

  FirebaseDatabase? _database;

  bool get isAvailable => Firebase.apps.isNotEmpty;

  FirebaseDatabase get _resolvedDatabase {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    final app = Firebase.app();
    final databaseUrl = app.options.databaseURL?.trim();
    final fallbackUrl = 'https://${app.options.projectId}-default-rtdb.firebaseio.com';
    final created = FirebaseDatabase.instanceFor(
      app: app,
      databaseURL:
          databaseUrl == null || databaseUrl.isEmpty ? fallbackUrl : databaseUrl,
    );
    _database = created;
    return created;
  }

  DatabaseReference _auctionRef(String artworkId) =>
      _resolvedDatabase.ref('auctions/$artworkId');

  DatabaseReference _bidHistoryRef(String artworkId) =>
      _resolvedDatabase.ref('auction_bids/$artworkId');

  Future<void> ensureAuctionForArtwork(Artwork artwork) async {
    if (!isAvailable || !artwork.isAuction) {
      return;
    }
    final ref = _auctionRef(artwork.id);
    final snapshot = await ref.get();
    final endsAt = artwork.auctionEndAt?.millisecondsSinceEpoch;
    final active = artwork.auctionEndAt == null ||
        artwork.auctionEndAt!.isAfter(DateTime.now());
    if (!snapshot.exists) {
      await ref.set({
        'artworkId': artwork.id,
        'currentBid': artwork.price,
        'currentBidderId': '',
        'currentBidderName': '',
        'bidCount': 0,
        'endsAt': endsAt,
        'status': active ? 'active' : 'ended',
        'updatedAt': ServerValue.timestamp,
      });
      return;
    }

    await ref.update({
      'endsAt': endsAt,
      'status': active ? 'active' : 'ended',
      'updatedAt': ServerValue.timestamp,
    });
  }

  Stream<AuctionSnapshot?> watchAuction(String artworkId) {
    if (!isAvailable) {
      return Stream.value(null);
    }
    return _auctionRef(artworkId).onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw is! Map<Object?, Object?>) {
        return null;
      }
      return AuctionSnapshot(
        artworkId: artworkId,
        currentBid: _asDouble(raw['currentBid']),
        currentBidderId: (raw['currentBidderId'] ?? '') as String,
        currentBidderName: (raw['currentBidderName'] ?? '') as String,
        bidCount: _asInt(raw['bidCount']),
        endsAt: _asDateTime(raw['endsAt']),
        status: (raw['status'] ?? 'active') as String,
      );
    });
  }

  Future<void> placeBid({
    required Artwork artwork,
    required String bidderId,
    required String bidderName,
    required double amount,
  }) async {
    if (!isAvailable) {
      throw StateError('Auction service is unavailable.');
    }
    await ensureAuctionForArtwork(artwork);
    final ref = _auctionRef(artwork.id);
    final snapshot = await ref.get();
    final data = snapshot.value as Map<Object?, Object?>? ?? <Object?, Object?>{};
    final endsAt = _asDateTime(data['endsAt']);
    if (endsAt != null && !endsAt.isAfter(DateTime.now())) {
      await ref.update({'status': 'ended', 'updatedAt': ServerValue.timestamp});
      throw StateError('This auction has already ended.');
    }

    final currentBid = _asDouble(data['currentBid']);
    if (amount <= currentBid) {
      throw StateError('Your bid must be higher than the current bid.');
    }

    await ref.update({
      'currentBid': amount,
      'currentBidderId': bidderId,
      'currentBidderName': bidderName,
      'bidCount': _asInt(data['bidCount']) + 1,
      'status': 'active',
      'updatedAt': ServerValue.timestamp,
    });

    final bidRef = _bidHistoryRef(artwork.id).push();
    await bidRef.set({
      'id': bidRef.key ?? '',
      'artworkId': artwork.id,
      'bidderId': bidderId,
      'bidderName': bidderName,
      'amount': amount,
      'createdAt': ServerValue.timestamp,
    });
  }
}

double _asDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

DateTime? _asDateTime(Object? value) {
  final timestamp = _asInt(value);
  if (timestamp <= 0) {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(timestamp);
}
