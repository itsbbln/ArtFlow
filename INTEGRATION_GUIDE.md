# ArtFlow Authentication System - Integration & Testing Guide

## 🚀 Quick Start

### 1. File Overview
```
✅ Updated Files:
  - lib/features/screens/screens.dart (SplashScreen, GetStartedScreen, RegisterScreen, BuyerOnboardingScreen, ArtistOnboardingScreen)
  - lib/core/navigation/app_router.dart (Added /get-started route and BecomeArtistScreen import)

✅ New Files:
  - lib/features/screens/become_artist_screen.dart (Complete artist application flow)
  - AUTHENTICATION_IMPLEMENTATION.md (This documentation)
  - DESIGN_SYSTEM.md (Design guidelines)
```

---

## 🔄 Authentication Flow Walkthrough

### User Journey: New Registration

```
1. App Launch
   └─ SplashScreen (2.5s animation)
       └─ Auto-navigate to GetStartedScreen

2. GetStartedScreen
   └─ User reads about ArtFlow features
       ├─ Clicks "Create Account"
       └─ Navigate to RegisterScreen

3. RegisterScreen (Register Mode)
   └─ User fills:
       ├─ Full Name
       ├─ Email Address
       ├─ Password (6+ chars)
       ├─ Confirm Password
       └─ Agree to Terms checkbox
   └─ Click "Create Account"

4. BuyerOnboardingScreen
   └─ User selects art interests (optional but recommended)
       └─ Click "Continue to Explore"

5. HomeScreen
   └─ User can now browse artworks
   └─ Access profile and other features
```

### User Journey: Artist Application

```
1. User (Buyer) navigates to profile
   └─ User wants to become artist

2. Navigate to /become-artist route
   └─ BecomeArtistScreen (3-step form)

3. Step 1: Select Medium
   └─ User chooses primary art medium

4. Step 2: Artist Profile
   └─ User enters art style
   └─ User writes bio about their work

5. Step 3: Experience & Confirm
   └─ User describes creative background
   └─ User agrees to Artist Terms
   └─ Click "Submit Application"

6. Application Submitted
   └─ Confirmation message
   └─ Redirect to profile
   └─ (Admin review pending)
```

---

## 🧪 Testing Checklist

### Registration Flow Tests
```
✅ Valid Registration
  Input: John Doe | john@example.com | password123 | password123 | Terms checked
  Expected: Navigate to BuyerOnboardingScreen

✅ Missing Full Name
  Expected: Error: "Please enter your full name"

✅ Invalid Email
  Input: notanemail
  Expected: Error: "Please enter a valid email address"

✅ Email with valid format
  Input: john@example.com, user+tag@domain.co.uk
  Expected: Validation passes

✅ Short Password
  Input: 12345
  Expected: Error: "Password must be at least 6 characters"

✅ Mismatched Passwords
  Input: Password: pass123 | Confirm: pass456
  Expected: Error: "Passwords do not match"

✅ Terms Not Agreed
  Expected: Error: "Please agree to the Terms of Service"
```

### Login Flow Tests
```
✅ Valid Login
  Input: john@example.com | password123
  Expected: Navigate to HomeScreen

✅ Empty Email
  Expected: Error: "Please enter your email address"

✅ Empty Password
  Expected: Error: "Password must be at least 6 characters"

✅ Toggle to Register
  On Login screen, click "Create account"
  Expected: Form switches to registration mode
```

### Onboarding Tests
```
✅ Buyer Onboarding
  Select interests (e.g., 3 out of 10)
  Expected: Counter shows "3 interests selected"
  Click "Continue" → Redirect to HomeScreen

✅ Artist Onboarding
  Fill: Style + Bio
  Expected: Button enabled only when both filled
  Click "Launch Dashboard" → Redirect to /artist-dashboard

✅ Skip Onboarding
  Click "Skip this step"
  Expected: Redirect without saving preferences
```

### Artist Application Tests
```
✅ Complete Application
  Step 1: Select medium (e.g., "Digital Art")
  Step 2: Fill style (e.g., "Abstract") + bio
  Step 3: Fill experience + agree terms
  Expected: All "Next" buttons enabled
  Final: Click "Submit" → Success message + redirect to profile

✅ Incomplete Step
  Step 1: Don't select medium
  Expected: "Next" button disabled

✅ Character Counter
  Step 2: Type bio text
  Expected: Character count updates (0/500)

✅ Step Navigation
  Complete steps 1-2
  Click "Back"
  Expected: Return to previous step with data intact
```

---

## 🔧 Integration Points

### With AuthState (Provider)
```dart
// Access authentication state
final auth = context.watch<AuthState>();

// Get current user info
auth.displayName
auth.username
auth.bio
auth.style
auth.isArtist
auth.isVerifiedArtist
auth.isAdmin

// Authentication methods
auth.register(name: '', role: '', email: '')
auth.completeArtistOnboarding(style: '', bio: '')
auth.completeBuyerOnboarding(preferences: [])
auth.setAuthenticated(role: UserRole.buyer)
auth.setUnauthenticated()
```

