# CRM Business v1.0.0

Multi-tenant CRM SaaS baseline: Flutter Android + NestJS API + PostgreSQL + Prisma.

## v1.0 hardening
- Short-lived JWT access tokens + rotating refresh tokens.
- Refresh tokens are stored only as SHA-256 hashes.
- Active-user check on every authenticated request.
- Strict DTO validation.
- Helmet security headers.
- Global throttling (120 requests/minute default).
- Explicit CORS allowlist via `CORS_ORIGINS`.
- Server-side SaaS quotas for users/customers/opportunities.
- FREE/TRIAL subscription provisioned during company registration when seed plans exist.
- Cross-tenant reference validation for assigned users/customers/opportunities/tasks.
- Prisma baseline migration included.
- Android CI runs analyze, tests, and release APK build.

## Local backend
```bash
cd backend
cp .env.example .env
npm install
npx prisma generate
npx prisma migrate deploy
npm run prisma:seed
npm run build
npm start
```

## Environment
`JWT_SECRET` must be a random secret of at least 32 characters. Set production `DATABASE_URL` and a comma-separated `CORS_ORIGINS` allowlist.

## Android
The included GitHub Actions workflow builds a release APK. Before Google Play publication, configure a real release/upload keystore and Play App Signing.

## Current release
CRM Business **v1.5.0 — Launch Readiness**. See `README_V15.md` for production deployment and release steps.
