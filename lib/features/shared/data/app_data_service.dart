import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../entities/models/artwork.dart';
import '../../entities/models/commission.dart';
import '../../entities/models/notification_item.dart';
import '../../entities/models/order.dart' as app_models;
import '../../entities/models/review.dart';

class AppDataService {
  AppDataService({FirebaseFirestore? firestore}) : _firestore = firestore;

  static final AppDataService instance = AppDataService();

  FirebaseFirestore? _firestore;

  bool get isAvailable => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _resolvedFirestore {
    final existing = _firestore;
    if (existing != null) {
      return existing;
    }
    if (!isAvailable) {
      throw StateError('Firebase has not been initialized.');
    }
    final created = FirebaseFirestore.instance;
    _firestore = created;
    return created;
  }

  CollectionReference<Map<String, dynamic>> get _artworks =>
      _resolvedFirestore.collection('artworks');
  CollectionReference<Map<String, dynamic>> get _commissions =>
      _resolvedFirestore.collection('commissions');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _resolvedFirestore.collection('orders');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _resolvedFirestore.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _resolvedFirestore.collection('reviews');
  CollectionReference<Map<String, dynamic>> get _transactions =>
      _resolvedFirestore.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _users =>
      _resolvedFirestore.collection('users');

  static const categories = <String>[
    'all',
    'painting',
    'digital',
    'prints',
    'crafts',
    'sculpture',
    'photography',
    'textile',
    'mixed_media',
    'illustration',
    'stickers',
    'charms',
    'merch',
  ];

