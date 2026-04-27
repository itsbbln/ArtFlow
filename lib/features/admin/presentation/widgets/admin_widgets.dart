import 'package:flutter/material.dart';

/// Dashboard summary card
class DashboardMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor ?? Colors.blue, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// User list item for admin management
class AdminUserListItem extends StatelessWidget {
  final String displayName;
  final String email;
  final String accountType;
  final String status;
  final VoidCallback onViewDetails;
  final VoidCallback onSuspend;
  final VoidCallback onBan;

  const AdminUserListItem({
    super.key,
    required this.displayName,
    required this.email,
    required this.accountType,
    required this.status,
    required this.onViewDetails,
    required this.onSuspend,
    required this.onBan,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'Active' ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(displayName),
        subtitle: Text(email),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('View Details'),
              onTap: onViewDetails,
            ),
            PopupMenuItem(
              child: const Text('Suspend'),
              onTap: onSuspend,
            ),
            PopupMenuItem(
              child: const Text('Ban'),
              onTap: onBan,
            ),
          ],
        ),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                accountType,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Artwork moderation item
class ArtworkModerationCard extends StatelessWidget {
  final String title;
  final String artistName;
  final String imageUrl;
  final int reportCount;
  final List<String> reportedIssues;
  final VoidCallback onApprove;
  final VoidCallback onHide;
  final VoidCallback onRemove;

  const ArtworkModerationCard({
    super.key,
    required this.title,
    required this.artistName,
    required this.imageUrl,
    required this.reportCount,
    required this.reportedIssues,
    required this.onApprove,
    required this.onHide,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            child: Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Artist: $artistName',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                if (reportCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Reports: $reportCount',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: reportedIssues
                        .map((issue) => Chip(
                              label: Text(issue),
                              labelStyle: const TextStyle(fontSize: 10),
                              backgroundColor: Colors.red.withOpacity(0.2),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton(
                      onPressed: onApprove,
                      child: const Text('Approve'),
                    ),
                    OutlinedButton(
                      onPressed: onHide,
                      child: const Text('Hide'),
                    ),
                    OutlinedButton(
                      onPressed: onRemove,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Transaction record item
class TransactionRecordCard extends StatelessWidget {
  final String orderId;
  final String buyerName;
  final String sellerName;
  final double amount;
  final double platformFee;
  final String escrowStatus;
  final String artworkTitle;

  const TransactionRecordCard({
    super.key,
    required this.orderId,
    required this.buyerName,
    required this.sellerName,
    required this.amount,
    required this.platformFee,
    required this.escrowStatus,
    required this.artworkTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(artworkTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Order #$orderId'),
            Text('$buyerName → $sellerName'),
            const SizedBox(height: 4),
            Text('Amount: \$${amount.toStringAsFixed(2)} | Fee: \$${platformFee.toStringAsFixed(2)}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getEscrowColor(escrowStatus),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            escrowStatus,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getEscrowColor(String status) {
    switch (status.toLowerCase()) {
      case 'held':
        return Colors.orange;
      case 'released':
        return Colors.green;
      case 'disputed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

/// Dispute case card
class DisputeCaseCard extends StatelessWidget {
  final String title;
  final String orderId;
  final String buyerName;
  final String sellerName;
  final String status;
  final VoidCallback onViewDetails;
  final VoidCallback onResolve;

  const DisputeCaseCard({
    super.key,
    required this.title,
    required this.orderId,
    required this.buyerName,
    required this.sellerName,
    required this.status,
    required this.onViewDetails,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Order #$orderId'),
            Text('$buyerName vs $sellerName'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: onViewDetails,
        isThreeLine: true,
      ),
    );
  }
}
