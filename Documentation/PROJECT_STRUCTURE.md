# ArtFlow Project Structure and System Overview

## Purpose

This document describes the current structure of the ArtFlow Flutter project as it exists in the repository today. It is intended to help contributors understand:

- how the application is organized
- how users move through the app
- where business logic lives
- how Firebase is used
- which areas are stable and which areas still need cleanup

This reflects the current codebase state on April 29, 2026.

---

## 1. Project Summary

ArtFlow is a Flutter application for an art marketplace/community experience with three primary user perspectives:

- Buyer
- Artist
- Admin

Core product capabilities currently present in the codebase include:

- authentication with email/password and Google Sign-In
- buyer and artist onboarding
- artist verification application flow
- artwork listing and browsing
- commissions and orders
- notifications
- chat/messaging
- admin dashboard and moderation tools

The app targets multiple platforms through Flutter:

- Android
- iOS
- Web
- Windows
- macOS
- Linux

---

## 2. Top-Level Repository Structure

```text
Art Flow/
|-- android/
|-- ios/
|-- linux/
|-- macos/
|-- web/
|-- windows/
|-- assets/
|-- Documentation/
|-- lib/
|-- test/
|-- .env
|-- .env.example
|-- .gitignore
|-- firestore.rules
|-- pubspec.yaml
|-- pubspec.lock
|-- README.md
|-- various implementation/design markdown docs
```

### Important top-level folders

`assets/`
- Static assets such as logos and app images.

`Documentation/`
- Long-form documentation. Currently contains a PDF and this project structure document.

`lib/`
- The main Flutter/Dart application source code.

`test/`
- Flutter tests. Right now this area is small compared with the main app size.

### Important top-level files

`pubspec.yaml`
- Declares Flutter dependencies, assets, and app metadata.

`firestore.rules`
- Firestore security rules for users, artworks, commissions, orders, notifications, reviews, and admin-only collections.

`.env` and `.env.example`
- Environment/local secret placeholders. `.env` is ignored by Git.

---

## 3. Dependency Snapshot

The main runtime dependencies in `pubspec.yaml` currently include:

- `flutter`
- `go_router`
- `provider`
- `intl`
- `google_fonts`
- `image_picker`
- `shared_preferences`
- `flutter_dotenv`
- `supabase_flutter`
- `firebase_core`
- `cloud_firestore`
- `firebase_auth`
- `firebase_database`
- `google_sign_in`

### What they are used for

`go_router`
- Route definition, redirects, and protected navigation flow.

`provider`
- App-wide state exposure for authentication and shared data.

`firebase_auth`
- Login, registration, and current-user session management.

`cloud_firestore`
- Main application data store for users, artworks, commissions, orders, reviews, notifications, and artist applications.

`firebase_database`
- Realtime chat/messaging backend.

`shared_preferences`
- Lightweight local persistence, currently used for welcome/onboarding completion state.

`flutter_dotenv`
- Loads local environment values from `.env`.

`supabase_flutter`
- Initializes Supabase and powers image uploads for profile and artwork media.

---

## 4. Source Code Structure Under `lib/`

```text
lib/
|-- main.dart
|-- app.dart
|-- core/
|   |-- navigation/
|   |-- theme/
|   |-- widgets/
|-- features/
|   |-- admin/
|   |-- artworks/
|   |-- auth/
|   |-- chat/
|   |-- entities/
|   |-- payments/
|   |-- screens/
|   |-- shared/
```

### `main.dart`

Application entry point.

Responsibilities:

- attempts to load `.env`
- initializes Flutter bindings
- attempts `Firebase.initializeApp()`
- optionally initializes Supabase when environment values are present
- starts the app with `ArtflowApp`

Behavior note:
- if Firebase initialization fails, the app prints a debug message and still runs

### `app.dart`

Top-level app composition.

Responsibilities:

- creates `AuthState`
- creates `AppDataState`
- initializes both state objects
- wires them into `Provider`
- creates the shared router
- applies the global theme

This is the app composition root.

---

## 5. Core Layer

### `lib/core/navigation/app_router.dart`

Defines the `GoRouter` configuration.

Responsibilities:

