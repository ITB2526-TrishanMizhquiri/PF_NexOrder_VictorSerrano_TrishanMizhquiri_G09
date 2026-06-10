# Documentación Técnica Completa - NexOrder Infrastructure

**Proyecto:** NexOrder Infrastructure  
**Autores:** Victor Serrano & Trishan Mizhquiri  
**Período:** 13 de abril 2026 – 12 de mayo 2026  
**Módulos:** M0370, M0369, M0375, M0378, M0374, M0377, C037

**Propósito:** Documento de referencia técnica completa que integra infraestructura VPC, servicios web, seguridad, monitorización y resiliencia.

---

## 📋 Índice General

### [Sprint 1: Infraestructura VPC](#sprint-1-infraestructura-vpc)
1. [Arquitectura de Red](#1-arquitectura-de-red)
2. [TA01: VPC y Subredes](#2-ta01-vpc-y-subredes)
3. [TA02: Internet Gateway y Enrutamiento](#3-ta02-internet-gateway-y-enrutamiento)
4. [TA03: Instancias EC2 y RDS](#4-ta03-instancias-ec2-y-rds)
5. [TA04: Security Groups](#5-ta04-security-groups)
6. [TA05: Hardening del Sistema](#6-ta05-hardening-del-sistema)
7. [Verificación Final de Conectividad](#7-verificación-final-de-conectividad)

### [Sprint 2: Servicios Web y Seguridad](#sprint-2-servicios-web-y-seguridad)
8. [Arquitectura de Aplicación Web](#8-arquitectura-de-aplicación-web)
9. [T07: Servidor Web y PHP](#9-t07-servidor-web-y-php)
10. [T08: SSL/TLS y Redirección HTTPS](#10-t08-ssltls-y-redirección-https)
11. [T09: Protección SSH con Fail2ban](#11-t09-protección-ssh-con-fail2ban)
12. [T10: Control de Acceso MySQL](#12-t10-control-de-acceso-mysql)
13. [T11: Hardening del Servidor Web](#13-t11-hardening-del-servidor-web)
14. [T12: Capa de Validación Web (PHP+PDO)](#14-t12-capa-de-validación-web-phppdo)

### [Sprint 3: Monitorización y Resiliencia](#sprint-3-monitorización-y-resiliencia)
15. [Arquitectura de Monitorización y Resiliencia](#15-arquitectura-de-monitorización-y-resiliencia)
16. [T13: Script de Backup Automatizado](#16-t13-script-de-backup-automatizado)
17. [T14: Programación con Cron](#17-t14-programación-con-cron)
18. [T15: Rotación de Logs con Logrotate](#18-t15-rotación-de-logs-con-logrotate)
19. [T16: CloudWatch y Alertas Proactivas](#19-t16-cloudwatch-y-alertas-proactivas)
20. [T17: Script de Despliegue Continuo](#20-t17-script-de-despliegue-continuo)
21. [T18: Prueba de Restauración y RTO](#21-t18-prueba-de-restauración-y-rto)
22. [T19: Auditoría de Seguridad con nmap](#22-t19-auditoría-de-seguridad-con-nmap)

### [Acceso Rápido a Scripts y Configuraciones](#acceso-rápido-a-scripts-y-configuraciones)

---

## Sprint 1: Infraestructura VPC

**Fecha:** 13 de abril 2025 – 19 de abril 2025  
**Módulos:** M0370 (Planificación de redes) · M0369 (Integración de ordenadores en red)

---

## 1. Arquitectura de Red

La infraestructura de NexOrder sigue un modelo de red en dos capas dentro de una única VPC en AWS región `us-east-1`:

- **Capa pública** (`10.0.1.0/23`): expuesta a Internet, alberga el servidor web EC2.
- **Capa privada** (`10.0.2.0/23`): sin acceso directo a Internet, alberga la base de datos RDS.

Este diseño aplica el principio de defensa en profundidad: incluso si el servidor web fuera comprometido, un atacante no podría alcanzar la base de datos directamente desde Internet.

![Diagrama lógico](/img/sprint1/0-diagrama-logico.png)

> 📸 **Figura 0** – Arquitectura lógica: diagrama conceptual de la red

---

## 2. TA01: VPC y Subredes

### 2.1 Creación de la VPC

La VPC es el contenedor lógico de toda la infraestructura. Se crea con un bloque CIDR `/16` para disponer de espacio suficiente para crecer en subredes sin necesidad de re-diseñar la red.

| Parámetro | Valor |
|-----------|-------|
| **Nombre** | VPC-NexOrder |
| **CIDR IPv4** | 10.0.0.0/16 |
| **IPv6** | Deshabilitado |
| **Tenencia** | Predeterminada |
| **ID resultante** | vpc-0905a60eb17e6565f |
| **Región** | us-east-1 (Norte de Virginia) |

**¿Por qué `/16`?** Un bloque `/16` proporciona 65.536 direcciones IP. Esto permite crear múltiples subredes `/23` (246 IPs cada una) sin que se solapen, dejando margen para entornos de staging, QA o microservicios futuros.

![Creación VPC](/img/sprint1/1-creación-vpc.png)

> 📸 **Figura 1** – Panel AWS de creación de VPC: con CIDR `10.0.0.0/16` y etiqueta `Name=VPC-NexOrder`

![Formulario VPC](/img/sprint1/2-formulario-vpc.png)

> 📸 **Figura 2** – Formulario de configuración completo: IPv6 deshabilitado, tenencia predeterminada

### 2.2 Subred Pública

La subred pública alberga los recursos que deben ser accesibles desde Internet (servidor web, balanceadores de carga, etc.).

| Parámetro | Valor |
|-----------|-------|
| **Nombre** | Subnet-Publica-Web |
| **CIDR** | 10.0.1.0/23 (246 IPs) |
| **Zona de Disponibilidad** | us-east-1a |
| **VPC** | vpc-0905a60eb17e6565f |
| **ID resultante** | subnet-0b18a1ba9a8bbb7ad |

![Subred pública](/img/sprint1/3-subnet-publica.png)

> 📸 **Figura 3** – Configuración de Subnet-Publica-Web: con CIDR `10.0.1.0/23` (subred 1 de 2)

### 2.3 Subred Privada

La subred privada alberga la base de datos. Al no tener ruta a Internet, sus recursos solo son accesibles desde dentro de la VPC.

| Parámetro | Valor |
|-----------|-------|
| **Nombre** | Subnet-Privada-D |
| **CIDR** | 10.0.2.0/23 (246 IPs) |
| **Zona de Disponibilidad** | us-east-1a |
| **VPC** | vpc-0905a60eb17e6565f |
| **ID resultante** | subnet-06db775e1d4b17a88 |

![Subred privada](/img/sprint1/4-subnet-privada.png)

> 📸 **Figura 4** – Configuración de Subnet-Privada-D: con CIDR `10.0.2.0/23` (subred 2 de 2)

### 2.4 Validación de Subredes

Tras la creación, AWS confirma que ambas subredes están en estado `Available` y asociadas a la VPC correcta.

| Nombre | ID de Subred | CIDR | Estado |
|--------|--------------|------|--------|
| Subnet-Publica-Web | subnet-0b18a1ba9a8bbb7ad | 10.0.1.0/23 | Available |
| Subnet-Privada-D | subnet-06db775e1d4b17a88 | 10.0.2.0/23 | Available |

![Listado subredes](/img/sprint1/5-listado-subredes.png)

> 📸 **Figura 5** – Listado de subredes creadas: con estado `Available` en la consola AWS

---

## 3. TA02: Internet Gateway y Enrutamiento

### 3.1 Internet Gateway (IGW)

El Internet Gateway (IGW) es el componente que conecta la VPC con Internet. Sin él, ningún recurso dentro de la VPC podría comunicarse con el exterior.

| Parámetro | Valor |
|-----------|-------|
| **Nombre** | IGW-NexOrder |
| **ID resultante** | igw-099e10b6c7e172a24 |
| **VPC asociada** | vpc-0905a60eb17e6565f |

**Proceso:**
1. Se crea el IGW con el nombre `IGW-NexOrder`.
2. Se asocia a la VPC mediante la opción "Asociar a una VPC".

![Panel IGW](/img/sprint1/6-panel-igw.png)

> 📸 **Figura 6** – Formulario de creación de IGW-NexOrder

![Asociación IGW](/img/sprint1/7-asociacion-igw.png)

> 📸 **Figura 7** – Asociación del IGW: a `vpc-0905a60eb17e6565f`

### 3.2 Tablas de Enrutamiento

Se crean dos tablas de enrutamiento independientes para implementar una separación estricta del tráfico entre la capa pública y la privada. Las asociaciones son explícitas (no se usa la tabla principal de la VPC para ningún recurso crítico).

#### RT-Publica-NexOrder
**ID:** `rtb-0e78fa3e4905a11fd`  
**Asociada a:** `Subnet-Publica-Web`

| Destino | Objetivo | Estado | Propósito |
|---------|----------|--------|-----------|
| 10.0.0.0/16 | local | Activo | Comunicación intra-VPC |
| 0.0.0.0/0 | igw-099e10b6c7e172a24 | Activo | Acceso bidireccional a Internet |

**¿Por qué añadimos `0.0.0.0/0 → IGW`?** Esta ruta indica que cualquier tráfico destinado a una IP fuera de la VPC debe salir a través del Internet Gateway. Sin ella, el servidor web podría existir en la subred, pero ningún usuario externo podría alcanzarlo ni la instancia podría descargar actualizaciones.

![RT Pública](/img/sprint1/8-rt-publica.png)

> 📸 **Figura 8** – Tabla de enrutamiento pública: con asociación explícita a `Subnet-Publica-Web` (CIDR `10.0.1.0/23`)

![Edición rutas](/img/sprint1/9-edicion-rutas.png)

> 📸 **Figura 9** – Edición de rutas: `0.0.0.0/0` apuntando a `igw-099e10b6c7e172a24`

#### RT-Privada-NexOrder
**ID:** `rtb-0886f3878f7e26479`  
**Asociada a:** `Subnet-Privada-D`

| Destino | Objetivo | Estado | Propósito |
|---------|----------|--------|-----------|
| 10.0.0.0/16 | local | Activo | Solo comunicación intra-VPC |

Esta tabla no contiene ninguna ruta `0.0.0.0/0`, lo que garantiza que la base de datos nunca pueda ser alcanzada directamente desde Internet ni pueda iniciar conexiones salientes hacia él.

![RT Privada](/img/sprint1/10-rt-privada.png)

> 📸 **Figura 10** – Tabla de enrutamiento privada: con asociación explícita a `Subnet-Privada-D` (CIDR `10.0.2.0/23`), sin ruta a Internet

---

## 4. TA03: Instancias EC2 y RDS

### 4.1 Instancia EC2

La instancia EC2 actúa como servidor web de la aplicación NexOrder, situado en la subred pública para ser accesible desde Internet.

| Parámetro | Valor |
|-----------|-------|
| **Nombre** | NexOrder-EC2-Web |
| **ID** | i-093d338216cd0568d |
| **AMI** | Amazon Linux 2023 (kernel-6.1) |
| **Tipo** | t3.micro |
| **Subred** | subnet-0b18a1ba9a8bbb7ad (pública) |
| **IP Pública** | 3.86.92.89 |
| **IP Privada** | 10.0.1.237 |
| **VPC** | vpc-0905a60eb17e6565f |
| **Key Pair** | NexOrder-SSH-Key.pem |

![Lanzamiento EC2](/img/sprint1/11-lanzamiento-ec2.png)

> 📸 **Figura 11** – Formulario de lanzamiento de EC2: con AMI Amazon Linux 2023

![Resumen EC2](/img/sprint1/12-resumen-ec2.png)

> 📸 **Figura 12** – Resumen de instancia: `i-093d338216cd0568d` con IPs pública (`3.86.92.89`) y privada (`10.0.1.237`)

### 4.2 Instancia RDS MySQL

La base de datos RDS se despliega en la subred privada para garantizar su aislamiento total de Internet.

| Parámetro | Valor |
|-----------|-------|
| **DB Identifier** | nexorder-db |
| **Motor** | MySQL Community 8.0.40 |
| **Clase** | db.t3.micro |
| **Usuario master** | admin |
| **Subred** | subnet-06db775e1d4b17a88 (privada) |
| **Endpoint** | nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com |
| **AZ** | us-east-1a |
| **Internet Access Gateway** | Disabled |
| **IAM Authentication** | Disabled |

**Nota de seguridad:** La contraseña `N3x0r-DB-2026!Sec` debe almacenarse inmediatamente en un gestor de contraseñas (1Password, Bitwarden, AWS Secrets Manager, etc.). No debe quedar en texto plano en ningún fichero del repositorio.

![RDS creating](/img/sprint1/13-rds-creating.png)

> 📸 **Figura 13** – Panel de RDS nexorder-db: en estado `Creating` (MySQL Community, db.t3.micro)

![RDS available](/img/sprint1/14-rds-available.png)

> 📸 **Figura 14** – Listado de bases de datos: `nexorder-db` en estado `Available`

### 4.3 Conexión SSH Inicial

Una vez lanzada la instancia, se verifica el acceso SSH desde terminal local utilizando la clave generada durante el lanzamiento:

```bash
# Asegurar permisos correctos sobre la clave privada
chmod 400 NexOrder-SSH-Key.pem

# Conectar a la instancia EC2
ssh -i "NexOrder-SSH-Key.pem" ec2-user@44.207.176.14
```

**Resultado esperado:** banner de bienvenida de Amazon Linux 2023 y prompt `[ec2-user@Web-NexOrder ~]$`.

![SSH ec2-user](/img/sprint1/15-ssh-ec2user.png)

> 📸 **Figura 15** – Terminal SSH exitosa: conexión como `ec2-user` a `44.207.176.14` con Amazon Linux 2023

### 4.4 Prueba de Conexión EC2 → RDS

Desde dentro de la instancia EC2, se instala el cliente MySQL y se valida la conectividad con la base de datos a través del endpoint DNS interno:

```bash
# Instalar cliente MySQL en Amazon Linux 2023
sudo apt update && sudo apt install default-mysql-client -y

# Conectar a RDS usando el endpoint DNS interno
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u admin -p
```

**Resultado esperado:**
```
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 39
Server version: 8.0.40 Source distribution

mysql>
```

El `connection id 39` confirma que la comunicación entre EC2 y RDS funciona correctamente a través de la red privada de la VPC, sin pasar en ningún momento por Internet.

![MySQL connection](/img/sprint1/16-mysql-connection.png)

> 📸 **Figura 16** – Conexión MySQL exitosa: `connection id 39` desde EC2 hacia el endpoint RDS

---

## 5. TA04: Security Groups

Los Security Groups actúan como firewalls virtuales con estado (stateful): las reglas de entrada y salida se evalúan por conexión, y el tráfico de retorno de una conexión permitida se autoriza automáticamente.

### 5.1 SG-Web-NexOrder

**ID:** `sg-0e0334685744195e2`  
**Descripción:** Permitir tráfico HTTP y SSH para el servidor web  
**VPC:** `vpc-0905a60eb17e6565f`

**Reglas de Entrada (Inbound):**

| Tipo | Protocolo | Puerto | Origen | Justificación |
|------|-----------|--------|--------|---------------|
| HTTP | TCP | 80 | 0.0.0.0/0 | Acceso web público sin cifrar |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Acceso web cifrado (producción) |
| SSH | TCP | 22 | 79.116.173.66/32 | Administración restringida a la IP del equipo |

**Reglas de Salida (Outbound):** Todo el tráfico permitido (default AWS).

**¿Por qué SSH con `/32`?** Restringir SSH a una única IP (`/32`) elimina casi por completo la exposición a ataques de fuerza bruta automatizados. Un `/32` representa exactamente una dirección IP. Si la IP del administrador cambia, basta con actualizar esta regla.

![SG Web](/img/sprint1/17-sg-web.png)

> 📸 **Figura 17** – Creación de SG-Web-NexOrder: con reglas HTTP(80), HTTPS(443) y SSH(22) restringido a `79.116.173.66/32`

### 5.2 SG-DB-NexOrder

**Descripción:** Base de Datos  
**VPC:** `vpc-0905a60eb17e6565f`

**Reglas de Entrada (Inbound):**

| Tipo | Protocolo | Puerto | Origen | Justificación |
|------|-----------|--------|--------|---------------|
| MySQL/Aurora | TCP | 3306 | sg-0e0334685744195e2 | Solo desde instancias asociadas a SG-Web |

**¿Por qué referenciar el SG en lugar de una IP?** Al usar el ID del Security Group como origen, la regla se aplica dinámicamente a cualquier instancia que tenga asignado ese SG. Si la IP pública del servidor web cambia (reinicio, escalado), la regla sigue siendo válida sin modificaciones. Esto también impide que cualquier otra máquina, aunque esté dentro de la VPC, acceda a la base de datos.

![SG DB](/img/sprint1/18-sg-db.png)

> 📸 **Figura 18** – Creación de SG-DB-NexOrder: con MySQL(3306) referenciando `sg-0e0334685744195e2`

---

## 6. TA05: Hardening del Sistema

El hardening es el proceso de reducir la superficie de ataque de un sistema eliminando configuraciones inseguras por defecto, restringiendo accesos y actualizando vulnerabilidades conocidas.

### 6.1 Actualización de Paquetes

El primer paso de cualquier hardening es asegurar que el sistema tenga los últimos parches de seguridad aplicados.

```bash
# Actualizar todos los paquetes del sistema
sudo dnf update -y

# Instalar herramientas de administración y seguridad
sudo dnf install -y vim wget curl git fail2ban

# Verificar versión del kernel tras actualización
dnf info kernel | grep Version
```

**Resultado:** Kernel actualizado a `6.1.168`. Se instalaron correctamente `git`, `vim`, `wget`, `curl` y `fail2ban` (herramienta de prevención de fuerza bruta).

![dnf update](/img/sprint1/19-dnf-update.png)

> 📸 **Figura 19** – Salida de sudo dnf update -y: mostrando `mysql80-community-release` actualizado

![Instalación herramientas](/img/sprint1/20-instalacion-herramientas.png)

> 📸 **Figura 20** – Instalación de herramientas: git 2.50.1, vim-enhanced 9.2, etc.

![Kernel version](/img/sprint1/21-kernel-version.png)

> 📸 **Figura 21** – Verificación de kernel: `Version: 6.1.168`

### 6.2 Usuario Administrativo Restringido

En lugar de usar el usuario `ec2-user` (con sudo completo) para operaciones del día a día, se crea un usuario `nexadmin` con permisos sudo únicamente para los comandos necesarios.

```bash
# Crear usuario 'nexadmin' (sin contraseña de sistema, solo clave SSH)
sudo adduser nexadmin

# Configurar directorio SSH con permisos seguros
sudo mkdir -p /home/nexadmin/.ssh
sudo chmod 700 /home/nexadmin/.ssh

# Reutilizar la misma clave pública que ec2-user
sudo cp /home/ec2-user/.ssh/authorized_keys /home/nexadmin/.ssh/
sudo chown -R nexadmin:nexadmin /home/nexadmin/.ssh
sudo chmod 600 /home/nexadmin/.ssh/authorized_keys

# Definir permisos sudo restringidos (solo comandos operativos)
echo 'nexadmin ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart apache2, \
/usr/bin/systemctl reload apache2, \
/usr/bin/dnf update, \
/usr/bin/dnf upgrade, \
/usr/local/bin/backup_nexorder.sh, \
/usr/local/bin/deploy_nexorder.sh' | sudo tee /etc/sudoers.d/nexadmin

# Proteger el archivo de sudoers
sudo chmod 440 /etc/sudoers.d/nexadmin

# Validar sintaxis del archivo antes de aplicar
sudo visudo -c
```

**Resultado:** `/etc/sudoers.d/nexadmin: parsed OK`. El usuario puede gestionar Apache y ejecutar scripts de despliegue/backup, pero no puede ejecutar comandos arbitrarios como root.

![Creación nexadmin](/img/sprint1/22-creacion-nexadmin.png)

> 📸 **Figura 22** – Creación de usuario nexadmin: ejecución de `adduser`, `mkdir`, `chmod` y `cp` de `authorized_keys`

![Sudoers config](/img/sprint1/23-sudoers-config.png)

> 📸 **Figura 23** – Configuración de sudoers: validación `/etc/sudoers.d/nexadmin: parsed OK`

### 6.3 Hardening de SSH

La configuración por defecto de SSH en muchos servidores permite el login como root y la autenticación por contraseña, ambas prácticas inseguras. Se aplica hardening con comandos `sed` (reversibles, sobre backup previo):

```bash
# Siempre hacer backup antes de modificar configuraciones críticas
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Deshabilitar login como root
sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Deshabilitar autenticación por contraseña (solo claves SSH)
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Asegurar que la autenticación por clave pública está habilitada
sudo sed -i 's/^PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Deshabilitar contraseñas vacías
sudo sed -i 's/^PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config

# Verificar que los cambios se aplicaron correctamente
sudo grep -E "PermitRootLogin|PasswordAuthentication|PubkeyAuthentication" /etc/ssh/sshd_config
```

**Resultado esperado:**
```
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
```

![sed sshd](/img/sprint1/24-sed-sshd.png)

> 📸 **Figura 24** – Comandos sed aplicados: sobre `/etc/ssh/sshd_config` (backup previo creado)

![Pubkey auth](/img/sprint1/25-pubkey-auth.png)

> 📸 **Figura 25** – Aplicación de reglas SSH: para `PubkeyAuthentication` y `PermitEmptyPasswords`

![grep verification](/img/sprint1/26-grep-verification.png)

> 📸 **Figura 26** – Verificación con grep: `PermitRootLogin no`, `PubkeyAuthentication yes`, `PasswordAuthentication no`

### 6.4 Reinicio y Validación del Servicio

Antes de reiniciar SSH, se valida la sintaxis del archivo de configuración para evitar quedarse sin acceso al servidor:

```bash
# Validar sintaxis ANTES de reiniciar (paso crítico)
sudo sshd -t && echo "Configuración SSH válida"

# Reiniciar el demonio SSH
sudo systemctl restart sshd

# Verificar que el servicio está activo
sudo systemctl status sshd --no-pager

# Confirmar que está escuchando en el puerto correcto
sudo ss -tlnp | grep sshd
```

**Resultado:** Servicio `active (running)` escuchando en `0.0.0.0:22` y `[::]:22` (IPv4 e IPv6).

**Buena práctica:** Siempre mantener la sesión SSH activa mientras se prueba la configuración. Solo cerrar la sesión original una vez verificado que la nueva configuración funciona.

![sshd restart](/img/sprint1/27-sshd-restart.png)

> 📸 **Figura 27** – Validación y reinicio SSH: `sshd -t` retorna OK + `systemctl restart sshd`

![sshd status](/img/sprint1/28-sshd-status.png)

> 📸 **Figura 28** – Estado del servicio SSH: `active (running)` con PID `30274`

![ss tlnp](/img/sprint1/29-ss-tlnp.png)

> 📸 **Figura 29** – Verificación de puerto: `ss -tlnp` confirmando `sshd` escuchando en `0.0.0.0:22`

### 6.5 Prueba con usuario nexadmin

Validación final del nuevo usuario y el hardening aplicado:

```bash
ssh -i "NexOrder-SSH-Key.pem" nexadmin@44.207.176.14
```

**Resultado:** Acceso exitoso. El prompt muestra `[nexadmin@Web-NexOrder ~]$`, confirmando que:
- La autenticación por clave funciona para el nuevo usuario.
- La contraseña de sistema no es necesaria.
- El hardening SSH está activo y operativo.

![Login nexadmin](/img/sprint1/30-login-nexadmin.png)

> 📸 **Figura 30** – Conexión SSH con nexadmin: banner de Amazon Linux 2023 y prompt `[nexadmin@Web-NexOrder ~]$`

---

## 7. Verificación Final de Conectividad

Checklist de validación integral de toda la infraestructura del Sprint 1:

| Componente | Verificación | Estado |
|------------|--------------|--------|
| VPC `vpc-0905a60eb17e6565f` | Creada y operativa | ✅ |
| Subnet-Publica-Web | Available, CIDR `10.0.1.0/23` | ✅ |
| Subnet-Privada-D | Available, CIDR `10.0.2.0/23` | ✅ |
| IGW-NexOrder | Asociado a VPC, estado `Attached` | ✅ |
| RT-Publica | Ruta `0.0.0.0/0 → IGW` activa | ✅ |
| RT-Privada | Sin ruta a Internet, solo `local` | ✅ |
| NexOrder-EC2-Web | Running, IP pública `3.86.92.89` | ✅ |
| nexorder-db | Available, MySQL 8.0.40 | ✅ |
| SG-Web-NexOrder | HTTP/HTTPS abierto, SSH restringido | ✅ |
| SG-DB-NexOrder | MySQL solo desde SG-Web | ✅ |
| Conexión SSH `ec2-user` | Acceso verificado | ✅ |
| Conexión SSH `nexadmin` | Acceso verificado post-hardening | ✅ |
| Conexión EC2 → RDS | `connection id 39`, MySQL activo | ✅ |
| `PermitRootLogin` | `no` | ✅ |
| `PasswordAuthentication` | `no` | ✅ |
| `PubkeyAuthentication` | `yes` | ✅ |

---

## Sprint 2: Servicios Web y Seguridad

**Fecha:** 20 de abril 2026 – 26 de abril 2026  
**Módulos:** M0375 (Servicios de red) · M0378 (Administración de servidores) · C037 (Seguridad)

---

## 8. Arquitectura de Aplicación Web

El Sprint 2 construye la capa de aplicación sobre la infraestructura de red del Sprint 1. Los servicios desplegados forman una pila completa con seguridad en cada nivel:

![Arquitectura web](/img/sprint2/0-arquitectura-web.png)

> 📸 **Figura 0** – Arquitectura de servicios: diagrama conceptual de la pila de aplicación web

---

## 9. T07: Servidor Web y PHP

### 9.1 Instalación de httpd y PHP

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
| httpd | 2.4.66-1.amzn2023.0.1 | x86_64 | amazonlinux |
| php8.5 | 8.5.4-1.amzn2023.0.1 | x86_64 | amazonlinux |

**¿Por qué estos dos paquetes juntos?** `httpd` (Apache 2.4) es el servidor web que gestiona las conexiones HTTP/HTTPS entrantes. PHP permite que Apache ejecute scripts del lado del servidor, que es el lenguaje con el que está desarrollada la aplicación NexOrder. Sin ambos, el servidor solo podría servir archivos estáticos.

![SSH conexion](/img/sprint2/1-ssh-conexion.png)

> 📸 **Figura 1** – Terminal con `ssh -i "NexOrder-SSH-Key.pem" ec2-user@52.90.85.X` conectando correctamente a Amazon Linux 2023

![dnf update](/img/sprint2/2-dnf-update.png)

> 📸 **Figura 2** – Salida de `sudo dnf update -y` mostrando `Complete!` con Amazon Linux 2023 Kernel Livepatch repository

![Install httpd php](/img/sprint2/3-install-httpd-php.png)

> 📸 **Figura 3** – Salida de `sudo dnf install -y httpd php` con las versiones `httpd 2.4.66` y `php8.5 8.5.4` instaladas

### 9.2 Habilitación y Verificación

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

![start httpd](/img/sprint2/4-start-httpd.png)

> 📸 **Figura 4** – Terminal con `systemctl start httpd` y `systemctl enable httpd` creando el symlink de arranque automático

![status httpd](/img/sprint2/5-status.httpd.png)

> 📸 **Figura 5** – `systemctl status httpd` mostrando `active (running)` con PID 26333, puerto 80 en escucha

![curl localhost](/img/sprint2/6-curl-localhost.png)

> 📸 **Figura 6** – `curl localhost` devolviendo `<!DOCTYPE HTML PUBLIC ... It works! Apache httpd`

---

## 10. T08: SSL/TLS y Redirección HTTPS

El objetivo de esta tarea es asegurar que todo el tráfico hacia el servidor web viaje cifrado. Se implementan tres capas: certificado TLS, VirtualHost SSL y redirección permanente HTTP→HTTPS.

### 10.1 Instalación de Módulos SSL

```bash
# Instalar módulo SSL de Apache y la herramienta openssl
sudo dnf install -y mod_ssl openssl
```

**Paquetes instalados:**

| Paquete | Versión | Tamaño |
|---------|---------|--------|
| mod_ssl | 1:2.4.66-1.amzn2023.0.1 | 111 k |
| sscg (dependencia) | 3.0.3-77.amzn2023 | 46 k |

![Install SSL](/img/sprint2/7-install-ssl.png)

> 📸 **Figura 7** – Salida de `sudo dnf install -y mod_ssl openssl` con instalación correcta de `mod_ssl` y `sscg`

### 10.2 Generación de Certificado Autofirmado

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
| Clave privada | /etc/pki/tls/private/nexorder.key |
| Certificado | /etc/pki/tls/certs/nexorder.crt |
| Validez | 365 días |
| Algoritmo | RSA 2048 bits |

**¿Por qué autofirmado?** En un entorno de laboratorio o preproducción sin dominio DNS registrado, un certificado de Let's Encrypt no es viable (requiere dominio público). El certificado autofirmado proporciona cifrado TLS idéntico al de un certificado CA; la única diferencia es que los navegadores muestran una advertencia de confianza, lo que se acepta con `-k` en `curl` o añadiendo excepción en el navegador.

![Generate certs](/img/sprint2/8-generate-certs.png)

> 📸 **Figura 8** – Terminal ejecutando el comando `openssl req -x509 ...` con salida de generación de clave y certificado

### 10.3 Configuración VirtualHost y Redirección

Se crea un archivo de configuración dedicado para separar la configuración SSL de la configuración base de Apache:

```bash
sudo nano /etc/httpd/conf.d/nexorder-ssl.conf
```

**¿Qué hace cada directiva?**
- `RewriteEngine On` / `RewriteCond %{HTTPS} off` / `RewriteRule`: redirige automáticamente cualquier petición HTTP al equivalente HTTPS con un código 301 (redirección permanente, que los buscadores y navegadores cachean).
- `SSLEngine on`: activa el motor SSL para ese VirtualHost.
- `SSLCertificateFile` / `SSLCertificateKeyFile`: apuntan al certificado y clave generados en el paso anterior.
- `Strict-Transport-Security`: cabecera HSTS que instruye al navegador a nunca volver a usar HTTP para ese dominio durante `max-age` segundos (31.536.000 = 1 año). Previene ataques de downgrade.

![SSL config](/img/sprint2/9-ssl-config.png)

> 📸 **Figura 9** – Editor nano mostrando el contenido completo de `nexorder-ssl.conf` con ambos VirtualHost y la cabecera HSTS

Después de guardar, se verifica la sintaxis y se reinicia Apache:

```bash
sudo httpd -t && sudo systemctl restart httpd
```

![Restart httpd](/img/sprint2/10-restart-httpd.png)

> 📸 **Figura 10** – `sudo httpd -t && sudo systemctl restart httpd` con salida `Syntax OK` y servicio reiniciado

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

![Redirect HTTP](/img/sprint2/11-redirect-http.png)

> 📸 **Figura 11** – `curl -I http://localhost` devolviendo `HTTP/1.1 301 Moved Permanently` con `Location: https://localhost/`

**Resultado de `curl -Ik https://localhost`:**
```
HTTP/1.1 200 OK
Server: Apache
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

![HTTPS working](/img/sprint2/12-https-working.png)

> 📸 **Figura 12** – `curl -Ik https://localhost` devolviendo `200 OK` con cabecera `Strict-Transport-Security: max-age=31536000; includeSubDomains`

### 10.4 Resolución de Incidencias (Puerto 443)

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

![Headers module](/img/sprint2/13-headers-module.png)

> 📸 **Figura 13** – `echo 'LoadModule headers_module ...'` añadido correctamente a `00-base.conf`

![Verificar](/img/sprint2/14-verificar.png)

> 📸 **Figura 14** – Con `httpd -M | grep ssl_module` estamos confirmando `ssl_module (shared)`

![Rewrite module](/img/sprint2/15-rewrite-module.png)

> 📸 **Figura 15** – `echo 'LoadModule rewrite_module ...'` añadido correctamente

![Syntax OK](/img/sprint2/16-syntax-ok.png)

> 📸 **Figura 16** – `sudo httpd -t` devolviendo `Syntax OK`

![ss tlnp](/img/sprint2/17-ss-tlnp.png)

> 📸 **Figura 17** – `ss -tlnp | grep httpd` mostrando escucha simultánea en `*:80` y `*:443`

---

## 11. T09: Protección SSH con Fail2ban

Fail2ban es un servicio de prevención de intrusiones que monitoriza los logs del sistema en tiempo real. Cuando detecta un patrón de ataques (como múltiples intentos de login SSH fallidos), banea automáticamente la IP atacante mediante reglas de firewall temporales.

### 11.1 Instalación y Activación

```bash
# Instalar Fail2ban desde los repositorios de Amazon Linux
sudo dnf install -y fail2ban

# Habilitar e iniciar en un solo comando
sudo systemctl enable --now fail2ban
```

**Versión instalada:** `fail2ban 1.1.0-1.amzn2023.0.1` (noarch, 10k)

El flag `--now` de `systemctl enable` combina `enable` y `start` en un solo comando, creando el symlink de arranque automático e iniciando el servicio inmediatamente.

![Install fail2ban](/img/sprint2/18-install-fail2ban.png)

> 📸 **Figura 18** – `sudo dnf install -y fail2ban` con instalación de `fail2ban 1.1.0-1.amzn2023.0.1`

![Enable fail2ban](/img/sprint2/19-enable-fail2ban.png)

> 📸 **Figura 19** – `sudo systemctl enable --now fail2ban` creando el symlink en `/usr/lib/systemd/system/fail2ban.service`

### 11.2 Configuración de Jail

Fail2ban lee su configuración de `/etc/fail2ban/jail.conf` (defaults) pero se sobreescribe con `/etc/fail2ban/jail.local` para que las actualizaciones del paquete no borren la configuración personalizada:

```bash
sudo nano /etc/fail2ban/jail.local
```

| Parámetro | Valor | Significado |
|-----------|-------|-------------|
| enabled | true | Activa esta regla (jail) |
| port | ssh | Monitoriza el puerto 22 |
| filter | sshd | Usa el filtro predefinido para SSH |
| logpath | /var/log/secure | Archivo de log donde busca los intentos fallidos |
| maxretry | 3 | Número máximo de fallos antes del bloqueo |
| bantime | 1h | Duración del bloqueo (1 hora) |

![Jail local](/img/sprint2/20-jail-local.png)

> 📸 **Figura 20** – Editor nano mostrando `/etc/fail2ban/jail.local` con las 4 directivas de la jail `[sshd]`

### 11.3 Verificación de Estado

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
- `Status for the jail: sshd`: Fail2ban está monitorizando el servicio SSH activamente.
- `Journal matches: _SYSTEMD_UNIT=sshd.service`: el programa está conectado a los registros del sistema operativo (journald) y puede leer los eventos de SSH en tiempo real.
- `Currently banned: 0`: no hay ninguna IP bloqueada porque aún no se ha superado el umbral de 3 intentos fallidos. Este es el estado correcto en un servidor recién configurado.

![Fail2ban status](/img/sprint2/21-fail2ban-status.png)

> 📸 **Figura 21** – `fail2ban-client status sshd` mostrando la jail activa con `Currently banned: 0` y `Journal matches` configurado

---

## 12. T10: Control de Acceso MySQL

El objetivo es implementar el principio de mínimo privilegio en la base de datos: la aplicación web solo tendrá los permisos estrictamente necesarios para operar, limitando el daño potencial en caso de brecha de seguridad.

### 12.1 Conexión como Administrador

Desde la EC2, se conecta a la instancia RDS usando el usuario `admin` creado durante el Sprint 1:

```bash
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u admin -p
# Contraseña: N3x0r-DB-2026!Sec
```

**Resultado:** `MySQL connection id is 100` → conexión exitosa a MySQL 8.0.40.

![MySQL login](/img/sprint2/22-mysql-login.png)

> 📸 **Figura 22** – Terminal con login MySQL como `admin`, mostrando `connection id 100` y `Server version: 8.0.40`

### 12.2 Hardening y Creación de Usuario

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

![Create DB user](/img/sprint2/23-create-db-user.png)

> 📸 **Figura 23** – `CREATE DATABASE`, `CREATE USER` y `GRANT SELECT, INSERT, UPDATE` ejecutados con `Query OK`

![Drop test flush](/img/sprint2/24-drop-test-flush.png)

> 📸 **Figura 24** – `DROP DATABASE test`, `FLUSH PRIVILEGES` y `SHOW GRANTS FOR 'nexorder_app'@'%'` con la tabla de permisos resultante

![Show grants](/img/sprint2/25-show-grants.png)

> 📸 **Figura 25** – Vista ampliada de `SHOW GRANTS` confirmando los dos grants: USAGE global + SELECT/INSERT/UPDATE en nexorder_db

### 12.3 Validación de Mínimo Privilegio

Se verifica que el usuario `nexorder_app` puede conectarse y operar dentro de sus permisos, pero no puede realizar operaciones destructivas:

```bash
# Conectar como el usuario de aplicación
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u nexorder_app -p
```

![Login nexorder](/img/sprint2/26-login-nexorder.png)

> 📸 **Figura 26** – Login MySQL como `nexorder_app` con `connection id 105`

**Dentro de MySQL:**
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

![Permission denied](/img/sprint2/27-permission-denied.png)

> 📸 **Figura 27** – `CREATE TABLE prueba_fallo` devolviendo `ERROR 1142 (42000): CREATE command denied`

### 12.4 Esquema de Base de Datos NexOrder

Con el usuario `admin`, se crea y ejecuta el esquema completo de la aplicación:

```bash
# Crear el archivo del esquema
sudo nano nexorder_schema.sql

# Ejecutar el script contra RDS
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com \
  -u admin -p \
  nexorder_db < /home/ec2-user/nexorder_schema.sql
```

![Schema SQL](/img/sprint2/28-schema-sql.png)

> 📸 **Figura 28** – Editor nano mostrando `nexorder_schema.sql` con las primeras tablas (`estados`, `usuarios`)

![Execute schema](/img/sprint2/29-execute-schema.png)

> 📸 **Figura 29** – Ejecución del script y salida tabulada con `SHOW TABLES`, conteo de registros y menú de productos

**Tablas creadas:**

| Tabla | Descripción | Filas iniciales |
|-------|-------------|-----------------|
| estados | Estados de pedido normalizados | 5 |
| usuarios | Clientes, cocina, admin | 2 |
| productos | Menú del restaurante | 7 |
| pedidos | Cabecera de pedidos | 0 |
| detalle_pedidos | Líneas de pedido (N:M) | 0 |

**Diseño notable:**
- Columna `subtotal` en `detalle_pedidos` es una columna generada (`GENERATED ALWAYS AS (cantidad * precio_unitario) STORED`): se calcula automáticamente, eliminando errores de consistencia.
- Todas las tablas usan `ENGINE=InnoDB` (soporte de transacciones y claves foráneas).
- Índices en columnas de búsqueda frecuente (`idx_username`, `idx_email`, `idx_categoria`, etc.).

```bash
# Verificar tablas creadas
mysql> use nexorder_db;
mysql> show tables;
mysql> DESCRIBE estados;
```

![Describe tables 1](/img/sprint2/30-describe-tables-1.png)

> 📸 **Figura 30** – `SHOW TABLES` mostrando las 5 tablas + `DESCRIBE estados` y `DESCRIBE pedidos`

![Describe tables 2](/img/sprint2/31-describe-tables-2.png)

> 📸 **Figura 31** – `DESCRIBE detalle_pedidos` con columna `subtotal STORED GENERATED` + `DESCRIBE usuarios` y `DESCRIBE productos`

![Describe tables 3](/img/sprint2/32-describe-tables-3.png)

> 📸 **Figura 32** – `DESCRIBE pedidos` completo con claves foráneas y `DESCRIBE productos` con el ENUM de categorías

---

## 13. T11: Hardening del Servidor Web

Apache, por defecto, incluye en sus cabeceras HTTP y páginas de error información detallada sobre su versión y el sistema operativo subyacente. Esta información es un regalo para un atacante que quiera buscar vulnerabilidades conocidas para esa versión exacta.

### 13.1 Configuración de Cabeceras

Se edita el archivo de configuración principal de Apache:

```bash
sudo nano /etc/httpd/conf/httpd.conf
```

![httpd conf start](/img/sprint2/33-httpd-conf-start.png)

> 📸 **Figura 33** – Editor nano con el inicio de `/etc/httpd/conf/httpd.conf` (archivo principal de configuración)

Al final del archivo se añaden dos directivas:

```apache
ServerTokens Prod
ServerSignature Off
```

**¿Qué hace cada directiva?**
- `ServerTokens Prod`: controla qué información se incluye en la cabecera `Server:` de cada respuesta HTTP. Con el valor `Prod`, solo se envía `Apache` (sin versión, sin OS, sin módulos). Por defecto enviaría algo como `Apache/2.4.66 (Amazon Linux) OpenSSL/3.5.5 PHP/8.5.4`.
- `ServerSignature Off`: elimina el pie de página que Apache añade a las páginas de error generadas automáticamente (404, 403, 500...), que mostraría la versión del servidor y el hostname.

![httpd conf end](/img/sprint2/34-httpd-conf-end.png)

> 📸 **Figura 34** – Final del archivo con `ServerTokens Prod` y `ServerSignature Off` añadidos y guardados

### 13.2 Verificación de Ocultación

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

![Server tokens](/img/sprint2/35-server-tokens.png)

> 📸 **Figura 35** – `curl -I localhost` devolviendo `Server: Apache` (sin versión) con código `403 Forbidden` (normal, sin index)

---

## 14. T12: Capa de Validación Web (PHP+PDO)

Se despliegan tres archivos PHP en el `DocumentRoot` de Apache para validar de extremo a extremo la conectividad segura entre la capa web y la capa de datos.

### 14.1 Creación de Archivos PHP

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

![Create PHP files](/img/sprint2/36-create-php-files.png)

> 📸 **Figura 36** – Terminal ejecutando `touch`, `chown apache:apache *.php` y `chmod 644 *.php` en `/var/www/html/`

### 14.2 Contenido de los Archivos

#### `connexio.php` — Motor de conexión PDO

Archivo de prueba de conectividad que valida la conexión PDO a RDS con manejo de errores completo.

**Prácticas de seguridad aplicadas:**
- `ATTR_EMULATE_PREPARES => false`: fuerza el uso de sentencias preparadas reales en el servidor MySQL, lo que previene inyecciones SQL (el driver no construye el SQL en el cliente).
- `htmlspecialchars()` en todos los outputs: previene XSS (Cross-Site Scripting) convirtiendo `<`, `>`, `"`, `'` en sus equivalentes HTML.
- `ERRMODE_EXCEPTION`: los errores de BD lanzan excepciones capturables, nunca se muestran en crudo.

![Connexio PHP](/img/sprint2/37-connexio-php.png)

> 📸 **Figura 37** – Editor nano con el contenido completo de `connexio.php` incluyendo el bloque PDO con opciones de seguridad

#### `index.php` — Página principal

Página de menú estático con badges de estado y enlaces a los archivos de validación. Incluye el badge `HTTPS Activo` que confirma visualmente que el certificado SSL está activo.

![Index PHP](/img/sprint2/38-index-php.png)

> 📸 **Figura 38** – Editor nano con el contenido completo de `index.php` (HTML con badge `HTTPS Activo` y tarjetas de características)

#### `panel.php` — Panel de estado y consulta segura

Panel de validación funcional que ejecuta una consulta PDO segura para mostrar la versión de MySQL, el usuario conectado y la base de datos activa.

![Panel PHP](/img/sprint2/39-panel-php.png)

> 📸 **Figura 39** – Editor nano con el contenido completo de `panel.php` incluyendo la conexión PDO y la tabla HTML de estado

### 14.3 Pruebas de Conectividad

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
| php -v | PHP 8.5.4 (cli), Zend Engine v4.5.4 |
| curl -k https://localhost/ | HTML de index.php con NexOrder HTTPS Activo |
| curl -k https://localhost/connexio.php | ✅ Conexión exitosa a RDS MySQL 8.0 |
| curl -k https://localhost/panel.php | Tabla con versión MySQL, usuario y BD activa |

![PHP version](/img/sprint2/40-php-version.png)

> 📸 **Figura 40** – `php -v` mostrando `PHP 8.5.4 (cli)` con Zend Engine v4.5.4

![Curl index](/img/sprint2/41-curl-index.png)

> 📸 **Figura 41** – `curl -k https://localhost/` devolviendo el HTML de `index.php` con badge `HTTPS Activo`

![Curl connexio](/img/sprint2/42-curl-connexio.png)

> 📸 **Figura 42** – `curl -k https://localhost/connexio.php` mostrando `✅ Conexión exitosa a RDS MySQL 8.0`

![Curl panel](/img/sprint2/43-curl-panel.png)

> 📸 **Figura 43** – `curl -k https://localhost/panel.php` devolviendo la tabla de estado (primer intento muestra error de driver PDO que se resolvió después)

### 14.4 Resolución de Incidencia Firewalld

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

![Firewall cmd](/img/sprint2/44-firewall-cmd.png)

> 📸 **Figura 44** – Ejecución de los cuatro comandos `firewall-cmd` con salidas `success` y `--list-all` mostrando `services: dhcpv6-client http https mdns ssh`

### 14.5 Validación desde Navegador

Prueba final desde IP pública accediendo directamente con el navegador:

```bash
# Prueba desde la propia EC2 usando IP pública dinámica
curl -k https://$(curl -s https://checkip.amazonaws.com)/index.php

# Prueba de redirección HTTP→HTTPS
curl -L http://localhost/index.php | head -10
```

![Curl public](/img/sprint2/45-curl-public.png)

> 📸 **Figura 45** – `curl -k https://$(curl -s https://checkip.amazonaws.com)/index.php` devolviendo el HTML correcto de `index.php`

![Curl redirect](/img/sprint2/46-curl-redirect.png)

> 📸 **Figura 46** – `curl -L http://localhost/index.php | head -10` (muestra advertencia SSL por hostname 'localhost' vs CN '44.207.176.14')

**URL de acceso desde navegador externo:**
```
https://44.207.176.14/index.php
```

**Resultado:** La página `index.php` carga correctamente en el navegador con el badge `HTTPS Activo` y las dos tarjetas de características técnicas. El candado muestra "No seguro" porque es un certificado autofirmado (esperado).

![Chrome nexorder](/img/sprint2/47-chrome-nexorder.png)

> 📸 **Figura 47** – Navegador Chrome cargando `https://44.207.176.14/index.php` con la interfaz completa de NexOrder y badge `HTTPS Activo`

---

## Sprint 3: Monitorización y Resiliencia

**Fecha:** 27 de abril 2026 – 3 de mayo 2026  
**Módulos:** M0364 (Automatización) · M0367 (Backups) · M0368 (Auditoría) · C036 (Seguridad)

---

## 15. Arquitectura de Monitorización y Resiliencia

El Sprint 3 añade la capa de operaciones sobre la infraestructura y servicios de los sprints anteriores. Se implementan cinco pilares de resiliencia que garantizan la continuidad del negocio:

![Arquitectura](/img/sprint3/0-arquitectura.png)

> 📸 **Figura 0** – Arquitectura de operaciones: diagrama conceptual de los flujos de monitorización y resiliencia

---

## 16. T13: Script de Backup Automatizado

El objetivo es crear un sistema de backup lógico completamente automatizado que exporte la base de datos MySQL, la comprima, la versione con timestamp y gestione la retención automáticamente.

### 16.1 Preparación del Entorno

Antes de crear el script se preparan los directorios y permisos con un criterio de mínimo privilegio:

```bash
# 1. Crear el directorio donde se almacenarán los backups
sudo mkdir -p /backups

# 2. Crear el archivo de log de auditoría
sudo touch /var/log/nexorder_backup.log

# 3. Asignar propietario al usuario operativo (ec2-user)
sudo chown -R ec2-user:ec2-user /backups /var/log/nexorder_backup.log

# 4. Permisos seguros: solo el propietario puede leer/escribir
chmod 700 /backups
chmod 600 /var/log/nexorder_backup.log
```

**Justificación de permisos:**

| Recurso | Permiso | Razón |
|---------|---------|-------|
| `/backups` | 700 | Nadie más que `ec2-user` puede listar ni acceder a los backups (contienen datos sensibles) |
| `nexorder_backup.log` | 600 | El log incluye mensajes con nombres de BD; solo el propietario debe leerlo |

![Backup env setup](/img/sprint3/1-backup-env-setup.png)

> 📸 **Figura 1** – Terminal ejecutando los cinco comandos de preparación: `mkdir /backups`, `touch nexorder_backup.log`, `chown ec2-user`, `chmod 700` y `chmod 600`

### 16.2 Creación del Script

El script se coloca en `/usr/local/bin/` siguiendo la convención POSIX para ejecutables de administración:

```bash
sudo nano /usr/local/bin/backup_nexorder.sh
```

**Contenido completo del script disponible en:** [/docs/src/backup_nexorder.sh](/docs/src/backup_nexorder.sh)

```bash
# Hacer el script ejecutable
sudo chmod +x /usr/local/bin/backup_nexorder.sh
```

**Decisiones de diseño del script:**
- Pipeline `mysqldump | gzip`: evita escribir el SQL sin comprimir a disco. El archivo `.gz` ocupa entre 5 y 10 veces menos espacio.
- `$?` tras el pipe: verifica el código de salida del último comando. Si `mysqldump` falla, `gzip` recibirá stdin vacío y también fallará, propagando el error.
- `find -mtime +7 -delete`: implementa una política de retención de 7 días sin intervención manual.
- Timestamps en log: cada línea incluye fecha y hora exactas, creando una traza de auditoría completa.

![Backup script nano](/img/sprint3/2-backup-script-nano.png)

> 📸 **Figura 2** – Editor nano con el contenido completo de `backup_nexorder.sh` mostrando configuración, pipeline `mysqldump | gzip` y bloque `if [ $? -eq 0 ]`

![Backup chmod](/img/sprint3/3-backup-chmod.png)

> 📸 **Figura 3** – `sudo nano /usr/local/bin/backup_nexorder.sh` y `sudo chmod +x` del script

### 16.3 Prueba Manual

```bash
# Ejecutar el script manualmente
/usr/local/bin/backup_nexorder.sh

# Verificar el archivo generado
ls -lh /backups/

# Verificar el log de auditoría
tail -5 /var/log/nexorder_backup.log
```

**Resultado en `/backups/`:**
```
total 4.0K
-rw-r--r--. 1 ec2-user ec2-user 2.4K May 10 14:47 nexorder_db_20260510_144737.sql.gz
```

**Resultado en el log:**
```
[2026-05-10 14:47:37] [ÉXITO] Backup creado: nexorder_db_20260510_144737.sql.gz (4.0K)
[2026-05-10 14:47:37] [INFO] Limpieza de backups antiguos completada.
```

Las advertencias de `mysqldump` sobre GTIDs son normales en RDS gestionado y no afectan a la integridad del backup.

![Backup manual test](/img/sprint3/4-backup-manual-test.png)

> 📸 **Figura 4** – `ls -lh /backups/` mostrando el `.sql.gz` generado + `tail -5 nexorder_backup.log` con entradas `[ÉXITO]` y `[INFO] Limpieza`

---

## 17. T14: Programación con Cron

El objetivo es automatizar la ejecución del script de backup diariamente a las 03:00 AM, horario de mínima actividad del sistema.

### 17.1 Verificación de Permisos

Antes de configurar cron, se asegura que `ec2-user` puede escribir en el log:

```bash
# Verificar permisos actuales
ls -l /var/log/nexorder_backup.log

# Ajustar para que cron pueda escribir
sudo chown ec2-user:ec2-user /var/log/nexorder_backup.log
sudo chmod 664 /var/log/nexorder_backup.log
```

![Cron log permissions](/img/sprint3/5-cron-log-permissions.png)

> 📸 **Figura 5** – `ls -l` mostrando el log antes (`-rw-------`) y después (`-rw-rw-r--`) del ajuste de permisos con `chmod 664`

### 17.2 Instalación y Activación de Cronie

Amazon Linux 2023 no incluye `crond` por defecto; se instala el paquete `cronie`:

```bash
# Instalar el demonio cron
sudo dnf install cronie -y
```

**Versiones instaladas:** `cronie 1.5.7-1.amzn2023.0.2` y `cronie-anacron 1.5.7-1.amzn2023.0.2`

![Cronie install](/img/sprint3/6-cronie-install.png)

> 📸 **Figura 6** – `sudo dnf install cronie -y` instalando `cronie 1.5.7` y `cronie-anacron 1.5.7`

```bash
# Habilitar para arranque automático e iniciar inmediatamente
sudo systemctl enable crond
sudo systemctl start crond

# Verificar que el servicio está activo
sudo systemctl status crond
```

![Crond status](/img/sprint3/7-crond-status.png)

> 📸 **Figura 7** – `systemctl status crond` mostrando `active (running)` con PID 2562, con mensajes de inicio `CRON STARTUP (1.5.7)` e `inotify support`

### 17.3 Configuración del Crontab

```bash
# Editar el crontab del usuario actual (ec2-user)
crontab -e
```

**Línea añadida al final del archivo:**
```bash
# Backup diario NexOrder - 03:00 AM (T14)
0 3 * * * /usr/local/bin/backup_nexorder.sh >> /var/log/nexorder_backup.log 2>&1
```

**Explicación del formato cron:**
```
┌─ minuto (0-59)   → 0  (minuto 0, en punto)
│ ┌─ hora (0-23)   → 3  (03:00 AM)
│ │ ┌─ día mes     → *  (todos los días)
│ │ │ ┌─ mes       → *  (todos los meses)
│ │ │ │ ┌─ día sem → *  (todos los días de la semana)
│ │ │ │ │
0 3 * * * /usr/local/bin/backup_nexorder.sh >> /var/log/nexorder_backup.log 2>&1
```

**¿Por qué estas opciones?**

| Elemento | Valor | Razón |
|----------|-------|-------|
| `0 3 * * *` | 03:00 AM diario | Hora de mínima actividad; minimiza impacto en rendimiento |
| Ruta absoluta | `/usr/local/bin/...` | Cron no hereda el `$PATH` del usuario; las rutas relativas fallan |
| `>> log` | Append al log | Acumula historial sin sobreescribir registros anteriores |
| `2>&1` | Redirigir stderr a stdout | Captura tanto salida normal como errores en el mismo log |

![Crontab edit 1](/img/sprint3/8-crontab-edit-1.png)

> 📸 **Figura 8** – Editor crontab con el mensaje `installing new crontab` y la línea `0 3 * * *` añadida

![Crontab test mode](/img/sprint3/9-crontab-test-mode.png)

> 📸 **Figura 9** – Editor crontab mostrando la versión de prueba `* * * * *` (cada minuto) junto a la definitiva `0 3 * * *`

### 17.4 Verificación y Prueba

```bash
# Verificar que el crontab se guardó correctamente
crontab -l
```

**Resultado:**
```
0 3 * * * /usr/local/bin/backup_nexorder.sh >> /var/log/nexorder_backup.log 2>&1
```

Para validar sin esperar a las 03:00 AM, se ejecutó temporalmente con `* * * * *` (cada minuto), generando múltiples backups que confirman el funcionamiento correcto.

![Crontab verify](/img/sprint3/10-crontab-verify.png)

> 📸 **Figura 10** – `crontab -l` mostrando `0 3 * * * /usr/local/bin/backup_nexorder.sh >> /var/log/nexorder_backup.log 2>&1`

![Backups listing](/img/sprint3/11-backups-listing.png)

> 📸 **Figura 11** – `ls -lh /backups/` con 6 archivos `.sql.gz` timestamped generados durante la prueba con `* * * * *`

---

## 18. T15: Rotación de Logs con Logrotate

Sin rotación de logs, los archivos de Apache y MySQL crecen indefinidamente hasta llenar el disco. `logrotate` automatiza el corte, compresión y eliminación de registros antiguos.

### 18.1 Configuración para Apache (httpd)

Se edita el archivo existente (eliminando duplicados para evitar error `duplicate log entry`):

```bash
sudo nano /etc/logrotate.d/httpd
```

**Contenido aplicado:**
```apache
/var/log/httpd/*log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    sharedscripts
    postrotate
        /bin/systemctl reload httpd.service > /dev/null 2>/dev/null || true
    endscript
}
```

**Explicación de cada directiva:**

| Directiva | Función |
|-----------|---------|
| `daily` | Rota los logs cada día |
| `rotate 7` | Conserva los últimos 7 archivos rotados (7 días de historial) |
| `compress` | Comprime los archivos rotados con gzip, ahorrando espacio |
| `missingok` | No falla si el archivo de log no existe |
| `notifempty` | No rota si el archivo está vacío |
| `sharedscripts` | Ejecuta `postrotate` una sola vez aunque haya varios archivos coincidentes |
| `postrotate reload` | Envía señal a Apache para abrir nuevos descriptores sin reiniciar el servicio |

El `postrotate` es crítico: sin él, Apache seguiría escribiendo en el archivo antiguo (ya renombrado por logrotate) porque mantiene el descriptor de fichero abierto.

![Logrotate httpd open](/img/sprint3/12-logrotate-httpd-open.png)

> 📸 **Figura 12** – Terminal con `sudo nano /etc/logrotate.d/httpd` abriendo el archivo de configuración

![Logrotate httpd content 1](/img/sprint3/13-logrotate-httpd-content-1.png)

> 📸 **Figura 13** – Editor nano con el bloque completo de logrotate para `/var/log/httpd/*log` incluyendo `postrotate` con `systemctl reload`

![Logrotate httpd debug](/img/sprint3/14-logrotate-httpd-debug.png)

> 📸 **Figura 14** – Salida de `sudo logrotate -d /etc/logrotate.d/httpd` mostrando `rotating log /var/log/httpd/access_log after 1 days (7 rotations)` sin errores

### 18.2 Configuración para MySQL

```bash
sudo nano /etc/logrotate.d/mysql
```

**Contenido:**
```apache
/var/log/mysqld.log {
    daily
    rotate 7
    copytruncate
    missingok
    compress
    notifempty
}
```

**¿Por qué `copytruncate` en lugar de `postrotate`?** MySQL mantiene el archivo de log abierto con un descriptor bloqueado. Con `copytruncate`, logrotate primero copia el contenido al archivo rotado y luego trunca el original a 0 bytes, sin necesidad de enviar señales al proceso MySQL (que en RDS no es accesible directamente).

![Logrotate mysql open](/img/sprint3/15-logrotate-mysql-open.png)

> 📸 **Figura 15** – Terminal con `sudo nano /etc/logrotate.d/mysql` abriendo el archivo

![Logrotate mysql content 1](/img/sprint3/16-logrotate-mysql-content-1.png)

> 📸 **Figura 16** – Editor nano con `/etc/logrotate.d/mysql` mostrando `copytruncate` y el bloque completo + salida de `logrotate -d` en modo debug

---

## 19. T16: CloudWatch y Alertas Proactivas

CloudWatch transforma la monitorización de reactiva (revisar el servidor cuando algo falla) a proactiva (recibir alertas antes de que el problema afecte a los usuarios).

### 19.1 Acceso a CloudWatch

Se accede a la consola AWS → búsqueda del servicio → CloudWatch. La página de Overview muestra el estado inicial sin alarmas ni paneles configurados.

![CloudWatch search](/img/sprint3/17-cloudwatch-search.png)

> 📸 **Figura 17** – Navegador con la consola AWS y búsqueda de "CloudWatch", mostrando el resultado `CloudWatch - Monitorice recursos y aplicaciones`

![CloudWatch overview](/img/sprint3/18-cloudwatch-overview.png)

> 📸 **Figura 18** – Página de Overview de CloudWatch con el asistente de configuración inicial y las 4 opciones principales (Crear alarmas, Panel, Registros, Eventos)

### 19.2 Creación de Alarma CPU

Se navega a Alarmas → Crear alarma y se selecciona la métrica `CPUUtilization` de la instancia EC2.

**Ruta:** `EC2 > Per-Instance Metrics > 09NexOrder-EC2-WEB-09 > CPUUtilization`

**Parámetros de la alarma:**

| Parámetro | Valor | Razón |
|-----------|-------|-------|
| **Métrica** | CPUUtilization | KPI más crítico de un servidor web |
| **Namespace** | AWS/EC2 | Métrica nativa de EC2, sin agente adicional |
| **Instance ID** | i-0959d7cac425606cf | Específica de `09NexOrder-EC2-WEB-09` |
| **Estadística** | Media | Evalúa el valor promedio del período |
| **Período** | 1 minuto | Evaluación granular para respuesta rápida |
| **Tipo de límite** | Estático | Umbral fijo y predecible |
| **Condición** | Mayor que (`>`) 80 | Alerta cuando la CPU supera el 80% |

**Lógica de activación:** si el valor medio de `CPUUtilization` supera el 80% durante un período de 1 minuto, la alarma pasa de `OK` a `En Alarma`, disparando inmediatamente la acción SNS configurada.

![CloudWatch metric select](/img/sprint3/19-cloudwatch-metric-select.png)

> 📸 **Figura 19** – Selector de métricas CloudWatch con `CPUUtilization` de `09NexOrder-EC2-WEB-09` seleccionado (checkbox marcado) y gráfico de línea visible

![CloudWatch alarm conditions](/img/sprint3/20-cloudwatch-alarm-conditions.png)

> 📸 **Figura 20** – Formulario de condiciones: umbral Estático `> 80`, período 1 minuto, instancia `09NexOrder-EC2-WEB-09`, gráfico con la línea roja en 80%

### 19.3 Configuración de Acciones SNS

Una vez definida la métrica y el umbral, se configura la acción automática al saltar la alarma:

- **Activador:** Estado `En modo alarma`
- **Acción:** Enviar notificación al tema SNS `Default_CloudWatch_Alarms_Topic`
- **Correo suscrito:** `victor.serrano.7e8@itb.cat`

Amazon SNS requiere confirmación de la suscripción por email como medida de seguridad. Tras confirmar, la suscripción queda activa con ARN:

`arn:aws:sns:us-east-1:324341945465:Default_CloudWatch_Alarms_Topic:52cc3e53-d32b-40d8-9285-167f14515f4e`

**Nombre de la alarma:** `Alarma_CPU_NexOrder_Serrano`  
**Descripción:** `Aviso cuando la CPU supera el 80%`

![CloudWatch SNS action](/img/sprint3/21-cloudwatch-sns-action.png)

> 📸 **Figura 21** – Formulario "Configurar las acciones" con `En modo alarma` seleccionado, tema SNS `Default_CloudWatch_Alarms_Topic` y email `victor.serrano.7e8@itb.cat`

![SNS subscription confirmed](/img/sprint3/22-sns-subscription-confirmed.png)

> 📸 **Figura 22** – Página AWS SNS con `¡Suscripción confirmada!` y el ARN completo de la suscripción

![CloudWatch alarm details](/img/sprint3/23-cloudwatch-alarm-details.png)

> 📸 **Figura 23** – Formulario "Agregar detalles de alarma" con nombre `Alarma_CPU_NexOrder_Serrano` y descripción `Aviso cuando la CPU supera el 80%`

![CloudWatch alarm preview](/img/sprint3/24-cloudwatch-alarm-preview.png)

> 📸 **Figura 24** – Página "Ver la vista previa y crear" con los 3 pasos resumidos: métrica CPU, acción SNS y nombre de la alarma antes de confirmar la creación

![CloudWatch alarm created](/img/sprint3/25-cloudwatch-alarm-created.png)

> 📸 **Figura 25** – Banner verde `Se ha creado correctamente la alarma Alarma_CPU_NexOrder_Serrano` en el listado de alarmas con estado `Datos insuficientes`

### 19.4 Dashboard Personalizado y Métricas EBS

Se crea un dashboard centralizado para visualizar en tiempo real los indicadores más importantes:

**Nombre del dashboard:** `Dashboard_NexOrder_Serrano`

**Widgets configurados:**
1. **Widget tipo Línea** – `CPUUtilization`: permite observar la tendencia de la CPU a lo largo del tiempo e identificar picos de actividad.
2. **Widget tipo Número** – `VolumeReadBytes` y `VolumeWriteBytes` (EBS): muestra el valor exacto e instantáneo de bytes leídos y escritos en disco. Métricas seleccionadas desde `EBS > Métricas por volumen` para el volumen `vol-0673cc270ab121...`.

**¿Por qué monitorizar EBS?** Un disco saturado en lecturas o escrituras puede causar degradación de rendimiento en Apache y MySQL. Detectar esta saturación permite actuar antes de que los tiempos de respuesta se disparen.

![Dashboard create](/img/sprint3/26-dashboard-create.png)

> 📸 **Figura 26** – Diálogo modal "Crear un nuevo panel" con nombre `Dashboard_NexOrder_Serrano` y botón `Crear un panel`

![Dashboard final](/img/sprint3/27-dashboard-final.png)

> 📸 **Figura 27** – Panel final `Dashboard_NexOrder_Serrano` con widget de línea `CPUUtilization` y widgets de número `VolumeReadBytes` (0 B) y `VolumeWriteBytes` (694 kB)

![Widget type selector](/img/sprint3/28-widget-type-selector.png)

> 📸 **Figura 28** – Selector de tipo de widget con `Línea` seleccionado; opciones visibles: Tabla, Número, Medidor, Área apilada, Barra, Gráfico circular, Explorador

![Widget CPU number](/img/sprint3/29-widget-cpu-number.png)

> 📸 **Figura 29** – Selector de métricas con `CPUUtilization` de `NexOrder-EC2-Web` marcado; tipo de widget cambiado a `Número`

![Widget CPU line graph](/img/sprint3/30-widget-cpu-line-grap.png)

> 📸 **Figura 30** – Pantalla "Añadir gráfico de métrica" con `CPUUtilization` seleccionado y lista completa de métricas EC2 disponibles

![EBS namespace selector](/img/sprint3/31-ebs-namespace-selector.png)

> 📸 **Figura 31** – Selector de categorías de métricas con el namespace `EBS` (30 métricas) destacado en la lista

![EBS metrics selected](/img/sprint3/32-ebs-metrics-selected.png)

> 📸 **Figura 32** – Lista de métricas EBS con `VolumeReadBytes` y `VolumeWriteBytes` del volumen `vol-0673cc270ab121...` seleccionados; gráfico de previsualización con ambas curvas (azul y naranja)

---

## 20. T17: Script de Despliegue Continuo

El objetivo es automatizar la transferencia de archivos desde un entorno de staging hacia el `DocumentRoot` de Apache, con validación de errores y registro de auditoría completo.

### 20.1 Preparación del Entorno

```bash
# 1. Crear la carpeta de staging (área de preparación antes de producción)
mkdir -p /home/ec2-user/web-staging

# 2. Crear el archivo de log del despliegue
sudo touch /var/log/deploy_nexorder.log

# 3. Asignar propietario para poder escribir sin sudo
sudo chown ec2-user:ec2-user /var/log/deploy_nexorder.log
```

**¿Por qué un directorio de staging?** Permite preparar y revisar los archivos antes de hacerlos públicos. El script hace un espejo exacto del staging en producción, por lo que solo lo que está en staging llega a la web.

![Deploy env setup](/img/sprint3/33-deploy-env-setup.png)

> 📸 **Figura 33** – Terminal ejecutando `mkdir -p /home/ec2-user/web-staging`, `touch /var/log/deploy_nexorder.log` y `chown ec2-user` del log

### 20.2 Creación del Script

```bash
sudo nano /usr/local/bin/deploy_nexorder.sh
```

**Contenido del script con las correcciones aplicadas para Amazon Linux 2023 disponible en:** [/docs/src/desploy_nexorder.sh](/docs/src/desploy_nexorder.sh)

```bash
sudo chmod +x /usr/local/bin/deploy_nexorder.sh
```

**Decisiones de diseño:**
- `sudo rsync`: `/var/www/html/` pertenece al usuario `apache`. Sin `sudo`, el script fallaría al escribir en él.
- `systemctl reload httpd` (no `restart`): `reload` recarga la configuración sin interrumpir las conexiones activas.
- `--delete`: garantiza que producción sea un espejo exacto del staging. Sin esta opción, los archivos eliminados del staging permanecerían en producción.
- Doble validación `$?`: se verifica por separado el éxito de `rsync` y del `reload`, con mensajes específicos para cada fallo.

![Deploy script nano](/img/sprint3/34-deploy-script-nano.png)

> 📸 **Figura 34** – Editor nano con el contenido completo de `deploy_nexorder.sh` mostrando la configuración, el bloque `rsync -avz --delete` y la lógica de validación `$?`

### 20.3 Simulación y Validación

```bash
# 1. Crear archivo de prueba en staging
sudo nano /home/ec2-user/web-staging/version2.html

# 2. Ejecutar el despliegue
/usr/local/bin/deploy_nexorder.sh

# 3. Verificar que el archivo llegó a producción
ls -l /var/www/html/version2.html

# 4. Verificar el log de auditoría
tail -10 /var/log/deploy_nexorder.log

# 5. Probar acceso HTTP (debe redirigir a HTTPS)
curl -I http://localhost/version2.html

# 6. Probar acceso HTTPS directo
curl -k https://localhost/version2.html
```

**Resultado del log:**
```
[2026-05-10 16:13:52] --- INICIO DESPLIEGUE ---
[2026-05-10 16:13:52] Sincronización de archivos completada exitosamente.
[2026-05-10 16:13:52] Recargando servicio httpd para aplicar cambios...
[2026-05-10 16:13:52] Servicio httpd recargado correctamente.
[2026-05-10 16:13:52] DESPLIEGUE COMPLETADO CON EXITO
[2026-05-10 16:13:52] === FIN DESPLIEGUE ===
```

![Staging version2 html](/img/sprint3/35-staging-version2-html.png)

> 📸 **Figura 35** – Editor nano con el contenido de `version2.html` (HTML de prueba con título `NexOrder v2.0` y mensaje de despliegue exitoso)

![Deploy verification log](/img/sprint3/36-deploy-verification-log.png)

> 📸 **Figura 36** – `ls -l /var/www/html/version2.html` confirmando el archivo en producción (229 bytes, May 10 16:13) + `tail -10 /var/log/deploy_nexorder.log` con las 6 líneas de auditoría del despliegue exitoso

![Deploy curl test](/img/sprint3/37-deploy-curl-test.png)

> 📸 **Figura 37** – `curl -I http://localhost/version2.html` devolviendo `301 Moved Permanently` + `curl -k https://localhost/version2.html` devolviendo el HTML completo de `NexOrder v2.0`

---

## 21. T18: Prueba de Restauración y RTO

El RTO (Recovery Time Objective) es el tiempo máximo tolerable para restaurar un servicio tras una caída. Esta tarea mide el RTO real del sistema bajo condiciones controladas.

### 21.1 Verificación del Backup Disponible

```bash
# Anotar hora de inicio (para calcular RTO después)
date
# Resultado: Tue May 12 14:42:27 UTC 2026

# Verificar los backups disponibles
ls -lh /backups/*.sql.gz

# Crear el informe de restauración
nano ~/restore_test.md
```

**Backups disponibles:**
```
-rw-r--r--. 1 ec2-user ec2-user 2.4K May 11 14:00 nexorder_db_20260511_140001.sql.gz
-rw-r--r--. 1 ec2-user ec2-user 2.4K May 12 14:00 nexorder_db_20260512_140001.sql.gz
```

![Restore start verify](/img/sprint3/38-restore-start-verify.png)

> 📸 **Figura 38** – `date` mostrando `Tue May 12 14:42:27 UTC 2026` + `ls -lh /backups/*.sql.gz` con los archivos disponibles + `nano ~/restore_test.md` con el informe inicial

![Restore report initial](/img/sprint3/39-restore-report-initial.png)

> 📸 **Figura 39** – Editor nano con el contenido inicial de `restore_test.md` con los campos pendientes de completar

### 21.2 Simulación de Caída (DROP DATABASE)

```bash
# Conectar como administrador a RDS
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u admin -p
```

**Dentro de MySQL (`connection id 5249`):**
```sql
-- Verificar que la BD existe
SHOW DATABASES LIKE 'nexorder_db';

-- Acceder a la BD y ver sus tablas actuales
USE nexorder_db;
SHOW TABLES;    -- 5 tablas: detalle_pedidos, estados, pedidos, productos, usuarios

-- SIMULAR CAÍDA CRÍTICA: eliminar la BD completa
DROP DATABASE nexorder_db;
-- Query OK, 5 rows affected (0.17 sec)

-- Verificar que ya no existe
SHOW DATABASES LIKE 'nexorder_db';
-- Empty set (0.00 sec)

EXIT;
```

La BD `nexorder_db` con sus 5 tablas ha sido eliminada. El sistema está en estado de fallo crítico.

![Drop database simulation](/img/sprint3/40-drop-database-simulation.png)

> 📸 **Figura 40** – Login MySQL con `connection id 5249`

![Drop database](/img/sprint3/41-drop-database.png)

> 📸 **Figura 41** – `SHOW DATABASES`, `USE nexorder_db`, `SHOW TABLES` (5 tablas), `DROP DATABASE nexorder_db` con `Query OK` y `SHOW DATABASES` final devolviendo `Empty set`

### 21.3 Restauración desde Backup

La restauración en RDS requiere filtrar las sentencias `SET @@SESSION.SQL_LOG_BIN` y `SET @@GLOBAL` del dump, ya que estas requieren el privilegio `SUPER` que AWS no concede en RDS gestionado:

```bash
# Restaurar filtrando las sentencias incompatibles con RDS
gunzip -c /backups/nexorder_db_20260512_140001.sql.gz \
  | grep -v "SET @@SESSION.SQL_LOG_BIN" \
  | grep -v "SET @@GLOBAL" \
  | mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com \
          -u admin -p nexorder_db
```

**¿Por qué el filtrado?** `mysqldump` incluye comandos de configuración de replicación (`SET @@SESSION.SQL_LOG_BIN=0`) que requieren privilegios de superusuario. En Amazon RDS, AWS no concede `SUPER` por razones de seguridad del servicio gestionado. El filtrado con `grep -v` elimina estas líneas sin afectar a los datos.

![Restore gunzip mysql](/img/sprint3/42-restore-gunzip-mysql.png)

> 📸 **Figura 42** – Terminal con `gunzip -c backup.sql.gz | grep -v "SET @@SESSION..." | grep -v "SET @@GLOBAL" | mysql ...` + verificación posterior con `SHOW TABLES` mostrando las 5 tablas restauradas

### 21.4 Verificación de Integridad

```bash
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u admin -p
USE nexorder_db;
SHOW TABLES;

SELECT COUNT(*) as productos FROM productos;   -- 7
SELECT COUNT(*) as usuarios FROM usuarios;     -- 2
SELECT COUNT(*) as estados FROM estados;       -- 5

SELECT nombre, precio FROM productos LIMIT 3;
```

**Resultado de integridad:**

| Tabla | Registros | Estado |
|-------|-----------|--------|
| productos | 7 | ✅ Íntegro |
| usuarios | 2 | ✅ Íntegro |
| estados | 5 | ✅ Íntegro |
| pedidos | 0 | ✅ OK (vacía por diseño) |
| detalle_pedidos | 0 | ✅ OK (vacía por diseño) |

Los datos de prueba (`Ensalada César $8.50`, `Pizza Margarita $12.00`, `Hamburguesa Clásica $10.50`) están presentes y son correctos.

![Restore integrity check](/img/sprint3/43-restore-integrity-check.png)

> 📸 **Figura 43** – MySQL mostrando `SHOW TABLES` (5 tablas), `COUNT(*)` de productos (7), usuarios (2) y estados (5), y `SELECT nombre, precio FROM productos LIMIT 3` con datos reales

### 21.5 Cálculo del RTO

```bash
# Anotar hora de finalización
date
# Resultado: Tue May 12 15:06:28 UTC 2026
```

**Cálculo:**
```
Hora inicio (fallo detectado):  14:42:27
Hora fin   (sistema restaurado): 15:06:28
────────────────────────────────────────
RTO real:                        0h 24m 01s
```

**Informe final `~/restore_test.md` disponible en:** [/docs/src/restore_test.md](/docs/src/restore_test.md)

![RTO calculation](/img/sprint3/44-rto-calculation.png)

> 📸 **Figura 44** – `date` mostrando `Tue May 12 15:06:28 UTC 2026` con el cálculo manual `15:06:28 - 14:42:27 = 0:24:01`

![Restore report final](/img/sprint3/45-restore-report-final.png)

> 📸 **Figura 45** – Editor nano con `restore_test.md` completado: hora inicio, hora fin, RTO calculado y resultado final con los tres checks

---

## 22. T19: Auditoría de Seguridad con nmap

La auditoría valida que la superficie de exposición del servidor es mínima: solo los puertos estrictamente necesarios están abiertos desde Internet.

**Herramienta:** nmap 7.95 ejecutado desde máquina Kali Linux (`kali@VictorS`)

```bash
nmap -p 1-1000 -T4 -A -V 44.207.176.14
```

**Parámetros:**

| Flag | Función |
|------|---------|
| `-p 1-1000` | Escanea el rango de puertos más comunes |
| `-T4` | Velocidad agresiva (apropiada para redes de confianza) |
| `-A` | Detección de OS, versiones de servicios y scripts NSE |
| `-V` | Verbose: información detallada del progreso |

**Resultado del escaneo:**

| Puerto | Estado | Servicio |
|--------|--------|----------|
| 22/tcp | Abierto | SSH (restringido a IP admin por Security Group) |
| 80/tcp | Abierto | HTTP (redirige automáticamente a HTTPS) |
| 443/tcp | Abierto | HTTPS (TLS con certificado autofirmado) |

**Interpretación:**
- Solo 3 puertos abiertos en el rango 1-1000: superficie de ataque mínima, consistente con la política de mínimo privilegio aplicada desde el Sprint 1.
- Puerto 3306 (MySQL) cerrado: la BD no es alcanzable desde Internet (solo desde `SG-Web-NexOrder` por Security Group).
- Conexión estable: baja latencia entre la máquina Kali y el servidor AWS confirma conectividad correcta.
- Ningún servicio innecesario expuesto: no hay APIs internas, paneles de administración ni servicios de datos accesibles públicamente.

![Nmap scan result](/img/sprint3/46-nmap-scan-result.png)

> 📸 **Figura 46** – Terminal Kali Linux (`kali@VictorS`) ejecutando `nmap -p 1-1000 -T4 -A -V 44.207.176.14` con la salida completa del escaneo mostrando el progreso de NSE scripts y el resultado final

---
## Acceso Rápido a Scripts y Configuraciones


```
/docs/src/
├── [backup_nexorder.sh](/docs/src/backup_nexorder.sh)     # Script backup automatizado (T13)
├── [deploy_nexorder.sh](/docs/src/deploy_nexorder.sh)     # Script despliegue continuo (T17)
├── [restore_test.md](/docs/src/restore_test.md)           # Informe prueba DR + RTO (T18)
├── [jail.local](/docs/src/jail.local)                     # Configuración Fail2ban (T09)
├── [nexorder-ssl.conf](/docs/src/nexorder-ssl.conf)       # VirtualHost HTTPS + HSTS (T08)
├── [nexorder_schema.sql](/docs/src/nexorder_schema.sql)   # Esquema completo BD (T10)
├── [connexio.php](/docs/src/connexio.php)                 # Motor conexión PDO (T12)
├── [panel.php](/docs/src/panel.php)                       # Panel estado + consulta segura (T12)
└── [index.php](/docs/src/index.php)                       # Página principal menú (T12)
```


---


## Comandos de Emergencia (Quick Reference)


### Restaurar Base de Datos
```bash
# 1. Verificar backup disponible
ls -lh /backups/*.sql.gz | tail -1


# 2. Restaurar (filtrando sentencias incompatibles con RDS)
gunzip -c /backups/nexorder_db_*.sql.gz \
  | grep -v "SET @@SESSION.SQL_LOG_BIN" \
  | grep -v "SET @@GLOBAL" \
  | mysql -h <ENDPOINT> -u admin -p nexorder_db


# 3. Verificar integridad
mysql -h <ENDPOINT> -u admin -p -e "USE nexorder_db; SHOW TABLES; SELECT COUNT(*) FROM productos;"
```


### Revertir Despliegue (Rollback)
```bash
# 1. Copiar versión anterior desde backup o staging
sudo rsync -avz --delete /home/ec2-user/web-staging-backup/ /var/www/html/


# 2. Recargar Apache
sudo systemctl reload httpd


# 3. Verificar
curl -k https://localhost/
```


### Desbloquear IP en Fail2ban
```bash
# Ver IPs bloqueadas
sudo fail2ban-client status sshd


# Desbanear IP específica
sudo fail2ban-client set sshd unbanip <IP>


# Reiniciar jail si es necesario
sudo fail2ban-client reload
```


### Verificar Estado de Servicios
```bash
# Servicios críticos
systemctl status httpd crond fail2ban


# Puertos activos
ss -tlnp | grep -E ':(80|443|22|3306)'


# Espacio en disco
df -h / /backups /var/log
```

---


## Contacto del Equipo


| Rol | Nombre | Canal |
|-----|--------|-------|
| Responsable Infraestructura | Victor Serrano | victor.serrano@nexorder.local |
| Responsable Seguridad | Trishan Mizhquiri | trishan.mizhquiri@email.com |
| Emergencias 24/7 | Equipo NexOrder | SNS Topic: `NexOrder_Alerts` |


---

**Documentación completada:** 13 de abril – 12 de mayo 2026  
**Responsables:** Victor Serrano · Trishan Mizhquiri  
**Repositorio:** GitHub + documentación Markdown + evidencias ProofHub
 
> **Nota de Seguridad:** Contraseñas y claves sensibles gestionadas mediante gestor de contraseñas externo (no almacenadas en documentación).
