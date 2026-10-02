# v1.6 Release Checklist

## Server
- [ ] Domain DNS points to production server
- [ ] TLS certificate installed
- [ ] `.env.production` created outside Git
- [ ] `scripts/check-production-env.sh` passes
- [ ] PostgreSQL backup policy verified
- [ ] Docker services healthy
- [ ] `/api/health` returns 200
- [ ] `/api/health/ready` returns database=ok

## SaaS isolation
- [ ] Company A created
- [ ] Company B created
- [ ] Customer A created
- [ ] Company B cannot read Customer A
- [ ] Company B cannot modify Customer A
- [ ] Suspended company cannot authenticate

## Android
- [ ] API_BASE_URL points to HTTPS production API
- [ ] Flutter analyze passes
- [ ] Flutter tests pass
- [ ] Release AAB generated
- [ ] Signing secrets remain outside Git

## Launch
- [ ] Backup restore tested
- [ ] Monitoring/alerting configured
- [ ] Privacy policy URL prepared
- [ ] Google Play store listing prepared
