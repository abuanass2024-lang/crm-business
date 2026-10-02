# CRM Business v0.9 — Reports, Analytics & SaaS Plans

## Added
- Tenant-scoped analytics dashboard.
- Pipeline analytics by stage with value and weighted value.
- Employee workload/activity metrics without political or subjective ranking.
- Task completion and overdue metrics.
- SaaS plan catalog: Free, Basic, Professional, Enterprise-ready model.
- Company subscription status: TRIAL, ACTIVE, PAST_DUE, SUSPENDED, CANCELLED.
- API endpoints for current plan and active plans.
- PostgreSQL/Prisma models for plans and subscriptions.

## API
- GET /api/analytics/dashboard
- GET /api/analytics/pipeline
- GET /api/analytics/employees
- GET /api/analytics/tasks
- GET /api/subscriptions/plans
- GET /api/subscriptions/current

## Important
This release provides the data model and read APIs for subscriptions. Payment gateway integration and server-side quota enforcement are deliberately the next hardening step.
