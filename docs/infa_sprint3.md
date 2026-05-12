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

"Se ha configurado una tarea cron (`0 3 * * *`) para ejecutar el script de backup diariamente a las 03:00, horario de baja actividad que minimiza el impacto en el rendimiento del sistema. La salida del script se redirige a `/var/log/nexorder_backup.log` con `2>&1` para capturar tanto stdout como stderr, garantizando auditoría completa de cada ejecución. Los permisos `664` en el log permiten escritura por el usuario del cron mientras mantienen lectura para administración y revisión. El script utiliza rutas absolutas para evitar fallos en entornos no interactivos de cron.

### T15: Implementar rotación de logs (logrotate)
Añadimos en el archivo sudo nano /etc/logrotate.d/httpd  y eliminamos el que había ya que si no va a salir un error de entrada duplicada 

![Figura 12(/img/sprint1/0-diagrama-logico.png) 
![Figura 13(/img/sprint1/0-diagrama-logico.png) 

Haciendo lo anterior lo que hacemos que es que los log se cortan cada dia y guardamos solo los últimos 7 días y los comprimimos para ahorrar espacio 
Podemos ver que:

No hay errores críticos en la configuración del servidor
Has implementado la automatización necesaria para que el disco duro de la instancia EC2 no se llene con archivos de texto infinitos
Mantener la integridad de los datos al asegurar que siempre habrá 7 días de historial disponibles para auditorías de seguridad
eso quiere decir que el servidor es "inteligente” y se mantiene limpio a sí mismo de forma automática

![Figura 14(/img/sprint1/0-diagrama-logico.png) 

Hemos usado el sudo nano /etc/logrotate.d/mysql para crear una regla 
![Figura 14(/img/sprint1/0-diagrama-logico.png) 
![Figura 15(/img/sprint1/0-diagrama-logico.png) 

### T16: Configurar CloudWatch y alertas proactivas
Accedemos a la consola de AWS y localizamos el servicio CloudWatch
![Figura 16(/img/sprint1/0-diagrama-logico.png) 

Una vez dentro de CloudWatch, nos situamos en la sección de Métricas. Aquí es donde el sistema empieza a recolectar los datos brutos del servidor

![Figura 17(/img/sprint1/0-diagrama-logico.png) 

Finalmente, accedemos al apartado de Alarmas. Aquí es donde convertimos la monitorización pasiva en proactiva. Al pulsar en 'Crear alarma'

![Figura 18(/img/sprint1/0-diagrama-logico.png) 

Se ha seleccionado la métrica específica CPUUtilization vinculada directamente a nuestra instancia de servidor web Como se observa en el gráfico de líneas, el sistema ya está monitorizando y mostrando la carga de trabajo en tiempo real

![Figura 19(/img/sprint1/0-diagrama-logico.png) 

Se ha establecido un periodo de 1 minuto. Esto significa que la métrica se evalúa en intervalos cortos para asegurar una capacidad de respuesta rápida ante cualquier anomalía
Establecimiento de Condiciones:

Tipo de límite: utiliza un umbral Estático, que es el más fiable
Umbral Crítico: se ha configurado la alarma para que se dispare cuando la utilización de la CPU sea Mayor a 80

Lógica de activación:Si el valor medio de la CPU supera este 80% durante el periodo de un minuto, el estado de la alarma pasará de "OK" a "En Alarma", activando inmediatamente el protocolo de notificación SNS configurado

![Figura 20(/img/sprint1/0-diagrama-logico.png) 

Una vez definida la métrica, el siguiente paso crítico es establecer qué acción debe realizar el sistema cuando se detecte un problema

Configuración de Acciones:Se ha configurado un activador para que, cuando la alarma pase al estado "En modo alarma" se envíe una notificación de forma automática

Para ello se ha seleccionado un tema de Amazon SNS existente denominado Este paso garantiza que el sistema no solo monitorice en silencio, sino que sea capaz de alertar activamente a los administradores

![Figura 21(/img/sprint1/0-diagrama-logico.png) 

Como medida de seguridad y validación, Amazon SNS requiere una confirmación  podemos ver que ha confirmada la suscripción 

![Figura 22(/img/sprint1/0-diagrama-logico.png) 

procedemos a identificar la alarma para facilitar su gestión y reconocimiento dentro del panel de AWS
Nombre de la Alarma:Alarma_CPU_NexOrder_Serrano

![Figura 23(/img/sprint1/0-diagrama-logico.png) 

Podemos ver una vista previa de la configuración
Métrica y Condiciones Confirmación del umbral estático de 80% de CPU evaluado cada 1 minuto
Acciones de Notificación:Verificación de que la alerta está correctamente vinculada al tema SNS para el envío de correos
Detalles Identificativos:Revisión del nombre y la descripción personalizada

![Figura 24(/img/sprint1/0-diagrama-logico.png) 

Confirmación de Despliegue

![Figura 25(/img/sprint1/0-diagrama-logico.png) 

Creamos un panel y le colocamos el siguiente nombre

![Figura 26(/img/sprint1/0-diagrama-logico.png) 


Hemos  configurado un Dashboard personalizado en CloudWatch utilizamos  widgets de tipo Línea que nos permite visualizar en tiempo real la carga de lectura y escritura en el disco duro de la instancia

![Figura 27(/img/sprint1/0-diagrama-logico.png) 

Hemos  configurado un Dashboard personalizado en CloudWatch utilizamos  widgets de tipo Línea que nos permite visualizar en tiempo real la carga de lectura y escritura en el disco duro de la instancia

![Figura 28(/img/sprint1/0-diagrama-logico.png) 

Veremos esta tabla que se trata del Selector de Métricas de CloudWatch y es la herramienta que te permite ver entre todos los datos que genera tu servidor para elegir cuáles quieres vigilar
Hemos seleccionado CPUUtilization por ser el KPI (Indicador Clave de Desempeño) más crítico de la infraestructura.
