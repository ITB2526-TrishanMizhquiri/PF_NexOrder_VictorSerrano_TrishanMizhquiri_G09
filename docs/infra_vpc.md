# Documentación Técnica - Infraestructura VPC Sprint 1
**Proyecto:** NexOrder Infrastructure  
**Responsables:** Victor Serrano, Trishan Mizhquiri  
**Fecha:** 13 de abril 2026 - 19 de abril 2026  
**Criterios:** M0370 (Planificación de redes), M0369 (Integración de ordenadores en red)

---

## 📋 Índice
1. [Arquitectura de Red](#1-arquitectura-de-red)
2. [TA01: VPC y Subredes](#2-ta01-vpc-y-subredes)
   - [2.1 Creación de VPC](#21-creación-de-vpc)
   - [2.2 Subred Pública](#22-subred-pública)
   - [2.3 Subred Privada](#23-subred-privada)
   - [2.4 Validación de Subredes](#24-validación-de-subredes)
3. [TA02: Internet Gateway y Enrutamiento](#3-ta02-internet-gateway-y-enrutamiento)
   - [3.1 Internet Gateway (IGW)](#31-internet-gateway-igw)
   - [3.2 Tablas de Enrutamiento](#32-tablas-de-enrutamiento)
     - [3.2.1 RT-Publica-NexOrder](#321-rt-publica-nexorder)
     - [3.2.2 RT-Privada-NexOrder](#322-rt-privada-nexorder)
4. [TA03: Instancias EC2 y RDS](#4-ta03-instancias-ec2-y-rds)
   - [4.1 Instancia EC2](#41-instancia-ec2)
   - [4.2 Instancia RDS MySQL](#42-instancia-rds-mysql)
   - [4.3 Conexión SSH Inicial](#43-conexión-ssh-inicial)
   - [4.4 Prueba de Conexión EC2 → RDS](#44-prueba-de-conexión-ec2--rds)
5. [TA04: Security Groups](#5-ta04-security-groups)
   - [5.1 SG-Web-NexOrder](#51-sg-web-nexorder)
   - [5.2 SG-DB-NexOrder](#52-sg-db-nexorder)
6. [TA05: Hardening del Sistema](#6-ta05-hardening-del-sistema)
   - [6.1 Actualización de Paquetes](#61-actualización-de-paquetes)
   - [6.2 Usuario Administrativo Restringido](#62-usuario-administrativo-restringido)
   - [6.3 Hardening de SSH](#63-hardening-de-ssh)
   - [6.4 Reinicio y Validación del Servicio](#64-reinicio-y-validación-del-servicio)
   - [6.5 Prueba con Usuario nexadmin](#65-prueba-con-usuario-nexadmin)
7. [TA06: Verificación Final de Conectividad](#7-ta06-verificación-final-de-conectividad)
8. [Justificación de Criterios](#8-justificación-de-criterios)
   - [8.1 M0370 – Planificación de Redes](#81-m0370--planificación-de-redes)
   - [8.2 M0369 – Integración de Ordenadores en Red](#82-m0369--integración-de-ordenadores-en-red)

---

## 1. Arquitectura de Red

### Diagrama Lógico

![Diagrama Lógico](/img/sprint1/diagrama-logico.png)

> 📸 **Figura 0:** Diagrama Logico de la arquitectura de red`
---

## 2. TA01: VPC y Subredes

### 2.1 Creación de VPC
**CIDR Block:** 10.0.0.0/16  
**Nombre:** VPC-NexOrder  
**ID:** vpc-0905a60eb17e6565f  
**Región:** us-east-1 (Norte de Virginia)

**Justificación:** Se seleccionó un bloque `/16` para permitir hasta 65.536 direcciones IP, proporcionando espacio suficiente para crecimiento futuro manteniendo una jerarquía de red clara.

![Creación de VPC con CIDR 10.0.0.0/16](/img/sprint1/01-vpc-creacion.png)

> 📸 **Figura 1:** Creación de VPC con CIDR `10.0.0.0/16` y etiqueta `Name=VPC-NexOrder`

### 2.2 Subred Pública
**CIDR:** 10.0.1.0/24 (256 IPs)  
**Nombre:** Subnet-Publica-Web  
**ID:** subnet-0b18a1ba9a8bbb7ad  
**AZ:** us-east-1a  
**Propósito:** Albergar el servidor web accesible desde Internet.

![Configuración de subred pública 10.0.1.0/24](/img/sprint1/02-subnet-publica.png)

> 📸 **Figura 2:** Configuración de subred pública con CIDR `10.0.1.0/24` en us-east-1a

### 2.3 Subred Privada
**CIDR:** 10.0.2.0/24 (256 IPs)  
**Nombre:** Subnet-Privada-D  
**ID:** subnet-06db775e1d4b17a88  
**AZ:** us-east-1a  
**Propósito:** Albergar la base de datos con aislamiento total de Internet.

![Configuración de subred privada 10.0.2.0/24](/img/sprint1/03-subnet-privada.png)

> 📸 **Figura 3:** Configuración de subred privada con CIDR `10.0.2.0/24` en us-east-1a

### 2.4 Validación de Subredes
Ambas subredes creadas exitosamente y en estado `Available`.

![Lista de subredes creadas](/img/sprint1/04-subredes-validacion.png)

> 📸 **Figura 4:** Validación de subredes creadas - subnet-0b18a1ba9a8bbb7ad y subnet-06db775e1d4b17a88

---

## 3. TA02: Internet Gateway y Enrutamiento

### 3.1 Internet Gateway (IGW)
**Nombre:** IGW-NexOrder  
**ID:** igw-099e10b6c7e172a25  
**Asociado a:** vpc-0905a60eb17e6565f

**Justificación:** El IGW actúa como router virtual que conecta la VPC a Internet, esencial para que el servidor web reciba y envíe tráfico externo.

![Creación del Internet Gateway](/img/sprint1/05-igw-creacion.png)

> 📸 **Figura 5:** Creación de IGW-NexOrder (igw-099e10b6c7e172a25)

![Asociación del IGW a la VPC](/img/sprint1/06-igw-asociacion.png)

> 📸 **Figura 6:** Asociación del IGW a VPC-NexOrder (vpc-0905a60eb17e6565f)

### 3.2 Tablas de Enrutamiento
Se crearon dos tablas diferenciadas para separar el tráfico: la pública habilita conectividad externa, mientras que la privada garantiza aislamiento total.

#### 3.2.1 RT-Publica-NexOrder
**ID:** rtb-0e78fa3e4905a11fd  
**Asociada a:** subnet-0b18a1ba9a8bbb7ad (Subnet-Publica-Web)

**Rutas configuradas:**
| Destino | Target | Estado |
|---------|--------|--------|
| 10.0.0.0/16 | local | Activo |
| 0.0.0.0/0 | igw-099e10b6c7e172a25 | Activo |

**Justificación:** La ruta `0.0.0.0/0 → IGW` habilita acceso bidireccional a Internet para el servidor web, permitiendo tráfico entrante (HTTP/HTTPS) y saliente (actualizaciones).

![Asociación de tabla pública a subred](/img/sprint1/07-rt-publica-asociacion.png)

> 📸 **Figura 7:** Asociación explícita de RT-Publica-NexOrder a Subnet-Publica-Web

![Edición de rutas de tabla pública](/img/sprint1/08-rt-publica-rutas.png)

> 📸 **Figura 8:** Configuración de ruta `0.0.0.0/0 → igw-099e10b6c7e172a25`

#### 3.2.2 RT-Privada-NexOrder
**ID:** rtb-0886f3878f7e27479  
**Asociada a:** subnet-06db775e1d4b17a88 (Subnet-Privada-D)

**Rutas configuradas:**
| Destino | Target | Estado |
|---------|--------|--------|
| 10.0.0.0/16 | local | Activo |

**Justificación:** Sin ruta a Internet (`0.0.0.0/0`), garantizando aislamiento total de la capa de datos. Solo se permite comunicación interna dentro de la VPC.

![Tabla de enrutamiento privada](/img/sprint1/09-rt-privada.png)

> 📸 **Figura 9:** RT-Privada-NexOrder sin acceso a Internet (solo ruta local)

---

## 4. TA03: Instancias EC2 y RDS

### 4.1 Instancia EC2
**Nombre:** NexOrder-EC2-Web  
**ID:** i-093d338216cd0568d  
**AMI:** Amazon Linux 2023 (kernel-6.1)  
**Instance Type:** t3.micro  
**Subnet:** subnet-0b18a1ba9a8bbb7ad  
**IP Pública:** 3.86.92.89  
**IP Privada:** 10.0.1.247  
**Key Pair:** NexOrder-SSH-Key.pem

![Configuración de lanzamiento de EC2](/img/sprint1/10-ec2-config.png)

> 📸 **Figura 10:** Configuración de NexOrder-EC2-Web con Amazon Linux 2023

![Detalle de instancia EC2 creada](/img/sprint1/11-ec2-detalle.png)

> 📸 **Figura 11:** Instancia i-093d338216cd0568d con IP pública 3.86.92.89 y privada 10.0.1.247

### 4.2 Instancia RDS MySQL
**DB Identifier:** nexorder-db  
**Engine:** MySQL Community 8.0.40  
**Instance Class:** db.t3.micro  
**Master Username:** admin  
**Subnet:** subnet-06db775e1d4b17a88  
**Endpoint:** nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com  
**Availability Zone:** us-east-1a

![Configuración de RDS MySQL](/img/sprint1/12-rds-config.png)

> 📸 **Figura 12:** Configuración de nexorder-db con MySQL 8.0.40 y db.t3.micro

![RDS en estado Available](/img/sprint1/13-rds-available.png)

> 📸 **Figura 13:** RDS nexorder-db en estado `Available` en us-east-1a

### 4.3 Conexión SSH Inicial
Desde terminal local:
```bash
chmod 400 NexOrder-SSH-Key.pem
ssh -i "NexOrder-SSH-Key.pem" ec2-user@44.207.176.14
```
Resultado: Conexión exitosa a Amazon Linux 2023.

![Conexión SSH a EC2](/img/sprint1/14-ssh-conexion.png)

> 📸 **Figura 14:** Conexión SSH exitosa como ec2-user a 44.207.176.14

### 4.4 Prueba de Conexión EC2 → RDS
Instalación de cliente MySQL y prueba:
```bash
sudo dnf update && sudo dnf install default-mysql-client -y
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u admin -p
```
Resultado:
```
Welcome to the MySQL monitor. Commands end with ; or \g.
Your MySQL connection id is 39
Server version: 8.0.40 Source distribution
mysql>
```

![Conexión MySQL desde EC2 a RDS](/img/sprint1/15-mysql-conexion.png)

> 📸 **Figura 15:** Conexión MySQL exitosa (connection id 39) desde EC2 a RDS

---

## 5. TA04: Security Groups

### 5.1 SG-Web-NexOrder
**ID:** sg-0e0334685744195e2  
**Propósito:** Firewall virtual para el servidor web.

**Reglas de Entrada:**
| Tipo | Protocolo | Puerto | Origen | Descripción |
|------|-----------|--------|--------|-------------|
| HTTP | TCP | 80 | 0.0.0.0/0 | Acceso web para clientes |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Acceso web seguro |
| SSH | TCP | 22 | 79.116.173.66/32 | Acceso administrativo restringido |

**Justificación:** Principio de mínimo privilegio. Solo se expone tráfico web y SSH restringido a la IP del administrador.

![Configuración de SG-Web-NexOrder](/img/sprint1/16-sg-web.png)

> 📸 **Figura 16:** SG-Web-NexOrder con reglas HTTP(80), HTTPS(443) y SSH(22 restringido)

### 5.2 SG-DB-NexOrder
**Propósito:** Firewall virtual para la base de datos.

**Reglas de Entrada:**
| Tipo | Protocolo | Puerto | Origen | Descripción |
|------|-----------|--------|--------|-------------|
| MySQL/Aurora | TCP | 3306 | sg-0e0334685744195e2 | Solo desde SG-Web-NexOrder |

**Justificación:** Se referencia el ID del SG-Web en lugar de IPs fijas. Esto garantiza que solo la EC2 asociada a ese grupo pueda comunicarse con la base de datos, mejorando la seguridad y flexibilidad.

![Configuración de SG-DB-NexOrder](/img/sprint1/17-sg-db.png)

> 📸 **Figura 17:** SG-DB-NexOrder con MySQL(3306) referenciando sg-0e0334685744195e2

---

## 6. TA05: Hardening del Sistema

### 6.1 Actualización de Paquetes
```bash
sudo dnf update -y
sudo dnf install -y vim wget curl git fail2ban
dnf info kernel | grep Version
```
**Resultado:** Kernel actualizado a `6.1.168`. Herramientas de administración y seguridad instaladas.

![Ejecución de dnf update](/img/sprint1/18-dnf-update.png)

> 📸 **Figura 18:** Actualización de paquetes con `sudo dnf update -y`

![Instalación de herramientas de seguridad](/img/sprint1/19-herramientas-install.png)

> 📸 **Figura 19:** Instalación de vim, wget, curl, git y fail2ban

![Verificación de versión de kernel](/img/sprint1/20-kernel-version.png)

> 📸 **Figura 20:** Kernel actualizado a versión 6.1.168

### 6.2 Usuario Administrativo Restringido
Creación de usuario `nexadmin` sin contraseña, solo autenticación por claves SSH:
```bash
sudo adduser nexadmin
sudo mkdir -p /home/nexadmin/.ssh
sudo chmod 700 /home/nexadmin/.ssh
sudo cp /home/ec2-user/.ssh/authorized_keys /home/nexadmin/.ssh/
sudo chown -R nexadmin:nexadmin /home/nexadmin/.ssh
sudo chmod 600 /home/nexadmin/.ssh/authorized_keys
```
Restricción de `sudo` vía archivo dedicado:
```bash
echo 'nexadmin ALL=(ALL) NOPASSWD:/usr/bin/systemctl restart apache2,/usr/bin/systemctl reload apache2,/usr/bin/dnf update,/usr/bin/dnf upgrade,/usr/local/bin/backup_nexorder.sh,/usr/local/bin/deploy_nexorder.sh' | sudo tee /etc/sudoers.d/nexadmin
sudo chmod 440 /etc/sudoers.d/nexadmin
sudo visudo -c
```
**Resultado:** `/etc/sudoers.d/nexadmin: parsed OK`

![Creación de usuario nexadmin](/img/sprint1/21-usuario-nexadmin.png)

> 📸 **Figura 21:** Creación de usuario nexadmin con directorio .ssh configurado

![Configuración de sudoers restringidos](/img/sprint1/22-sudoers-config.png)

> 📸 **Figura 22:** Configuración de permisos sudo restringidos y validación con visudo -c

### 6.3 Hardening de SSH
Backup y aplicación de reglas estrictas:
```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PermitEmptyPasswords yes/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
```
Verificación:
```bash
sudo grep -E "PermitRootLogin|PasswordAuthentication|PubkeyAuthentication" /etc/ssh/sshd_config
```
**Resultado:**
```
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
```

![Aplicación de hardening SSH con sed](/img/sprint1/23-ssh-hardening.png)

> 📸 **Figura 23:** Aplicación de comandos sed para hardening de SSH

![Verificación de configuración SSH](/img/sprint1/24-ssh-verify.png)

> 📸 **Figura 24:** Verificación de configuración: PermitRootLogin no, PubkeyAuthentication yes, PasswordAuthentication no

### 6.4 Reinicio y Validación del Servicio
```bash
sudo sshd -t && echo "✓ Configuración SSH válida"
sudo systemctl restart sshd
sudo systemctl status sshd --no-pager
sudo ss -tlnp | grep sshd
```
**Resultado:** Servicio `active (running)`, escuchando en `0.0.0.0:22`.

![Reinicio y validación del servicio SSH](/img/sprint1/25-ssh-restart.png)

> 📸 **Figura 25:** Reinicio de sshd y verificación de estado active (running)

### 6.5 Prueba con Usuario nexadmin
```bash
ssh -i "NexOrder-SSH-Key.pem" nexadmin@44.207.176.14
```
Resultado: Acceso exitoso sin contraseña, validando autenticación por claves y hardening aplicado.

![Conexión SSH con usuario nexadmin](/img/sprint1/26-ssh-nexadmin.png)

> 📸 **Figura 26:** Conexión SSH exitosa con usuario nexadmin a Amazon Linux 2023

---

## 7. TA06: Verificación Final de Conectividad
Validación integral de la arquitectura tras aplicar hardening y políticas de red.

**Checklist:**
- [x] VPC y subredes operativas
- [x] Enrutamiento diferenciado (pública con IGW, privada aislada)
- [x] EC2 y RDS en subredes correctas
- [x] Security Groups aplicados (mínimo privilegio)
- [x] Hardening SSH verificado (`root disabled`, `key-only`, `nexadmin` restringido)
- [x] Conexión EC2 → RDS MySQL estable (`connection id 39`)

**Evidencia:**
```bash
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u admin -p
Enter password: 'N3x0r-DB-2026!Sec'
Welcome to the MySQL monitor. Commands end with ; or \g.
Server version: 8.0.40 Source distribution
mysql> exit
```

![Validación final de conectividad MySQL](/img/sprint1/27-mysql-final.png)

> 📸 **Figura 27:** Validación final de conectividad MySQL desde EC2 a RDS

---

## 8. Justificación de Criterios

### 8.1 M0370 – Planificación de Redes
✅ **Cumplido:**
- Diseño VPC con segregación lógica pública/privada usando CIDR jerárquico (`10.0.0.0/16` → `/24`)
- Tablas de enrutamiento explícitas y diferenciadas
- IGW asociado únicamente a la subred pública
- Aislamiento garantizado de la capa de datos (RDS sin ruta `0.0.0.0/0`)
- Documentación técnica completa con IDs, rangos y justificaciones

### 8.2 M0369 – Integración de Ordenadores en Red
✅ **Cumplido:**
- EC2 y RDS integrados en la misma VPC con comunicación controlada
- Conectividad validada mediante endpoint DNS interno de RDS
- Firewall a nivel de red (Security Groups) configurado con referencia cruzada (no IPs fijas)
- Hardening de red SSH aplicado (puerto 22 restringido, autenticación por claves, root deshabilitado)
- Pruebas de conectividad y acceso validadas en entorno real

---

**Documentación completada:** 13-19 de abril 2026  
**Responsables:** Victor Serrano, Trishan Mizhquiri  