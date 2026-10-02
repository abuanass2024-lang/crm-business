#!/usr/bin/env sh
set -eu
file="${1:-.env.production}"
[ -f "$file" ] || { echo "Missing $file"; exit 1; }
for key in POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD DATABASE_URL JWT_SECRET CORS_ORIGINS; do
  value=$(grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true)
  [ -n "$value" ] || { echo "Missing $key"; exit 1; }
done
jwt=$(grep -E '^JWT_SECRET=' "$file" | tail -1 | cut -d= -f2-)
[ "${#jwt}" -ge 32 ] || { echo "JWT_SECRET must be at least 32 characters"; exit 1; }
case "$jwt" in CHANGE_ME*|change_me*) echo "JWT_SECRET is still a placeholder"; exit 1;; esac
echo "Production environment sanity check: PASS"
