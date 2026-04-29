import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/editorial_colors.dart';
import '../../auth/presentation/auth_state.dart';
import '../../shared/data/app_data_state.dart';
import '../../shared/widgets/artwork_card.dart';
import '../widgets/order_status_chip.dart';

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
    final data = context.watch<AppDataState>();
    final displayName = auth.displayName;
    final username = auth.username;
    final bio = auth.bio;
    final currentUserId = auth.currentUserId;
    final userInitial = displayName.isEmpty ? '?' : displayName[0];

    final works = data.artworks.where((item) {
      return (currentUserId != null && item.artistId == currentUserId) ||
          item.artistName == displayName;
    }).toList();

    final averageRating = works.isEmpty
        ? 0.0
        : works.fold<double>(0, (total, item) => total + item.avgRating) /
            works.length;
    final salesCount = works.where((w) => data.isSold(w.id)).length;
    final commissions = data.commissions;

    final aboutText =
        bio.isEmpty ? 'Say something about yourself — tap Edit profile below to share your story.' : bio;

    final postsCount = works.length;
    final followers = auth.followersCount;
    final following = auth.followingCount;
    final pinned = auth.pinnedDetails;
    final commissionInsightCount = commissions.where((c) {
      return c.artistId == currentUserId ||
          c.clientId == currentUserId ||
          c.artistName == displayName ||
          c.clientName == displayName;
    }).length;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: BukidnonGradients.pageAmbient),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(44),
                      ),
                      child: SizedBox(
                        height: 188,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration:
                              BoxDecoration(gradient: BukidnonGradients.profileHero),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CustomPaint(painter: _ProfileHeaderMeshPainter()),
                              SafeArea(
                                bottom: false,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(18, 8, 10, 0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.28),
                                          ),
                                        ),
                                        child: Text(
                                          'CREATOR PROFILE',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 9.5,
                                            letterSpacing: 1.95,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        tooltip: 'Edit profile',
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              Colors.white.withValues(alpha: 0.16),
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () =>
                                            context.push('/edit-profile'),
                                        icon:
                                            const Icon(Icons.tune_rounded, size: 22),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, 56),
                      child: Hero(
                        tag: 'profile_avatar_${currentUserId ?? 'me'}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                EditorialColors.tribalGold,
                                EditorialColors.tribalRed,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: AppShadows.raised,
                          ),
                          padding: const EdgeInsets.all(5),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.white,
                            backgroundImage: auth.photoUrl.isNotEmpty
                                ? NetworkImage(auth.photoUrl)
                                : null,
                            child: auth.photoUrl.isEmpty
                                ? Text(
                                    userInitial,
                                    style: GoogleFonts.playfairDisplay(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 40,
                                      color: EditorialColors.ink,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(22, 64, 22, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          color: EditorialColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: EditorialColors.parchmentDeep.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: EditorialColors.border.withValues(alpha: 0.82)),
                        ),
                        child: Text(
                          username,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: EditorialColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ProfileStatStrip(
                        postsCount: postsCount,
                        followers: followers,
                        following: following,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (auth.isArtist || auth.isAdmin)
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: EditorialColors.tribalRed,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => context.push('/create'),
                                icon: const Icon(Icons.add_photo_alternate_rounded),
                                label: Text(
                                  'Add artwork',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          if (auth.isArtist || auth.isAdmin) const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                  color:
                                      EditorialColors.tribalGold.withValues(alpha: 0.75),
                                ),
                                foregroundColor: EditorialColors.charcoal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => context.push('/edit-profile'),
                              icon:
                                  const Icon(Icons.edit_calendar_outlined, size: 18),
                              label: Text(
                                'Edit profile',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              EditorialColors.tribalCream.withValues(alpha: 0.72),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: EditorialColors.border.withValues(alpha: 0.85),
                          ),
                          boxShadow: AppShadows.raised,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.article_outlined,
                                    color: EditorialColors.tribalRed.withValues(alpha: 0.9)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'About',
                                    style: GoogleFonts.playfairDisplay(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: EditorialColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              bio.isEmpty ? aboutText : bio,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                height: 1.55,
                                color: EditorialColors.charcoal.withValues(alpha: 0.92),
                              ),
                            ),
                            if (pinned.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: pinned
                                    .map(
                                      (line) => Chip(
                                        avatar: Icon(
                                          Icons.diamond_outlined,
                                          size: 16,
                                          color:
                                              EditorialColors.tribalGold.withValues(alpha: 0.95),
                                        ),
                                        label: Text(
                                          line,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            height: 1.3,
                                          ),
                                        ),
                                        backgroundColor:
                                            Colors.white.withValues(alpha: 0.94),
                                        side: BorderSide(
                                          color:
                                              EditorialColors.tribalGold.withValues(alpha: 0.45),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 4),
                            TextButton.icon(
                              onPressed: () => context.push('/edit-profile'),
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: EditorialColors.tribalRed,
                              ),
                              label: Text(
                                'Adjust intro & pins',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: EditorialColors.tribalRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick actions
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: _FbCard(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FbOutlineAction(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Orders',
                      onTap: () => context.push('/orders'),
                    ),
                    _FbOutlineAction(
                      icon: Icons.payment_outlined,
                      label: 'Payments',
                      onTap: () => context.push('/payments'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Artist application
          if (!auth.isArtist &&
              !auth.verificationSubmitted &&
              !auth.artistApplicationRejected)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: FilledButton.icon(
                  onPressed: () => context.push('/become-artist'),
                  icon: const Icon(Icons.brush_outlined),
                  label: const Text('Become an Artist'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: EditorialColors.tribalRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            )
          else if (auth.hasPendingArtistApplication)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/verification'),
                  icon: const Icon(Icons.pending_actions_rounded),
                  label: const Text('Application Pending'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: EditorialColors.tribalRed,
                    side: const BorderSide(color: EditorialColors.tribalRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            )
          else if (auth.isAdmin)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/admin'),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Admin Panel'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),

          // Insight stats — artists only (same visibility as portfolio tools)
          if (auth.isArtist)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _FbCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.insights_outlined,
                            size: 22,
                            color: EditorialColors.tribalRed.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 8),
                          Text('Insights', style: _fbSectionTitle),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ProfileInsightsGrid(
                        tiles: [
                          _ProfileInsightTile(
                            icon: Icons.palette_outlined,
                            label: 'Artworks listed',
                            value: '${works.length}',
                          ),
                          _ProfileInsightTile(
                            icon: Icons.payments_outlined,
                            label: 'Sales',
                            value: '$salesCount',
                          ),
                          _ProfileInsightTile(
                            icon: Icons.star_rounded,
                            label: 'Avg. rating',
                            value: averageRating == 0
                                ? '—'
                                : averageRating.toStringAsFixed(1),
                          ),
                          _ProfileInsightTile(
                            icon: Icons.forum_outlined,
                            label: 'Commission threads',
                            value: '$commissionInsightCount',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Portfolio grid
          if (auth.isArtist) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text('Portfolio', style: _fbSectionTitle),
                    const Spacer(),
                    SegmentedButton<bool>(
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor:
                            EditorialColors.tribalRed.withValues(alpha: 0.14),
                        selectedForegroundColor: EditorialColors.tribalRed,
                        foregroundColor: EditorialColors.charcoal,
                        side: BorderSide(
                          color: EditorialColors.border.withValues(alpha: 0.9),
                        ),
                      ),
                      segments: [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Posts', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Commissions', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ],
                      selected: {_showArtworks},
                      onSelectionChanged: (v) {
                        setState(() => _showArtworks = v.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_showArtworks)
              if (works.isEmpty)
                SliverToBoxAdapter(
                  child: _PortfolioEmptyPlaceholder(
                    title: 'No artworks yet',
                    subtitle: 'Upload a piece — your portfolio is how collectors discover you.',
                    cta: 'Upload artwork',
                    icon: Icons.image_outlined,
                    route: '/create',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.74,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      childCount: works.length,
                      (context, index) {
                        final item = works[index];
                        return ArtworkCard(
                          artwork: item,
                          onTap: () => context.push('/artwork/${item.id}'),
                        );
                      },
                    ),
                  ),
                )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: commissions
                          .where(
                            (c) =>
                                c.artistId == currentUserId ||
                                c.artistName == displayName,
                          )
                          .isEmpty
                      ? const _PortfolioEmptyPlaceholder(
                          title: 'No commission threads',
                          subtitle: 'Commission requests tied to your work show up here.',
                          cta: 'Messages',
                          icon: Icons.chat_bubble_outline,
                          route: '/messages',
                        )
                      : Column(
                          children: commissions
                              .where(
                                (c) =>
                                    c.artistId == currentUserId ||
                                    c.artistName == displayName,
                              )
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    child: ListTile(
                                      title: Text(item.title),
                                      subtitle: Text(
                                        item.clientName.isEmpty ? item.brief : '${item.clientName} · ${item.brief}',
                                      ),
                                      trailing: orderStatusChip(item.status),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      tileColor: const Color(0xFFF8F9FB),
                                      onTap: () {},
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  static final TextStyle _fbSectionTitle = GoogleFonts.inter(
    fontWeight: FontWeight.w800,
    fontSize: 17,
    letterSpacing: -0.3,
    color: EditorialColors.ink,
  );
}

/// Lightweight mesh over the profile banner (no assets).
class _ProfileHeaderMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final g = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.09),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.18, size.height * 0.08), radius: size.width));
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.92), size.width * 0.45, g);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.038)
      ..strokeWidth = 1;
    for (double x = -40; x < size.width + 80; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x + 80, size.height), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileStatStrip extends StatelessWidget {
  const _ProfileStatStrip({
    required this.postsCount,
    required this.followers,
    required this.following,
  });

  final int postsCount;
  final int followers;
  final int following;

  @override
  Widget build(BuildContext context) {
    Widget cell(String value, String label) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: EditorialColors.tribalRed,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.35,
                  color: EditorialColors.muted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dividerColor =
        EditorialColors.border.withValues(alpha: 0.65);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EditorialColors.border.withValues(alpha: 0.76),
        ),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          cell('$postsCount', 'Posts'),
          SizedBox(
            height: 40,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: dividerColor,
            ),
          ),
          cell('$followers', 'Fans'),
          SizedBox(
            height: 40,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: dividerColor,
            ),
          ),
          cell('$following', 'Watching'),
        ],
      ),
    );
  }
}

