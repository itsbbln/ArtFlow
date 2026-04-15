import '../../entities/models/artwork.dart';
import '../../entities/models/commission.dart';
import '../../entities/models/message_item.dart';
import '../../entities/models/notification_item.dart';
import '../../entities/models/order.dart';

class ConversationPreview {
  const ConversationPreview({
    required this.id,
    required this.otherName,
    required this.preview,
    required this.unread,
  });

  final String id;
  final String otherName;
  final String preview;
  final bool unread;
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
    const ConversationPreview(
      id: '1',
      otherName: 'Maria Reyes',
      preview: 'Great, sharing references now.',
      unread: true,
    ),
    const ConversationPreview(
      id: '2',
      otherName: 'Anton Cruz',
      preview: 'Can you confirm preferred size?',
      unread: false,
    ),
  ];

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
}
