import '../../entities/models/artwork.dart';
import '../../entities/models/commission.dart';
import '../../entities/models/message_item.dart';
import '../../entities/models/notification_item.dart';
import '../../entities/models/order.dart';
import '../../entities/models/review.dart';

class ConversationPreview {
  ConversationPreview({
    required this.id,
    required this.otherName,
    required this.preview,
    required this.unread,
  });

  String id;
  String otherName;
  String preview;
  bool unread;
}

class MockSeeder {
  static const placeholder =
      'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=700&h=700&fit=crop';

  static final artworks = <Artwork>[
    Artwork(
      id: '1',
      title: 'Golden Dusk',
      artistName: 'Maria Reyes',
      price: 4200,
      category: 'painting',
      description: 'A warm sunset portrait inspired by Bukidnon valleys.',
      medium: 'Oil on canvas',
      size: '24x36 in',
      imageUrl: placeholder,
      images: [placeholder],
      isFeatured: true,
      avgRating: 4.8,
    ),
    Artwork(
      id: '2',
      title: 'Metro Pulse',
      artistName: 'Anton Cruz',
      price: 3200,
      category: 'digital',
      description: 'Contemporary neon strokes with urban geometry.',
      medium: 'Digital print',
      size: '18x24 in',
      imageUrl: placeholder,
      images: [placeholder],
      avgRating: 4.5,
    ),
    Artwork(
      id: '3',
      title: 'Quiet Harbor',
      artistName: 'Lian Santos',
      price: 5100,
      category: 'painting',
      description: 'Still-water harbor scene painted with muted palette.',
      medium: 'Acrylic',
      size: '20x30 in',
      imageUrl: placeholder,
      images: [placeholder],
      avgRating: 4.9,
    ),
    Artwork(
      id: '4',
      title: 'Digital Bloom',
      artistName: 'Noel Tan',
      price: 2900,
      category: 'mixed_media',
      description: 'A layered floral composition with hand-textured brushes.',
      medium: 'Mixed media',
      size: '16x20 in',
      imageUrl: placeholder,
      images: [placeholder],
      avgRating: 4.2,
    ),
  ];

  static final commissions = <Commission>[
    Commission(
      id: 'C100',
      title: 'Family portrait',
      status: 'Active',
      budget: 3000,
    ),
    Commission(
      id: 'C101',
      title: 'Album cover art',
      status: 'Completed',
      budget: 6000,
    ),
    Commission(
      id: 'C102',
      title: 'Character concept',
      status: 'In Review',
      budget: 2500,
    ),
  ];

  static final orders = <Order>[
    Order(id: '900', artworkId: '1', status: 'Delivered', total: 4200),
    Order(id: '901', artworkId: '3', status: 'Processing', total: 5100),
    Order(id: '902', artworkId: '4', status: 'Shipped', total: 2900),
  ];

  static final notifications = <NotificationItem>[
    NotificationItem(
      id: 'N0',
      title: '🔔 Pending Verifications',
      body: '2 artists awaiting verification. Review in the Admin Panel.',
      createdAt: DateTime(2026, 4, 15, 14, 45),
      read: false,
    ),
    NotificationItem(
      id: 'N1',
      title: 'Commission update',
      body: 'Family portrait moved to sketch phase.',
      createdAt: DateTime(2026, 4, 15, 9, 30),
      read: false,
    ),
    NotificationItem(
      id: 'N2',
      title: 'Order delivered',
      body: 'Order #900 has been delivered.',
      createdAt: DateTime(2026, 4, 14, 18, 20),
      read: true,
    ),
    NotificationItem(
      id: 'N3',
      title: 'New message',
      body: 'Anton Cruz sent a message.',
      createdAt: DateTime(2026, 4, 14, 8, 5),
      read: false,
    ),
  ];

  static final messages = <MessageItem>[
    MessageItem(
      id: 'M1',
      conversationId: '1',
      senderId: 'artist_1',
      text: 'Hi! I can start this weekend.',
      sentAt: DateTime(2026, 4, 12, 10, 10),
    ),
    MessageItem(
      id: 'M2',
      conversationId: '1',
      senderId: 'me',
      text: 'Great, sharing references now.',
      sentAt: DateTime(2026, 4, 12, 10, 12),
    ),
    MessageItem(
      id: 'M3',
      conversationId: '2',
      senderId: 'artist_2',
      text: 'Can you confirm preferred size?',
      sentAt: DateTime(2026, 4, 14, 8, 5),
    ),
  ];

  static final conversations = <ConversationPreview>[
    ConversationPreview(
      id: '1',
      otherName: 'Maria Reyes',
      preview: 'Great, sharing references now.',
      unread: true,
    ),
    ConversationPreview(
      id: '2',
      otherName: 'Anton Cruz',
      preview: 'Can you confirm preferred size?',
      unread: false,
    ),
  ];

