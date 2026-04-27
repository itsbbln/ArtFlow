import 'package:flutter/material.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/admin_models.dart';
import '../widgets/admin_widgets.dart';

/// Dispute Management Screen
class DisputeManagementScreen extends StatefulWidget {
  const DisputeManagementScreen({super.key});

  @override
  State<DisputeManagementScreen> createState() => _DisputeManagementScreenState();
}

class _DisputeManagementScreenState extends State<DisputeManagementScreen> {
  final _adminRepository = AdminRepository();
  String _filterStatus = 'Open'; // Open, In Review, Resolved, Closed

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Open'),
                const SizedBox(width: 8),
                _buildFilterChip('In Review'),
                const SizedBox(width: 8),
                _buildFilterChip('Resolved'),
                const SizedBox(width: 8),
                _buildFilterChip('Closed'),
              ],
            ),
          ),
        ),
        // Disputes list
        Expanded(
          child: StreamBuilder<List<DisputeCase>>(
            stream: _adminRepository.getAllDisputes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              var disputes = snapshot.data ?? [];

              // Apply filter
              disputes = disputes
                  .where((d) => _getDisputeStatusText(d.status) == _filterStatus)
                  .toList();

              if (disputes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green[300],
                      ),
                      const SizedBox(height: 12),
                      Text('No $_filterStatus disputes'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: disputes.length,
                itemBuilder: (context, index) {
                  final dispute = disputes[index];
                  return DisputeCaseCard(
                    title: dispute.title,
                    orderId: dispute.orderId,
                    buyerName: dispute.buyerId,
                    sellerName: dispute.sellerId,
                    status: _getDisputeStatusText(dispute.status),
                    onViewDetails: () => _showDisputeDetailsDialog(context, dispute),
                    onResolve: () => _showResolveDialog(context, dispute.disputeId),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _filterStatus == label,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? label : 'Open';
        });
      },
    );
  }

  void _showDisputeDetailsDialog(BuildContext context, DisputeCase dispute) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dispute.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Order ID:', dispute.orderId),
              _buildDetailRow('Buyer ID:', dispute.buyerId),
              _buildDetailRow('Seller ID:', dispute.sellerId),
              _buildDetailRow('Status:', _getDisputeStatusText(dispute.status)),
              _buildDetailRow('Created:', dispute.createdDate.toString().split('.')[0]),
              const SizedBox(height: 12),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(dispute.description),
              ),
              if (dispute.resolution.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Resolution:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(dispute.resolution),
                ),
              ],
              if (dispute.chatHistory.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Chat History:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...dispute.chatHistory
                    .take(5)
                    .map((msg) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $msg', style: const TextStyle(fontSize: 12)),
                        ))
                    .toList(),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context, String disputeId) {
    final resolutionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Dispute'),
        content: TextField(
          controller: resolutionController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter resolution details',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _resolveDispute(disputeId, resolutionController.text);
              Navigator.pop(context);
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveDispute(String disputeId, String resolution) async {
    try {
      await _adminRepository.resolveDispute(disputeId, resolution);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute resolved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _getDisputeStatusText(DisputeStatus status) {
    switch (status) {
      case DisputeStatus.open:
        return 'Open';
      case DisputeStatus.inReview:
        return 'In Review';
      case DisputeStatus.resolved:
        return 'Resolved';
      case DisputeStatus.closed:
        return 'Closed';
    }
  }
}
