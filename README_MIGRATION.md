# Artflow Flutter Migration Baseline

This folder contains a Flutter mobile baseline generated from the React/Vite routes and entities in the parent project.

## What Was Migrated

- App shell and navigation using `go_router`
- Route parity for all existing React routes
- Entity model stubs for Artwork, Commissions, Message, Notification, Order, and Review
- Shared `ArtworkCard` widget
- Authentication state skeleton and route guarding
- API and repository stubs for future backend wiring

## Important Notes

- This is a structural migration baseline, not a 1:1 feature-complete behavior port.
- Data and backend calls are currently mocked/stubbed.
- Replace stubs in `lib/features/shared/data` and repositories with your real API layer.

## Run

```bash
cd artflow_flutter
flutter run
```
