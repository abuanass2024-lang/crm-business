# CRM Business v0.4

This version adds real multi-tenant Customer CRUD and Customer 360.

## API
- GET /api/customers?q=
- POST /api/customers
- GET /api/customers/:id
- PATCH /api/customers/:id
- DELETE /api/customers/:id

Every endpoint requires a JWT. The company/tenant is taken from the verified JWT and is never accepted as a trusted client selector.

## Android
flutter pub get
flutter analyze
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR_API_DOMAIN/api
