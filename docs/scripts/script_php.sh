#!/bin/bash
echo "� Configurando php.ini para producción segura..."

# Backup del archivo original por seguridad
sudo cp /etc/php.ini /etc/php.ini.backup_$(date +%F)

# 1. Ocultar que PHP está instalado (seguridad)
sudo sed -i 's/^expose_php = On/expose_php = Off/' /etc/php.ini

# 2. Asegurar que display_errors esté Off (ya lo está, pero por seguridad)
sudo sed -i 's/^display_errors = Off/display_errors = Off/' /etc/php.ini
sudo sed -i 's/^display_errors = On/display_errors = Off/' /etc/php.ini

# 3. Asegurar que log_errors esté On (ya lo está)
sudo sed -i 's/^log_errors = Off/log_errors = On/' /etc/php.ini

# 4. Aumentar upload_max_filesize de 2M a 5M
sudo sed -i 's/^upload_max_filesize = 2M/upload_max_filesize = 5M/' /etc/php.ini

# 5. Asegurar que post_max_size esté en 8M (ya lo está)
sudo sed -i 's/^post_max_size = 8M/post_max_size = 8M/' /etc/php.ini

# 6. Habilitar session.cookie_httponly (protege contra XSS)
sudo sed -i 's/^session.cookie_httponly =$/session.cookie_httponly = 1/' /etc/php.ini
sudo sed -i 's/^session.cookie_httponly =/session.cookie_httponly = 1/' /etc/php.ini

# 7. Habilitar session.cookie_secure (requiere HTTPS)
sudo sed -i 's/^;session.cookie_secure =$/session.cookie_secure = 1/' /etc/php.ini
sudo sed -i 's/^;session.cookie_secure =/session.cookie_secure = 1/' /etc/php.ini

# 8. Habilitar session.use_strict_mode (protege contra session fixation)
sudo sed -i 's/^session.use_strict_mode = 0/session.use_strict_mode = 1/' /etc/php.ini

echo "✅ Todos los cambios aplicados correctamente!"
echo "� Backup guardado en: /etc/php.ini.backup_$(date +%F)"
echo "� Reiniciando Apache para aplicar cambios..."
sudo systemctl restart httpd
echo "✅ ¡Apache reiniciado! Los cambios ya están activos."
