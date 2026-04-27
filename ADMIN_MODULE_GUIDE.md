# Admin Module Documentation

## Overview

The Admin Module is a comprehensive platform control panel for ArtFlow administrators. It provides complete oversight of the entire ecosystem including users, artists, artworks, transactions, disputes, and platform analytics.

## Module Structure

```
lib/features/admin/
├── admin.dart (barrel export)
├── data/
│   └── repositories/
│       └── admin_repository.dart
├── domain/
│   └── models/
│       └── admin_models.dart
└── presentation/
    ├── screens/
    │   ├── admin_dashboard_screen.dart
    │   ├── user_management_screen.dart
    │   ├── artist_verification_screen.dart
    │   ├── artwork_moderation_screen.dart
    │   ├── transaction_monitoring_screen.dart
    │   ├── dispute_management_screen.dart
    │   ├── analytics_screen.dart
    │   └── platform_settings_screen.dart
    └── widgets/
        └── admin_widgets.dart
```

## Core Features

### 1. 📊 Dashboard
**Location**: `AdminDashboardScreen`

Main overview displaying:
- Total users count
- Verified artists count
- Total transactions
- Active auctions
- Revenue analytics with platform fee percentage
- Quick action buttons to navigate to key features

### 2. 👥 User Management
**Location**: `UserManagementScreen`

Features:
- View all users (Buyers, Artists - Verified/Pending)
- Filter by account type
- View detailed user information
- See purchase/listing history
- Suspend/Ban users
- Reactivate suspended/banned users

### 3. 🎨 Artist Verification
**Location**: `ArtistVerificationScreen`

Workflow:
- Review pending artist applications
- View portfolio samples
- Check identity verification documents
- Review artist bio and details
- Approve applications (makes them verified artists)
- Reject with feedback

### 4. 🖼️ Artwork Moderation
**Location**: `ArtworkModerationScreen`

Controls:
- View all artworks
- Filter by moderation status
- See reported issues and count
- Review flagged content
- Approve artworks
- Hide artworks (remove from public view)
- Remove artworks permanently

### 5. 💰 Transaction Monitoring
**Location**: `TransactionMonitoringScreen`

Capabilities:
- View all transactions
- Track order information
- Monitor escrow status (Held, Released, Disputed, Refunded)
- Filter by escrow status
- View transaction summary (total amount, fees)
- Check platform revenue

### 6. ⚖️ Dispute Management
**Location**: `DisputeManagementScreen`

Handles:
- View all disputes
- Filter by status (Open, In Review, Resolved, Closed)
- Review dispute details and chat history
- View order information
- Resolve disputes with detailed resolution notes
- Mark disputes as completed

### 7. 📈 Analytics & Reports
**Location**: `AnalyticsScreen`

Provides:
- Sales trend data
- Category popularity analysis
- Top-performing artists with revenue
- Active buyer metrics
- Historical sales data

### 8. ⚙️ Platform Settings
**Location**: `PlatformSettingsScreen`

Configuration:
- Manage platform fee percentage
- Add/edit art categories
- Manage regions (e.g., Bukidnon, Manila, Cebu)
- Control system notifications
- Publish system announcements

## Data Models

### Admin Models (`admin_models.dart`)

#### PlatformStats
Dashboard statistics for platform overview.

```dart
PlatformStats(
  totalUsers: 1500,
  verifiedArtists: 250,
  totalTransactions: 5000,
  activeAuctions: 45,
  totalRevenue: 125000.00,
  platformFeePercentage: 5.0,
)
```

#### AdminUserInfo
Complete user profile for admin viewing.

```dart
AdminUserInfo(
  userId: 'user123',
  displayName: 'John Doe',
  email: 'john@example.com',
  accountType: UserAccountType.artistVerified,
  registeredDate: DateTime.now(),
  status: 'Active',
  activityLog: [...],
  isVerified: true,
  totalPurchases: 15,
  totalListings: 8,
)
```

#### ArtistVerificationApplication
Artist application with portfolio and identity verification.

```dart
ArtistVerificationApplication(
  applicationId: 'app123',
  userId: 'user123',
  displayName: 'Artist Name',
  bio: 'Artist biography...',
  artStyle: 'Digital Art',
  medium: 'Digital Painting',
  sampleArtworks: ['url1', 'url2', ...],
  identityVerificationUrl: 'document_url',
  submittedDate: DateTime.now(),
  status: ApplicationStatus.pending,
)
```

#### ArtworkForModeration
Artwork requiring review.

```dart
ArtworkForModeration(
  artworkId: 'art123',
  title: 'Sunset Over Mountains',
  artistName: 'Artist Name',
  imageUrl: 'image_url',
  uploadedDate: DateTime.now(),
  reportedIssues: ['Inappropriate content', 'Copyright concern'],
  reportCount: 3,
  status: ModerationStatus.pending,
  description: 'Artwork description...',
)
```

