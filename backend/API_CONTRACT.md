# CRM Business API v0.1

## Auth
POST /api/auth/register-company
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
GET /api/auth/me

## Customers
GET /api/customers
POST /api/customers
GET /api/customers/:id
PATCH /api/customers/:id
DELETE /api/customers/:id

## Opportunities
GET /api/opportunities
POST /api/opportunities
GET /api/opportunities/:id
PATCH /api/opportunities/:id
DELETE /api/opportunities/:id
POST /api/opportunities/:id/stage

## Tasks
GET /api/tasks
POST /api/tasks
PATCH /api/tasks/:id
DELETE /api/tasks/:id

## Dashboard
GET /api/dashboard

Every tenant-scoped endpoint derives company_id from the authenticated identity. The client must never be trusted to choose another company_id.

## v0.8 Automation & Audit
GET /api/automation/rules
POST /api/automation/rules
PATCH /api/automation/rules/:id
DELETE /api/automation/rules/:id
GET /api/automation/executions
POST /api/automation/run-due
GET /api/audit-logs

## v0.9 Analytics & Subscriptions
GET /api/analytics/dashboard
GET /api/analytics/pipeline
GET /api/analytics/employees
GET /api/analytics/tasks
GET /api/subscriptions/plans
GET /api/subscriptions/current
