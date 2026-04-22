import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth/presentation/auth_state.dart';
import '../entities/models/artwork.dart';
import '../payments/data/mock_payment_gateway.dart';
import '../shared/data/mock_seeder.dart';
import '../shared/widgets/artwork_card.dart';
import 'widgets/admin_summary_panel.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8F1414), Color(0xFFB71B1B), Color(0xFFDAAF1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoSize = constraints.maxHeight < 700 ? 140.0 : 180.0;
            final titleSize = constraints.maxHeight < 700 ? 30.0 : 34.0;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/artflow_logo.png',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'ArtFlow',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Commission, discover, and collect art in one mobile experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 26),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF8F1414),
                        ),
                        onPressed: () => context.go('/register'),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Get Started'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'buyer';
  bool _isLogin = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              _isLogin ? 'Welcome back' : 'Create account',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              _isLogin
                  ? 'Log in to continue using ArtFlow.'
                  : 'Join ArtFlow as a buyer or artist.',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Sign up'),
                    selected: !_isLogin,
                    onSelected: (_) => setState(() => _isLogin = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Login'),
                    selected: _isLogin,
                    onSelected: (_) => setState(() => _isLogin = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'buyer',
                  icon: Icon(Icons.shopping_bag_outlined),
                  label: Text('Buyer'),
                ),
                ButtonSegment(
                  value: 'artist',
                  icon: Icon(Icons.brush_outlined),
                  label: Text('Artist'),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (selection) {
                setState(() {
                  _role = selection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            if (!_isLogin) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if ((!_isLogin && _nameController.text.trim().isEmpty) ||
                    _emailController.text.trim().isEmpty ||
                    _passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please complete all fields. Password must be at least 6 characters.',
                      ),
                    ),
                  );
                  return;
                }
                final auth = context.read<AuthState>();
                auth.register(
                  name: _isLogin ? 'ArtFlow User' : _nameController.text,
                  role: _role,
                  email: _emailController.text,
                );
                if (_isLogin) {
                  context.go('/');
                } else {
                  context.go(
                    _role == 'artist'
                        ? '/onboarding/artist'
                        : '/onboarding/buyer',
                  );
                }
              },
              child: Text(_isLogin ? 'Login' : 'Create account'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                context.read<AuthState>().setAuthenticated(role: UserRole.buyer);
                context.go('/');
              },
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}

class BuyerOnboardingScreen extends StatefulWidget {
  const BuyerOnboardingScreen({super.key});

  @override
  State<BuyerOnboardingScreen> createState() => _BuyerOnboardingScreenState();
}

