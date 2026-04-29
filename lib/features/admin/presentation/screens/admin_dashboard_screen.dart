import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/admin_models.dart';
import '../widgets/admin_widgets.dart';
import 'user_management_screen.dart';
import 'artist_verification_screen.dart';
import 'artwork_moderation_screen.dart';
import 'transaction_monitoring_screen.dart';
import 'dispute_management_screen.dart';
import 'analytics_screen.dart';
import 'platform_settings_screen.dart';
import '../../../auth/presentation/auth_state.dart';
import '../../../shared/data/app_data_state.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
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
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showPendingVerificationNotification(pendingSnapshot.data!);
                    });
                    
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
    final userId = context.read<AuthState>().currentUserId;
    if (userId == null) {
      return;
    }
    context.read<AppDataState>().addNotification(
          userId: userId,
          title: 'Pending Verifications',
          body:
              '$pendingCount artists/users awaiting verification. Review in the Artist Verification tab.',
        );
  }
}
