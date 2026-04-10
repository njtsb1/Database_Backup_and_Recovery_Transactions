# Automated backup script for MySQL/MariaDB using mysqldump
# Usage: ./backup.sh [dest_dir]
#
# Notes:
# - Do not pass a password on the command line. Configure ~/.my.cnf with username/password
# or export MYSQL_PWD as an environment variable (less recommended).
# - Adjust DB_NAMES, RETENTION_DAYS and other variables as needed.
# - Requires: mysqldump, gzip, pv (optional), sha256sum (optional), aws cli (optional)
#

set -euo pipefail

# ---------- Settings ----------
DEST_DIR="${1:-./backups}" # destination directory (default ./backups)
TIMESTAMP="$(date +%F_%H%M%S)"
HOST="localhost"
PORT="3306"
DB_NAMES=("ecommerce") # databases to be dumped (array)
# For multiple databases: DB_NAMES=("ecommerce" "analytics")
INCLUDE_ROUTINES=true
INCLUDE_EVENTS=true
INCLUDE_TRIGGERS=true
SINGLE_TRANSACTION=true # recommended for InnoDB
HEX_BLOB=true
COLUMN_STATISTICS=false # Set to true to include column-statistics
RETENTION_DAYS=14 # How many days to keep
COMPRESS=true
USE_PV=false # If true, use PV to show progress
LOGFILE="${DEST_DIR}/backup_${TIMESTAMP}.log"
SHA_FILE="${DEST_DIR}/backup_${TIMESTAMP}.sha256"

# Optional: upload to S3 (comment if not used)
S3_UPLOAD=false
S3_BUCKET="s3://my-bucket-backups"

# ---------- Preparation ----------
mkdir -p "${DEST_DIR}"
exec > >(tee -a "${LOGFILE}") 2>&1

echo "=== Starting backup: ${TIMESTAMP} ==="
echo "Destination: ${DEST_DIR}"
echo "Banks: ${DB_NAMES[*]}"

# Mount mysqldump options
DUMP_OPTS=()
if [ "${INCLUDE_ROUTINES}" = true ]; then DUMP_OPTS+=(--routines); fi
if [ "${INCLUDE_EVENTS}" = true ]; then DUMP_OPTS+=(--events); fi
if [ "${INCLUDE_TRIGGERS}" = true ]; then DUMP_OPTS+=(--triggers); fi
if [ "${SINGLE_TRANSACTION}" = true ]; then DUMP_OPTS+=(--single-transaction); fi
if [ "${HEX_BLOB}" = true ]; then DUMP_OPTS+=(--hex-blob); fi
if [ "${COLUMN_STATISTICS}" = false ]; then DUMP_OPTS+=(--column-statistics=0); fi

# Build list of banks for mysqldump
# If you want to include CREATE DATABASE/USE, use --databases followed by the names
DBS_ARG=(--databases "${DB_NAMES[@]}")

OUTFILE_BASE="${DEST_DIR}/backup_${DB_NAMES[*]// /_}_${TIMESTAMP}.sql"
OUTFILE="${OUTFILE_BASE}"
if [ "${COMPRESS}" = true ]; then OUTFILE="${OUTFILE_BASE}.gz"; fi

# ---------- Dump execution ----------
echo "Running mysqldump..."
DUMP_CMD=(mysqldump -h "${HOST}" -P "${PORT}" -u backup_user "${DUMP_OPTS[@]}" "${DBS_ARG[@]}")

# Note: do not include password here; use ~/.my.cnf or MYSQL_PWD (less secure)
if [ "${COMPRESS}" = true ]; then
  if [ "${USE_PV}" = true ] && command -v pv >/dev/null 2>&1; then
    "${DUMP_CMD[@]}" | pv | gzip > "${OUTFILE}"
  else
    "${DUMP_CMD[@]}" | gzip > "${OUTFILE}"
  fi
else
  if [ "${USE_PV}" = true ] && command -v pv >/dev/null 2>&1; then
    "${DUMP_CMD[@]}" | pv > "${OUTFILE}"
  else
    "${DUMP_CMD[@]}" > "${OUTFILE}"
  fi
fi

echo "Dump finished: ${OUTFILE}"

# ---------- Integrity check (hash) ----------
if command -v sha256sum >/dev/null 2>&1; then
  echo "Calculating SHA256..."
  sha256sum "${OUTFILE}" > "${SHA_FILE}"
  echo "SHA saved in ${SHA_FILE}"
fi

# ---------- Optional upload to S3 ----------
if [ "${S3_UPLOAD}" = true ]; then
  if command -v aws >/dev/null 2>&1; then
    echo "Sending ${OUTFILE} to ${S3_BUCKET}..."
    aws s3 cp "${OUTFILE}" "${S3_BUCKET}/" --only-show-errors
    if [ -f "${SHA_FILE}" ]; then
      aws s3 cp "${SHA_FILE}" "${S3_BUCKET}/" --only-show-errors
    fi
    echo "Upload complete."
  else
    echo "aws cli not found; skipping S3 upload."
  fi
fi

# ---------- Rotation / Retention ----------
echo "Removing backups older than ${RETENTION_DAYS} days..."
find "${DEST_DIR}" -type f -mtime +"${RETENTION_DAYS}" -name 'backup_*' -print -delete || true

echo "Backup completed successfully on $(date +%F_%T)"
exit 0
