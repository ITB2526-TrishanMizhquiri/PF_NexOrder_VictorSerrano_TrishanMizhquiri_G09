#!/bin/bash
# =========================================================
# SCRIPT DE REPARACIÓN - NexOrder (Soluciona Error 500)
# =========================================================

APP_DIR="/var/www/nexorder"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}� Iniciando reparación de NexOrder...${NC}"

# 1. Verificar que el directorio existe
if [ ! -d "$APP_DIR" ]; then
    echo -e "${RED}❌ Error: El directorio $APP_DIR no existe.${NC}"
    exit 1
fi

# 2. Corregir Propietario y Permisos
echo -e "${YELLOW}� Corrigiendo propietario y permisos...${NC}"
sudo chown -R apache:apache "$APP_DIR"
sudo find "$APP_DIR" -type d -exec chmod 755 {} \;
sudo find "$APP_DIR" -type f -exec chmod 644 {} \;

# Permisos especiales para la carpeta config (más restrictiva)
sudo chmod 750 "$APP_DIR/config"
sudo chmod 640 "$APP_DIR/config/.env" 2>/dev/null

# Permisos de escritura para logs y tmp
sudo chmod -R 775 "$APP_DIR/logs" 2>/dev/null
sudo chmod -R 775 "$APP_DIR/tmp" 2>/dev/null

# 3. Corregir Contextos de SELinux (Crítico en Amazon Linux)
echo -e "${YELLOW}�️ Corrigiendo contextos de SELinux...${NC}"
sudo restorecon -Rv "$APP_DIR"
sudo chcon -R -t httpd_sys_content_t "$APP_DIR"
sudo chcon -R -t httpd_sys_rw_content_t "$APP_DIR/logs" 2>/dev/null
sudo chcon -R -t httpd_sys_rw_content_t "$APP_DIR/tmp" 2>/dev/null

# 4. Habilitar visualización de errores PHP (Para depurar si sigue fallando)
echo -e "${YELLOW}� Habilitando visualización de errores PHP...${NC}"
sudo sed -i 's/^display_errors = Off/display_errors = On/' /etc/php.ini
sudo sed -i 's/^display_errors = On/display_errors = On/' /etc/php.ini
sudo sed -i 's/^error_reporting = .*/error_reporting = E_ALL/' /etc/php.ini

# 5. Verificar sintaxis de los archivos PHP principales
echo -e "${YELLOW}� Verificando sintaxis PHP...${NC}"
sudo php -l "$APP_DIR/public/index.php"
sudo php -l "$APP_DIR/app/db.php"
sudo php -l "$APP_DIR/app/auth.php"

# 6. Reiniciar Apache
echo -e "${YELLOW}� Reiniciando Apache...${NC}"
sudo systemctl restart httpd

echo -e "${GREEN}✅ Reparación completada.${NC}"
echo -e "${GREEN}� Ahora recarga la página en tu navegador.${NC}"
echo -e "${YELLOW}⚠️ Si sigue dando error 500, ahora verás el mensaje exacto de PHP en la pantalla.${NC}"

