# CRM Business v0.7 — Users, Roles & Permissions

Added company user management and server-side permission enforcement.

## Roles
OWNER, ADMIN, MANAGER, SALES, VIEWER

## Examples
- users.read
- users.manage
- customers.create
- opportunities.update
- tasks.create
- reports.read

OWNER bypasses permission lookup. Other roles are checked server-side through `role_permissions`.

## Endpoints
GET /api/users
POST /api/users
PATCH /api/users/:id

Run seed after Prisma migration:
`npm run prisma:seed`
