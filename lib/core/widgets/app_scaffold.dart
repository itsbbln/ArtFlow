import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/auth_state.dart';

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
    final initial = auth.isAuthenticated ? 'A' : 'U';

    return Scaffold(
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
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.palette_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ArtFlow',
                          style: Theme.of(context).textTheme.titleLarge,
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
                          child: const Center(
                            child: Text(
                              '3',
                              style: TextStyle(
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
                  InkWell(
                    onTap: () => context.push('/profile'),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1E5CE),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
                      label: 'Create',
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
