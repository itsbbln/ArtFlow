import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/auth_state.dart';
import '../../features/shared/data/mock_seeder.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _tabs = <String>[
    '/',
    '/explore',
    '/create',
    '/messages',
    '/profile',
  ];

  int _selectedIndex() {
    if (location.startsWith('/explore')) {
      return 1;
    }
    if (location.startsWith('/create')) {
      return 2;
    }
    if (location.startsWith('/messages') || location.startsWith('/chat')) {
      return 3;
    }
    if (location.startsWith('/profile') ||
        location.startsWith('/edit-profile')) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      endDrawer: Drawer(
        child: Container(
          color: const Color(0xFFF7F2EA),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person_outline, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            auth.isAdmin
                                ? 'Admin'
                                : auth.isArtist
                                ? 'Artist'
                                : 'Buyer',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/profile');
                  },
                ),
                _MenuTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Orders',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/orders');
                  },
                ),
                _MenuTile(
                  icon: Icons.request_page_outlined,
                  title: 'Commissions',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/commissions');
                  },
                ),
                _MenuTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Payments',
                  subtitle: 'Coming soon',
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payments: coming soon.')),
                    );
                  },
                ),
                _MenuTile(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/notifications');
                  },
                ),
                if (auth.isAdmin)
                  _MenuTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/admin');
                    },
                  ),
                if (auth.isArtist)
                  _MenuTile(
                    icon: Icons.verified_outlined,
                    title: auth.isVerifiedArtist
                        ? 'Verified Artist'
                        : 'Get Verified Badge',
                    subtitle: auth.isVerifiedArtist ? null : 'PHP 150 one-time',
                    onTap: () {
                      Navigator.of(context).pop();
                      if (!auth.isVerifiedArtist) {
                        auth.setVerifiedArtist(true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verified badge enabled (mock).'),
                          ),
                        );
                      }
                    },
                  ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                _MenuTile(
                  icon: Icons.logout,
                  title: 'Log out',
                  danger: true,
                  onTap: () {
                    Navigator.of(context).pop();
                    auth.setUnauthenticated();
                    context.go('/register');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withValues(alpha: 0.92),
                border: const Border(
                  bottom: BorderSide(color: Color(0x1A000000)),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/'),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Image.asset(
                              'assets/images/artflow_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ArtFlow',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.search, size: 20),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () => context.push('/notifications'),
                        icon: const Icon(Icons.notifications_none, size: 20),
                      ),
                      if (MockSeeder.unreadNotificationCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Center(
                              child: Text(
                                '${MockSeeder.unreadNotificationCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Builder(
                    builder: (context) {
                      return IconButton(
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                        icon: const Icon(Icons.menu_rounded, size: 22),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: SafeArea(top: false, child: child)),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).scaffoldBackgroundColor.withValues(alpha: 0.95),
              border: const Border(top: BorderSide(color: Color(0x1A000000))),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _BottomItem(
                      icon: Icons.home_outlined,
                      label: 'Home',
                      active: _selectedIndex() == 0,
                      onTap: () => context.go(_tabs[0]),
                    ),
                    _BottomItem(
                      icon: Icons.search,
                      label: 'Explore',
                      active: _selectedIndex() == 1,
                      onTap: () => context.go(_tabs[1]),
                    ),
                    _BottomItem(
                      icon: Icons.add_box_outlined,
                      label: 'Upload',
                      active: _selectedIndex() == 2,
                      onTap: () => context.go(_tabs[2]),
                    ),
                    _BottomItem(
                      icon: Icons.chat_bubble_outline,
                      label: 'Chat',
                      active: _selectedIndex() == 3,
                      onTap: () => context.go(_tabs[3]),
                    ),
                    _BottomItem(
                      icon: Icons.person_outline,
                      label: 'Profile',
                      active: _selectedIndex() == 4,
                      onTap: () => context.go(_tabs[4]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final dangerColor = const Color(0xFFB71B1B);
    final titleColor = danger ? dangerColor : const Color(0xFF2D2A26);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon, color: titleColor),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, color: titleColor),
          ),
          subtitle: subtitle == null
              ? null
              : Text(subtitle!, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactive = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: active ? activeColor : inactive),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? activeColor : inactive,
              ),
            ),
            const SizedBox(height: 3),
            if (active)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
