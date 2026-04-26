# ArtFlow Authentication & User Account Management System

## Overview
This document outlines the complete implementation of the User Account Management Module for ArtFlow, including registration, login, artist verification, and profile management systems.

---

## 🎯 Key Features Implemented

### 1. **Authentication Flow**

#### Splash Screen → Get Started → Login/Register
- **SplashScreen** (Logo Animation Only)
  - Displays animated logo with fade and scale transitions
  - Auto-navigates to GetStartedScreen after 2.5 seconds
  - Clean, minimal design with gradient background

- **GetStartedScreen** (Fancy Entry Point)
  - Beautiful introduction with feature highlights
  - Feature cards showcasing core functionalities
  - Dual CTA buttons: "Create Account" and "Sign In"
  - Responsive design with gradient background

#### RegisterScreen (Unified Login/Register)
- **Unified Interface**: Single screen for both registration and login
- **Registration Flow**:
  - Full Name input
  - Email Address (with validation)
  - Password (min 6 characters)
  - Confirm Password (must match)
  - Terms & Conditions agreement checkbox
  - Elegant form with icons and visual hierarchy
  - Low-visibility placeholders as per design spec

- **Login Flow**:
  - Email Address
  - Password
  - Toggle between Login/Register with "Already have an account?" text
  - Clean form layout with space from top

