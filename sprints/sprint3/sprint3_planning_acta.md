# Acta Sprint Planning - Sprint 3
**Proyecto:** NexOrder Infrastructure  
**Semana:** S3  
**Fecha:** 27 de abril 2026 - 3 de mayo 2026  
**Responsables:** Victor Serrano, Trishan Mizhquiri  
**Prioridad:** Alta

---

## 📋 Índice
1. [Objetivo del Sprint](#1-objetivo-del-sprint)
2. [Alcance del Sprint (Scope)](#2-alcance-del-sprint-scope)
   - [2.1 Tareas Planificadas](#21-tareas-planificadas)
3. [Dependencias Críticas](#3-dependencias-críticas)
4. [Agenda de la Reunión Planning](#4-agenda-de-la-reunión-planning)
5. [Acuerdos del Sprint](#5-acuerdos-del-sprint)
   - [5.1 Criterios Técnicos](#51-criterios-técnicos)
   - [5.2 Evidencias Requeridas](#52-evidencias-requeridas)
   - [5.3 Definición de Done](#53-definición-de-done)
6. [Seguiment Visual a ProofHub](#6-seguiment-visual-a-proofhub)
   - [6.1 Estat inicial de la planificació](#61-estat-inicial-de-la-planificació-proofhub)
   - [6.2 Avanços intermedis (30 d'abril)](#62-avanços-intermedis-30-dabril)
   - [6.3 Finalització del Sprint](#63-finalització-del-sprint)

---

## 1. Objetivo del Sprint
Implementar automatización de backups lógicos, rotación de logs, monitorización proactiva con CloudWatch/SNS, despliegue continuo mediante `rsync` y pruebas de recuperación ante desastres (cálculo de RTO), finalizando con una auditoría de seguridad externa (`nmap`) para validar la superficie de exposición.

---

## 2. Alcance del Sprint (Scope)

### 2.1 Tareas Planificadas

| ID | Tarea | Descripción | Responsable | Esfuerzo (h) | Dependencias |
|----|-------|-------------|-------------|--------------|--------------|
| T13 | Script backup automatizado | `backup_nexorder.sh` con `mysqldump`, `gzip`, timestamp YYYYMMDD y retención 7d | Trishan | 3h | RDS (S1) |
| T14 | Configurar cron ejecución programada | Instalación `cronie`, programación `0 3 * * *`, redirección `2>&1` a log de auditoría | Trishan | 1.5h | T13 |
| T15 | Implementar rotación de logs | Configurar `logrotate` para `httpd` y `mysql` (daily, rotate 7, compress, postrotate) | Victor | 1.5h | EC2 (S1) |
| T16 | CloudWatch y alertas proactivas | Alarma CPU >80% (periodo 1 min), tema SNS email, Dashboard con métricas EBS Read/Write | Victor | 3h | EC2 (S1) |
| T17 | Script despliegue continuo | `deploy_nexorder.sh` con `rsync -avz --delete` (staging→prod), `reload httpd`, log auditoría | Trishan | 2.5h | Web (S2) |
| T18 | Prueba restauración backup | Simular `DROP DB`, restaurar `gunzip \| mysql` (filtrando `SET@@`), verificar integridad, medir RTO | Trishan | 2h | T13, T14 |
| T19 | Auditoría de Seguridad | Escaneo `nmap -sV` desde Kali para validar puertos expuestos, versiones y latencia | Victor | 0.5h | SG (S1) |

**Total esfuerzo estimado:** 14 horas

---

## 3. Dependencias Críticas
1. **T14** requiere que **T13** esté validada (el script debe ejecutarse manualmente sin errores antes de programarlo en cron)
2. **T15** requiere acceso `sudo` a `/etc/logrotate.d/` y que los servicios `httpd` y `mysqld` estén generando logs activos
3. **T16** requiere que la EC2 esté operativa y tenga permisos de monitoreo habilitados en IAM/CloudWatch
4. **T18** depende de que **T13/T14** hayan generado al menos un backup válido en `/backups/` para la simulación de caída
5. **T17** requiere que el entorno `web-staging` esté configurado y que `httpd` responda en `/var/www/html/`
6. **T19** es independiente pero requiere que los Security Groups permitan tráfico ICMP/TCP desde la IP de la máquina Kali para el escaneo

---

## 4. Agenda de la Reunión Planning

1. **Revisión de objetivos del Sprint** (10 min)
   - Presentar alcance, entregables esperados y alineación con criterios M0374, M0377, M0378 y C037
   
2. **Análisis de tareas y asignación** (20 min)
   - Revisar cada tarea (T13-T19)
   - Confirmar responsables, estimaciones de esfuerzo y recursos necesarios
   
3. **Identificación de dependencias y riesgos** (15 min)
   - Mapear dependencias críticas entre backups, cron y restauración
   - Discutir posibles bloqueos (ej. permisos `cronie`, rutas absolutas, restricciones `SUPER` en RDS, límites de SNS)
   
4. **Acuerdos y definición de Done** (10 min)
   - Establecer criterios de aceptación para RTO, logrotate y alertas CloudWatch
   - Definir formato, ubicación y nomenclatura de evidencias

---

## 5. Acuerdos del Sprint

### 5.1 Criterios Técnicos
- **Backup:** `mysqldump` comprimido con `gzip`, timestamp `YYYYMMDD_HHMMSS`, retención automática `find -mtime +7 -delete`
- **Cron:** `0 3 * * *` con redirección explícita `>> /var/log/nexorder_backup.log 2>&1` (rutas absolutas obligatorias)
- **Logrotate:** `daily`, `rotate 7`, `compress`, `postrotate systemctl reload httpd` (sin errores de entrada duplicada)
- **CloudWatch:** Alarma estática `CPUUtilization > 80%` (evaluación 1 min), tema SNS configurado y suscrito, Dashboard con widgets Línea y Número
- **Deploy:** `rsync -avz --delete` desde `/home/ec2-user/web-staging/`, `sudo systemctl reload httpd` solo si `$? -eq 0`
- **Auditoría:** `nmap -sV -T4 <IP>` validando solo puertos 22, 80/443 expuestos y latencia estable

### 5.2 Evidencias Requeridas
- Capturas de terminal ejecutando `backup_nexorder.sh` y `deploy_nexorder.sh`
- Salida de `crontab -l` y `tail -5 /var/log/nexorder_backup.log`
- Archivos `/etc/logrotate.d/httpd` y `/etc/logrotate.d/mysql` configurados
- Dashboard CloudWatch con widgets CPU, VolumeReadBytes, VolumeWriteBytes
- Alarma CPU >80% vinculada a SNS y correo de confirmación recibido
- Log de restauración simulada (`restore_test.md`) con cálculo de RTO (<30 min)
- Salida de `nmap` mostrando servicios detectados y latencia

### 5.3 Definición de Done
- [ ] Script backup ejecutable manualmente y vía cron sin errores
- [ ] Logrotate configurado y verificando compresión de logs antiguos
- [ ] Alarma CloudWatch activa con notificación SNS recibida exitosamente
- [ ] Deploy script sincroniza staging → producción y recarga httpd correctamente
- [ ] Prueba de restauración completada con RTO documentado y datos íntegros
- [ ] Auditoría `nmap` validada y reporte generado
- [ ] Documentación técnica y actas actualizadas en el repositorio

---

## 6. Seguiment Visual a ProofHub

### 6.1 Estat inicial de la planificació (ProofHub)
A continuació es mostra el tauler de gestió amb totes les tasques T13-T19 creades i assignades abans de l'inici de les execucions:

![ProofHub - Tasques inicials S3](/img/sprint3/proofhub/proofhub-inicial-1.png)
![ProofHub - Tasques inicials S3](/img/sprint3/proofhub/proofhub-inicial-2.png)
![ProofHub - Tasques inicials S3](/img/sprint3/proofhub/proofhub-inicial-3.png)

> 📸 **Figura 6.1:** Estat inicial del tauler ProofHub amb tasques T13-T19 en estat "Per fer".

---

### 6.2 Avanços intermedis (30 d'abril)
Estat del projecte a mitjan sprint, amb la configuració de backups, cron, logrotate i CloudWatch en procés de validació.

![ProofHub - Tasques en curs S3](/img/sprint3/proofhub/proofhub-30abril-1.png)
![ProofHub - Tasques en curs S3](/img/sprint3/proofhub/proofhub-30abril-2.png)
![ProofHub - Tasques en curs S3](/img/sprint3/proofhub/proofhub-30abril-3.png)

> 📸 **Figura 6.2:** Avanç a 30 d'abril. T13, T14, T15 completades, T16 i T17 en execució.

---

### 6.3 Finalització del Sprint
Tauler completat amb totes les tasques T13-T19 marcades com a completades i evidències de monitorització, DR i auditoria adjuntes.

![ProofHub - Tasques finalitzades S3](/img/sprint3/proofhub/proofhub-final-1.png)
![ProofHub - Tasques finalitzades S3](/img/sprint3/proofhub/proofhub-final-2.png)
![ProofHub - Tasques finalitzades S3](/img/sprint3/proofhub/proofhub-final-3.png)

> 📸 **Figura 6.3:** Sprint 3 tancat. Totes les tasques a "Completat" amb resiliència i monitorització validades.

---