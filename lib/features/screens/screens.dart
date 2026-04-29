import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth/domain/auth_status.dart';
import '../auth/presentation/auth_state.dart';
import '../chat/data/chat_service.dart';
import '../chat/domain/chat_models.dart';
import '../entities/models/artwork.dart';
import '../entities/models/commission.dart';
import '../shared/data/auction_service.dart';
import '../shared/data/app_data_state.dart';
import '../shared/data/supabase_image_service.dart';
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
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    // Check if mode is passed in query params
    final uri = Uri.base;
    if (uri.queryParameters['mode'] == 'register') {
      _isLogin = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final auth = context.read<AuthState>();
      final pendingError = auth.lastAuthError;
      if (pendingError != null && pendingError.isNotEmpty) {
        setState(() => _inlineError = pendingError);
        auth.clearLastAuthError();
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateEmailPasswordInputs() {
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email address.');
      return false;
    }
    if (!_isValidEmail(_emailController.text.trim())) {
      _showError('Please enter a valid email address.');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters.');
      return false;
    }

    if (!_isLogin) {
      if (_fullNameController.text.trim().isEmpty) {
        _showError('Please enter your full name.');
        return false;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError('Passwords do not match.');
        return false;
      }
      if (!_agreeToTerms) {
        _showError('Please agree to the Terms of Service.');
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

  void _clearError() {
    context.read<AuthState>().clearLastAuthError();
    if (_inlineError == null) {
      return;
    }
    setState(() => _inlineError = null);
  }

  void _showError(String message) {
    setState(() => _inlineError = message);
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong password.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'invalid-email':
        return 'That email address is invalid.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'popup-closed-by-user':
      case 'google-sign-in-cancelled':
        return 'Google sign in was cancelled.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<void> _handleGoogleAuth() async {
    final auth = context.read<AuthState>();
    _clearError();

    if (!_isLogin) {
      if (!_agreeToTerms) {
        _showError('Please agree to the Terms of Service.');
        return;
      }
    }

    try {
      if (_isLogin) {
        await auth.loginWithGoogle();
      } else {
        await auth.registerWithGoogle();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(_friendlyAuthError(e));
      return;
    } catch (_) {
      if (!mounted) return;
      _showError('Unable to continue with Google right now.');
      return;
    }

    if (mounted && auth.isAuthenticated) {
      _clearError();
      if (auth.isAdmin) {
        context.go('/admin');
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _handleEmailPasswordAuth() async {
    _clearError();
    if (!_validateEmailPasswordInputs()) {
      return;
    }

    final auth = context.read<AuthState>();
    if (!auth.firebaseAvailable) {
      _showError(
        'Firebase authentication is not available on this build yet. Add the Firebase config for this platform first.',
      );
      return;
    }

    try {
      if (_isLogin) {
        await auth.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await auth.register(
          name: _fullNameController.text.trim(),
          role: 'buyer',
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      _showError(_friendlyAuthError(e));
      return;
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError('Unable to continue with email and password right now.');
      return;
    }

    if (mounted && auth.isAuthenticated) {
      _clearError();
      if (auth.isAdmin) {
        context.go('/admin');
      } else {
        context.go('/');
      }
    } else if (mounted) {
      _showError(
        _isLogin
            ? 'Sign in failed. Check your email and password.'
            : 'Could not create your account.',
      );
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
                _FormField(
                  label: 'Full Name',
                  hint: 'Enter the name you want to show on ArtFlow',
                  controller: _fullNameController,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
              ],

              _FormField(
                label: 'Email Address',
                hint: 'Enter your email',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

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
                _FormField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onTogglePassword: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                const SizedBox(height: 20),

                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _agreeToTerms,
                  onChanged: (val) {
                    setState(() {
                      _agreeToTerms = val ?? false;
                      _inlineError = null;
                    });
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
              ],

              if (_inlineError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _inlineError!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: auth.status == AuthStatus.checking
                      ? null
                      : _handleEmailPasswordAuth,
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
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: Divider(color: Colors.black.withValues(alpha: 0.15)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Colors.black.withValues(alpha: 0.15)),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE4D8CB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F1E7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'G',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isLogin
                            ? 'Sign in using your Google account. We will use your Google email to continue.'
                            : 'Create your ArtFlow account using Google. Your Google email will become your sign-in email.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ============ CTA BUTTONS ============
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: auth.status == AuthStatus.checking
                      ? null
                      : _handleGoogleAuth,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFE4D8CB)),
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
                            color: Color(0xFFB71B1B),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isLogin
                                  ? 'Continue with Google'
                                  : 'Create with Google',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
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
                        setState(() {
                          _isLogin = !_isLogin;
                          _fullNameController.clear();
                          _emailController.clear();
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                          _agreeToTerms = false;
                          _inlineError = null;
                        });
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
    final application = auth.currentArtistApplication;
    final rejectionReason = auth.artistApplicationRejectionReason.trim();
    final submittedAt = application?.submittedAt;
    final reviewedAt = application?.reviewedAt;

    IconData icon;
    Color iconColor;
    String title;
    String description;
    String primaryActionLabel;
    VoidCallback primaryAction;

    if (auth.isVerifiedArtist || auth.artistApplicationApproved) {
      icon = Icons.verified_user_outlined;
      iconColor = Colors.green;
      title = 'Artist Access Approved';
      description =
          'Your application has been approved. Creator tools are now enabled on your account.';
      primaryActionLabel = 'Go to Profile';
      primaryAction = () => context.go('/profile');
    } else if (auth.artistApplicationRejected) {
      icon = Icons.rule_folder_outlined;
      iconColor = const Color(0xFFB76A00);
      title = 'Application Needs Updates';
      description = rejectionReason.isEmpty
          ? 'Your application was reviewed, but the team needs more information before approving artist access.'
          : rejectionReason;
      primaryActionLabel = 'Update Application';
      primaryAction = () => context.go('/become-artist');
    } else {
      icon = Icons.pending_actions_rounded;
      iconColor = const Color(0xFFB71B1B);
      title = 'Application Under Review';
      description =
          'Your artist application has been submitted. Our team is reviewing your portfolio and verification details now.';
      primaryActionLabel = 'Return to Home';
      primaryAction = () => context.go('/');
    }

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
                Icon(icon, size: 80, color: iconColor),
                const SizedBox(height: 32),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                if (submittedAt != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Submitted: ${DateFormat('MMM d, yyyy h:mm a').format(submittedAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black45),
                  ),
                ],
                if (reviewedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Reviewed: ${DateFormat('MMM d, yyyy h:mm a').format(reviewedAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black45),
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: primaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71B1B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(primaryActionLabel),
                  ),
                ),
                const SizedBox(height: 16),
                if (auth.hasPendingArtistApplication)
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
    super.dispose();
  }

  bool _isComplete() {
    final bio = _bioController.text.trim();
    return _styleController.text.trim().isNotEmpty &&
        bio.isNotEmpty &&
        bio.length <= 500 &&
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
                              _sampleArtworks.add('');
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();

    final artworks = _filterByCategory(data.artworks, _selectedCategory);
    final featured = artworks.where((item) => item.isFeatured).toList();
    final categories = data.categories;
    final auctions = artworks.where((item) {
      return item.isAuction &&
          item.auctionStatus == 'active' &&
          (item.auctionEndAt == null ||
              item.auctionEndAt!.isAfter(DateTime.now()));
    }).toList();

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
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.16),
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
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Featured Artwork',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            firstFeatured.artistName,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            firstFeatured.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              firstFeatured.imageUrl ??
                                  (firstFeatured.images.isNotEmpty
                                      ? firstFeatured.images.first
                                      : ''),
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 140,
                                color: const Color(0xFFF1E5CE),
                                child: const Icon(Icons.image_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.tonal(
                            onPressed: () =>
                                context.push('/artwork/${firstFeatured.id}'),
                            child: const Text('View Artwork'),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Featured Artwork',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  firstFeatured.artistName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                  onPressed: () => context.push(
                                    '/artwork/${firstFeatured.id}',
                                  ),
                                  child: const Text('View Artwork'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              firstFeatured.imageUrl ??
                                  (firstFeatured.images.isNotEmpty
                                      ? firstFeatured.images.first
                                      : ''),
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
              );
            },
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
              final category = categories[index];
              final isSelected = category == _selectedCategory;

              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
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
                    _categoryLabel(category),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        if (auctions.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Happening Now',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: auctions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = auctions[index];
                return SizedBox(
                  width: 190,
                  child: ArtworkCard(
                    artwork: item,
                    onTap: () => context.push('/artwork/${item.id}'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
        ],

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
            child: Center(child: Text("No artworks in this category yet")),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 2;
              const spacing = 10.0;
              final cardWidth =
                  (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
                  crossAxisCount;
              final cardHeight = cardWidth + 92;

              return GridView.builder(
                itemCount: artworks.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
          height: 252,
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

                      Flexible(
                        child: Text(
                          slide.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.4,
                          ),
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
    final data = context.watch<AppDataState>();
    // stable dedupe (keeps order instead of Set randomizing)
    final artists = <String>[];
    final ratingsByArtist = <String, double>{};
    for (final artwork in data.artworks) {
      if (!artists.contains(artwork.artistName)) {
        artists.add(artwork.artistName);
      }
      final current = ratingsByArtist[artwork.artistName] ?? 0;
      ratingsByArtist[artwork.artistName] = current == 0
          ? artwork.avgRating
          : ((current + artwork.avgRating) / 2);
    }

    if (artists.isEmpty) {
      return const SizedBox.shrink();
    }

    // sort by rating (better "featured" logic)
    artists.sort(
      (a, b) => (ratingsByArtist[b] ?? 0).compareTo(ratingsByArtist[a] ?? 0),
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
          height: 204,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: artists.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final artistName = artists[index];
              final rating = ratingsByArtist[artistName] ?? 0;

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
                height: 32,
                child: FilledButton.tonal(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('View profile'),
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

class ArtistDashboardScreen extends StatelessWidget {
  const ArtistDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();
    final artistId = _chatUserId(auth);
    final commissions = data.commissions.where((item) {
      return item.artistId == artistId || item.artistName == auth.displayName;
    }).toList();
    final openCommissions = commissions.where((c) {
      final s = c.status.toLowerCase();
      return s == 'pending' ||
          s == 'accepted' ||
          s == 'sketch' ||
          s == 'in progress';
    }).length;
    final completedCommissions = commissions
        .where((c) => c.status.toLowerCase() == 'completed')
        .length;
    final myArtworks = data.artworks
        .where((item) => item.artistName == auth.displayName)
        .toList();
    final avgRating = myArtworks.isEmpty
        ? 0
        : myArtworks.fold<double>(
                0,
                (runningTotal, item) => runningTotal + item.avgRating,
              ) /
              myArtworks.length;
    final myArtworkIds = myArtworks.map((a) => a.id).toSet();
    final revenue = data.orders
        .where(
          (o) => o.artistId == artistId || myArtworkIds.contains(o.artworkId),
        )
        .fold<double>(0, (sum, item) => sum + item.total);
    final orderCount = data.orders
        .where(
          (o) => o.artistId == artistId || myArtworkIds.contains(o.artworkId),
        )
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Artist Dashboard',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: 'Open Commissions',
                value: '$openCommissions',
              ),
            ),
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: 'Completed',
                value: '$completedCommissions',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: 'Revenue',
                value: '\$${revenue.toStringAsFixed(0)}',
              ),
            ),
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: 'Rating',
                value: avgRating == 0 ? '-' : avgRating.toStringAsFixed(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: 'Portfolio',
                value: '${myArtworks.length}',
              ),
            ),
            SizedBox(
              width: 160,
              child: _MetricCard(label: 'Orders', value: '$orderCount'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => context.push('/create'),
              icon: const Icon(Icons.add),
              label: const Text('Upload Artwork'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/profile'),
              icon: const Icon(Icons.grid_view_outlined),
              label: const Text('View Portfolio'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/commissions'),
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Manage Commissions'),
            ),
          ],
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
              subtitle: Text(
                '${item.clientName.isEmpty ? 'Buyer request' : item.clientName} · Budget \$${item.budget.toStringAsFixed(0)}',
              ),
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
    final data = context.watch<AppDataState>();
    var artworks = data.artworks.where((item) {
      final categoryMatch =
          _selectedCategory == 'all' || item.category == _selectedCategory;
      final artistMatch =
          _artistController.text.trim().isEmpty ||
          item.artistName.toLowerCase().contains(
            _artistController.text.toLowerCase(),
          );
      final styleMatch =
          _styleController.text.trim().isEmpty ||
          item.medium?.toLowerCase().contains(
                _styleController.text.toLowerCase(),
              ) ==
              true;
      final priceMatch =
          item.price >= _priceRange.start && item.price <= _priceRange.end;
      final queryMatch =
          item.title.toLowerCase().contains(_query.toLowerCase()) ||
          item.artistName.toLowerCase().contains(_query.toLowerCase()) ||
          item.tags.any(
            (tag) => tag.toLowerCase().contains(_query.toLowerCase()),
          );
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
        (a, b) => data
            .isBoosted(b.id)
            .toString()
            .compareTo(data.isBoosted(a.id).toString()),
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
            children: data.categories.map((item) {
              final selected = item == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_categoryLabel(item)),
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
  bool _trackedView = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();
    final artwork = data.artworks.firstWhere(
      (art) => art.id == widget.id,
      orElse: () => data.artworks.isNotEmpty
          ? data.artworks.first
          : Artwork(
              id: widget.id,
              title: 'Artwork',
              artistName: 'Artist',
              price: 0,
            ),
    );
    final formatter = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 0);
    final images = artwork.images.isNotEmpty
        ? artwork.images
        : [
            if ((artwork.imageUrl ?? '').isNotEmpty) artwork.imageUrl!,
          ];
    final img = images.isNotEmpty ? images.first : '';
    if (!_trackedView) {
      _trackedView = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        data.trackView(artwork.id);
      });
    }

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
        GestureDetector(
          onTap: images.isEmpty
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _FullscreenGalleryScreen(
                        images: images,
                        initialIndex: 0,
                        title: artwork.title,
                      ),
                    ),
                  );
                },
          child: ClipRRect(
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
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _FullscreenGalleryScreen(
                          images: images,
                          initialIndex: index,
                          title: artwork.title,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[index],
                      width: 86,
                      height: 86,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 86,
                        height: 86,
                        color: const Color(0xFFF1E5CE),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_outlined),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            Chip(
              label: Text(_categoryLabel(artwork.category)),
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              label: Text(
                artwork.isAuction ? 'Auction' : 'Direct Sale',
              ),
              visualDensity: VisualDensity.compact,
            ),
            if (artwork.isFeatured)
              const Chip(
                label: Text('Featured'),
                backgroundColor: Color(0x33E3BC2D),
                visualDensity: VisualDensity.compact,
              ),
            if (data.isSold(artwork.id))
              const Chip(
                label: Text('Sold'),
                backgroundColor: Color(0x33166534),
                visualDensity: VisualDensity.compact,
              ),
            if (!artwork.acceptingCommissions)
              const Chip(
                label: Text('Commission Closed'),
                backgroundColor: Color(0x33B71B1B),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (artwork.medium != null)
                SizedBox(
                  width: 180,
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
                        Text(
                          artwork.medium!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              if (artwork.size != null)
                SizedBox(
                  width: 180,
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
                        Text(
                          artwork.size!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                width: 180,
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
                        'Inventory',
                        style: TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                      Text(
                        artwork.isOneOfAKind
                            ? 'One of a kind'
                            : 'Stock: ${artwork.stockCount}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 18),
        if (artwork.isAuction) ...[
          StreamBuilder<AuctionSnapshot?>(
            stream: _auctionService.watchAuction(artwork.id),
            builder: (context, snapshot) {
              final auction = snapshot.data;
              final currentBid = auction?.currentBid ?? artwork.price;
              final endsAt = auction?.endsAt ?? artwork.auctionEndAt;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gavel_outlined),
                        const SizedBox(width: 8),
                        Text(
                          'Auction',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Current bid: ${formatter.format(currentBid)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auction?.currentBidderName.isNotEmpty == true
                          ? 'Highest bidder: ${auction!.currentBidderName}'
                          : 'No bids yet. Starting bid is live.',
                    ),
                    if (endsAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Ends on ${DateFormat('MMM d, yyyy').format(endsAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (auth.currentUserId != artwork.artistId)
                      FilledButton.icon(
                        onPressed: () async {
                          final bid = await _showBidDialog(
                            context,
                            minimumBid: currentBid + 1,
                          );
                          if (bid == null) {
                            return;
                          }
                          try {
                            await _auctionService.placeBid(
                              artwork: artwork,
                              bidderId: auth.currentUserId ?? '',
                              bidderName: auth.displayName,
                              amount: bid,
                            );
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bid placed successfully.'),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                        icon: const Icon(Icons.gavel),
                        label: const Text('Place Bid'),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _sendInquiryRequest(
              context: context,
              auth: auth,
              artwork: artwork,
            ),
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
                context.read<AppDataState>().markArtworkSold(artwork.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Artwork marked as sold.')),
                );
              },
              child: const Text('Mark as Sold'),
            ),
          ),
        ],
        const SizedBox(height: 10),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: artwork.artistId.isEmpty
              ? null
              : FirebaseFirestore.instance
                  .collection('users')
                  .doc(artwork.artistId)
                  .snapshots(),
          builder: (context, snapshot) {
            final acceptingCommissions =
                snapshot.data?.data()?['acceptingCommissions'] as bool? ??
                artwork.acceptingCommissions;
            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                if (compact) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: acceptingCommissions
                              ? () => context.push(
                                  _commissionRoute(
                                    artistName: artwork.artistName,
                                    artistId: artwork.artistId,
                                    artworkId: artwork.id,
                                    artworkTitle: artwork.title,
                                  ),
                                )
                              : null,
                          icon: const Icon(Icons.palette_outlined),
                          label: Text(
                            acceptingCommissions
                                ? 'Commission'
                                : 'Commission Closed',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: artwork.isAuction
                              ? null
                              : () => context.push('/checkout/${artwork.id}'),
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: Text(
                            artwork.isAuction ? 'Auction Listing' : 'Buy Now',
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: acceptingCommissions
                            ? () => context.push(
                                _commissionRoute(
                                  artistName: artwork.artistName,
                                  artistId: artwork.artistId,
                                  artworkId: artwork.id,
                                  artworkTitle: artwork.title,
                                ),
                              )
                            : null,
                        icon: const Icon(Icons.palette_outlined),
                        label: Text(
                          acceptingCommissions
                              ? 'Commission'
                              : 'Commission Closed',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: artwork.isAuction
                            ? null
                            : () => context.push('/checkout/${artwork.id}'),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: Text(
                          artwork.isAuction ? 'Auction Listing' : 'Buy Now',
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
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
  final _stockController = TextEditingController(text: '1');
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedCategory;
  bool _featureThisArtwork = false;
  bool _initialized = false;
  bool _saving = false;
  int _step = 0;
  String _saleType = 'direct_sale';
  String _inventoryType = 'one_of_a_kind';
  DateTime? _auctionEndDate;
  final List<_SelectedArtworkPhoto> _localPhotos = [];
  final List<String> _existingImageUrls = [];

  Artwork? _editingArtwork(AppDataState data) {
    if (widget.artworkId == null) {
      return null;
    }
    return data.artworks
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
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickArtworkPhotos() async {
    final picked = await _imagePicker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (picked.isEmpty || !mounted) {
      return;
    }
    final selected = <_SelectedArtworkPhoto>[];
    for (final image in picked) {
      final bytes = await image.readAsBytes();
      final extension = image.path.contains('.')
          ? image.path.split('.').last
          : 'jpg';
      selected.add(
        _SelectedArtworkPhoto(bytes: bytes, extension: extension),
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _localPhotos.addAll(selected);
    });
  }

  bool _stepValid() {
    switch (_step) {
      case 0:
        return _selectedCategory != null &&
            _titleController.text.trim().isNotEmpty &&
            (_existingImageUrls.isNotEmpty || _localPhotos.isNotEmpty);
      case 1:
        return _descriptionController.text.trim().isNotEmpty &&
            _mediumController.text.trim().isNotEmpty &&
            _sizeController.text.trim().isNotEmpty &&
            (_inventoryType == 'one_of_a_kind' ||
                (int.tryParse(_stockController.text) ?? 0) > 0);
      default:
        final parsedPrice = double.tryParse(_priceController.text) ?? 0;
        return parsedPrice > 0 &&
            (_saleType == 'direct_sale' || _auctionEndDate != null);
    }
  }

  Future<void> _openSmartPricingHelper() async {
    final result = await Navigator.of(context).push<_SmartPricingResult>(
      MaterialPageRoute(
        builder: (_) => _SmartPricingHelperScreen(
          category: _selectedCategory ?? 'painting',
        ),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _priceController.text = result.suggestedMinimum.toStringAsFixed(0);
    });
  }

  Future<void> _pickAuctionEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _auctionEndDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _auctionEndDate = DateTime(picked.year, picked.month, picked.day, 23, 59);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();
    final editing = _editingArtwork(data);
    if (!_initialized && editing != null) {
      _titleController.text = editing.title;
      _priceController.text = editing.price.toStringAsFixed(0);
      _descriptionController.text = editing.description ?? '';
      _mediumController.text = editing.medium ?? '';
      _sizeController.text = editing.size ?? '';
      _tagsController.text = editing.tags.join(', ');
      _stockController.text = editing.stockCount.toString();
      _selectedCategory = editing.category;
      _featureThisArtwork = editing.isFeatured;
      _saleType = editing.saleType;
      _inventoryType = editing.inventoryType;
      _auctionEndDate = editing.auctionEndAt;
      _existingImageUrls
        ..clear()
        ..addAll(
          editing.images.isNotEmpty
              ? editing.images
              : [
                  if ((editing.imageUrl ?? '').isNotEmpty) editing.imageUrl!,
                ],
        );
      _initialized = true;
    }
    final categoryItems = data.categories.where((item) => item != 'all').toList();
    final imageCount = _existingImageUrls.length + _localPhotos.length;

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
        _ArtworkStepHeader(currentStep: _step),
        const SizedBox(height: 18),
        if (_step == 0) ...[
          Text('Artwork Image', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _saving ? null : _pickArtworkPhotos,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDED8CE)),
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: imageCount > 0
                  ? Stack(
                      children: [
                        Positioned.fill(
                          child: Image(
                            image: _localPhotos.isNotEmpty
                                ? MemoryImage(_localPhotos.first.bytes)
                                : NetworkImage(_existingImageUrls.first)
                                      as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.68),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$imageCount photo${imageCount == 1 ? '' : 's'}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const _ImageUploadPlaceholder(
                      title: 'Tap to upload artwork photo',
                    ),
            ),
          ),
          const SizedBox(height: 12),
          if (imageCount > 0)
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageCount + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == imageCount) {
                    return InkWell(
                      onTap: _saving ? null : _pickArtworkPhotos,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 92,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDED8CE)),
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined),
                      ),
                    );
                  }

                  final existing = index < _existingImageUrls.length;
                  final localIndex = index - _existingImageUrls.length;
                  final imageProvider = existing
                      ? NetworkImage(_existingImageUrls[index]) as ImageProvider
                      : MemoryImage(_localPhotos[localIndex].bytes);

                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image(
                          image: imageProvider,
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (existing) {
                                _existingImageUrls.removeAt(index);
                              } else {
                                _localPhotos.removeAt(localIndex);
                              }
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.68),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText: 'Name your artwork',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category *',
              border: OutlineInputBorder(),
            ),
            hint: const Text('Select category'),
            items: categoryItems
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(_categoryLabel(item)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
        ],
        if (_step == 1) ...[
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _mediumController,
            decoration: const InputDecoration(
              labelText: 'Medium/Style',
              hintText: 'Digital Painting',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sizeController,
            decoration: const InputDecoration(
              labelText: 'Size',
              hintText: '100 x 56',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'one_of_a_kind',
                label: Text('One of a kind'),
              ),
              ButtonSegment<String>(
                value: 'multiple',
                label: Text('Many / Stock'),
              ),
            ],
            selected: {_inventoryType},
            onSelectionChanged: (selection) {
              setState(() {
                _inventoryType = selection.first;
              });
            },
          ),
          if (_inventoryType == 'multiple') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
        if (_step == 2) ...[
          SegmentedButton<String>(
            segments: const [
              ButtonSegment<String>(
                value: 'direct_sale',
                label: Text('Direct Sale'),
              ),
              ButtonSegment<String>(
                value: 'auction',
                label: Text('Auction'),
              ),
            ],
            selected: {_saleType},
            onSelectionChanged: (selection) {
              setState(() {
                _saleType = selection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _saleType == 'auction'
                        ? 'Starting bid (P) *'
                        : 'Price (P) *',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: _openSmartPricingHelper,
                icon: const Icon(Icons.auto_awesome),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Tags',
              hintText: 'Separate with commas',
              border: OutlineInputBorder(),
            ),
          ),
          if (_saleType == 'auction') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickAuctionEndDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _auctionEndDate == null
                    ? 'Set auction end date'
                    : 'Ends ${DateFormat('MMM d, yyyy').format(_auctionEndDate!)}',
              ),
            ),
          ],
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
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        if (_step < 2) {
                          if (!_stepValid()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please complete the current step first.',
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() => _step += 1);
                          return;
                        }

                        if (!_stepValid()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please complete the required artwork details.',
                              ),
                            ),
                          );
                          return;
                        }

                        final parsedPrice =
                            double.tryParse(_priceController.text) ?? 0;
                        final recordId =
                            editing?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString();
                        final userId = auth.currentUserId ?? '';
                        final resolvedImages = <String>[
                          ..._existingImageUrls,
                        ];

                        if (userId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Sign in again before uploading artwork.',
                              ),
                            ),
                          );
                          return;
                        }

                        setState(() => _saving = true);
                        try {
                          for (final photo in _localPhotos) {
                            if (!_supabaseImageService.isConfigured) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fill the Supabase credentials in .env before uploading artwork images.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final uploaded = await _supabaseImageService
                                .uploadArtworkImage(
                                  userId: userId,
                                  artworkId: recordId,
                                  bytes: photo.bytes,
                                  fileExtension: photo.extension,
                                );
                            resolvedImages.add(uploaded);
                          }

                          if (resolvedImages.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Add at least one artwork image before publishing.',
                                ),
                              ),
                            );
                            return;
                          }

                          final record = Artwork(
                            id: recordId,
                            title: _titleController.text.trim(),
                            artistId: userId,
                            artistName: auth.displayName,
                            price: parsedPrice,
                            description: _descriptionController.text.trim(),
                            category: _selectedCategory ?? 'other',
                            medium: _mediumController.text.trim(),
                            size: _sizeController.text.trim(),
                            imageUrl: resolvedImages.first,
                            images: resolvedImages,
                            tags: _tagsController.text
                                .split(',')
                                .map((item) => item.trim())
                                .where((item) => item.isNotEmpty)
                                .toList(),
                            isFeatured: _featureThisArtwork,
                            avgRating: editing?.avgRating ?? 0,
                            sold: editing?.sold ?? false,
                            views: editing?.views ?? 0,
                            inquiries: editing?.inquiries ?? 0,
                            inventoryType: _inventoryType,
                            stockCount: _inventoryType == 'multiple'
                                ? (int.tryParse(_stockController.text) ?? 1)
                                : 1,
                            saleType: _saleType,
                            auctionStatus: _saleType == 'auction'
                                ? 'active'
                                : 'inactive',
                            auctionEndAt: _saleType == 'auction'
                                ? _auctionEndDate
                                : null,
                            acceptingCommissions: auth.acceptingCommissions,
                          );
                          await context.read<AppDataState>().upsertArtwork(record);
                          if (_saleType == 'auction') {
                            await _auctionService.ensureAuctionForArtwork(record);
                          }
                          if (!context.mounted) {
                            return;
                          }
                          context.go('/artist-dashboard');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                editing == null
                                    ? 'Artwork published.'
                                    : 'Artwork updated.',
                              ),
                            ),
                          );
                        } catch (_) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Artwork could not be saved right now. Check the image upload configuration and try again.',
                              ),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _saving = false);
                          }
                        }
                      },
                child: Text(
                  _step < 2
                      ? 'Next'
                      : editing == null
                      ? 'Publish'
                      : 'Save',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _saving
                    ? null
                    : () {
                        if (_step == 0) {
                          context.pop();
                          return;
                        }
                        setState(() => _step -= 1);
                      },
                child: Text(_step == 0 ? 'Close' : 'Back'),
              ),
            ),
          ],
        ),
        if (editing != null) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              context.read<AppDataState>().deleteArtwork(editing.id);
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
    final data = context.watch<AppDataState>();
    final displayName = auth.displayName;
    final username = auth.username;
    final bio = auth.bio;
    final currentUserId = auth.currentUserId;
    final userInitial = displayName.isEmpty ? 'A' : displayName[0];
    final works = data.artworks
        .where(
          (item) =>
              (currentUserId != null && item.artistId == currentUserId) ||
              item.artistName == displayName,
        )
        .toList();
    final averageRating = works.isEmpty
        ? 0
        : works.fold<double>(
                0,
                (runningTotal, item) => runningTotal + item.avgRating,
              ) /
              works.length;
    final salesCount = works.where((w) => data.isSold(w.id)).length;
    final commissions = data.commissions;

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
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 8,
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
                                if (auth.isArtist)
                                  Chip(
                                    label: Text(
                                      auth.acceptingCommissions
                                          ? 'Accepting Commissions'
                                          : 'Commission Closed',
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
                            clipBehavior: Clip.antiAlias,
                            child: auth.photoUrl.isEmpty
                                ? Text(
                                    userInitial,
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  )
                                : Image.network(
                                    auth.photoUrl,
                                    width: 88,
                                    height: 88,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return Text(
                                        userInitial,
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      );
                                    },
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
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 160,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/orders'),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Orders'),
                    ),
                  ),
                  SizedBox(
                    width: 160,
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
              if (!auth.isArtist &&
                  !auth.verificationSubmitted &&
                  !auth.artistApplicationRejected)
                FilledButton.icon(
                  onPressed: () => context.push('/become-artist'),
                  icon: const Icon(Icons.brush_outlined),
                  label: const Text('Become an Artist'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                )
              else if (auth.hasPendingArtistApplication)
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
              else if (auth.artistApplicationRejected)
                OutlinedButton.icon(
                  onPressed: () => context.push('/verification'),
                  icon: const Icon(Icons.assignment_late_outlined),
                  label: const Text('Application Feedback'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
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
              Text('Stats', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _StatColumn(label: 'Artworks', value: '${works.length}'),
                    _StatColumn(label: 'Sales', value: '$salesCount'),
                    _StatColumn(
                      label: 'Rating',
                      value: averageRating == 0
                          ? '-'
                          : averageRating.toStringAsFixed(1),
                    ),
                    _StatColumn(
                      label: 'Commissions',
                      value:
                          '${commissions.where((item) => item.artistId == currentUserId || item.clientId == currentUserId || item.artistName == displayName || item.clientName == displayName).length}',
                    ),
                  ],
                ),
              ),
              if (auth.isArtist) ...[
                const SizedBox(height: 16),
                Text(
                  'Portfolio',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Artworks'),
                      icon: Icon(Icons.grid_view_outlined),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Commissions'),
                      icon: Icon(Icons.assignment_outlined),
                    ),
                  ],
                  selected: {_showArtworks},
                  onSelectionChanged: (value) {
                    setState(() {
                      _showArtworks = value.first;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_showArtworks)
                  if (works.isEmpty)
                    const _ProfileEmptyState(
                      title: 'No artworks yet',
                      subtitle:
                          'Upload a piece to start building your portfolio.',
                      cta: 'Upload New Artwork',
                      icon: Icons.image_outlined,
                      route: '/create',
                    )
                  else
                    ...works.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ArtworkCard(
                          artwork: item,
                          onTap: () => context.push('/artwork/${item.id}'),
                        ),
                      );
                    })
                else if (commissions
                    .where(
                      (item) =>
                          item.artistId == currentUserId ||
                          item.artistName == displayName,
                    )
                    .isEmpty)
                  const _ProfileEmptyState(
                    title: 'No commission work yet',
                    subtitle:
                        'Incoming commission requests and completed projects will appear here.',
                    cta: 'Open Messages',
                    icon: Icons.chat_bubble_outline,
                    route: '/messages',
                  )
                else
                  ...commissions
                      .where(
                        (item) =>
                            item.artistId == currentUserId ||
                            item.artistName == displayName,
                      )
                      .map((item) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item.title),
                            subtitle: Text(
                              item.clientName.isEmpty
                                  ? item.brief
                                  : '${item.clientName} · ${item.brief}',
                            ),
                            trailing: _statusChip(item.status),
                          ),
                        );
                      }),
              ],
              const SizedBox(height: 24),
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

class _EmptyMessageCard extends StatelessWidget {
  const _EmptyMessageCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageUploadPlaceholder extends StatelessWidget {
  const _ImageUploadPlaceholder({
    this.title = 'Tap to add image',
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_outlined, color: Colors.black54),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _ArtworkStepHeader extends StatelessWidget {
  const _ArtworkStepHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Basics', 'Details', 'Pricing'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFFD9D2C8),
                  borderRadius: BorderRadius.circular(99),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  labels[index],
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (index != labels.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('-'),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _SelectedArtworkPhoto {
  const _SelectedArtworkPhoto({
    required this.bytes,
    required this.extension,
  });

  final Uint8List bytes;
  final String extension;
}

class _SmartPricingResult {
  const _SmartPricingResult({
    required this.suggestedMinimum,
    required this.suggestedMaximum,
    required this.estimatedNetProfit,
    required this.averageMarketPrice,
  });

  final double suggestedMinimum;
  final double suggestedMaximum;
  final double estimatedNetProfit;
  final double averageMarketPrice;
}

class _SmartPricingHelperScreen extends StatefulWidget {
  const _SmartPricingHelperScreen({required this.category});

  final String category;

  @override
  State<_SmartPricingHelperScreen> createState() =>
      _SmartPricingHelperScreenState();
}

class _SmartPricingHelperScreenState extends State<_SmartPricingHelperScreen> {
  late String _category;
  final _hoursController = TextEditingController(text: '6');
  final _hourlyRateController = TextEditingController(text: '55');
  final _materialCostController = TextEditingController(text: '49');
  _SmartPricingResult? _result;

  @override
  void initState() {
    super.initState();
    _category = widget.category;
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _hourlyRateController.dispose();
    _materialCostController.dispose();
    super.dispose();
  }

  void _calculate() {
    final hours = double.tryParse(_hoursController.text) ?? 0;
    final hourlyRate = double.tryParse(_hourlyRateController.text) ?? 0;
    final materialCost = double.tryParse(_materialCostController.text) ?? 0;
    final base = (hours * hourlyRate) + materialCost;
    final suggestedMinimum = base * 1.25;
    final suggestedMaximum = base * 2.08;
    final estimatedNet = suggestedMinimum * 0.95 - materialCost;
    final averageMap = <String, double>{
      'painting': 4267,
      'digital': 2180,
      'illustration': 1950,
      'photography': 1650,
      'prints': 980,
      'stickers': 550,
      'charms': 720,
    };

    setState(() {
      _result = _SmartPricingResult(
        suggestedMinimum: suggestedMinimum,
        suggestedMaximum: suggestedMaximum,
        estimatedNetProfit: estimatedNet,
        averageMarketPrice: averageMap[_category] ?? 1800,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'P', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing Guidance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Smart Pricing Helper',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Calculate a fair price based on your effort and materials.',
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: const [
              'painting',
              'digital',
              'illustration',
              'photography',
              'prints',
              'stickers',
              'charms',
            ]
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(_categoryLabel(item)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _category = value);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Art Category',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hoursController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Hours spent',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hourlyRateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Your hourly rate (PHP)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _materialCostController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Material costs (PHP)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _calculate,
            child: const Text('Calculate Suggested Price'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF4E3DF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Suggested Price Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      '${currency.format(_result!.suggestedMinimum)} - ${currency.format(_result!.suggestedMaximum)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Platform Fee (5%): -${currency.format(_result!.suggestedMinimum * 0.05)}',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Estimated Net Profit: ${currency.format(_result!.estimatedNetProfit)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_result),
                    child: const Text('Use Suggested Minimum'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Market Comparison\nAverage price for ${_categoryLabel(_category).toLowerCase()}: ${currency.format(_result!.averageMarketPrice)}',
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'This is a guide based on your inputs. Consider market demand and your experience level when setting the final price.',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FullscreenGalleryScreen extends StatefulWidget {
  const _FullscreenGalleryScreen({
    required this.images,
    required this.initialIndex,
    required this.title,
  });

  final List<String> images;
  final int initialIndex;
  final String title;

  @override
  State<_FullscreenGalleryScreen> createState() =>
      _FullscreenGalleryScreenState();
}

class _FullscreenGalleryScreenState extends State<_FullscreenGalleryScreen> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<double?> _showBidDialog(
  BuildContext context, {
  required double minimumBid,
}) async {
  final controller = TextEditingController(
    text: minimumBid.toStringAsFixed(0),
  );
  final submitted = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Place Bid'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Bid amount',
            helperText: 'Minimum ${minimumBid.toStringAsFixed(0)}',
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
  final parsed = double.tryParse(controller.text);
  controller.dispose();
  if (submitted != true || parsed == null) {
    return null;
  }
  return parsed;
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
  String _profilePhotoExtension = 'jpg';
  bool _portfolioPack = false;
  bool _featuredBoost = false;
  bool _acceptingCommissions = true;
  bool _profileLoaded = false;
  bool _savingProfile = false;

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
    final extension = picked.path.contains('.')
        ? picked.path.split('.').last
        : 'jpg';
    setState(() {
      _profilePhotoBytes = bytes;
      _profilePhotoExtension = extension;
    });
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
      _portfolioPack = auth.hasPortfolioPack;
      _featuredBoost = auth.hasFeaturedBoost;
      _acceptingCommissions = auth.acceptingCommissions;
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
                child: _profilePhotoBytes != null
                    ? ClipOval(
                        child: Image.memory(
                          _profilePhotoBytes!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                    : auth.photoUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          auth.photoUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person_outline, size: 36),
                        ),
                      )
                    : ClipOval(
                        child: const Icon(Icons.person_outline, size: 36),
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
        if (auth.isArtist || auth.isAdmin)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _acceptingCommissions,
            title: const Text('Accept commissions'),
            subtitle: const Text(
              'Turn this off to disable commission requests on your artworks.',
            ),
            onChanged: (value) {
              setState(() {
                _acceptingCommissions = value;
              });
            },
          ),
        if (auth.isArtist || auth.isAdmin) const SizedBox(height: 12),
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
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            auth.isVerifiedArtist ? Icons.verified : Icons.verified_outlined,
            color: auth.isVerifiedArtist ? Colors.green : Colors.black45,
          ),
          title: const Text('Artist verification'),
          subtitle: Text(
            auth.isVerifiedArtist
                ? 'Verified through the admin review flow.'
                : 'Managed through the artist application review process.',
          ),
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
          onPressed: _savingProfile
              ? null
              : () async {
                  setState(() => _savingProfile = true);
                  try {
                    var resolvedPhotoUrl = auth.photoUrl;
                    if (_profilePhotoBytes != null) {
                      final userId = auth.currentUserId ?? '';
                      if (userId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Sign in again before uploading a profile image.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (!_supabaseImageService.isConfigured) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Fill the Supabase credentials in .env before uploading a profile image.',
                            ),
                          ),
                        );
                        return;
                      }
                      resolvedPhotoUrl = await _supabaseImageService
                          .uploadProfileImage(
                            userId: userId,
                            bytes: _profilePhotoBytes!,
                            fileExtension: _profilePhotoExtension,
                          );
                    }

                    await auth.saveProfile(
                      name: _nameController.text,
                      username: _usernameController.text,
                      bio: _bioController.text,
                      photoUrl: resolvedPhotoUrl,
                      portfolioPack: _portfolioPack,
                    featuredBoost: _featuredBoost,
                    acceptingCommissions: _acceptingCommissions,
                  );
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated.')),
                    );
                    context.go('/profile');
                  } catch (_) {
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Profile could not be updated right now.',
                        ),
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _savingProfile = false);
                    }
                  }
                },
          child: _savingProfile
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save changes'),
        ),
      ],
    );
  }
}

final _chatService = ChatService();
final _auctionService = AuctionService();
const _supabaseImageService = SupabaseImageService();
ChatContact _artistAliasContact(String artistName) {
  return ChatContact(
    userId: ChatContact.aliasUserIdForName(artistName),
    displayName: artistName,
    role: 'Artist',
  );
}

ChatContact _artworkContact(Artwork artwork) {
  if (artwork.artistId.isNotEmpty) {
    return ChatContact(
      userId: artwork.artistId,
      displayName: artwork.artistName,
      role: 'Artist',
    );
  }
  return _artistAliasContact(artwork.artistName);
}

String _roleLabel(AuthState auth) {
  if (auth.isAdmin) {
    return 'Admin';
  }
  if (auth.isArtist) {
    return 'Artist';
  }
  return 'Buyer';
}

String _chatUserId(AuthState auth) {
  return auth.currentUserId ?? ChatContact.aliasUserIdForName(auth.displayName);
}

String _commissionRoute({
  required String artistName,
  String artistId = '',
  String artworkId = '',
  String artworkTitle = '',
}) {
  final artist = Uri.encodeComponent(artistName);
  final artistUserId = Uri.encodeComponent(artistId);
  final artId = Uri.encodeComponent(artworkId);
  final title = Uri.encodeComponent(artworkTitle);
  return '/commission?artist=$artist&artistId=$artistUserId&artworkId=$artId&artworkTitle=$title';
}

String _categoryLabel(String value) {
  return value
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

List<Artwork> _filterByCategory(List<Artwork> artworks, String category) {
  if (category == 'all') {
    return artworks;
  }
  return artworks.where((item) => item.category == category).toList();
}

Future<void> _sendInquiryRequest({
  required BuildContext context,
  required AuthState auth,
  required Artwork artwork,
}) async {
  if (!_canUseChat(context, auth)) {
    return;
  }

  final noteController = TextEditingController(
    text:
        'Hi ${artwork.artistName}, I would like to ask about "${artwork.title}". Is it still available?',
  );

  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send inquiry',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'This starts a direct message request with the artist about this artwork.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Opening message',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Send request'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  final message = noteController.text.trim();
  noteController.dispose();
  if (submitted != true || message.isEmpty || !context.mounted) {
    return;
  }

  await context.read<AppDataState>().trackInquiry(artwork);
  final contact = _artworkContact(artwork);
  final conversationId = await _prepareConversation(
    auth: auth,
    otherUser: contact,
  );
  if (!context.mounted || conversationId == null) {
    return;
  }

  await _chatService.sendMessage(
    conversationId: conversationId,
    senderId: _chatUserId(auth),
    senderName: auth.displayName,
    senderRole: _roleLabel(auth),
    recipient: contact,
    text: message,
  );
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Inquiry sent. You can continue in chat.')),
  );
  context.push(_chatRoute(conversationId, contact));
}

bool _canUseChat(BuildContext context, AuthState auth) {
  if (!_chatService.isAvailable || !auth.firebaseAvailable) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Chat is unavailable because Firebase is not configured for this platform yet.',
        ),
      ),
    );
    return false;
  }

  if (auth.hasFirebaseSession && auth.currentUserId != null) {
    return true;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Chat requires a signed-in account.')),
  );
  context.go('/register');
  return false;
}