  Stream<List<Artwork>> watchArtworks() {
    if (!isAvailable) {
      return Stream.value(const <Artwork>[]);
    }
    return _artworks
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_artworkFromDoc).toList());
  }

  Future<List<Artwork>> fetchArtworks() async {
    if (!isAvailable) {
      return const <Artwork>[];
    }
    final snapshot = await _artworks
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(_artworkFromDoc).toList();
  }

  Stream<Artwork?> watchArtwork(String id) {
    if (!isAvailable) {
      return Stream.value(null);
    }
    return _artworks.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return _artworkFromDoc(doc);
    });
  }

  Future<Artwork?> fetchArtwork(String id) async {
    if (!isAvailable) {
      return null;
    }
    final doc = await _artworks.doc(id).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return _artworkFromDoc(doc);
  }

  Future<void> upsertArtwork(Artwork artwork) async {
    if (!isAvailable) {
      return;
    }
    final resolvedImages = artwork.images.where((item) => item.isNotEmpty).toList();
    final primaryImage = artwork.imageUrl?.isNotEmpty == true
        ? artwork.imageUrl
        : (resolvedImages.isNotEmpty ? resolvedImages.first : '');
    await _artworks.doc(artwork.id).set({
      ...artwork.toJson(),
      'imageUrl': primaryImage,
      'images': resolvedImages,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'sold': artwork.sold,
      'views': artwork.views,
      'inquiries': artwork.inquiries,
      'tagsLower': artwork.tags.map((item) => item.toLowerCase()).toList(),
      'artistNameLower': artwork.artistName.toLowerCase(),
      'titleLower': artwork.title.toLowerCase(),
      'mediumLower': (artwork.medium ?? '').toLowerCase(),
      'categoryLower': artwork.category.toLowerCase(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteArtwork(String id) async {
    if (!isAvailable) {
      return;
    }
    await _artworks.doc(id).delete();
  }

  Future<void> markArtworkSold(String id) async {
    if (!isAvailable) {
      return;
    }
    await _artworks.doc(id).set({
      'sold': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> incrementArtworkView(String id) async {
    if (!isAvailable) {
      return;
    }
    await _artworks.doc(id).set({
      'views': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> incrementArtworkInquiry(String id) async {
    if (!isAvailable) {
      return;
    }
    await _artworks.doc(id).set({
      'inquiries': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> createCommission(Commission commission) async {
    if (!isAvailable) {
      return;
    }
    await _commissions.doc(commission.id).set({
      ...commission.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusLower': commission.status.toLowerCase(),
      'dueDate': commission.dueDate == null
          ? null
          : Timestamp.fromDate(commission.dueDate!),
      'lastReminderAt': commission.lastReminderAt == null
          ? null
          : Timestamp.fromDate(commission.lastReminderAt!),
    }, SetOptions(merge: true));

    if (commission.artistId.isNotEmpty) {
      await addNotification(
        userId: commission.artistId,
        title: 'New commission request',
        body: '${commission.clientName} sent ${commission.title}.',
        type: 'commission',
        source: 'commissions',
        conversationId: commission.conversationId,
        commissionId: commission.id,
      );
    }
  }

  Future<List<Commission>> fetchCommissionsForUser({
    required String userId,
    required String displayName,
    required bool artistView,
  }) async {
    if (!isAvailable) {
      return const <Commission>[];
    }
    Query<Map<String, dynamic>> query = artistView
        ? _commissions.where('artistId', isEqualTo: userId)
        : _commissions.where('clientId', isEqualTo: userId);

    final snapshot = await query.orderBy('createdAt', descending: true).get();
    var items = snapshot.docs.map(_commissionFromDoc).toList();
    if (items.isEmpty && displayName.isNotEmpty) {
      final fallback = await _commissions
          .where(
            artistView ? 'artistName' : 'clientName',
            isEqualTo: displayName,
          )
          .orderBy('createdAt', descending: true)
          .get();
      items = fallback.docs.map(_commissionFromDoc).toList();
    }
    return items;
  }

  Stream<List<Commission>> watchCommissionsForUser({
    required String userId,
    required String displayName,
    required bool artistView,
  }) {
    if (!isAvailable) {
      return Stream.value(const <Commission>[]);
    }
    Query<Map<String, dynamic>> query = artistView
        ? _commissions.where('artistId', isEqualTo: userId)
        : _commissions.where('clientId', isEqualTo: userId);

    return query.orderBy('createdAt', descending: true).snapshots().asyncMap((
      snapshot,
    ) async {
      var items = snapshot.docs.map(_commissionFromDoc).toList();
      if (items.isEmpty && displayName.isNotEmpty) {
        items = await fetchCommissionsForUser(
          userId: userId,
          displayName: displayName,
          artistView: artistView,
        );
      }
      return items;
    });
  }

  Future<void> updateCommissionStatus(String id, String nextStatus) async {
    if (!isAvailable) {
      return;
    }
    final doc = await _commissions.doc(id).get();
    final data = doc.data();
    await _commissions.doc(id).set({
      'status': nextStatus,
      'statusLower': nextStatus.toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (data != null) {
      final notifyUserId = (data['clientId'] as String?) ?? '';
      final title = (data['title'] as String?) ?? 'Commission';
      if (notifyUserId.isNotEmpty) {
        await addNotification(
          userId: notifyUserId,
          title: 'Commission update',
          body: '$title is now $nextStatus.',
          type: 'commission',
          source: 'commissions',
          conversationId: (data['conversationId'] as String?) ?? '',
          commissionId: id,
        );
      }
    }
  }

  Future<void> updateCommissionReminder(
    String id, {
    required DateTime remindedAt,
  }) async {
    if (!isAvailable) {
      return;
    }
    await _commissions.doc(id).set({
      'lastReminderAt': Timestamp.fromDate(remindedAt),
      'reminderCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> createOrder(app_models.Order order) async {
    if (!isAvailable) {
      return;
    }
    await _orders.doc(order.id).set({
      ...order.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusLower': order.status.toLowerCase(),
    }, SetOptions(merge: true));

    await _transactions.doc(order.id).set({
      'orderId': order.id,
      'buyerId': order.buyerId,
      'sellerId': order.artistId,
      'buyerName': order.buyerName,
      'sellerName': order.artistName,
      'amount': order.total,
      'platformFee': order.total * 0.1,
      'escrowStatus': 'held',
      'artworkTitle': order.artworkTitle,
      'paymentMethod': order.paymentMethod,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (order.artistId.isNotEmpty) {
      await addNotification(
        userId: order.artistId,
        title: 'New order',
        body: '${order.buyerName} placed an order for ${order.artworkTitle}.',
      );
    }
  }

  Future<List<app_models.Order>> fetchOrdersForUser({
    required String userId,
    required String displayName,
    required bool artistView,
  }) async {
    if (!isAvailable) {
      return const <app_models.Order>[];
    }
    Query<Map<String, dynamic>> query = artistView
        ? _orders.where('artistId', isEqualTo: userId)
        : _orders.where('buyerId', isEqualTo: userId);
    final snapshot = await query.orderBy('createdAt', descending: true).get();
    var items = snapshot.docs.map(_orderFromDoc).toList();
    if (items.isEmpty && displayName.isNotEmpty) {
      final fallback = await _orders
          .where(
            artistView ? 'artistName' : 'buyerName',
            isEqualTo: displayName,
          )
          .orderBy('createdAt', descending: true)
          .get();
      items = fallback.docs.map(_orderFromDoc).toList();
    }
    return items;
  }

  Stream<List<app_models.Order>> watchOrdersForUser({
    required String userId,
    required String displayName,
    required bool artistView,
  }) {
    if (!isAvailable) {
      return Stream.value(const <app_models.Order>[]);
    }
    Query<Map<String, dynamic>> query = artistView
        ? _orders.where('artistId', isEqualTo: userId)
        : _orders.where('buyerId', isEqualTo: userId);

    return query.orderBy('createdAt', descending: true).snapshots().asyncMap((
      snapshot,
    ) async {
      var items = snapshot.docs.map(_orderFromDoc).toList();
      if (items.isEmpty && displayName.isNotEmpty) {
        items = await fetchOrdersForUser(
          userId: userId,
          displayName: displayName,
          artistView: artistView,
        );
      }
      return items;
    });
  }

  Future<void> updateOrderStatus(String id, String nextStatus) async {
    if (!isAvailable) {
      return;
    }
    final doc = await _orders.doc(id).get();
    final data = doc.data();
    final completed = nextStatus.toLowerCase() == 'completed';
    await _orders.doc(id).set({
      'status': nextStatus,
      'statusLower': nextStatus.toLowerCase(),
      'paymentStatus': completed
          ? 'Released'
          : (data?['paymentStatus'] ?? 'Held'),
      'payoutStatus': completed
          ? 'Paid Out'
          : (data?['payoutStatus'] ?? 'Pending'),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _transactions.doc(id).set({
      'escrowStatus': completed ? 'released' : 'held',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (data != null) {
      final notifyUserId = (data['buyerId'] as String?) ?? '';
      final title = (data['artworkTitle'] as String?) ?? 'Order';
      if (notifyUserId.isNotEmpty) {
        await addNotification(
          userId: notifyUserId,
          title: 'Order update',
          body: '$title is now $nextStatus.',
        );
      }
    }
  }

  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String source = '',
    String conversationId = '',
    String commissionId = '',
  }) async {
    if (!isAvailable || userId.isEmpty) {
      return;
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _notifications.doc(id).set({
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'type': type,
      'source': source,
      'conversationId': conversationId,
      'commissionId': commissionId,
    });
  }

  Stream<List<NotificationItem>> watchNotifications(String userId) {
    if (!isAvailable || userId.isEmpty) {
      return Stream.value(const <NotificationItem>[]);
    }
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_notificationFromDoc).toList());
  }

  Stream<int> watchUnreadNotificationCount(String userId) {
    if (!isAvailable || userId.isEmpty) {
      return Stream.value(0);
    }
    return _notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAllNotificationsRead(String userId) async {
    if (!isAvailable || userId.isEmpty) {
      return;
    }
    final snapshot = await _notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    final batch = _resolvedFirestore.batch();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {'read': true}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> addReview({
    required String artistId,
    required String artistName,
    required int rating,
    required String comment,
    required String authorId,
  }) async {
    if (!isAvailable) {
      return;
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _reviews.doc(id).set({
      'id': id,
      'artistId': artistId,
      'artistName': artistName,
      'rating': rating,
      'comment': comment,
      'authorId': authorId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Review>> watchReviewsForArtist({
    required String artistId,
    required String artistName,
  }) {
    if (!isAvailable) {
      return Stream.value(const <Review>[]);
    }
    final withId = artistId.isNotEmpty
        ? _reviews.where('artistId', isEqualTo: artistId)
        : _reviews.where('artistName', isEqualTo: artistName);
    return withId.snapshots().map((snapshot) {
      final items = snapshot.docs.map(_reviewFromDoc).toList();
      items.sort((a, b) => b.id.compareTo(a.id));
      return items;
    });
  }

  Future<double> averageRating({
    required String artistId,
    required String artistName,
  }) async {
    if (!isAvailable) {
      return 0;
    }
    final reviews = await watchReviewsForArtist(
      artistId: artistId,
      artistName: artistName,
    ).first;
    if (reviews.isEmpty) {
      return 0;
    }
    final total = reviews.fold<int>(
      0,
      (runningTotal, item) => runningTotal + item.rating,
    );
    return total / reviews.length;
  }

  Future<List<Map<String, String>>> fetchChatContacts({
    required String currentUserId,
  }) async {
    if (!isAvailable) {
      return const <Map<String, String>>[];
    }
    final snapshot = await _users.get();
    return snapshot.docs.where((doc) => doc.id != currentUserId).map((doc) {
      final data = doc.data();
      final roleValue = (data['role'] as String?) ?? 'buyer';
      final role = roleValue == 'admin'
          ? 'Admin'
          : (roleValue == 'artist' ? 'Artist' : 'Buyer');
      return {
        'userId': doc.id,
        'displayName': (data['displayName'] as String?) ?? 'User',
        'role': role,
      };
    }).toList()..sort((a, b) => a['displayName']!.compareTo(b['displayName']!));
  }

  Future<Map<String, String>> fetchConversationStatusesForUser({
    required String userId,
    required bool artistView,
  }) async {
    if (!isAvailable) {
      return const <String, String>{};
    }
    final snapshot =
        await (artistView
                ? _commissions.where('artistId', isEqualTo: userId)
                : _commissions.where('clientId', isEqualTo: userId))
            .get();
    final map = <String, String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final conversationId = (data['conversationId'] as String?) ?? '';
      if (conversationId.isEmpty) {
        continue;
      }
      map[conversationId] = _conversationStatusLabel(
        (data['status'] as String?) ?? 'Pending',
      );
    }
    return map;
  }

  String _conversationStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed transaction';
      case 'rejected':
        return 'Request declined';
      case 'delivered':
        return 'Awaiting buyer confirmation';
      case 'pending':
        return 'Message request pending';
      default:
        return 'Ongoing commission';
    }
  }

  Artwork _artworkFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Artwork.fromJson({
      'id': doc.id,
      ...data,
      'avgRating': (data['avgRating'] as num?) ?? 0,
    });
  }

  Commission _commissionFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Commission.fromJson({'id': doc.id, ...data});
  }

  app_models.Order _orderFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return app_models.Order.fromJson({'id': doc.id, ...data});
  }

  NotificationItem _notificationFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];
    return NotificationItem(
      id: doc.id,
      title: (data['title'] as String?) ?? 'Notification',
      body: (data['body'] as String?) ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      read: (data['read'] as bool?) ?? false,
      type: (data['type'] as String?) ?? 'general',
      source: (data['source'] as String?) ?? '',
      conversationId: (data['conversationId'] as String?) ?? '',
      commissionId: (data['commissionId'] as String?) ?? '',
    );
  }

  Review _reviewFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Review.fromJson({'id': doc.id, ...data});
  }
}
