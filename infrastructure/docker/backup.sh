#!/usr/bin/env bash
# Payspin Postgres backup. Run from the deploy dir (where docker-compose.yml lives).
#
# Cron example (daily 03:15, keep 14 days):
#   15 3 * * * cd /opt/payspin && ./backup.sh >> /var/log/payspin-backup.log 2>&1
set -euo pipefail

COMPOSE_DIR="${COMPOSE_DIR:-/opt/payspin}"
BACKUP_DIR="${BACKUP_DIR:-/opt/payspin/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
ENV_FILE="${COMPOSE_DIR}/.env.production"

cd "$COMPOSE_DIR"

# Pull DB credentials from the deployed env file.
# shellcheck disable=SC1090
set -a; [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"; set +a
PG_USER="${POSTGRES_USER:-payspin}"
PG_DB="${POSTGRES_DB:-payspin}"

mkdir -p "$BACKUP_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="${BACKUP_DIR}/payspin-${STAMP}.sql.gz"

echo "==> Dumping ${PG_DB} -> ${OUT}"
docker compose --env-file "$ENV_FILE" exec -T postgres \
  pg_dump -U "$PG_USER" -d "$PG_DB" | gzip > "$OUT"

echo "==> Pruning backups older than ${RETENTION_DAYS} days"
find "$BACKUP_DIR" -name 'payspin-*.sql.gz' -mtime "+${RETENTION_DAYS}" -delete

echo "Backup complete: $(du -h "$OUT" | cut -f1) ${OUT}"
