import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_shadows.dart';
import '../../core/theme/editorial_colors.dart';
import '../auth/presentation/auth_state.dart';
import '../shared/data/app_data_state.dart';
import 'screen_utils.dart';
import 'widgets/metric_summary_card.dart';
import 'widgets/order_status_chip.dart';

class ArtistDashboardScreen extends StatelessWidget {
  const ArtistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();
    final artistId = chatUserIdFor(auth);
    final commissions = data.commissions.where((item) {
      return item.artistId == artistId || item.artistName == auth.displayName;
    }).toList();
    final openCommissions = commissions.where((c) {
      final s = c.status.toLowerCase();
      return s == 'pending' ||
          s == 'accepted' ||
          s == 'sketch' ||
          s == 'in progress';
    }).length;
    final completedCommissions =
        commissions.where((c) => c.status.toLowerCase() == 'completed').length;
    final myArtworks = data.artworks.where((item) => item.artistName == auth.displayName).toList();
    final avgRating = myArtworks.isEmpty
        ? 0
        : myArtworks.fold<double>(
                0,
                (runningTotal, item) => runningTotal + item.avgRating,
              ) /
            myArtworks.length;
    final myArtworkIds = myArtworks.map((a) => a.id).toSet();
    final revenue = data.orders
        .where(
          (o) => o.artistId == artistId || myArtworkIds.contains(o.artworkId),
        )
        .fold<double>(0, (sum, item) => sum + item.total);
    final orderCount = data.orders
        .where(
          (o) => o.artistId == artistId || myArtworkIds.contains(o.artworkId),
        )
        .length;

    return ColoredBox(
      color: EditorialColors.pageCream,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Artist Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: EditorialColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Your studio at a glance',
            style: TextStyle(fontSize: 13, color: EditorialColors.muted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 160,
                child: MetricSummaryCard(label: 'Open Commissions', value: '$openCommissions'),
              ),
              SizedBox(
                width: 160,
                child: MetricSummaryCard(label: 'Completed', value: '$completedCommissions'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 160,
                child: MetricSummaryCard(label: 'Revenue', value: '\$${revenue.toStringAsFixed(0)}'),
              ),
              SizedBox(
                width: 160,
                child: MetricSummaryCard(
                  label: 'Rating',
                  value: avgRating == 0 ? '-' : avgRating.toStringAsFixed(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 160,
                child: MetricSummaryCard(label: 'Portfolio', value: '${myArtworks.length}'),
              ),
              SizedBox(
                width: 160,
                child: MetricSummaryCard(label: 'Orders', value: '$orderCount'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => context.push('/create'),
                style: FilledButton.styleFrom(
                  backgroundColor: EditorialColors.tribalRed,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Upload Artwork'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EditorialColors.tribalRed,
                  side: BorderSide(color: EditorialColors.tribalGold.withValues(alpha: 0.55)),
                ),
                icon: const Icon(Icons.grid_view_outlined),
                label: const Text('View Portfolio'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/commissions'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EditorialColors.charcoal,
                  side: const BorderSide(color: EditorialColors.border),
                ),
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('Manage Commissions'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Recent requests', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...commissions.take(3).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppShadows.card,
                ),
                child: Material(
                  color: Colors.white,
                  elevation: 0,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {},
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: Text(item.title),
                    subtitle: Text(
                      '${item.clientName.isEmpty ? 'Buyer request' : item.clientName} · Budget \$${item.budget.toStringAsFixed(0)}',
                    ),
                    trailing: orderStatusChip(item.status),
                  ),
                ),
              ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
