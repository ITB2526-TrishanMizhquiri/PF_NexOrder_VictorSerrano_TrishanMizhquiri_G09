# Documentación Técnica – Servicios Web y Seguridad Sprint 2

**Proyecto:** NexOrder Infrastructure

**Autores:** Victor Serrano & Trishan Mizhquiri

**Fecha:** 20 de abril 2026 – 26 de abril 2026

**Módulos:** M0375 (Servicios de red) · M0378 (Administración de servidores) · C037 (Seguridad)

---

##  Índice

1. [Arquitectura de Aplicación Web](#1-arquitectura-de-aplicación-web)
2. [T07: Servidor Web y PHP](#2-t07-servidor-web-y-php)
   - [2.1 Instalación de httpd y PHP](#21-instalación-de-httpd-y-php)
   - [2.2 Habilitación y Verificación](#22-habilitación-y-verificación)
3. [T08: SSL/TLS y Redirección HTTPS](#3-t08-ssltls-y-redirección-https)
   - [3.1 Instalación de módulos SSL](#31-instalación-de-módulos-ssl)
   - [3.2 Generación de Certificado Autofirmado](#32-generación-de-certificado-autofirmado)
   - [3.3 Configuración VirtualHost y Redirección](#33-configuración-virtualhost-y-redirección)
   - [3.4 Resolución de Incidencias (Puerto 443)](#34-resolución-de-incidencias-puerto-443)
4. [T09: Protección SSH con Fail2ban](#4-t09-protección-ssh-con-fail2ban)
   - [4.1 Instalación y Activación](#41-instalación-y-activación)
   - [4.2 Configuración de Jail](#42-configuración-de-jail)
   - [4.3 Verificación de Estado](#43-verificación-de-estado)
5. [T10: Control de Acceso MySQL](#5-t10-control-de-acceso-mysql)
   - [5.1 Conexión como Administrador](#51-conexión-como-administrador)
   - [5.2 Hardening y Creación de Usuario](#52-hardening-y-creación-de-usuario)
   - [5.3 Validación de Mínimo Privilegio](#53-validación-de-mínimo-privilegio)
   - [5.4 Esquema de Base de Datos NexOrder](#54-esquema-de-base-de-datos-nexorder)
6. [T11: Hardening del Servidor Web](#6-t11-hardening-del-servidor-web)
   - [6.1 Configuración de Cabeceras](#61-configuración-de-cabeceras)
   - [6.2 Verificación de Ocultación](#62-verificación-de-ocultación)
7. [T12: Capa de Validación Web (PHP+PDO)](#7-t12-capa-de-validación-web-phppdo)
   - [7.1 Creación de Archivos PHP](#71-creación-de-archivos-php)
   - [7.2 Contenido de los Archivos](#72-contenido-de-los-archivos)
   - [7.3 Pruebas de Conectividad](#73-pruebas-de-conectividad)
   - [7.4 Resolución de Incidencia Firewalld](#74-resolución-de-incidencia-firewalld)
   - [7.5 Validación desde Navegador](#75-validación-desde-navegador)
8. [Justificación de Criterios](#8-justificación-de-criterios)
---

## 1. Arquitectura de Aplicación Web

El Sprint 2 construye la **capa de aplicación** sobre la infraestructura de red del Sprint 1. Los servicios desplegados forman una pila completa con seguridad en cada nivel:

![Figura 0](/img/sprint2/0-arquitectura-web.png)
sprint2
>  **Figura 0 – Arquitectura de servicios:** diagrama conceptual de la pila de aplicación web

---

## 2. T07: Servidor Web y PHP

### 2.1 Instalación de httpd y PHP

Se accede a la instancia `Web-NexOrder` vía SSH y se procede a actualizar el sistema antes de instalar cualquier paquete nuevo:

```bash
# Conectar a la instancia
ssh -i "NexOrder-SSH-Key.pem" ec2-user@52.90.85.X

# Actualizar repositorios y paquetes del sistema
sudo dnf update -y

# Instalar servidor web y motor PHP
sudo dnf install -y httpd php
```

**Versiones instaladas:**

| Paquete | Versión | Arquitectura | Repositorio |
|---------|---------|--------------|-------------|
| `httpd` | 2.4.66-1.amzn2023.0.1 | x86_64 | amazonlinux |
| `php8.5` | 8.5.4-1.amzn2023.0.1 | x86_64 | amazonlinux |

**¿Por qué estos dos paquetes juntos?** `httpd` (Apache 2.4) es el servidor web que gestiona las conexiones HTTP/HTTPS entrantes. PHP permite que Apache ejecute scripts del lado del servidor, que es el lenguaje con el que está desarrollada la aplicación NexOrder. Sin ambos, el servidor solo podría servir archivos estáticos.

![Figura 1](/img/sprint2/1-ssh-conexion.png)
>  **Figura 1** – Terminal con `ssh -i "NexOrder-SSH-Key.pem" ec2-user@52.90.85.X` conectando correctamente a Amazon Linux 2023

![Figura 2](/img/sprint2/2-dnf-update.png)
>  **Figura 2** – Salida de `sudo dnf update -y` mostrando `Complete!` con Amazon Linux 2023 Kernel Livepatch repository

![Figura 3](/img/sprint2/3-install-httpd-php.png)
>  **Figura 3** – Salida de `sudo dnf install -y httpd php` con las versiones `httpd 2.4.66` y `php8.5 8.5.4` instaladas

---

### 2.2 Habilitación y Verificación

Una vez instalado, se habilita el servicio para que arranque automáticamente con el sistema y se verifica su estado:

```bash
# Habilitar arranque automático al inicio del sistema
sudo systemctl start httpd
sudo systemctl enable httpd

# Verificar estado del servicio
sudo systemctl status httpd

# Verificar que escucha en el puerto 80
sudo ss -tlnp | grep :80

# Prueba de conectividad HTTP básica
curl localhost
```

**Resultado esperado:** `httpd.service` en estado `active (running)`, Main PID activo, escuchando en puerto 80. El `curl localhost` devuelve el HTML de bienvenida de Apache (`It works! Apache httpd`).

**Nota:** El mensaje `AH00558: httpd: Could not reliably determine the server's fully qualified domain name` en los logs es una advertencia cosmética sobre el `ServerName`; no afecta al funcionamiento y se suprimirá al configurar los VirtualHosts.

![Figura 4](/img/sprint2/4-start-httpd.png)
>  **Figura 4** – Terminal con `systemctl start httpd` y `systemctl enable httpd` creando el symlink de arranque automático

![Figura 5](/img/sprint2/5-status-httpd.png)
>  **Figura 5** – `systemctl status httpd` mostrando `active (running)` con PID 26333, puerto 80 en escucha

![Figura 6](/img/sprint2/6-curl-localhost.png)
>  **Figura 6** – `curl localhost` devolviendo `<!DOCTYPE HTML PUBLIC ... It works! Apache httpd`

---

## 3. T08: SSL/TLS y Redirección HTTPS

El objetivo de esta tarea es asegurar que **todo el tráfico hacia el servidor web viaje cifrado**. Se implementan tres capas: certificado TLS, VirtualHost SSL y redirección permanente HTTP→HTTPS.

### 3.1 Instalación de Módulos SSL

```bash
# Instalar módulo SSL de Apache y la herramienta openssl
sudo dnf install -y mod_ssl openssl
```

**Paquetes instalados:**

| Paquete | Versión | Tamaño |
|---------|---------|--------|
| `mod_ssl` | 1:2.4.66-1.amzn2023.0.1 | 111 k |
| `sscg` (dependencia) | 3.0.3-77.amzn2023 | 46 k |

![Figura 7](/img/sprint2/7-install-ssl.png)
>  **Figura 7** – Salida de `sudo dnf install -y mod_ssl openssl` con instalación correcta de `mod_ssl` y `sscg`

---

### 3.2 Generación de Certificado Autofirmado

Se genera un certificado X.509 autofirmado con clave RSA de 2048 bits, válido por 365 días:

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/pki/tls/private/nexorder.key \
  -out /etc/pki/tls/certs/nexorder.crt \
  -subj "/C=ES/ST=Madrid/L=Madrid/O=NexOrder/CN=44.207.176.14"
```

**Parámetros del certificado:**

| Campo | Valor |
|-------|-------|
| País (C) | ES |
| Estado (ST) | Madrid |
| Localidad (L) | Madrid |
| Organización (O) | NexOrder |
| Common Name (CN) | 44.207.176.14 |
| Clave privada | `/etc/pki/tls/private/nexorder.key` |
| Certificado | `/etc/pki/tls/certs/nexorder.crt` |
| Validez | 365 días |
| Algoritmo | RSA 2048 bits |

**¿Por qué autofirmado?** En un entorno de laboratorio o preproducción sin dominio DNS registrado, un certificado de Let's Encrypt no es viable (requiere dominio público). El certificado autofirmado proporciona cifrado TLS idéntico al de un certificado CA; la única diferencia es que los navegadores muestran una advertencia de confianza, lo que se acepta con `-k` en `curl` o añadiendo excepción en el navegador.

![Figura 8](/img/sprint2/8-generate-certs.png)
>  **Figura 8** – Terminal ejecutando el comando `openssl req -x509 ...` con salida de generación de clave y certificado

---

### 3.3 Configuración VirtualHost y Redirección

Se crea un archivo de configuración dedicado para separar la configuración SSL de la configuración base de Apache:

```bash
sudo nano /etc/httpd/conf.d/nexorder-ssl.conf
```
[Enllaç al documento: Configuración de Nexorder-ssl.conf](/docs/src/nexorder-ssl.conf)

**¿Qué hace cada directiva?**

- `RewriteEngine On` / `RewriteCond %{HTTPS} off` / `RewriteRule`: redirige automáticamente cualquier petición HTTP al equivalente HTTPS con un código 301 (redirección permanente, que los buscadores y navegadores cachean).
- `SSLEngine on`: activa el motor SSL para ese VirtualHost.
- `SSLCertificateFile` / `SSLCertificateKeyFile`: apuntan al certificado y clave generados en el paso anterior.
- `Strict-Transport-Security`: cabecera HSTS que instruye al navegador a nunca volver a usar HTTP para ese dominio durante `max-age` segundos (31.536.000 = 1 año). Previene ataques de downgrade.

![Figura 9](/img/sprint2/9-ssl-config.png)
>  **Figura 9** – Editor nano mostrando el contenido completo de `nexorder-ssl.conf` con ambos VirtualHost y la cabecera HSTS

Después de guardar, se verifica la sintaxis y se reinicia Apache:

```bash
sudo httpd -t && sudo systemctl restart httpd
```
![Figura 10](/img/sprint2/10-restart-httpd.png)
>  **Figura 10** – `sudo httpd -t && sudo systemctl restart httpd` con salida `Syntax OK` y servicio reiniciado

**Pruebas de redirección y HTTPS:**

```bash
# Verificar redirección HTTP→HTTPS (debe devolver 301)
curl -I http://localhost

# Verificar respuesta HTTPS y presencia de cabecera HSTS (debe devolver 200)
curl -Ik https://localhost
```

**Resultado de `curl -I http://localhost`:**
```
HTTP/1.1 301 Moved Permanently
Location: https://localhost/
Server: Apache
```

![Figura 11](/img/sprint2/11-redirect-http.png)
>  **Figura 11** – `curl -I http://localhost` devolviendo `HTTP/1.1 301 Moved Permanently` con `Location: https://localhost/`

**Resultado de `curl -Ik https://localhost`:**
```
HTTP/1.1 200 OK
Server: Apache
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

![Figura 12](/img/sprint2/12-https-working.png)
>  **Figura 12** – `curl -Ik https://localhost` devolviendo `200 OK` con cabecera `Strict-Transport-Security: max-age=31536000; includeSubDomains`

---

### 3.4 Resolución de Incidencias (Puerto 443)

Durante las pruebas se detectó que Apache no escuchaba en el puerto 443 porque los módulos `mod_headers` y `mod_rewrite` no estaban cargados. Solución aplicada:

```bash
# Añadir mod_headers (necesario para la directiva Header y HSTS)
echo 'LoadModule headers_module modules/mod_headers.so' | sudo tee -a \
  /etc/httpd/conf.modules.d/00-base.conf

# Verificar que mod_ssl está cargado correctamente
httpd -M | grep ssl_module

# Añadir mod_rewrite (necesario para la redirección HTTP→HTTPS)
echo 'LoadModule rewrite_module modules/mod_rewrite.so' | sudo tee -a \
  /etc/httpd/conf.modules.d/00-base.conf

# Verificar sintaxis de configuración
sudo httpd -t

# Reiniciar y verificar puertos activos (deben aparecer 80 Y 443)
sudo systemctl restart httpd
sudo ss -tlnp | grep httpd
```

**Resultado de `ss -tlnp | grep httpd`:**
```
LISTEN 0  511  *:80   *:*  users:(("httpd",pid=36204,...))
LISTEN 0  511  *:443  *:*  users:(("httpd",pid=36204,...))
```

![Figura 13](/img/sprint2/13-headers-module.png)
>  **Figura 13** – `echo 'LoadModule headers_module ...'` añadido correctamente a `00-base.conf`

![Figura 14](/img/sprint2/14-verificar.png)
>  **Figura 14** – Con `httpd -M | grep ssl_module` estamos confirmando `ssl_module (shared)`

![Figura 15](/img/sprint2/15-rewrite-module.png)
>  **Figura 15** – `echo 'LoadModule rewrite_module ...'` añadido correctamente

![Figura 16](/img/sprint2/16-syntax-ok.png)
>  **Figura 16** – `sudo httpd -t` devolviendo `Syntax OK`

![Figura 17](/img/sprint2/17-ss-tlnp.png)
>  **Figura 17** – `ss -tlnp | grep httpd` mostrando escucha simultánea en `*:80` y `*:443`

---

## 4. T09: Protección SSH con Fail2ban

Fail2ban es un servicio de prevención de intrusiones que monitoriza los logs del sistema en tiempo real. Cuando detecta un patrón de ataques (como múltiples intentos de login SSH fallidos), banea automáticamente la IP atacante mediante reglas de firewall temporales.

### 4.1 Instalación y Activación

```bash
# Instalar Fail2ban desde los repositorios de Amazon Linux
sudo dnf install -y fail2ban

# Habilitar e iniciar en un solo comando
sudo systemctl enable --now fail2ban
```

**Versión instalada:** `fail2ban 1.1.0-1.amzn2023.0.1` (noarch, 10k)

El flag `--now` de `systemctl enable` combina `enable` y `start` en un solo comando, creando el symlink de arranque automático e iniciando el servicio inmediatamente.

![Figura 18](/img/sprint2/18-install-fail2ban.png)
>  **Figura 18** – `sudo dnf install -y fail2ban` con instalación de `fail2ban 1.1.0-1.amzn2023.0.1`

![Figura 19](/img/sprint2/19-enable-fail2ban.png)
>  **Figura 19** – `sudo systemctl enable --now fail2ban` creando el symlink en `/usr/lib/systemd/system/fail2ban.service`

---

### 4.2 Configuración de Jail

Fail2ban lee su configuración de `/etc/fail2ban/jail.conf` (defaults) pero se sobreescribe con `/etc/fail2ban/jail.local` para que las actualizaciones del paquete no borren la configuración personalizada:

```bash
sudo nano /etc/fail2ban/jail.local
```

[Enllaç al documento: Configuración de Jail](/docs/src/jail.local)


| Parámetro | Valor | Significado |
|-----------|-------|-------------|
| `enabled` | `true` | Activa esta regla (jail) |
| `port` | `ssh` | Monitoriza el puerto 22 |
| `filter` | `sshd` | Usa el filtro predefinido para SSH |
| `logpath` | `/var/log/secure` | Archivo de log donde busca los intentos fallidos |
| `maxretry` | `3` | Número máximo de fallos antes del bloqueo |
| `bantime` | `1h` | Duración del bloqueo (1 hora) |

![Figura 20](/img/sprint2/20-jail-local.png)
>  **Figura 20** – Editor nano mostrando `/etc/fail2ban/jail.local` con las 4 directivas de la jail `[sshd]`

---

### 4.3 Verificación de Estado

```bash
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
```

**Resultado:**
```
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- Journal matches:  _SYSTEMD_UNIT=sshd.service + _COMM=sshd
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
```

**Interpretación de la salida:**
- **`Status for the jail: sshd`**: Fail2ban está monitorizando el servicio SSH activamente.
- **`Journal matches: _SYSTEMD_UNIT=sshd.service`**: el programa está conectado a los registros del sistema operativo (journald) y puede leer los eventos de SSH en tiempo real.
- **`Currently banned: 0`**: no hay ninguna IP bloqueada porque aún no se ha superado el umbral de 3 intentos fallidos. Este es el estado correcto en un servidor recién configurado.

![Figura 21](/img/sprint2/21-fail2ban-status.png)
>  **Figura 21** – `fail2ban-client status sshd` mostrando la jail activa con `Currently banned: 0` y `Journal matches` configurado

---

## 5. T10: Control de Acceso MySQL

El objetivo es implementar el **principio de mínimo privilegio** en la base de datos: la aplicación web solo tendrá los permisos estrictamente necesarios para operar, limitando el daño potencial en caso de brecha de seguridad.

### 5.1 Conexión como Administrador

Desde la EC2, se conecta a la instancia RDS usando el usuario `admin` creado durante el Sprint 1:

```bash
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u admin -p
# Contraseña: N3x0r-DB-2026!Sec
```

**Resultado:** `MySQL connection id is 100` → conexión exitosa a MySQL 8.0.40.

![Figura 22](/img/sprint2/22-mysql-login.png)
>  **Figura 22** – Terminal con login MySQL como `admin`, mostrando `connection id 100` y `Server version: 8.0.40`

---

### 5.2 Hardening y Creación de Usuario

Una vez dentro del prompt `mysql>`, se ejecuta el bloque completo de hardening:

```sql
-- 1. Crear la BD con charset seguro (evita problemas de encoding)
CREATE DATABASE IF NOT EXISTS nexorder_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- 2. Crear usuario de aplicación con plugin de autenticación compatible
CREATE USER 'nexorder_app'@'%'
  IDENTIFIED WITH mysql_native_password
  BY 'N3x0r_App_2026!Secure';

-- 3. Asignar SOLO los permisos necesarios (sin DELETE, DROP, ALTER, CREATE)
GRANT SELECT, INSERT, UPDATE ON nexorder_db.* TO 'nexorder_app'@'%';

-- 4. Limpieza: eliminar la BD de prueba por defecto (vector de ataque habitual)
DROP DATABASE IF EXISTS test;

-- 5. Aplicar cambios inmediatamente en memoria
FLUSH PRIVILEGES;

-- 6. Verificar que los permisos están correctamente asignados
SHOW GRANTS FOR 'nexorder_app'@'%';
```

**Resultado de `SHOW GRANTS`:**
```
+-----------------------------------------------------------------------+
| Grants for nexorder_app@%                                             |
+-----------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `nexorder_app`@`%`                             |
| GRANT SELECT, INSERT, UPDATE ON `nexorder_db`.* TO `nexorder_app`@`%`|
+-----------------------------------------------------------------------+
2 rows in set (0.00 sec)
```
![Figura 23](/img/sprint2/23-create-db-user.png)
>  **Figura 23** – `CREATE DATABASE`, `CREATE USER` y `GRANT SELECT, INSERT, UPDATE` ejecutados con `Query OK`

![Figura 24](/img/sprint2/24-drop-test-flush.png)
>  **Figura 24** – `DROP DATABASE test`, `FLUSH PRIVILEGES` y `SHOW GRANTS FOR 'nexorder_app'@'%'` con la tabla de permisos resultante

![Figura 25](/img/sprint2/25-show-grants.png)
>  **Figura 25** – Vista ampliada de `SHOW GRANTS` confirmando los dos grants: USAGE global + SELECT/INSERT/UPDATE en nexorder_db

---

### 5.3 Validación de Mínimo Privilegio

Se verifica que el usuario `nexorder_app` puede conectarse y operar dentro de sus permisos, pero no puede realizar operaciones destructivas:

```bash
# Conectar como el usuario de aplicación
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u nexorder_app -p
```
![Figura 26](/img/sprint2/26-login-nexorder.png)
>  **Figura 26** – Login MySQL como `nexorder_app` con `connection id 105`

Dentro de MySQL:

```sql
-- Seleccionar la BD (debe funcionar: tiene SELECT)
USE nexorder_db;

-- Intentar crear una tabla (DEBE FALLAR: no tiene CREATE)
CREATE TABLE prueba_fallo (id INT);
-- ERROR esperado: ERROR 1142 (42000): CREATE command denied
```

**Resultado obtenido:**
```
mysql> USE nexorder_db;
Database changed
mysql> CREATE TABLE prueba_fallo (id INT);
ERROR 1142 (42000): CREATE command denied to user 'nexorder_app'@'10.0.1.237' for table 'prueba_fallo'
```

Este error confirma que la seguridad por capas funciona. En un escenario de SQL Injection, un atacante que controle la aplicación PHP no podría borrar tablas, crear backdoors ni modificar la estructura de la base de datos.

![Figura 27](/img/sprint2/27-permission-denied.png)
>  **Figura 27** – `CREATE TABLE prueba_fallo` devolviendo `ERROR 1142 (42000): CREATE command denied`

---

### 5.4 Esquema de Base de Datos NexOrder

Con el usuario `admin`, se crea y ejecuta el esquema completo de la aplicación:

```bash
# Crear el archivo del esquema
sudo nano nexorder_schema.sql

[Enllaç al documento: Configuración de Nexorder_schema.sql](/docs/src/nexorder_schema.sql)

# Ejecutar el script contra RDS
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com \
  -u admin -p \
  nexorder_db < /home/ec2-user/nexorder_schema.sql
```
![Figura 28](/img/sprint2/28-schema-sql.png)
>  **Figura 28** – Editor nano mostrando `nexorder_schema.sql` con las primeras tablas (`estados`, `usuarios`)

![Figura 29](/img/sprint2/29-execute-schema.png)
>  **Figura 29** – Ejecución del script y salida tabulada con `SHOW TABLES`, conteo de registros y menú de productos

**Tablas creadas:**

| Tabla | Descripción | Filas iniciales |
|-------|-------------|-----------------|
| `estados` | Estados de pedido normalizados | 5 |
| `usuarios` | Clientes, cocina, admin | 2 |
| `productos` | Menú del restaurante | 7 |
| `pedidos` | Cabecera de pedidos | 0 |
| `detalle_pedidos` | Líneas de pedido (N:M) | 0 |

**Diseño notable:**
- Columna `subtotal` en `detalle_pedidos` es una **columna generada** (`GENERATED ALWAYS AS (cantidad * precio_unitario) STORED`): se calcula automáticamente, eliminando errores de consistencia.
- Todas las tablas usan `ENGINE=InnoDB` (soporte de transacciones y claves foráneas).
- Índices en columnas de búsqueda frecuente (`idx_username`, `idx_email`, `idx_categoria`, etc.).

```bash
# Verificar tablas creadas
mysql> use nexorder_db;
mysql> show tables;
mysql> DESCRIBE estados;
```
![Figura 30](/img/sprint2/30-describe-tables-1.png)
>  **Figura 30** – `SHOW TABLES` mostrando las 5 tablas + `DESCRIBE estados` y `DESCRIBE pedidos`

![Figura 31](/img/sprint2/31-describe-tables-2.png)
>  **Figura 31** – `DESCRIBE detalle_pedidos` con columna `subtotal STORED GENERATED` + `DESCRIBE usuarios` y `DESCRIBE productos`

![Figura 32](/img/sprint2/32-describe-tables-3.png)
>  **Figura 32** – `DESCRIBE pedidos` completo con claves foráneas y `DESCRIBE productos` con el ENUM de categorías

---

## 6. T11: Hardening del Servidor Web

Apache, por defecto, incluye en sus cabeceras HTTP y páginas de error información detallada sobre su versión y el sistema operativo subyacente. Esta información es un regalo para un atacante que quiera buscar vulnerabilidades conocidas para esa versión exacta.

### 6.1 Configuración de Cabeceras

Se edita el archivo de configuración principal de Apache:

```bash
sudo nano /etc/httpd/conf/httpd.conf
```
![Figura 33](/img/sprint2/33-httpd-conf-start.png)
>  **Figura 33** – Editor nano con el inicio de `/etc/httpd/conf/httpd.conf` (archivo principal de configuración)

Al final del archivo se añaden dos directivas:

```apache
ServerTokens Prod
ServerSignature Off
```

**¿Qué hace cada directiva?**

- **`ServerTokens Prod`**: controla qué información se incluye en la cabecera `Server:` de cada respuesta HTTP. Con el valor `Prod`, solo se envía `Apache` (sin versión, sin OS, sin módulos). Por defecto enviaría algo como `Apache/2.4.66 (Amazon Linux) OpenSSL/3.5.5 PHP/8.5.4`.
- **`ServerSignature Off`**: elimina el pie de página que Apache añade a las páginas de error generadas automáticamente (404, 403, 500...), que mostraría la versión del servidor y el hostname.

![Figura 34](/img/sprint2/34-httpd-conf-end.png)
>  **Figura 34** – Final del archivo con `ServerTokens Prod` y `ServerSignature Off` añadidos y guardados

---

### 6.2 Verificación de Ocultación

```bash
sudo systemctl restart httpd
curl -I http://localhost
```

**Resultado:**
```
HTTP/1.1 403 Forbidden
Server: Apache
```

La cabecera `Server:` muestra únicamente `Apache`, sin número de versión, módulos ni sistema operativo. Un atacante que haga reconocimiento no podrá determinar qué versión exacta usar para sus exploits.

![Figura 35](/img/sprint2/35-server-tokens.png)
>  **Figura 35** – `curl -I localhost` devolviendo `Server: Apache` (sin versión) con código `403 Forbidden` (normal, sin index)

---

## 7. T12: Capa de Validación Web (PHP+PDO)

Se despliegan tres archivos PHP en el `DocumentRoot` de Apache para validar de extremo a extremo la conectividad segura entre la capa web y la capa de datos.

### 7.1 Creación de Archivos PHP

```bash
# Posicionarse en el directorio web de Apache
cd /var/www/html/

# Crear los tres archivos vacíos
sudo touch index.php connexio.php panel.php

# Asignar al usuario del proceso Apache (principio de mínimo privilegio en OS)
sudo chown apache:apache *.php

# Permisos: lectura para todos, escritura solo para propietario (apache)
sudo chmod 644 *.php
```

**¿Por qué `chown apache:apache`?** Apache ejecuta sus workers como el usuario `apache`. Si los archivos pertenecieran a `root` o `ec2-user`, el proceso de Apache no podría leerlos correctamente en ciertas configuraciones de seguridad de SELinux/AppArmor.

![Figura 36](/img/sprint2/36-create-php-files.png)
> **Figura 36** – Terminal ejecutando `touch`, `chown apache:apache *.php` y `chmod 644 *.php` en `/var/www/html/`

---

### 7.2 Contenido de los Archivos

#### `connexio.php` — Motor de conexión PDO

Archivo de prueba de conectividad que valida la conexión PDO a RDS con manejo de errores completo:

[Enllaç al documento: Connexio.php](/docs/src/connexio.php)

**Prácticas de seguridad aplicadas:**
- `ATTR_EMULATE_PREPARES => false`: fuerza el uso de sentencias preparadas reales en el servidor MySQL, lo que previene inyecciones SQL (el driver no construye el SQL en el cliente).
- `htmlspecialchars()` en todos los outputs: previene XSS (Cross-Site Scripting) convirtiendo `<`, `>`, `"`, `'` en sus equivalentes HTML.
- `ERRMODE_EXCEPTION`: los errores de BD lanzan excepciones capturables, nunca se muestran en crudo.

![Figura 37](/img/sprint2/37-connexio-php.png)
>  **Figura 37** – Editor nano con el contenido completo de `connexio.php` incluyendo el bloque PDO con opciones de seguridad

#### `index.php` — Página principal

Página de menú estático con badges de estado y enlaces a los archivos de validación. Incluye el badge `HTTPS Activo` que confirma visualmente que el certificado SSL está activo.

[Enllaç al documento: Index.php](/docs/src/index.php)

![Figura 38](/img/sprint2/38-index-php.png)
>  **Figura 38** – Editor nano con el contenido completo de `index.php` (HTML con badge `HTTPS Activo` y tarjetas de características)

#### `panel.php` — Panel de estado y consulta segura

Panel de validación funcional que ejecuta una consulta PDO segura para mostrar la versión de MySQL, el usuario conectado y la base de datos activa:

[Enllaç al documento: Panel.php](/docs/src/panel.php)

![Figura 39](/img/sprint2/39-panel-php.png)
>  **Figura 39** – Editor nano con el contenido completo de `panel.php` incluyendo la conexión PDO y la tabla HTML de estado

---

### 7.3 Pruebas de Conectividad

Se verifica el stack completo desde la línea de comandos:

```bash
# 1. Verificar que PHP está disponible para Apache
php -v

# 2. Probar index.php vía HTTPS (forzado con -k para aceptar certificado autofirmado)
curl -k https://localhost/

# 3. Probar connexio.php (validación PDO a RDS)
curl -k https://localhost/connexio.php

# 4. Probar panel.php (consulta segura con PDO)
curl -k https://localhost/panel.php
```

**Resultados:**

| Endpoint | Resultado |
|----------|-----------|
| `php -v` | PHP 8.5.4 (cli), Zend Engine v4.5.4 |
| `curl -k https://localhost/` | HTML de `index.php` con `NexOrder HTTPS Activo` |
| `curl -k https://localhost/connexio.php` | ` Conexión exitosa a RDS MySQL 8.0` |
| `curl -k https://localhost/panel.php` | Tabla con versión MySQL, usuario y BD activa |

![Figura 40](/img/sprint2/40-php-version.png)
>  **Figura 40** – `php -v` mostrando `PHP 8.5.4 (cli)` con Zend Engine v4.5.4

![Figura 41](/img/sprint2/41-curl-index.png)
>  **Figura 41** – `curl -k https://localhost/` devolviendo el HTML de `index.php` con badge `HTTPS Activo`

![Figura 42](/img/sprint2/42-curl-connexio.png)
>  **Figura 42** – `curl -k https://localhost/connexio.php` mostrando ` Conexión exitosa a RDS MySQL 8.0`

![Figura 43](/img/sprint2/43-curl-panel.png)
>  **Figura 43** – `curl -k https://localhost/panel.php` devolviendo la tabla de estado (primer intento muestra error de driver PDO que se resolvió después)

---

### 7.4 Resolución de Incidencia Firewalld

Durante las pruebas desde IP pública se detectó que `firewalld` estaba bloqueando los puertos 80 y 443 a nivel de sistema operativo (distinto de los Security Groups de AWS):

```bash
# Permitir tráfico HTTP (puerto 80) de forma permanente
sudo firewall-cmd --permanent --add-service=http

# Permitir tráfico HTTPS (puerto 443) de forma permanente
sudo firewall-cmd --permanent --add-service=https

# Aplicar cambios sin reiniciar el servicio
sudo firewall-cmd --reload

# Verificar que los servicios están correctamente registrados
sudo firewall-cmd --list-all
```

**Salida de `--list-all` tras la corrección:**
```
public
  target: default
  services: dhcpv6-client http https mdns ssh
  ...
```
![Figura 44](/img/sprint2/44-firewall-cmd.png)
>  **Figura 44** – Ejecución de los cuatro comandos `firewall-cmd` con salidas `success` y `--list-all` mostrando `services: dhcpv6-client http https mdns ssh`

---

### 7.5 Validación desde Navegador

Prueba final desde IP pública accediendo directamente con el navegador:

```bash
# Prueba desde la propia EC2 usando IP pública dinámica
curl -k https://$(curl -s https://checkip.amazonaws.com)/index.php

# Prueba de redirección HTTP→HTTPS
curl -L http://localhost/index.php | head -10
```
![Figura 45](/img/sprint2/45-curl-public.png)
> 📸 **Figura 45** – `curl -k https://$(curl -s https://checkip.amazonaws.com)/index.php` devolviendo el HTML correcto de `index.php`

![Figura 46](/img/sprint2/46-curl-redirect.png)
>  **Figura 46** – `curl -L http://localhost/index.php | head -10` (muestra advertencia SSL por hostname 'localhost' vs CN '44.207.176.14')

URL de acceso desde navegador externo:
```
https://44.207.176.14/index.php
```

**Resultado:** La página `index.php` carga correctamente en el navegador con el badge `HTTPS Activo` y las dos tarjetas de características técnicas. El candado muestra "No seguro" porque es un certificado autofirmado (esperado).

![Figura 47](/img/sprint2/47-chrome-nexorder.png)
> 📸 **Figura 47** – Navegador Chrome cargando `https://44.207.176.14/index.php` con la interfaz completa de NexOrder y badge `HTTPS Activo`

---

## 8. Justificación de Criterios

### 8.1 M0375 – Servicios de Red

| Evidencia | Tarea | Estado |
|-----------|-------|--------|
| Despliegue de Apache 2.4 en puerto 80/443 | T07, T08 | ✅ |
| Implementación de TLS 1.2+ con certificado RSA 2048 | T08 | ✅ |
| Redirección HTTP→HTTPS con código 301 permanente | T08 | ✅ |
| Cabecera HSTS (`max-age=31536000; includeSubDomains`) | T08 | ✅ |
| Validación de conectividad con `curl` y `ss` | T07, T08, T12 | ✅ |
| Apertura controlada de puertos con `firewall-cmd` | T12 | ✅ |

### 8.2 M0378 – Administración de Servidores

| Evidencia | Tarea | Estado |
|-----------|-------|--------|
| Gestión de servicios con `systemctl` (enable/start/status/restart) | T07, T09 | ✅ |
| Instalación y gestión de paquetes con `dnf` | T07, T08, T09 | ✅ |
| Configuración de Apache (`httpd.conf`, `nexorder-ssl.conf`) | T08, T11 | ✅ |
| Monitoreo de puertos activos con `ss -tlnp` | T07, T08 | ✅ |
| Despliegue y gestión de archivos web con permisos correctos | T12 | ✅ |
| Resolución de incidencias (módulos Apache, firewalld) | T08, T12 | ✅ |

### 8.3 C037 – Seguridad y Resiliencia

| Evidencia | Tarea | Mecanismo |
|-----------|-------|-----------|
| Fail2ban activo: bloqueo tras 3 intentos SSH fallidos, ban 1h | T09 | Prevención fuerza bruta |
| SSL/TLS + HSTS: cifrado en tránsito y protección downgrade | T08 | Protección de canal |
| Mínimo privilegio DB: `nexorder_app` sin CREATE/DROP/DELETE | T10 | Contención de daños |
| `ServerTokens Prod` + `ServerSignature Off` | T11 | Reducción de superficie de ataque |
| PDO con `EMULATE_PREPARES => false` y `htmlspecialchars()` | T12 | Prevención SQLi y XSS |
| Certificado autofirmado RSA 2048, validez controlada | T08 | Integridad de comunicaciones |

---

*Documentación completada: 20–26 de abril de 2026*

*Autores: Victor Serrano · Trishan Mizhquiri*
