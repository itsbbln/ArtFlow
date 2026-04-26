import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/presentation/auth_state.dart';

class WelcomeSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;

  WelcomeSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
  });
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<WelcomeSlide> slides = [
    WelcomeSlide(
      title: 'Welcome to ArtFlow',
      description:
          'Discover, buy, and sell unique artwork from talented artists worldwide. Connect with creators and celebrate art.',
      icon: Icons.palette,
      backgroundColor: const Color(0xFF8F1414),
    ),
    WelcomeSlide(
      title: 'Explore Amazing Artworks',
      description:
          'Browse through thousands of unique pieces from emerging and established artists. Find art that speaks to you.',
      icon: Icons.search,
      backgroundColor: const Color(0xFFB71B1B),
    ),
    WelcomeSlide(
      title: 'Support Artists Directly',
      description:
          'Purchase directly from creators and help support the art community. Every purchase makes a difference.',
      icon: Icons.favorite,
      backgroundColor: const Color(0xFFDAAF1F),
    ),
    WelcomeSlide(
      title: 'Showcase Your Work',
      description:
          'Are you an artist? Build your portfolio, connect with collectors, and sell your creations on ArtFlow.',
      icon: Icons.brush,
      backgroundColor: const Color(0xFF8F1414),
    ),
    WelcomeSlide(
      title: 'Get Started Today',
      description:
          'Join our thriving community of art lovers and creators. Your next favorite artwork is just a tap away.',
      icon: Icons.rocket_launch,
      backgroundColor: const Color(0xFFB71B1B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToSlide(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: slides
                .map(
                  (slide) => _buildSlide(slide),
                )
                .toList(),
          ),
          // Skip Button
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: () async {
                await context.read<AuthState>().completeWelcome();
                if (mounted) {
                  context.go('/register');
                }
              },
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Navigation and Indicators
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Dot Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    slides.length,
                    (index) => GestureDetector(
                      onTap: () => _goToSlide(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Navigation Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Button
                      _currentIndex > 0
                          ? FilledButton.tonal(
                              onPressed: () => _goToSlide(_currentIndex - 1),
                              child: const Text('Previous'),
                            )
                          : const SizedBox(width: 80),
                      // Next or Get Started Button
                      _currentIndex == 0
                          ? FilledButton(
                              onPressed: () => _goToSlide(_currentIndex + 1),
                              child: const Text('-> Get Started'),
                            )
                          : _currentIndex < slides.length - 1
                              ? FilledButton(
                                  onPressed: () => _goToSlide(_currentIndex + 1),
                                  child: const Text('Next'),
                                )
                              : FilledButton(
                                  onPressed: () async {
                                    await context.read<AuthState>().completeWelcome();
                                    if (mounted) {
                                      context.go('/register');
                                    }
                                  },
                                  child: const Text('Login / Register'),
                                ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(WelcomeSlide slide) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            slide.backgroundColor,
            slide.backgroundColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              slide.icon,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                slide.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                slide.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
