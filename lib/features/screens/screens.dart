import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth/domain/auth_status.dart';
import '../auth/presentation/auth_state.dart';
import '../entities/models/artwork.dart';
import '../entities/models/commission.dart';
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
              const Color(0xFFFAEBDC).withValues(alpha: 0.6),
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
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isLogin
                          ? 'Log in to discover and collect amazing art'
                          : 'Join ArtFlow to discover and collect amazing art',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.black54,
                          ),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  onPressed: auth.status == AuthStatus.checking ? null : _handleSubmit,
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.black54,
                        ),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
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
              const Color(0xFFFAEBDC).withValues(alpha: 0.6),
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                      ),
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
              borderSide: const BorderSide(
                color: Color(0xFFE4D8CB),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE4D8CB),
              ),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFFFAEBDC).withValues(alpha: 0.6),
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
                    selectedColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.black54,
                        ),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFFFAEBDC).withValues(alpha: 0.1),
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
                    items: _mediums.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) => setState(() => _selectedMedium = val!),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.category_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      hintStyle: TextStyle(
                        color: Colors.black26,
                      ),
                      prefixIcon: const Icon(Icons.palette_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE4D8CB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE4D8CB),
                        ),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      counterText: '', // Hide default counter to use custom one below
                      hintStyle: TextStyle(
                        color: Colors.black26,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE4D8CB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE4D8CB),
                        ),
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
                              border: Border.all(color: const Color(0xFFE4D8CB), style: BorderStyle.solid),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: Colors.black54),
                                SizedBox(height: 4),
                                Text('Add Image', style: TextStyle(fontSize: 10, color: Colors.black54)),
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
                                    child: const Icon(Icons.close, size: 12, color: Colors.white),
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
                            await context.read<AuthState>().submitArtistApplication(
                                  style: _styleController.text.trim(),
                                  bio: _bioController.text.trim(),
                                  medium: _selectedMedium,
                                  penName: _penNameController.text.trim(),
                                  portfolioUrl: _portfolioController.text.trim(),
                                  sampleArtworks: _sampleArtworks,
                                );
                            if (!context.mounted) return;
                            context.go('/verification');
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
                    'Skip for now',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.black54,
                        ),
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

    final firstFeatured =
        featured.isNotEmpty ? featured.first : null;

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

        Text('Discover Local',
            style: Theme.of(context).textTheme.headlineMedium),
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
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
              ),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  const Color(0xFFF1E5CE).withValues(alpha: 0.1),
                  Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.1),
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
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
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
                        onPressed: () => context
                            .push('/artwork/${firstFeatured.id}'),
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
            Text('Categories',
                style: Theme.of(context).textTheme.titleLarge),
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
              final label =
                  categories[index].replaceAll('_', ' ');

              final isSelected = index == 0;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
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
                    color:
                        isSelected ? Colors.white : Colors.black87,
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
            Text('Trending Now',
                style: Theme.of(context).textTheme.titleLarge),
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
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 252,
            ),
            itemBuilder: (context, index) {
              final item = artworks[index];
              return ArtworkCard(
                artwork: item,
                onTap: () =>
                    context.push('/artwork/${item.id}'),
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

                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: [
                        slide.color,
                        slide.color.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
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
                          color: Colors.white.withValues(alpha: 0.1),
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
    artists.sort((a, b) =>
        MockSeeder.averageRating(b).compareTo(
              MockSeeder.averageRating(a),
            ));

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
            TextButton(
              onPressed: () {},
              child: const Text('See all'),
            ),
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
                color: Colors.black.withValues(alpha: 0.1),
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
                  color: color.withValues(alpha: 0.1),
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
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

class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});

  @override
  State<ArtistDashboardScreen> createState() => _ArtistDashboardScreenState();
}

class _ArtistDashboardScreenState extends State<ArtistDashboardScreen> {
  Timer? _refreshTimer;
  StreamSubscription<Artwork>? _artworkSubscription;