- sets `initialLocation`
- handles auth-based redirects
- distinguishes buyer, artist, and admin access
- wraps most routes inside a shared shell scaffold

Important route behavior:

- unauthenticated users are kept within welcome/register/onboarding flows
- admins are redirected to `/admin`
- verified artists can access upload/create routes
- users with pending artist verification can access `/verification`

### `lib/core/theme/app_theme.dart`

Defines the design system baseline for the app.

Current visual direction:

- warm cream background
- deep red primary color
- gold secondary color
- `Playfair Display` headings
- `Inter` body text

### `lib/core/widgets/app_scaffold.dart`

Shared app shell used for most non-auth routes.

Responsibilities:

- top app bar area
- notification shortcut and unread badge
- end drawer navigation
- bottom navigation
- role-based menu changes
- pending artist application banner

This is the main structural wrapper for in-app navigation.

---

## 6. Feature Layer Breakdown

## 6.1 Authentication

Location:

```text
lib/features/auth/
|-- data/
|   |-- auth_service.dart
|-- domain/
|   |-- artist_application.dart
|   |-- auth_status.dart
|-- presentation/
|   |-- auth_state.dart
```

### `auth_service.dart`

This is the low-level authentication/data access service for auth-related operations.

Responsibilities:

- email/password registration
- email/password login
- Google Sign-In
- sign out
- initial user document creation in Firestore
- admin role bootstrapping for specific admin emails
- artist application submission
- profile updates
- approval/rejection helper access for verification flows

### `auth_state.dart`

This is the app-facing authentication state object and one of the most important classes in the app.

Responsibilities:

- tracks authentication status
- tracks user role
- stores current profile details
- listens to Firestore user document changes
- listens to the current artist application record
- exposes helper booleans such as:
  - `isAdmin`
  - `isArtist`
  - `isVerifiedArtist`
  - `hasPendingArtistApplication`
- supports login, registration, Google auth, logout, onboarding completion, and verification submission

### Auth data model highlights

The auth layer currently treats these concepts as central:

- `buyer`
- `artist`
- `admin`
- artist verification status
- scholar verification status
- onboarding/welcome completion

---

## 6.2 Shared App Data

Location:

```text
lib/features/shared/
|-- data/
|   |-- api_client.dart
|   |-- app_data_service.dart
|   |-- app_data_state.dart
|   |-- supabase_image_service.dart
|-- presentation/widgets/
|   |-- loading_spinner.dart
|-- widgets/
|   |-- artwork_card.dart
```

### `app_data_service.dart`

This is the main Firestore service layer for non-auth application data.

Responsibilities:

- artworks CRUD and counters
- commissions CRUD/status
- orders CRUD/status
- notifications create/read
- reviews create/read
- artist ratings aggregation
- chat contact lookup from users collection
- conversation status mapping for UI

Collections used by this service:

- `artworks`
- `commissions`
- `orders`
- `transactions`
- `notifications`
- `reviews`
- `users`

### `app_data_state.dart`

This is the app-wide reactive state wrapper around `app_data_service.dart`.

Responsibilities:

- subscribes to artwork stream globally
- binds commissions/orders/notifications for the current user
- exposes app data to UI via `Provider`
- provides convenience methods for writing data

This object acts as the shared domain store for most app screens.

### `supabase_image_service.dart`

This service uploads public image files to Supabase Storage.

Current uses:

- profile photo uploads
- artwork image uploads
- artist application portfolio uploads
- artist identity verification uploads
- scholar verification uploads

Behavior note:
- image uploads only work after valid Supabase credentials are added to `.env`
- if Supabase is not configured, the related UI shows a clear warning instead of crashing

---

## 6.3 Chat

Location:

```text
lib/features/chat/
|-- data/
|   |-- chat_service.dart
|-- domain/
|   |-- chat_models.dart
```

### `chat_service.dart`

Chat uses Firebase Realtime Database instead of Firestore.

Responsibilities:

- create or ensure conversations exist
- watch conversation lists
- watch messages in real time
- resolve the other chat participant
- send messages
- mark threads as read

Realtime Database paths used:

- `chat_threads`
- `chat_messages`
- `chat_user_threads`

This separation makes sense because messaging benefits from a realtime event-driven model.

---

## 6.4 Admin

Location:

