#!/bin/bash
# =========================================================
# SCRIPT DE DESPLIEGUE CONTINUO - NexOrder (T17)
# Correcciones: sudo en rsync + servicio httpd (Amazon Linux)
# =========================================================

SRC_DIR="/home/ec2-user/web-staging/"
DEST_DIR="/var/www/html/"
LOG_FILE="/var/log/deploy_nexorder.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TIMESTAMP] --- INICIO DESPLIEGUE ---" >> "$LOG_FILE"

# Verificar prerequisito
if ! command -v rsync &> /dev/null; then
    echo "[$TIMESTAMP] ERROR: rsync no está instalado." >> "$LOG_FILE"
    exit 1
fi

# -a: archive  -v: verbose  -z: compress  --delete: modo espejo
sudo rsync -avz --delete "$SRC_DIR" "$DEST_DIR" >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "[$TIMESTAMP] Sincronización de archivos completada exitosamente." >> "$LOG_FILE"
    echo "[$TIMESTAMP] Recargando servicio httpd para aplicar cambios..." >> "$LOG_FILE"
    sudo systemctl reload httpd
    if [ $? -eq 0 ]; then
        echo "[$TIMESTAMP] Servicio httpd recargado correctamente." >> "$LOG_FILE"
        echo "[$TIMESTAMP] DESPLIEGUE COMPLETADO CON EXITO" >> "$LOG_FILE"
    else
        echo "[$TIMESTAMP] AVISO: Archivos copiados, pero fallo al recargar httpd." >> "$LOG_FILE"
    fi
else
    echo "[$TIMESTAMP] ERROR FATAL en la sincronización. httpd NO se recargó." >> "$LOG_FILE"
    exit 1
fi

echo "[$TIMESTAMP] --- FIN DESPLIEGUE ---" >> "$LOG_FILE"
echo "-----------------------------------" >> "$LOG_FILE"