import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firestore follower graph:
/// — `users/{artistId}/followers/{followerId}`
/// — `users/{followerId}/following/{artistId}`
/// Denormalized `followersCount` / `followingCount` on `users/{uid}`.
class FollowService {
  FollowService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<void> follow({
    required String followerId,
    required String artistId,
  }) async {
    if (followerId == artistId || followerId.isEmpty || artistId.isEmpty) {
      return;
    }

    final followerEdge =
        _userDoc(artistId).collection('followers').doc(followerId);

    final dup = await followerEdge.get();
    if (dup.exists) {
      return;
    }

    final batch = _db.batch();
    final followingEdge =
        _userDoc(followerId).collection('following').doc(artistId);

    batch.set(followerEdge, {'createdAt': FieldValue.serverTimestamp()});
    batch.set(followingEdge, {'createdAt': FieldValue.serverTimestamp()});

    batch.set(
      _userDoc(artistId),
      {'followersCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
    batch.set(
      _userDoc(followerId),
      {'followingCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('FollowService.follow error: $e');
      rethrow;
    }
  }

  Future<void> unfollow({
    required String followerId,
    required String artistId,
  }) async {
    if (followerId == artistId || followerId.isEmpty || artistId.isEmpty) {
      return;
    }

    final followerEdge =
        _userDoc(artistId).collection('followers').doc(followerId);

    final snap = await followerEdge.get();
    if (!snap.exists) {
      return;
    }

    final batch = _db.batch();
    final followingEdge =
        _userDoc(followerId).collection('following').doc(artistId);

    batch.delete(followerEdge);
    batch.delete(followingEdge);

    batch.set(
      _userDoc(artistId),
      {'followersCount': FieldValue.increment(-1)},
      SetOptions(merge: true),
    );
    batch.set(
      _userDoc(followerId),
      {'followingCount': FieldValue.increment(-1)},
      SetOptions(merge: true),
    );

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('FollowService.unfollow error: $e');
      rethrow;
    }
  }

  Stream<bool> watchIsFollowing({
    required String followerId,
    required String artistId,
  }) {
    if (followerId.isEmpty || artistId.isEmpty || followerId == artistId) {
      return Stream.value(false);
    }
    return _userDoc(artistId)
        .collection('followers')
        .doc(followerId)
        .snapshots()
        .map((s) => s.exists);
  }
}