class _FbCard extends StatelessWidget {
  const _FbCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: EditorialColors.border.withValues(alpha: 0.78),
        ),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

class _FbOutlineAction extends StatelessWidget {
  const _FbOutlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: EditorialColors.charcoal,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          side: BorderSide(color: EditorialColors.tribalGold.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      ),
    );
  }
}

class _ProfileInsightsGrid extends StatelessWidget {
  const _ProfileInsightsGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    assert(tiles.length == 4, 'Expected four insight tiles');
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 10),
            Expanded(child: tiles[1]),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: tiles[2]),
            const SizedBox(width: 10),
            Expanded(child: tiles[3]),
          ],
        ),
      ],
    );
  }
}

class _ProfileInsightTile extends StatelessWidget {
  const _ProfileInsightTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            EditorialColors.tribalCream.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: EditorialColors.border.withValues(alpha: 0.78),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: EditorialColors.tribalMaroon.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              height: 1.05,
              color: EditorialColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: EditorialColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioEmptyPlaceholder extends StatelessWidget {
  const _PortfolioEmptyPlaceholder({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: EditorialColors.border),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: EditorialColors.muted, height: 1.45),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push(route),
            style: FilledButton.styleFrom(
              backgroundColor: EditorialColors.tribalRed.withValues(alpha: 0.12),
              foregroundColor: EditorialColors.tribalRed,
            ),
            child: Text(cta, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
