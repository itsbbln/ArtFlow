import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/admin_models.dart';

/// Repository for Admin operations
/// Handles all admin-related data operations
class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============ DASHBOARD ============
  /// Fetch platform statistics
  Future<PlatformStats> getPlatformStats() async {
    try {
      // Get user count
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      // Get verified artists count
      final artistsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'artist')
          .where('isVerified', isEqualTo: true)
          .get();
      final verifiedArtists = artistsSnapshot.docs.length;

      // Get transactions count (simulated)
      final transactionsSnapshot = await _firestore.collection('transactions').get();
      final totalTransactions = transactionsSnapshot.docs.length;

      // Get active auctions count
      final auctionsSnapshot = await _firestore
          .collection('artworks')
          .where('status', isEqualTo: 'active')
          .get();
      final activeAuctions = auctionsSnapshot.docs.length;

      // Calculate total revenue from transactions
      double totalRevenue = 0;
      for (final doc in transactionsSnapshot.docs) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        totalRevenue += amount;
      }

      const platformFeePercentage = 5.0; // Default 5%

      return PlatformStats(
        totalUsers: totalUsers,
        verifiedArtists: verifiedArtists,
        totalTransactions: totalTransactions,
        activeAuctions: activeAuctions,
        totalRevenue: totalRevenue,
        platformFeePercentage: platformFeePercentage,
      );
    } catch (e) {
      throw Exception('Failed to fetch platform stats: $e');
    }
  }

  /// Get count of pending artist applications
  Future<int> getPendingArtistApplicationsCount() async {
    try {
      final snapshot = await _firestore
          .collection('artistApplications')
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // ============ USER MANAGEMENT ============
  /// Stream of all users for admin viewing
  Stream<List<AdminUserInfo>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final role = data['role'] as String?;
        final isVerified = data['isVerified'] as bool? ?? false;
        final isScholarVerified = data['isScholarVerified'] as bool? ?? false;
        final scholarVerificationSubmitted = data['scholarVerificationSubmitted'] as bool? ?? false;

        UserAccountType accountType;
        if (role == 'artist') {
          accountType = isVerified ? UserAccountType.artistVerified : UserAccountType.artistPending;
        } else if (scholarVerificationSubmitted || isScholarVerified) {
          accountType = isScholarVerified ? UserAccountType.scholarVerified : UserAccountType.scholarPending;
        } else {
          accountType = UserAccountType.buyer;
        }

        return AdminUserInfo(
          userId: doc.id,
          displayName: data['displayName'] as String? ?? 'Unknown',
          email: data['email'] as String? ?? '',
          accountType: accountType,
          registeredDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] as String? ?? 'Active',
          activityLog: List<String>.from(data['activityLog'] as List? ?? []),
          isVerified: isVerified,
          isScholarVerified: isScholarVerified,
          scholarVerificationSubmitted: scholarVerificationSubmitted,
          totalPurchases: (data['totalPurchases'] as num?)?.toInt() ?? 0,
          totalListings: (data['totalListings'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    });
  }

  /// Get specific user details
  Future<AdminUserInfo?> getUserDetails(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final role = data['role'] as String?;
      final isVerified = data['isVerified'] as bool? ?? false;
      final isScholarVerified = data['isScholarVerified'] as bool? ?? false;
      final scholarVerificationSubmitted = data['scholarVerificationSubmitted'] as bool? ?? false;

      UserAccountType accountType;
      if (role == 'artist') {
        accountType = isVerified ? UserAccountType.artistVerified : UserAccountType.artistPending;
      } else if (scholarVerificationSubmitted || isScholarVerified) {
        accountType = isScholarVerified ? UserAccountType.scholarVerified : UserAccountType.scholarPending;
      } else {
        accountType = UserAccountType.buyer;
      }

      return AdminUserInfo(
        userId: doc.id,
        displayName: data['displayName'] as String? ?? 'Unknown',
        email: data['email'] as String? ?? '',
        accountType: accountType,
        registeredDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] as String? ?? 'Active',
        activityLog: List<String>.from(data['activityLog'] as List? ?? []),
        isVerified: isVerified,
        isScholarVerified: isScholarVerified,
        scholarVerificationSubmitted: scholarVerificationSubmitted,
        totalPurchases: (data['totalPurchases'] as num?)?.toInt() ?? 0,
        totalListings: (data['totalListings'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to fetch user details: $e');
    }
  }

  /// Suspend a user
  Future<void> suspendUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'Suspended',
      'suspendedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ban a user
  Future<void> banUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'Banned',
      'bannedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reactivate a suspended/banned user
  Future<void> reactivateUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'Active',
      'reactivatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ ARTIST VERIFICATION ============
  /// Get pending artist applications
  Stream<List<ArtistVerificationApplication>> getPendingApplications() {
    return _firestore
        .collection('artistApplications')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ArtistVerificationApplication(
          applicationId: doc.id,
          userId: data['userId'] as String? ?? '',
          displayName: data['displayName'] as String? ?? '',
          email: data['email'] as String? ?? '',
          bio: data['bio'] as String? ?? '',
          artStyle: data['artStyle'] as String? ?? '',
          medium: data['medium'] as String? ?? '',
          sampleArtworks: List<String>.from(data['sampleArtworks'] as List? ?? []),
          identityVerificationUrl: data['identityVerification'] as String? ?? '',
          submittedDate: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: ApplicationStatus.pending,
        );
      }).toList();
    });
  }

  /// Approve artist application
  Future<void> approveArtistApplication(String applicationId, String userId) async {
    await Future.wait([
      _firestore.collection('artistApplications').doc(applicationId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      }),
      _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      }),
    ]);
  }

  /// Reject artist application with feedback
  Future<void> rejectArtistApplication(
    String applicationId,
    String userId,
    String rejectionReason,
  ) async {
    await _firestore.collection('artistApplications').doc(applicationId).update({
      'status': 'rejected',
      'rejectionReason': rejectionReason,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ SCHOLAR VERIFICATION ============
  /// Stream of pending scholar verification applications
  Stream<List<ScholarVerificationApplication>> getPendingScholarApplications() {
    return _firestore
        .collection('users')
        .where('scholarVerificationSubmitted', isEqualTo: true)
        .where('isScholarVerified', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ScholarVerificationApplication(
          userId: doc.id,
          displayName: data['displayName'] as String? ?? 'Unknown',
          email: data['email'] as String? ?? '',
          schoolIdUrl: data['schoolIdUrl'] as String? ?? '',
          submittedDate: (data['scholarSubmittedAt'] as Timestamp?)?.toDate() ??
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: ApplicationStatus.pending,
          rejectionReason: data['scholarRejectionReason'] as String? ?? '',
        );
      }).toList();
    });
  }

  /// Approve scholar verification application
  Future<void> approveScholarApplication(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isScholarVerified': true,
      'scholarVerificationSubmitted': false,
      'scholarVerifiedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject scholar verification application
  Future<void> rejectScholarApplication(String userId, String rejectionReason) async {
    await _firestore.collection('users').doc(userId).update({
      'isScholarVerified': false,
      'scholarVerificationSubmitted': false,
      'scholarRejectionReason': rejectionReason,
      'scholarRejectedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ ARTWORK MODERATION ============
  /// Stream of all artworks for moderation
  Stream<List<ArtworkForModeration>> getAllArtworks() {
    return _firestore.collection('artworks').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final status = _parseModerationStatus(data['moderationStatus'] as String?);

        return ArtworkForModeration(
          artworkId: doc.id,
          title: data['title'] as String? ?? 'Unknown',
          artistName: data['artistName'] as String? ?? 'Unknown',
          imageUrl: data['imageUrl'] as String? ?? '',
          uploadedDate: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          reportedIssues: List<String>.from(data['reportedIssues'] as List? ?? []),
          reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
          status: status,
          description: data['description'] as String? ?? '',
        );
      }).toList();
    });
  }

  /// Get flagged artworks
  Stream<List<ArtworkForModeration>> getFlaggedArtworks() {
    return _firestore
        .collection('artworks')
        .where('reportCount', isGreaterThan: 0)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final status = _parseModerationStatus(data['moderationStatus'] as String?);

        return ArtworkForModeration(
          artworkId: doc.id,
          title: data['title'] as String? ?? 'Unknown',
          artistName: data['artistName'] as String? ?? 'Unknown',
          imageUrl: data['imageUrl'] as String? ?? '',
          uploadedDate: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          reportedIssues: List<String>.from(data['reportedIssues'] as List? ?? []),
          reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
          status: status,
          description: data['description'] as String? ?? '',
        );
      }).toList();
    });
  }

  /// Hide artwork (remove from public view)
  Future<void> hideArtwork(String artworkId) async {
    await _firestore.collection('artworks').doc(artworkId).update({
      'moderationStatus': 'hidden',
      'hiddenAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove artwork permanently
  Future<void> removeArtwork(String artworkId) async {
    await _firestore.collection('artworks').doc(artworkId).update({
      'moderationStatus': 'removed',
      'removedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Approve artwork
  Future<void> approveArtwork(String artworkId) async {
    await _firestore.collection('artworks').doc(artworkId).update({
      'moderationStatus': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ TRANSACTION MONITORING ============
  /// Stream of all transactions
  Stream<List<TransactionRecord>> getAllTransactions() {
    return _firestore.collection('transactions').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final escrowStatus = _parseEscrowStatus(data['escrowStatus'] as String?);

        return TransactionRecord(
          transactionId: doc.id,
          orderId: data['orderId'] as String? ?? '',
          buyerName: data['buyerName'] as String? ?? 'Unknown',
          sellerName: data['sellerName'] as String? ?? 'Unknown',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          platformFee: (data['platformFee'] as num?)?.toDouble() ?? 0,
          transactionDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          escrowStatus: escrowStatus,
          artworkTitle: data['artworkTitle'] as String? ?? 'Unknown',
        );
      }).toList();
    });
  }

  // ============ DISPUTE MANAGEMENT ============
  /// Stream of all disputes
  Stream<List<DisputeCase>> getAllDisputes() {
    return _firestore.collection('disputes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final status = _parseDisputeStatus(data['status'] as String?);

        return DisputeCase(
          disputeId: doc.id,
          orderId: data['orderId'] as String? ?? '',
          buyerId: data['buyerId'] as String? ?? '',
          sellerId: data['sellerId'] as String? ?? '',
          title: data['title'] as String? ?? 'Unknown',
          description: data['description'] as String? ?? '',
          chatHistory: List<String>.from(data['chatHistory'] as List? ?? []),
          createdDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: status,
          resolution: data['resolution'] as String? ?? '',
        );
      }).toList();
    });
  }

  /// Resolve a dispute
  Future<void> resolveDispute(String disputeId, String resolution) async {
    await _firestore.collection('disputes').doc(disputeId).update({
      'status': 'resolved',
      'resolution': resolution,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark dispute as completed
  Future<void> closeDispute(String disputeId) async {
    await _firestore.collection('disputes').doc(disputeId).update({
      'status': 'closed',
      'closedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ ANALYTICS ============
  /// Get sales analytics
  Future<SalesAnalytics> getSalesAnalytics() async {
    try {
      // Fetch transactions for trend
      final transactionSnapshot = await _firestore.collection('transactions').get();
      final salesTrend = transactionSnapshot.docs
          .map((doc) {
            final data = doc.data();
            return SalesTrendPoint(
              date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              amount: (data['amount'] as num?)?.toDouble() ?? 0,
            );
          })
          .toList();

      // Category popularity (simulated)
      final categoryMap = <String, int>{
        'Digital': 45,
        'Traditional': 32,
        'Photography': 28,
        'Sculpture': 15,
      };

      // Top performing artists (simulated)
      final topArtists = [
        TopArtist(
          artistId: 'artist1',
          artistName: 'Alex Rivera',
          totalSales: 150,
          totalRevenue: 5000,
        ),
        TopArtist(
          artistId: 'artist2',
          artistName: 'Maya Chen',
          totalSales: 120,
          totalRevenue: 4200,
        ),
        TopArtist(
          artistId: 'artist3',
          artistName: 'Jordan Smith',
          totalSales: 98,
          totalRevenue: 3500,
        ),
      ];

      // Buyer activities (simulated)
      final buyerActivities = [
        BuyerActivity(
          buyerId: 'buyer1',
          buyerName: 'Emma Wilson',
          purchaseCount: 25,
          totalSpent: 3200,
          lastActivityDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
        BuyerActivity(
          buyerId: 'buyer2',
          buyerName: 'David Johnson',
          purchaseCount: 18,
          totalSpent: 2100,
          lastActivityDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];

      return SalesAnalytics(
        salesTrend: salesTrend,
        categoryPopularity: categoryMap,
        topPerformingArtists: topArtists,
        buyerActivities: buyerActivities,
      );
    } catch (e) {
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  // ============ PLATFORM SETTINGS ============
  /// Get platform settings
  Future<PlatformSettings> getPlatformSettings() async {
    try {
      final doc = await _firestore.collection('platformSettings').doc('main').get();

      if (!doc.exists) {
        return _getDefaultSettings();
      }

      final data = doc.data()!;
      const platformFeePercentage = 5.0; // Default 5%

      final categories = [
        ArtCategory(id: 'digital', name: 'Digital Art', style: 'Digital'),
        ArtCategory(id: 'traditional', name: 'Traditional Art', style: 'Traditional'),
        ArtCategory(id: 'photography', name: 'Photography', style: 'Photography'),
        ArtCategory(id: 'sculpture', name: 'Sculpture', style: 'Sculpture'),
      ];

      final regions = [
        Region(id: 'bukidnon', name: 'Bukidnon'),
        Region(id: 'manila', name: 'Manila'),
        Region(id: 'cebu', name: 'Cebu'),
        Region(id: 'davao', name: 'Davao'),
      ];

      return PlatformSettings(
        platformFeePercentage: (data['feePercentage'] as num?)?.toDouble() ?? platformFeePercentage,
        categories: categories,
        regions: regions,
        notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
        systemAnnouncement: data['announcement'] as String? ?? '',
      );
    } catch (e) {
      return _getDefaultSettings();
    }
  }

  /// Update platform fee percentage
  Future<void> updatePlatformFee(double percentage) async {
    await _firestore.collection('platformSettings').doc('main').update({
      'feePercentage': percentage,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update system announcement
  Future<void> updateSystemAnnouncement(String announcement) async {
    await _firestore.collection('platformSettings').doc('main').update({
      'announcement': announcement,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle notifications
  Future<void> toggleNotifications(bool enabled) async {
    await _firestore.collection('platformSettings').doc('main').update({
      'notificationsEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ HELPER METHODS ============
  ModerationStatus _parseModerationStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return ModerationStatus.pending;
      case 'approved':
        return ModerationStatus.approved;
      case 'hidden':
        return ModerationStatus.hidden;
      case 'removed':
        return ModerationStatus.removed;
      default:
        return ModerationStatus.pending;
    }
  }

  EscrowStatus _parseEscrowStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'held':
        return EscrowStatus.held;
      case 'released':
        return EscrowStatus.released;
      case 'disputed':
        return EscrowStatus.disputed;
      case 'refunded':
        return EscrowStatus.refunded;
      default:
        return EscrowStatus.held;
    }
  }

  DisputeStatus _parseDisputeStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return DisputeStatus.open;
      case 'inreview':
        return DisputeStatus.inReview;
      case 'resolved':
        return DisputeStatus.resolved;
      case 'closed':
        return DisputeStatus.closed;
      default:
        return DisputeStatus.open;
    }
  }

  PlatformSettings _getDefaultSettings() {
    return PlatformSettings(
      platformFeePercentage: 5.0,
      categories: [
        ArtCategory(id: 'digital', name: 'Digital Art', style: 'Digital'),
        ArtCategory(id: 'traditional', name: 'Traditional Art', style: 'Traditional'),
        ArtCategory(id: 'photography', name: 'Photography', style: 'Photography'),
        ArtCategory(id: 'sculpture', name: 'Sculpture', style: 'Sculpture'),
      ],
      regions: [
        Region(id: 'bukidnon', name: 'Bukidnon'),
        Region(id: 'manila', name: 'Manila'),
        Region(id: 'cebu', name: 'Cebu'),
        Region(id: 'davao', name: 'Davao'),
      ],
      notificationsEnabled: true,
      systemAnnouncement: '',
    );
  }
}
