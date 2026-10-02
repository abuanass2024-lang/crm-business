# CRM Business v1.3.0 — Production Deployment Baseline

This release prepares the multi-tenant CRM for production deployment without embedding production secrets.

## Added
- `/api/health`, `/api/health/live`, `/api/health/ready`.
- Production Docker Compose stack: PostgreSQL + API + Nginx.
- Production environment template: `.env.production.example`.
- Nginx reverse-proxy baseline.
- PostgreSQL backup script.
- Unified CI for backend migration/build/security smoke test and Android analyze/test/APK build.
- APP_VERSION support for runtime health reporting.

## Production start
1. Copy `.env.production.example` to `.env.production`.
2. Replace all secrets and the public CORS origin.
3. Put TLS certificates under `deploy/nginx/certs/` and extend the Nginx server block for HTTPS.
4. Run `docker compose --env-file .env.production -f docker-compose.prod.yml up -d --build`.
5. Apply Prisma migrations: `docker compose --env-file .env.production -f docker-compose.prod.yml run --rm api npx prisma migrate deploy`.
6. Verify `/api/health/live` and `/api/health/ready` through the reverse proxy.

## Security notes
- Never commit `.env.production`, database dumps, TLS private keys, JWT secrets, or signing keys.
- Production must use HTTPS.
- Keep CORS restricted to the actual application origins.
- Backups should be copied to an independent encrypted storage target and periodically restore-tested.
- Android release signing keys must be stored as CI secrets, not in the repository.
