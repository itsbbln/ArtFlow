import 'package:flutter/material.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/admin_models.dart';
import '../widgets/admin_widgets.dart';
import 'user_management_screen.dart';
import 'artist_verification_screen.dart';
import 'scholar_verification_screen.dart';
import 'artwork_moderation_screen.dart';
import 'transaction_monitoring_screen.dart';
import 'dispute_management_screen.dart';
import 'analytics_screen.dart';
import 'platform_settings_screen.dart';
import '../../../shared/data/mock_seeder.dart';

/// Main Admin Dashboard Screen
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _adminRepository = AdminRepository();

  int _lastNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: MockSeeder.notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: MockSeeder.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = MockSeeder.notifications[index];
                    return ListTile(
                      leading: Icon(
                        notification.read
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color: notification.read ? Colors.grey : Colors.orange,
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.read
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.body),
                          Text(
                            notification.createdAt.toString().split('.')[0],
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Mark as read would require updating MockSeeder
                        // For now just close
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              MockSeeder.markAllNotificationsRead();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Mark all as read'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Control Panel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Show notifications (could be a dialog or navigate to notifications screen)
                  _showNotificationsDialog(context);
                },
              ),
              if (MockSeeder.unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${MockSeeder.unreadNotificationCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        elevation: 2,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: '📊 Dashboard'),
              Tab(text: '👥 Users'),
              Tab(text: '🎨 Artist Verify'),
              Tab(text: '🎓 Scholar Verify'),
              Tab(text: '🖼️ Moderation'),
              Tab(text: '💰 Transactions'),
              Tab(text: '⚖️ Disputes'),
              Tab(text: '📈 Analytics'),
              Tab(text: '⚙️ Settings'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          const UserManagementScreen(),
          const ArtistVerificationScreen(),
          const ScholarVerificationScreen(),
          const ArtworkModerationScreen(),
          const TransactionMonitoringScreen(),
          const DisputeManagementScreen(),
          const AnalyticsScreen(),
          const PlatformSettingsScreen(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return FutureBuilder<PlatformStats>(
      future: _adminRepository.getPlatformStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading stats: ${snapshot.error}'),
          );
        }

        final stats = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending verifications alert
              FutureBuilder<int>(
                future: _adminRepository.getPendingArtistApplicationsCount(),
                builder: (context, pendingSnapshot) {
                  if (pendingSnapshot.hasData && pendingSnapshot.data! > 0) {
                    final pendingCount = pendingSnapshot.data!;
                    
                    // Only add notification if the count has changed
                    if (pendingCount != _lastNotificationCount) {
                      _lastNotificationCount = pendingCount;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _showPendingVerificationNotification(pendingCount);
                        // Force rebuild to show the notification badge in AppBar
                        setState(() {});
                      });
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notification_important, color: Colors.orange, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '⚠️ ${pendingSnapshot.data} Pending Artist Application${pendingSnapshot.data! > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const Text(
                                  'Artists waiting for verification',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _tabController.animateTo(2),
                            child: const Text('Review', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Main metrics grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  DashboardMetricCard(
                    title: 'Total Users',
                    value: '${stats.totalUsers}',
                    icon: Icons.people,
                    iconColor: Colors.blue,
                    onTap: () => _tabController.animateTo(1),
                  ),
                  DashboardMetricCard(
                    title: 'Verified Artists',
                    value: '${stats.verifiedArtists}',
                    icon: Icons.verified,
                    iconColor: Colors.green,
                    onTap: () => _tabController.animateTo(2),
                  ),
                  DashboardMetricCard(
                    title: 'Transactions',
                    value: '${stats.totalTransactions}',
                    icon: Icons.receipt_long,
                    iconColor: Colors.purple,
                    onTap: () => _tabController.animateTo(4),
                  ),
                  DashboardMetricCard(
                    title: 'Active Auctions',
                    value: '${stats.activeAuctions}',
                    icon: Icons.gavel,
                    iconColor: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Revenue section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revenue Overview',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Revenue',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${stats.totalRevenue.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Platform Fee',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${stats.platformFeePercentage}%',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _tabController.animateTo(2),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Review Artists'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _tabController.animateTo(3),
                    icon: const Icon(Icons.flag),
                    label: const Text('Review Reports'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _tabController.animateTo(5),
                    icon: const Icon(Icons.warning),
                    label: const Text('Disputes'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _tabController.animateTo(6),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Analytics'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show notification when there are pending verifications
  void _showPendingVerificationNotification(int pendingCount) {
    // Add admin notification
    MockSeeder.addNotification(
      '🔔 Pending Verifications',
      '$pendingCount artists/users awaiting verification. Review in the Artist Verification tab.',
    );
  }
}
