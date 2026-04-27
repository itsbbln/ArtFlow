import 'package:flutter/material.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/admin_models.dart';

/// Analytics and Reports Screen
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _adminRepository = AdminRepository();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SalesAnalytics>(
      future: _adminRepository.getSalesAnalytics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final analytics = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sales trend chart (simplified)
              _buildSectionTitle(context, '📈 Sales Trend'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ...analytics.salesTrend
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key;
                            final point = entry.value;
                            return ListTile(
                              title: Text(point.date.toString().split(' ')[0]),
                              trailing: Text(
                                '\$${point.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              visualDensity: VisualDensity.compact,
                            );
                          })
                          .take(10)
                          .toList(),
                      if (analytics.salesTrend.length > 10)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '... and ${analytics.salesTrend.length - 10} more',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Category popularity
              _buildSectionTitle(context, '🎨 Category Popularity'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: analytics.categoryPopularity.entries
                        .map((entry) {
                          final maxCount = analytics.categoryPopularity.values.reduce((a, b) => a > b ? a : b);
                          final percentage = (entry.value / maxCount * 100).toStringAsFixed(1);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key),
                                    Text(
                                      '${entry.value}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: entry.value / maxCount,
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Top performing artists
              _buildSectionTitle(context, '⭐ Top Performing Artists'),
              Card(
                child: Column(
                  children: analytics.topPerformingArtists
                      .asMap()
                      .entries
                      .map((entry) {
                        final index = entry.key;
                        final artist = entry.value;
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(artist.artistName),
                          subtitle: Text('${artist.totalSales} sales • \$${artist.totalRevenue.toStringAsFixed(2)}'),
                          trailing: const Icon(Icons.trending_up, color: Colors.green),
                        );
                      })
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              // Buyer activities
              _buildSectionTitle(context, '🛍️ Active Buyers'),
              Card(
                child: Column(
                  children: analytics.buyerActivities
                      .map((activity) {
                        return ListTile(
                          title: Text(activity.buyerName),
                          subtitle: Text(
                            '${activity.purchaseCount} purchases • Last active: ${activity.lastActivityDate.toString().split(' ')[0]}',
                          ),
                          trailing: Text(
                            '\$${activity.totalSpent.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