  @override
  void initState() {
    super.initState();
    MockSeeder.startGlobalAuctionSimulation();
    
    // Listen for artwork updates (like new bids)
    _artworkSubscription = MockSeeder.artworkUpdates.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });

    // Refresh dashboard data every 30 seconds for other stats
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _artworkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final commissions = MockSeeder.commissions;
    final openCommissions = commissions.where((c) {
      final s = c.status.toLowerCase();
      return s == 'pending' || s == 'accepted' || s == 'active' || s == 'in review';
    }).toList();
    final completedCommissions = commissions.where((c) => c.status.toLowerCase() == 'completed').length;
    final myArtworks = MockSeeder.artworks
        .where((item) => item.artistName == auth.displayName)
        .toList();
    
    // Calculate top performing artworks
    final topArtworks = List<Artwork>.from(myArtworks);
    topArtworks.sort((a, b) => (MockSeeder.analyticsViews[b.id] ?? 0).compareTo(MockSeeder.analyticsViews[a.id] ?? 0));
    
    final avgRating = MockSeeder.averageRating(auth.displayName);
    final myArtworkIds = myArtworks.map((a) => a.id).toSet();
    final revenue = MockSeeder.orders
        .where((o) => myArtworkIds.contains(o.artworkId))
        .fold<double>(
      0,
      (sum, item) => sum + item.total,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Artist Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Welcome back, ${auth.displayName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            IconButton(
              onPressed: () => context.push('/notifications'),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Performance Stats
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8F1414), Color(0xFFB71B1B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8F1414).withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Earnings (Net)',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'P${(revenue * 0.95).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '+P${(revenue * 0.1).toStringAsFixed(0)} this month',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DashboardStat(label: 'Views', value: '${myArtworks.fold<int>(0, (sum, a) => sum + (MockSeeder.analyticsViews[a.id] ?? 0))}'),
                  _DashboardStat(label: 'Likes', value: '${(myArtworks.length * 12)}'),
                  _DashboardStat(label: 'Commissions', value: '${openCommissions.length}'),
                  _DashboardStat(label: 'Rating', value: avgRating == 0 ? '-' : avgRating.toStringAsFixed(1)),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Quick Actions
        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.upload_outlined,
                label: 'Upload',
                onTap: () => context.push('/create'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.grid_view_outlined,
                label: 'Portfolio',
                onTap: () => context.push('/portfolio-management'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Wallet',
                onTap: () => context.push('/wallet'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                onTap: () => context.push('/artist-orders'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.calculate_outlined,
                label: 'Pricing',
                onTap: () => context.push('/pricing-guidance'),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Recent Auction Bids Section
        if (myArtworks.any((a) => a.isAuction && a.bidHistory.isNotEmpty)) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Auction Bids', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Icon(Icons.gavel_outlined, color: Colors.orange, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          ...(() {
            final bidEntries = myArtworks
              .where((a) => a.isAuction && a.bidHistory.isNotEmpty)
              .expand((a) => a.bidHistory.map((b) => MapEntry(a, b)))
              .toList();
            bidEntries.sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));
            
            return bidEntries.take(3).map((entry) {
              final artwork = entry.key;
              final bid = entry.value;
              final formatter = NumberFormat.currency(symbol: 'P', decimalDigits: 0);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        artwork.imageUrl ?? MockSeeder.placeholder,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${bid.bidderName} bid ${formatter.format(bid.amount)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'on "${artwork.title}"',
                            style: const TextStyle(color: Colors.black54, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(bid.timestamp),
                      style: const TextStyle(color: Colors.black38, fontSize: 10),
                    ),
                  ],
                ),
              );
            });
          })(),
          const SizedBox(height: 16),
        ],

        // Active Commissions Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Active Commissions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.push('/commissions'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (commissions.isEmpty)
          const Center(child: Text('No active commissions', style: TextStyle(color: Colors.black54)))
        else
          ...commissions.where((c) => c.status != 'Completed').take(2).map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.white,
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Budget P${item.budget.toStringAsFixed(0)}'),
                trailing: _statusChip(item.status),
                onTap: () => context.push('/commissions'),
              ),
            );
          }),

        const SizedBox(height: 16),
        
        // Performance Analytics Mini Chart Placeholder
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Visibility Trends', style: TextStyle(fontWeight: FontWeight.bold)),
                  Icon(Icons.trending_up, color: Colors.green, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final height = 20.0 + (index * 5) % 40;
                    return Container(
                      width: 30,
                      height: height,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8F1414).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Profile visibility increased by 12% this week', style: TextStyle(fontSize: 11, color: Colors.black54)),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Top Performing Artworks
        if (topArtworks.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Top Performing Artworks', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Icon(Icons.star_outline, color: Colors.amber, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          ...topArtworks.take(3).map((artwork) {
            final views = MockSeeder.analyticsViews[artwork.id] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      artwork.imageUrl ?? MockSeeder.placeholder,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artwork.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          artwork.category,
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.visibility_outlined, size: 14, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text('$views', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const Text('views', style: TextStyle(color: Colors.black38, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
}


class _DashboardStat extends StatelessWidget {
  final String label;
  final String value;

  const _DashboardStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF8F1414)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
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

class ArtworkDetailScreen extends StatefulWidget {
  const ArtworkDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  StreamSubscription<Artwork>? _artworkSubscription;
  late Artwork _artwork;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
    _setupAuctionListener();
  }

  void _loadArtwork() {
    _artwork = MockSeeder.artworks.firstWhere(
      (art) => art.id == widget.id,
      orElse: () => MockSeeder.artworks.first,
    );
    MockSeeder.trackView(_artwork.id);
  }

  void _setupAuctionListener() {
    if (_artwork.isAuction) {
      MockSeeder.startGlobalAuctionSimulation();
      
      _artworkSubscription = MockSeeder.artworkUpdates.listen((updatedArtwork) {
        if (updatedArtwork.id == widget.id && mounted) {
          final oldBid = _artwork.highestBid;
          setState(() {
            _artwork = updatedArtwork;
          });

          // If a new bid was placed on this artwork, show a notification
          if (oldBid != updatedArtwork.highestBid && updatedArtwork.highestBid != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('New bid on "${updatedArtwork.title}": PHP ${updatedArtwork.highestBid!.toStringAsFixed(0)}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.orange[800],
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _artworkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final artwork = _artwork;
    final formatter = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 0);
    final gateway = MockPaymentGateway();
    final img =
        artwork.imageUrl ??
        (artwork.images.isNotEmpty
            ? artwork.images.first
            : MockSeeder.placeholder);
    final conversationId = MockSeeder.getOrCreateConversation(artwork.artistName).id;

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
            if (artwork.isAuction)
              Chip(
                label: const Text('Auction'),
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        Text(artwork.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('by ${artwork.artistName}'),
        const SizedBox(height: 12),
        if (artwork.isAuction) ...[
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.highestBid != null ? 'Highest Bid' : 'Starting Price',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    formatter.format(artwork.highestBid ?? artwork.startingPrice ?? artwork.price),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  if (artwork.bidCount > 0)
                    Text(
                      '${artwork.bidCount} ${artwork.bidCount == 1 ? 'bid' : 'bids'}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                ],
              ),
              const Spacer(),
              if (artwork.auctionEndTime != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Bidding Ends In',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    TweenAnimationBuilder<Duration>(
                      duration: artwork.auctionEndTime!.difference(DateTime.now()),
                      tween: Tween(
                        begin: artwork.auctionEndTime!.difference(DateTime.now()),
                        end: Duration.zero,
                      ),
                      builder: (context, duration, child) {
                        final days = duration.inDays;
                        final hours = duration.inHours % 24;
                        final minutes = duration.inMinutes % 60;
                        final seconds = duration.inSeconds % 60;
                        return Text(
                          '${days}d ${hours}h ${minutes}m ${seconds}s',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB71B1B),
                          ),
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Recent Bids',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (artwork.bidHistory.isEmpty)
            const Text(
              'No bids yet. Be the first to bid!',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            )
          else
            ...artwork.bidHistory.reversed.take(5).map((bid) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      bid.bidderName,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      formatter.format(bid.amount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm').format(bid.timestamp),
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              );
            }),
          const Divider(height: 24),
        ] else
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
                setState(() {});
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
                  if (artwork.isAuction) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        final bidController = TextEditingController();
                        return AlertDialog(
                          title: const Text('Place a Bid'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Current Highest: ${formatter.format(artwork.highestBid ?? artwork.startingPrice ?? artwork.price)}'),
                              const SizedBox(height: 16),
                              TextField(
                                controller: bidController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Your Bid (P)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () {
                                final bid = double.tryParse(bidController.text) ?? 0;
                                final minBid = artwork.highestBid ?? artwork.startingPrice ?? artwork.price;
                                if (bid <= minBid) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Bid must be higher than ${formatter.format(minBid)}.')),
                                  );
                                  return;
                                }
                                MockSeeder.placeBid(artwork.id, bid, auth.displayName);
                                Navigator.pop(context);
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Bid of ${formatter.format(bid)} placed!')),
                                );
                              },
                              child: const Text('Confirm Bid'),
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }
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
                icon: Icon(artwork.isAuction ? Icons.gavel_outlined : Icons.shopping_bag_outlined),
                label: Text(artwork.isAuction ? 'Place Bid' : 'Buy Now'),
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
  bool _isAuction = false;
  int _auctionDurationDays = 7;
  int _currentStep = 0;
  File? _imageFile;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

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
      _priceController.text = (editing.isAuction ? editing.startingPrice : editing.price)?.toStringAsFixed(0) ?? '';
      _descriptionController.text = editing.description ?? '';
      _mediumController.text = editing.medium ?? '';
      _sizeController.text = editing.size ?? '';
      _selectedCategory = editing.category;
      _featureThisArtwork = editing.isFeatured;
      _isAuction = editing.isAuction;
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close),
        ),
        title: Text(editing == null ? 'Upload Artwork' : 'Edit Artwork'),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: const Color(0xFF8F1414),
          ),
        ),
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              _nextStep();
            } else {
              _handlePublish(auth, editing);
            }
          },
          onStepCancel: _previousStep,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == 2 ? (editing == null ? 'Publish' : 'Save Changes') : 'Next'),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              title: const Text('Basics'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Artwork Image', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: const Color(0xFFDED8CE)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : (editing?.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(editing!.imageUrl!, fit: BoxFit.cover),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.black26),
                                      SizedBox(height: 8),
                                      Text('Tap to upload artwork photo', style: TextStyle(color: Colors.black45)),
                                    ],
                                  )),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'Name your artwork',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select Category'),
                      items: const [
                        DropdownMenuItem(value: 'painting', child: Text('Painting')),
                        DropdownMenuItem(value: 'digital', child: Text('Digital Art')),
                        DropdownMenuItem(value: 'illustration', child: Text('Illustration')),
                        DropdownMenuItem(value: 'photography', child: Text('Photography')),
                      ],
                      onChanged: (value) => setState(() => _selectedCategory = value),
                    ),
                  ],
                ),
              ),
            ),
            Step(
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              title: const Text('Details'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Tell the story behind your art...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _mediumController,
                      decoration: const InputDecoration(
                        labelText: 'Medium/Style',
                        hintText: 'e.g. Oil on canvas, Digital Painting',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _sizeController,
                      decoration: const InputDecoration(
                        labelText: 'Size',
                        hintText: 'e.g. 24x36 inches, 4000x5000 px',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Step(
              isActive: _currentStep >= 2,
              title: const Text('Pricing'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sell or Auction Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAuction = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isAuction ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: !_isAuction ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Direct Sale',
                                    style: TextStyle(
                                      fontWeight: !_isAuction ? FontWeight.bold : FontWeight.normal,
                                      color: !_isAuction ? Colors.black : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAuction = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isAuction ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _isAuction ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'Auction',
                                    style: TextStyle(
                                      fontWeight: _isAuction ? FontWeight.bold : FontWeight.normal,
                                      color: _isAuction ? Colors.black : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: _isAuction ? 'Starting Price (P) *' : 'Price (P) *',
                              border: const OutlineInputBorder(),
                              prefixText: 'P ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          onPressed: () async {
                            final suggestedPrice = await Navigator.push<double>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PricingGuidanceScreen(isPicker: true),
                              ),
                            );
                            if (suggestedPrice != null) {
                              setState(() {
                                _priceController.text = suggestedPrice.toStringAsFixed(0);
                              });
                            }
                          },
                          icon: const Icon(Icons.auto_awesome),
                          tooltip: 'Pricing Guidance',
                        ),
                      ],
                    ),
                    if (_isAuction) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _auctionDurationDays,
                        decoration: const InputDecoration(
                          labelText: 'Auction Duration',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                        items: [3, 5, 7, 10, 14].map((days) {
                          return DropdownMenuItem(
                            value: days,
                            child: Text('$days Days'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _auctionDurationDays = value ?? 7),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags',
                        hintText: 'e.g. abstract, landscape, oil',
                        border: OutlineInputBorder(),
                        helperText: 'Separate with commas',
                      ),
                    ),
                    if (auth.hasFeaturedBoost) ...[
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _featureThisArtwork,
                        title: const Text('Feature this artwork'),
                        subtitle: const Text('Uses 1 featured boost slot'),
                        onChanged: (value) => setState(() => _featureThisArtwork = value),
                      ),
                    ],
                    if (editing != null) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),
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
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePublish(AuthState auth, Artwork? editing) {
    if (!auth.isVerified && !auth.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be a verified artist to publish artworks.')),
      );
      return;
    }

    final parsedPrice = double.tryParse(_priceController.text) ?? 0;
    if (_titleController.text.trim().isEmpty || _selectedCategory == null || parsedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete title, category and price.')),
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
      imageUrl: _imageFile?.path ?? editing?.imageUrl ?? MockSeeder.placeholder,
      images: [if (_imageFile != null) _imageFile!.path else if (editing != null) editing.imageUrl! else MockSeeder.placeholder],
      isFeatured: _featureThisArtwork,
      avgRating: editing?.avgRating ?? 0,
      isAuction: _isAuction,
      startingPrice: _isAuction ? parsedPrice : null,
      auctionEndTime: _isAuction ? DateTime.now().add(Duration(days: _auctionDurationDays)) : null,
      status: _isAuction ? 'For Bidding' : 'For Sale',
    );

    MockSeeder.upsertArtwork(record);
    MockSeeder.toggleFeaturedBoost(record.id, _featureThisArtwork);
    MockSeeder.addNotification(
      'Artwork updated',
      '${record.title} has been ${editing == null ? 'uploaded' : 'saved'}.',
    );
    context.go('/artist-dashboard');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(editing == null ? 'Artwork published!' : 'Artwork updated!')),
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
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.black87,
                                  ),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (auth.isScholarVerified) ...[
                                  const SizedBox(width: 10),
                                  Chip(
                                    label: const Text('Scholar'),
                                    avatar: const Icon(Icons.school, size: 16),
                                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                    labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                                const SizedBox(width: 10),
                                Chip(
                                  label: Text(auth.isArtist ? 'Creator' : 'Collector'),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                  color: Colors.black.withValues(alpha: 0.1),
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
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (auth.isArtist && (auth.style.isNotEmpty || auth.medium.isNotEmpty)) ...[
                      Row(
                        children: [
                          if (auth.style.isNotEmpty)
                            _buildInfoChip(Icons.brush_outlined, auth.style),
                          if (auth.style.isNotEmpty && auth.medium.isNotEmpty)
                            const SizedBox(width: 8),
                          if (auth.medium.isNotEmpty)
                            _buildInfoChip(Icons.palette_outlined, auth.medium),
                        ],
                      ),
                      const Divider(height: 24),
                    ],
                    Text(
                      aboutText,
                      style: const TextStyle(color: Colors.black87, height: 1.5),
                    ),
                  ],
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
              // Scholar Application Logic
              if (!auth.isScholarVerified && !auth.scholarVerificationSubmitted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/scholar-verification'),
                    icon: const Icon(Icons.school_outlined),
                    label: const Text('Apply for Scholar Tier'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                )
              else if (auth.scholarVerificationSubmitted && !auth.isScholarVerified)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.hourglass_empty),
                    label: const Text('Scholar Application Pending'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),

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
              else if (auth.isVerifiedArtist)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton.icon(
                    onPressed: () => context.push('/artist-dashboard'),
                    icon: const Icon(Icons.dashboard_customize_outlined),
                    label: const Text('Artist Dashboard'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: const Color(0xFFB71B1B),
                    ),
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
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _styleController = TextEditingController();
  final _mediumController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _profilePhotoBytes;
  bool _verifiedBadge = false;
  bool _portfolioPack = false;
  bool _featuredBoost = false;
  bool _profileLoaded = false;
  bool _isSaving = false;

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
    _styleController.dispose();
    _mediumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!_profileLoaded) {
      _nameController.text = auth.displayName;
      _usernameController.text = auth.username;
      _bioController.text = auth.bio;
      _styleController.text = auth.style;
      _mediumController.text = auth.medium;
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
        if (auth.isArtist) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _styleController,
            decoration: const InputDecoration(
              labelText: 'Art Style',
              hintText: 'e.g. Digital, Impressionism, Surrealism',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mediumController,
            decoration: const InputDecoration(
              labelText: 'Medium',
              hintText: 'e.g. Oil, Procreate, Watercolor',
              border: OutlineInputBorder(),
            ),
          ),
        ],
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
          onPressed: _isSaving
              ? null
              : () async {
                  setState(() => _isSaving = true);
                  try {
                    await auth.updateProfile(
                      name: _nameController.text,
                      username: _usernameController.text,
                      bio: _bioController.text,
                      artStyle: auth.isArtist ? _styleController.text : null,
                      medium: auth.isArtist ? _mediumController.text : null,
                    );
                    auth.setVerifiedArtist(_verifiedBadge);
                    if (_portfolioPack) {
                      auth.enablePortfolioPack();
                    }
                    if (_featuredBoost) {
                      auth.enableFeaturedBoost();
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated.')),
                    );
                    context.go('/profile');
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save changes'),
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
  void _updateProgress(String id, String progress) {
    setState(() {
      final idx = MockSeeder.commissions.indexWhere((c) => c.id == id);
      if (idx != -1) {
        MockSeeder.commissions[idx] =
            MockSeeder.commissions[idx].copyWith(progress: progress);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Progress updated to $progress')),
    );
  }

  void _addNote(String id) {
    final commission = MockSeeder.commissions.firstWhere((c) => c.id == id);
    final controller = TextEditingController(text: commission.notes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Progress Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Describe progress or requirements...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                final idx = MockSeeder.commissions.indexWhere((c) => c.id == id);
                if (idx != -1) {
                  MockSeeder.commissions[idx] = MockSeeder.commissions[idx]
                      .copyWith(notes: controller.text);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commissions = MockSeeder.commissions;
    final pending = commissions
        .where((c) => c.status.toLowerCase() == 'pending')
        .toList();
    final active = commissions
        .where((c) => c.status.toLowerCase() == 'accepted')
        .toList();
    final completed = commissions
        .where((c) => c.status.toLowerCase() == 'completed')
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Commission Manager'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCommissionList(pending, 'No pending requests.'),
            _buildCommissionList(active, 'No active commissions.'),
            _buildCommissionList(completed, 'No completed commissions.'),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionList(List<Commission> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
          child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildCommissionCard(item);
      },
    );
  }

  Widget _buildCommissionCard(Commission item) {
    final normalizedStatus = item.status.toLowerCase();
    final progressSteps = ['Sketch', 'In Progress', 'Completed'];
    final progressIdx = progressSteps.indexOf(item.progress);
    final progressPercent = (progressIdx + 1) / progressSteps.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text('Buyer: ${item.buyerName}',
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                _statusChip(item.status),
              ],
            ),
            const Divider(height: 24),
            Text(item.description),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.payments_outlined,
                    size: 16, color: Color(0xFF8F1414)),
                const SizedBox(width: 4),
                Text(
                  'Budget: P${item.budget.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF8F1414)),
                ),
                const Spacer(),
                if (item.deadline != null) ...[
                  const Icon(Icons.event_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${DateFormat('MMM d, y').format(item.deadline!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            if (normalizedStatus == 'accepted') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress: ${item.progress}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${(progressPercent * 100).toInt()}%',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: progressSteps.map((p) {
                    final isSelected = item.progress == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            if (p == 'Completed') {
                              _confirmCompletion(item.id);
                            } else {
                              _updateProgress(item.id, p);
                            }
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (item.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.notes,
                          style: TextStyle(
                              fontSize: 13, color: Colors.amber[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            if (normalizedStatus == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          MockSeeder.updateCommissionStatus(item.id, 'Rejected');
                        });
                      },
                      style:
                          OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          MockSeeder.updateCommissionStatus(item.id, 'Accepted');
                        });
                      },
                      child: const Text('Accept Request'),
                    ),
                  ),
                ],
              )
            else if (normalizedStatus == 'accepted')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addNote(item.id),
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text('Update Note'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final conversationId =
                            MockSeeder.getOrCreateConversation(item.buyerName)
                                .id;
                        context.push(
                            '/chat/${Uri.encodeComponent(conversationId)}');
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: const Text('Message Buyer'),
                    ),
                  ),
                ],
              )
            else if (normalizedStatus == 'completed')
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    final conversationId =
                        MockSeeder.getOrCreateConversation(item.buyerName).id;
                    context
                        .push('/chat/${Uri.encodeComponent(conversationId)}');
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat with Buyer'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmCompletion(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Commission?'),
        content: const Text(
            'This will mark the commission as finished. Have you delivered the final artwork to the buyer?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No')),
          FilledButton(
            onPressed: () {
              setState(() {
                MockSeeder.updateCommissionStatus(id, 'Completed');
                final idx = MockSeeder.commissions.indexWhere((c) => c.id == id);
                if (idx != -1) {
                  MockSeeder.commissions[idx] = MockSeeder.commissions[idx]
                      .copyWith(progress: 'Completed');
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Commission marked as completed!')),
              );
            },
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
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

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.isEmpty
          ? const Center(child: Text('No orders yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final item = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Order #${item.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Artwork ${item.artworkId}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('P${item.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              _statusChip(item.status),
                            ],
                          ),
                        ),
                        const Divider(),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Payment handled externally.')),
                                  );
                                },
                                icon: const Icon(Icons.payment, size: 16),
                                label: const Text('Payment Info', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () async {
                                  MockSeeder.markArtworkSold(item.artworkId);
                                  final artwork = MockSeeder.artworks
                                      .where((art) => art.id == item.artworkId)
                                      .firstOrNull;
                                  if (artwork != null) {
                                    await _rateArtist(context, artwork.artistName);
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: const Text('Deal Completed', style: TextStyle(fontSize: 12)),
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
    );
  }
}

class PricingGuidanceScreen extends StatefulWidget {
  const PricingGuidanceScreen({super.key, this.isPicker = false});

  final bool isPicker;

  @override
  State<PricingGuidanceScreen> createState() => _PricingGuidanceScreenState();
}

class _PricingGuidanceScreenState extends State<PricingGuidanceScreen> {
  final _hoursController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _materialsController = TextEditingController();
  String _selectedCategory = 'painting';
  
  double _suggestedMin = 0;
  double _suggestedMax = 0;
  double _profit = 0;
  double _marketAvg = 0;
  bool _calculated = false;

  final List<String> _categories = ['painting', 'digital', 'mixed_media', 'sculpture', 'other'];

  void _calculate() {
    final hours = double.tryParse(_hoursController.text) ?? 0;
    final hourlyRate = double.tryParse(_hourlyRateController.text) ?? 0;
    final materials = double.tryParse(_materialsController.text) ?? 0;

    // Calculate market average from MockSeeder
    final categoryArtworks = MockSeeder.artworks.where((a) => a.category == _selectedCategory).toList();
    if (categoryArtworks.isNotEmpty) {
      _marketAvg = categoryArtworks.map((a) => a.price).reduce((a, b) => a + b) / categoryArtworks.length;
    } else {
      _marketAvg = 0;
    }

    if (hours > 0 && hourlyRate > 0) {
      final baseCost = (hours * hourlyRate) + materials;
      setState(() {
        _suggestedMin = baseCost * 1.2; // 20% margin
        _suggestedMax = baseCost * 2.0; // 100% margin
        _profit = _suggestedMin - materials - (baseCost * 0.05); // Less materials and 5% fee
        _calculated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing Guidance')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Smart Pricing Helper',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Calculate a fair price based on your effort and materials.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 32),
          
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Art Category',
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
            ),
            items: _categories.map((cat) => DropdownMenuItem(
              value: cat,
              child: Text(cat[0].toUpperCase() + cat.substring(1).replaceAll('_', ' ')),
            )).toList(),
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hoursController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Hours spent',
              prefixIcon: Icon(Icons.timer_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hourlyRateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Your hourly rate (PHP)',
              prefixIcon: Icon(Icons.payments_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _materialsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Material costs (PHP)',
              prefixIcon: Icon(Icons.brush_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _calculate,
              child: const Text('Calculate Suggested Price'),
            ),
          ),
          
          if (_calculated) ...[
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8F1414).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8F1414).withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  const Text('Suggested Price Range', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    'P${_suggestedMin.toStringAsFixed(0)} - P${_suggestedMax.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF8F1414)),
                  ),
                  const Divider(height: 32),
                  _PriceRow(label: 'Platform Fee (5%)', value: '-P${(_suggestedMin * 0.05).toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _PriceRow(label: 'Estimated Net Profit', value: 'P${_profit.toStringAsFixed(2)}', isBold: true),
                  if (widget.isPicker) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.pop(_suggestedMin),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8F1414),
                        ),
                        child: const Text('Use Suggested Minimum'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_marketAvg > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Market Comparison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            'Average price for ${_selectedCategory.replaceAll('_', ' ')}: P${_marketAvg.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is a guide based on your inputs. Consider market demand and your experience level when setting the final price.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.isBold = false});
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
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

class ArtistProfileScreen extends StatefulWidget {
  const ArtistProfileScreen({super.key, required this.artistId});

  final String artistId;

  @override
  State<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}

class _ArtistProfileScreenState extends State<ArtistProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final works = MockSeeder.artworks
        .where((item) =>
            item.artistName == widget.artistId ||
            widget.artistId == '1' ||
            item.id == widget.artistId)
        .toList();

    // Find artist details from the first artwork or use defaults
    final artistName =
        works.isNotEmpty ? works.first.artistName : 'Artist #${widget.artistId}';
    final avgRating = MockSeeder.averageRating(artistName);
    final totalSales = MockSeeder.orders.where((o) {
      final art = MockSeeder.artworks.firstWhere((a) => a.id == o.artworkId,
          orElse: () => MockSeeder.artworks.first);
      return art.artistName == artistName;
    }).length;

    // Mock stats for followers/following
    final followers = 1240 + (works.length * 45);
    final following = 150 + works.length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1541963463532-d68292c34b19?w=800&q=80',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.share, color: Colors.white, size: 20),
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: const NetworkImage(
                            'https://i.pravatar.cc/150?u=artist'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          artistName,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        if (MockSeeder.verifiedArtist) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              color: Colors.blue, size: 22),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${artistName.toLowerCase().replaceAll(' ', '_')}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Vivid portraiture and digital mixed media compositions. Inspired by Philippine culture and modern urban life.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black87, fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ProfileStat(
                              label: 'Works', value: '${works.length}'),
                          _ProfileStat(label: 'Sales', value: '$totalSales'),
                          _ProfileStat(
                              label: 'Followers', value: '$followers'),
                          _ProfileStat(
                              label: 'Following', value: '$following'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => context.push('/commission'),
                            icon: const Icon(Icons.palette_outlined, size: 18),
                            label: const Text('Request Commission'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {
                            final conversationId =
                                MockSeeder.getOrCreateConversation(artistName)
                                    .id;
                            context.push(
                                '/chat/${Uri.encodeComponent(conversationId)}');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Icon(Icons.chat_bubble_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Follow'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: 'Works'),
                  Tab(text: 'About'),
                  Tab(text: 'Reviews'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Works Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: works.length,
                    itemBuilder: (context, index) {
                      final item = works[index];
                      return ArtworkCard(
                        artwork: item,
                        onTap: () => context.push('/artwork/${item.id}'),
                      );
                    },
                  ),
                ),
                // About Tab
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Biography',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Text(
                        'A contemporary Filipino artist based in Manila. My work explores the intersection of traditional Filipino motifs and modern digital aesthetics. I have been active in the local art scene for over 5 years and have participated in several group exhibitions.',
                        style: TextStyle(fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      const Text('Details',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.location_on_outlined, 'Manila, Philippines'),
                      _buildDetailRow(Icons.calendar_today_outlined, 'Joined April 2021'),
                      _buildDetailRow(Icons.brush_outlined, 'Digital, Oil, Mixed Media'),
                      const SizedBox(height: 24),
                      const Text('Socials',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _socialIcon(Icons.language),
                          _socialIcon(Icons.camera_alt_outlined),
                          _socialIcon(Icons.facebook),
                        ],
                      ),
                    ],
                  ),
                ),
                // Reviews Tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                Text(
                                  avgRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: List.generate(
                                      5,
                                      (i) => Icon(
                                            Icons.star,
                                            size: 16,
                                            color: i < avgRating.floor()
                                                ? Colors.amber
                                                : Colors.grey[300],
                                          )),
                                ),
                                const SizedBox(height: 4),
                                Text('Based on 24 reviews',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                            const Spacer(),
                            // Simple rating bars mock
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [5, 4, 3, 2, 1].map((star) {
                                return Row(
                                  children: [
                                    Text('$star',
                                        style: const TextStyle(fontSize: 10)),
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 100,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: star == 5 ? 0.8 : (star == 4 ? 0.15 : 0.05),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.amber,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Expanded(
                        child: Center(
                          child: Text('No reviews yet in this version.',
                              style: TextStyle(color: Colors.grey)),
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
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[200],
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}


class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
    final auth = context.watch<AuthState>();
    if (!auth.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Admin access only.'),
        ),
      );
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

class PortfolioManagementScreen extends StatefulWidget {
  const PortfolioManagementScreen({super.key});

  @override
  State<PortfolioManagementScreen> createState() => _PortfolioManagementScreenState();
}

class _PortfolioManagementScreenState extends State<PortfolioManagementScreen> {
  String _selectedStatus = 'All';
  String _sortBy = 'Newest';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final myArtworks = MockSeeder.artworks
        .where((item) => item.artistName == auth.displayName)
        .where((item) => _selectedStatus == 'All' || item.status == _selectedStatus)
        .toList();

    // Sorting logic
    if (_sortBy == 'Price High-Low') {
      myArtworks.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Price Low-High') {
      myArtworks.sort((a, b) => a.price.compareTo(b.price));
    }

    // Stats
    final totalSold = MockSeeder.artworks
        .where((a) => a.artistName == auth.displayName && a.status == 'Sold')
        .length;
    final forBidding = MockSeeder.artworks
        .where((a) => a.artistName == auth.displayName && a.status == 'For Bidding')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Portfolio'),
        actions: [
          IconButton(
            onPressed: () => context.push('/create'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          // Artist Profile Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFB71B1B),
                  child: Text(
                    auth.displayName.isNotEmpty ? auth.displayName[0] : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            auth.displayName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          if (auth.isVerifiedArtist) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Colors.blue, size: 16),
                          ],
                        ],
                      ),
                      if (auth.style.isNotEmpty || auth.medium.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              if (auth.style.isNotEmpty)
                                _buildInfoChip(Icons.brush_outlined, auth.style),
                              if (auth.medium.isNotEmpty)
                                _buildInfoChip(Icons.palette_outlined, auth.medium),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Works', MockSeeder.artworks.where((a) => a.artistName == auth.displayName).length.toString()),
                _buildStat('Sold', totalSold.toString()),
                _buildStat('Bidding', forBidding.toString()),
              ],
            ),
          ),

          // Filters and Sorting
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('For Sale'),
                _buildFilterChip('For Bidding'),
                _buildFilterChip('Reserved'),
                _buildFilterChip('Sold'),
                const SizedBox(width: 8),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: const Icon(Icons.sort, size: 16),
                      style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                      onChanged: (String? newValue) {
                        if (newValue != null) setState(() => _sortBy = newValue);
                      },
                      items: <String>['Newest', 'Price High-Low', 'Price Low-High']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          Expanded(
            child: myArtworks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.collections_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _selectedStatus == 'All' 
                            ? 'No artworks in your portfolio yet.' 
                            : 'No artworks with status "$_selectedStatus"',
                          style: const TextStyle(color: Colors.black54)
                        ),
                        if (_selectedStatus == 'All') ...[
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => context.push('/create'),
                            child: const Text('Upload Your First Work'),
                          ),
                        ],
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: myArtworks.length,
                    itemBuilder: (context, index) {
                      final artwork = myArtworks[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Image.network(
                                    artwork.imageUrl ?? MockSeeder.placeholder,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        artwork.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'P${artwork.price.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          _miniStatusChip(artwork.status),
                                        ],
                                      ),
                                      if (artwork.status == 'For Bidding') ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.gavel, size: 12, color: Colors.black45),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${artwork.bidCount} bids',
                                              style: const TextStyle(fontSize: 11, color: Colors.black45),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    context.push('/create/${artwork.id}');
                                  } else if (value == 'delete') {
                                    _confirmDelete(context, artwork);
                                  } else {
                                    _updateStatus(context, artwork, value);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 20),
                                        SizedBox(width: 12),
                                        Text('Edit Details'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  _buildPopupStatusItem('For Sale', Icons.sell_outlined),
                                  _buildPopupStatusItem('For Bidding', Icons.gavel_outlined),
                                  _buildPopupStatusItem('Reserved', Icons.lock_clock_outlined),
                                  _buildPopupStatusItem('Sold', Icons.check_circle_outline),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                        SizedBox(width: 12),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                child: const CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 14,
                                  child: Icon(Icons.more_vert, size: 16, color: Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  Widget _buildFilterChip(String status) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(status),
        selected: isSelected,
        onSelected: (bool selected) {
          setState(() => _selectedStatus = status);
        },
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        selectedColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.grey[100],
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupStatusItem(String status, IconData icon) {
    return PopupMenuItem(
      value: status,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text('Set as $status'),
        ],
      ),
    );
  }


  void _confirmDelete(BuildContext context, Artwork artwork) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Artwork?'),
        content: Text('Are you sure you want to remove "${artwork.title}" from your portfolio?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              MockSeeder.artworks.removeWhere((a) => a.id == artwork.id);
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Artwork deleted.')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, Artwork artwork, String status) {
    final index = MockSeeder.artworks.indexWhere((a) => a.id == artwork.id);
    if (index != -1) {
      final updated = Artwork(
        id: artwork.id,
        title: artwork.title,
        artistName: artwork.artistName,
        price: artwork.price,
        description: artwork.description,
        category: artwork.category,
        medium: artwork.medium,
        size: artwork.size,
        imageUrl: artwork.imageUrl,
        images: artwork.images,
        isFeatured: artwork.isFeatured,
        avgRating: artwork.avgRating,
        status: status,
      );
      MockSeeder.artworks[index] = updated;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status.')));
    }
  }

  Widget _miniStatusChip(String status) {
    final normalized = status.toLowerCase();
    Color color = Colors.grey;
    if (normalized == 'for sale') color = Colors.green;
    if (normalized == 'for bidding') color = Colors.blue;
    if (normalized == 'reserved') color = Colors.orange;
    if (normalized == 'sold') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // Mock withdrawal history
  final List<Map<String, dynamic>> _withdrawals = [
    {
      'id': 'W001',
      'amount': 5000.0,
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'method': 'GCash',
      'status': 'Completed'
    },
    {
      'id': 'W002',
      'amount': 2500.0,
      'date': DateTime.now().subtract(const Duration(days: 25)),
      'method': 'Bank Transfer',
      'status': 'Completed'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final myArtworks = MockSeeder.artworks
        .where((item) => item.artistName == auth.displayName)
        .toList();
    final myArtworkIds = myArtworks.map((a) => a.id).toSet();
    
    // Calculate sales earnings
    final sales = MockSeeder.orders.where((o) => myArtworkIds.contains(o.artworkId)).toList();
    final salesGross = sales.fold<double>(0, (sum, item) => sum + item.total);
    
    // Calculate commission earnings
    final commissions = MockSeeder.commissions.where((c) => c.artistName == auth.displayName && c.status == 'Completed').toList();
    final commissionsGross = commissions.fold<double>(0, (sum, item) => sum + item.budget);
    
    final totalGross = salesGross + commissionsGross;
    final platformFees = totalGross * 0.05;
    
    // Calculate total withdrawals
    final totalWithdrawn = _withdrawals.fold<double>(0, (sum, item) => sum + item['amount']);
    
    final netBalance = totalGross - platformFees - totalWithdrawn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showFeesInfo(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Balance Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[800]!, Colors.green[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('Current Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    'P${netBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: netBalance > 100 
                              ? () => _showWithdrawDialog(context, netBalance)
                              : null,
                          icon: const Icon(Icons.account_balance_wallet_outlined),
                          label: const Text('Withdraw Funds'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green[800],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Stats Section
            Row(
              children: [
                _buildSmallStatCard('Total Earned', 'P${totalGross.toStringAsFixed(0)}', Icons.trending_up, Colors.blue),
                const SizedBox(width: 12),
                _buildSmallStatCard('Total Withdrawn', 'P${totalWithdrawn.toStringAsFixed(0)}', Icons.outbox, Colors.orange),
              ],
            ),
            const SizedBox(height: 32),

            // Breakdown
            Text('Earnings Breakdown',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _breakdownRow('Art Sales', 'P${salesGross.toStringAsFixed(2)}', icon: Icons.sell_outlined),
                    _breakdownRow('Commissions', 'P${commissionsGross.toStringAsFixed(2)}', icon: Icons.palette_outlined),
                    const Divider(height: 24),
                    _breakdownRow('Platform Fees (5%)', '-P${platformFees.toStringAsFixed(2)}', isNegative: true),
                    const Divider(height: 24),
                    _breakdownRow('Total Net', 'P${(totalGross - platformFees).toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 12),
            if (sales.isEmpty && commissions.isEmpty && _withdrawals.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No transactions yet.', style: TextStyle(color: Colors.black54)),
                ),
              )
            else
              ...[
                // Merge and sort transactions
                ..._withdrawals.map((w) => _buildTransactionItem(
                      'Withdrawal: ${w['method']}',
                      w['date'],
                      -w['amount'],
                      Icons.account_balance,
                      Colors.orange,
                    )),
                ...commissions.map((c) => _buildTransactionItem(
                      'Commission: ${c.title}',
                      DateTime.now().subtract(const Duration(days: 2)), // Mock date
                      c.budget * 0.95,
                      Icons.palette,
                      Colors.purple,
                    )),
                ...sales.map((s) => _buildTransactionItem(
                      'Sale: Order #${s.id}',
                      DateTime.now().subtract(const Duration(days: 5)), // Mock date
                      s.total * 0.95,
                      Icons.sell,
                      Colors.green,
                    )),
              ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {bool isNegative = false, bool isBold = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: isNegative ? Colors.red : (isBold ? Colors.black : Colors.black87),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, DateTime date, double amount, IconData icon, Color color) {
    final isNegative = amount < 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(DateFormat('MMM d, yyyy').format(date), style: const TextStyle(fontSize: 12)),
        trailing: Text(
          '${isNegative ? "-" : "+"}P${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: isNegative ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showFeesInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fee Structure'),
        content: const Text(
          'ArtFlow charges a flat 5% platform fee on all successful sales and commissions. This covers secure payment processing, platform maintenance, and artist support services.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, double balance) {
    final amountController = TextEditingController();
    String selectedMethod = 'GCash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Withdraw Funds', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Available: P${balance.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),
                
                const Text('Amount to Withdraw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'P ',
                    hintText: '0.00',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text('Withdrawal Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                _buildMethodOption(
                  'GCash',
                  '0917 **** 123',
                  Icons.account_balance_wallet,
                  Colors.blue,
                  selectedMethod == 'GCash',
                  () => setModalState(() => selectedMethod = 'GCash'),
                ),
                const SizedBox(height: 12),
                _buildMethodOption(
                  'Bank Transfer',
                  'BPI **** 4567',
                  Icons.account_balance,
                  Colors.indigo,
                  selectedMethod == 'Bank Transfer',
                  () => setModalState(() => selectedMethod = 'Bank Transfer'),
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final amount = double.tryParse(amountController.text) ?? 0;
                      if (amount <= 0 || amount > balance) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount.')));
                        return;
                      }
                      
                      Navigator.pop(context);
                      _confirmWithdrawal(amount, selectedMethod);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Review Withdrawal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodOption(String title, String subtitle, IconData icon, Color color, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey[200]!, width: isSelected ? 2 : 1),
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  void _confirmWithdrawal(double amount, String method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Withdrawal'),
        content: Text('Are you sure you want to withdraw P${amount.toStringAsFixed(2)} to your $method account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _withdrawals.insert(0, {
                  'id': 'W${math.Random().nextInt(1000).toString().padLeft(3, "0")}',
                  'amount': amount,
                  'date': DateTime.now(),
                  'method': method,
                  'status': 'Processing'
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Withdrawal of P${amount.toStringAsFixed(2)} to $method is being processed.')));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}


class ArtistOrdersScreen extends StatefulWidget {
  const ArtistOrdersScreen({super.key});

  @override
  State<ArtistOrdersScreen> createState() => _ArtistOrdersScreenState();
}

class _ArtistOrdersScreenState extends State<ArtistOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Mock local state for order status updates
  final Map<String, String> _orderStatuses = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final myArtworks = MockSeeder.artworks
        .where((item) => item.artistName == auth.displayName)
        .toList();
    final myArtworkIds = myArtworks.map((a) => a.id).toSet();
    final allOrders = MockSeeder.orders.where((o) => myArtworkIds.contains(o.artworkId)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(allOrders, ['Pending', 'Processing', 'Shipped', 'Delivered'], myArtworks),
          _buildOrderList(allOrders, ['Completed'], myArtworks),
          _buildOrderList(allOrders, ['Cancelled', 'Returned'], myArtworks),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Order> allOrders, List<String> statuses, List<Artwork> myArtworks) {
    final filteredOrders = allOrders.where((o) {
      final currentStatus = _orderStatuses[o.id] ?? o.status;
      return statuses.contains(currentStatus);
    }).toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No orders found here', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        final artwork = myArtworks.firstWhere((a) => a.id == order.artworkId);
        final currentStatus = _orderStatuses[order.id] ?? order.status;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                artwork.imageUrl ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image),
                ),
              ),
            ),
            title: Text('Order #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artwork.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                _statusChip(currentStatus),
              ],
            ),
            trailing: Text('P${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildDetailRow('Customer', 'Juan Dela Cruz'), // Mocked
                    _buildDetailRow('Date', 'Apr 28, 2026'), // Mocked
                    _buildDetailRow('Payment', 'GCash'), // Mocked
                    _buildDetailRow('Shipping', '123 Art St., Metro Manila'), // Mocked
                    const SizedBox(height: 16),
                    const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Processing', 'Shipped', 'Delivered', 'Completed'].map((s) {
                              final isCurrent = currentStatus == s;
                              return ChoiceChip(
                                label: Text(s, style: TextStyle(fontSize: 12, color: isCurrent ? Colors.white : Colors.black)),
                                selected: isCurrent,
                                selectedColor: Theme.of(context).colorScheme.primary,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _orderStatuses[order.id] = s;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order #${order.id} status updated to $s')));
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.chat_outlined, size: 18),
                            label: const Text('Contact Buyer'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.receipt_long_outlined, size: 18),
                            label: const Text('Print Label'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
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
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
  );
}

Widget _buildInfoChip(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.black54),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}
