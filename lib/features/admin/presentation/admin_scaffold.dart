import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_state.dart';

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  // Admin navigation tabs
  static const _adminTabs = <String>[
    '/admin',
    '/admin-profile',
  ];

  int _selectedIndex() {
    if (location.startsWith('/admin-profile')) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    // Check if user is admin
    if (!auth.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Admin access only'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.go('/admin-profile'),
            tooltip: 'Admin Profile',
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(),
        onDestinationSelected: (int index) {
          context.go(_adminTabs[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
