import 'package:flutter/material.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/admin_models.dart';
import '../widgets/admin_widgets.dart';

/// Transaction Monitoring Screen
class TransactionMonitoringScreen extends StatefulWidget {
  const TransactionMonitoringScreen({super.key});

  @override
  State<TransactionMonitoringScreen> createState() => _TransactionMonitoringScreenState();
}

class _TransactionMonitoringScreenState extends State<TransactionMonitoringScreen> {
  final _adminRepository = AdminRepository();
  String _filterStatus = 'All'; // All, Held, Released, Disputed, Refunded

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
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Held'),
                const SizedBox(width: 8),
                _buildFilterChip('Released'),
                const SizedBox(width: 8),
                _buildFilterChip('Disputed'),
                const SizedBox(width: 8),
                _buildFilterChip('Refunded'),
              ],
            ),
          ),
        ),
        // Transactions list
        Expanded(
          child: StreamBuilder<List<TransactionRecord>>(
            stream: _adminRepository.getAllTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              var transactions = snapshot.data ?? [];

              // Apply filter
              if (_filterStatus != 'All') {
                transactions = transactions
                    .where((t) => _getEscrowStatusText(t.escrowStatus) == _filterStatus)
                    .toList();
              }

              if (transactions.isEmpty) {
                return const Center(
                  child: Text('No transactions found'),
                );
              }

              // Calculate summary
              double totalAmount = transactions.fold(0, (sum, t) => sum + t.amount);
              double totalFees = transactions.fold(0, (sum, t) => sum + t.platformFee);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: transactions.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildSummaryCard(totalAmount, totalFees);
                  }

                  final transaction = transactions[index - 1];
                  return TransactionRecordCard(
                    orderId: transaction.orderId,
                    buyerName: transaction.buyerName,
                    sellerName: transaction.sellerName,
                    amount: transaction.amount,
                    platformFee: transaction.platformFee,
                    escrowStatus: _getEscrowStatusText(transaction.escrowStatus),
                    artworkTitle: transaction.artworkTitle,
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
          _filterStatus = selected ? label : 'All';
        });
      },
    );
  }

  Widget _buildSummaryCard(double totalAmount, double totalFees) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Amount'),
                    Text(
                      '\$${totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Fees'),
                    Text(
                      '\$${totalFees.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getEscrowStatusText(EscrowStatus status) {
    switch (status) {
      case EscrowStatus.held:
        return 'Held';
      case EscrowStatus.released:
        return 'Released';
      case EscrowStatus.disputed:
        return 'Disputed';
      case EscrowStatus.refunded:
        return 'Refunded';
    }
  }
}
