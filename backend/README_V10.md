# CRM Business v1.0 — Production Hardening

This release moves the project from feature-complete MVP toward a deployable multi-tenant baseline.

### Security
- Access tokens default to 15 minutes.
- Refresh tokens are random, stored only as SHA-256 hashes, rotated on use, and revocable.
- `JWT_SECRET` must be at least 32 characters.
- Helmet is enabled.
- Global request throttling: 120 requests/minute per client by default.
- DTO validation is strict.
- CORS is allowlist-based through `CORS_ORIGINS`.

### Multi-tenancy
Every tenant-scoped service receives `companyId` from the authenticated JWT. The mobile client never supplies a trusted tenant selector.

### SaaS quotas
The active/trial subscription plan controls max users, customers, and opportunities. Creation endpoints enforce limits server-side.

### Deployment checklist
1. Copy `.env.example` to `.env`.
2. Generate a strong `JWT_SECRET`.
3. Set production `DATABASE_URL`.
4. Set `CORS_ORIGINS`.
5. Run `npm install`, `npx prisma generate`, `npx prisma migrate deploy`.
6. Seed plans/permissions.
7. Run `npm run build`.
8. Run the security smoke checks.
9. Build the Android release through the included CI workflow.
