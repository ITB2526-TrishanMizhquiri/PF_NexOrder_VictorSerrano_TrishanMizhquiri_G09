#!/bin/bash
# =========================================================
# SCRIPT DE BACKUP AUTOMATIZADO - NexOrder (T13)
# =========================================================

# --- CONFIGURACIÓN ---
DB_HOST="nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_PASS="N3x0r-DB-2026!Sec"
DB_NAME="nexorder_db"
BACKUP_DIR="/backups"
LOG_FILE="/var/log/nexorder_backup.log"

# --- LÓGICA ---
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="nexorder_db_${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Iniciando backup de $DB_NAME..." >> "$LOG_FILE"

# Exportación lógica + compresión en pipeline
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" \
  2>>"$LOG_FILE" | gzip > "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -eq 0 ]; then
    FILE_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ÉXITO] Backup creado: $BACKUP_FILE ($FILE_SIZE)" >> "$LOG_FILE"
    # Política de retención: eliminar backups con más de 7 días
    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Limpieza de backups antiguos completada." >> "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Fallo en mysqldump. Revisar log." >> "$LOG_FILE"
    exit 1
fi