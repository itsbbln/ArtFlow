import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/editorial_colors.dart';
import '../auth/presentation/auth_state.dart';

class WelcomeSlide {
  const WelcomeSlide({
    required this.eyebrow,
    required this.headline,
    required this.accent,
    required this.description,
    required this.icon,
    required this.deep,
    required this.glow,
  });

  final String eyebrow;
  final String headline;
  final String accent;
  final String description;
  final IconData icon;
  final Color deep;
  final Color glow;
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  late final List<WelcomeSlide> _slides;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _slides = [
      WelcomeSlide(
        eyebrow: 'ARTFLOW',
        headline: 'Welcome to ',
        accent: 'the gallery',
        description:
            'Discover work from painters, illustrators, and makers grounded in Mindanao craft.',
        icon: Icons.museum_rounded,
        deep: EditorialColors.tribalMaroon,
        glow: EditorialColors.tribalRed.withValues(alpha: 0.9),
      ),
      WelcomeSlide(
        eyebrow: 'EXPLORE',
        headline: 'Curated ',
        accent: 'for collectors',
        description:
            'Browse pieces by medium, vibe, and price — with stories behind every upload.',
        icon: Icons.explore_rounded,
        deep: EditorialColors.tribalRed,
        glow: EditorialColors.tribalMaroon.withValues(alpha: 0.94),
      ),
      WelcomeSlide(
        eyebrow: 'SUPPORT LOCAL',
        headline: 'Buy ',
        accent: 'direct',
        description:
            'Every purchase supports creators in Bukidnon and beyond — fewer middlemen.',
        icon: Icons.favorite_rounded,
        deep: const Color(0xFFAA8F00),
        glow: EditorialColors.tribalGold.withValues(alpha: 0.95),
      ),
      WelcomeSlide(
        eyebrow: 'CREATE',
        headline: 'Open your ',
        accent: 'studio',
        description:
            'Artists showcase portfolios, run commissions, and grow an audience.',
        icon: Icons.brush_rounded,
        deep: EditorialColors.tribalMaroon,
        glow: const Color(0xFFE85C4A),
      ),
      WelcomeSlide(
        eyebrow: "LET'S GO",
        headline: 'Start ',
        accent: 'collecting today',
        description:
            'Sign in — or browse as guest — then dive into Featured and Explore.',
        icon: Icons.rocket_launch_rounded,
        deep: EditorialColors.tribalRed,
        glow: EditorialColors.tribalMaroon.withValues(alpha: 0.9),
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToSlide(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    await context.read<AuthState>().completeWelcome();
    if (!mounted) {
      return;
    }
    context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];
    final inset = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: slide.deep,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemCount: _slides.length,
                    itemBuilder: (_, i) {
                      final s = _slides[i];
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              s.deep,
                              s.glow,
                              Colors.black.withValues(alpha: 0.78),
                            ],
                            stops: const [0.0, 0.54, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, right: 12),
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: _finish,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.35,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: KeyedSubtree(
                        key: ValueKey<int>(_currentIndex),
                        child: Container(
                          width: 152,
                          height: 152,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.52),
                                Colors.white.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Icon(slide.icon, size: 62, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SizedBox(
                      height: 120,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.52),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(36)),
                child: Container(
                  color: EditorialColors.surfaceCream,
                  padding: EdgeInsets.fromLTRB(26, 26, 26, inset.bottom + 18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slide.eyebrow,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      letterSpacing: 2.35,
                                      fontWeight: FontWeight.w900,
                                      color: EditorialColors.tribalRed,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: slide.headline,
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 31,
                                            fontWeight: FontWeight.w800,
                                            height: 1.05,
                                            color: EditorialColors.ink,
                                            letterSpacing: -0.55,
                                          ),
                                        ),
                                        TextSpan(
                                          text: slide.accent,
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 31,
                                            fontWeight: FontWeight.w900,
                                            height: 1.05,
                                            letterSpacing: -0.55,
                                            color: EditorialColors.tribalRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    slide.description,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      height: 1.55,
                                      color: EditorialColors.muted
                                          .withValues(alpha: 0.98),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: List.generate(_slides.length, (i) {
                                  final active = i == _currentIndex;
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: i == _slides.length - 1 ? 0 : 6,
                                      ),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 260),
                                        height: 5,
                                        decoration: BoxDecoration(
                                          gradient: active
                                              ? LinearGradient(
                                                  colors: [
                                                    EditorialColors.tribalRed,
                                                    EditorialColors.tribalGold
                                                        .withValues(alpha: 0.95),
                                                  ],
                                                )
                                              : null,
                                          color: active
                                              ? null
                                              : EditorialColors.border
                                                  .withValues(alpha: 0.82),
                                          borderRadius: BorderRadius.circular(99),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  if (_currentIndex > 0)
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _goToSlide(_currentIndex - 1),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          side: BorderSide(
                                            color: EditorialColors.border
                                                .withValues(alpha: 0.95),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Text(
                                          'Back',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_currentIndex > 0) const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _currentIndex <
                                              _slides.length - 1
                                          ? () => _goToSlide(_currentIndex + 1)
                                          : _finish,
                                      style: FilledButton.styleFrom(
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        backgroundColor:
                                            EditorialColors.tribalRed,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        _currentIndex < _slides.length - 1
                                            ? 'Continue'
                                            : 'Enter ArtFlow',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