class _BuyerOnboardingScreenState extends State<BuyerOnboardingScreen> {
  final Set<String> _selected = {};
  static const _interests = [
    'Portrait',
    'Digital Art',
    'Nature',
    'Abstract',
    'Minimalist',
    'Fantasy',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buyer onboarding',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pick your interests so we can personalize your feed.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _interests.map((item) {
                  final selected = _selected.contains(item);
                  return FilterChip(
                    selected: selected,
                    label: Text(item),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selected.add(item);
                        } else {
                          _selected.remove(item);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.read<AuthState>().completeBuyerOnboarding(
                      preferences: _selected.toList(),
                    );
                    context.go('/');
                  },
                  child: const Text('Finish setup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArtistOnboardingScreen extends StatefulWidget {
  const ArtistOnboardingScreen({super.key});

  @override
  State<ArtistOnboardingScreen> createState() => _ArtistOnboardingScreenState();
}

class _ArtistOnboardingScreenState extends State<ArtistOnboardingScreen> {
  final _styleController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _styleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Artist onboarding',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Set up your creator profile and commission preferences.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _styleController,
              decoration: const InputDecoration(
                labelText: 'Primary art style',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Artist bio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                context.read<AuthState>().completeArtistOnboarding(
                  style: _styleController.text,
                  bio: _bioController.text,
                );
                context.go('/artist-dashboard');
              },
              child: const Text('Launch dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final artworks = MockSeeder.artworks;
    final featured = artworks.where((item) => item.isFeatured).toList();
    final categories = MockSeeder.categories;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        Text(
          'Maayong adlaw, ${auth.displayName.split(' ').first}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Discover Local',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          'Bukidnon Art',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 14),
        if (featured.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.16),
              ),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  const Color(0xFFF1E5CE).withValues(alpha: 0.6),
                  Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Featured Artist',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        featured.first.artistName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        featured.first.title,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () =>
                            context.push('/artwork/${featured.first.id}'),
                        child: const Text('View Artwork'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    featured.first.imageUrl ?? MockSeeder.placeholder,
                    width: 94,
                    height: 94,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 94,
                        height: 94,
                        color: const Color(0xFFF1E5CE),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_outlined),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Categories', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/explore'),
              child: const Text('See all'),
            ),
          ],
        ),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final label = categories[index].replaceAll('_', ' ');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: index == 0
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE4D8CB)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: index == 0 ? Colors.white : Colors.black87,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              Icons.trending_up,
              size: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 6),
            Text('Trending Now', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          itemCount: artworks.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 252,
          ),
          itemBuilder: (context, index) {
            final item = artworks[index];
            return ArtworkCard(
              artwork: item,
              onTap: () => context.push('/artwork/${item.id}'),
            );
          },
        ),
      ],
    );
  }
}

class ArtistDashboardScreen extends StatelessWidget {
  const ArtistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final commissions = MockSeeder.commissions;
    final myArtworks = MockSeeder.artworks
        .where((item) => item.artistName == auth.displayName)
        .toList();
    final avgRating = MockSeeder.averageRating(auth.displayName);
    final revenue = MockSeeder.orders.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Artist Dashboard',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: _MetricCard(label: 'Open Commissions', value: '8')),
            SizedBox(width: 10),
            Expanded(child: _MetricCard(label: 'Completed', value: '42')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Revenue',
                value: '\$${revenue.toStringAsFixed(0)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Rating',
                value: avgRating == 0 ? '-' : avgRating.toStringAsFixed(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(label: 'Portfolio', value: '${myArtworks.length}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Inquiries',
                value: '${MockSeeder.analyticsInquiries[auth.displayName] ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.push('/create'),
          icon: const Icon(Icons.add),
          label: const Text('Upload Artwork'),
        ),
        const SizedBox(height: 16),
        Text('Recent requests', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...commissions.take(3).map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
              title: Text(item.title),
              subtitle: Text('Budget \$${item.budget.toStringAsFixed(0)}'),
              trailing: _statusChip(item.status),
            ),
          );
        }),
      ],
    );
  }
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _query = '';
  String _selectedCategory = 'all';
  bool _showFilters = false;
  String _sortBy = 'newest';
  final _artistController = TextEditingController();
  final _styleController = TextEditingController();
  RangeValues _priceRange = const RangeValues(0, 6000);

  @override
  void dispose() {
    _artistController.dispose();
    _styleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var artworks = MockSeeder.artworks.where((item) {
      final categoryMatch =
          _selectedCategory == 'all' || item.category == _selectedCategory;
      final artistMatch =
          _artistController.text.trim().isEmpty ||
          item.artistName.toLowerCase().contains(
            _artistController.text.toLowerCase(),
          );
      final styleMatch =
          _styleController.text.trim().isEmpty ||
          item.medium?.toLowerCase().contains(_styleController.text.toLowerCase()) ==
              true;
      final priceMatch =
          item.price >= _priceRange.start && item.price <= _priceRange.end;
      final queryMatch =
          item.title.toLowerCase().contains(_query.toLowerCase()) ||
          item.artistName.toLowerCase().contains(_query.toLowerCase());
      return categoryMatch &&
          queryMatch &&
          artistMatch &&
          styleMatch &&
          priceMatch;
    }).toList();

    if (_sortBy == 'price_low') {
      artworks.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'price_high') {
      artworks.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'rating') {
      artworks.sort((a, b) => b.avgRating.compareTo(a.avgRating));
    } else if (_sortBy == 'featured') {
      artworks.sort(
        (a, b) => MockSeeder.isBoosted(b.id).toString().compareTo(
          MockSeeder.isBoosted(a.id).toString(),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search artworks, artists...',
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          onPressed: () => setState(() => _query = ''),
                          icon: const Icon(Icons.close),
                        )
                      : null,
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(() => _showFilters = !_showFilters),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        if (_showFilters) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _sortBy,
            items: const [
              DropdownMenuItem(value: 'newest', child: Text('Newest First')),
              DropdownMenuItem(
                value: 'price_low',
                child: Text('Price: Low to High'),
              ),
              DropdownMenuItem(
                value: 'price_high',
                child: Text('Price: High to Low'),
              ),
              DropdownMenuItem(value: 'rating', child: Text('Highest Rated')),
              DropdownMenuItem(
                value: 'featured',
                child: Text('Featured Priority'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _sortBy = value;
                });
              }
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _artistController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Artist',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _styleController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Style / Medium',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 20,
            labels: RangeLabels(
              '₱${_priceRange.start.toStringAsFixed(0)}',
              '₱${_priceRange.end.toStringAsFixed(0)}',
            ),
            onChanged: (value) => setState(() => _priceRange = value),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: MockSeeder.categories.map((item) {
              final selected = item == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(item.replaceAll('_', ' ')),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = item),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${artworks.length} artworks found',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        GridView.builder(
          itemCount: artworks.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 252,
          ),
          itemBuilder: (context, index) {
            final item = artworks[index];
            return ArtworkCard(
              artwork: item,
              onTap: () => context.push('/artwork/${item.id}'),
            );
          },
        ),
      ],
    );
  }
}

