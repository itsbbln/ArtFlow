/// Admin Dashboard Models and Entities

// Platform Statistics
class PlatformStats {
  final int totalUsers;
  final int verifiedArtists;
  final int totalTransactions;
  final int activeAuctions;
  final double totalRevenue;
  final double platformFeePercentage;

  PlatformStats({
    required this.totalUsers,
    required this.verifiedArtists,
    required this.totalTransactions,
    required this.activeAuctions,
    required this.totalRevenue,
    required this.platformFeePercentage,
  });
}

// User Management Models
class AdminUserInfo {
  final String userId;
  final String displayName;
  final String email;
  final UserAccountType accountType; // Buyer, Artist, Scholar (Verified/Pending)
  final DateTime registeredDate;
  final String status; // Active, Suspended, Banned
  final List<String> activityLog;
  final bool isVerified;
  final bool isScholarVerified;
  final bool scholarVerificationSubmitted;
  final int totalPurchases;
  final int totalListings;

  AdminUserInfo({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.accountType,
    required this.registeredDate,
    required this.status,
    required this.activityLog,
    required this.isVerified,
    required this.isScholarVerified,
    required this.scholarVerificationSubmitted,
    required this.totalPurchases,
    required this.totalListings,
  });
}

enum UserAccountType {
  buyer,
  artistPending,
  artistVerified,
  scholarPending,
  scholarVerified,
}

// Artist Verification Models
class ArtistVerificationApplication {
  final String applicationId;
  final String userId;
  final String displayName;
  final String email;
  final String bio;
  final String artStyle;
  final String medium;
  final String penName;
  final String portfolioUrl;
  final String additionalDetails;
  final List<String> sampleArtworks;
  final String identityVerificationUrl;
  final DateTime submittedDate;
  final ApplicationStatus status;

  ArtistVerificationApplication({
    required this.applicationId,
    required this.userId,
    required this.displayName,
    required this.email,
    required this.bio,
    required this.artStyle,
    required this.medium,
    required this.penName,
    required this.portfolioUrl,
    required this.additionalDetails,
    required this.sampleArtworks,
    required this.identityVerificationUrl,
    required this.submittedDate,
    required this.status,
  });
}

enum ApplicationStatus {
  pending,
  approved,
  rejected,
}

// Scholar Verification Models
class ScholarVerificationApplication {
  final String userId;
  final String displayName;
  final String email;
  final String schoolIdUrl;
  final DateTime submittedDate;
  final ApplicationStatus status;
  final String rejectionReason;

  ScholarVerificationApplication({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.schoolIdUrl,
    required this.submittedDate,
    required this.status,
    required this.rejectionReason,
  });
}

// Artwork Moderation Models
class ArtworkForModeration {
  final String artworkId;
  final String title;
  final String artistName;
  final String imageUrl;
  final DateTime uploadedDate;
  final List<String> reportedIssues; // Inappropriate content reasons
  final int reportCount;
  final ModerationStatus status;
  final String description;

  ArtworkForModeration({
    required this.artworkId,
    required this.title,
    required this.artistName,
    required this.imageUrl,
    required this.uploadedDate,
    required this.reportedIssues,
    required this.reportCount,
    required this.status,
    required this.description,
  });
}

enum ModerationStatus {
  pending,
  approved,
  hidden,
  removed,
}

// Transaction Monitoring Models
class TransactionRecord {
  final String transactionId;
  final String orderId;
  final String buyerName;
  final String sellerName;
  final double amount;
  final double platformFee;
  final DateTime transactionDate;
  final EscrowStatus escrowStatus;
  final String artworkTitle;

  TransactionRecord({
    required this.transactionId,
    required this.orderId,
    required this.buyerName,
    required this.sellerName,
    required this.amount,
    required this.platformFee,
    required this.transactionDate,
    required this.escrowStatus,
    required this.artworkTitle,
  });
}

enum EscrowStatus {
  held,
  released,
  disputed,
  refunded,
}

// Dispute Management Models
class DisputeCase {
  final String disputeId;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final String title;
  final String description;
  final List<String> chatHistory;
  final DateTime createdDate;
  final DisputeStatus status;
  final String resolution;

  DisputeCase({
    required this.disputeId,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.chatHistory,
    required this.createdDate,
    required this.status,
    required this.resolution,
  });
}

enum DisputeStatus {
  open,
  inReview,
  resolved,
  closed,
}

// Analytics Models
class SalesAnalytics {
  final List<SalesTrendPoint> salesTrend;
  final Map<String, int> categoryPopularity; // Category -> Count
  final List<TopArtist> topPerformingArtists;
  final List<BuyerActivity> buyerActivities;

  SalesAnalytics({
    required this.salesTrend,
    required this.categoryPopularity,
    required this.topPerformingArtists,
    required this.buyerActivities,
  });
}

class SalesTrendPoint {
  final DateTime date;
  final double amount;

  SalesTrendPoint({required this.date, required this.amount});
}

class TopArtist {
  final String artistId;
  final String artistName;
  final int totalSales;
  final double totalRevenue;

  TopArtist({
    required this.artistId,
    required this.artistName,
    required this.totalSales,
    required this.totalRevenue,
  });
}

class BuyerActivity {
  final String buyerId;
  final String buyerName;
  final int purchaseCount;
  final double totalSpent;
  final DateTime lastActivityDate;

  BuyerActivity({
    required this.buyerId,
    required this.buyerName,
    required this.purchaseCount,
    required this.totalSpent,
    required this.lastActivityDate,
  });
}

// Platform Settings Models
class PlatformSettings {
  final double platformFeePercentage;
  final List<ArtCategory> categories;
  final List<Region> regions;
  final bool notificationsEnabled;
  final String systemAnnouncement;

  PlatformSettings({
    required this.platformFeePercentage,
    required this.categories,
    required this.regions,
    required this.notificationsEnabled,
    required this.systemAnnouncement,
  });
}

class ArtCategory {
  final String id;
  final String name;
  final String style; // e.g., Digital, Traditional

  ArtCategory({required this.id, required this.name, required this.style});
}

class Region {
  final String id;
  final String name; // e.g., Bukidnon

  Region({required this.id, required this.name});
}
