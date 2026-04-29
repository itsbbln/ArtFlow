import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../entities/models/artwork.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/editorial_colors.dart';

/// Magazine-style “Spotlight” block — full-width art with overlay copy.
class FeaturedArtistSection extends StatelessWidget {
  const FeaturedArtistSection({super.key, required this.featured});

  final Artwork? featured;

  String _imageUrl(Artwork a) {
    if (a.imageUrl != null && a.imageUrl!.isNotEmpty) return a.imageUrl!;
    if (a.images.isNotEmpty) return a.images.first;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final item = featured;
    if (item == null) {
      return const SizedBox.shrink();
    }

    final imageUrl = _imageUrl(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      EditorialColors.tribalRed,
                      EditorialColors.tribalGold.withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SPOTLIGHT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w900,
                      color: EditorialColors.tribalGold,
                    ),
                  ),
                  Text(
                    'Featured this week',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: EditorialColors.ink,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => context.push('/artwork/${item.id}'),
            child: Ink(
              height: 320,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppShadows.raised,
                border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.25),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(27),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isEmpty)
                      Container(color: EditorialColors.tribalMaroon.withValues(alpha: 0.25))
                    else
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, _, _) =>
                            Container(color: EditorialColors.parchmentDeep),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.02),
                              Colors.black.withValues(alpha: 0.78),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: EditorialColors.tribalGold.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        size: 14, color: EditorialColors.tribalMaroon),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Featured artist',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: EditorialColors.tribalMaroon,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                item.artistName,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.08,
                                  shadows: [
                                    Shadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 14),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                  color: Colors.white.withValues(alpha: 0.94),
                                  shadows: [
                                    Shadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 12),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  FilledButton.tonal(
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.94),
                                      foregroundColor: EditorialColors.tribalRed,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () =>
                                        context.push('/artwork/${item.id}'),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Open artwork',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.arrow_outward_rounded, size: 18),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 34,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
