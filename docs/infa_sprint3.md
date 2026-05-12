# Documentación Técnica – Infraestructura VPC Sprint 3

**Proyecto:** NexOrder Infrastructure

**Responsables:** Victor Serrano, Trishan Mizhquiri

**Fecha:** 4 de mayo 2026 – 12 de mayo 2026

**Módulos:** M0370 (Planificación de redes) · M0369 (Integración de ordenadores en red)

---

## 📋 Índice

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
9. [Leyenda de Imágenes](#9-leyenda-de-imágenes)

---

## T13. Desarrollar script backup automatizado

Descripción: Crear backup.sh que ejecute mysqldump, comprima gzip, añada timestamp y almacene en /backups local.

## Preparar entorno y permisos

```bash
# 1. Crear directorio de backups y log
sudo mkdir -p /backups
sudo touch /var/log/nexorder_backup.log

# 2. Asignar propietario al usuario actual (ec2-user) para facilitar gestión
sudo chown -R ec2-user:ec2-user /backups /var/log/nexorder_backup.log

# 3. Permisos seguros (solo el propietario puede leer/escribir)
chmod 700 /backups
chmod 600 /var/log/nexorder_backup.log
---
![Figura 0](/img/sprint1/0-diagrama-logico.png) 

##  Paso 2: Crear el script `backup_nexorder.sh`

```bash
# Crear el script en ruta estándar para administradores
sudo nano /usr/local/bin/backup_nexorder.sh

![Figura 1](/img/sprint1/0-diagrama-logico.png) 
> 📸 **Figura 0 – Arquitectura lógica:** diagrama conceptual de la red

---
# Hacer el script ejecutable
sudo chmod +x /usr/local/bin/backup_nexorder.sh
```

> ⚠️ **IMPORTANTE:** Antes de ejecutar, edita las líneas `DB_HOST`, `DB_PASS` y `DB_USER` con tus datos reales:
> ```bash
> sudo nano /usr/local/bin/backup_nexorder.sh
> ```
![Figura 2](/img/sprint1/0-diagrama-logico.png) 


## Ejecutar prueba manual

```bash
# Ejecutar el script
/usr/local/bin/backup_nexorder.sh

# Verificar archivo generado
ls -lh /backups/

# Verificar log de auditoría
tail -5 /var/log/nexorder_backup.log
```
![Figura 3](/img/sprint1/0-diagrama-logico.png) 

##  Justificación Técnica ASIXc
 *"Se ha desarrollado un script Bash (`backup_nexorder.sh`) que automatiza la exportación lógica de la base de datos MySQL mediante `mysqldump`, aplicando compresión `gzip` para optimizar espacio y añadiendo un timestamp para versionado. El script incluye control de errores (`$?`), registro de auditoría en `/var/log/` y política de retención de 7 días mediante `find -mtime`.

## T14. - Configurar cron ejecución programada
Descripción: Programar tarea cron diaria 03:00, verificar permisos y redirigir salida a log auditoría.
## 🔧 Paso 1: Verificar permisos del log

Antes de configurar cron, asegúrate de que el usuario pueda escribir en el log:

```bash
# Verificar propietario y permisos actuales
ls -l /var/log/nexorder_backup.log

# Si es necesario, ajustar permisos (el usuario del cron debe poder escribir)
sudo chown ec2-user:ec2-user /var/log/nexorder_backup.log
sudo chmod 664 /var/log/nexorder_backup.log
```
![Figura 3](/img/sprint1/0-diagrama-logico.png) 
 El archivo debe ser writable por `ec2-user`.

---

## Pasos para instalar y activar CRON

### Instalar el paquete correcto
```bash
sudo dnf install cronie -y
```
![Figura 5](/img/sprint1/0-diagrama-logico.png) 
### Habilitar e iniciar el servicio
```bash
# Habilitar para que arranque con el sistema
sudo systemctl enable crond

# Iniciar el servicio ahora
sudo systemctl start crond

# Verificar estado
sudo systemctl status crond 
```
![Figura 6](/img/sprint1/0-diagrama-logico.png) 

## Editar crontab

```bash
# Editar la tabla cron del usuario actual (ec2-user)
crontab -e
```
## Añadir la tarea programada

Pega esta línea **al final del archivo**:

```cron
# Backup diario NexOrder - 03:00 AM (T14)
0 3 * * * /usr/local/bin/backup_nexorder.sh >> /var/log/nexorder_backup.log 2>&1
```
![Figura 7](/img/sprint1/0-diagrama-logico.png) 
![Figura 8(/img/sprint1/0-diagrama-logico.png) 

## Guardar y verificar

**Guardar el archivo:**
**Verificar que se guardó correctamente:**
```bash
# Listar tareas cron del usuario actual
crontab -l
```
![Figura 9(/img/sprint1/0-diagrama-logico.png) 

## Prueba inmediata (recomendada)

Para no esperar hasta las 03:00 AM, puedes probar el cron ejecutándolo manualmente o modificando temporalmente el horario:

### Opción A: Ejecutar manualmente (más seguro)
```bash
# Ejecutar el script ahora mismo para probar
/usr/local/bin/backup_nexorder.sh

# Verificar que se generó un nuevo backup y se escribió en el log
ls -lh /backups/ | tail -1
tail -3 /var/log/nexorder_backup.log
```
### Opción B: Probar con cron cada minuto (solo para pruebas)
```bash
# 1. Editar crontab temporalmente
crontab -e

# 2. Cambiar la línea a (ejecutar cada minuto):
* * * * * /usr/local/bin/backup_nexorder.sh >> /var/log/nexorder_backup.log 2>&1

# 3. Guardar y esperar 1-2 minutos

# 4. Verificar el log
tail -5 /var/log/nexorder_backup.log

# 5. Restaurar el horario original (03:00)
crontab -e
# Cambiar: * * * * *  →  0 3 * * *
```
![Figura 10(/img/sprint1/0-diagrama-logico.png) 
![Figura 11(/img/sprint1/0-diagrama-logico.png) 

---
> *"Se ha configurado una tarea cron (`0 3 * * *`) para ejecutar el script de backup diariamente a las 03:00, horario de baja actividad que minimiza el impacto en el rendimiento del sistema. La salida del script se redirige a `/var/log/nexorder_backup.log` con `2>&1` para capturar tanto stdout como stderr, garantizando auditoría completa de cada ejecución. Los permisos `664` en el log permiten escritura por el usuario del cron mientras mantienen lectura para administración y revisión. El script utiliza rutas absolutas para evitar fallos en entornos no interactivos de cron.
---
### T15: Implementar rotación de logs (logrotate)
Añadimos en el archivo sudo nano /etc/logrotate.d/httpd  y eliminamos el que había ya que si no va a salir un error de entrada duplicada 
![Figura 12(/img/sprint1/0-diagrama-logico.png) 