Future<String?> _prepareConversation({
  required AuthState auth,
  required ChatContact otherUser,
}) async {
  if (!_chatService.isAvailable || !auth.firebaseAvailable) {
    return null;
  }

  final currentUserId = auth.currentUserId;
  if (currentUserId == null) {
    return null;
  }

  return _chatService.ensureConversation(
    currentUserId: currentUserId,
    currentUserName: auth.displayName,
    currentUserRole: _roleLabel(auth),
    otherUser: otherUser,
  );
}

String _chatRoute(String conversationId, ChatContact contact) {
  final name = Uri.encodeComponent(contact.displayName);
  final role = Uri.encodeComponent(contact.role);
  final userId = Uri.encodeComponent(contact.userId);
  return '/chat/$conversationId?userId=$userId&name=$name&role=$role';
}

List<ChatContact> _mergeChatContacts({
  required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  required String currentUserId,
}) {
  final contacts = docs.where((doc) => doc.id != currentUserId).map((doc) {
    final data = doc.data();
    final roleValue = (data['role'] as String?) ?? 'buyer';
    final role = roleValue == 'admin'
        ? 'Admin'
        : (roleValue == 'artist' ? 'Artist' : 'Buyer');
    return ChatContact(
      userId: doc.id,
      displayName: (data['displayName'] as String?) ?? 'User',
      role: role,
    );
  }).toList();

  contacts.sort((a, b) => a.displayName.compareTo(b.displayName));
  return contacts;
}