#### TransactionRecord
Complete transaction information.

```dart
TransactionRecord(
  transactionId: 'txn123',
  orderId: 'order123',
  buyerName: 'Buyer Name',
  sellerName: 'Seller Name',
  amount: 100.00,
  platformFee: 5.00,
  transactionDate: DateTime.now(),
  escrowStatus: EscrowStatus.held,
  artworkTitle: 'Art Title',
)
```

#### DisputeCase
Dispute with resolution workflow.

```dart
DisputeCase(
  disputeId: 'disp123',
  orderId: 'order123',
  buyerId: 'buyer123',
  sellerId: 'seller123',
  title: 'Dispute Title',
  description: 'Detailed issue description...',
  chatHistory: [...],
  createdDate: DateTime.now(),
  status: DisputeStatus.open,
  resolution: 'Resolution details...',
)
```

## Repository Methods

### AdminRepository (`admin_repository.dart`)

#### Dashboard
- `getPlatformStats()` - Fetch platform statistics

#### User Management
- `getAllUsers()` - Stream of all users
- `getUserDetails(userId)` - Get specific user
- `suspendUser(userId)` - Suspend user account
- `banUser(userId)` - Ban user permanently
- `reactivateUser(userId)` - Reactivate suspended user

#### Artist Verification
- `getPendingApplications()` - Stream pending artist apps
- `approveArtistApplication(appId, userId)` - Approve artist
- `rejectArtistApplication(appId, userId, reason)` - Reject with feedback

#### Artwork Moderation
- `getAllArtworks()` - Stream all artworks
- `getFlaggedArtworks()` - Stream flagged/reported artworks
- `approveArtwork(artworkId)` - Approve artwork
- `hideArtwork(artworkId)` - Hide from public view
- `removeArtwork(artworkId)` - Remove permanently

#### Transaction Monitoring
- `getAllTransactions()` - Stream all transactions

#### Dispute Management
- `getAllDisputes()` - Stream all disputes
- `resolveDispute(disputeId, resolution)` - Resolve with notes
- `closeDispute(disputeId)` - Mark as closed

#### Analytics
- `getSalesAnalytics()` - Fetch comprehensive analytics

#### Platform Settings
- `getPlatformSettings()` - Get all settings
- `updatePlatformFee(percentage)` - Update commission fee
- `updateSystemAnnouncement(text)` - Post announcement
- `toggleNotifications(enabled)` - Enable/disable notifications

## Usage Example

```dart
import 'package:artflow/features/admin/admin.dart';

// Create repository
final adminRepo = AdminRepository();

// Fetch platform stats
final stats = await adminRepo.getPlatformStats();
print('Total users: ${stats.totalUsers}');

// Stream users
adminRepo.getAllUsers().listen((users) {
  // Update UI with users list
});

// Approve artist application
await adminRepo.approveArtistApplication('appId', 'userId');

// Monitor transactions
adminRepo.getAllTransactions().listen((transactions) {
  // Track transaction data
});
```

## Enums

### UserAccountType
- `buyer` - Regular buyer account
- `artistPending` - Artist awaiting verification
- `artistVerified` - Verified artist account

### ApplicationStatus
- `pending` - Awaiting review
- `approved` - Application accepted
- `rejected` - Application denied

### ModerationStatus
- `pending` - Awaiting review
- `approved` - Content approved
- `hidden` - Hidden from public view
- `removed` - Permanently removed

### EscrowStatus
- `held` - Funds in escrow
- `released` - Released to seller
- `disputed` - Under dispute
- `refunded` - Refunded to buyer

### DisputeStatus
- `open` - New dispute
- `inReview` - Under admin review
- `resolved` - Resolution provided
- `closed` - Case closed

## Key Differences from Previous Admin Implementation

✅ **Removed**:
- Artist-specific data (artworks count, portfolios)
- School tier benefits information
- Mixed artist and admin functionality

✅ **Added**:
- Dedicated platform control features
- Comprehensive user management
- Complete moderation system
- Analytics and reporting
- Settings management
- Proper separation of concerns

## Notes

1. All artist verification and management happens in dedicated screens
2. Artist data is not mixed with admin operations
3. Platform settings are now centralized
4. Transaction monitoring is separate from dispute management
5. Analytics are comprehensive and platform-focused

## Future Enhancements

- Real-time notifications for new applications/disputes
- Advanced analytics with charts and graphs
- Batch operations for user management
- Automated moderation rules
- Admin activity logging and audit trails
- Role-based admin permissions
