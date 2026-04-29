import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/editorial_colors.dart';
import '../../auth/presentation/auth_state.dart';
import '../../shared/data/app_data_state.dart';
import '../../shared/widgets/artwork_card.dart';
import '../screen_utils.dart';
import '../widgets/editorial_section_header.dart';
import 'featured_artist_section.dart';
import 'partner_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String _selectedCategory = 'all';
  late AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 840),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _introController.forward();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  static const LinearGradient _pillSelectedGradient = LinearGradient(
    colors: [EditorialColors.tribalRed, EditorialColors.tribalMaroon],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();

    final artworks = filterArtworksByCategory(data.artworks, _selectedCategory);
    final featured = artworks.where((item) => item.isFeatured).toList();
    final categories = data.categories;
    final auctions = artworks.where((item) {
      return item.isAuction &&
          item.auctionStatus == 'active' &&
          (item.auctionEndAt == null || item.auctionEndAt!.isAfter(DateTime.now()));
    }).toList();

    final firstFeatured = featured.isNotEmpty ? featured.first : null;

    final fade = CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    final greeting = auth.displayName.split(' ').first;

    return ColoredBox(
      color: EditorialColors.pageCream,
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                EditorialColors.tribalMaroon,
                                EditorialColors.tribalRed,
                                EditorialColors.tribalGold.withValues(alpha: 0.92),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: AppShadows.raised,
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(painter: _HeroMeshPainter()),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color:
                                              Colors.white.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Text(
                                        'ARTFLOW · BUkidnon-born',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          letterSpacing: 1.85,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Maayong adlaw,\n$greeting',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            Colors.white.withValues(alpha: 0.95),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Discover\n',
                                            style: GoogleFonts.playfairDisplay(
                                              fontSize: 34,
                                              fontWeight: FontWeight.w800,
                                              height: 1.02,
                                              color: Colors.white,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'local art.',
                                            style: GoogleFonts.playfairDisplay(
                                              fontSize: 34,
                                              fontWeight: FontWeight.w900,
                                              height: 1.02,
                                              color: EditorialColors.tribalCream,
                                              shadows: [
                                                Shadow(
                                                  color:
                                                      Colors.black.withValues(alpha: 0.38),
                                                  blurRadius: 18,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Material(
                                      color: Colors.white.withValues(alpha: 0.96),
                                      borderRadius: BorderRadius.circular(18),
                                      elevation: 0,
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: () => context.push('/explore'),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.local_fire_department_outlined,
                                                color: EditorialColors.tribalRed,
                                                size: 22,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'Search artists, murals, ceramics…',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        EditorialColors.muted.withValues(
                                                      alpha: 0.94,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Icon(Icons.north_east_rounded,
                                                  color:
                                                      EditorialColors.tribalRed.withValues(
                                                    alpha: 0.82,
                                                  ),
                                                  size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const PartnerCarousel(),
                      const SizedBox(height: 26),
                      FeaturedArtistSection(featured: firstFeatured),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: EditorialSectionHeader(
                    title: 'Shop by vibe',
                    subtitle: 'Swipe chips — tiles below update live.',
                    trailing: TextButton(
                      onPressed: () => context.push('/explore'),
                      style: TextButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Open gallery',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: EditorialColors.tribalRed,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_circle_right_rounded,
                              color: EditorialColors.tribalGold, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 46,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == _selectedCategory;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () =>
                                setState(() => _selectedCategory = category),
                            child: Ink(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient:
                                    isSelected ? _pillSelectedGradient : null,
                                color: isSelected ? null : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : EditorialColors.border,
                                  width: 1,
                                ),
                                boxShadow: isSelected
                                    ? AppShadows.softGlow
                                    : AppShadows.card,
                              ),
                              child: Center(
                                child: Text(
                                  categoryLabel(category),
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : EditorialColors.charcoal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (auctions.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    EditorialColors.blush.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: EditorialColors.tribalRed
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Icon(
                                Icons.flash_on_rounded,
                                color: EditorialColors.tribalRed,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Live auctions',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.35,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 272,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: auctions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final item = auctions[index];
                              return SizedBox(
                                width: 194,
                                child: ArtworkCard(
                                  artwork: item,
                                  onTap: () =>
                                      context.push('/artwork/${item.id}'),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium_outlined,
                          color: EditorialColors.goldSoft, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Trending now',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: EditorialColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (artworks.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.photo_library_outlined,
                              size: 46, color: EditorialColors.border),
                          const SizedBox(height: 14),
                          Text(
                            'Nothing tagged here yet.',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try another chip or peek the full Explore feed.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: EditorialColors.muted,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.tonal(
                            onPressed: () => context.push('/explore'),
                            child: Text('Go to Explore',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 38),
                  sliver: SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const crossAxisCount = 2;
                        const spacing = 14.0;
                        final maxW = constraints.maxWidth;
                        final cardWidth =
                            (maxW - spacing * (crossAxisCount - 1)) /
                                crossAxisCount;
                        final cardHeight = cardWidth + 96;

                        return GridView.builder(
                          itemCount: artworks.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: spacing,
                            crossAxisSpacing: spacing,
                            mainAxisExtent: cardHeight,
                          ),
                          itemBuilder: (context, index) {
                            final item = artworks[index];
                            return ArtworkCard(
                              artwork: item,
                              onTap: () => context.push('/artwork/${item.id}'),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft diagonal stripes for hero depth (no asset).
class _HeroMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.07),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, p);

    final line = Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.045);
    for (double i = -size.height; i < size.width; i += 28) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
