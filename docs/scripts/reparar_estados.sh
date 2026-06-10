#!/bin/bash
# =========================================================
# SCRIPT DE DIAGNÓSTICO Y REPARACIÓN - Tabla estados
# =========================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔍 Diagnóstico de tabla estados${NC}"
echo "======================================"

# =========================================================
# PASO 1: Ver estructura real de tabla estados
# =========================================================
echo -e "${YELLOW}[1/3] Obteniendo estructura de tabla estados...${NC}"

mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com \
      -u nexorder_app -p'N3x0r-DB-2026!Sec' \
      nexorder_db -e "DESCRIBE estados;"

echo ""
echo "--- Datos en tabla estados ---"
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com \
      -u nexorder_app -p'N3x0r-DB-2026!Sec' \
      nexorder_db -e "SELECT * FROM estados;"

# =========================================================
# PASO 2: Detectar nombre correcto de columna
# =========================================================
echo -e "${YELLOW}[2/3] Detectando columna de nombre...${NC}"

COL_NOMBRE=$(mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com \
             -u nexorder_app -p'N3x0r-DB-2026!Sec' \
             nexorder_db -N -e "SELECT column_name FROM information_schema.columns WHERE table_schema='nexorder_db' AND table_name='estados' AND column_name LIKE '%nombre%' OR column_name LIKE '%name%' OR column_name LIKE '%estado%';" | head -1)

if [ -z "$COL_NOMBRE" ]; then
    COL_NOMBRE="nombre"  # Default
fi

echo "Columna detectada: $COL_NOMBRE"

# =========================================================
# PASO 3: Actualizar todos los archivos PHP
# =========================================================
echo -e "${YELLOW}[3/3] Actualizando archivos PHP...${NC}"

# Actualizar pedido.php
sudo sed -i "s/e\.nombre_estado/e.$COL_NOMBRE/g" /var/www/nexorder/public/pedido.php
sudo sed -i "s/e\.nombre_estado/e.$COL_NOMBRE/g" /var/www/nexorder/public/cocina.php
sudo sed -i "s/e\.nombre_estado/e.$COL_NOMBRE/g" /var/www/nexorder/public/admin.php

# También actualizar en el HTML/PHP donde se use
sudo sed -i "s/\[\"nombre_estado\"\]/[\"$COL_NOMBRE\"]/g" /var/www/nexorder/public/pedido.php
sudo sed -i "s/\[\"nombre_estado\"\]/[\"$COL_NOMBRE\"]/g" /var/www/nexorder/public/cocina.php
sudo sed -i "s/\[\"nombre_estado\"\]/[\"$COL_NOMBRE\"]/g" /var/www/nexorder/public/admin.php

sudo sed -i "s/p\[\"nombre_estado\"\]/p[\"$COL_NOMBRE\"]/g" /var/www/nexorder/public/admin.php

echo "✅ Archivos actualizados"

# Reiniciar Apache
sudo systemctl restart httpd

echo ""
echo -e "${GREEN}✅ REPARACIÓN COMPLETADA${NC}"
echo "================================"
echo ""
echo "📋 Columna corregida: $COL_NOMBRE"
echo ""
echo "🔗 Prueba ahora:"
echo "   https://44.207.176.14/pedido.php"
echo "   https://44.207.176.14/cocina.php"
echo "   https://44.207.176.14/admin.php"
