# Documentación Técnica – Monitorización, Backups y Resiliencia Sprint 3

**Proyecto:** NexOrder Infrastructure

**Autores:** Victor Serrano & Trishan Mizhquiri

**Fecha:** 27 de abril 2026 – 3 de mayo 2026

**Módulos:** M036
4 (Automatización) · M036
7 (Backups) · M036
8 (Auditoría) · C036
 (Seguridad)

---

## 📋 Índice

1. [Arquitectura de Monitorización y Resiliencia](#1-arquitectura-de-monitorización-y-resiliencia)
2. [T13: Script de Backup Automatizado](#2-t13-script-de-backup-automatizado)
   - [2.1 Preparación del Entorno](#21-preparación-del-entorno)
   - [2.2 Creación del Script](#22-creación-del-script)
   - [2.3 Prueba Manual](#23-prueba-manual)
3. [T14: Programación con Cron](#3-t14-programación-con-cron)
   - [3.1 Verificación de Permisos](#31-verificación-de-permisos)
   - [3.2 Instalación y Activación de Cronie](#32-instalación-y-activación-de-cronie)
   - [3.3 Configuración del Crontab](#33-configuración-del-crontab)
   - [3.4 Verificación y Prueba](#34-verificación-y-prueba)
4. [T15: Rotación de Logs con Logrotate](#4-t15-rotación-de-logs-con-logrotate)
   - [4.1 Configuración para Apache (httpd)](#41-configuración-para-apache-httpd)
   - [4.2 Configuración para MySQL](#42-configuración-para-mysql)
5. [T16: CloudWatch y Alertas Proactivas](#5-t16-cloudwatch-y-alertas-proactivas)
   - [5.1 Acceso a CloudWatch](#51-acceso-a-cloudwatch)
   - [5.2 Creación de Alarma CPU](#52-creación-de-alarma-cpu)
   - [5.3 Configuración de Acciones SNS](#53-configuración-de-acciones-sns)
   - [5.4 Dashboard Personalizado y Métricas EBS](#54-dashboard-personalizado-y-métricas-ebs)
6. [T17: Script de Despliegue Continuo](#6-t17-script-de-despliegue-continuo)
   - [6.1 Preparación del Entorno](#61-preparación-del-entorno)
   - [6.2 Creación del Script](#62-creación-del-script)
   - [6.3 Simulación y Validación](#63-simulación-y-validación)
7. [T18: Prueba de Restauración y RTO](#7-t18-prueba-de-restauración-y-rto)
   - [7.1 Verificación del Backup Disponible](#71-verificación-del-backup-disponible)
   - [7.2 Simulación de Caída (DROP DATABASE)](#72-simulación-de-caída-drop-database)
   - [7.3 Restauración desde Backup](#73-restauración-desde-backup)
   - [7.4 Verificación de Integridad](#74-verificación-de-integridad)
   - [7.5 Cálculo del RTO](#75-cálculo-del-rto)
8. [T19: Auditoría de Seguridad con nmap](#8-t19-auditoría-de-seguridad-con-nmap)
9. [Justificación de Criterios](#9-justificación-de-criterios)

---

## 1. Arquitectura de Monitorización y Resiliencia

El Sprint 3 añade la **capa de operaciones** sobre la infraestructura y servicios de los sprints anteriores. Se implementan cinco pilares de resiliencia que garantizan la continuidad del negocio:

![Arquitectura de Monitorización y Resiliencia](/img/sprint3/0-arquitectura.png)
> **Figura 0 – Arquitectura de operaciones:** diagrama conceptual de los flujos de monitorización y resiliencia

---

## 2. T13: Script de Backup Automatizado

El objetivo es crear un sistema de backup lógico completamente automatizado que exporte la base de datos MySQL, la comprima, la versione con timestamp y gestione la retención automáticamente.

### 2.1 Preparación del Entorno

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
| `/backups` | `700` | Nadie más que `ec2-user` puede listar ni acceder a los backups (contienen datos sensibles) |
| `nexorder_backup.log` | `600` | El log incluye mensajes con nombres de BD; solo el propietario debe leerlo |

![Preparación permisos backup](/img/sprint3/1-backup-env-setup.png)
> **Figura 1** – Terminal ejecutando los cinco comandos de preparación: `mkdir /backups`, `touch nexorder_backup.log`, `chown ec2-user`, `chmod 700` y `chmod 600`

---

### 2.2 Creación del Script

El script se coloca en `/usr/local/bin/` siguiendo la convención POSIX para ejecutables de administración:

```bash
sudo nano /usr/local/bin/backup_nexorder.sh
```

Contenido completo del script:

[Enllaç al documento: backup_nexorder.sh](/docs/src/backup_nexorder.sh)

```bash
# Hacer el script ejecutable
sudo chmod +x /usr/local/bin/backup_nexorder.sh
```

**Decisiones de diseño del script:**

- **Pipeline `mysqldump | gzip`**: evita escribir el SQL sin comprimir a disco. El archivo `.gz` ocupa entre 5 y 10 veces menos espacio.
- **`$?` tras el pipe**: verifica el código de salida del último comando. Si `mysqldump` falla, `gzip` recibirá stdin vacío y también fallará, propagando el error.
- **`find -mtime +7 -delete`**: implementa una política de retención de 7 días sin intervención manual.
- **Timestamps en log**: cada línea incluye fecha y hora exactas, creando una traza de auditoría completa.

![Script backup_nexorder.sh en nano](/img/sprint3/2-backup-script-nano.png)
> **Figura 2** – Editor nano con el contenido completo de `backup_nexorder.sh` mostrando configuración, pipeline `mysqldump | gzip` y bloque `if [ $? -eq 0 ]`

![chmod +x del script](/img/sprint3/3-backup-chmod.png)
> **Figura 3** – `sudo nano /usr/local/bin/backup_nexorder.sh` y `sudo chmod +x` del script

---

### 2.3 Prueba Manual

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

![Prueba manual del backup](/img/sprint3/4-backup-manual-test.png)
> **Figura 4** – `ls -lh /backups/` mostrando el `.sql.gz` generado + `tail -5 nexorder_backup.log` con entradas `[ÉXITO]` y `[INFO] Limpieza`

---

## 3. T14: Programación con Cron

El objetivo es automatizar la ejecución del script de backup diariamente a las 03:00 AM, horario de mínima actividad del sistema.

### 3.1 Verificación de Permisos

Antes de configurar cron, se asegura que `ec2-user` puede escribir en el log:

```bash
# Verificar permisos actuales
ls -l /var/log/nexorder_backup.log

# Ajustar para que cron pueda escribir
sudo chown ec2-user:ec2-user /var/log/nexorder_backup.log
sudo chmod 664 /var/log/nexorder_backup.log
```

![Verificación y ajuste de permisos del log](/img/sprint3/5-cron-log-permissions.png)
> **Figura 5** – `ls -l` mostrando el log antes (`-rw-------`) y después (`-rw-rw-r--`) del ajuste de permisos con `chmod 664`

---

### 3.2 Instalación y Activación de Cronie

Amazon Linux 2023 no incluye `crond` por defecto; se instala el paquete `cronie`:

```bash
# Instalar el demonio cron
sudo dnf install cronie -y
```

![Instalación de cronie](/img/sprint3/6-cronie-install.png)
> **Figura 6** – `sudo dnf install cronie -y` instalando `cronie 1.5.7` y `cronie-anacron 1.5.7`

```bash 
# Habilitar para arranque automático e iniciar inmediatamente
sudo systemctl enable crond
sudo systemctl start crond

# Verificar que el servicio está activo
sudo systemctl status crond
```

**Versiones instaladas:** `cronie 1.5.7-1.amzn2023.0.2` y `cronie-anacron 1.5.7-1.amzn2023.0.2`


![Estado del servicio crond](/img/sprint3/7-crond-status.png)
> **Figura 7** – `systemctl status crond` mostrando `active (running)` con PID 2562, con mensajes de inicio `CRON STARTUP (1.5.7)` e `inotify support`

---

### 3.3 Configuración del Crontab

```bash
# Editar el crontab del usuario actual (ec2-user)
crontab -e
```

Línea añadida al final del archivo:

```cron
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

![Crontab con tarea instalada](/img/sprint3/8-crontab-edit-1.png)
![Crontab con tarea instalada](/img/sprint3/8-crontab-edit-2.png)
> **Figura 8** – Editor crontab con el mensaje `installing new crontab` y la línea `0 3 * * *` añadida

![Crontab modo prueba cada minuto](/img/sprint3/9-crontab-test-mode.png)
> **Figura 9** – Editor crontab mostrando la versión de prueba `* * * * *` (cada minuto) junto a la definitiva `0 3 * * *`

---

### 3.4 Verificación y Prueba

```bash
# Verificar que el crontab se guardó correctamente
crontab -l
```

**Resultado:**
```
0 3 * * * /usr/local/bin/backup_nexorder.sh >> /var/log/nexorder_backup.log 2>&1
```

Para validar sin esperar a las 03:00 AM, se ejecutó temporalmente con `* * * * *` (cada minuto), generando múltiples backups que confirman el funcionamiento correcto.

![crontab -l con tarea verificada](/img/sprint3/10-crontab-verify.png)
> **Figura 10** – `crontab -l` mostrando `0 3 * * * /usr/local/bin/backup_nexorder.sh >> /var/log/nexorder_backup.log 2>&1`

![Listado de backups generados por cron](/img/sprint3/11-backups-listing.png)
> **Figura 11** – `ls -lh /backups/` con 6 archivos `.sql.gz` timestamped generados durante la prueba con `* * * * *`

---

## 4. T15: Rotación de Logs con Logrotate

Sin rotación de logs, los archivos de Apache y MySQL crecen indefinidamente hasta llenar el disco. `logrotate` automatiza el corte, compresión y eliminación de registros antiguos.

### 4.1 Configuración para Apache (httpd)

Se edita el archivo existente (eliminando duplicados para evitar error `duplicate log entry`):

```bash
sudo nano /etc/logrotate.d/httpd
```

Contenido aplicado:

```text
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

![Apertura de /etc/logrotate.d/httpd](/img/sprint3/12-logrotate-httpd-open.png)
> **Figura 12** – Terminal con `sudo nano /etc/logrotate.d/httpd` abriendo el archivo de configuración

![Contenido logrotate httpd en nano](/img/sprint3/13-logrotate-httpd-content-1.png)
![Contenido logrotate httpd en nano](/img/sprint3/13-logrotate-httpd-content-2.png)
> **Figura 13** – Editor nano con el bloque completo de logrotate para `/var/log/httpd/*log` incluyendo `postrotate` con `systemctl reload`

![Validación logrotate httpd en modo debug](/img/sprint3/14-logrotate-httpd-debug.png)
> **Figura 14** – Salida de `sudo logrotate -d /etc/logrotate.d/httpd` mostrando `rotating log /var/log/httpd/access_log after 1 days (7 rotations)` sin errores

---

### 4.2 Configuración para MySQL

```bash
sudo nano /etc/logrotate.d/mysql
```

Contenido:

```text
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

![Apertura de /etc/logrotate.d/mysql](/img/sprint3/15-logrotate-mysql-open.png)
> **Figura 15** – Terminal con `sudo nano /etc/logrotate.d/mysql` abriendo el archivo

![Contenido logrotate mysql y validación debug](/img/sprint3/16-logrotate-mysql-content-1.png)
![Contenido logrotate mysql y validación debug](/img/sprint3/16-logrotate-mysql-content-2.png)
> **Figura 16** – Editor nano con `/etc/logrotate.d/mysql` mostrando `copytruncate` y el bloque completo + salida de `logrotate -d` en modo debug

---

## 5. T16: CloudWatch y Alertas Proactivas

CloudWatch transforma la monitorización de reactiva (revisar el servidor cuando algo falla) a proactiva (recibir alertas antes de que el problema afecte a los usuarios).

### 5.1 Acceso a CloudWatch

Se accede a la consola AWS → búsqueda del servicio → CloudWatch. La página de Overview muestra el estado inicial sin alarmas ni paneles configurados.

![Búsqueda de CloudWatch en consola AWS](/img/sprint3/17-cloudwatch-search.png)
> **Figura 17** – Navegador con la consola AWS y búsqueda de "CloudWatch", mostrando el resultado `CloudWatch - Monitorice recursos y aplicaciones`

![Overview de CloudWatch](/img/sprint3/18-cloudwatch-overview.png)
> **Figura 18** – Página de Overview de CloudWatch con el asistente de configuración inicial y las 4 opciones principales (Crear alarmas, Panel, Registros, Eventos)

---

### 5.2 Creación de Alarma CPU

Se navega a **Alarmas → Crear alarma** y se selecciona la métrica `CPUUtilization` de la instancia EC2.

**Ruta:** `EC2 > Per-Instance Metrics > 09NexOrder-EC2-WEB-09 > CPUUtilization`

Parámetros de la alarma:

| Parámetro | Valor | Razón |
|-----------|-------|-------|
| Métrica | `CPUUtilization` | KPI más crítico de un servidor web |
| Namespace | `AWS/EC2` | Métrica nativa de EC2, sin agente adicional |
| Instance ID | `i-0959d7cac425606cf` | Específica de `09NexOrder-EC2-WEB-09` |
| Estadística | Media | Evalúa el valor promedio del período |
| Período | 1 minuto | Evaluación granular para respuesta rápida |
| Tipo de límite | Estático | Umbral fijo y predecible |
| Condición | Mayor que (`>`) `80` | Alerta cuando la CPU supera el 80% |

**Lógica de activación:** si el valor medio de `CPUUtilization` supera el 80% durante un período de 1 minuto, la alarma pasa de `OK` a `En Alarma`, disparando inmediatamente la acción SNS configurada.

![Selector de métricas con CPUUtilization](/img/sprint3/19-cloudwatch-metric-select.png)
> **Figura 19** – Selector de métricas CloudWatch con `CPUUtilization` de `09NexOrder-EC2-WEB-09` seleccionado (checkbox marcado) y gráfico de línea visible

![Configuración de condiciones de la alarma](/img/sprint3/20-cloudwatch-alarm-conditions.png)
> **Figura 20** – Formulario de condiciones: umbral Estático `> 80`, período 1 minuto, instancia `09NexOrder-EC2-WEB-09`, gráfico con la línea roja en 80%

---

### 5.3 Configuración de Acciones SNS

Una vez definida la métrica y el umbral, se configura la acción automática al saltar la alarma:

- **Activador:** Estado `En modo alarma`
- **Acción:** Enviar notificación al tema SNS `Default_CloudWatch_Alarms_Topic`
- **Correo suscrito:** `victor.serrano.7e8@itb.cat`

Amazon SNS requiere confirmación de la suscripción por email como medida de seguridad. Tras confirmar, la suscripción queda activa con ARN:
`arn:aws:sns:us-east-1:324341945465:Default_CloudWatch_Alarms_Topic:52cc3e53-d32b-40d8-9285-167f14515f4e`

**Nombre de la alarma:** `Alarma_CPU_NexOrder_Serrano`
**Descripción:** `Aviso cuando la CPU supera el 80%`

![Configurar las acciones SNS](/img/sprint3/21-cloudwatch-sns-action.png)
> **Figura 21** – Formulario "Configurar las acciones" con `En modo alarma` seleccionado, tema SNS `Default_CloudWatch_Alarms_Topic` y email `victor.serrano.7e8@itb.cat`

![Confirmación de suscripción SNS](/img/sprint3/22-sns-subscription-confirmed.png)
> **Figura 22** – Página AWS SNS con `¡Suscripción confirmada!` y el ARN completo de la suscripción

![Detalles de la alarma - nombre y descripción](/img/sprint3/23-cloudwatch-alarm-details.png)
> **Figura 23** – Formulario "Agregar detalles de alarma" con nombre `Alarma_CPU_NexOrder_Serrano` y descripción `Aviso cuando la CPU supera el 80%`

![Vista previa completa de la alarma](/img/sprint3/24-cloudwatch-alarm-preview.png)
> **Figura 24** – Página "Ver la vista previa y crear" con los 3 pasos resumidos: métrica CPU, acción SNS y nombre de la alarma antes de confirmar la creación

![Alarma creada correctamente](/img/sprint3/25-cloudwatch-alarm-created.png)
> **Figura 25** – Banner verde `Se ha creado correctamente la alarma Alarma_CPU_NexOrder_Serrano` en el listado de alarmas con estado `Datos insuficientes`

---

### 5.4 Dashboard Personalizado y Métricas EBS

Se crea un dashboard centralizado para visualizar en tiempo real los indicadores más importantes:

```
Nombre del dashboard: Dashboard_NexOrder_Serrano
```

**Widgets configurados:**

**Widget tipo Línea – `CPUUtilization`:** permite observar la tendencia de la CPU a lo largo del tiempo e identificar picos de actividad.

**Widget tipo Número – `VolumeReadBytes` y `VolumeWriteBytes` (EBS):** muestra el valor exacto e instantáneo de bytes leídos y escritos en disco. Métricas seleccionadas desde `EBS > Métricas por volumen` para el volumen `vol-0673cc270ab121...`.

**¿Por qué monitorizar EBS?** Un disco saturado en lecturas o escrituras puede causar degradación de rendimiento en Apache y MySQL. Detectar esta saturación permite actuar antes de que los tiempos de respuesta se disparen.

![Diálogo de creación del panel](/img/sprint3/26-dashboard-create.png)
> **Figura 26** – Diálogo modal "Crear un nuevo panel" con nombre `Dashboard_NexOrder_Serrano` y botón `Crear un panel`

![Dashboard final con los tres widgets](/img/sprint3/27-dashboard-final.png)
> **Figura 27** – Panel final `Dashboard_NexOrder_Serrano` con widget de línea `CPUUtilization` y widgets de número `VolumeReadBytes` (0 B) y `VolumeWriteBytes` (694 kB)

![Selector de tipo de widget](/img/sprint3/28-widget-type-selector.png)
> **Figura 28** – Selector de tipo de widget con `Línea` seleccionado; opciones visibles: Tabla, Número, Medidor, Área apilada, Barra, Gráfico circular, Explorador

![Widget CPU tipo Número](/img/sprint3/29-widget-cpu-number.png)
> **Figura 29** – Selector de métricas con `CPUUtilization` de `NexOrder-EC2-Web` marcado; tipo de widget cambiado a `Número`

![Gráfico de métricas con CPUUtilization](/img/sprint3/30-widget-cpu-line-graph.png)
> **Figura 30** – Pantalla "Añadir gráfico de métrica" con `CPUUtilization` seleccionado y lista completa de métricas EC2 disponibles

![Selector de namespace EBS](/img/sprint3/31-ebs-namespace-selector.png)
> **Figura 31** – Selector de categorías de métricas con el namespace `EBS` (30 métricas) destacado en la lista

![Métricas EBS VolumeReadBytes y VolumeWriteBytes seleccionadas](/img/sprint3/32-ebs-metrics-selected.png)
> **Figura 32** – Lista de métricas EBS con `VolumeReadBytes` y `VolumeWriteBytes` del volumen `vol-0673cc270ab121...` seleccionados; gráfico de previsualización con ambas curvas (azul y naranja)

---

## 6. T17: Script de Despliegue Continuo

El objetivo es automatizar la transferencia de archivos desde un entorno de staging hacia el `DocumentRoot` de Apache, con validación de errores y registro de auditoría completo.

### 6.1 Preparación del Entorno

```bash
# 1. Crear la carpeta de staging (área de preparación antes de producción)
mkdir -p /home/ec2-user/web-staging

# 2. Crear el archivo de log del despliegue
sudo touch /var/log/deploy_nexorder.log

# 3. Asignar propietario para poder escribir sin sudo
sudo chown ec2-user:ec2-user /var/log/deploy_nexorder.log
```

**¿Por qué un directorio de staging?** Permite preparar y revisar los archivos antes de hacerlos públicos. El script hace un espejo exacto del staging en producción, por lo que solo lo que está en staging llega a la web.

![Preparación del entorno de despliegue](/img/sprint3/33-deploy-env-setup.png)
> **Figura 33** – Terminal ejecutando `mkdir -p /home/ec2-user/web-staging`, `touch /var/log/deploy_nexorder.log` y `chown ec2-user` del log

---

### 6.2 Creación del Script

```bash
sudo nano /usr/local/bin/deploy_nexorder.sh
```

Contenido del script con las correcciones aplicadas para Amazon Linux 2023:

[Enllaç al documento: deploy_nexorder.sh](/docs/src/desploy_nexorder.sh)

```bash
sudo chmod +x /usr/local/bin/deploy_nexorder.sh
```

**Decisiones de diseño:**

- **`sudo rsync`**: `/var/www/html/` pertenece al usuario `apache`. Sin `sudo`, el script fallaría al escribir en él.
- **`systemctl reload httpd`** (no `restart`): `reload` recarga la configuración sin interrumpir las conexiones activas.
- **`--delete`**: garantiza que producción sea un espejo exacto del staging. Sin esta opción, los archivos eliminados del staging permanecerían en producción.
- **Doble validación `$?`**: se verifica por separado el éxito de `rsync` y del `reload`, con mensajes específicos para cada fallo.

![Script deploy_nexorder.sh en nano](/img/sprint3/34-deploy-script-nano.png)
> **Figura 34** – Editor nano con el contenido completo de `deploy_nexorder.sh` mostrando la configuración, el bloque `rsync -avz --delete` y la lógica de validación `$?`

---

### 6.3 Simulación y Validación

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

![Archivo version2.html en staging](/img/sprint3/35-staging-version2-html.png)
> **Figura 35** – Editor nano con el contenido de `version2.html` (HTML de prueba con título `NexOrder v2.0` y mensaje de despliegue exitoso)

![Verificación post-despliegue y log](/img/sprint3/36-deploy-verification-log.png)
> **Figura 36** – `ls -l /var/www/html/version2.html` confirmando el archivo en producción (229 bytes, May 10 16:13) + `tail -10 /var/log/deploy_nexorder.log` con las 6 líneas de auditoría del despliegue exitoso

![curl HTTP y HTTPS sobre version2.html](/img/sprint3/37-deploy-curl-test.png)
> **Figura 37** – `curl -I http://localhost/version2.html` devolviendo `301 Moved Permanently` + `curl -k https://localhost/version2.html` devolviendo el HTML completo de `NexOrder v2.0`

---

## 7. T18: Prueba de Restauración y RTO

El RTO (Recovery Time Objective) es el tiempo máximo tolerable para restaurar un servicio tras una caída. Esta tarea mide el RTO real del sistema bajo condiciones controladas.

### 7.1 Verificación del Backup Disponible

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

![Hora de inicio, listado de backups e informe inicial](/img/sprint3/38-restore-start-verify.png)
> **Figura 38** – `date` mostrando `Tue May 12 14:42:27 UTC 2026` + `ls -lh /backups/*.sql.gz` con los archivos disponibles + `nano ~/restore_test.md` con el informe inicial

![restore_test.md en estado inicial](/img/sprint3/39-restore-report-initial.png)
> **Figura 39** – Editor nano con el contenido inicial de `restore_test.md` con los campos pendientes de completar

---

### 7.2 Simulación de Caída (DROP DATABASE)

```bash
# Conectar como administrador a RDS
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u admin -p
```

Dentro de MySQL (`connection id 5249`):

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

![Simulación DROP DATABASE y verificación](/img/sprint3/40-drop-database-simulation.png)
> **Figura 40** – Login MySQL con `connection id 5249`

![Simulación DROP DATABASE y verificación](/img/sprint3/41-drop-database.png)
> **Figura 41** -- `SHOW DATABASES`, `USE nexorder_db`, `SHOW TABLES` (5 tablas), `DROP DATABASE nexorder_db` con `Query OK` y `SHOW DATABASES` final devolviendo `Empty set`

---

### 7.3 Restauración desde Backup

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

![Restauración con gunzip y filtrado SET @@](/img/sprint3/42-restore-gunzip-mysql.png)
> **Figura 42** – Terminal con `gunzip -c backup.sql.gz | grep -v "SET @@SESSION..." | grep -v "SET @@GLOBAL" | mysql ...` + verificación posterior con `SHOW TABLES` mostrando las 5 tablas restauradas

---

### 7.4 Verificación de Integridad

```bash
mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u admin -p
```

```sql
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
| `productos` | 7 | ✅ Íntegro |
| `usuarios` | 2 | ✅ Íntegro |
| `estados` | 5 | ✅ Íntegro |
| `pedidos` | 0 | ✅ OK (vacía por diseño) |
| `detalle_pedidos` | 0 | ✅ OK (vacía por diseño) |

Los datos de prueba (`Ensalada César $8.50`, `Pizza Margarita $12.00`, `Hamburguesa Clásica $10.50`) están presentes y son correctos.

![Verificación de integridad post-restauración](/img/sprint3/43-restore-integrity-check.png)
> **Figura 43** – MySQL mostrando `SHOW TABLES` (5 tablas), `COUNT(*)` de productos (7), usuarios (2) y estados (5), y `SELECT nombre, precio FROM productos LIMIT 3` con datos reales

---

### 7.5 Cálculo del RTO

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

**Informe final `~/restore_test.md`:**

[Enllaç al documento: restore_test.md](/docs/src/restore_test.md)

![Hora de fin y cálculo del RTO](/img/sprint3/44-rto-calculation.png)
> **Figura 44** – `date` mostrando `Tue May 12 15:06:28 UTC 2026` con el cálculo manual `15:06:28 - 14:42:27 = 0:24:01`

![restore_test.md completado](/img/sprint3/45-restore-report-final.png)
> **Figura 45** – Editor nano con `restore_test.md` completado: hora inicio, hora fin, RTO calculado y resultado final con los tres checks

---

## 8. T19: Auditoría de Seguridad con nmap

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
|--------|--------|---------|
| `22/tcp` | Abierto | SSH (restringido a IP admin por Security Group) |
| `80/tcp` | Abierto | HTTP (redirige automáticamente a HTTPS) |
| `443/tcp` | Abierto | HTTPS (TLS con certificado autofirmado) |

**Interpretación:**
- **Solo 3 puertos abiertos** en el rango 1-1000: superficie de ataque mínima, consistente con la política de mínimo privilegio aplicada desde el Sprint 1.
- **Puerto 3306 (MySQL) cerrado**: la BD no es alcanzable desde Internet (solo desde `SG-Web-NexOrder` por Security Group).
- **Conexión estable**: baja latencia entre la máquina Kali y el servidor AWS confirma conectividad correcta.
- **Ningún servicio innecesario expuesto**: no hay APIs internas, paneles de administración ni servicios de datos accesibles públicamente.

![Escaneo nmap desde Kali Linux](/img/sprint3/45-nmap-scan-result.png)
> **Figura 46** – Terminal Kali Linux (`kali@VictorS`) ejecutando `nmap -p 1-1000 -T4 -A -V 44.207.176.14` con la salida completa del escaneo mostrando el progreso de NSE scripts y el resultado final

---

## 9. Justificación de Criterios

### 9.1 M036
4 – Administración Remota y Automatización

| Evidencia | Tarea | Estado |
|-----------|-------|--------|
| Script Bash `backup_nexorder.sh` con control de errores `$?` y log timestamped | T13 | ✅ |
| Tarea `cron` (`0 3 * * *`) con rutas absolutas y redirección `2>&1` | T14 | ✅ |
| Script Bash `deploy_nexorder.sh` con `rsync`, doble validación y `systemctl reload` | T17 | ✅ |
| Gestión de servicios con `systemctl` (crond, httpd) | T14, T17 | ✅ |

### 9.2 M036
7 – Backups Lógicos y Rotación

| Evidencia | Tarea | Estado |
|-----------|-------|--------|
| Exportación lógica con `mysqldump` + compresión `gzip` en pipeline | T13 | ✅ |
| Política de retención 7 días con `find -mtime +7 -delete` automatizada | T13 | ✅ |
| Rotación de logs Apache: `daily`, `rotate 7`, `compress`, `postrotate reload` | T15 | ✅ |
| Rotación de logs MySQL: `daily`, `rotate 7`, `compress`, `copytruncate` | T15 | ✅ |

### 9.3 M036
8 – Auditoría y Recuperación

| Evidencia | Tarea | Estado |
|-----------|-------|--------|
| Registro timestamped en `/var/log/` para backups y despliegues | T13, T17 | ✅ |
| Procedimiento de recuperación documentado y ejecutado (`DROP → restore → verify`) | T18 | ✅ |
| RTO real calculado y documentado: **24 min 01s** | T18 | ✅ |
| Informe `restore_test.md` con tiempos, pasos y resultado | T18 | ✅ |

### 9.4 C036
 – Seguridad y Resiliencia

| Evidencia | Tarea | Mecanismo |
|-----------|-------|-----------|
| CloudWatch `CPUUtilization > 80%` → SNS email automático | T16 | Monitorización proactiva |
| Dashboard con CPU + `VolumeReadBytes` + `VolumeWriteBytes` | T16 | Visibilidad centralizada |
| `rsync --delete` + `systemctl reload` (fallo seguro) | T17 | Despliegue controlado |
| Filtrado `grep -v "SET @@"` para compatibilidad RDS | T18 | Resiliencia en servicio gestionado |
| nmap confirma superficie de exposición mínima (3 puertos) | T19 | Auditoría externa |
| Permisos `700`/`600` en backups y logs sensibles | T13 | Protección de datos en reposo |

---

*Documentación completada: 27 de abril – 3 de mayo 2026*

*Autores: Victor Serrano · Trishan Mizhquiri*