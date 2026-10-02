# CRM Business v0.5 — Sales Pipeline

This release adds the first real sales pipeline layer on top of the v0.4 Customer 360 foundation.

## Backend

```bash
cd backend
npm install
npx prisma generate
npx prisma migrate dev --name add_opportunity_stage_history
npm run start:dev
```

## API

`GET /api/opportunities`
`POST /api/opportunities`
`GET /api/opportunities/:id`
`PATCH /api/opportunities/:id`
`DELETE /api/opportunities/:id`
`GET /api/opportunities/pipeline`

## Flutter

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

The application reads pipeline metrics from the API; no company identifier is accepted from the mobile client as a trust boundary.