### With GoRouter (Navigation)
```dart
// Navigate to registration
context.go('/register');

// Navigate to login
context.go('/register?mode=login');

// Navigate to artist application
context.go('/become-artist');

// Logout and return to get-started
context.read<AuthState>().setUnauthenticated();
context.go('/get-started');
```

---

## 🎨 Customization Guide

### Changing Colors
Edit `lib/core/theme/app_theme.dart`:
```dart
const primary = Color(0xFFB71B1B);      // Change primary color
const secondary = Color(0xFFE3BC2D);    // Change secondary
const background = Color(0xFFFFF6ED);   // Change background
```

### Modifying Form Fields
Edit `_FormField` in `become_artist_screen.dart` or create a shared component:
```dart
class _FormField extends StatelessWidget {
  // Customize border radius, padding, colors, etc.
}
```

### Adjusting Art Mediums
In `become_artist_screen.dart`:
```dart
static const _mediums = [
  'Your Medium Here',
  // Add/remove as needed
];
```

### Changing Animation Timings
In `screens.dart` SplashScreen:
```dart
duration: const Duration(milliseconds: 1500), // Adjust duration
curve: Curves.easeOutBack, // Change curve
```

---

## 📊 State Management Flow

### AuthState Lifecycle
```
Initialize → Check Session → 
├─ Session Valid: Authenticated ✅
└─ Session Invalid: Unauthenticated ❌

Registration Flow:
  register() → AuthState updated → setAuthenticated()
  
Onboarding:
  completeBuyerOnboarding() → Update preferences
  completeArtistOnboarding() → Update role + profile

Artist Application:
  (Same as onboarding, but with multi-step validation)
```

---

## 🐛 Troubleshooting

### Form Validation Not Working
**Issue**: Buttons disabled even with valid input
**Solution**: Check `_isStepValid()` or `_validateInputs()` logic

### Navigation Issues
**Issue**: Routes not found
**Solution**: Verify import statements in `app_router.dart`:
```dart
import '../../features/screens/become_artist_screen.dart';
```

### Theme Colors Not Applied
**Issue**: Colors don't match design
**Solution**: Verify theme is loaded in `app.dart`:
```dart
theme: AppTheme.light(),
```

### Animations Laggy
**Issue**: Splash or transitions stutter
**Solution**: Use `SingleTickerProviderStateMixin` correctly:
```dart
with SingleTickerProviderStateMixin {
  late AnimationController _controller;
}
```

---

## 📱 Testing on Devices

### Android
```bash
flutter run -d android
```

### iOS
```bash
flutter run -d ios
```

### Web (for quick testing)
```bash
flutter run -d chrome
```

### Hot Reload
```bash
r    # Hot reload
R    # Hot restart
```

---

## 📈 Future Integration Steps

### Phase 1: Backend Integration (3.0)
- [ ] Connect to real authentication API
- [ ] Implement email verification
- [ ] Add password reset functionality
- [ ] Store sessions securely

### Phase 2: Admin Features (4.0)
- [ ] Build admin verification dashboard
- [ ] Create artist approval workflow
- [ ] Add analytics and reporting

### Phase 3: Advanced Features (5.0)
- [ ] Social sign-in (Google, Facebook)
- [ ] Two-factor authentication
- [ ] Biometric login
- [ ] Account recovery

---

## 🔐 Security Notes

### Current Implementation
- Uses SharedPreferences for local storage (for mock only)
- Basic email and password validation
- In-memory session management

### Before Production
- ⚠️ Implement proper backend authentication
- ⚠️ Use secure storage (flutter_secure_storage)
- ⚠️ Implement SSL/TLS certificate pinning
- ⚠️ Add rate limiting on login attempts
- ⚠️ Implement CSRF protection
- ⚠️ Use OTP for email verification
- ⚠️ Implement proper logout (clear all cached data)

---

## 📚 Code Examples

### Custom Error Handling
```dart
void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      duration: Duration(seconds: 3),
    ),
  );
}
```

### Form Validation Pattern
```dart
bool _validateInputs() {
  if (_emailController.text.trim().isEmpty) {
    _showError('Email is required');
    return false;
  }
  if (!_isValidEmail(_emailController.text)) {
    _showError('Invalid email format');
    return false;
  }
  return true;
}
```

### Route Navigation with State
```dart
// Navigate with role-specific onboarding
if (_role == 'artist') {
  context.go('/onboarding/artist');
} else {
  context.go('/onboarding/buyer');
}
```

---

## 🎓 Learning Resources

- [Flutter Forms](https://flutter.dev/docs/cookbook/forms)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Provider Pattern](https://pub.dev/packages/provider)
- [Material Design 3](https://material.io/design)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)

---

**Document Version**: 1.0
**Framework**: Flutter 3.11+
**Dart Version**: 3.1+
**Last Updated**: April 2026

For questions or issues, refer to:
- AUTHENTICATION_IMPLEMENTATION.md (Feature overview)
- DESIGN_SYSTEM.md (Visual guidelines)
- App code comments and documentation
