# Script de backup automatizado para MySQL/MariaDB usando mysqldump
# Uso: ./backup.sh [dest_dir]
#
# Observações:
# - Não passe senha na linha de comando. Configure ~/.my.cnf com usuário/senha
#   ou exporte MYSQL_PWD como variável de ambiente (menos recomendado).
# - Ajuste DB_NAMES, RETENTION_DAYS e outras variáveis conforme necessário.
# - Requer: mysqldump, gzip, pv (opcional), sha256sum (opcional), aws cli (opcional)
#

set -euo pipefail

# ---------- Configurações ----------
DEST_DIR="${1:-./backups}"           # diretório de destino (padrão ./backups)
TIMESTAMP="$(date +%F_%H%M%S)"
HOST="localhost"
PORT="3306"
DB_NAMES=("ecommerce")               # bancos a serem dumpados (array)
# Para múltiplos bancos: DB_NAMES=("ecommerce" "analytics")
INCLUDE_ROUTINES=true
INCLUDE_EVENTS=true
INCLUDE_TRIGGERS=true
SINGLE_TRANSACTION=true              # recomendado para InnoDB
HEX_BLOB=true
COLUMN_STATISTICS=false              # set to true to include column-statistics
RETENTION_DAYS=14                    # quantos dias manter
COMPRESS=true
USE_PV=false                         # se true, usa pv para mostrar progresso
LOGFILE="${DEST_DIR}/backup_${TIMESTAMP}.log"
SHA_FILE="${DEST_DIR}/backup_${TIMESTAMP}.sha256"

# Opcional: upload para S3 (comente se não usar)
S3_UPLOAD=false
S3_BUCKET="s3://meu-bucket-backups"

# ---------- Preparação ----------
mkdir -p "${DEST_DIR}"
exec > >(tee -a "${LOGFILE}") 2>&1

echo "=== Iniciando backup: ${TIMESTAMP} ==="
echo "Destino: ${DEST_DIR}"
echo "Bancos: ${DB_NAMES[*]}"

# Monta opções do mysqldump
DUMP_OPTS=()
if [ "${INCLUDE_ROUTINES}" = true ]; then DUMP_OPTS+=(--routines); fi
if [ "${INCLUDE_EVENTS}" = true ]; then DUMP_OPTS+=(--events); fi
if [ "${INCLUDE_TRIGGERS}" = true ]; then DUMP_OPTS+=(--triggers); fi
if [ "${SINGLE_TRANSACTION}" = true ]; then DUMP_OPTS+=(--single-transaction); fi
if [ "${HEX_BLOB}" = true ]; then DUMP_OPTS+=(--hex-blob); fi
if [ "${COLUMN_STATISTICS}" = false ]; then DUMP_OPTS+=(--column-statistics=0); fi

# Constrói lista de bancos para mysqldump
# Se quiser incluir CREATE DATABASE/USE, use --databases seguido dos nomes
DBS_ARG=(--databases "${DB_NAMES[@]}")

OUTFILE_BASE="${DEST_DIR}/backup_${DB_NAMES[*]// /_}_${TIMESTAMP}.sql"
OUTFILE="${OUTFILE_BASE}"
if [ "${COMPRESS}" = true ]; then OUTFILE="${OUTFILE_BASE}.gz"; fi

# ---------- Execução do dump ----------
echo "Executando mysqldump..."
DUMP_CMD=(mysqldump -h "${HOST}" -P "${PORT}" -u backup_user "${DUMP_OPTS[@]}" "${DBS_ARG[@]}")

# Nota: não inclua senha aqui; use ~/.my.cnf ou MYSQL_PWD (menos seguro)
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

echo "Dump finalizado: ${OUTFILE}"

# ---------- Verificação de integridade (hash) ----------
if command -v sha256sum >/dev/null 2>&1; then
  echo "Calculando SHA256..."
  sha256sum "${OUTFILE}" > "${SHA_FILE}"
  echo "SHA salvo em ${SHA_FILE}"
fi

# ---------- Upload opcional para S3 ----------
if [ "${S3_UPLOAD}" = true ]; then
  if command -v aws >/dev/null 2>&1; then
    echo "Enviando ${OUTFILE} para ${S3_BUCKET}..."
    aws s3 cp "${OUTFILE}" "${S3_BUCKET}/" --only-show-errors
    if [ -f "${SHA_FILE}" ]; then
      aws s3 cp "${SHA_FILE}" "${S3_BUCKET}/" --only-show-errors
    fi
    echo "Upload concluído."
  else
    echo "aws cli não encontrado; pulando upload S3."
  fi
fi

# ---------- Rotação / retenção ----------
echo "Removendo backups com mais de ${RETENTION_DAYS} dias..."
find "${DEST_DIR}" -type f -mtime +"${RETENTION_DAYS}" -name 'backup_*' -print -delete || true

echo "Backup concluído com sucesso em $(date +%F_%T)"
exit 0
