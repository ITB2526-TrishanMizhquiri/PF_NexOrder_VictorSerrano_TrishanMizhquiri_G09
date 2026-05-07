# Documentación Técnica - Servicios Web y Seguridad Sprint 2
**Proyecto:** NexOrder Infrastructure  
**Autor:** Victor Serrano & Trishan Mizhquiri  
**Fecha:** 20 de abril 2026 - 26 de abril 2026  
**Criterios:** M0375 (Servicios de red), M0378 (Administración de servidores), C037 (Seguridad)

---

## 📋 Índice
1. [Arquitectura de Aplicación Web](#1-arquitectura-de-aplicación-web)
2. [T07: Servidor Web y PHP](#2-t07-servidor-web-y-php)
   - [2.1 Instalación de httpd y PHP](#21-instalación-de-httpd-y-php)
   - [2.2 Habilitación y Verificación](#22-habilitación-y-verificación)
3. [T08: SSL/TLS y Redirección HTTPS](#3-t08-ssltls-y-redirección-https)
   - [3.1 Generación de Certificado](#31-generación-de-certificado)
   - [3.2 Configuración VirtualHost y Redirección](#32-configuración-virtualhost-y-redirección)
   - [3.3 Resolución de Incidencias (Puerto 443)](#33-resolución-de-incidencias-puerto-443)
4. [T09: Protección SSH con Fail2ban](#4-t09-protección-ssh-con-fail2ban)
   - [4.1 Instalación y Configuración](#41-instalación-y-configuración)
   - [4.2 Verificación de Jail](#42-verificación-de-jail)
5. [T10: Control de Acceso MySQL](#5-t10-control-de-acceso-mysql)
   - [5.1 Creación de BD y Usuario](#51-creación-de-bd-y-usuario)
   - [5.2 Validación de Mínimo Privilegio](#52-validación-de-mínimo-privilegio)
6. [T11: Hardening del Servidor Web](#6-t11-hardening-del-servidor-web)
   - [6.1 Configuración de Cabeceras](#61-configuración-de-cabeceras)
   - [6.2 Verificación de Ocultación](#62-verificación-de-ocultación)
7. [T12: Capa de Validación Web (PHP+PDO)](#7-t12-capa-de-validación-web-phppdo)
   - [7.1 Creación de Archivos](#71-creación-de-archivos)
   - [7.2 Pruebas de Conectividad](#72-pruebas-de-conectividad)
8. [Justificación de Criterios](#8-justificación-de-criterios)
   - [8.1 M0375 – Servicios de Red](#81-m0375--servicios-de-red)
   - [8.2 M0378 – Administración de Servidores](#82-m0378--administración-de-servidores)
   - [8.3 C037 – Seguridad y Resiliencia](#83-c037--seguridad-y-resiliencia)

---

## 1. Arquitectura de Aplicación Web

### Diagrama Lógico de Servicios


![Diagrama Lógico](/img/sprint2/diagrama-logico.png)

> 📸 **Figura 0:** Diagrama Logico de la arquitectura de aplicación web`

---

## 2. T07: Servidor Web y PHP

### 2.1 Instalación de httpd y PHP
Actualización del sistema e instalación de paquetes base:
```bash
sudo dnf update -y
sudo dnf install -y httpd php
```
**Justificación:** `httpd` (Apache 2.4) actúa como servidor web principal, mientras que PHP 8.x permite la ejecución del lenguaje de programación de NexOrder.

![Instalación de httpd y PHP](/img/sprint2/07-install-httpd-php.png)

> 📸 **Figura 1:** Instalación de `httpd` y `php` mediante `dnf` en Amazon Linux 2023

### 2.2 Habilitación y Verificación
Habilitación del servicio para arranque automático y validación de puertos:
```bash
sudo systemctl enable httpd
sudo systemctl start httpd
sudo systemctl status httpd
sudo ss -tlnp | grep :80
curl localhost
```
**Resultado:** Servicio `active (running)`, escuchando en puerto `80`. Respuesta HTML de Apache por defecto.

![Estado y puerto de Apache](/img/sprint2/07-apache-status-port.png)

> 📸 **Figura 2:** Verificación de `systemctl status httpd` y puerto 80 activo

![Respuesta curl localhost](/img/sprint2/07-curl-localhost.png)

> 📸 **Figura 3:** Petición `curl localhost` respondiendo correctamente

---

## 3. T08: SSL/TLS y Redirección HTTPS

### 3.1 Generación de Certificado
Instalación de módulos y creación de certificado autofirmado válido por 365 días:
```bash
sudo dnf install -y mod_ssl openssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/pki/tls/private/nexorder.key \
  -out /etc/pki/tls/certs/nexorder.crt \
  -subj "/C=ES/ST=Madrid/L=Madrid/O=NexOrder/CN=44.207.176.14"
```

![Generación de certificado SSL](/img/sprint2/08-cert-gen.png)

> 📸 **Figura 4:** Generación de certificado autofirmado `nexorder.crt` y clave `nexorder.key`

### 3.2 Configuración VirtualHost y Redirección
Creación de archivo de configuración dedicado:
📄 **Archivo creado:** [`/docs/src/nexorder-ssl.conf`](/docs/src/nexorder-ssl.conf)

Contenido aplicado:
```apache
<VirtualHost *:80>
    ServerName localhost
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>

<VirtualHost *:443>
    ServerName localhost
    DocumentRoot /var/www/html
    SSLEngine on
    SSLCertificateFile /etc/pki/tls/certs/nexorder.crt
    SSLCertificateKeyFile /etc/pki/tls/private/nexorder.key
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
</VirtualHost>
```

![Configuración VirtualHost SSL](/img/sprint2/08-vhost-config.png)

> 📸 **Figura 5:** Archivo `nexorder-ssl.conf` con redirección 301 y cabecera HSTS

### 3.3 Resolución de Incidencias (Puerto 443)
Se detectó que Apache no escuchaba en 443. Solución aplicada:
```bash
echo 'LoadModule headers_module modules/mod_headers.so' | sudo tee -a /etc/httpd/conf.modules.d/00-base.conf
echo 'LoadModule rewrite_module modules/mod_rewrite.so' | sudo tee -a /etc/httpd/conf.modules.d/00-base.conf
sudo httpd -t && sudo systemctl restart httpd
sudo ss -tlnp | grep httpd
```

![Corrección módulos Apache](/img/sprint2/08-fix-modules.png)

> 📸 **Figura 6:** Inclusión de `mod_headers` y `mod_rewrite` para habilitar SSL y redirección

![Verificación puertos 80 y 443](/img/sprint2/08-ports-80-443.png)

> 📸 **Figura 7:** `ss -tlnp` confirmando escucha simultánea en puertos 80 y 443

---

## 4. T09: Protección SSH con Fail2ban

### 4.1 Instalación y Configuración
```bash
sudo dnf install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo nano /etc/fail2ban/jail.local
```
📄 **Archivo creado:** [`/docs/src/jail.local`](/docs/src/jail.local)

Contenido de `jail.local`:
```ini
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/secure
maxretry = 3
bantime = 1h
```

![Configuración fail2ban jail.local](/img/sprint2/09-jail-config.png)

> 📸 **Figura 8:** Archivo `jail.local` con regla `sshd` (3 intentos, bloqueo 1h)

### 4.2 Verificación de Jail
```bash
fail2ban-client status sshd
```
**Resultado:** `Status for the jail: sshd`, `Currently banned: 0`, monitoreando logs del sistema.

![Estado Fail2ban sshd](/img/sprint2/09-fail2ban-status.png)

> 📸 **Figura 9:** Validación de `fail2ban-client status sshd` con monitorización activa

---

## 5. T10: Control de Acceso MySQL

### 5.1 Creación de BD y Usuario
Conexión como `admin` y ejecución de bloque de hardening:
```sql
CREATE DATABASE IF NOT EXISTS nexorder_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'nexorder_app'@'%' IDENTIFIED WITH mysql_native_password BY 'N3x0r_App_2026!Secure';
GRANT SELECT, INSERT, UPDATE ON nexorder_db.* TO 'nexorder_app'@'%';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
SHOW GRANTS FOR 'nexorder_app'@'%';
```

![Creación de BD y usuario RDS](/img/sprint2/10-db-user-creation.png)

> 📸 **Figura 10:** Creación de `nexorder_db` y usuario `nexorder_app` desde terminal MySQL

### 5.2 Validación de Mínimo Privilegio
Prueba de conexión y verificación de restricciones:
```bash
mysql -h <ENDPOINT_RDS> -u nexorder_app -p
```
Dentro de MySQL:
```sql
USE nexorder_db;
CREATE TABLE test_fail(id INT); -- Debe fallar: ERROR 1142
```
**Resultado:** `ERROR 1142 (42000): CREATE command denied to user 'nexorder_app'@'%'`. Seguridad por capas validada.

![Verificación permisos y fallo CREATE](/img/sprint2/10-permissions-validation.png)

> 📸 **Figura 11:** `SHOW GRANTS` y prueba de `CREATE TABLE` fallida (ERROR 1142)

---

## 6. T11: Hardening del Servidor Web

### 6.1 Configuración de Cabeceras
Edición del archivo principal de configuración:
📄 **Archivo modificado:** [`/docs/src/httpd.conf`](/docs/src/httpd.conf)

Directivas añadidas al final del archivo:
```apache
ServerTokens Prod
ServerSignature Off
```
**Justificación:** Oculta la versión exacta de Apache en cabeceras HTTP y páginas de error, dificultando reconocimiento automático por atacantes.

![Hardening httpd.conf](/img/sprint2/11-httpd-conf.png)

> 📸 **Figura 12:** Añadir `ServerTokens Prod` y `ServerSignature Off` al final de `httpd.conf`

### 6.2 Verificación de Ocultación
```bash
sudo systemctl restart httpd
curl -I http://localhost
```
**Resultado:** Cabecera `Server: Apache` sin número de versión. Footer de errores 404 eliminado.

![Verificación cabeceras HTTP](/img/sprint2/11-curl-headers.png)

> 📸 **Figura 13:** `curl -I localhost` mostrando solo `Server: Apache` (sin versión)

---

## 7. T12: Capa de Validación Web (PHP+PDO)

### 7.1 Creación de Archivos
Despliegue de archivos de validación en `/var/www/html/`:
📄 **Archivos creados:** 
- [`/docs/src/index.php`](/docs/src/index.php) (Menú principal)
- [`/docs/src/connexio.php`](/docs/src/connexio.php) (Motor de conexión PDO)
- [`/docs/src/panel.php`](/docs/src/panel.php) (Panel de estado + consulta segura)

```bash
cd /var/www/html/
sudo touch index.php connexio.php panel.php
sudo chown apache:apache *.php
sudo chmod 644 *.php
```
**Propósito:** Validar conectividad segura, aplicación de `htmlspecialchars()` y `ATTR_EMULATE_PREPARES => false`.

![Creación de archivos PHP](/img/sprint2/12-files-created.png)

> 📸 **Figura 14:** Archivos creados en `/var/www/html/` con permisos `apache:apache` y `644`

### 7.2 Pruebas de Conectividad
Validación vía HTTPS forzado:
```bash
curl -k https://localhost/
curl -k https://localhost/connexio.php
curl -k https://localhost/panel.php
```
**Resultado:** 
- `index.php`: Muestra menú con enlaces y badges "HTTPS Activo"
- `connexio.php`: `✅ Conexión exitosa a RDS MySQL 8.0`
- `panel.php`: Tabla con versión MySQL, usuario conectado y BD activa

![Prueba connexio.php y panel.php](/img/sprint2/12-curl-validation.png)

> 📸 **Figura 15:** `curl -k` validando conectividad PDO y consulta segura desde PHP a RDS

---

## 8. Justificación de Criterios

### 8.1 M0375 – Servicios de Red
✅ **Cumplido:**
- Despliegue y configuración de servidor web Apache (puerto 80/443)
- Implementación de protocolo seguro TLS 1.2+ con redirección HTTP→HTTPS (301)
- Gestión de cabeceras de red (HSTS, ocultación de versión)
- Validación de conectividad de red mediante `curl` y `ss`

### 8.2 M0378 – Administración de Servidores
✅ **Cumplido:**
- Gestión de servicios con `systemctl` (enable, start, status, restart)
- Administración de paquetes con `dnf` (actualizaciones, instalación de módulos)
- Configuración de archivos de servicio (`httpd.conf`, `nexorder-ssl.conf`, `jail.local`)
- Monitoreo de estado de servicios y puertos activos

### 8.3 C037 – Seguridad y Resiliencia
✅ **Cumplido:**
- **Fail2ban:** Protección activa contra fuerza bruta SSH (3 intentos → 1h bloqueo)
- **SSL/TLS + HSTS:** Cifrado en tránsito y forzado de conexión segura en navegadores
- **Mínimo Privilegio (DB):** Usuario `nexorder_app` limitado a `SELECT/INSERT/UPDATE`. `CREATE/DROP` bloqueado (ERROR 1142)
- **Hardening Web:** `ServerTokens Prod` y `ServerSignature Off` para reducir superficie de ataque
- **Arquitectura Segura:** Capa PHP validada con PDO, `EMULATE_PREPARES => false` y sanitización `htmlspecialchars()`

---

**Documentación completada:** 20-26 de abril 2026  
**Responsable:** Victor Serrano & Trishan Mizhquiri  