- **Visual Design Features**:
  - Consistent color scheme (primary: #B71B1B, secondary: #E3BC2D)
  - Form fields with prefixes icons and toggle visibility for passwords
  - Gradient background (warm cream to off-white)
  - Professional typography with proper hierarchy
  - Rounded corners (12px) for modern look
  - Clear visual feedback and error states

### 2. **User Role Management**

#### Default Roles
- **Standard User (Buyer)**: Default role for all registrations
- **Verified Artist**: Obtained after artist application approval
- **Scholar Tier**: Applied with valid School ID (admin verification required)
- **Admin**: Special role for system administrators

#### Artist Application Process
Users can apply to become artists through the "Become a Verified Artist" feature:

1. **Access Point**: Available via `/become-artist` route (no ProfileScreen modifications)
2. **Three-Step Application**:
   - **Step 1 - Select Medium**: Choose primary art medium from 8 options
   - **Step 2 - Artist Profile**: Provide art style and biography
   - **Step 3 - Experience & Agreement**: Share creative background and agree to terms

3. **Application Review**:
   - Submitted applications are queued for admin review
   - Admin notification: 2-3 business days
   - Upon approval: User gets "Verified Artist" badge
   - Artist details published to portfolio

### 3. **Onboarding Screens**

#### BuyerOnboardingScreen
- Personalized experience setup
- Select art interests (10 categories: Portrait, Digital Art, Nature, Abstract, Minimalist, Fantasy, Sculpture, Photography, Installation, Mixed Media)
- Shows interest count
- Options to continue or skip
- Gradient background matching theme

#### ArtistOnboardingScreen
- Creator profile setup
- Primary art style input
- Artist bio (with character counter)
- Skip for now option
- Step indicators for clarity

### 4. **Account Management Features** (Without Modifying ProfileScreen)

#### User Data Management
- Full Name
- Email Address
- Username (auto-generated from name)
- Bio/Artist bio
- Art style and medium
- Account status indicators

#### Verified Artist Features
- Professional portfolio profile
- Artistic identity customization
- Verified Artist badge display
- Portfolio showcase with sample artworks
- Direct access to artist dashboard

#### Scholar Tier (Student Benefits)
- School ID verification requirement
- Admin approval needed
- Special tier badge
- Educational benefits and discounts

### 5. **Secure Authentication Mechanisms**

#### Password Security
- Minimum 6 characters requirement
- Confirm password validation (must match)
- Password visibility toggle
- Secure storage via SharedPreferences

#### Email Validation
- RFC-compliant regex pattern validation
- User-friendly error messages
- Case-insensitive email handling

#### Session Management
- AuthService integration for session checking
- Automatic redirect to splash screen on app launch
- Session persistence via SharedPreferences

---

## 📁 File Structure

```
lib/
├── features/
│   ├── auth/
│   │   ├── presentation/
│   │   │   └── auth_state.dart          (Authentication state management)
│   │   ├── data/
│   │   │   └── auth_service.dart        (Backend integration)
│   │   └── domain/
│   │       └── auth_status.dart         (Authentication status enum)
│   └── screens/
│       ├── screens.dart                 (Main screens including Splash, GetStarted, Register, Onboarding, Home, etc.)
│       └── become_artist_screen.dart    (NEW: Artist application flow)
├── core/
│   ├── navigation/
│   │   └── app_router.dart              (Updated routing with new flows)
│   └── theme/
│       └── app_theme.dart               (Consistent theming)
```

---

## 🛣️ Route Map

### Pre-Authentication Routes
- `/splash` - Logo animation (auto-navigates to get-started)
- `/get-started` - Entry point with feature highlights
- `/welcome` - Welcome slides for new users (optional, can skip)
- `/register` - Unified login/register screen

### Post-Registration Routes
- `/onboarding/buyer` - Buyer preference selection
- `/onboarding/artist` - Artist profile setup

### Authenticated Routes
- `/` - Home screen
- `/profile` - User profile (unchanged)
- `/become-artist` - Artist application form
- `/artist-dashboard` - Artist workspace
- `/edit-profile` - Profile editing
- Other screens (explore, artwork detail, create, etc.)

---

## 🎨 Design System Applied

### Color Palette
- **Primary**: #B71B1B (Deep Red)
- **Secondary**: #E3BC2D (Gold)
- **Background**: #FFF6ED (Warm Cream)
- **Surface**: #FFFFFF (White)
- **Foreground**: #161616 (Dark)
- **Error**: #9A1D1D

### Typography
- **Headlines**: Playfair Display (Bold, weights 600-700)
- **Body**: Inter (Regular weight 400, semibold 600)
- **Font Hierarchy**: Clear distinction between h1, h2, h3, title, body, and captions

### Component Styling
- **Border Radius**: 12px (inputs), 14px (buttons), 20px (cards)
- **Shadows**: Subtle elevation (4-12px blur)
- **Spacing**: 8px base unit with 12px, 16px, 20px, 24px increments
- **Input Fields**: 
  - 14px vertical padding, 16px horizontal
  - Light fill color with primary border on focus
  - Low-visibility placeholders (colors.black26)

---

## 📋 User Registration & Verification Flow

```
┌─────────────────┐
│  User Registers │
│  (Full Name,    │
│   Email, Pwd)   │
└────────┬────────┘
         │
         ▼
┌──────────────────────────┐
│ Default: Standard User   │
│ (Buyer Role Assigned)    │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Buyer Onboarding:        │
│ Select Art Interests     │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Can Browse & Search Art  │
│ (Limited features)       │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ User Applies to Become   │
│ Artist (/become-artist)  │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Admin Reviews:           │
│ • Art Medium             │
│ • Portfolio/Bio          │
│ • Experience             │
└────────┬─────────────────┘
         │
    ┌────┴────┐
    │          │
    ▼          ▼
 APPROVED    REJECTED
    │          │
    ▼          ▼
  Verified   Can Reapply
  Artist     (after updates)
    │
    ▼
 Badge & Portfolio
 Published
```

---

## 🔐 Security Considerations

1. **Password Handling**
   - Minimum 6 characters (consider increasing to 8+ in production)
   - Confirm password matching
   - Visual toggle for visibility (user control)

2. **Email Validation**
   - Regex pattern matches RFC 5322 standards
   - Case-insensitive handling

3. **Session Management**
   - AuthService checks existing sessions on app launch
   - Automatic redirect to login if session expired
   - SharedPreferences for local persistence

4. **Future Enhancements**
   - Implement email verification via OTP
   - Two-factor authentication
   - Secure password reset flow
   - Account recovery questions
   - Biometric authentication

---

## 🎯 Testing Scenarios

### Registration
```
Test Case 1: Valid Registration
Input: Full Name, Valid Email, Password (6+ chars), Matching Confirm Password
Expected: User created, redirected to buyer onboarding

Test Case 2: Missing Full Name
Expected: Error: "Please enter your full name"

Test Case 3: Invalid Email
Expected: Error: "Please enter a valid email address"

Test Case 4: Password < 6 chars
Expected: Error: "Password must be at least 6 characters"

Test Case 5: Mismatched Passwords
Expected: Error: "Passwords do not match"

Test Case 6: Unchecked Terms
Expected: Error: "Please agree to the Terms of Service"
```

### Login
```
Test Case 1: Valid Email & Password
Expected: User authenticated, redirected to home

Test Case 2: Empty Email
Expected: Error: "Please enter your email address"

Test Case 3: Invalid Credentials
Expected: Error message (in production, backend validation)
```

### Artist Application
```
Test Case 1: Complete Application
Input: Medium selected, Bio filled, Experience filled, Terms agreed
Expected: Application submitted, redirect to profile

Test Case 2: Skip Steps
Expected: Cannot proceed without completing required fields
```

---

## 💡 Usage Examples

### Navigate to Become Artist
```dart
context.go('/become-artist');
```

### Access Artist Dashboard (Artist Only)
```dart
context.go('/artist-dashboard');
```

### Logout & Return to Get Started
```dart
context.read<AuthState>().setUnauthenticated();
context.go('/get-started');
```

---

## 🚀 Future Enhancements

1. **Email Verification**
   - Send OTP to confirm email
   - Prevent duplicate registrations

2. **Social Sign-In**
   - Google OAuth
   - Facebook OAuth

3. **Enhanced Artist Verification**
   - Portfolio upload requirements
   - Multiple sample artworks submission
   - Social proof (followers, previous sales)

4. **Subscription Tiers**
   - Free tier for buyers
   - Artist subscription (portfolio pack, featured boost)
   - Premium features and analytics

5. **Account Security**
   - Two-factor authentication
   - Biometric login
   - Trusted device management

6. **Onboarding Customization**
   - A/B testing for different user flows
   - Personalized recommendations based on interests

---

## 📞 Support & Maintenance

### Known Limitations
- Currently uses mock authentication (no backend integration)
- Admin verification is not yet implemented in UI
- Scholar tier verification not yet implemented
- No email sending functionality

### Development Notes
- All styling follows the Material 3 design system
- Theme colors can be modified in `app_theme.dart`
- Form validation can be enhanced with custom validators
- Consider implementing proper error boundary screens

---

## ✅ Checklist

- [x] Splash screen with logo animation
- [x] Get started screen with fancy design
- [x] Unified login/register interface
- [x] Form validation and error handling
- [x] Password visibility toggle
- [x] Buyer onboarding flow
- [x] Artist onboarding flow
- [x] Become artist application form
- [x] Updated routing with new flows
- [x] Consistent theming and design
- [x] Proper visual hierarchy
- [x] Responsive design
- [x] No ProfileScreen modifications
- [x] Clean code organization

---

**Last Updated**: April 2026
**Status**: ✅ Complete & Ready for Testing