```text
lib/features/admin/
|-- admin.dart
|-- data/repositories/
|   |-- admin_repository.dart
|-- domain/models/
|   |-- admin_models.dart
|-- presentation/
|   |-- admin_scaffold.dart
|   |-- screens/
|   |   |-- admin_dashboard_screen.dart
|   |   |-- admin_profile_screen.dart
|   |   |-- analytics_screen.dart
|   |   |-- artist_verification_screen.dart
|   |   |-- artwork_moderation_screen.dart
|   |   |-- dispute_management_screen.dart
|   |   |-- platform_settings_screen.dart
|   |   |-- transaction_monitoring_screen.dart
|   |   |-- user_management_screen.dart
|   |-- widgets/
|       |-- admin_widgets.dart
```

### `admin_repository.dart`

This is the main data layer for admin functionality.

Responsibilities:

- platform statistics
- pending artist verification count
- user listing and status management
- artist application approval/rejection
- artwork moderation actions
- transactions monitoring
- disputes management
- analytics aggregation
- platform settings

### `admin_dashboard_screen.dart`

The admin UI entry point currently uses tabs to expose multiple admin modules.

Main sections:

- Dashboard
- Users
- Artist Verify
- Moderation
- Transactions
- Disputes
- Analytics
- Settings

### Current admin implementation note

Some admin areas are backed by live Firestore data, while others still contain simulated or partially stubbed values.

---

## 6.5 Entities / Data Models

Location:

```text
lib/features/entities/models/
|-- artwork.dart
|-- commission.dart
|-- message_item.dart
|-- notification_item.dart
|-- order.dart
|-- review.dart
```

These model classes define the shape of shared app data used by services and screens.

Important models:

`artwork.dart`
- artwork metadata, artist identity, pricing, category, media, views, sold state, featured state

`commission.dart`
- commission request and status

`order.dart`
- buyer/seller transaction record and payout/payment state

`notification_item.dart`
- user notifications

`review.dart`
- artist reviews and ratings

---

## 6.6 Screens

Location:

```text
lib/features/screens/
|-- become_artist_screen.dart
|-- scholar_verification_screen.dart
|-- screens.dart
|-- welcome_screen.dart
|-- widgets/
|   |-- admin_summary_panel.dart
```

### Important structural note

`screens.dart` currently contains a very large amount of the app's user-facing UI and screen logic.

Current size observed:

- about 5,172 lines
- about 190 KB

This file includes many screens and flows such as:

- splash
- register/login
- buyer onboarding
- artist onboarding
- home
- artwork detail
- create artwork
- profile/edit profile
- messages
- chat
- commissions
- orders
- payments
- notifications
- artist profile
- search
- admin entry
- not found screen

This is a key maintainability hotspot and should eventually be split into focused files by feature or screen type.

---

## 6.7 Artworks and Payments

Other smaller feature areas include:

`lib/features/artworks/`
- repository and presentation state related to artworks/home feed

`lib/features/payments/`
- mock payment gateway
- checkout screen
- payment success screen

Current payment flow:

- artwork detail screen opens checkout
- checkout collects contact details
- checkout collects delivery preferences
- checkout collects payment selection and review
- mock authorization completes
- order is created
- transaction record is created for admin monitoring

These areas suggest future growth toward more modular feature separation, but much of the actual UI still lives in `screens.dart`.

---

## 7. Current User Flow

## 7.1 App Startup Flow

```text
App launch
-> main.dart
-> .env load attempt
-> Firebase initialization attempt
-> optional Supabase initialization
-> ArtflowApp created
-> AuthState.initialize()
-> AppDataState.initialize()
-> router redirect logic decides destination
```

### Startup decision points

- if auth is still checking, route stays on `/splash`
- if unauthenticated, user is redirected to welcome/register flow
- if authenticated as admin, user is redirected to `/admin`
- if authenticated as verified artist, user may be redirected to `/artist-dashboard`
- otherwise authenticated users land in the main app flow

---

## 7.2 Authentication and Onboarding Flow

```text
Splash
-> Welcome
-> Register/Login
-> Buyer onboarding or Artist onboarding
-> Main app
```

### Register/Login options

- email/password
- Google sign-in
- guest-like skip path exists in UI

