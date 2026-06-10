#!/bin/bash
echo "� Iniciando script de aseguramiento de NexOrder..."

APP_DIR="/var/www/nexorder"
PUBLIC_DIR="$APP_DIR/public"

# 1. Asegurar que ec2-user pertenezca al grupo apache (para que puedas editar archivos sin sudo)
echo "� Agregando ec2-user al grupo apache..."
sudo usermod -a -G apache ec2-user

# 2. Unificar propietario y grupo a apache en TODA la estructura
echo "� Unificando propietario y grupo a apache..."
sudo chown -R apache:apache $APP_DIR

# 3. Establecer permisos base seguros
echo "� Aplicando permisos base (Directorios: 755, Archivos: 644)..."
sudo find $APP_DIR -type d -exec chmod 755 {} \;
sudo find $APP_DIR -type f -exec chmod 644 {} \;

# 4. Permisos específicos para carpetas que requieren escritura
echo "✍️  Dando permisos de escritura a tmp, logs y public..."
sudo chmod -R 775 $APP_DIR/tmp
sudo chmod -R 775 $APP_DIR/logs
sudo chmod -R 775 $PUBLIC_DIR # Necesario si subes imágenes o archivos desde la web

# 5. Máxima seguridad para la carpeta de configuración (si la usas en el futuro)
echo "�️  Asegurando carpeta config..."
sudo chmod 700 $APP_DIR/config

# 6. CORRECCIÓN DE SELINUX (Vital en Amazon Linux)
echo "�️  Ajustando etiquetas de seguridad de SELinux..."
sudo restorecon -Rv $APP_DIR
sudo chcon -R -t httpd_sys_content_t $APP_DIR
sudo chcon -R -t httpd_sys_rw_content_t $APP_DIR/tmp
sudo chcon -R -t httpd_sys_rw_content_t $APP_DIR/logs
sudo chcon -R -t httpd_sys_rw_content_t $PUBLIC_DIR

echo "✅ ¡Proceso completado con éxito!"
echo "⚠️  IMPORTANTE: Debes cerrar tu sesión SSH (escribe 'exit') y volver a conectarte para que el cambio de grupo surta efecto."
