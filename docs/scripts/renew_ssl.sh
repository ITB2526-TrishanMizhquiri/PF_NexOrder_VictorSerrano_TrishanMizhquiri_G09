#!/bin/bash

# Configuración
CERT_FILE="/etc/pki/tls/certs/nexorder.crt"
KEY_FILE="/etc/pki/tls/private/nexorder.key"
LOG_FILE="/var/log/ssl_renewal.log"
DAYS_THRESHOLD=15

# Obtener fecha de expiración
EXPIRY_DATE=$(openssl x509 -in $CERT_FILE -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
CURRENT_EPOCH=$(date +%s)
DAYS_LEFT=$(( (EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))

echo "$(date '+%Y-%m-%d %H:%M:%S') - Certificado expira en $DAYS_LEFT días (Límite: $DAYS_THRESHOLD)" >> $LOG_FILE

# Verificar si quedan menos de 15 días
if [ $DAYS_LEFT -lt $DAYS_THRESHOLD ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ⚠️ Renovando certificado..." >> $LOG_FILE
    
    # Generar nuevo certificado
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $KEY_FILE \
    -out $CERT_FILE \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=NexOrder/OU=IT/CN=localhost"
    
    # Reiniciar Apache para aplicar el nuevo certificado
    systemctl restart httpd
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ✅ Certificado renovado y Apache reiniciado." >> $LOG_FILE
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ✅ Certificado válido, no se requiere renovación." >> $LOG_FILE
fi
