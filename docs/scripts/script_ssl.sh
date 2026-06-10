#!/bin/bash

# ============================================================
# Script de Configuración SSL con Let's Encrypt (Certbot)
# Para: Amazon Linux 2023 / Amazon Linux 2 con Apache
# ============================================================

set -e

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}� Iniciando configuración SSL con Let's Encrypt...${NC}"

# ============================================================
# PASO 1: Verificar que se ejecuta como root
# ============================================================
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Error: Este script debe ejecutarse como root (sudo)${NC}"
    exit 1
fi

# ============================================================
# PASO 2: Solicitar el dominio
# ============================================================
echo ""
echo -e "${YELLOW}� Configuración del dominio${NC}"
echo "IMPORTANTE: Let's Encrypt requiere un dominio válido (no funciona con IPs)"
echo "Ejemplo: nexorder.com, app.nexorder.com"
echo ""
read -p "Ingresa tu dominio (ej: nexorder.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ Error: Debes ingresar un dominio${NC}"
    exit 1
fi

echo ""
read -p "¿Tienes el dominio apuntando a esta instancia? (s/n): " CONFIRM
if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
    echo -e "${YELLOW}⚠️  Asegúrate de configurar el DNS antes de continuar${NC}"
    echo "   Crea un registro A en tu DNS apuntando a: $(curl -s ifconfig.me)"
    exit 1
fi

# ============================================================
# PASO 3: Instalar Certbot y dependencias
# ============================================================
echo ""
echo -e "${GREEN}� Instalando Certbot y dependencias...${NC}"

# Detectar versión de Amazon Linux
if [ -f /etc/system-release ]; then
    if grep -q "Amazon Linux release 2023" /etc/system-release; then
        echo "   Detectado: Amazon Linux 2023"
        sudo dnf install -y certbot python3-certbot-apache mod_ssl
    elif grep -q "Amazon Linux release 2" /etc/system-release; then
        echo "   Detectado: Amazon Linux 2"
        sudo yum install -y certbot python2-certbot-apache mod_ssl
    else
        echo -e "${RED}❌ Sistema operativo no soportado${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ No se pudo detectar el sistema operativo${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Certbot instalado correctamente${NC}"

# ============================================================
# PASO 4: Verificar que Apache esté corriendo
# ============================================================
echo ""
echo -e "${GREEN}� Verificando Apache...${NC}"

if ! systemctl is-active --quiet httpd; then
    echo -e "${YELLOW}⚠️  Apache no está corriendo. Iniciando...${NC}"
    sudo systemctl start httpd
    sudo systemctl enable httpd
fi

echo -e "${GREEN}✅ Apache está activo${NC}"

# ============================================================
# PASO 5: Verificar configuración de Apache
# ============================================================
echo ""
echo -e "${GREEN}� Verificando configuración de Apache...${NC}"

# Verificar que existe el VirtualHost
if [ ! -f /etc/httpd/conf.d/nexorder-ssl.conf ]; then
    echo -e "${RED}❌ No se encontró /etc/httpd/conf.d/nexorder-ssl.conf${NC}"
    echo "   Asegúrate de tener configurado tu VirtualHost primero"
    exit 1
fi

echo -e "${GREEN}✅ Configuración de Apache encontrada${NC}"

# ============================================================
# PASO 6: Obtener certificado SSL
# ============================================================
echo ""
echo -e "${GREEN}� Obteniendo certificado SSL para: $DOMAIN${NC}"
echo "   Esto puede tardar unos minutos..."
echo ""

# Ejecutar Certbot
certbot --apache -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN --redirect

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Certificado SSL obtenido exitosamente${NC}"
else
    echo -e "${RED}❌ Error al obtener el certificado${NC}"
    echo "   Posibles causas:"
    echo "   - El dominio no apunta a esta instancia"
    echo "   - El puerto 80 está bloqueado"
    echo "   - Apache no está configurado correctamente"
    exit 1
fi

# ============================================================
# PASO 7: Verificar configuración SSL
# ============================================================
echo ""
echo -e "${GREEN}� Verificando configuración SSL...${NC}"

# Verificar que el certificado se instaló
if [ -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ]; then
    echo -e "${GREEN}✅ Certificado instalado en: /etc/letsencrypt/live/$DOMAIN/${NC}"
else
    echo -e "${RED}❌ No se encontró el certificado${NC}"
    exit 1
fi

# ============================================================
# PASO 8: Configurar renovación automática
# ============================================================
echo ""
echo -e "${GREEN}⏰ Configurando renovación automática...${NC}"

# Crear script de renovación
cat > /opt/scripts/renew_ssl.sh << 'EOF'
#!/bin/bash
# Script de renovación automática de certificado SSL

LOG_FILE="/var/log/ssl_renewal.log"
DOMAIN="PLACEHOLDER_DOMAIN"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Iniciando renovación de certificado para $DOMAIN" >> $LOG_FILE

# Intentar renovar
certbot renew --quiet --post-hook "systemctl reload httpd"

if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Renovación exitosa" >> $LOG_FILE
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error en la renovación" >> $LOG_FILE
    # Aquí podrías agregar notificación por email
fi
EOF

# Reemplazar placeholder con el dominio real
sed -i "s/PLACEHOLDER_DOMAIN/$DOMAIN/g" /opt/scripts/renew_ssl.sh

# Dar permisos de ejecución
chmod +x /opt/scripts/renew_ssl.sh

# Agregar al crontab (ejecutar 2 veces al día)
(crontab -l 2>/dev/null; echo "0 0,12 * * * /opt/scripts/renew_ssl.sh") | crontab -

echo -e "${GREEN}✅ Renovación automática configurada (2 veces al día)${NC}"

# ============================================================
# PASO 9: Verificar que HTTPS funciona
# ============================================================
echo ""
echo -e "${GREEN}� Verificando que HTTPS funciona...${NC}"

sleep 5  # Esperar a que Apache se reinicie

# Verificar con curl
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "${GREEN}✅ HTTPS funcionando correctamente (código: $HTTP_CODE)${NC}"
else
    echo -e "${YELLOW}️  HTTPS respondió con código: $HTTP_CODE${NC}"
    echo "   Verifica manualmente: https://$DOMAIN"
fi

# ============================================================
# PASO 10: Mostrar información del certificado
# ============================================================
echo ""
echo -e "${GREEN}� Información del certificado:${NC}"
echo "   Dominio: $DOMAIN"
echo "   Ruta: /etc/letsencrypt/live/$DOMAIN/"
echo "   Expiración: $(sudo openssl x509 -in /etc/letsencrypt/live/$DOMAIN/cert.pem -noout -enddate | cut -d= -f2)"
echo ""

# ============================================================
# RESUMEN FINAL
# ============================================================
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ CONFIGURACIÓN SSL COMPLETADA${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "� Resumen:"
echo "   • Certificado SSL instalado para: $DOMAIN"
echo "   • HTTP redirige automáticamente a HTTPS"
echo "   • Renovación automática: 2 veces al día"
echo "   • Logs de renovación: /var/log/ssl_renewal.log"
echo ""
echo "� URLs:"
echo "   • HTTP:  http://$DOMAIN (redirige a HTTPS)"
echo "   • HTTPS: https://$DOMAIN"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   • Ejecuta este mismo script en WEB2"
echo "   • Asegúrate de que el dominio apunte al ALB, no a las EC2 directamente"
echo "   • Verifica el certificado en: https://www.ssllabs.com/ssltest/"
echo ""
echo -e "${GREEN}� ¡Todo listo!${NC}"