class ArtworkDetailScreen extends StatelessWidget {
  const ArtworkDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final artwork = MockSeeder.artworks.firstWhere(
      (art) => art.id == id,
      orElse: () => MockSeeder.artworks.first,
    );
    final formatter = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 0);
    final gateway = MockPaymentGateway();
    final img =
        artwork.imageUrl ??
        (artwork.images.isNotEmpty
            ? artwork.images.first
            : MockSeeder.placeholder);
    final conversationId = MockSeeder.getOrCreateConversation(artwork.artistName).id;
    MockSeeder.trackView(artwork.id);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.favorite_border),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.share_outlined),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            img,
            height: 320,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 320,
                color: const Color(0xFFF1E5CE),
                alignment: Alignment.center,
                child: const Icon(Icons.image_outlined, size: 52),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            Chip(
              label: Text(artwork.category),
              visualDensity: VisualDensity.compact,
            ),
            if (artwork.isFeatured)
              const Chip(
                label: Text('Featured'),
                backgroundColor: Color(0x33E3BC2D),
                visualDensity: VisualDensity.compact,
              ),
            if (MockSeeder.isSold(artwork.id))
              const Chip(
                label: Text('Sold'),
                backgroundColor: Color(0x33166534),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        Text(artwork.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('by ${artwork.artistName}'),
        const SizedBox(height: 12),
        Text(
          formatter.format(artwork.price),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 14),
        Text(artwork.description ?? 'No description provided.'),
        const SizedBox(height: 10),
        if (artwork.medium != null || artwork.size != null)
          Row(
            children: [
              if (artwork.medium != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medium',
                          style: TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                        Text(artwork.medium!),
                      ],
                    ),
                  ),
                ),
              if (artwork.medium != null && artwork.size != null)
                const SizedBox(width: 8),
              if (artwork.size != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Size',
                          style: TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                        Text(artwork.size!),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              MockSeeder.trackInquiry(artwork.artistName);
              context.push('/chat/${Uri.encodeComponent(conversationId)}');
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Inquire'),
          ),
        ),
        if (auth.isArtist || auth.isAdmin) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                MockSeeder.markArtworkSold(artwork.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Artwork marked as sold.')),
                );
              },
              child: const Text('Mark as Sold'),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/commission'),
                icon: const Icon(Icons.palette_outlined),
                label: const Text('Commission'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  final result = await gateway.pay(
                    amount: artwork.price,
                    currency: 'PHP',
                    description: artwork.title,
                  );
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${result.message} (${result.reference})'),
                    ),
                  );
                  context.push('/orders');
                },
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Buy Now'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CreateArtworkScreen extends StatefulWidget {
  const CreateArtworkScreen({super.key, this.artworkId});

  final String? artworkId;

  @override
  State<CreateArtworkScreen> createState() => _CreateArtworkScreenState();
}

