# CRM Business v0.8 — Automation Engine + Audit Log

## New in v0.8
- Rule engine: Trigger → Condition → Action → Execution Log.
- Tenant-isolated automation rules.
- Supported triggers: CUSTOMER_CREATED, OPPORTUNITY_CREATED, OPPORTUNITY_STAGE_CHANGED, TASK_CREATED, TASK_DUE_SOON, TASK_OVERDUE, OPPORTUNITY_WON, OPPORTUNITY_LOST.
- Supported actions: CREATE_TASK, CREATE_NOTIFICATION, CHANGE_CUSTOMER_STATUS, LOG_ACTIVITY.
- Idempotent execution records to reduce duplicate actions.
- Audit log API with old/new values and actor.
- Audit events for authentication, customer/opportunity/task/user changes and opportunity stage changes.

## API
Automation:
- GET /api/automation/rules
- POST /api/automation/rules
- PATCH /api/automation/rules/:id
- DELETE /api/automation/rules/:id
- GET /api/automation/executions
- POST /api/automation/run-due

Audit:
- GET /api/audit-logs

## Example rule
Trigger: OPPORTUNITY_STAGE_CHANGED
Condition: toStage = PROPOSAL
Action: CREATE_TASK
Action data: {"title":"متابعة العرض","priority":"HIGH","dueInDays":2}

All rule execution and audit records are scoped by authenticated companyId.
