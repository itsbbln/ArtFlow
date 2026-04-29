# ArtFlow TODO

## Ready To Use Now

- Email/password and Google sign-in
- Role-based routing for buyer, artist, and admin views
- Buyer/artist/admin core navigation
- Artist application submission and admin approval/rejection
- Chat with Firebase Realtime Database
- Persisted profile edits for name, username, bio, and premium toggles
- Profile photo upload flow
- Artwork image upload flow
- Artist application portfolio and ID image upload flow
- Scholar verification image upload flow
- Structured mock checkout flow
- Order creation plus admin-facing transaction record creation

## Still Needs Implementation

### Payments

- Replace the mock payment gateway with a real provider integration
- Add payment failure, cancellation, refund, and retry flows
- Persist richer payment metadata such as provider transaction IDs and webhook-confirmed states
- Align platform fee math between buyer UI, transactions, and admin analytics

### Media / Storage

- Add upload progress UI for large images
- Add image compression/resize strategy beyond the current picker settings
- Add delete/replace cleanup for old Supabase files

### Artwork Management

- Support multiple artwork images instead of a single main image
- Add artwork image reordering and removal
- Add richer artwork metadata validation and moderation flags

### Profile / User Data

- Decide whether premium toggles should stay user-controlled or become purchase-backed features
- Add persistent address/contact book data for checkout reuse
- Add editable profile fields for location, links, and portfolio details

### Admin

- Wire buyer/artist flows to create real dispute cases
- Add scholar verification review UI to the admin panel
- Replace simulated analytics data with real aggregated reporting
- Implement category and region CRUD in platform settings
- Improve artwork moderation inputs so reports/flags are created by real user actions

### Security / Backend

- Revisit Firestore rules around `transactions` after the final payment architecture is chosen
- Move cross-user notification fan-out to trusted backend logic
- Add stronger validation around transaction creation and status transitions
- Add signed upload or stricter storage policies for media if needed

### Quality

- Split the large `lib/features/screens/screens.dart` file into focused screen files
- Expand widget and integration test coverage beyond the current app boot smoke test
- Clean up existing analyzer warnings and deprecated `withOpacity` usage

## Environment Keys To Fill

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_STORAGE_BUCKET`
- `SUPABASE_PROFILE_FOLDER`
- `SUPABASE_ARTWORK_FOLDER`
- `SUPABASE_ARTIST_APPLICATION_FOLDER`
- `SUPABASE_SCHOLAR_FOLDER`

## Notes

- The mock checkout flow is intentionally staged like a real purchase flow, but it does not contact a real payment provider yet.
- Supabase upload support is implemented for profile photos, artwork media, artist application images, and scholar verification images.
- SQL bucket policy setup is included in [supabase_storage_policies.sql](/c:/Users/USER/Desktop/Art%20Flow/Documentation/supabase_storage_policies.sql:1).
