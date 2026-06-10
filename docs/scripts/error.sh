#!/bin/bash
# =========================================================
# SCRIPT DE LIMPIEZA COMPLETA - Apache (Versión Robusta)
# =========================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}� LIMPIEZA DE APACHE - Versión Robusta${NC}"
echo "=============================================="

# =========================================================
# PASO 1: Configurar ServerName
# =========================================================
echo -e "${YELLOW}[1/6] Configurando ServerName...${NC}"

IP_PUBLICA=$(curl -s --connect-timeout 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
if [ -z "$IP_PUBLICA" ]; then
    IP_PUBLICA=$(hostname -I | awk '{print $1}')
fi
if [ -z "$IP_PUBLICA" ]; then
    IP_PUBLICA="localhost"
fi

sudo tee /etc/httpd/conf.d/servername.conf > /dev/null <<EOF
ServerName $IP_PUBLICA
EOF

echo "✅ ServerName: $IP_PUBLICA"

# =========================================================
# PASO 2: Configurar SSLSessionCache
# =========================================================
echo -e "${YELLOW}[2/6] Configurando SSLSessionCache...${NC}"

sudo tee /etc/httpd/conf.d/sslsession.conf > /dev/null <<'EOF'
SSLSessionCache shmcb:/var/cache/mod_ssl/scache(512000)
SSLSessionCacheTimeout 300
EOF

sudo mkdir -p /var/cache/mod_ssl
sudo chown apache:apache /var/cache/mod_ssl
sudo chmod 700 /var/cache/mod_ssl

echo "✅ SSLSessionCache configurado"

# =========================================================
# PASO 3: Desactivar heartbeat
# =========================================================
echo -e "${YELLOW}[3/6] Desactivando módulo heartbeat...${NC}"

for file in /etc/httpd/conf.modules.d/*.conf; do
    if [ -f "$file" ]; then
        sudo sed -i 's/^LoadModule lbmethod_heartbeat_module/#LoadModule lbmethod_heartbeat_module/' "$file" 2>/dev/null || true
    fi
done

echo "✅ Heartbeat desactivado"

# =========================================================
# PASO 4: Regenerar certificado SSL (compatible con todas las versiones)
# =========================================================
echo -e "${YELLOW}[4/6] Regenerando certificado SSL...${NC}"

sudo mkdir -p /etc/pki/tls/private
sudo mkdir -p /etc/pki/tls/certs

# Generar certificado sin opciones problemáticas
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/pki/tls/private/nexorder.key \
    -out /etc/pki/tls/certs/nexorder.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=NexOrder/OU=IT/CN=$IP_PUBLICA" 2>/dev/null

if [ $? -eq 0 ]; then
    sudo chmod 600 /etc/pki/tls/private/nexorder.key
    sudo chmod 644 /etc/pki/tls/certs/nexorder.crt
    sudo chown root:root /etc/pki/tls/private/nexorder.key
    sudo chown root:root /etc/pki/tls/certs/nexorder.crt
    echo "✅ Certificado SSL regenerado"
else
    echo "⚠️  Error al generar certificado, continuando..."
fi

# Actualizar configuración SSL
for file in /etc/httpd/conf.d/*.conf; do
    if grep -q "SSLCertificateFile" "$file" 2>/dev/null; then
        sudo sed -i 's|^SSLCertificateFile .*|SSLCertificateFile /etc/pki/tls/certs/nexorder.crt|' "$file"
        sudo sed -i 's|^SSLCertificateKeyFile .*|SSLCertificateKeyFile /etc/pki/tls/private/nexorder.key|' "$file"
    fi
done

# =========================================================
# PASO 5: Verificar configuración
# =========================================================
echo -e "${YELLOW}[5/6] Verificando configuración...${NC}"

sudo httpd -t
if [ $? -eq 0 ]; then
    echo "✅ Configuración válida"
else
    echo "❌ Error en configuración"
    exit 1
fi

# =========================================================
# PASO 6: Limpiar logs y reiniciar
# =========================================================
echo -e "${YELLOW}[6/6] Reiniciando Apache...${NC}"

sudo truncate -s 0 /var/log/httpd/error_log 2>/dev/null || true
sudo systemctl restart httpd

sleep 2

if systemctl is-active --quiet httpd; then
    echo -e "${GREEN}✅ Apache reiniciado correctamente${NC}"
else
    echo -e "${YELLOW}⚠️  Apache no se inició correctamente${NC}"
fi

# =========================================================
# VERIFICACIÓN
# =========================================================
echo ""
echo -e "${GREEN}✅ LIMPIEZA COMPLETADA${NC}"
echo "================================"
echo ""
echo "� Verifica los nuevos logs:"
echo "   sudo tail -10 /var/log/httpd/error_log"
echo ""
echo "� Ahora solo deberían aparecer mensajes normales:"
echo "   - [suexec:notice]"
echo "   - [systemd:notice]"
echo "   - [mpm_event:notice]"
echo "   - [core:notice]"
