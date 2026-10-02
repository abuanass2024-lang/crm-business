# CRM Business v1.2.0

Android-first UX and runtime integration release.

## User journey
Login/Register → Home → Customers → Customer 360 → Pipeline → Tasks → Analytics → Subscription → Logout.

## API configuration
Set `API_BASE_URL` at build time. Android emulator default remains `http://10.0.2.2:3000/api` for local backend testing.

## Production checklist
- Replace API_BASE_URL with HTTPS production endpoint.
- Configure Android application ID/signing.
- Run flutter analyze/test.
- Build release APK/AAB.
- Execute backend integration journey and tenant isolation smoke tests.
