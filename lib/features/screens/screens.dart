import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_shadows.dart';
import '../../core/theme/editorial_colors.dart';
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
import 'screen_utils.dart';
import 'widgets/empty_message_card.dart';
import 'widgets/metric_summary_card.dart';
import 'widgets/order_status_chip.dart';

export 'artist_dashboard_screen.dart';
export 'explore/explore_screen.dart';
export 'home/home_screen.dart';
export 'profile/profile_screen.dart';

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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EditorialColors.tribalMaroon,
            EditorialColors.tribalRed,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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

  void _switchAuthMode(bool toLogin) {
    if (_isLogin == toLogin) {
      return;
    }
    setState(() {
      _isLogin = toLogin;
      _fullNameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _agreeToTerms = false;
      _inlineError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final cs = Theme.of(context).colorScheme;

    Widget authModeSegments() {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: EditorialColors.parchmentDeep.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EditorialColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: _isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () => _switchAuthMode(true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Sign in',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _isLogin
                                  ? EditorialColors.tribalRed
                                  : EditorialColors.muted,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  color: !_isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () => _switchAuthMode(false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Create account',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: !_isLogin
                                  ? EditorialColors.tribalRed
                                  : EditorialColors.muted,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: EditorialColors.ink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              EditorialColors.pageCream,
              BukidnonGradients.pageAmbient.colors.last,
              EditorialColors.surfaceCream.withValues(alpha: 0.92),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                authModeSegments(),
                const SizedBox(height: 28),
                Text(
                  _isLogin ? 'Welcome back' : 'Join ArtFlow',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: EditorialColors.ink,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Sign in to browse, collect, and message artists.'
                      : 'Create an account to save favorites and checkout securely.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.45,
                    color: EditorialColors.muted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.circularXl(),
                    border: Border.all(color: EditorialColors.border),
                    boxShadow: AppShadows.raised,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isLogin) ...[
                          _FormField(
                            label: 'Full Name',
                            hint: 'Name shown on ArtFlow',
                            controller: _fullNameController,
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 18),
                        ],
                        _FormField(
                          label: 'Email',
                          hint: 'you@example.com',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),
                        _FormField(
                          label: 'Password',
                          hint: 'At least 6 characters',
                          controller: _passwordController,
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onTogglePassword: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 18),
                          _FormField(
                            label: 'Confirm password',
                            hint: 'Repeat your password',
                            controller: _confirmPasswordController,
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onTogglePassword: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _agreeToTerms,
                            activeColor: cs.primary,
                            onChanged: (val) {
                              setState(() {
                                _agreeToTerms = val ?? false;
                                _inlineError = null;
                              });
                            },
                            title: RichText(
                              text: TextSpan(
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: EditorialColors.charcoal.withValues(alpha: 0.75)),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (_inlineError != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: cs.errorContainer
                                  .withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.error.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: cs.error,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _inlineError!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: cs.onErrorContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: auth.status == AuthStatus.checking
                                ? null
                                : _handleEmailPasswordAuth,
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: auth.status == AuthStatus.checking
                                ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: cs.onPrimary,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Continue' : 'Create account',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: EditorialColors.border,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'or continue with',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: EditorialColors.muted,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: EditorialColors.border,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: auth.status == AuthStatus.checking
                        ? null
                        : _handleGoogleAuth,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: EditorialColors.charcoal,
                      side: BorderSide(color: EditorialColors.border),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: auth.status == AuthStatus.checking
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: EditorialColors.tribalRed,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      EditorialColors.parchmentDeep.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isLogin ? 'Google' : 'Google sign-up',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _isLogin
                        ? 'Uses your Google email — same privacy as email sign-in.'
                        : 'We use your Google email as your ArtFlow login.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.4,
                      color: EditorialColors.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    context.read<AuthState>().setAuthenticated(
                          role: UserRole.buyer,
                        );
                    context.go('/');
                  },
                  child: Text(
                    'Browse as guest',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: EditorialColors.muted,
                    ),
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
              label: Text(categoryLabel(artwork.category)),
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
                                  buildCommissionRoute(
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
                                buildCommissionRoute(
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
                    child: Text(categoryLabel(item)),
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
                    child: Text(categoryLabel(item)),
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
                'Market Comparison\nAverage price for ${categoryLabel(_category).toLowerCase()}: ${currency.format(_result!.averageMarketPrice)}',
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
  final _pinnedController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _profilePhotoBytes;
  String _profilePhotoExtension = 'jpg';
  bool _portfolioPack = false;
  bool _featuredBoost = false;
  bool _acceptingCommissions = true;
  bool _introExpanded = true;
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

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: hint != null,
      border: const OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: EditorialColors.tribalRed.withValues(alpha: 0.95)),
      ),
      floatingLabelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: EditorialColors.tribalRed,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _pinnedController.dispose();
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
      _pinnedController.text = auth.pinnedDetails.join('\n');
      _profileLoaded = true;
    }

    final topPadding = MediaQuery.paddingOf(context).top;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: BukidnonGradients.pageAmbient),
      child: ListView(
        padding: EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 200 + topPadding,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 154 + topPadding,
                  width: double.infinity,
                  padding: EdgeInsets.only(top: topPadding),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        EditorialColors.tribalRed,
                        EditorialColors.tribalMaroon,
                        Color(0xFFE85C4A),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white.withValues(alpha: 0.95)),
                        tooltip: 'Back',
                      ),
                      Expanded(
                        child: Text(
                          'Edit profile',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 44,
                  child: Hero(
                    tag: 'profile_avatar_${auth.currentUserId ?? 'me'}',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: EditorialColors.surfaceCream,
                            child: _profilePhotoBytes != null
                                ? ClipOval(
                                    child: Image.memory(
                                      _profilePhotoBytes!,
                                      width: 88,
                                      height: 88,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : auth.photoUrl.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      auth.photoUrl,
                                      width: 88,
                                      height: 88,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.person_outline, size: 38),
                                    ),
                                  )
                                : const Icon(Icons.person_outline, size: 38),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Material(
                              color: EditorialColors.tribalRed,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _showPhotoSourceOptions,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.photo_camera_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 114,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.92),
                      foregroundColor: EditorialColors.muted,
                    ),
                    onPressed: _showPhotoSourceOptions,
                    icon: const Icon(Icons.camera_alt_outlined, size: 22),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _showPhotoSourceOptions,
                icon: Icon(Icons.upload_outlined, size: 18, color: EditorialColors.tribalRed),
                label: Text(
                  'Change profile photo',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: EditorialColors.tribalRed,
                  ),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: EditorialColors.border.withValues(alpha: 0.85)),
          InkWell(
            onTap: () => setState(() => _introExpanded = !_introExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Intro',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: EditorialColors.ink,
                      ),
                    ),
                  ),
                  Icon(
                    _introExpanded ? Icons.expand_less : Icons.expand_more,
                    color: EditorialColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_introExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Icon(Icons.waving_hand_outlined, color: EditorialColors.muted),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _bioController,
                          maxLines: 5,
                          style: GoogleFonts.inter(color: EditorialColors.charcoal, height: 1.45),
                          decoration: _fieldDecoration(
                            'Bio',
                            hint: 'What should people know about you?',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Icon(Icons.push_pin_outlined, color: EditorialColors.tribalRed),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _pinnedController,
                          maxLines: 8,
                          style: GoogleFonts.inter(color: EditorialColors.charcoal, height: 1.45),
                          decoration: _fieldDecoration(
                            'Pinned to profile',
                            hint:
                                'One line each — schools, exhibits, organizations, links…',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: Text(
              'Account',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: EditorialColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: TextField(
              controller: _nameController,
              style: GoogleFonts.inter(color: EditorialColors.charcoal),
              decoration: _fieldDecoration('Name'),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: TextField(
              controller: _usernameController,
              style: GoogleFonts.inter(color: EditorialColors.charcoal),
              decoration: _fieldDecoration('Username'),
            ),
          ),
          const SizedBox(height: 12),
          if (auth.isArtist || auth.isAdmin)
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18),
              value: _acceptingCommissions,
              title: Text('Accept commissions', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text(
                'Turn this off to disable commission requests on your artworks.',
                style: GoogleFonts.inter(fontSize: 13, color: EditorialColors.muted),
              ),
              activeThumbColor: EditorialColors.tribalRed,
              onChanged: (value) {
                setState(() {
                  _acceptingCommissions = value;
                });
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                auth.isVerifiedArtist ? Icons.verified : Icons.verified_outlined,
                color: auth.isVerifiedArtist ? EditorialColors.gold : EditorialColors.muted,
              ),
              title: Text('Artist verification', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text(
                auth.isVerifiedArtist
                    ? 'Verified through the admin review flow.'
                    : 'Managed through the artist application review process.',
                style: GoogleFonts.inter(fontSize: 13, color: EditorialColors.muted),
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18),
            value: _portfolioPack,
            title: Text('Extended Portfolio Pack', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('PHP 99 unlock', style: GoogleFonts.inter(fontSize: 13, color: EditorialColors.muted)),
            activeThumbColor: EditorialColors.tribalRed,
            onChanged: (value) => setState(() => _portfolioPack = value),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18),
            value: _featuredBoost,
            title: Text('Featured Artwork Boost', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('PHP 20/day', style: GoogleFonts.inter(fontSize: 13, color: EditorialColors.muted)),
            activeThumbColor: EditorialColors.tribalRed,
            onChanged: (value) => setState(() => _featuredBoost = value),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: EditorialColors.tribalRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
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
                          pinnedDetails: _pinnedController.text
                              .split(RegExp(r'\r?\n'))
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList(),
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
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Save changes', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
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
    senderId: chatUserIdFor(auth),
    senderName: auth.displayName,
    senderRole: roleLabel(auth),
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
    currentUserRole: roleLabel(auth),
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
    return ColoredBox(
      color: EditorialColors.pageCream,
      child: Stack(
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

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: AppRadii.circularLg(),
                      onTap: () =>
                          context.push(_chatRoute(item.conversationId, contact)),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadii.circularLg(),
                          border: Border.all(color: EditorialColors.border),
                          boxShadow: AppShadows.card,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: EditorialColors.tribalRed
                                  .withValues(alpha: 0.12),
                              foregroundColor: EditorialColors.tribalRed,
                              child: Text(item.initial),
                            ),
                            title: Text(
                              item.otherName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      statusByConversation[
                                          item.conversationId]!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
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
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            elevation: 2,
            onPressed: () => _showNewMessageSheet(context),
            icon: const Icon(Icons.edit_rounded),
            label: Text('New', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
      ),
    );
  }
}

bool _calendarSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Widget _chatDateChip(DateTime sentAt) {
  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);
  final day = DateTime(sentAt.year, sentAt.month, sentAt.day);
  late final String label;
  if (day == startOfToday) {
    label = 'Today';
  } else if (day ==
      startOfToday.subtract(const Duration(days: 1))) {
    label = 'Yesterday';
  } else if (startOfToday.difference(day).inDays < 364) {
    label = DateFormat('EEEE · MMMM d').format(sentAt);
  } else {
    label = DateFormat('EEEE · MMM d, yyyy').format(sentAt);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    decoration: BoxDecoration(
      color: EditorialColors.surfaceCream.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(999),
      border:
          Border.all(color: EditorialColors.border.withValues(alpha: 0.88)),
      boxShadow: AppShadows.card,
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: EditorialColors.muted.withValues(alpha: 0.95),
      ),
    ),
  );
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

    return ColoredBox(
      color: EditorialColors.pageCream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.white,
            elevation: 1,
            shadowColor: EditorialColors.border.withValues(alpha: 0.55),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          EditorialColors.tribalGold.withValues(alpha: 0.9),
                          EditorialColors.tribalRed.withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: AppShadows.card,
                    ),
                    padding: const EdgeInsets.all(3),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      child: Text(
                        chatInitial,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: EditorialColors.tribalMaroon,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chatName,
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            height: 1.1,
                            color: EditorialColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (participant != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: EditorialColors.blush.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color:
                                        EditorialColors.tribalRed.withValues(alpha: 0.22),
                                  ),
                                ),
                                  child: Text(
                                    participant.role.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.95,
                                    color: EditorialColors.tribalRed,
                                  ),
                                ),
                              ),
                            if (relatedCommission != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: EditorialColors.amberHighlight.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color:
                                        EditorialColors.border.withValues(alpha: 0.75),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.palette_outlined,
                                      size: 14,
                                      color: EditorialColors.goldSoft.withValues(alpha: 0.95),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Commission • ${relatedCommission.status}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: EditorialColors.charcoal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    EditorialColors.tribalCream.withValues(alpha: 0.52),
                    EditorialColors.pageCream,
                    Colors.white.withValues(alpha: 0.97),
                  ],
                ),
              ),
              child: StreamBuilder<List<ChatMessage>>(
                stream: _chatService.watchMessages(widget.conversationId),
                builder: (context, snapshot) {
                  final messages = snapshot.data ?? const <ChatMessage>[];
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _markRead();
                  });

                  if (messages.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  EditorialColors.tribalRed.withValues(alpha: 0.08),
                              border: Border.all(
                                color:
                                    EditorialColors.tribalRed.withValues(alpha: 0.15),
                              ),
                              boxShadow: AppShadows.card,
                            ),
                            child: Icon(
                              Icons.auto_awesome_mosaic_rounded,
                              size: 48,
                              color: EditorialColors.tribalRed.withValues(alpha: 0.92),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'No messages yet',
                            style: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.w800,
                              fontSize: 23,
                              color: EditorialColors.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Drop a greeting, paste a Pinterest board link, '
                            'or clarify what you\'d love to commission — everything '
                            'stays inside this encrypted thread.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.55,
                              color: EditorialColors.muted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final maxBubble = MediaQuery.sizeOf(context).width * 0.78;

                  return ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final item = messages[index];
                      final prev = index > 0 ? messages[index - 1] : null;
                      final showDayChip = prev == null ||
                          !_calendarSameDay(item.sentAt, prev.sentAt);

                      if (item.isSystemNotification) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: 12,
                            top: index == 0 ? 4 : (showDayChip ? 6 : 0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDayChip)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child:
                                      Center(child: _chatDateChip(item.sentAt)),
                                ),
                              Center(
                                child: Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 320),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: EditorialColors.border
                                          .withValues(alpha: 0.85),
                                    ),
                                    boxShadow: AppShadows.card,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 18,
                                        color:
                                            EditorialColors.tribalGold.withValues(alpha: 0.92),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item.text,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            height: 1.45,
                                            fontWeight: FontWeight.w600,
                                            color: EditorialColors.charcoal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final mine = item.senderId == currentUserId;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: mine ? 4 : 6,
                          top: index == 0
                              ? 2
                              : (showDayChip ? 14 : (mine ? 2 : 4)),
                        ),
                        child: Column(
                          crossAxisAlignment: mine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (showDayChip)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child:
                                    Center(child: _chatDateChip(item.sentAt)),
                              ),
                            Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: maxBubble),
                                child: Column(
                                  crossAxisAlignment: mine
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        boxShadow: AppShadows.card,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(20),
                                          topRight: const Radius.circular(20),
                                          bottomLeft: Radius.circular(mine ? 20 : 5),
                                          bottomRight: Radius.circular(mine ? 5 : 20),
                                        ),
                                        gradient: mine
                                            ? LinearGradient(
                                                colors: [
                                                  EditorialColors.tribalRed,
                                                  EditorialColors.tribalMaroon,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        color: mine
                                            ? null
                                            : Colors.white,
                                        border: mine
                                            ? null
                                            : Border.all(
                                                color: EditorialColors.border
                                                    .withValues(alpha: 0.9),
                                              ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 11,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (!mine) ...[
                                              Text(
                                                item.senderName,
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                  color:
                                                      EditorialColors.tribalMaroon,
                                                  letterSpacing: 0.35,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                item.senderRole,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: EditorialColors.muted,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                            ],
                                            Text(
                                              item.text,
                                              style: GoogleFonts.inter(
                                                fontSize: 14.8,
                                                height: 1.48,
                                                fontWeight: FontWeight.w500,
                                                color: mine
                                                    ? Colors.white
                                                    : EditorialColors.charcoal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5, left: 4, right: 4),
                                      child: Text(
                                        DateFormat('h:mm a').format(item.sentAt),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              EditorialColors.muted.withValues(alpha: 0.88),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        if (auth.isArtist &&
            relatedCommission != null &&
            relatedCommission.isOngoing)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color:
                      EditorialColors.tribalRed.withValues(alpha: 0.090),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color:
                        EditorialColors.tribalGold.withValues(alpha: 0.52),
                  ),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 18,
                      color: EditorialColors.tribalMaroon,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Reminder: send your client a quick progress ping for this commission.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          height: 1.35,
                          color: EditorialColors.tribalMaroon,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Material(
          color: Colors.white,
          elevation: 8,
          shadowColor: EditorialColors.border.withValues(alpha: 0.45),
          child: SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(14, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 6,
                      textCapitalization:
                          TextCapitalization.sentences,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.45,
                        color: EditorialColors.charcoal,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            participant == null ? 'Loading…' : 'Message ${chatName}…',
                        hintStyle: GoogleFonts.inter(
                          color:
                              EditorialColors.muted.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor:
                            EditorialColors.parchment.withValues(alpha: 0.92),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide:
                              BorderSide(color: EditorialColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide:
                              BorderSide(color: EditorialColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            color:
                                EditorialColors.tribalRed.withValues(alpha: 0.92),
                            width: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Tooltip(
                    message: 'Send',
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: participant == null
                            ? null
                            : LinearGradient(
                                colors: [
                                  EditorialColors.tribalRed,
                                  EditorialColors.tribalMaroon,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        color:
                            participant == null ? EditorialColors.border : null,
                        boxShadow: participant == null ? null : AppShadows.softGlow,
                      ),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: IconButton(
                          splashRadius: 24,
                          onPressed: participant == null
                              ? null
                              : () async {
                                  final text = _messageController.text.trim();
                                  if (text.isEmpty) {
                                    return;
                                  }
                                  await _chatService.sendMessage(
                                    conversationId: widget.conversationId,
                                    senderId: currentUserId,
                                    senderName: auth.displayName,
                                    senderRole: roleLabel(auth),
                                    recipient: participant,
                                    text: text,
                                  );
                                  await _markRead();
                                  _messageController.clear();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  FocusScope.of(context).unfocus();
                                },
                          icon: Icon(
                            Icons.send_rounded,
                            color: participant == null
                                ? EditorialColors.muted
                                : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
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
                clientId: chatUserIdFor(auth),
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
                senderId: chatUserIdFor(auth),
                senderName: auth.displayName,
                senderRole: roleLabel(auth),
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
    final userId = chatUserIdFor(auth);
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
          const EmptyMessageCard(
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
                    trailing: orderStatusChip(item.status),
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
    final actorId = chatUserIdFor(auth);
    final artistView = auth.isArtist || auth.isAdmin;
    final orders = data.orders.where((item) {
      return artistView
          ? item.artistId == actorId || item.artistName == auth.displayName
          : item.buyerId == actorId || item.buyerName == auth.displayName;
    }).toList();

    return ColoredBox(
      color: EditorialColors.pageCream,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            artistView ? 'Sales & payouts' : 'Your orders',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: EditorialColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            artistView
                ? 'Track buyer orders and fulfilment.'
                : 'Purchases and delivery status at a glance.',
            style: GoogleFonts.inter(fontSize: 13.5, color: EditorialColors.muted),
          ),
          const SizedBox(height: 18),
          if (orders.isEmpty)
            const EmptyMessageCard(
              title: 'No orders yet',
              subtitle: 'Completed purchases and sales will appear here.',
            ),
          ...orders.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadii.circularLg(),
                  border: Border.all(color: EditorialColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.artworkTitle.isEmpty
                              ? 'Order #${item.id}'
                              : item.artworkTitle,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            artistView
                                ? '${item.buyerName.isEmpty ? 'Buyer order' : item.buyerName} · ${item.paymentMethod}'
                                : '${item.artistName.isEmpty ? 'Artist order' : item.artistName} · ${item.paymentMethod}',
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${item.total.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: EditorialColors.tribalRed,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.status,
                              style: GoogleFonts.inter(fontSize: 11.5, color: EditorialColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          orderStatusChip(item.paymentStatus),
                          orderStatusChip(item.payoutStatus),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (!artistView && item.status.toLowerCase() != 'completed')
                            OutlinedButton(
                              onPressed: () {
                                final nextStatus = item.status.toLowerCase() == 'pending'
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
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                item.status.toLowerCase() == 'delivered'
                                    ? 'Confirm receipt'
                                    : 'Advance order',
                              ),
                            ),
                          if (!artistView && item.status.toLowerCase() == 'completed')
                            OutlinedButton(
                              onPressed: () async {
                                await _rateArtist(context, item.artistName);
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Rate artist'),
                            ),
                          if (artistView && item.status.toLowerCase() != 'completed')
                            FilledButton(
                              onPressed: () {
                                final nextStatus = item.status.toLowerCase() == 'pending'
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
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Mark ${item.status == 'Delivered' ? 'Completed' : 'Next Step'}',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final data = context.watch<AppDataState>();
    final actorId = chatUserIdFor(auth);
    final artistView = auth.isArtist || auth.isAdmin;
    final orders = data.orders.where((item) {
      return artistView
          ? item.artistId == actorId || item.artistName == auth.displayName
          : item.buyerId == actorId || item.buyerName == auth.displayName;
    }).toList();
    final gross = orders.fold<double>(0, (sum, item) => sum + item.total);
    final fees = gross * 0.1;
    final net = gross - fees;

    return ColoredBox(
      color: EditorialColors.pageCream,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
        children: [
          Text(
            artistView ? 'Wallet & payouts' : 'Payments',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: EditorialColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            artistView
                ? 'Earnings overview and payout simulation.'
                : 'Checkout methods and spending summary.',
            style: GoogleFonts.inter(fontSize: 13.5, color: EditorialColors.muted),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 360;
              Widget metricWrap({required List<Widget> kids}) {
                if (!wide) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: kids,
                  );
                }
                return Row(
                  children: [
                    for (var i = 0; i < kids.length; i++) ...[
                      Expanded(child: kids[i]),
                      if (i < kids.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                );
              }

              return metricWrap(
                kids: [
                  MetricSummaryCard(
                    label: artistView ? 'Gross sales' : 'Total paid',
                    value: '\$${gross.toStringAsFixed(0)}',
                  ),
                  MetricSummaryCard(
                    label: 'Platform fees',
                    value: '\$${fees.toStringAsFixed(0)}',
                  ),
                  MetricSummaryCard(
                    label: artistView ? 'Net income' : 'Escrow held',
                    value: '\$${net.toStringAsFixed(0)}',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.circularLg(),
              border: Border.all(color: EditorialColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artistView ? 'Withdrawal options' : 'Payment methods',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: EditorialColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: Icon(Icons.account_balance_wallet_rounded, size: 18, color: EditorialColors.tribalRed),
                        label: const Text('GCash'),
                        side: BorderSide(color: EditorialColors.border),
                        backgroundColor: EditorialColors.parchment,
                      ),
                      Chip(
                        avatar: Icon(Icons.payment_rounded, size: 18, color: EditorialColors.tribalRed),
                        label: const Text('Maya'),
                        side: BorderSide(color: EditorialColors.border),
                        backgroundColor: EditorialColors.parchment,
                      ),
                      Chip(
                        avatar: Icon(Icons.account_balance_rounded, size: 18, color: EditorialColors.tribalRed),
                        label: const Text('Bank transfer'),
                        side: BorderSide(color: EditorialColors.border),
                        backgroundColor: EditorialColors.parchment,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    artistView
                        ? 'Payouts stay pending until orders complete and escrow releases.'
                        : 'Buyer payments show as held until you confirm delivery.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.45,
                      color: EditorialColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Transaction history',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: EditorialColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            const EmptyMessageCard(
              title: 'No payment activity yet',
              subtitle: 'Completed transactions will appear here.',
            ),
          ...orders.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadii.circularLg(),
                  border: Border.all(color: EditorialColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  title: Text(
                    item.artworkTitle.isEmpty ? 'Order #${item.id}' : item.artworkTitle,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${item.paymentMethod} · ${item.paymentStatus} · ${item.payoutStatus}',
                    style: GoogleFonts.inter(fontSize: 12, color: EditorialColors.muted),
                  ),
                  trailing: Text(
                    '\$${item.total.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: EditorialColors.tribalRed,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
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

  static const _divider = Color(0xFFCED0D4);

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  /// Prefers new `pinnedDetails`; falls back to legacy exhibit/org lists.
  static List<String> _pinnedLines(Map<String, dynamic>? data) {
    if (data == null) {
      return [];
    }
    final pins = _stringList(data['pinnedDetails']);
    if (pins.isNotEmpty) {
      return pins;
    }
    return [
      ..._stringList(data['exhibitHighlights']),
      ..._stringList(data['memberOrganizations']),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppDataState>();
    final auth = context.watch<AuthState>();
    final works = data.artworks.where((item) => item.artistId == artistId).toList();
    final artistName = works.isNotEmpty ? works.first.artistName : 'Artist';
    final avgRating = works.isEmpty
        ? 0.0
        : works.fold<double>(0, (t, item) => t + item.avgRating) / works.length;
    final postsCount = works.length;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: BukidnonGradients.pageAmbient),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(artistId).snapshots(),
        builder: (context, userSnap) {
          final u = userSnap.data?.data();
          final displayName = (u?['displayName'] as String?)?.trim();
          final name = (displayName != null && displayName.isNotEmpty) ? displayName : artistName;
          final username = (u?['username'] as String?)?.trim() ?? '';
          final photo = (u?['photoUrl'] as String?)?.trim() ?? '';
          final bio = (u?['bio'] as String?)?.trim() ?? '';
          final followers = (u?['followersCount'] as num?)?.toInt() ?? 0;
          final following = (u?['followingCount'] as num?)?.toInt() ?? 0;
          final pinned = ArtistProfileScreen._pinnedLines(u);
          final acceptingCommissions = u?['acceptingCommissions'] as bool? ?? true;
          final verified = u?['isVerified'] as bool? ?? false;

          final viewerId = auth.currentUserId;
          final isSelf = viewerId != null && viewerId == artistId;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              SizedBox(
                height: 210,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 132,
                        decoration: BoxDecoration(
                          gradient: BukidnonGradients.profileHero,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppShadows.card,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      child: Hero(
                        tag: 'profile_avatar_$artistId',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: AppShadows.card,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: EditorialColors.surfaceCream,
                            backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                            child: photo.isEmpty
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: GoogleFonts.inter(
                                      fontSize: 38,
                                      fontWeight: FontWeight.w700,
                                      color: EditorialColors.charcoal,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              if (username.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  username,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppShadows.card,
                  border: Border.all(color: _divider.withValues(alpha: 0.85)),
                ),
                child: Row(
                  children: [
                    Expanded(child: _PubStat(value: '$postsCount', label: 'Posts')),
                    SizedBox(
                      height: 34,
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: _divider,
                      ),
                    ),
                    Expanded(child: _PubStat(value: '$followers', label: 'Followers')),
                    SizedBox(
                      height: 34,
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: _divider,
                      ),
                    ),
                    Expanded(child: _PubStat(value: '$following', label: 'Following')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (verified)
                Center(
                  child: Chip(
                    avatar: const Icon(Icons.verified, size: 16, color: Color(0xFF1877F2)),
                    label: const Text('Verified artist'),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (avgRating > 0) ...[
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Rating · ${avgRating.toStringAsFixed(1)}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (!isSelf && viewerId != null)
                    StreamBuilder<bool>(
                      stream: auth.watchFollowingArtist(artistId),
                      builder: (context, fo) {
                        final followingArtist = fo.data ?? false;
                        if (followingArtist) {
                          return OutlinedButton(
                            onPressed: () async {
                              try {
                                await auth.unfollowArtist(artistId);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not unfollow')),
                                  );
                                }
                              }
                            },
                            child: const Text('Following'),
                          );
                        }
                        return FilledButton(
                          onPressed: () async {
                            try {
                              await auth.followArtist(artistId);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not follow')),
                                );
                              }
                            }
                          },
                          child: const Text('Follow'),
                        );
                      },
                    )
                  else if (!isSelf && viewerId == null)
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Sign in to follow'),
                    ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          EditorialColors.tribalGold.withValues(alpha: 0.24),
                      foregroundColor: EditorialColors.tribalMaroon,
                    ),
                    onPressed: acceptingCommissions
                        ? () => context.push(
                              buildCommissionRoute(
                                artistName: name,
                                artistId: artistId,
                              ),
                            )
                        : null,
                    child: Text(
                      acceptingCommissions ? 'Request commission' : 'Commissions closed',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _sendInquiryRequest(
                      context: context,
                      auth: auth,
                      artwork: works.isNotEmpty
                          ? works.first
                          : Artwork(
                              id: artistId,
                              title: 'Portfolio inquiry',
                              artistName: name,
                              price: 0,
                              imageUrl: '',
                              images: const [],
                            ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message'),
                  ),
                ],
              ),
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: EditorialColors.tribalCream.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _divider.withValues(alpha: 0.82)),
                    boxShadow: AppShadows.card,
                  ),
                  child: Text(
                    bio,
                    style: GoogleFonts.inter(fontSize: 15, height: 1.45, color: EditorialColors.charcoal),
                  ),
                ),
              ],
              if (pinned.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: _divider.withValues(alpha: 0.82)),
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withValues(alpha: 0.93),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pinned',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: EditorialColors.ink),
                      ),
                      const SizedBox(height: 10),
                      ...pinned.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.push_pin_outlined, size: 18, color: EditorialColors.tribalRed.withValues(alpha: 0.95)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(line, style: GoogleFonts.inter(fontSize: 15, height: 1.4))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const Text(
                'Works',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 10),
              ...works.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ArtworkCard(
                    artwork: item,
                    onTap: () => context.push('/artwork/${item.id}'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PubStat extends StatelessWidget {
  const _PubStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
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