ChatContact? _manualChatContactForQuery(
  String query,
  List<ChatContact> existingContacts,
) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final existingMatch = existingContacts
      .where(
        (contact) => contact.displayName.toLowerCase() == trimmed.toLowerCase(),
      )
      .toList()
      .firstOrNull;
  if (existingMatch != null) {
    return existingMatch;
  }
  return null;
}

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  Future<void> _showNewMessageSheet(BuildContext context) async {
    final auth = context.read<AuthState>();
    if (!_canUseChat(context, auth)) {
      return;
    }

    var query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, snapshot) {
                          final contacts = snapshot.hasData
                              ? _mergeChatContacts(
                                  docs: snapshot.data!.docs,
                                  currentUserId: auth.currentUserId!,
                                )
                              : const <ChatContact>[];
                          final filtered = contacts.where((contact) {
                            return contact.displayName.toLowerCase().contains(
                                  query.toLowerCase(),
                                ) ||
                                contact.role.toLowerCase().contains(
                                  query.toLowerCase(),
                                );
                          }).toList();
                          final manualContact = _manualChatContactForQuery(
                            query,
                            contacts,
                          );
                          final showManualStart =
                              manualContact != null &&
                              filtered
                                  .where(
                                    (contact) =>
                                        contact.userId == manualContact.userId,
                                  )
                                  .isEmpty;

                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount:
                                filtered.length + (showManualStart ? 1 : 0),
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              if (showManualStart && index == 0) {
                                return ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.add_comment_outlined),
                                  ),
                                  title: Text(
                                    'Start chat with "${manualContact.displayName}"',
                                  ),
                                  subtitle: const Text(
                                    'Create a new conversation',
                                  ),
                                  trailing: const Icon(
                                    Icons.chat_bubble_outline,
                                  ),
                                  onTap: () async {
                                    final conversationId =
                                        await _prepareConversation(
                                          auth: auth,
                                          otherUser: manualContact,
                                        );
                                    if (!context.mounted ||
                                        conversationId == null) {
                                      return;
                                    }
                                    Navigator.of(context).pop();
                                    context.push(
                                      _chatRoute(conversationId, manualContact),
                                    );
                                  },
                                );
                              }

                              final adjustedIndex =
                                  index - (showManualStart ? 1 : 0);
                              final contact = filtered[adjustedIndex];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(contact.initial),
                                ),
                                title: Text(contact.displayName),
                                subtitle: Text(contact.role),
                                trailing: const Icon(Icons.chat_bubble_outline),
                                onTap: () async {
                                  final conversationId =
                                      await _prepareConversation(
                                        auth: auth,
                                        otherUser: contact,
                                      );
                                  if (!context.mounted ||
                                      conversationId == null) {
                                    return;
                                  }
                                  Navigator.of(context).pop();
                                  context.push(
                                    _chatRoute(conversationId, contact),
                                  );
                                },
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
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();
    final userId = auth.currentUserId;
    final statusByConversation = <String, String>{
      for (final commission in data.commissions)
        if (commission.conversationId.isNotEmpty)
          commission.conversationId:
              commission.status.toLowerCase() == 'completed'
              ? 'Completed transaction'
              : commission.status.toLowerCase() == 'rejected'
              ? 'Request declined'
              : commission.status.toLowerCase() == 'delivered'
              ? 'Awaiting buyer confirmation'
              : commission.status.toLowerCase() == 'pending'
              ? 'Message request pending'
              : 'Ongoing commission',
    };

    if (!auth.hasFirebaseSession || userId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                'Chat needs sign-in',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in with your account to message artists and buyers in real time.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/register'),
                child: const Text('Go to Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    final dateFmt = DateFormat('MMM d, h:mm a');
    return Stack(
      children: [
        StreamBuilder<List<ChatConversationPreview>>(
          stream: _chatService.watchConversationsForUser(userId),
          builder: (context, snapshot) {
            final conversations =
                snapshot.data ?? const <ChatConversationPreview>[];
            if (conversations.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 52),
                      const SizedBox(height: 12),
                      Text(
                        'No conversations yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Start a message with an artist or buyer to see your inbox here.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final item = conversations[index];
                final contact = ChatContact(
                  userId: item.otherUserId,
                  displayName: item.otherName,
                  role: item.otherRole,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(item.initial)),
                    title: Text(item.otherName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.otherRole} · ${dateFmt.format(item.updatedAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (statusByConversation[item.conversationId] !=
                            null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              statusByConversation[item.conversationId]!,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: item.hasUnread
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${item.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                    onTap: () =>
                        context.push(_chatRoute(item.conversationId, contact)),
                  ),
                );
              },
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
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.participantId,
    this.participantName,
    this.participantRole,
  });

  final String conversationId;
  final String? participantId;
  final String? participantName;
  final String? participantRole;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  ChatContact? _participant;
  String? _reminderSentForCommissionId;

  @override
  void initState() {
    super.initState();
    if (widget.participantId != null && widget.participantName != null) {
      _participant = ChatContact(
        userId: widget.participantId!,
        displayName: widget.participantName!,
        role: widget.participantRole ?? 'Artist',
      );
    }
    _markRead();
    _loadParticipant();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    final auth = context.read<AuthState>();
    final userId = auth.currentUserId;
    if (userId == null) {
      return;
    }
    await _chatService.markConversationRead(
      userId: userId,
      conversationId: widget.conversationId,
    );
  }

  Future<void> _loadParticipant() async {
    final auth = context.read<AuthState>();
    final userId = auth.currentUserId;
    if (userId == null || _participant != null) {
      return;
    }

    final participant = await _chatService.getConversationContact(
      currentUserId: userId,
      conversationId: widget.conversationId,
    );
    if (!mounted || participant == null) {
      return;
    }

    setState(() {
      _participant = participant;
    });
  }

  Future<void> _maybeSendCommissionReminder({
    required AuthState auth,
    required Commission commission,
  }) async {
    if (!auth.isArtist ||
        commission.artistId != auth.currentUserId ||
        !commission.isOngoing ||
        commission.conversationId != widget.conversationId) {
      return;
    }
    if (_reminderSentForCommissionId == commission.id) {
      return;
    }
    final now = DateTime.now();
    final lastReminder = commission.lastReminderAt;
    if (lastReminder != null && now.difference(lastReminder).inHours < 24) {
      _reminderSentForCommissionId = commission.id;
      return;
    }
    final reminderText =
        'Reminder for "${commission.title}": send a quick progress update to your client so they know how the commission project is going.';
    await context.read<AppDataState>().addNotification(
      userId: auth.currentUserId ?? '',
      title: 'System Notifications',
      body: reminderText,
      type: 'system',
      source: 'system_notifications',
      conversationId: commission.conversationId,
      commissionId: commission.id,
    );
    await context.read<AppDataState>().updateCommissionReminder(
      commission.id,
      remindedAt: now,
    );
    await _chatService.sendSystemMessage(
      conversationId: commission.conversationId,
      text: reminderText,
    );
    _reminderSentForCommissionId = commission.id;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();
    final currentUserId = auth.currentUserId;
    final relatedCommission = data.commissions
        .where((item) => item.conversationId == widget.conversationId)
        .toList()
        .firstOrNull;

    if (relatedCommission != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeSendCommissionReminder(
          auth: auth,
          commission: relatedCommission,
        );
      });
    }

    if (!auth.hasFirebaseSession || currentUserId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                'Chat needs sign-in',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in first, then come back to continue this conversation.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final participant = _participant;
    final chatName = participant?.displayName ?? 'Conversation';
    final chatInitial = participant?.initial ?? 'C';

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
              if (participant != null)
                Text(
                  participant.role,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _chatService.watchMessages(widget.conversationId),
            builder: (context, snapshot) {
              final messages = snapshot.data ?? const <ChatMessage>[];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _markRead();
              });

              if (messages.isEmpty) {
                return const Center(
                  child: Text('No messages yet. Start the conversation below.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final item = messages[index];
                  if (item.isSystemNotification) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 280),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.text,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    );
                  }
                  final mine = item.senderId == currentUserId;
                  return Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!mine)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                item.senderName,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          Text(item.text),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (auth.isArtist &&
            relatedCommission != null &&
            relatedCommission.isOngoing)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Reminder: send your client a progress update for this commission.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
                  onPressed: () async {
                    final text = _messageController.text.trim();
                    if (text.isEmpty || participant == null) {
                      return;
                    }
                    await _chatService.sendMessage(
                      conversationId: widget.conversationId,
                      senderId: currentUserId,
                      senderName: auth.displayName,
                      senderRole: _roleLabel(auth),
                      recipient: participant,
                      text: text,
                    );
                    await _markRead();
                    _messageController.clear();
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
  const CommissionRequestScreen({
    super.key,
    this.artistName,
    this.artistId,
    this.artworkId,
    this.artworkTitle,
  });

  final String? artistName;
  final String? artistId;
  final String? artworkId;
  final String? artworkTitle;

  @override
  State<CommissionRequestScreen> createState() =>
      _CommissionRequestScreenState();
}

class _CommissionRequestScreenState extends State<CommissionRequestScreen> {
  final _artistController = TextEditingController();
  final _titleController = TextEditingController();
  final _briefController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _dueDate;
  bool _prefilled = false;

  @override
  void dispose() {
    _artistController.dispose();
    _titleController.dispose();
    _briefController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!_prefilled) {
      _artistController.text = widget.artistName ?? '';
      _titleController.text = widget.artworkTitle?.isNotEmpty == true
          ? 'Commission inspired by ${widget.artworkTitle}'
          : '';
      _prefilled = true;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Commission request',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _artistController,
          decoration: const InputDecoration(
            labelText: 'Artist',
            border: OutlineInputBorder(),
          ),
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
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 14)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked == null) {
              return;
            }
            setState(() {
              _dueDate = picked;
            });
          },
          icon: const Icon(Icons.event_outlined),
          label: Text(
            _dueDate == null
                ? 'Choose target completion date'
                : 'Due ${DateFormat('MMM d, yyyy').format(_dueDate!)}',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            final budget = double.tryParse(_budgetController.text) ?? 0;
            final artistName = _artistController.text.trim();
            if (artistName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please choose an artist first.')),
              );
              return;
            }
            if (_dueDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please choose a target completion date.'),
                ),
              );
              return;
            }

            final artistContact = widget.artistId?.isNotEmpty == true
                ? ChatContact(
                    userId: widget.artistId!,
                    displayName: artistName,
                    role: 'Artist',
                  )
                : _artistAliasContact(artistName);
            final conversationId = await _prepareConversation(
              auth: auth,
              otherUser: artistContact,
            );
            final brief = _briefController.text.trim();
            final timeline = DateFormat('MMM d, yyyy').format(_dueDate!);
            context.read<AppDataState>().addCommission(
              Commission(
                id: 'C${DateTime.now().millisecondsSinceEpoch}',
                title: _titleController.text.trim().isEmpty
                    ? 'Custom artwork request'
                    : _titleController.text.trim(),
                brief: brief,
                budget: budget <= 0 ? 1000 : budget,
                clientId: _chatUserId(auth),
                clientName: auth.displayName,
                artistId: artistContact.userId,
                artistName: artistName,
                conversationId: conversationId ?? '',
                artworkId: widget.artworkId ?? '',
                artworkTitle: widget.artworkTitle ?? '',
                timeline: timeline,
                dueDate: _dueDate,
                status: 'Pending',
              ),
            );
            if (conversationId != null) {
              await _chatService.sendMessage(
                conversationId: conversationId,
                senderId: _chatUserId(auth),
                senderName: auth.displayName,
                senderRole: _roleLabel(auth),
                recipient: artistContact,
                text:
                    'Commission request: ${_titleController.text.trim().isEmpty ? 'Custom artwork request' : _titleController.text.trim()}\nBudget: PHP ${(budget <= 0 ? 1000 : budget).toStringAsFixed(0)}\nTarget date: $timeline\n${brief.isEmpty ? 'Sharing more details soon.' : brief}',
              );
            }
            if (!context.mounted) {
              return;
            }
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
  static const _artistProgression = <String, String>{
    'accepted': 'Sketch',
    'sketch': 'In Progress',
    'in progress': 'Revision',
    'revision': 'Delivered',
  };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();
    final userId = _chatUserId(auth);
    final artistView = auth.isArtist || auth.isAdmin;
    final commissions = data.commissions.where((item) {
      return artistView
          ? item.artistId == userId || item.artistName == auth.displayName
          : item.clientId == userId || item.clientName == auth.displayName;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          artistView
              ? 'Incoming commission requests'
              : 'My commission requests',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (commissions.isEmpty)
          const _EmptyMessageCard(
            title: 'No commission activity yet',
            subtitle: 'Start with an inquiry or submit a commission request.',
          ),
        ...commissions.map((item) {
          final normalized = item.status.toLowerCase();
          final nextStatus = _artistProgression[normalized];
          final counterpart = artistView ? item.clientName : item.artistName;
          final canOpenChat = item.conversationId.isNotEmpty;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.title),
                    subtitle: Text(
                      '${counterpart.isEmpty ? (artistView ? 'Buyer request' : 'Artist request') : counterpart} · Budget \$${item.budget.toStringAsFixed(0)}',
                    ),
                    trailing: _statusChip(item.status),
                  ),
                  if (item.artworkTitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Linked artwork: ${item.artworkTitle}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (item.brief.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(item.brief),
                    ),
                  if (item.timeline.isNotEmpty)
                    Text(
                      'Target date: ${item.timeline}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (item.dueDate != null &&
                      item.status.toLowerCase() != 'completed')
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        item.dueDate!.isBefore(DateTime.now())
                            ? 'Due date has passed'
                            : 'Due in ${item.dueDate!.difference(DateTime.now()).inDays} day(s)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: item.dueDate!.isBefore(DateTime.now())
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black54,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (canOpenChat)
                        OutlinedButton.icon(
                          onPressed: () {
                            final role = artistView ? 'Buyer' : 'Artist';
                            final contact = ChatContact(
                              userId: artistView
                                  ? item.clientId
                                  : item.artistId,
                              displayName: counterpart,
                              role: role,
                            );
                            context.push(
                              _chatRoute(item.conversationId, contact),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Message'),
                        ),
                      if (artistView && normalized == 'pending') ...[
                        OutlinedButton(
                          onPressed: () {
                            context.read<AppDataState>().updateCommissionStatus(
                              item.id,
                              'Rejected',
                            );
                          },
                          child: const Text('Reject'),
                        ),
                        FilledButton(
                          onPressed: () {
                            context.read<AppDataState>().updateCommissionStatus(
                              item.id,
                              'Accepted',
                            );
                          },
                          child: const Text('Accept'),
                        ),
                      ],
                      if (artistView && nextStatus != null)
                        FilledButton(
                          onPressed: () {
                            context.read<AppDataState>().updateCommissionStatus(
                              item.id,
                              nextStatus,
                            );
                          },
                          child: Text('Mark $nextStatus'),
                        ),
                      if (!artistView && normalized == 'delivered')
                        FilledButton(
                          onPressed: () {
                            context.read<AppDataState>().updateCommissionStatus(
                              item.id,
                              'Completed',
                            );
                          },
                          child: const Text('Confirm receipt'),
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
      final data = context.read<AppDataState>();
      final artistArtwork = data.artworks
          .where((item) => item.artistName == artistName)
          .toList()
          .firstOrNull;
      data.addReview(
        artistId: artistArtwork?.artistId ?? '',
        artistName: artistName,
        rating: rating,
        comment: commentController.text.trim(),
        authorId: context.read<AuthState>().currentUserId ?? '',
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
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();
    final actorId = _chatUserId(auth);
    final artistView = auth.isArtist || auth.isAdmin;
    final orders = data.orders.where((item) {
      return artistView
          ? item.artistId == actorId || item.artistName == auth.displayName
          : item.buyerId == actorId || item.buyerName == auth.displayName;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          artistView ? 'Sales and payouts' : 'Buyer order history',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (orders.isEmpty)
          const _EmptyMessageCard(
            title: 'No orders yet',
            subtitle: 'Completed purchases and sales will appear here.',
          ),
        ...orders.map((item) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.artworkTitle.isEmpty
                          ? 'Order #${item.id}'
                          : item.artworkTitle,
                    ),
                    subtitle: Text(
                      artistView
                          ? '${item.buyerName.isEmpty ? 'Buyer order' : item.buyerName} · ${item.paymentMethod}'
                          : '${item.artistName.isEmpty ? 'Artist order' : item.artistName} · ${item.paymentMethod}',
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statusChip(item.paymentStatus),
                      _statusChip(item.payoutStatus),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!artistView &&
                          item.status.toLowerCase() != 'completed')
                        OutlinedButton(
                          onPressed: () {
                            final nextStatus =
                                item.status.toLowerCase() == 'pending'
                                ? 'In Progress'
                                : item.status.toLowerCase() == 'in progress'
                                ? 'Delivered'
                                : 'Completed';
                            setState(() {
                              context.read<AppDataState>().updateOrderStatus(
                                item.id,
                                nextStatus,
                              );
                            });
                          },
                          child: Text(
                            item.status.toLowerCase() == 'delivered'
                                ? 'Confirm receipt'
                                : 'Advance order',
                          ),
                        ),
                      if (!artistView &&
                          item.status.toLowerCase() == 'completed')
                        OutlinedButton(
                          onPressed: () async {
                            await _rateArtist(context, item.artistName);
                          },
                          child: const Text('Rate artist'),
                        ),
                      if (artistView &&
                          item.status.toLowerCase() != 'completed')
                        FilledButton(
                          onPressed: () {
                            final nextStatus =
                                item.status.toLowerCase() == 'pending'
                                ? 'In Progress'
                                : item.status.toLowerCase() == 'in progress'
                                ? 'Delivered'
                                : 'Completed';
                            setState(() {
                              context.read<AppDataState>().updateOrderStatus(
                                item.id,
                                nextStatus,
                              );
                            });
                          },
                          child: Text(
                            'Mark ${item.status == 'Delivered' ? 'Completed' : 'Next Step'}',
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

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();
    final actorId = _chatUserId(auth);
    final artistView = auth.isArtist || auth.isAdmin;
    final orders = data.orders.where((item) {
      return artistView
          ? item.artistId == actorId || item.artistName == auth.displayName
          : item.buyerId == actorId || item.buyerName == auth.displayName;
    }).toList();
    final gross = orders.fold<double>(0, (sum, item) => sum + item.total);
    final fees = gross * 0.1;
    final net = gross - fees;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          artistView ? 'Wallet and payouts' : 'Checkout and payments',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: artistView ? 'Gross Sales' : 'Total Paid',
                value: '\$${gross.toStringAsFixed(0)}',
              ),
            ),
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: 'Platform Fees',
                value: '\$${fees.toStringAsFixed(0)}',
              ),
            ),
            SizedBox(
              width: 160,
              child: _MetricCard(
                label: artistView ? 'Net Income' : 'Escrow Held',
                value: '\$${net.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artistView
                      ? 'Withdrawal options'
                      : 'Simulated payment methods',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('GCash')),
                    Chip(label: Text('Maya')),
                    Chip(label: Text('Bank Transfer')),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  artistView
                      ? 'Payouts remain pending until orders are completed and funds are released from escrow.'
                      : 'Buyer payments are recorded as held until delivery is confirmed.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Transaction history',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (orders.isEmpty)
          const _EmptyMessageCard(
            title: 'No payment activity yet',
            subtitle: 'Completed transactions will appear here.',
          ),
        ...orders.map((item) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                item.artworkTitle.isEmpty
                    ? 'Order #${item.id}'
                    : item.artworkTitle,
              ),
              subtitle: Text(
                '${item.paymentMethod} · ${item.paymentStatus} · ${item.payoutStatus}',
              ),
              trailing: Text('\$${item.total.toStringAsFixed(0)}'),
            ),
          );
        }),
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
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();
    final notifications = data.notifications;
    final dateFmt = DateFormat('MMM d, h:mm a');

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              final userId = auth.currentUserId;
              if (userId != null) {
                context.read<AppDataState>().markAllNotificationsRead(userId);
              }
            },
            child: const Text('Mark all as read'),
          ),
        ),
        ...notifications.map((item) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                item.type == 'system'
                    ? Icons.auto_awesome
                    : item.read
                    ? Icons.notifications_none
                    : Icons.notifications_active,
              ),
              title: Text(item.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.body),
                  if (item.type == 'system')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text('System Notifications'),
                      ),
                    ),
                ],
              ),
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
    final data = context.watch<AppDataState>();
    final works = data.artworks
        .where((item) => item.artistId == artistId)
        .toList();
    final artistName = works.isNotEmpty
        ? works.first.artistName
        : 'Artist #$artistId';
    final avgRating = works.isEmpty
        ? 0
        : works.fold<double>(
                0,
                (runningTotal, item) => runningTotal + item.avgRating,
              ) /
              works.length;

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
            if (works.any((item) => item.artistId.isNotEmpty))
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
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(artistId)
              .snapshots(),
          builder: (context, snapshot) {
            final acceptingCommissions =
                snapshot.data?.data()?['acceptingCommissions'] as bool? ?? true;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: acceptingCommissions
                      ? () => context.push(
                            _commissionRoute(
                              artistName: artistName,
                              artistId: artistId,
                            ),
                          )
                      : null,
                  child: Text(
                    acceptingCommissions
                        ? 'Request commission'
                        : 'Commission Closed',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _sendInquiryRequest(
                    context: context,
                    auth: context.read<AuthState>(),
                    artwork: works.isNotEmpty
                        ? works.first
                        : Artwork(
                            id: artistId,
                            title: 'Portfolio inquiry',
                            artistName: artistName,
                            price: 0,
                            imageUrl: '',
                            images: const [],
                          ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message artist'),
                ),
              ],
            );
          },
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
    final data = context.watch<AppDataState>();
    final items = data.artworks.where((item) {
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
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
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
