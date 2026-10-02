#!/usr/bin/env sh
set -eu
: "${POSTGRES_CONTAINER:=crm-business-postgres-1}"
: "${POSTGRES_USER:=crm}"
: "${POSTGRES_DB:=crm_business}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
mkdir -p "$BACKUP_DIR"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
out="$BACKUP_DIR/${POSTGRES_DB}_${STAMP}.dump"
docker exec "$POSTGRES_CONTAINER" pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc > "$out"
echo "Backup written to $out"
