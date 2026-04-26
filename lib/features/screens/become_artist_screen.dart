import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/presentation/auth_state.dart';

// ============================================================================
// BECOME AN ARTIST SCREEN - Artist Application
// ============================================================================
class BecomeArtistScreen extends StatefulWidget {
  const BecomeArtistScreen({super.key});

  @override
  State<BecomeArtistScreen> createState() => _BecomeArtistScreenState();
}

class _BecomeArtistScreenState extends State<BecomeArtistScreen> {
  final _styleController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  String? _selectedMedium;
  bool _agreeToTerms = false;
  int _currentStep = 0;

  static const _mediums = [
    'Painting',
    'Digital Art',
    'Photography',
    'Sculpture',
    'Illustration',
    'Mixed Media',
    'Printmaking',
    'Other',
  ];

  @override
  void dispose() {
    _styleController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return _selectedMedium != null;
      case 1:
        return _styleController.text.trim().isNotEmpty &&
            _bioController.text.trim().isNotEmpty;
      case 2:
        return _experienceController.text.trim().isNotEmpty &&
            _agreeToTerms;
      default:
        return false;
    }
  }

  void _submitApplication() {
    if (!_isStepValid(0) || !_isStepValid(1) || !_isStepValid(2)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all steps')),
      );
      return;
    }

    final auth = context.read<AuthState>();
    // In a real app, this would send the application to the backend
    // For now, we'll just mark the user as having applied
    auth.completeArtistOnboarding(
      style: _styleController.text.trim(),
      bio: _bioController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Application submitted! Admins will review your portfolio within 2-3 business days.',
        ),
        duration: Duration(seconds: 4),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.go('/profile');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFFFAEBDC).withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            children: [
              const SizedBox(height: 20),

              // Header
              Text(
                'Become a Verified Artist',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Share your creative work with our community. Showcase your portfolio and connect with collectors.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black54,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 32),

              // Step Indicator
              _StepIndicator(currentStep: _currentStep),
              const SizedBox(height: 32),

              // Step 1: Select Medium
              if (_currentStep == 0) ...[
                Text(
                  'What is your primary art medium? *',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _mediums.map((medium) {
                    final selected = _selectedMedium == medium;
                    return FilterChip(
                      selected: selected,
                      label: Text(medium),
                      backgroundColor: Colors.white,
                      selectedColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                      side: BorderSide(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFFE4D8CB),
                        width: selected ? 1.5 : 1,
                      ),
                      onSelected: (value) {
                        setState(() => _selectedMedium = value ? medium : null);
                      },
                    );
                  }).toList(),
                ),
              ],

              // Step 2: About Your Art
              if (_currentStep == 1) ...[
                Text(
                  'Tell us about your artistic style *',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _styleController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Abstract, Contemporary, Digital',
                    hintStyle: TextStyle(color: Colors.black26),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE4D8CB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE4D8CB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'About your art and creative journey *',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bioController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Share your artistic vision, inspiration, what makes your work unique...',
                    hintStyle: TextStyle(color: Colors.black26),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE4D8CB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE4D8CB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_bioController.text.length}/500 characters',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ],

              // Step 3: Experience & Agreement
              if (_currentStep == 2) ...[
                Text(
                  'Your creative background *',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _experienceController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Years of experience, awards, exhibitions, or notable works...',
                    hintStyle: TextStyle(color: Colors.black26),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE4D8CB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE4D8CB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _InfoBox(
                  icon: Icons.info_outlined,
                  title: 'Verification Process',
                  description:
                      'Your application will be reviewed by our admin team within 2-3 business days. Upload sample artworks to your portfolio to improve your chances of approval.',
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _agreeToTerms,
                  onChanged: (val) {
                    setState(() => _agreeToTerms = val ?? false);
                  },
                  title: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Artist Terms of Service',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Navigation Buttons
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _currentStep--);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _currentStep < 2
                          ? _isStepValid(_currentStep)
                              ? () {
                                  setState(() => _currentStep++);
                                }
                              : null
                          : _submitApplication,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _currentStep < 2 ? 'Next' : 'Submit Application',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (index) {
          final isActive = index <= currentStep;
          final isCompleted = index < currentStep;
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    border: Border.all(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFFE4D8CB),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ['Medium', 'Profile', 'Confirm'][index],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isActive ? Colors.black87 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoBox({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