  static final reviewsByArtist = <String, List<Review>>{
    'Maria Reyes': [
      Review(
        id: 'R1',
        rating: 5,
        comment: 'Great communication and output.',
        authorId: 'buyer_1',
      ),
    ],
    'Anton Cruz': [
      Review(
        id: 'R2',
        rating: 4,
        comment: 'Fast turnaround and quality artwork.',
        authorId: 'buyer_2',
      ),
    ],
  };

  static final featureBoostedArtworkIds = <String>{};
  static final soldArtworkIds = <String>{};
  static final analyticsViews = <String, int>{};
  static final analyticsInquiries = <String, int>{};
  static bool verifiedArtist = false;
  static bool extendedPortfolioPack = false;

  static List<String> get categories => const [
    'all',
    'painting',
    'digital',
    'crafts',
    'sculpture',
    'photography',
    'textile',
    'mixed_media',
  ];

  static int get unreadNotificationCount =>
      notifications.where((item) => !item.read).length;

  static int get totalInquiries =>
      analyticsInquiries.values.fold(0, (sum, value) => sum + value);

  static int get totalViews =>
      analyticsViews.values.fold(0, (sum, value) => sum + value);

  static void trackView(String artworkId) {
    analyticsViews[artworkId] = (analyticsViews[artworkId] ?? 0) + 1;
  }

  static void trackInquiry(String artistName) {
    analyticsInquiries[artistName] = (analyticsInquiries[artistName] ?? 0) + 1;
  }

  static ConversationPreview getOrCreateConversation(String name) {
    final match = conversations.where((item) => item.otherName == name).toList();
    if (match.isNotEmpty) {
      return match.first;
    }
    final id = 'conv_${name.toLowerCase().replaceAll(' ', '_')}';
    final created = ConversationPreview(
      id: id,
      otherName: name,
      preview: 'Start your conversation...',
      unread: false,
    );
    conversations.insert(0, created);
    return created;
  }

  static void addMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) {
    messages.add(
      MessageItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        sentAt: DateTime.now(),
      ),
    );
    final preview = conversations
        .where((item) => item.id == conversationId)
        .toList()
        .firstOrNull;
    if (preview != null) {
      preview.preview = text;
      preview.unread = senderId != 'me';
    }
  }

  static void markConversationRead(String conversationId) {
    final preview = conversations
        .where((item) => item.id == conversationId)
        .toList()
        .firstOrNull;
    if (preview != null) {
      preview.unread = false;
    }
  }

  static void addNotification(String title, String body) {
    notifications.insert(
      0,
      NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        createdAt: DateTime.now(),
        read: false,
      ),
    );
  }

  static void markAllNotificationsRead() {
    final updated = notifications
        .map(
          (item) => NotificationItem(
            id: item.id,
            title: item.title,
            body: item.body,
            createdAt: item.createdAt,
            read: true,
          ),
        )
        .toList();
    notifications
      ..clear()
      ..addAll(updated);
  }

  static void upsertArtwork(Artwork artwork) {
    final index = artworks.indexWhere((item) => item.id == artwork.id);
    if (index >= 0) {
      artworks[index] = artwork;
    } else {
      artworks.insert(0, artwork);
    }
  }

  static void deleteArtwork(String id) {
    artworks.removeWhere((item) => item.id == id);
  }

  static void toggleFeaturedBoost(String artworkId, bool enabled) {
    if (enabled) {
      featureBoostedArtworkIds.add(artworkId);
    } else {
      featureBoostedArtworkIds.remove(artworkId);
    }
  }

  static bool isBoosted(String artworkId) => featureBoostedArtworkIds.contains(
    artworkId,
  );

  static void markArtworkSold(String artworkId) {
    soldArtworkIds.add(artworkId);
    addNotification('Artwork sold', 'Artwork #$artworkId has been marked sold.');
  }

  static bool isSold(String artworkId) => soldArtworkIds.contains(artworkId);

  static void addCommission({
    required String title,
    required String brief,
    required double budget,
  }) {
    commissions.insert(
      0,
      Commission(
        id: 'C${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        status: 'Pending',
        budget: budget,
      ),
    );
    addNotification('Commission request', '$title submitted: $brief');
  }

  static void updateCommissionStatus(String id, String nextStatus) {
    final index = commissions.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final current = commissions[index];
    commissions[index] = Commission(
      id: current.id,
      title: current.title,
      status: nextStatus,
      budget: current.budget,
    );
    addNotification('Commission update', '${current.title} is now $nextStatus.');
  }

  static void addReview({
    required String artistName,
    required int rating,
    required String comment,
  }) {
    reviewsByArtist.putIfAbsent(artistName, () => []);
    reviewsByArtist[artistName]!.add(
      Review(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        rating: rating,
        comment: comment,
        authorId: 'me',
      ),
    );
  }

  static double averageRating(String artistName) {
    final reviews = reviewsByArtist[artistName];
    if (reviews == null || reviews.isEmpty) {
      return 0;
    }
    final total = reviews.fold<int>(0, (sum, item) => sum + item.rating);
    return total / reviews.length;
  }
}
