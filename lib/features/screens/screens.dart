import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth/domain/auth_status.dart';
import '../auth/presentation/auth_state.dart';
import '../entities/models/artwork.dart';
import '../entities/models/auction.dart';
import '../entities/models/order.dart';
import '../payments/data/mock_payment_gateway.dart';
import '../shared/data/mock_seeder.dart';
import '../shared/widgets/artwork_card.dart';
import '../admin/presentation/screens/admin_dashboard_screen.dart';

// ============================================================================
// SPLASH SCREEN - Logo Animation Only
// ============================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // No manual navigation here anymore.
    // GoRouter's redirect logic handles navigation based on AuthStatus.
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF8F1414),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                'assets/images/artflow_logo.png',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// REGISTER/LOGIN SCREEN - Unified Authentication UI
// ============================================================================
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    // Check if mode is passed in query params
    final uri = Uri.base;
    if (uri.queryParameters['mode'] == 'register') {
      _isLogin = false;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email address');
      return false;
    }
    if (!_isValidEmail(_emailController.text.trim())) {
      _showError('Please enter a valid email address');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return false;
    }

    if (!_isLogin) {
      if (_fullNameController.text.trim().isEmpty) {
        _showError('Please enter your full name');
        return false;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('Passwords do not match');
        return false;
      }
      if (!_agreeToTerms) {
        _showError('Please agree to the Terms of Service');
        return false;
      }
    }
    return true;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_validateInputs()) return;

    final auth = context.read<AuthState>();

    if (_isLogin) {
      await auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted && auth.isAuthenticated) {
        if (auth.isAdmin) {
          context.go('/admin');
        } else {
          context.go('/');
        }
      }
    } else {
      await auth.register(
        name: _fullNameController.text.trim(),
        role: 'buyer',
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted && auth.isAuthenticated) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
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

              // ============ HEADER ============
              Center(
                child: Column(
                  children: [
                    Text(
                      _isLogin ? 'Welcome back' : 'Create your account',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isLogin
                          ? 'Log in to discover and collect amazing art'
                          : 'Join ArtFlow to discover and collect amazing art',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // ============ FORM FIELDS ============
              if (!_isLogin) ...[
                // Full Name
                _FormField(
                  label: 'Full Name',
                  hint: 'Enter your name',
                  controller: _fullNameController,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
              ],

              // Email Address
              _FormField(
                label: 'Email Address',
                hint: 'Enter your email',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Password
              _FormField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordController,
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscurePassword,
                onTogglePassword: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              const SizedBox(height: 20),

              if (!_isLogin) ...[
                // Confirm Password
                _FormField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onTogglePassword: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Terms & Conditions
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _agreeToTerms,
                  onChanged: (val) {
                    setState(() => _agreeToTerms = val ?? false);
                  },
                  title: RichText(
                    text: TextSpan(
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ] else
                const SizedBox(height: 8),

              // ============ CTA BUTTONS ============
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: auth.status == AuthStatus.checking
                      ? null
                      : _handleSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: auth.status == AuthStatus.checking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLogin ? 'Sign In' : 'Create Account',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Skip for now
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    context.read<AuthState>().setAuthenticated(
                      role: UserRole.buyer,
                    );
                    context.go('/');
                  },
                  child: Text(
                    'Skip for now',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: Colors.black54),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ============ TOGGLE LOGIN/REGISTER ============
              Center(
                child: Wrap(
                  spacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _isLogin = !_isLogin);
                        _fullNameController.clear();
                        _emailController.clear();
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      },
                      child: Text(
                        _isLogin ? 'Create account' : 'Sign in',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    return Scaffold(
      body: Container(
        width: double.infinity,
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
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.pending_actions_rounded,
                  size: 80,
                  color: Color(0xFFB71B1B),
                ),
                const SizedBox(height: 32),
                Text(
                  'Application Under Review',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your artist application has been submitted. Our team is currently reviewing your profile and sample artworks. This usually takes 24-48 hours.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71B1B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Return to Home'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await auth.setUnauthenticated();
                    if (context.mounted) context.go('/welcome');
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onTogglePassword;
  final TextInputType keyboardType;

  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onTogglePassword,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword && obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.black26,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black54,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
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
      ],
    );
  }
}

// ============================================================================
// BUYER ONBOARDING SCREEN - Personalized Experience Setup
// ============================================================================
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
    'Sculpture',
    'Photography',
    'Installation',
    'Mixed Media',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
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
                "What's your style?",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Select your art interests so we can personalize your feed with artworks you'll love.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Interest Chips
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _interests.map((item) {
                  final selected = _selected.contains(item);
                  return FilterChip(
                    selected: selected,
                    label: Text(item),
                    backgroundColor: Colors.white,
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    side: BorderSide(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0xFFE4D8CB),
                      width: selected ? 1.5 : 1,
                    ),
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

              const SizedBox(height: 40),

              // Progress indicator
              Center(
                child: Text(
                  '${_selected.length} interests selected',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ),

              const SizedBox(height: 20),

              // CTA Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    context.read<AuthState>().completeBuyerOnboarding(
                      preferences: _selected.toList(),
                    );
                    context.go('/');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue to Explore',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => context.go('/'),
                  child: Text(
                    'Skip this step',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: Colors.black54),
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

// ============================================================================
// ARTIST ONBOARDING SCREEN - Creator Profile Setup
// ============================================================================
class ArtistOnboardingScreen extends StatefulWidget {
  const ArtistOnboardingScreen({super.key});

  @override
  State<ArtistOnboardingScreen> createState() => _ArtistOnboardingScreenState();
}

class _ArtistOnboardingScreenState extends State<ArtistOnboardingScreen> {
  final _styleController = TextEditingController();
  final _bioController = TextEditingController();
  final _penNameController = TextEditingController();
  final _portfolioController = TextEditingController();
  String _selectedMedium = 'Painting';
  final List<String> _sampleArtworks = [];
  bool _isSubmitting = false;

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
    _penNameController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  bool _isComplete() {
    final bio = _bioController.text.trim();
    return _styleController.text.trim().isNotEmpty &&
        bio.isNotEmpty &&
        bio.length <= 500 &&
        _penNameController.text.trim().isNotEmpty &&
        _portfolioController.text.trim().isNotEmpty &&
        _sampleArtworks.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
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
                'Create your artist profile',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Let collectors know about your creative journey and artistic style.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Primary Art Style
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primary Medium *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMedium,
                    items: _mediums
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedMedium = val!),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.category_outlined),
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Primary Art Style
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primary Art Style *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _styleController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'e.g. Abstract, Digital, Oil Painting',
                      hintStyle: TextStyle(color: Colors.black26),
                      prefixIcon: const Icon(Icons.palette_outlined),
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
                ],
              ),
              const SizedBox(height: 24),

              // Pen Name
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Artist Pen Name *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _penNameController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Enter your artist or pen name',
                      hintStyle: const TextStyle(color: Colors.black26),
                      prefixIcon: const Icon(Icons.person_outline),
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
                ],
              ),
              const SizedBox(height: 24),

              // Portfolio Link
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portfolio Link *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _portfolioController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Link to your work (Behance, Dribbble, etc.)',
                      hintStyle: const TextStyle(color: Colors.black26),
                      prefixIcon: const Icon(Icons.link_outlined),
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
                ],
              ),
              const SizedBox(height: 24),

              // Artist Bio
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Your Art *',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 500,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText:
                          'Tell collectors about your creative journey, inspiration, and what makes your work unique...',
                      counterText:
                          '', // Hide default counter to use custom one below
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
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sample Artworks
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample Artworks (Optional)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Add Button
                        GestureDetector(
                          onTap: () {
                            // Simulate adding an image
                            setState(() {
                              _sampleArtworks.add(MockSeeder.placeholder);
                            });
                          },
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE4D8CB),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Colors.black54,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add Image',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Image List
                        ..._sampleArtworks.asMap().entries.map((entry) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(entry.value),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _sampleArtworks.removeAt(entry.key);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // CTA Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isComplete() && !_isSubmitting
                      ? () async {
                          setState(() => _isSubmitting = true);
                          try {
                            await context
                                .read<AuthState>()
                                .submitArtistApplication(
                                  style: _styleController.text.trim(),
                                  bio: _bioController.text.trim(),
                                  medium: _selectedMedium,
                                  penName: _penNameController.text.trim(),
                                  portfolioUrl: _portfolioController.text
                                      .trim(),
                                  sampleArtworks: _sampleArtworks,
                                );
                            if (mounted) context.go('/verification');
                          } finally {
                            if (mounted) setState(() => _isSubmitting = false);
                          }
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Launch Dashboard',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => context.go('/'),
                  child: Text(
                    'Skip for now',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: Colors.black54),
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    final artworks = MockSeeder.artworks;
    final featured = artworks.where((item) => item.isFeatured).toList();
    final categories = MockSeeder.categories;
    final myCommissions = MockSeeder.commissions;

    final firstFeatured = featured.isNotEmpty ? featured.first : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        Text(
          "Maayong adlaw, ${auth.displayName.split(' ').first}",
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

        const PartnerCarousel(),
        const SizedBox(height: 20),
        const FeaturedArtistSection(),
        const SizedBox(height: 18),

        // ================= FEATURED =================
        if (firstFeatured != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.16),
              ),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  const Color(0xFFF1E5CE).withOpacity(0.6),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.08),
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
                        'Featured Artwork',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        firstFeatured.artistName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        firstFeatured.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () =>
                            context.push('/artwork/${firstFeatured.id}'),
                        child: const Text('View Artwork'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    firstFeatured.imageUrl ?? MockSeeder.placeholder,
                    width: 94,
                    height: 94,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 94,
                      height: 94,
                      color: const Color(0xFFF1E5CE),
                      child: const Icon(Icons.image_outlined),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // ================= CATEGORIES =================
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

              final isSelected = index == 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
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
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // ================= TRENDING =================
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

        if (artworks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text("No artworks yet")),
          )
        else
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

class _PartnerSlide {
  const _PartnerSlide({
    required this.label,
    required this.description,
    required this.color,
    required this.assetPath,
  });

  final String label;
  final String description;
  final Color color;
  final String assetPath;
}

class PartnerCarousel extends StatefulWidget {
  const PartnerCarousel({super.key});

  @override
  State<PartnerCarousel> createState() => _PartnerCarouselState();
}

class _PartnerCarouselState extends State<PartnerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.88);
  int _currentIndex = 0;

  static const slides = <_PartnerSlide>[
    _PartnerSlide(
      label: 'Partnered Orgs',
      description:
          'Partnering with local organizations to support Bukidnon artists and craftspeople.',
      color: Color(0xFF7B3F00),
      assetPath: 'assets/images/artizan_logo.png',
    ),
    _PartnerSlide(
      label: 'Bukidnon Artists',
      description:
          'Highlighting Bukidnon makers and artists through curated collaborations.',
      color: Color(0xFF1E4F3F),
      assetPath: 'assets/images/bukidnon_artists_logo.png',
    ),
    _PartnerSlide(
      label: 'Artizan Community',
      description:
          'Growing artisan networks with trusted local partnership programs.',
      color: Color(0xFF5C2B8A),
      assetPath: 'assets/images/artizan_logo.png',
    ),
  ];

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Partner highlights',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _controller,
            itemCount: slides.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final slide = slides[index];

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double scale = 1.0;

                  if (_controller.position.haveDimensions) {
                    scale = (_controller.page! - index).abs();
                    scale = (1 - (scale * 0.15)).clamp(0.9, 1.0);
                  }

                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: [slide.color, slide.color.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // logo bubble
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Image.asset(
                          slide.assetPath,
                          width: 36,
                          height: 36,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        slide.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        slide.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),

                      const Spacer(),

                      // optional CTA (cleaner than next/prev buttons)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {},
                          child: const Text('Learn more →'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // ================= DOT INDICATOR =================
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (index) {
            final active = index == _currentIndex;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: active ? 22 : 8,
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class FeaturedArtistSection extends StatelessWidget {
  const FeaturedArtistSection({super.key});

  @override
  Widget build(BuildContext context) {
    // stable dedupe (keeps order instead of Set randomizing)
    final artists = <String>[];
    for (final artwork in MockSeeder.artworks) {
      if (!artists.contains(artwork.artistName)) {
        artists.add(artwork.artistName);
      }
    }

    if (artists.isEmpty) {
      return const SizedBox.shrink();
    }

    // sort by rating (better "featured" logic)
    artists.sort(
      (a, b) =>
          MockSeeder.averageRating(b).compareTo(MockSeeder.averageRating(a)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Featured artists',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: artists.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final artistName = artists[index];
              final rating = MockSeeder.averageRating(artistName);

              final role = index == 0
                  ? 'Top artist'
                  : index < 3
                  ? 'Featured creator'
                  : 'Bukidnon artist';

              return _FeaturedArtistCard(
                artistName: artistName,
                rating: rating,
                role: role,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedArtistCard extends StatelessWidget {
  const _FeaturedArtistCard({
    required this.artistName,
    required this.rating,
    required this.role,
  });

  final String artistName;
  final double rating;
  final String role;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // later: navigate to artist profile
          // context.push('/artist/$artistName');
        },
        child: Container(
          width: 185,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  artistName.isNotEmpty ? artistName[0] : 'A',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                role,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),

              const Spacer(),

              // rating row
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    rating == 0 ? 'New' : rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 34,
                child: FilledButton.tonal(
                  onPressed: () {},
                  child: const Text('View profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArtistDashboardScreen extends StatelessWidget {
  const ArtistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final commissions = MockSeeder.commissions;
    final openCommissions = commissions.where((c) {
      final s = c.status.toLowerCase();
      return s == 'pending' || s == 'active' || s == 'in review';
    }).length;
    final completedCommissions = commissions
        .where((c) => c.status.toLowerCase() == 'completed')
        .length;
    final myArtworks = MockSeeder.artworks
        .where((item) => item.artistName == auth.displayName)
        .toList();
    final avgRating = MockSeeder.averageRating(auth.displayName);
    final myArtworkIds = myArtworks.map((a) => a.id).toSet();
    final revenue = MockSeeder.orders
        .where((o) => myArtworkIds.contains(o.artworkId))
        .fold<double>(0, (sum, item) => sum + item.total);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Artist Dashboard',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Open Commissions',
                value: '$openCommissions',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Completed',
                value: '$completedCommissions',
              ),
            ),
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
              child: _MetricCard(
                label: 'Portfolio',
                value: '${myArtworks.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'Inquiries',
                value:
                    '${MockSeeder.analyticsInquiries[auth.displayName] ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (auth.isVerified)
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
  String _selectedStyle = 'all';
  String _selectedMediumType = 'all';
  final _artistController = TextEditingController();
  RangeValues _priceRange = const RangeValues(0, 6000);

  @override
  void dispose() {
    _artistController.dispose();
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
          _selectedStyle == 'all' || _artStyleFor(item) == _selectedStyle;
      final mediumTypeMatch =
          _selectedMediumType == 'all' ||
          _mediumTypeFor(item) == _selectedMediumType;
      final priceMatch =
          item.price >= _priceRange.start && item.price <= _priceRange.end;
      final queryMatch =
          item.title.toLowerCase().contains(_query.toLowerCase()) ||
          item.artistName.toLowerCase().contains(_query.toLowerCase()) ||
          (item.description?.toLowerCase().contains(_query.toLowerCase()) ??
              false);
      return categoryMatch &&
          queryMatch &&
          artistMatch &&
          styleMatch &&
          mediumTypeMatch &&
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
        (a, b) => MockSeeder.isBoosted(
          b.id,
        ).toString().compareTo(MockSeeder.isBoosted(a.id).toString()),
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
          DropdownButtonFormField<String>(
            initialValue: _selectedStyle,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All styles')),
              DropdownMenuItem(value: 'realism', child: Text('Realism')),
              DropdownMenuItem(value: 'abstract', child: Text('Abstract')),
              DropdownMenuItem(value: 'anime', child: Text('Anime')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedStyle = value;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Art style',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedMediumType,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All medium types')),
              DropdownMenuItem(
                value: 'traditional',
                child: Text('Traditional'),
              ),
              DropdownMenuItem(value: 'digital', child: Text('Digital')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedMediumType = value;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Medium type',
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
    final conversationId = MockSeeder.getOrCreateConversation(
      artwork.artistName,
    ).id;
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
                  MockSeeder.addOrder(
                    artworkId: artwork.id,
                    total: artwork.price,
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
                initialValue: _selectedCategory,
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
            if (!auth.isVerified && !auth.isAdmin) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'You must be a verified artist to publish artworks.',
                  ),
                ),
              );
              return;
            }
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
              id:
                  editing?.id ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
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
    final salesCount = works.where((w) => MockSeeder.isSold(w.id)).length;
    final commissions = MockSeeder.commissions;

    final aboutText = bio.isEmpty
        ? 'Share a bit about your creative journey, style, or local craftsmanship.'
        : bio;

    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.82),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/edit-profile'),
                        icon: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 66, 16, 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 36),
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: Colors.black87),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              username,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Chip(
                                  label: Text(
                                    auth.isAdmin
                                        ? 'Admin'
                                        : auth.isVerifiedArtist
                                        ? 'Verified Artist'
                                        : auth.isArtist
                                        ? 'Artist'
                                        : 'Buyer',
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(width: 10),
                                Chip(
                                  label: Text(
                                    auth.isArtist ? 'Creator' : 'Collector',
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -44,
                        child: Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1E5CE),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              userInitial,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
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
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('About', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  aboutText,
                  style: const TextStyle(color: Colors.black87, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              // Action Buttons Section
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/orders'),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Orders'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/payments'),
                      icon: const Icon(Icons.payment_outlined),
                      label: const Text('Payments'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Artist Application Logic
              if (!auth.isArtist && !auth.verificationSubmitted)
                FilledButton.icon(
                  onPressed: () => context.push('/become-artist'),
                  icon: const Icon(Icons.brush_outlined),
                  label: const Text('Become an Artist'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                )
              else if (auth.verificationSubmitted && !auth.isVerified)
                OutlinedButton.icon(
                  onPressed: () => context.push('/verification'),
                  icon: const Icon(Icons.pending_actions_rounded),
                  label: const Text('Application Pending'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: const Color(0xFFB71B1B),
                    side: const BorderSide(color: Color(0xFFB71B1B)),
                  ),
                )
              else if (auth.isAdmin)
                OutlinedButton.icon(
                  onPressed: () => context.push('/admin'),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Admin Panel'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
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
          FilledButton(onPressed: () => context.push(route), child: Text(cta)),
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
                          MockSeeder.updateCommissionStatus(
                            item.id,
                            'Completed',
                          );
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
  Future<void> _showPaymentReportDialog(
    BuildContext context,
    Order order,
  ) async {
    final amountController = TextEditingController(
      text: order.total.toStringAsFixed(0),
    );
    String method = order.paymentMethod ?? 'GCash';
    XFile? proof;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Report Payment: #${order.id}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Payment amount',
                        border: OutlineInputBorder(),
                        prefixText: 'PHP ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: method,
                      items: const [
                        DropdownMenuItem(value: 'GCash', child: Text('GCash')),
                        DropdownMenuItem(value: 'Maya', child: Text('Maya')),
                        DropdownMenuItem(
                          value: 'Bank Transfer',
                          child: Text('Bank Transfer'),
                        ),
                      ],
                      onChanged: (value) {
                        method = value ?? 'GCash';
                      },
                      decoration: const InputDecoration(
                        labelText: 'Payment method',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final selected = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (selected != null) {
                          setDialogState(() {
                            proof = selected;
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(
                        proof == null
                            ? 'Upload proof (optional)'
                            : 'Proof: ${proof!.name}',
                      ),
                    ),
                  ],
                ),
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
      },
    );

    if (submitted == true) {
      final amount = double.tryParse(amountController.text.trim()) ?? 0;
      setState(() {
        MockSeeder.reportExternalPayment(
          orderId: order.id,
          amount: amount <= 0 ? order.total : amount,
          method: method,
          proofFileName: proof?.name,
        );
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment report submitted.')),
        );
      }
    }
    amountController.dispose();
  }

  void _confirmPayment(String orderId) {
    setState(() {
      MockSeeder.confirmPayment(orderId);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment marked confirmed.')));
  }

  void _disputePayment(String orderId) {
    setState(() {
      MockSeeder.disputePayment(orderId);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment marked disputed.')));
  }

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
                items: [1, 2, 3, 4, 5].map((value) {
                  return DropdownMenuItem(value: value, child: Text('$value'));
                }).toList(),
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Artwork ${item.artworkId}'),
                      const SizedBox(height: 4),
                      _paymentChip(item.paymentStatus),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${item.total.toStringAsFixed(0)}'),
                      const SizedBox(height: 2),
                      Text(
                        item.status,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () =>
                            _showPaymentReportDialog(context, item),
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
                if (item.reportedAmount != null || item.paymentMethod != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Reported: PHP ${(item.reportedAmount ?? item.total).toStringAsFixed(0)}'
                            ' via ${item.paymentMethod ?? 'N/A'}'
                            '${item.paymentProofName != null ? ' (${item.paymentProofName})' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (item.paymentStatus.toLowerCase() == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _confirmPayment(item.id),
                          child: const Text('Artist Confirm'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _disputePayment(item.id),
                          child: const Text('Mark Disputed'),
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

class AuctionsScreen extends StatefulWidget {
  const AuctionsScreen({super.key});

  @override
  State<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends State<AuctionsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _countdownLabel(DateTime endAt) {
    final diff = endAt.difference(DateTime.now());
    if (diff.isNegative) {
      return 'Ended';
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _placeBidDialog(Auction auction) async {
    final controller = TextEditingController(
      text: (auction.currentBid + 100).toStringAsFixed(0),
    );
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Place bid: ${auction.title}'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Your bid',
              prefixText: 'PHP ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Place Bid'),
            ),
          ],
        );
      },
    );
    if (submitted == true) {
      final amount = double.tryParse(controller.text.trim()) ?? 0;
      final ok = MockSeeder.placeBid(auctionId: auction.id, amount: amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'Bid accepted.'
                  : 'Bid must be higher than current bid and auction must be active.',
            ),
          ),
        );
        setState(() {});
      }
    }
    controller.dispose();
  }

  void _finalizeAuction(Auction auction) {
    final order = MockSeeder.settleAuction(auction.id);
    setState(() {});
    if (order != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You won! Order #${order.id} created.'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => context.push('/orders'),
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Auction finalized. No new order was created for your account.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auctions = MockSeeder.auctions;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Live Auctions', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        ...auctions.map((auction) {
          final ended = DateTime.now().isAfter(auction.endAt);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${auction.artistName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statusChip(
                        'Highest: PHP ${auction.currentBid.toStringAsFixed(0)}',
                      ),
                      const SizedBox(width: 8),
                      _statusChip('Ends in ${_countdownLabel(auction.endAt)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current highest bidder: ${auction.highestBidder == 'me' ? 'You' : auction.highestBidder}',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: ended || auction.completed
                              ? null
                              : () => _placeBidDialog(auction),
                          child: const Text('Place Bid'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: ended && !auction.completed
                              ? () => _finalizeAuction(auction)
                              : null,
                          child: const Text('Finalize'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

Widget _paymentChip(String paymentStatus) {
  final normalized = paymentStatus.toLowerCase();
  Color color;
  if (normalized == 'confirmed') {
    color = const Color(0xFF166534);
  } else if (normalized == 'disputed') {
    color = const Color(0xFFB91C1C);
  } else {
    color = const Color(0xFF92400E);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      'Payment: ${paymentStatus[0].toUpperCase()}${paymentStatus.substring(1)}',
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );
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
                item.read
                    ? Icons.notifications_none
                    : Icons.notifications_active,
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
    final artistName = works.isNotEmpty
        ? works.first.artistName
        : 'Artist #$artistId';
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
              avgRating == 0
                  ? 'No ratings yet'
                  : 'Rating ${avgRating.toStringAsFixed(1)}',
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
  String _selectedStyle = 'all';
  String _selectedMediumType = 'all';
  RangeValues _priceRange = const RangeValues(0, 10000);

  @override
  Widget build(BuildContext context) {
    final items = MockSeeder.artworks.where((item) {
      final query = _query.toLowerCase();
      final queryMatch =
          item.title.toLowerCase().contains(query) ||
          item.artistName.toLowerCase().contains(query) ||
          (item.description?.toLowerCase().contains(query) ?? false) ||
          (item.medium?.toLowerCase().contains(query) ?? false);
      final styleMatch =
          _selectedStyle == 'all' || _artStyleFor(item) == _selectedStyle;
      final mediumTypeMatch =
          _selectedMediumType == 'all' ||
          _mediumTypeFor(item) == _selectedMediumType;
      final priceMatch =
          item.price >= _priceRange.start && item.price <= _priceRange.end;
      return queryMatch && styleMatch && mediumTypeMatch && priceMatch;
    }).toList();
    final byCategory = <String, List<Artwork>>{};
    for (final item in items) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }

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
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _selectedStyle,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All styles')),
            DropdownMenuItem(value: 'realism', child: Text('Realism')),
            DropdownMenuItem(value: 'abstract', child: Text('Abstract')),
            DropdownMenuItem(value: 'anime', child: Text('Anime')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedStyle = value;
              });
            }
          },
          decoration: const InputDecoration(
            labelText: 'Art style',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _selectedMediumType,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All medium types')),
            DropdownMenuItem(value: 'traditional', child: Text('Traditional')),
            DropdownMenuItem(value: 'digital', child: Text('Digital')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMediumType = value;
              });
            }
          },
          decoration: const InputDecoration(
            labelText: 'Medium type',
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
        const SizedBox(height: 14),
        Text(
          'Browse by category',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (byCategory.isEmpty)
          const Text('No artworks match your search and filters.'),
        ...byCategory.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.replaceAll('_', ' ').toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 260,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: entry.value.map((item) {
                      return SizedBox(
                        width: 190,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ArtworkCard(
                            artwork: item,
                            onTap: () => context.push('/artwork/${item.id}'),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

String _mediumTypeFor(Artwork item) {
  final value = (item.medium ?? '').toLowerCase();
  if (value.contains('digital')) {
    return 'digital';
  }
  return 'traditional';
}

String _artStyleFor(Artwork item) {
  final value =
      '${item.category} ${item.medium ?? ''} ${item.description ?? ''}'
          .toLowerCase();
  if (value.contains('anime') || value.contains('character')) {
    return 'anime';
  }
  if (value.contains('abstract') || value.contains('mixed')) {
    return 'abstract';
  }
  return 'realism';
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.isAdmin) {
      return const Scaffold(body: Center(child: Text('Admin access only.')));
    }
    return const AdminDashboardScreen();
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
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );
}
