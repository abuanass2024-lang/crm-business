# CRM Business v1.2.0 — Android UX & Runtime

Adds an Android-first navigation shell, Arabic RTL-friendly labels, persistent session refresh, dashboard cards, Customers/Customer 360, Pipeline, Tasks, Analytics and Subscription screens, plus logout.

Build with:
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-API-DOMAIN/api

## v1.3 compatibility
The Android client is included in the production CI workflow. Configure the API base URL at build time as documented in the mobile source.