class _CreateArtworkScreenState extends State<CreateArtworkScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mediumController = TextEditingController();
  final _sizeController = TextEditingController();
  final _tagsController = TextEditingController();
  String? _selectedCategory;
  bool _featureThisArtwork = false;
  bool _initialized = false;

  Artwork? get _editingArtwork {
    if (widget.artworkId == null) {
      return null;
    }
    return MockSeeder.artworks
        .where((item) => item.id == widget.artworkId)
        .toList()
        .firstOrNull;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _mediumController.dispose();
    _sizeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final editing = _editingArtwork;
    if (!_initialized && editing != null) {
      _titleController.text = editing.title;
      _priceController.text = editing.price.toStringAsFixed(0);
      _descriptionController.text = editing.description ?? '';
      _mediumController.text = editing.medium ?? '';
      _sizeController.text = editing.size ?? '';
      _selectedCategory = editing.category;
      _featureThisArtwork = editing.isFeatured;
      _initialized = true;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Text(
              editing == null ? 'Upload Artwork' : 'Edit Artwork',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Photos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Container(
          height: 88,
          width: 88,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDED8CE)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: Colors.black54),
              SizedBox(height: 4),
              Text('Add', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title *',
            hintText: 'Name your artwork',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Tell the story behind your art...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (P) *',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select'),
                items: const [
                  DropdownMenuItem(value: 'painting', child: Text('Painting')),
                  DropdownMenuItem(
                    value: 'digital',
                    child: Text('Digital Art'),
                  ),
                  DropdownMenuItem(
                    value: 'illustration',
                    child: Text('Illustration'),
                  ),
                  DropdownMenuItem(
                    value: 'photography',
                    child: Text('Photography'),
                  ),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mediumController,
                decoration: const InputDecoration(
                  labelText: 'Medium',
                  hintText: 'e.g. Oil on canvas',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _sizeController,
                decoration: const InputDecoration(
                  labelText: 'Size',
                  hintText: 'e.g. 24x36 inches',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tagsController,
          decoration: const InputDecoration(
            labelText: 'Tags (comma separated)',
            hintText: 'abstract, nature, Bukidnon...',
            border: OutlineInputBorder(),
          ),
        ),
        if (auth.hasFeaturedBoost) ...[
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _featureThisArtwork,
            title: const Text('Feature this artwork'),
            subtitle: const Text('Uses your active boost slot'),
            onChanged: (value) => setState(() => _featureThisArtwork = value),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () {
            final parsedPrice = double.tryParse(_priceController.text) ?? 0;
            if (_titleController.text.trim().isEmpty ||
                _selectedCategory == null ||
                parsedPrice <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please complete title, category and price.'),
                ),
              );
              return;
            }
            final record = Artwork(
              id: editing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: _titleController.text.trim(),
              artistName: auth.displayName,
              price: parsedPrice,
              description: _descriptionController.text.trim(),
              category: _selectedCategory ?? 'other',
              medium: _mediumController.text.trim(),
              size: _sizeController.text.trim(),
              imageUrl: MockSeeder.placeholder,
              images: const [MockSeeder.placeholder],
              isFeatured: _featureThisArtwork,
              avgRating: editing?.avgRating ?? 0,
            );
            MockSeeder.upsertArtwork(record);
            MockSeeder.toggleFeaturedBoost(record.id, _featureThisArtwork);
            MockSeeder.addNotification(
              'Artwork updated',
              '${record.title} has been ${editing == null ? 'uploaded' : 'saved'}.',
            );
            context.go('/artist-dashboard');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  editing == null
                      ? 'Artwork published (mock).'
                      : 'Artwork updated (mock).',
                ),
              ),
            );
          },
          icon: const Icon(Icons.publish_outlined),
          label: Text(editing == null ? 'Publish Artwork' : 'Save Changes'),
        ),
        if (editing != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              MockSeeder.deleteArtwork(editing.id);
              MockSeeder.addNotification(
                'Artwork removed',
                '${editing.title} was deleted.',
              );
              context.go('/profile');
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Artwork'),
          ),
        ],
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showArtworks = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final displayName = auth.displayName;
    final username = auth.username;
    final bio = auth.bio;
    final userInitial = displayName.isEmpty ? 'A' : displayName[0];
    final works = MockSeeder.artworks
        .where((item) => item.artistName == displayName)
        .toList();
    final averageRating = MockSeeder.averageRating(displayName);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFF1E5CE),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              userInitial,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            displayName,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            username,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              bio,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Chip(
            label: Text(
              auth.isAdmin
                  ? 'Admin'
                  : auth.isVerifiedArtist
                  ? 'Verified Artist'
                  : auth.isArtist
                  ? 'Artist'
                  : 'Buyer',
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatColumn(label: 'ARTWORKS', value: '${works.length}'),
            _StatColumn(
              label: 'SALES',
              value: '${MockSeeder.soldArtworkIds.length}',
            ),
            _StatColumn(
              label: 'RATING',
              value: averageRating == 0 ? '-' : averageRating.toStringAsFixed(1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: 132,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/edit-profile'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                  ),
                  label: const Text(
                    'Edit Profile',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 116,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/orders'),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                  ),
                  label: const Text(
                    'Orders',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (auth.isAdmin)
                SizedBox(
                  width: 112,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/admin'),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    label: const Text(
                      'Admin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => setState(() => _showArtworks = true),
                child: const Text('Artworks'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showArtworks = false),
                child: const Text('Commissions'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_showArtworks)
          if (works.isEmpty)
            const _ProfileEmptyState(
              title: 'No artworks yet',
              subtitle: 'Upload your first artwork to get started',
              cta: 'Upload Artwork',
              icon: Icons.palette_outlined,
              route: '/create',
            )
          else
            ...works.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ArtworkCard(
                  artwork: item,
                  onTap: () => context.push('/artwork/${item.id}'),
                ),
              );
            }),
        if (_showArtworks && works.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...works.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/create/${item.id}'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          MockSeeder.deleteArtwork(item.id);
                        });
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        if (!_showArtworks)
          const _ProfileEmptyState(
            title: 'No commissions yet',
            subtitle: 'Commission requests will appear here.',
            cta: 'Explore',
            icon: Icons.request_page_outlined,
            route: '/explore',
          ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProfileEmptyState extends StatelessWidget {
  const _ProfileEmptyState({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.black45),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.push(route),
            child: Text(cta),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'Artist');
  final _usernameController = TextEditingController(text: '@artist');
  final _bioController = TextEditingController(
    text: 'Portrait and digital artist focused on vivid color stories.',
  );
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _profilePhotoBytes;
  bool _verifiedBadge = false;
  bool _portfolioPack = false;
  bool _featuredBoost = false;
  bool _profileLoaded = false;

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1080,
    );
    if (picked == null || !mounted) {
      return;
    }
    final bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() => _profilePhotoBytes = bytes);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
  }

  Future<void> _showPhotoSourceOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickPhoto(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!_profileLoaded) {
      _nameController.text = auth.displayName;
      _usernameController.text = auth.username;
      _bioController.text = auth.bio;
      _verifiedBadge = auth.isVerifiedArtist;
      _portfolioPack = auth.hasPortfolioPack;
      _featuredBoost = auth.hasFeaturedBoost;
      _profileLoaded = true;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Edit profile', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFF1E5CE),
                child: _profilePhotoBytes == null
                    ? const Icon(Icons.person_outline, size: 36)
                    : ClipOval(
                        child: Image.memory(
                          _profilePhotoBytes!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showPhotoSourceOptions,
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: OutlinedButton.icon(
            onPressed: _showPhotoSourceOptions,
            icon: const Icon(Icons.upload_outlined),
            label: const Text('Upload Photo'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bioController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Bio',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _verifiedBadge,
          title: const Text('Verified Artist Badge'),
          subtitle: const Text('PHP 150 one-time'),
          onChanged: (value) => setState(() => _verifiedBadge = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _portfolioPack,
          title: const Text('Extended Portfolio Pack'),
          subtitle: const Text('PHP 99 unlock'),
          onChanged: (value) => setState(() => _portfolioPack = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _featuredBoost,
          title: const Text('Featured Artwork Boost'),
          subtitle: const Text('PHP 20/day'),
          onChanged: (value) => setState(() => _featuredBoost = value),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            auth.updateProfile(
              name: _nameController.text,
              username: _usernameController.text,
              bio: _bioController.text,
            );
            auth.setVerifiedArtist(_verifiedBadge);
            if (_portfolioPack) {
              auth.enablePortfolioPack();
            }
            if (_featuredBoost) {
              auth.enableFeaturedBoost();
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
            context.go('/profile');
          },
          child: const Text('Save changes'),
        ),
      ],
    );
  }
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  Future<void> _showNewMessageSheet(BuildContext context) async {
    final users = <String>{
      ...MockSeeder.conversations.map((item) => item.otherName),
      ...MockSeeder.artworks.map((item) => item.artistName),
    }.toList()..sort();
    var query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = users
                .where(
                  (name) => name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'New Message',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      autofocus: true,
                      onChanged: (value) => setState(() => query = value),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search user',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final name = filtered[index];
                          final conversationId =
                              MockSeeder.getOrCreateConversation(name).id;
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Text(name),
                            trailing: const Icon(Icons.chat_bubble_outline),
                            onTap: () {
                              Navigator.of(context).pop();
                              context.push(
                                '/chat/${Uri.encodeComponent(conversationId)}',
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversations = MockSeeder.conversations;

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final item = conversations[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(item.otherName),
                subtitle: Text(
                  item.preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: item.unread
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      )
                    : null,
                onTap: () => context.push('/chat/${item.id}'),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _showNewMessageSheet(context),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    MockSeeder.markConversationRead(widget.conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = MockSeeder.messages
        .where((item) => item.conversationId == widget.conversationId)
        .toList();
    final matchedConversation = MockSeeder.conversations
        .where((item) => item.id == widget.conversationId)
        .firstOrNull;
    final fallbackName = widget.conversationId.startsWith('new_')
        ? widget.conversationId
            .replaceFirst('new_', '')
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ')
        : 'Artist';
    final chatName = matchedConversation?.otherName ?? fallbackName;
    final chatInitial = chatName.isNotEmpty ? chatName[0].toUpperCase() : 'A';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF1E5CE),
                child: Text(
                  chatInitial,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  chatName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered.reversed.toList()[index];
              final mine = item.senderId == 'me';
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  constraints: const BoxConstraints(maxWidth: 270),
                  decoration: BoxDecoration(
                    color: mine
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(item.text),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Write a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {
                    final text = _messageController.text.trim();
                    if (text.isEmpty) return;
                    setState(() {
                      MockSeeder.addMessage(
                        conversationId: widget.conversationId,
                        senderId: 'me',
                        text: text,
                      );
                      MockSeeder.markConversationRead(widget.conversationId);
                      _messageController.clear();
                    });
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CommissionRequestScreen extends StatefulWidget {
  const CommissionRequestScreen({super.key});

  @override
  State<CommissionRequestScreen> createState() =>
      _CommissionRequestScreenState();
}

class _CommissionRequestScreenState extends State<CommissionRequestScreen> {
  final _titleController = TextEditingController();
  final _briefController = TextEditingController();
  final _budgetController = TextEditingController();
  String _timeline = '2 weeks';

  @override
  void dispose() {
    _titleController.dispose();
    _briefController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Commission request',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Project title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _briefController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Creative brief',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Budget',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _timeline,
          items: const [
            DropdownMenuItem(value: '1 week', child: Text('1 week')),
            DropdownMenuItem(value: '2 weeks', child: Text('2 weeks')),
            DropdownMenuItem(value: '1 month', child: Text('1 month')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _timeline = value;
              });
            }
          },
          decoration: const InputDecoration(
            labelText: 'Timeline',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            final budget = double.tryParse(_budgetController.text) ?? 0;
            MockSeeder.addCommission(
              title: _titleController.text.trim().isEmpty
                  ? 'Custom artwork request'
                  : _titleController.text.trim(),
              brief: '${_briefController.text.trim()} (Timeline: $_timeline)',
              budget: budget <= 0 ? 1000 : budget,
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Commission request sent.')));
            context.go('/commissions');
          },
          child: const Text('Send request'),
        ),
      ],
    );
  }
}

class CommissionsScreen extends StatefulWidget {
  const CommissionsScreen({super.key});

  @override
  State<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends State<CommissionsScreen> {
  @override
  Widget build(BuildContext context) {
    final commissions = MockSeeder.commissions;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: commissions.map((item) {
        final normalized = item.status.toLowerCase();
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.title),
                  subtitle: Text('Budget \$${item.budget.toStringAsFixed(0)}'),
                  trailing: _statusChip(item.status),
                ),
                if (normalized == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              MockSeeder.updateCommissionStatus(
                                item.id,
                                'Rejected',
                              );
                            });
                          },
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              MockSeeder.updateCommissionStatus(
                                item.id,
                                'Accepted',
                              );
                            });
                          },
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                if (normalized == 'accepted')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          MockSeeder.updateCommissionStatus(item.id, 'Completed');
                        });
                      },
                      child: const Text('Mark Completed'),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Future<void> _rateArtist(BuildContext context, String artistName) async {
    int rating = 5;
    final commentController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rate Artist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: rating,
                items: [1, 2, 3, 4, 5]
                    .map((value) {
                      return DropdownMenuItem(value: value, child: Text('$value'));
                    })
                    .toList(),
                onChanged: (value) => rating = value ?? 5,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Share your feedback',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    if (submitted == true) {
      MockSeeder.addReview(
        artistName: artistName,
        rating: rating,
        comment: commentController.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Rating submitted.')));
      }
    }
    commentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = MockSeeder.orders;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: orders.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Order #${item.id}'),
                  subtitle: Text('Artwork ${item.artworkId}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${item.total.toStringAsFixed(0)}'),
                      const SizedBox(height: 2),
                      Text(item.status, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Payment handled externally (manual flow).',
                              ),
                            ),
                          );
                        },
                        child: const Text('Report External Payment'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          MockSeeder.markArtworkSold(item.artworkId);
                          final artwork = MockSeeder.artworks
                              .where((art) => art.id == item.artworkId)
                              .toList()
                              .firstOrNull;
                          if (artwork != null) {
                            await _rateArtist(context, artwork.artistName);
                          }
                        },
                        child: const Text('Deal Completed'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  @override
  Widget build(BuildContext context) {
    final notifications = MockSeeder.notifications;
    final dateFmt = DateFormat('MMM d, h:mm a');

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              setState(() {
                MockSeeder.markAllNotificationsRead();
              });
            },
            child: const Text('Mark all as read'),
          ),
        ),
        ...notifications.map((item) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                item.read ? Icons.notifications_none : Icons.notifications_active,
              ),
              title: Text(item.title),
              subtitle: Text(item.body),
              trailing: Text(dateFmt.format(item.createdAt)),
            ),
          );
        }),
      ],
    );
  }
}

