# CRM Business — Android Build

This directory is now a complete Flutter Android project scaffold around the MVP source.

## Requirements

- Flutter SDK (current stable)
- Android SDK / Android Studio tooling
- Java 17+

Flutter itself creates `android/local.properties` on the build machine; do not commit that machine-specific file.

## Build

```bash
cd mobile
flutter pub get
flutter analyze
flutter build apk --release
```

For smaller architecture-specific APKs:

```bash
flutter build apk --split-per-abi
```

For Google Play distribution:

```bash
flutter build appbundle --release
```

## Important

The current release build uses the debug signing configuration only to make local testing straightforward. Before publishing, configure a dedicated upload/release keystore and Play App Signing.

The current screens are an offline MVP UI. The NestJS API and PostgreSQL schema in the parent project are prepared for the next integration stage; no production API credentials are embedded in the app.
