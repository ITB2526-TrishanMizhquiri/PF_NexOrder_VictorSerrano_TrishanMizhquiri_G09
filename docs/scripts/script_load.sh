#!/bin/bash
echo "=== DIAGNÓSTICO COMPLETO ==="
echo ""

# 1. Apache
echo "1. Apache:"
sudo systemctl is-active httpd
echo ""

# 2. Puerto 80
echo "2. Puerto 80 escuchando:"
sudo ss -tlnp | grep :80 || echo "NO ESCUCHANDO"
echo ""

# 3. Respuesta local
echo "3. Respuesta HTTP local:"
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost/
echo ""

# 4. Respuesta detallada
echo "4. Headers de respuesta:"
curl -s -I http://localhost/ | head -5
echo ""

# 5. DocumentRoot
echo "5. DocumentRoot configurado:"
sudo grep -h "DocumentRoot" /etc/httpd/conf.d/*.conf 2>/dev/null | grep -v "^#"
echo ""

# 6. Index existe
echo "6. Archivo index.php:"
ls -la /var/www/nexorder/public/index.php 2>/dev/null || echo "NO EXISTE"
echo ""

# 7. Permisos
echo "7. Permisos de la carpeta public:"
ls -ld /var/www/nexorder/public/
echo ""

# 8. SELinux
echo "8. Estado SELinux:"
getenforce
echo ""

# 9. Firewall
echo "9. Firewall (iptables):"
sudo iptables -L -n | grep -E "80|http" | head -3 || echo "Sin reglas específicas"
echo ""

# 10. IP Privada
echo "10. IP Privada:"
hostname -I
