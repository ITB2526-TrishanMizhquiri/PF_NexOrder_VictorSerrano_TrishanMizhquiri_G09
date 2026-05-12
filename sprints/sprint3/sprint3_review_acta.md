# Acta Sprint Review - Sprint 3
**Proyecto:** NexOrder Infrastructure  
**Semana:** S3  
**Fecha:** 27 de abril 2026 - 3 de mayo 2026  
**Responsables:** Victor Serrano, Trishan Mizhquiri  
**Prioridad:** Alta

---

## 📋 Índice
1. [Resumen del Sprint](#1-resumen-del-sprint)
2. [Checklist de Validación de Entregables](#2-checklist-de-validación-de-entregables)
3. [Revisión de Criterios de Aceptación](#3-revisión-de-criterios-de-aceptación)
   - [3.1 Automatización y Backups](#31-automatización-y-backups)
   - [3.2 Monitorización y Alertas](#32-monitorización-y-alertas)
   - [3.3 Logs y Auditoría](#33-logs-y-auditoría)
   - [3.4 Documentación](#34-documentación)
4. [Evidencias Adjuntas](#4-evidencias-adjuntas)
5. [Observaciones y Lecciones Aprendidas](#5-observaciones-y-lecciones-aprendidas)
   - [5.1 Fortalezas](#51-fortalezas)
   - [5.2 Mejoras para Siguiente Sprint](#52-mejoras-para-siguiente-sprint)
   - [5.3 Incidentes de Seguridad Resueltos](#53-incidentes-de-seguridad-resueltos)
   - [5.4 Retrabajo y Gestión de Imprevistos](#54-retrabajo-y-gestión-de-imprevistos)
6. [Acuerdos para Sprint 4](#6-acuerdos-para-sprint-4)
7. [Actualización ProfHub](#7-actualización-profhub)
8. [Métricas del Sprint](#8-métricas-del-sprint)

---

## 1. Resumen del Sprint

**Objetivo:** Implementar automatización de backups lógicos, rotación de logs, monitorización proactiva con CloudWatch/SNS, despliegue continuo mediante `rsync` y pruebas de recuperación ante desastres (cálculo de RTO).

**Resultado:** ✅ **SPRINT COMPLETADO EXITOSAMENTE**  
Todas las tareas T13-T19 completadas y validadas.

**⚠️ Nota importante:** Durante la restauración de backup en RDS se detectó que las sentencias `SET @@SESSION.SQL_LOG_BIN` y `SET @@GLOBAL` eran bloqueadas por restricciones de privilegios `SUPER`. Se solucionó filtrando estas líneas con `grep -v` antes de importar, validando integridad posterior con `COUNT(*) > 0`.

---

## 2. Checklist de Validación de Entregables

| ID | Entregable | Estado | Evidencia | Responsable |
|----|------------|--------|-----------|-------------|
| T13 | Script `backup_nexorder.sh` creado | ✅ Completado | Captura archivo + ejecución | **Trishan** |
| T13 | Directorio `/backups` con permisos 700 | ✅ Completado | Captura `ls -la` | **Trishan** |
| T13 | Backup comprimido `.sql.gz` con timestamp | ✅ Completado | Captura `ls -lh /backups` | **Trishan** |
| T13 | Retención automática 7 días (`find -mtime +7`) | ✅ Completado | Captura script + log | **Trishan** |
| T14 | Paquete `cronie` instalado y activo | ✅ Completado | Captura `dnf install` + `systemctl status` | **Trishan** |
| T14 | Crontab configurado `0 3 * * *` | ✅ Completado | Captura `crontab -l` | **Trishan** |
| T14 | Log auditoría con redirección `2>&1` | ✅ Completado | Captura `tail -5 /var/log/nexorder_backup.log` | **Trishan** |
| T15 | `/etc/logrotate.d/httpd` configurado | ✅ Completado | Captura archivo + validación | **Victor** |
| T15 | `/etc/logrotate.d/mysql` configurado | ✅ Completado | Captura archivo + validación | **Victor** |
| T15 | Rotación diaria + compresión + 7 días retenidos | ✅ Completado | Captura ejecución `logrotate -d` | **Victor** |
| T16 | Métricas CloudWatch activas (CPU, EBS) | ✅ Completado | Captura consola AWS | **Victor** |
| T16 | Alarma CPU >80% (periodo 1 min) creada | ✅ Completado | Captura configuración alarma | **Victor** |
| T16 | SNS Topic suscrito y email confirmado | ✅ Completado | Captura email + consola SNS | **Victor** |
| T16 | Dashboard con widgets Línea y Número | ✅ Completado | Captura panel personalizado | **Victor** |
| T17 | Script `deploy_nexorder.sh` con `rsync -avz --delete` | ✅ Completado | Captura archivo + ejecución | **Trishan** |
| T17 | Prueba staging → producción exitosa | ✅ Completado | Captura `curl -k https://localhost/version2.html` | **Trishan** |
| T18 | Simulación `DROP DATABASE` ejecutada | ✅ Completado | Captura MySQL antes/después | **Trishan** |
| T18 | Restauración con `gunzip \| grep -v \| mysql` | ✅ Completado | Captura terminal de restore | **Trishan** |
| T18 | Verificación integridad (`SHOW TABLES`, `COUNT(*)`) | ✅ Completado | Captura consultas de validación | **Trishan** |
| T18 | RTO calculado y documentado (24 min 01s) | ✅ Completado | Captura `restore_test.md` | **Trishan** |
| T19 | Escaneo `nmap -sV` ejecutado desde Kali | ✅ Completado | Captura terminal Kali | **Victor** |
| T19 | Puertos 22, 80, 443 validados como únicos expuestos | ✅ Completado | Captura salida `nmap` | **Victor** |

**Total tareas:** 22  
**Completadas:** 22 ✅  
**Pendientes:** 0  
**Bloqueadas:** 0

---

## 3. Revisión de Criterios de Aceptación

### 3.1 Automatización y Backups
- [x] Script `backup_nexorder.sh` ejecutable manualmente y vía cron sin errores
- [x] Backup lógico comprimido con `gzip` y timestamp `YYYYMMDD_HHMMSS`
- [x] Retención automática de 7 días implementada con `find -mtime +7 -delete`
- [x] Cron programado a las 03:00 AM con rutas absolutas y redirección `2>&1`
- [x] Log de auditoría con stdout y stderr capturados en `/var/log/nexorder_backup.log`

### 3.2 Monitorización y Alertas
- [x] Métricas CPU, VolumeReadBytes, VolumeWriteBytes visibles en CloudWatch
- [x] Alarma estática `CPUUtilization > 80%` evaluada cada 1 minuto
- [x] Notificación SNS configurada, suscrita y correo de confirmación recibido
- [x] Dashboard centralizado con widgets de tipo Línea (CPU) y Número (EBS)

### 3.3 Logs y Auditoría
- [x] `httpd` y `mysql` logs rotan diariamente, comprimen y mantienen 7 días
- [x] `postrotate` recarga `httpd` sin interrupciones del servicio
- [x] Despliegue continuo mediante `rsync --delete` validado con prueba real
- [x] Prueba de restauración completa con RTO documentado (<30 min objetivo)
- [x] Auditoría `nmap` confirma superficie de ataque mínima (solo puertos necesarios)

### 3.4 Documentación
- [x] Documentación técnica actualizada en `docs/sprint3/infra_monitoring.md`
- [x] Capturas de pantalla de todas las tareas (T13-T19)
- [x] Comandos y scripts documentados con rutas absolutas y justificación técnica
- [x] Justificación de criterios M0374, M0377, M0378 y C037 incluida explícitamente

---

## 4. Evidencias Adjuntas

### T13 & T14 - Backup y Cron (Trishan)
1. ✅ Creación directorio `/backups` con permisos `700`
2. ✅ Script `backup_nexorder.sh` con `mysqldump` + `gzip` + timestamp
3. ✅ Prueba manual y verificación de archivo `.sql.gz` generado
4. ✅ Instalación y habilitación de `crond` (`systemctl enable/start`)
5. ✅ `crontab -l` mostrando `0 3 * * * /usr/local/bin/backup_nexorder.sh`
6. ✅ Validación de redirección `2>&1` en log de auditoría

### T15 & T16 - Logrotate y CloudWatch (Victor)
7. ✅ `/etc/logrotate.d/httpd` configurado (`daily`, `rotate 7`, `compress`, `postrotate`)
8. ✅ `/etc/logrotate.d/mysql` configurado (`copytruncate`, `missingok`)
9. ✅ Verificación de ejecución sin errores con `logrotate -d`
10. ✅ Acceso a Métricas y Alarms en consola AWS
11. ✅ Configuración de umbral estático CPU >80% (evaluación 1 min)
12. ✅ Acciones SNS vinculadas y suscripción confirmada por email
13. ✅ Dashboard con widgets: CPU (Línea), VolumeRead/WriteBytes (Número)

### T17 & T18 - Deploy y Restauración (Trishan)
14. ✅ Script `deploy_nexorder.sh` con `rsync -avz --delete` y validación `$?`
15. ✅ Validación de permisos `sudo` y `systemctl reload httpd` solo si rsync exitoso
16. ✅ Prueba con `version2.html` en staging → producción accesible vía HTTPS
17. ✅ `DROP DATABASE nexorder_db` simulado y verificado vacío
18. ✅ Restauración con `gunzip -c ... \| grep -v "SET@@" \| mysql` exitosa
19. ✅ Verificación `SHOW TABLES` (5 tablas) y `COUNT(*) > 0` en cada una
20. ✅ Cálculo RTO: 15:06:28 - 14:42:27 = **24 min 01s** documentado en `restore_test.md`

### T19 - Auditoría de Seguridad (Victor)
21. ✅ Escaneo `nmap -sV -T4` ejecutado desde Kali Linux hacia IP pública EC2
22. ✅ Validación de puertos: `22/tcp (SSH)`, `80/tcp (HTTP)`, `443/tcp (HTTPS)` únicos abiertos
23. ✅ Latencia baja confirmada (<50ms) indicando conexión estable

---

## 5. Observaciones y Lecciones Aprendidas

### 5.1 Fortalezas
1. **Resiliencia probada:** Restauración RDS funcional con RTO dentro de límites aceptables (24 min < 30 min objetivo)
2. **Monitorización proactiva:** CloudWatch + SNS permite respuesta inmediata ante picos de CPU o fallos de disco
3. **Automatización robusta:** Backups y despliegues sin intervención manual, con auditoría completa en logs
4. **Auditoría externa:** `nmap` valida que solo los puertos necesarios están expuestos, reduciendo superficie de ataque
5. **Gestión de logs eficiente:** `logrotate` previene llenado de disco automáticamente sin reinicios de servicio

### 5.2 Mejoras para Siguiente Sprint
1. **Backups remotos:** Replicar `/backups` a S3 mediante `aws cli s3 sync` para redundancia geográfica
2. **SSL real:** Migrar de certificado autofirmado a Let's Encrypt con renovación automática vía `certbot`
3. **WAF básico:** Implementar AWS WAF para protección capa aplicación contra SQLi, XSS y otros ataques OWASP Top 10
4. **CI/CD nativo:** Evaluar GitHub Actions o CodePipeline para reemplazar `deploy.sh` local y ganar trazabilidad
5. **Métricas de App:** Añadir CloudWatch Agent para logs de aplicación PHP y métricas personalizadas de negocio

### 5.3 Incidentes de Seguridad Resueltos
- ✅ Cron no ejecutaba por PATH relativo → Solucionado con rutas absolutas y redirección `2>&1`
- ✅ RDS bloqueaba `SET @@SESSION` durante restore → Solucionado con `grep -v` para filtrar metadatos de sesión
- ✅ Puerto 443 expuesto sin validación → Confirmado seguro con `nmap` y Security Group restrictivo
- ✅ Permisos de `rsync` en `/var/www/html` → Solucionado con `sudo` y validación de código de salida

### 5.4 Retrabajo y Gestión de Imprevistos ⚠️

**Incidente:** Error durante restauración de backup comprimido por restricciones `SUPER` en Amazon RDS.

**Impacto:**
- Restauración falló inicialmente al intentar importar sentencias de sesión no permitidas en servicio gestionado
- Tiempo adicional estimado: +1 hora para investigar y aplicar filtro con `grep -v`

**Acciones Correctivas:**
1. ✅ Filtrado de sentencias con `grep -v "SET@@SESSION.SQL_LOG_BIN"` para evitar bloqueo de binlog
2. ✅ Filtrado adicional de `grep -v "SET@@GLOBAL"` para evitar restricciones de privilegios globales
3. ✅ Validación manual de integridad post-restore (`SHOW TABLES`, `COUNT(*) > 0` en cada tabla)
4. ✅ Documentación del procedimiento completo en `restore_test.md` para futuras recuperaciones

**Lecciones Aprendidas:**
- 📌 RDS es un servicio gestionado: no tiene privilegios `SUPER` completos como una instalación on-premise
- 📌 Siempre filtrar metadatos de sesión al restaurar dumps en entornos gestionados (RDS, Cloud SQL, etc.)
- 📌 Probar el procedimiento de restore en entorno staging antes de aplicarlo en producción
- 📌 Documentar RTO y RPO para cumplir con requisitos de auditoría y SLA del proyecto

**Resultado final:** Restauración exitosa, base de datos operativa con 5 tablas íntegras y RTO medido de **24 minutos y 1 segundo**, dentro del objetivo de <30 minutos.

---

## 6. Acuerdos para Sprint 4

### Tareas Prioritarias
1. **Victor:** 
   - Implementar WAF básico con reglas OWASP Top 10 (T20)
   - Configurar replicación de backups a S3 con ciclo de vida (T21)
   - Hardening de kernel y activación de SELinux en modo enforcing (T22)

2. **Trishan:**
   - Migrar a certificados Let's Encrypt con `certbot` y renovación automática (T23)
   - Implementar logging estructurado (JSON) en PHP para análisis centralizado (T24)
   - Auditoría de compliance CIS Benchmarks para Amazon Linux 2023 (T25)

3. **Ambos:**
   - Documentar procedimientos de DR completos (RTO/RPO, contactos, escalado)
   - Revisar criterios C037, M0379, M0380 para Entrega Final del proyecto
   - Preparar presentación ejecutiva y defensa técnica ante tribunal

### Definición de Done - Sprint 4
- [ ] WAF activo bloqueando reglas OWASP Top 10 validadas con pruebas de penetración básicas
- [ ] Backups replicados en S3 con política de ciclo de vida (7 días estándar → 30 días Glacier)
- [ ] SELinux en modo `enforcing` sin bloqueos de servicios críticos (`ausearch` limpio)
- [ ] Certificados Let's Encrypt válidos, renovables automáticamente y con HSTS activo
- [ ] Auditoría CIS completada con <5 hallazgos críticos y plan de remediación documentado
- [ ] Documentación final consolidada y entrega completa en ProfHub con evidencias trazables

---

## 7. Actualización ProfHub

### Tareas Marcadas como Completadas
- [x] T13: Script backup automatizado con retención 7 días **(Trishan)**
- [x] T14: Configurar cron ejecución programada a las 03:00 AM **(Trishan)**
- [x] T15: Implementar rotación de logs para httpd y mysql **(Victor)**
- [x] T16: Configurar CloudWatch y alertas proactivas con SNS **(Victor)**
- [x] T17: Script despliegue continuo con rsync y validación **(Trishan)**
- [x] T18: Prueba restauración backup con cálculo de RTO **(Trishan)**
- [x] T19: Auditoría de Seguridad con nmap desde Kali **(Victor)**

### Evidencias Subidas
- [x] Capturas de consola AWS y terminal (23 imágenes organizadas por tarea)
- [x] Documentación técnica: `docs/sprint3/infra_monitoring.md`
- [x] Acta de planning: `docs/actas/sprint3_planning.md`
- [x] Acta de review: `docs/actas/sprint3_review.md`
- [x] Scripts operativos: `backup_nexorder.sh`, `deploy_nexorder.sh`, `restore_test.md`
- [x] Configuraciones: `jail.local`, `logrotate.d/httpd`, `logrotate.d/mysql`

### Comentarios de Retroalimentación
**Victor:**  
"CloudWatch y SNS han transformado la infraestructura de reactiva a proactiva. La configuración de logrotate garantiza que el disco no se sature por logs infinitos. El despliegue con rsync es eficiente, trazable y con fallo seguro gracias a la validación de `$?`."

**Trishan:**  
"La prueba de restauración fue crucial para validar la resiliencia real del sistema. Documentar el filtrado de `SET @@` para RDS nos dio experiencia práctica en DR en entornos gestionados. Cron funciona perfectamente con rutas absolutas y la auditoría en logs permite trazabilidad completa de cada ejecución."

---

## 8. Métricas del Sprint

| Métrica | Valor |
|---------|-------|
| **Velocidad planificada** | 14 horas |
| **Velocidad real (sin retrabajo)** | ~14.5 horas |
| **Retrabajo por filtro RDS** | +1 hora |
| **Velocidad real total** | ~15.5 horas |
| **Desviación** | +10.7% (dentro del margen aceptable <15%) |
| **Tareas completadas** | 7/7 (100%) |
| **Subtareas completadas** | 22/22 (100%) |
| **Defectos encontrados** | 1 (resuelto: filtrado SET@@ en restore) |
| **Retrabajo técnico** | 6.5% (configuración restore RDS) |
| **RTO medido** | 24 min 01s (objetivo: <30 min ✅) |
| **Disponibilidad estimada** | 99.9% (con backup + restore validado) |

---

**Próxima reunión:** Sprint Planning S4 - Semana del 4 de mayo - 10 de mayo 2026