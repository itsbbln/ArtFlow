import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth/presentation/auth_state.dart';
import '../entities/models/message_item.dart';
import '../payments/data/mock_payment_gateway.dart';
import '../shared/data/mock_seeder.dart';
import '../shared/widgets/artwork_card.dart';

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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Artflow',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Commission, discover, and collect art in one mobile experience.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
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
              'Create account',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            const Text('Join Artflow as a buyer or artist.'),
            const SizedBox(height: 20),
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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
                if (_nameController.text.trim().isEmpty ||
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
                context.read<AuthState>().setAuthenticated();
                context.go(
                  _role == 'artist'
                      ? '/onboarding/artist'
                      : '/onboarding/buyer',
                );
              },
              child: const Text('Create account'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                context.read<AuthState>().setAuthenticated();
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
                  onPressed: () => context.go('/'),
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
              onPressed: () => context.go('/artist-dashboard'),
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
    final artworks = MockSeeder.artworks;
    final featured = artworks.where((item) => item.isFeatured).toList();
    final categories = MockSeeder.categories;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        Text(
          'Maayong adlaw, Artist',
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
            childAspectRatio: 0.72,
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
    final commissions = MockSeeder.commissions;

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
            Expanded(
              child: _MetricCard(label: 'Open Commissions', value: '8'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MetricCard(label: 'Completed', value: '42'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
              child: _MetricCard(label: 'Revenue', value: '\$45,800'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MetricCard(label: 'Rating', value: '4.9'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.push('/create'),
          icon: const Icon(Icons.add),
          label: const Text('Create artwork'),
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

  @override
  Widget build(BuildContext context) {
    var artworks = MockSeeder.artworks.where((item) {
      final categoryMatch =
          _selectedCategory == 'all' || item.category == _selectedCategory;
      final queryMatch =
          item.title.toLowerCase().contains(_query.toLowerCase()) ||
          item.artistName.toLowerCase().contains(_query.toLowerCase());
      return categoryMatch && queryMatch;
    }).toList();

    if (_sortBy == 'price_low') {
      artworks.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'price_high') {
      artworks.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'rating') {
      artworks.sort((a, b) => b.avgRating.compareTo(a.avgRating));
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
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _sortBy = value;
                });
              }
            },
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
            childAspectRatio: 0.72,
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
  const CreateArtworkScreen({super.key});

  @override
  State<CreateArtworkScreen> createState() => _CreateArtworkScreenState();
}

class _CreateArtworkScreenState extends State<CreateArtworkScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Create artwork',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Price',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Artwork published (mock).')),
            );
            context.go('/artist-dashboard');
          },
          icon: const Icon(Icons.publish_outlined),
          label: const Text('Publish'),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final works = MockSeeder.artworks
        .where((item) => item.artistName == 'M. Reyes')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 30, child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maria Reyes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text('@mreyes.art'),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.push('/edit-profile'),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Portfolio'),
        const SizedBox(height: 8),
        ...works.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ArtworkCard(
              artwork: item,
              onTap: () => context.push('/artwork/${item.id}'),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            context.read<AuthState>().setUnauthenticated();
            context.go('/register');
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'Maria Reyes');
  final _usernameController = TextEditingController(text: '@mreyes.art');
  final _bioController = TextEditingController(
    text: 'Portrait and digital artist focused on vivid color stories.',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Edit profile', style: Theme.of(context).textTheme.headlineSmall),
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
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
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

  @override
  Widget build(BuildContext context) {
    final conversations = MockSeeder.conversations;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
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
  final _messages = <MessageItem>[...MockSeeder.messages];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _messages
        .where((item) => item.conversationId == widget.conversationId)
        .toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Text(
            'Conversation ${widget.conversationId}',
            style: Theme.of(context).textTheme.titleMedium,
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
                      _messages.add(
                        MessageItem(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          conversationId: widget.conversationId,
                          senderId: 'me',
                          text: text,
                          sentAt: DateTime.now(),
                        ),
                      );
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
  String _timeline = '2 weeks';

  @override
  void dispose() {
    _titleController.dispose();
    _briefController.dispose();
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Commission request sent.')),
            );
            context.go('/commissions');
          },
          child: const Text('Send request'),
        ),
      ],
    );
  }
}

class CommissionsScreen extends StatelessWidget {
  const CommissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final commissions = MockSeeder.commissions;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: commissions.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(item.title),
            subtitle: Text('Budget \$${item.budget.toStringAsFixed(0)}'),
            trailing: _statusChip(item.status),
          ),
        );
      }).toList(),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = MockSeeder.orders;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: orders.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
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
        );
      }).toList(),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = MockSeeder.notifications;
    final dateFmt = DateFormat('MMM d, h:mm a');

    return ListView(
      padding: const EdgeInsets.all(12),
      children: notifications.map((item) {
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
      }).toList(),
    );
  }
}

class ArtistProfileScreen extends StatelessWidget {
  const ArtistProfileScreen({super.key, required this.artistId});

  final String artistId;

  @override
  Widget build(BuildContext context) {
    final works = MockSeeder.artworks
        .where((item) => item.artistName.contains('Reyes') || artistId == '1')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 34,
          child: Icon(Icons.brush_outlined, size: 34),
        ),
        const SizedBox(height: 10),
        Text(
          'Artist #$artistId',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
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

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      'Flagged artwork: Metro Pulse',
      'Dispute opened: Order #902',
      'Commission delay escalation',
    ];

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Moderation'),
              Tab(text: 'Users'),
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
                          onPressed: () {},
                          child: const Text('Review'),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: const [
                    ListTile(
                      title: Text('Active users'),
                      trailing: Text('1,284'),
                    ),
                    Divider(height: 1),
                    ListTile(title: Text('Artists'), trailing: Text('429')),
                    Divider(height: 1),
                    ListTile(title: Text('Buyers'), trailing: Text('855')),
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