class ArtistProfileScreen extends StatelessWidget {
  const ArtistProfileScreen({super.key, required this.artistId});

  final String artistId;

  @override
  Widget build(BuildContext context) {
    final works = MockSeeder.artworks
        .where((item) => item.id == artistId || artistId == '1')
        .toList();
    final artistName = works.isNotEmpty ? works.first.artistName : 'Artist #$artistId';
    final avgRating = MockSeeder.averageRating(artistName);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 34,
          child: Icon(Icons.brush_outlined, size: 34),
        ),
        const SizedBox(height: 10),
        Text(
          artistName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (MockSeeder.verifiedArtist)
              const Chip(
                label: Text('Verified'),
                visualDensity: VisualDensity.compact,
              ),
            const SizedBox(width: 6),
            Text(
              avgRating == 0 ? 'No ratings yet' : 'Rating ${avgRating.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Specializes in vivid portraiture and digital mixed media compositions.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.push('/commission'),
          child: const Text('Request commission'),
        ),
        const SizedBox(height: 16),
        ...works.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ArtworkCard(
              artwork: item,
              onTap: () => context.push('/artwork/${item.id}'),
            ),
          );
        }),
      ],
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final items = MockSeeder.artworks.where((item) {
      return item.title.toLowerCase().contains(_query.toLowerCase()) ||
          item.artistName.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search everything',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 14),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ArtworkCard(
              artwork: item,
              onTap: () => context.push('/artwork/${item.id}'),
            ),
          );
        }),
      ],
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.isAdmin) {
      return const Center(
        child: Text('Admin access only.'),
      );
    }
    final reports = [
      'Flagged artwork: Metro Pulse',
      'Dispute opened: Order #902',
      'Commission delay escalation',
    ];

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Moderation'),
              Tab(text: 'Users'),
              Tab(text: 'Verify'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: reports.map((item) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item),
                        trailing: FilledButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Report reviewed (mock).'),
                              ),
                            );
                          },
                          child: const Text('Review'),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                AdminSummaryPanel(
                  activeUsers: 1284,
                  artistCount: MockSeeder.artworks
                      .map((e) => e.artistName)
                      .toSet()
                      .length,
                  buyerCount: 855,
                  unreadNotifications: MockSeeder.unreadNotificationCount,
                ),
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Card(
                      child: ListTile(
                        title: const Text('Verify Featured Artist Account'),
                        subtitle: Text(
                          auth.isVerifiedArtist
                              ? 'Already verified'
                              : 'Pending verification',
                        ),
                        trailing: FilledButton(
                          onPressed: () {
                            auth.setVerifiedArtist(true);
                            setState(() {});
                          },
                          child: const Text('Approve'),
                        ),
                      ),
                    ),
                    Card(
                      child: ListTile(
                        title: const Text('Manual Promotion Review'),
                        subtitle: const Text(
                          'Approve featured boost and portfolio extensions.',
                        ),
                        trailing: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Promotion approval logged.'),
                              ),
                            );
                          },
                          child: const Text('Open'),
                        ),
                      ),
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

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.find_in_page_outlined, size: 52),
            const SizedBox(height: 12),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'The route you requested does not exist.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

Widget _statusChip(String status) {
  final normalized = status.toLowerCase();
  Color color;
  if (normalized.contains('active') || normalized.contains('processing')) {
    color = const Color(0xFF0369A1);
  } else if (normalized.contains('completed') ||
      normalized.contains('delivered')) {
    color = const Color(0xFF166534);
  } else {
    color = const Color(0xFF92400E);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );
}