### Buyer onboarding

Captures interest/preferences and then proceeds into the main experience.

### Artist onboarding

Captures initial style and bio details, then proceeds into the app.

### Become Artist flow

A buyer can later apply to become an artist through the dedicated artist application screen.

That flow submits:

- bio
- style
- medium
- experience
- sample artworks
- optional identity verification reference

---

## 7.3 Main In-App Flow

Most in-app screens are wrapped by `AppScaffold`.

Core navigation areas include:

- Home
- Explore
- Create/Upload
- Messages
- Profile
- Orders
- Payments
- Notifications
- Search

### Role-based behavior

Buyer:
- browse artworks
- place orders/commissions
- chat with artists
- leave reviews

Artist:
- all buyer capabilities plus
- upload/manage artwork
- receive commissions
- manage orders and payouts

Admin:
- redirected to admin panel
- can view and manage platform-wide data

---

## 7.4 Artist Verification Flow

```text
Buyer user
-> Become Artist screen
-> artistApplications document created/updated
-> user document marked verificationSubmitted = true
-> admin reviews application
-> approved: user becomes role = artist and isVerified = true
-> rejected: status updated with rejection reason
```

`AuthState` listens to the current user's artist application and updates UI flags accordingly.

---

## 7.5 Chat Flow

```text
User opens messages
-> contacts/conversations loaded
-> ChatService ensures thread exists
-> messages stream from Realtime Database
-> send message updates thread metadata and unread counts
```

Chat is user-to-user and is connected with commissions/order-related communication flows.

---

## 7.6 Order / Commission Flow

Typical current flow in code:

```text
Buyer browses artwork
-> buyer sends inquiry or commission request
-> commission created
-> artist receives notification
-> buyer can open checkout for a direct purchase
-> mock payment authorization completes
-> order created/updated
-> transaction record created
-> statuses move through pending/in progress/delivered/completed
-> notification updates are sent
-> buyer can rate artist after completion
```

This is implemented through `AppDataService` plus screen-level UI actions.

---

## 8. Data and State Flow

## 8.1 High-Level Architecture

```text
UI Widgets
-> Provider state objects
-> service/repository layer
-> Firebase backend
```

Main flow components:

`AuthState`
- owns user session, role, profile, verification state

`AppDataState`
- owns artworks, commissions, orders, notifications

`AuthService`
- talks to Firebase Auth and user/application Firestore records

`AppDataService`
- talks to shared Firestore collections

`ChatService`
- talks to Realtime Database for messaging

`AdminRepository`
- talks to Firestore for platform/admin operations

---

## 8.2 Provider Usage

The app currently uses `ChangeNotifier` with `Provider`.

At the top of the app:

- `AuthState` is provided globally
- `AppDataState` is provided globally

This makes it easy for screens to call:

- `context.watch<AuthState>()`
- `context.watch<AppDataState>()`
- `context.read<AuthState>()`
- `context.read<AppDataState>()`

---

## 8.3 Firebase Usage Map

### Firebase Auth

Used for:

- registration
- login
- Google authentication
- current session identity

### Cloud Firestore

Used for:

- `users`
- `artworks`
- `commissions`
- `orders`
- `notifications`
- `reviews`
- `artistApplications`
- `transactions`
- `disputes`
- `platformSettings`

### Firebase Realtime Database

Used for:

- conversation threads
- chat messages
- per-user thread lists

### Shared Preferences

Used for:

- welcome/onboarding completion flag

### Supabase Storage

Used for:

- profile photo uploads
- artwork image uploads

