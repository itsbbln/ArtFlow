import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../entities/models/artwork.dart';
import '../../entities/models/commission.dart';
import '../../entities/models/notification_item.dart';
import '../../entities/models/order.dart' as app_models;
import 'app_data_service.dart';

class AppDataState extends ChangeNotifier {
  AppDataState({AppDataService? service})
      : _service = service ?? AppDataService.instance;

  final AppDataService _service;
  StreamSubscription<List<Artwork>>? _artworkSubscription;
  StreamSubscription<List<Commission>>? _commissionSubscription;
  StreamSubscription<List<app_models.Order>>? _orderSubscription;
  StreamSubscription<List<NotificationItem>>? _notificationSubscription;

  List<Artwork> _artworks = const [];
  List<Commission> _commissions = const [];
  List<app_models.Order> _orders = const [];
  List<NotificationItem> _notifications = const [];

  List<Artwork> get artworks => _artworks;
  List<Commission> get commissions => _commissions;
  List<app_models.Order> get orders => _orders;
  List<NotificationItem> get notifications => _notifications;
  List<String> get categories => AppDataService.categories;

  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _artworkSubscription = _service.watchArtworks().listen((items) {
      _artworks = items;
      notifyListeners();
    });
  }

  Future<void> bindForUser({
    required String userId,
    required String displayName,
    required bool artistView,
  }) async {
    await _commissionSubscription?.cancel();
    await _orderSubscription?.cancel();
    await _notificationSubscription?.cancel();

    _commissions = await _service.fetchCommissionsForUser(
      userId: userId,
      displayName: displayName,
      artistView: artistView,
    );
    _orders = await _service.fetchOrdersForUser(
      userId: userId,
      displayName: displayName,
      artistView: artistView,
    );
    _notifications = userId.isEmpty
        ? const []
        : await _service.watchNotifications(userId).first;
    notifyListeners();

    if (userId.isEmpty) {
      return;
    }

    _notificationSubscription = _service.watchNotifications(userId).listen((items) {
      _notifications = items;
      notifyListeners();
    });
    _commissionSubscription = _service
        .watchCommissionsForUser(
          userId: userId,
          displayName: displayName,
          artistView: artistView,
        )
        .listen((items) {
          _commissions = items;
          notifyListeners();
        });
    _orderSubscription = _service
        .watchOrdersForUser(
          userId: userId,
          displayName: displayName,
          artistView: artistView,
        )
        .listen((items) {
          _orders = items;
          notifyListeners();
        });
  }

  int get unreadNotificationCount =>
      _notifications.where((item) => !item.read).length;

  int get totalInquiries => _artworks.fold<int>(
        0,
        (runningTotal, item) => runningTotal + item.inquiries,
      );

  int get totalViews => _artworks.fold<int>(
        0,
        (runningTotal, item) => runningTotal + item.views,
      );

  bool isSold(String artworkId) {
    final match =
        _artworks.where((item) => item.id == artworkId).toList().firstOrNull;
    return match?.sold ?? false;
  }

  bool isBoosted(String artworkId) {
    final match =
        _artworks.where((item) => item.id == artworkId).toList().firstOrNull;
    return match?.isFeatured ?? false;
  }

  Future<void> trackView(String artworkId) async {
    await _service.incrementArtworkView(artworkId);
  }

  Future<void> trackInquiry(Artwork artwork) async {
    await _service.incrementArtworkInquiry(artwork.id);
  }

  Future<void> markAllNotificationsRead(String userId) async {
    await _service.markAllNotificationsRead(userId);
  }

  Future<void> upsertArtwork(Artwork artwork) async {
    await _service.upsertArtwork(artwork);
  }

  Future<void> deleteArtwork(String id) async {
    await _service.deleteArtwork(id);
  }

  Future<void> toggleFeaturedBoost(String artworkId, bool enabled) async {
    final artwork = _artworks.where((item) => item.id == artworkId).toList().firstOrNull;
    if (artwork == null) {
      return;
    }
    await _service.upsertArtwork(
      Artwork(
        id: artwork.id,
        title: artwork.title,
        artistId: artwork.artistId,
        artistName: artwork.artistName,
        price: artwork.price,
        description: artwork.description,
        category: artwork.category,
        medium: artwork.medium,
        size: artwork.size,
        imageUrl: artwork.imageUrl,
        images: artwork.images,
        isFeatured: enabled,
        avgRating: artwork.avgRating,
        sold: artwork.sold,
        views: artwork.views,
        inquiries: artwork.inquiries,
      ),
    );
  }

  Future<void> markArtworkSold(String artworkId) async {
    await _service.markArtworkSold(artworkId);
  }

  Future<void> addCommission(Commission commission) async {
    await _service.createCommission(commission);
  }

  Future<void> updateCommissionStatus(String id, String nextStatus) async {
    await _service.updateCommissionStatus(id, nextStatus);
  }

  Future<void> addOrder(app_models.Order order) async {
    await _service.createOrder(order);
  }

  Future<void> updateOrderStatus(String id, String nextStatus) async {
    await _service.updateOrderStatus(id, nextStatus);
  }

  Future<void> addReview({
    required String artistId,
    required String artistName,
    required int rating,
    required String comment,
    required String authorId,
  }) async {
    await _service.addReview(
      artistId: artistId,
      artistName: artistName,
      rating: rating,
      comment: comment,
      authorId: authorId,
    );
  }

  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String source = '',
    String conversationId = '',
    String commissionId = '',
  }) {
    return _service.addNotification(
      userId: userId,
      title: title,
      body: body,
      type: type,
      source: source,
      conversationId: conversationId,
      commissionId: commissionId,
    );
  }

  Future<void> updateCommissionReminder(
    String commissionId, {
    required DateTime remindedAt,
  }) {
    return _service.updateCommissionReminder(
      commissionId,
      remindedAt: remindedAt,
    );
  }

  Future<double> averageRating({
    required String artistId,
    required String artistName,
  }) {
    return _service.averageRating(artistId: artistId, artistName: artistName);
  }

  Future<Map<String, String>> fetchConversationStatusesForUser({
    required String userId,
    required bool artistView,
  }) {
    return _service.fetchConversationStatusesForUser(
      userId: userId,
      artistView: artistView,
    );
  }

  Future<List<Map<String, String>>> fetchChatContacts({
    required String currentUserId,
  }) {
    return _service.fetchChatContacts(currentUserId: currentUserId);
  }

  @override
  void dispose() {
    _artworkSubscription?.cancel();
    _commissionSubscription?.cancel();
    _orderSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
