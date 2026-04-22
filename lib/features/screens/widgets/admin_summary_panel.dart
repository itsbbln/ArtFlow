import 'package:flutter/material.dart';

class AdminSummaryPanel extends StatelessWidget {
  const AdminSummaryPanel({
    super.key,
    required this.activeUsers,
    required this.artistCount,
    required this.buyerCount,
    required this.unreadNotifications,
  });

  final int activeUsers;
  final int artistCount;
  final int buyerCount;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ListTile(title: const Text('Active users'), trailing: Text('$activeUsers')),
        const Divider(height: 1),
        ListTile(title: const Text('Artists'), trailing: Text('$artistCount')),
        const Divider(height: 1),
        ListTile(title: const Text('Buyers'), trailing: Text('$buyerCount')),
        const Divider(height: 1),
        ListTile(
          title: const Text('Unread notifications'),
          trailing: Text('$unreadNotifications'),
        ),
      ],
    );
  }
}
