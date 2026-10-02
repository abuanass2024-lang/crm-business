# CRM Business v1.0.0

Production-hardening baseline for the multi-tenant CRM.

## Added
- Strong JWT secret validation
- Short-lived access tokens + rotating refresh sessions
- Refresh-token hashing at rest
- Helmet security headers
- Global rate limiting
- Strict validation (`forbidNonWhitelisted`)
- Subscription quota enforcement for users/customers/opportunities
- Automatic FREE/TRIAL subscription provisioning during company registration
- Security smoke-check script
- Tenant isolation remains server-derived from JWT `companyId`

## Important
Run database migrations and generate Prisma client before deployment. Replace all development secrets and configure an explicit CORS allowlist.
