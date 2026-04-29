import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/editorial_colors.dart';

class _PartnerSlide {
  const _PartnerSlide({
    required this.label,
    required this.blurb,
    required this.gradient,
    required this.assetPath,
    required this.slug,
  });

  final String label;
  final String blurb;
  final List<Color> gradient;
  final String assetPath;
  final String slug;
}

class PartnerCarousel extends StatefulWidget {
  const PartnerCarousel({super.key});

  @override
  State<PartnerCarousel> createState() => _PartnerCarouselState();
}

class _PartnerCarouselState extends State<PartnerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.86);
  int _currentIndex = 0;

  static final slides = <_PartnerSlide>[
    _PartnerSlide(
      slug: '01',
      label: 'Bukidnon Roots',
      blurb:
          'Partnering with local orgs so makers get visibility beyond the mountain.',
      gradient: [
        EditorialColors.tribalMaroon,
        const Color(0xFF8F2A1F),
      ],
      assetPath: 'assets/images/bukidnon_artists_logo.png',
    ),
    _PartnerSlide(
      slug: '02',
      label: 'Artizan Collective',
      blurb: 'Grassroots artisans, fair collaboration, repeatable programs.',
      gradient: [
        const Color(0xFF1E4F3F),
        const Color(0xFF0E3026),
      ],
      assetPath: 'assets/images/artizan_logo.png',
    ),
    _PartnerSlide(
      slug: '03',
      label: 'Community Bridges',
      blurb:
          'Cross-town creative networks — mentorship, demos, seasonal fairs.',
      gradient: [
        const Color(0xFF6B2BB3),
        const Color(0xFF3D1968),
      ],
      assetPath: 'assets/images/artizan_logo.png',
    ),
  ];

  void _onPageChanged(int index) => setState(() => _currentIndex = index);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Partners',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.35,
                color: EditorialColors.ink,
              ),
            ),
            const Spacer(),
            Text(
              '${_currentIndex + 1}/${slides.length}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                color: EditorialColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Who we amplify with • scroll',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: EditorialColors.muted.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 206,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final slide = slides[index];

              return AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  var scale = 1.0;
                  if (_controller.position.haveDimensions) {
                    scale = (_controller.page! - index).abs();
                    scale = (1 - (scale * 0.12)).clamp(0.9, 1.0);
                  }
                  return Transform.scale(scale: scale, alignment: Alignment.center, child: child);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: slide.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: slide.gradient.first.withValues(alpha: 0.38),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                        ...AppShadows.card,
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            top: -4,
                            child: Opacity(
                              opacity: 0.14,
                              child: Text(
                                slide.slug,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 84,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: ColoredBox(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      child: SizedBox(
                                        width: 62,
                                        height: 62,
                                        child: Center(
                                          child: Image.asset(
                                            slide.assetPath,
                                            width: 40,
                                            height: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.22),
                                      ),
                                    ),
                                    child: Text(
                                      'LOCAL LINK',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.4,
                                        color: EditorialColors.tribalGold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                slide.label,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                slide.blurb,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.94),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          EditorialColors.tribalGold,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: EdgeInsets.zero,
                                      textStyle: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Story'),
                                        SizedBox(width: 4),
                                        Icon(Icons.north_east_rounded,
                                            size: 16),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.swipe_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.45),
                                      size: 22),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (i) {
            final on = i == _currentIndex;
            return GestureDetector(
              onTap: () => _controller.animateToPage(
                i,
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                height: 7,
                width: on ? 36 : 8,
                decoration: BoxDecoration(
                  gradient: on
                      ? LinearGradient(
                          colors: [
                            EditorialColors.tribalGold,
                            EditorialColors.tribalRed.withValues(alpha: 0.9),
                          ],
                        )
                      : null,
                  color: on ? null : EditorialColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
