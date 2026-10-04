#!/bin/sh
set -eu
printf '%s\n' "[crm] applying database migrations..."
npx prisma migrate deploy
printf '%s\n' "[crm] starting API..."
exec node dist/src/main.js
