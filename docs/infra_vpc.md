# Documentación Técnica – Infraestructura VPC Sprint 1

**Proyecto:** NexOrder Infrastructure

**Responsables:** Victor Serrano, Trishan Mizhquiri

**Fecha:** 13 de abril 2025 – 19 de abril 2025

**Módulos:** M0370 (Planificación de redes) · M0369 (Integración de ordenadores en red)

---

##  Índice

1. [Arquitectura de Red](#1-arquitectura-de-red)
2. [TA01: VPC y Subredes](#2-ta01-vpc-y-subredes)
   - [2.1 Creación de la VPC](#21-creación-de-la-vpc)
   - [2.2 Subred Pública](#22-subred-pública)
   - [2.3 Subred Privada](#23-subred-privada)
   - [2.4 Validación de Subredes](#24-validación-de-subredes)
3. [TA02: Internet Gateway y Enrutamiento](#3-ta02-internet-gateway-y-enrutamiento)
   - [3.1 Internet Gateway (IGW)](#31-internet-gateway-igw)
   - [3.2 Tablas de Enrutamiento](#32-tablas-de-enrutamiento)
4. [TA03: Instancias EC2 y RDS](#4-ta03-instancias-ec2-y-rds)
   - [4.1 Instancia EC2](#41-instancia-ec2)
   - [4.2 Instancia RDS MySQL](#42-instancia-rds-mysql)
   - [4.3 Conexión SSH Inicial](#43-conexión-ssh-inicial)
   - [4.4 Prueba EC2 → RDS](#44-prueba-de-conexión-ec2--rds)
5. [TA04: Security Groups](#5-ta04-security-groups)
   - [5.1 SG-Web-NexOrder](#51-sg-web-nexorder)
   - [5.2 SG-DB-NexOrder](#52-sg-db-nexorder)
6. [TA05: Hardening del Sistema](#6-ta05-hardening-del-sistema)
   - [6.1 Actualización de Paquetes](#61-actualización-de-paquetes)
   - [6.2 Usuario Administrativo Restringido](#62-usuario-administrativo-restringido)
   - [6.3 Hardening de SSH](#63-hardening-de-ssh)
   - [6.4 Reinicio y Validación](#64-reinicio-y-validación-del-servicio)
   - [6.5 Prueba con nexadmin](#65-prueba-con-usuario-nexadmin)
7. [Verificación Final de Conectividad](#7-verificación-final-de-conectividad)
8. [Justificación de Criterios](#8-justificación-de-criterios)

---

## 1. Arquitectura de Red

La infraestructura de NexOrder sigue un modelo de red en **dos capas** dentro de una única VPC en AWS región `us-east-1`:

- **Capa pública** (`10.0.1.0/23`): expuesta a Internet, alberga el servidor web EC2.
- **Capa privada** (`10.0.2.0/23`): sin acceso directo a Internet, alberga la base de datos RDS.

Este diseño aplica el principio de **defensa en profundidad**: incluso si el servidor web fuera comprometido, un atacante no podría alcanzar la base de datos directamente desde Internet.

![Figura 0](/img/sprint1/0-diagrama-logico.png) 
> 📸 **Figura 0 – Arquitectura lógica:** diagrama conceptual de la red

---

## 2. TA01: VPC y Subredes

### 2.1 Creación de la VPC

La VPC es el contenedor lógico de toda la infraestructura. Se crea con un bloque CIDR `/16` para disponer de espacio suficiente para crecer en subredes sin necesidad de re-diseñar la red.

| Parámetro | Valor |
|-----------|-------|
| Nombre | `VPC-NexOrder` |
| CIDR IPv4 | `10.0.0.0/16` |
| IPv6 | Deshabilitado |
| Tenencia | Predeterminada |
| ID resultante | `vpc-0905a60eb17e6565f` |
| Región | `us-east-1` (Norte de Virginia) |

**¿Por qué `/16`?** Un bloque `/16` proporciona 65.536 direcciones IP. Esto permite crear múltiples subredes `/23` (246 IPs cada una) sin que se solapen, dejando margen para entornos de staging, QA o microservicios futuros.

![Figura 1](/img/sprint1/1-creación-vpc.png) 
> 📸 **Figura 1 – Panel AWS de creación de VPC:** con CIDR `10.0.0.0/16` y etiqueta `Name=VPC-NexOrder`

![Figura 2](/img/sprint1/2-formulario-vpc.png) 
> 📸 **Figura 2 – Formulario de configuración completo:** IPv6 deshabilitado, tenencia predeterminada


---

### 2.2 Subred Pública

La subred pública alberga los recursos que deben ser accesibles desde Internet (servidor web, balanceadores de carga, etc.).

| Parámetro | Valor |
|-----------|-------|
| Nombre | `Subnet-Publica-Web` |
| CIDR | `10.0.1.0/23` (246 IPs) |
| Zona de Disponibilidad | `us-east-1a` |
| VPC | `vpc-0905a60eb17e6565f` |
| ID resultante | `subnet-0b18a1ba9a8bbb7ad` |

![Figura 3](/img/sprint1/3-subnet-publica.png) 
> 📸 **Figura 3 – Configuración de Subnet-Publica-Web:** con CIDR `10.0.1.0/23` (subred 1 de 2)


---

### 2.3 Subred Privada

La subred privada alberga la base de datos. Al no tener ruta a Internet, sus recursos solo son accesibles desde dentro de la VPC.

| Parámetro | Valor |
|-----------|-------|
| Nombre | `Subnet-Privada-D` |
| CIDR | `10.0.2.0/23` (246 IPs) |
| Zona de Disponibilidad | `us-east-1a` |
| VPC | `vpc-0905a60eb17e6565f` |
| ID resultante | `subnet-06db775e1d4b17a88` |

![Figura 4](/img/sprint1/4-subnet-privada.png) 
> 📸 **Figura 4 – Configuración de Subnet-Privada-D:** con CIDR `10.0.2.0/23` (subred 2 de 2)

---

### 2.4 Validación de Subredes

Tras la creación, AWS confirma que ambas subredes están en estado `Available` y asociadas a la VPC correcta.

| Nombre | ID de Subred | CIDR | Estado |
|--------|-------------|------|--------|
| Subnet-Publica-Web | subnet-0b18a1ba9a8bbb7ad | 10.0.1.0/23 | ✅ Available |
| Subnet-Privada-D | subnet-06db775e1d4b17a88 | 10.0.2.0/23 | ✅ Available |

![Figura 5](/img/sprint1/5-listado-subredes.png) 
> 📸 **Figura 5 – Listado de subredes creadas:** con estado `Available` en la consola AWS

---

## 3. TA02: Internet Gateway y Enrutamiento

### 3.1 Internet Gateway (IGW)

El Internet Gateway (IGW) es el componente que conecta la VPC con Internet. Sin él, ningún recurso dentro de la VPC podría comunicarse con el exterior.

| Parámetro | Valor |
|-----------|-------|
| Nombre | `IGW-NexOrder` |
| ID resultante | `igw-099e10b6c7e172a24` |
| VPC asociada | `vpc-0905a60eb17e6565f` |

**Proceso:**
1. Se crea el IGW con el nombre `IGW-NexOrder`.
2. Se asocia a la VPC mediante la opción **"Asociar a una VPC"**.

![Figura 6](/img/sprint1/6-panel-igw.png) 
> 📸 **Figura 6 – Formulario de creación de IGW-NexOrder**

![Figura 7](/img/sprint1/7-asociacion-igw.png) 
> 📸 **Figura 7 – Asociación del IGW:** a `vpc-0905a60eb17e6565f`

---

### 3.2 Tablas de Enrutamiento

Se crean **dos tablas de enrutamiento independientes** para implementar una separación estricta del tráfico entre la capa pública y la privada. Las asociaciones son **explícitas** (no se usa la tabla principal de la VPC para ningún recurso crítico).

#### RT-Publica-NexOrder

**ID:** `rtb-0e78fa3e4905a11fd`
**Asociada a:** `Subnet-Publica-Web`

| Destino | Objetivo | Estado | Propósito |
|---------|----------|--------|-----------|
| `10.0.0.0/16` | local | ✅ Activo | Comunicación intra-VPC |
| `0.0.0.0/0` | `igw-099e10b6c7e172a24` | ✅ Activo | Acceso bidireccional a Internet |

**¿Por qué añadimos `0.0.0.0/0 → IGW`?** Esta ruta indica que cualquier tráfico destinado a una IP fuera de la VPC debe salir a través del Internet Gateway. Sin ella, el servidor web podría existir en la subred, pero ningún usuario externo podría alcanzarlo ni la instancia podría descargar actualizaciones.

![Figura 8](/img/sprint1/8-rt-publica.png) 
> 📸 **Figura 8 – Tabla de enrutamiento pública:** con asociación explícita a `Subnet-Publica-Web` (CIDR `10.0.1.0/23`)

![Figura 9](/img/sprint1/9-edicion-rutas.png) 
> 📸 **Figura 9 – Edición de rutas:** `0.0.0.0/0` apuntando a `igw-099e10b6c7e172a24`


#### RT-Privada-NexOrder

**ID:** `rtb-0886f3878f7e26479`
**Asociada a:** `Subnet-Privada-D`

| Destino | Objetivo | Estado | Propósito |
|---------|----------|--------|-----------|
| `10.0.0.0/16` | local | ✅ Activo | Solo comunicación intra-VPC |

Esta tabla **no contiene** ninguna ruta `0.0.0.0/0`, lo que garantiza que la base de datos nunca pueda ser alcanzada directamente desde Internet ni pueda iniciar conexiones salientes hacia él.

![Figura 10](/img/sprint1/10-rt-privada.png) 
> 📸 **Figura 10 – Tabla de enrutamiento privada:** con asociación explícita a `Subnet-Privada-D` (CIDR `10.0.2.0/23`), sin ruta a Internet
---

## 4. TA03: Instancias EC2 y RDS

### 4.1 Instancia EC2

La instancia EC2 actúa como servidor web de la aplicación NexOrder, situado en la subred pública para ser accesible desde Internet.

| Parámetro | Valor |
|-----------|-------|
| Nombre | `NexOrder-EC2-Web` |
| ID | `i-093d338216cd0568d` |
| AMI | Amazon Linux 2023 (kernel-6.1) |
| Tipo | `t3.micro` |
| Subred | `subnet-0b18a1ba9a8bbb7ad` (pública) |
| IP Pública | `3.86.92.89` |
| IP Privada | `10.0.1.237` |
| VPC | `vpc-0905a60eb17e6565f` |
| Key Pair | `NexOrder-SSH-Key.pem` |

![Figura 11](/img/sprint1/11-lanzamiento-ec2.png) 
> 📸 **Figura 11 – Formulario de lanzamiento de EC2:** con AMI Amazon Linux 2023

![Figura 12](/img/sprint1/12-resumen-ec2.png) 
> 📸 **Figura 12 – Resumen de instancia:** `i-093d338216cd0568d` con IPs pública (`3.86.92.89`) y privada (`10.0.1.237`)


---

### 4.2 Instancia RDS MySQL

La base de datos RDS se despliega en la subred privada para garantizar su aislamiento total de Internet.

| Parámetro | Valor |
|-----------|-------|
| DB Identifier | `nexorder-db` |
| Motor | MySQL Community `8.0.40` |
| Clase | `db.t3.micro` |
| Usuario master | `admin` |
| Subred | `subnet-06db775e1d4b17a88` (privada) |
| Endpoint | `nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com` |
| AZ | `us-east-1a` |
| Internet Access Gateway | ❌ Disabled |
| IAM Authentication | ❌ Disabled |

> ⚠️ **Nota de seguridad:** La contraseña `N3x0r-DB-2025!Sec` debe almacenarse inmediatamente en un gestor de contraseñas (1Password, Bitwarden, AWS Secrets Manager, etc.). No debe quedar en texto plano en ningún fichero del repositorio.

![Figura 13](/img/sprint1/13-rds-creating.png) 
> 📸 **Figura 13 – Panel de RDS nexorder-db:** en estado `Creating` (MySQL Community, db.t3.micro)

![Figura 14](/img/sprint1/14-rds-available.png) 
> 📸 **Figura 14 – Listado de bases de datos:** `nexorder-db` en estado `Available`

---

### 4.3 Conexión SSH Inicial

Una vez lanzada la instancia, se verifica el acceso SSH desde terminal local utilizando la clave generada durante el lanzamiento:

```bash
# Asegurar permisos correctos sobre la clave privada
chmod 400 NexOrder-SSH-Key.pem

# Conectar a la instancia EC2
ssh -i "NexOrder-SSH-Key.pem" ec2-user@44.207.176.14
```

**Resultado esperado:** banner de bienvenida de Amazon Linux 2023 y prompt `[ec2-user@Web-NexOrder ~]$`.

![Figura 15](/img/sprint1/15-ssh-ec2user.png) 
> 📸 **Figura 15 – Terminal SSH exitosa:** conexión como `ec2-user` a `44.207.176.14` con Amazon Linux 2023

---

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

![Figura 16](/img/sprint1/16-mysql-connection.png) 
> 📸 **Figura 16 – Conexión MySQL exitosa:** `connection id 39` desde EC2 hacia el endpoint RDS

---

## 5. TA04: Security Groups

Los Security Groups actúan como **firewalls virtuales con estado** (stateful): las reglas de entrada y salida se evalúan por conexión, y el tráfico de retorno de una conexión permitida se autoriza automáticamente.

### 5.1 SG-Web-NexOrder

**ID:** `sg-0e0334685744195e2`
**Descripción:** Permitir tráfico HTTP y SSH para el servidor web
**VPC:** `vpc-0905a60eb17e6565f`

**Reglas de Entrada (Inbound):**

| Tipo | Protocolo | Puerto | Origen | Justificación |
|------|-----------|--------|--------|---------------|
| HTTP | TCP | 80 | `0.0.0.0/0` | Acceso web público sin cifrar |
| HTTPS | TCP | 443 | `0.0.0.0/0` | Acceso web cifrado (producción) |
| SSH | TCP | 22 | `79.116.173.66/32` | Administración restringida a la IP del equipo |

**Reglas de Salida (Outbound):** Todo el tráfico permitido (default AWS).

**¿Por qué SSH con `/32`?** Restringir SSH a una única IP (`/32`) elimina casi por completo la exposición a ataques de fuerza bruta automatizados. Un `/32` representa exactamente una dirección IP. Si la IP del administrador cambia, basta con actualizar esta regla.

![Figura 17](/img/sprint1/17-sg-web.png) 
> 📸 **Figura 17 – Creación de SG-Web-NexOrder:** con reglas HTTP(80), HTTPS(443) y SSH(22) restringido a `79.116.173.66/32`

---

### 5.2 SG-DB-NexOrder

**Descripción:** Base de Datos
**VPC:** `vpc-0905a60eb17e6565f`

**Reglas de Entrada (Inbound):**

| Tipo | Protocolo | Puerto | Origen | Justificación |
|------|-----------|--------|--------|---------------|
| MySQL/Aurora | TCP | 3296 | `sg-0e0334685744195e2` | Solo desde instancias asociadas a SG-Web |

**¿Por qué referenciar el SG en lugar de una IP?** Al usar el ID del Security Group como origen, la regla se aplica dinámicamente a cualquier instancia que tenga asignado ese SG. Si la IP pública del servidor web cambia (reinicio, escalado), la regla sigue siendo válida sin modificaciones. Esto también impide que cualquier otra máquina, aunque esté dentro de la VPC, acceda a la base de datos.

![Figura 18](/img/sprint1/18-sg-db.png) 
> 📸 **Figura 18 – Creación de SG-DB-NexOrder:** con MySQL(3296) referenciando `sg-0e0334685744195e2`

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

![Figura 19](/img/sprint1/19-dnf-update.png) 
> 📸 **Figura 19 – Salida de sudo dnf update -y:** mostrando `mysql80-community-release` actualizado

![Figura 20](/img/sprint1/20-instalacion-herramientas.png) 
> 📸 **Figura 20 – Instalación de herramientas:** git 2.50.1, vim-enhanced 9.2, etc.

![Figura 21](/img/sprint1/21-kernel-version.png) 
> 📸 **Figura 21 – Verificación de kernel:** `Version: 6.1.168`

---

### 6.2 Usuario Administrativo Restringido

En lugar de usar el usuario `ec2-user` (con sudo completo) para operaciones del día a día, se crea un usuario `nexadmin` con permisos sudo **únicamente para los comandos necesarios**.

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

**Resultado:** `nexadmin: parsed OK`. El usuario puede gestionar Apache y ejecutar scripts de despliegue/backup, pero no puede ejecutar comandos arbitrarios como root.

![Figura 22](/img/sprint1/22-creacion-nexadmin.png) 
> 📸 **Figura 22 – Creación de usuario nexadmin:** ejecución de `adduser`, `mkdir`, `chmod` y `cp` de `authorized_keys`

![Figura 23](/img/sprint1/23-sudoers-config.png) 
> 📸 **Figura 23 – Configuración de sudoers:** validación `/etc/sudoers.d/nexadmin: parsed OK`

---

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

![Figura 24](/img/sprint1/24-sed-sshd.png) 
> 📸 **Figura 24 – Comandos sed aplicados:** sobre `/etc/ssh/sshd_config` (backup previo creado)

![Figura 25](/img/sprint1/25-pubkey-auth.png) 
> 📸 **Figura 25 – Aplicación de reglas SSH:** para `PubkeyAuthentication` y `PermitEmptyPasswords`

![Figura 26](/img/sprint1/26-grep-verification.png) 
> 📸 **Figura 26 – Verificación con grep:** `PermitRootLogin no`, `PubkeyAuthentication yes`, `PasswordAuthentication no`

---

### 6.4 Reinicio y Validación del Servicio

Antes de reiniciar SSH, se valida la sintaxis del archivo de configuración para evitar quedarse sin acceso al servidor:

```bash
# Validar sintaxis ANTES de reiniciar (paso crítico)
sudo sshd -t && echo "✅ Configuración SSH válida"

# Reiniciar el demonio SSH
sudo systemctl restart sshd

# Verificar que el servicio está activo
sudo systemctl status sshd --no-pager

# Confirmar que está escuchando en el puerto correcto
sudo ss -tlnp | grep sshd
```

**Resultado:** Servicio `active (running)` escuchando en `0.0.0.0:22` y `[::]:22` (IPv4 e IPv6).

> ⚠️ **Buena práctica:** Siempre mantener la sesión SSH activa mientras se prueba la configuración. Solo cerrar la sesión original una vez verificado que la nueva configuración funciona.

![Figura 27](/img/sprint1/27-sshd-restart.png) 
> 📸 **Figura 27 – Validación y reinicio SSH:** `sshd -t` retorna ✅ + `systemctl restart sshd`

![Figura 28](/img/sprint1/28-sshd-status.png) 
> 📸 **Figura 28 – Estado del servicio SSH:** `active (running)` con PID `30274`

![Figura 29](/img/sprint1/29-ss-tlnp.png) 
> 📸 **Figura 29 – Verificación de puerto:** `ss -tlnp` confirmando `sshd` escuchando en `0.0.0.0:22`

---

### 6.5 Prueba con usuario nexadmin

Validación final del nuevo usuario y el hardening aplicado:

```bash
ssh -i "NexOrder-SSH-Key.pem" nexadmin@44.207.176.14
```

**Resultado:** Acceso exitoso. El prompt muestra `[nexadmin@Web-NexOrder ~]$`, confirmando que:
- La autenticación por clave funciona para el nuevo usuario.
- La contraseña de sistema no es necesaria.
- El hardening SSH está activo y operativo.

![Figura 30](/img/sprint1/30-login-nexadmin.png) 
> 📸 **Figura 30 – Conexión SSH con nexadmin:** banner de Amazon Linux 2023 y prompt `[nexadmin@Web-NexOrder ~]$`

---

## 7. Verificación Final de Conectividad

Checklist de validación integral de toda la infraestructura del Sprint 1:

| Componente | Verificación | Estado |
|------------|--------------|--------|
| VPC `vpc-0905a60eb17e6565f` | Creada y operativa | ✅ |
| Subnet-Publica-Web | `Available`, CIDR `10.0.1.0/23` | ✅ |
| Subnet-Privada-D | `Available`, CIDR `10.0.2.0/23` | ✅ |
| IGW-NexOrder | Asociado a VPC, estado `Attached` | ✅ |
| RT-Publica | Ruta `0.0.0.0/0 → IGW` activa | ✅ |
| RT-Privada | Sin ruta a Internet, solo `local` | ✅ |
| NexOrder-EC2-Web | Running, IP pública `3.86.92.89` | ✅ |
| nexorder-db | `Available`, MySQL 8.0.40 | ✅ |
| SG-Web-NexOrder | HTTP/HTTPS abierto, SSH restringido | ✅ |
| SG-DB-NexOrder | MySQL solo desde SG-Web | ✅ |
| Conexión SSH `ec2-user` | Acceso verificado | ✅ |
| Conexión SSH `nexadmin` | Acceso verificado post-hardening | ✅ |
| Conexión EC2 → RDS | `connection id 39`, MySQL activo | ✅ |
| PermitRootLogin | `no` | ✅ |
| PasswordAuthentication | `no` | ✅ |
| PubkeyAuthentication | `yes` | ✅ |

---

## 8. Justificación de Criterios

### 8.1 M0370 – Planificación de Redes

| Evidencia | Cumplimiento |
|-----------|-------------|
| Diseño VPC con jerarquía CIDR clara (`/16` → `/23`) | ✅ Sección 2 |
| Segmentación lógica pública/privada | ✅ Secciones 2.2 y 2.3 |
| Tablas de enrutamiento diferenciadas y asociaciones explícitas | ✅ Sección 3.2 |
| IGW restringido a subred pública | ✅ Sección 3.1 |
| Aislamiento total de la capa de datos (sin `0.0.0.0/0` en RT-Privada) | ✅ RT-Privada-NexOrder |
| Documentación técnica con IDs, rangos CIDR y justificaciones | ✅ Todo el documento |

### 8.2 M0369 – Integración de Ordenadores en Red

| Evidencia | Cumplimiento |
|-----------|-------------|
| EC2 y RDS integrados en la misma VPC con comunicación controlada | ✅ Sección 4 |
| Conectividad validada mediante endpoint DNS interno de RDS | ✅ Sección 4.4 |
| Firewall con referencia cruzada entre SGs (no IPs fijas) | ✅ Sección 5.2 |
| Hardening de red SSH (puerto 22 restringido, solo claves, root deshabilitado) | ✅ Sección 6.3 |
| Pruebas de conectividad validadas en entorno real de producción | ✅ Secciones 4.3, 4.4, 6.5 |

---

*Documentación completada: 13–19 de abril de 2025*

*Responsables: Victor Serrano · Trishan Mizhquiri*
