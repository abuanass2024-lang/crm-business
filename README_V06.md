# CRM Business v0.6 — Tasks, Activities & Notifications

This release extends v0.5 with:
- Tasks CRUD with tenant isolation and validation of customer/opportunity/assignee references.
- Activities create/list with tenant-safe customer/opportunity references.
- Notifications list, unread count, mark-one-read and mark-all-read.
- Prisma relations for tasks/opportunities and activities/opportunities.
- Android task screen connected to `/api/tasks`.
- JWT userId claim fixed for downstream activity/task/opportunity ownership.

## Backend

```bash
cd backend
npm install
npx prisma generate
npx prisma migrate dev --name tasks_activities_notifications
npm run start:dev
```

## Mobile

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

Release APK command when Flutter/Android SDK are installed:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR_API_DOMAIN/api
```