Environment values currently expected:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_STORAGE_BUCKET`
- `SUPABASE_PROFILE_FOLDER`
- `SUPABASE_ARTWORK_FOLDER`
- `SUPABASE_ARTIST_APPLICATION_FOLDER`
- `SUPABASE_SCHOLAR_FOLDER`

SQL policy helper:

- `Documentation/supabase_storage_policies.sql`

---

## 9. Security Rules Overview

The repository includes Firestore rules in `firestore.rules`.

Key patterns currently enforced:

- signed-in users can read core app data where appropriate
- users can create/manage their own user records within constraints
- admins have broad access
- artists can create and manage their own artworks
- commissions and orders are restricted to participants or admins
- artist applications are restricted to owner/admin

### Important current compromise

Notification creation is intentionally permissive for any authenticated user because the current app creates cross-user notifications directly from the client.

Implication:
- this works for now
- it is not ideal for production security
- long term, notification fan-out should move to trusted backend logic such as Cloud Functions

---

## 10. Current Strengths

- clear separation between auth state and shared app data state
- Firebase-backed architecture is already established
- environment-driven Supabase upload support is now wired into the app startup flow
- role-based routing is implemented
- admin functionality is broad and already scaffolded
- chat is separated into its own realtime service
- app theme and shell provide a consistent user experience
- multiple documentation files already exist for auth/admin/design areas
- checkout now follows explicit screens and steps instead of a one-tap purchase shortcut

---

## 11. Current Weaknesses and Hotspots

## 11.1 Very Large `screens.dart`

This is the biggest structural issue in the current codebase.

Risks:

- harder to navigate
- harder to test
- harder to review changes
- increased chance of merge conflicts
- UI/business logic can become tightly coupled

Recommended future split:

- auth screens
- onboarding screens
- marketplace/home screens
- profile/account screens
- messaging screens
- order/commission screens

## 11.2 Mixed Maturity Across Features

Some parts are fully data-driven; some admin/analytics/settings areas still use simulated or partially stubbed data.

Examples that still need more implementation:

- payment authorization is still mock-only
- dispute creation is not yet connected to buyer/artist flows
- scholar verification review is not yet exposed in the admin UI
- category and region management in platform settings are still placeholders

## 11.3 Limited Test Coverage

The `test/` area is currently small relative to app size and feature breadth.

## 11.4 Analyzer Warnings

A recent analyzer pass reported multiple warnings/info items, mostly:

- deprecated `withOpacity` usage
- `BuildContext` across async gap warnings
- unused local variables
- minor style/lint issues

These are not necessarily blockers, but they are worth cleaning up.

---

## 12. Suggested Mental Model for New Contributors

If you are trying to understand the project quickly, read in this order:

1. `lib/main.dart`
2. `lib/app.dart`
3. `lib/core/navigation/app_router.dart`
4. `lib/features/auth/presentation/auth_state.dart`
5. `lib/features/shared/data/app_data_state.dart`
6. `lib/features/shared/data/app_data_service.dart`
7. `lib/core/widgets/app_scaffold.dart`
8. `lib/features/screens/screens.dart`
9. `lib/features/chat/data/chat_service.dart`
10. `lib/features/admin/data/repositories/admin_repository.dart`

This gives a top-down picture from bootstrapping to user state, data, UI shell, and specialized features.

---

## 13. Future Documentation Suggestions

To keep project knowledge easy to maintain, the next useful docs would be:

- a route map with all paths and access rules
- a Firestore schema reference
- a Realtime Database chat schema reference
- a role/permission matrix
- a feature maturity checklist
- a refactor plan for splitting `screens.dart`

---

## 14. Quick Reference Summary

### App entry

- `lib/main.dart`
- `lib/app.dart`

### Routing

- `lib/core/navigation/app_router.dart`

### Theme and shell

- `lib/core/theme/app_theme.dart`
- `lib/core/widgets/app_scaffold.dart`

### Auth

- `lib/features/auth/data/auth_service.dart`
- `lib/features/auth/presentation/auth_state.dart`

### Shared data

- `lib/features/shared/data/app_data_service.dart`
- `lib/features/shared/data/app_data_state.dart`

### Chat

- `lib/features/chat/data/chat_service.dart`

### Admin

- `lib/features/admin/data/repositories/admin_repository.dart`
- `lib/features/admin/presentation/screens/admin_dashboard_screen.dart`

### Large UI aggregate file

- `lib/features/screens/screens.dart`

---

## 15. Closing Note

The project already contains the foundations of a full marketplace platform: auth, role-aware navigation, Firestore-backed content and transactions, realtime chat, and a meaningful admin surface.

Recent updates added persisted profile editing, Supabase-backed image upload hooks, a structured mock checkout flow, and transaction creation for admin monitoring.

The main next step for long-term maintainability is still improving structure in the heaviest UI areas and documenting backend data contracts more explicitly.
