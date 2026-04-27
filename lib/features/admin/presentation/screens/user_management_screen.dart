import 'package:flutter/material.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/admin_models.dart';
import '../widgets/admin_widgets.dart';

/// User Management Screen
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _adminRepository = AdminRepository();
  String _filterType = 'All'; // All, Buyers, Artists (Verified/Pending)

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
                _buildFilterChip('Buyers'),
                const SizedBox(width: 8),
                _buildFilterChip('Artists (Verified)'),
                const SizedBox(width: 8),
                _buildFilterChip('Artists (Pending)'),
              ],
            ),
          ),
        ),
        // Users list
        Expanded(
          child: StreamBuilder<List<AdminUserInfo>>(
            stream: _adminRepository.getAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              var users = snapshot.data ?? [];

              // Apply filter
              if (_filterType != 'All') {
                users = users.where((user) {
                  if (_filterType == 'Buyers') {
                    return user.accountType == UserAccountType.buyer;
                  } else if (_filterType == 'Artists (Verified)') {
                    return user.accountType == UserAccountType.artistVerified;
                  } else if (_filterType == 'Artists (Pending)') {
                    return user.accountType == UserAccountType.artistPending;
                  }
                  return true;
                }).toList();
              }

              if (users.isEmpty) {
                return const Center(
                  child: Text('No users found'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return AdminUserListItem(
                    displayName: user.displayName,
                    email: user.email,
                    accountType: _getAccountTypeDisplay(user.accountType),
                    status: user.status,
                    onViewDetails: () => _showUserDetailsDialog(context, user),
                    onSuspend: () => _suspendUser(user.userId),
                    onBan: () => _banUser(user.userId),
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
      selected: _filterType == label,
      onSelected: (selected) {
        setState(() {
          _filterType = selected ? label : 'All';
        });
      },
    );
  }

  String _getAccountTypeDisplay(UserAccountType type) {
    switch (type) {
      case UserAccountType.buyer:
        return 'Buyer';
      case UserAccountType.artistVerified:
        return 'Artist ✓';
      case UserAccountType.artistPending:
        return 'Artist (Pending)';
    }
  }

  void _showUserDetailsDialog(BuildContext context, AdminUserInfo user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email:', user.email),
              _buildDetailRow('Account Type:', _getAccountTypeDisplay(user.accountType)),
              _buildDetailRow('Status:', user.status),
              _buildDetailRow('Verified:', user.isVerified ? 'Yes' : 'No'),
              _buildDetailRow('Registered:', user.registeredDate.toString().split('.')[0]),
              _buildDetailRow('Purchases:', '${user.totalPurchases}'),
              _buildDetailRow('Listings:', '${user.totalListings}'),
              const SizedBox(height: 12),
              if (user.activityLog.isNotEmpty) ...[
                const Text(
                  'Recent Activity:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...user.activityLog.take(5).map((activity) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $activity', style: const TextStyle(fontSize: 12)),
                    ))
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

  Future<void> _suspendUser(String userId) async {
    try {
      await _adminRepository.suspendUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User suspended successfully')),
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

  Future<void> _banUser(String userId) async {
    try {
      await _adminRepository.banUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User banned successfully')),
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
}
