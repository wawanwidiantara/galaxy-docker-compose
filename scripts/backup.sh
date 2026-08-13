#!/usr/bin/env bash
# Backs up the Galaxy Postgres database and critical config from the running
# container. Postgres lives inside the single galaxy container and is not
# network-exposed, so this shells in via `docker exec` rather than a network
# backup tool.
#
# Usage: ./scripts/backup.sh
# Run via host cron for scheduled backups, e.g.:
#   0 2 * * * cd /path/to/galaxy-docker-compose && ./scripts/backup.sh >> logs/backup.log 2>&1
set -euo pipefail

CONTAINER_NAME="${GALAXY_CONTAINER_NAME:-galaxy_production}"
BACKUP_DIR="${GALAXY_BACKUP_DIR:-./backups}"
KEEP_DAYS="${GALAXY_BACKUP_KEEP_DAYS:-14}"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "${BACKUP_DIR}"

if ! docker inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
  echo "Container ${CONTAINER_NAME} not found — is it running?" >&2
  exit 1
fi

echo "[$(date -Is)] Dumping Postgres database..."
docker exec -u postgres "${CONTAINER_NAME}" \
  pg_dump -Fc galaxy > "${BACKUP_DIR}/galaxy-db-${STAMP}.dump"

echo "[$(date -Is)] Archiving Galaxy config..."
docker exec "${CONTAINER_NAME}" \
  tar -C /export/galaxy -czf - config \
  > "${BACKUP_DIR}/galaxy-config-${STAMP}.tar.gz"

echo "[$(date -Is)] Pruning backups older than ${KEEP_DAYS} days..."
find "${BACKUP_DIR}" -name 'galaxy-db-*.dump' -mtime "+${KEEP_DAYS}" -delete
find "${BACKUP_DIR}" -name 'galaxy-config-*.tar.gz' -mtime "+${KEEP_DAYS}" -delete

echo "[$(date -Is)] Done: ${BACKUP_DIR}/galaxy-db-${STAMP}.dump"

# NOTE: this backs up the database and config, not the (potentially huge)
# dataset files under ./export/galaxy/database/files/. Back those up with
# filesystem-level snapshotting (LVM/ZFS snapshot, rsync, or your NAS's own
# backup if you followed the "split storage" setup in PRODUCTION_SETUP.md).
