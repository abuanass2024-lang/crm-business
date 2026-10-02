# CRM Business v1.4.0 — SaaS Multi-Tenant Production + Platform Admin

## What changed
- Tenant lifecycle status: `ACTIVE` / `SUSPENDED`.
- Suspended companies are blocked at JWT authentication level.
- Platform Admin model and guarded API.
- Platform Admin endpoints:
  - `GET /api/platform-admin/stats`
  - `GET /api/platform-admin/companies`
  - `PATCH /api/platform-admin/companies/:id/status`
  - `POST /api/platform-admin/companies/:id/plan`
- Subscription trial/expiry quota enforcement.
- Android version `1.4.0+14`.
- Production-safe Android release signing configuration.
- Manual GitHub Actions workflow for APK + AAB release builds, with optional encrypted signing.

## Important security model
Normal company users remain tenant-scoped. Platform Admin is a separate capability granted by a `PlatformAdmin` database record; it is not granted merely because a user is an OWNER.

## First platform-admin bootstrap
After the first controlled production deployment, insert a PlatformAdmin record for the designated operator using a one-time administrative database procedure. Do not expose a public endpoint for granting Platform Admin privileges.

Example SQL shape (replace values with real IDs):

```sql
INSERT INTO "PlatformAdmin" ("id", "userId", "companyId")
VALUES ('platform-admin-1', '<USER_ID>', '<COMPANY_ID>');
```

## Migration
Run:

```bash
docker compose --env-file .env.production -f docker-compose.prod.yml run --rm api npx prisma migrate deploy
```

## Google Play release
Use `mobile/RELEASE_SIGNING.md`. Never commit a keystore, passwords, or signing secrets.
