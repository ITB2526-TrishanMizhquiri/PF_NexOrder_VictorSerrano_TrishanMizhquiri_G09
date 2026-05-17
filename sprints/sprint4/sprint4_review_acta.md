## 📄 `docs/actas/sprint4_planning.md`

```markdown
# Acta Sprint Planning - Sprint 4
**Proyecto:** NexOrder Infrastructure  
**Semana:** S4  
**Fecha:** 4 de mayo 2026 - 12 de mayo 2026  
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
   - [6.2 Avanços intermedis (8 de maig)](#62-avanços-intermedis-8-de-maig)
   - [6.3 Finalització del Sprint](#63-finalització-del-sprint)

---

## 1. Objetivo del Sprint
Completar la entrega final del proyecto NexOrder: migrar a certificados SSL reales con Let's Encrypt, replicar backups a S3 para redundancia geográfica, aplicar hardening avanzado con SELinux, realizar auditoría CIS Benchmarks y consolidar toda la documentación técnica para defensa del proyecto.

---

## 2. Alcance del Sprint (Scope)

### 2.1 Tareas Planificadas

| ID | Tarea | Descripción | Responsable | Esfuerzo (h) | Dependencias |
|----|-------|-------------|-------------|--------------|--------------|
| T20 | Implementar WAF básico | Configurar reglas OWASP Top 10 en AWS WAF para protección capa aplicación | Victor | 3h | SG (S1), Web (S2) |
| T21 | Replicar backups a S3 | Configurar `aws s3 sync` en backup_nexorder.sh para copia en S3 con ciclo de vida | Trishan | 2.5h | T13, T14 (S3) |
| T22 | Hardening kernel + SELinux | Activar SELinux en modo enforcing, auditar con `ausearch`, ajustar políticas | Victor | 3h | EC2 (S1), Hardening (S1) |
| T23 | Migrar a Let's Encrypt | Instalar certbot, obtener certificado válido, configurar renovación automática | Trishan | 2.5h | T08 (S2), DNS público |
| T24 | Logging estructurado PHP | Implementar logs JSON en aplicación para análisis centralizado en CloudWatch Logs | Ambos | 2h | T16 (S3), PHP (S2) |
| T25 | Auditoría CIS Benchmarks | Ejecutar script de auditoría CIS para Amazon Linux 2023, remediar hallazgos críticos | Victor | 1h | Todo el sprint |

**Total esfuerzo estimado:** 14 horas

---

## 3. Dependencias Críticas
1. **T20** requiere que los Security Groups estén correctamente configurados y que el tráfico web esté pasando por HTTPS
2. **T21** requiere que el script de backup (T13) funcione correctamente y que existan permisos IAM para S3
3. **T22** requiere acceso root y conocimiento de políticas SELinux; puede requerir reinicio de servicios
4. **T23** requiere un dominio público válido o uso de DNS temporal; certbot necesita puerto 80 abierto para validación HTTP-01
5. **T24** requiere que la aplicación PHP esté funcional y que CloudWatch Logs Agent esté instalado
6. **T25** es la tarea final de cierre; requiere que todas las anteriores estén completadas para auditar el estado final

---

## 4. Agenda de la Reunión Planning

1. **Revisión de objetivos del Sprint** (10 min)
   - Presentar alcance final, entregables de cierre y alineación con criterios M0379, M0380 y C037
   
2. **Análisis de tareas y asignación** (20 min)
   - Revisar cada tarea (T20-T25)
   - Confirmar responsables, estimaciones de esfuerzo y recursos necesarios
   
3. **Identificación de dependencias y riesgos** (15 min)
   - Mapear dependencias críticas entre WAF, backups S3 y auditoría CIS
   - Discutir posibles bloqueos (ej. validación de dominio para Let's Encrypt, políticas SELinux restrictivas)
   
4. **Acuerdos y definición de Done** (10 min)
   - Establecer criterios de aceptación para entrega final
   - Definir formato, ubicación y nomenclatura de evidencias para defensa

---

## 5. Acuerdos del Sprint

### 5.1 Criterios Técnicos
- **WAF:** Reglas OWASP Top 10 activas (SQLi, XSS, RCE), modo "Count" inicial para testing
- **Backups S3:** `aws s3 sync` con `--delete`, ciclo de vida: 7 días Standard → 30 días Glacier
- **SELinux:** Modo `enforcing`, políticas personalizadas solo para servicios críticos, `ausearch` limpio
- **Let's Encrypt:** Certificado válido 90 días, renovación automática vía cron, HSTS mantenido
- **Logging PHP:** Formato JSON, campos: timestamp, level, message, user_id, request_id
- **CIS Audit:** <5 hallazgos críticos, plan de remediación documentado para los restantes

### 5.2 Evidencias Requeridas
- Capturas de consola AWS WAF con reglas OWASP configuradas
- Salida de `aws s3 ls` mostrando backups replicados + configuración de ciclo de vida en S3
- `getenforce` mostrando `Enforcing` + `ausearch -m avc -ts recent` sin denegaciones críticas
- Certificado Let's Encrypt válido (`openssl s_client -connect`) + cron de renovación
- Ejemplo de log JSON en CloudWatch Logs + configuración del agente
- Reporte de auditoría CIS con resumen de hallazgos y acciones de remediación

### 5.3 Definición de Done
- [ ] WAF activo con reglas OWASP Top 10 en modo "Block" tras testing
- [ ] Backups replicados en S3 con política de ciclo de vida configurada
- [ ] SELinux en modo enforcing sin bloqueos de servicios críticos
- [ ] Certificado Let's Encrypt válido y renovación automática verificada
- [ ] Logs PHP en formato JSON visibles en CloudWatch Logs
- [ ] Auditoría CIS completada con <5 hallazgos críticos y plan documentado
- [ ] Documentación final consolidada y entrega completa en ProfHub

---

## 6. Seguiment Visual a ProofHub

### 6.1 Estat inicial de la planificació (ProofHub)
A continuació es mostra el tauler de gestió amb totes les tasques T20-T25 creades i assignades abans de l'inici de les execucions:

![ProofHub - Tasques inicials S4](/img/sprint4/proofhub-inicial-1.png)
![ProofHub - Tasques inicials S4](/img/sprint4/proofhub-inicial-2.png)
![ProofHub - Tasques inicials S4](/img/sprint4/proofhub-inicial-3.png)

> 📸 **Figura 6.1:** Estat inicial del tauler ProofHub amb tasques T20-T25 en estat "Per fer".

---

### 6.2 Avanços intermedis (8 de maig)
Estat del projecte a mitjan sprint, amb la configuració de WAF, backups S3 i SELinux en procés de validació.

![ProofHub - Tasques en curs S4](/img/sprint4/proofhub-08maig-1.png)
![ProofHub - Tasques en curs S4](/img/sprint4/proofhub-08maig-2.png)
![ProofHub - Tasques en curs S4](/img/sprint4/proofhub-08maig-3.png)

> 📸 **Figura 6.2:** Avanç a 8 de maig. T20, T21, T22 completades, T23 i T24 en execució.

---

### 6.3 Finalització del Sprint
Tauler completat amb totes les tasques T20-T25 marcades com a completades i evidències d'auditoria CIS i entrega final adjuntes.

![ProofHub - Tasques finalitzades S4](/img/sprint4/proofhub-final-1.png)
![ProofHub - Tasques finalitzades S4](/img/sprint4/proofhub-final-2.png)
![ProofHub - Tasques finalitzades S4](/img/sprint4/proofhub-final-3.png)

> 📸 **Figura 6.3:** Sprint 4 tancat. Totes les tasques a "Completat" amb projecte entregat i auditat.

---
```

---

## 📄 `docs/actas/sprint4_review.md`

```markdown
# Acta Sprint Review - Sprint 4
**Proyecto:** NexOrder Infrastructure  
**Semana:** S4  
**Fecha:** 4 de mayo 2026 - 12 de mayo 2026  
**Responsables:** Victor Serrano, Trishan Mizhquiri  
**Prioridad:** Alta

---

## 📋 Índice
1. [Resumen del Sprint](#1-resumen-del-sprint)
2. [Checklist de Validación de Entregables](#2-checklist-de-validación-de-entregables)
3. [Revisión de Criterios de Aceptación](#3-revisión-de-criterios-de-aceptación)
   - [3.1 Seguridad Avanzada](#31-seguridad-avanzada)
   - [3.2 Resiliencia y Backups](#32-resiliencia-y-backups)
   - [3.3 Auditoría y Cumplimiento](#33-auditoría-y-cumplimiento)
   - [3.4 Documentación](#34-documentación)
4. [Evidencias Adjuntas](#4-evidencias-adjuntas)
5. [Observaciones y Lecciones Aprendidas](#5-observaciones-y-lecciones-aprendidas)
   - [5.1 Fortalezas](#51-fortalezas)
   - [5.2 Mejoras para Futuros Proyectos](#52-mejoras-para-futuros-proyectos)
   - [5.3 Incidentes de Seguridad Resueltos](#53-incidentes-de-seguridad-resueltos)
   - [5.4 Retrabajo y Gestión de Imprevistos](#54-retrabajo-y-gestión-de-imprevistos)
6. [Acuerdos para Mantenimiento Post-Proyecto](#6-acuerdos-para-mantenimiento-post-proyecto)
7. [Actualización ProfHub](#7-actualización-profhub)
8. [Métricas del Sprint](#8-métricas-del-sprint)

---

## 1. Resumen del Sprint

**Objetivo:** Completar la entrega final del proyecto NexOrder: migrar a certificados SSL reales con Let's Encrypt, replicar backups a S3, aplicar hardening avanzado con SELinux, realizar auditoría CIS Benchmarks y consolidar documentación para defensa.

**Resultado:** ✅ **SPRINT COMPLETADO EXITOSAMENTE**  
Todas las tareas T20-T25 completadas y validadas. Proyecto entregado y auditado.

**⚠️ Nota importante:** Durante la configuración de Let's Encrypt se detectó que el dominio temporal no resolvía correctamente. Se solucionó usando validación DNS-01 en lugar de HTTP-01, añadiendo el registro TXT requerido en el proveedor DNS.

---

## 2. Checklist de Validación de Entregables

| ID | Entregable | Estado | Evidencia | Responsable |
|----|------------|--------|-----------|-------------|
| T20 | WAF con reglas OWASP Top 10 configuradas | ✅ Completado | Captura consola AWS WAF | Victor |
| T20 | WAF en modo "Block" tras testing inicial | ✅ Completado | Captura estado WAF + logs | Victor |
| T20 | Prueba de bloqueo SQLi/XSS simulada | ✅ Completado | Captura request bloqueado | Victor |
| T21 | Script backup_nexorder.sh actualizado con `aws s3 sync` | ✅ Completado | Captura script modificado | Trishan |
| T21 | Backups replicados en bucket S3 `nexorder-backups-prod` | ✅ Completado | Captura `aws s3 ls` | Trishan |
| T21 | Política de ciclo de vida: 7d Standard → 30d Glacier | ✅ Completado | Captura configuración S3 | Trishan |
| T22 | SELinux en modo `enforcing` (`getenforce`) | ✅ Completado | Captura terminal `getenforce` | Victor |
| T22 | Políticas personalizadas para httpd y mysqld | ✅ Completado | Captura `semanage fcontext` | Victor |
| T22 | `ausearch -m avc -ts recent` sin denegaciones críticas | ✅ Completado | Captura salida ausearch | Victor |
| T23 | Certbot instalado y certificado Let's Encrypt obtenido | ✅ Completado | Captura `certbot certonly` | Trishan |
| T23 | Apache configurado con certificado válido (no autofirmado) | ✅ Completado | Captura `openssl s_client` | Trishan |
| T23 | Cron de renovación automática configurado (`certbot renew --dry-run`) | ✅ Completado | Captura prueba de renovación | Trishan |
| T24 | Logging PHP en formato JSON implementado | ✅ Completado | Captura ejemplo de log JSON | Ambos |
| T24 | CloudWatch Logs Agent instalado y logs visibles | ✅ Completado | Captura consola CloudWatch Logs | Ambos |
| T25 | Auditoría CIS Benchmarks ejecutada | ✅ Completado | Captura reporte inicial | Victor |
| T25 | <5 hallazgos críticos tras remediación | ✅ Completado | Captura reporte final | Victor |
| T25 | Plan de remediación documentado para hallazgos restantes | ✅ Completado | Captura documento remediation_plan.md | Victor |

**Total tareas:** 17  
**Completadas:** 17 ✅  
**Pendientes:** 0  
**Bloqueadas:** 0

---

## 3. Revisión de Criterios de Aceptación

### 3.1 Seguridad Avanzada
- [x] WAF activo con reglas OWASP Top 10 (SQLi, XSS, RCE) en modo "Block"
- [x] Certificado Let's Encrypt válido (90 días) con renovación automática
- [x] SELinux en modo enforcing sin bloqueos de servicios críticos
- [x] Logging estructurado JSON para trazabilidad de eventos de seguridad

### 3.2 Resiliencia y Backups
- [x] Backups replicados en S3 con redundancia geográfica
- [x] Política de ciclo de vida: 7 días Standard → 30 días Glacier (optimización costes)
- [x] Prueba de restauración desde S3 validada (RTO mantenido <30 min)

### 3.3 Auditoría y Cumplimiento
- [x] Auditoría CIS Benchmarks para Amazon Linux 2023 ejecutada
- [x] <5 hallazgos críticos tras remediación
- [x] Plan de remediación documentado para hallazgos de media/baja prioridad
- [x] Cumplimiento GDPR/LOPD validado: datos cifrados, acceso restringido, logs auditados

### 3.4 Documentación
- [x] Documentación técnica final consolidada en `docs/docs_tecnic.md`
- [x] Manual de operaciones y procedimientos de emergencia actualizado
- [x] Presentación ejecutiva y defensa técnica preparada
- [x] Entrega completa en ProfHub con evidencias trazables

---

## 4. Evidencias Adjuntas

### T20 - WAF y Protección Aplicación (Victor)
1. ✅ Configuración de AWS WAF con reglas OWASP Top 10
2. ✅ WAF en modo "Block" tras testing inicial
3. ✅ Prueba simulada de SQLi bloqueada (`SELECT * FROM users WHERE id=1' OR '1'='1`)

### T21 - Backups S3 y Ciclo de Vida (Trishan)
4. ✅ Script `backup_nexorder.sh` actualizado con `aws s3 sync --delete`
5. ✅ Bucket `nexorder-backups-prod` con backups replicados
6. ✅ Política de ciclo de vida: transición a Glacier a los 30 días

### T22 - SELinux y Hardening Kernel (Victor)
7. ✅ `getenforce` mostrando `Enforcing`
8. ✅ Políticas personalizadas con `semanage fcontext` para httpd/mysqld
9. ✅ `ausearch -m avc -ts recent` sin denegaciones críticas

### T23 - Let's Encrypt y Renovación Automática (Trishan)
10. ✅ Certbot instalado y certificado obtenido vía DNS-01
11. ✅ Apache configurado con certificado válido (`openssl s_client -connect`)
12. ✅ Cron de renovación automática probado con `--dry-run`

### T24 - Logging Estructurado PHP (Ambos)
13. ✅ Ejemplo de log JSON con campos: timestamp, level, message, user_id, request_id
14. ✅ CloudWatch Logs Agent instalado y logs visibles en consola

### T25 - Auditoría CIS y Cierre (Victor)
15. ✅ Reporte inicial de auditoría CIS con hallazgos identificados
16. ✅ Reporte final con <5 hallazgos críticos tras remediación
17. ✅ Documento `remediation_plan.md` con acciones para hallazgos restantes

---

## 5. Observaciones y Lecciones Aprendidas

### 5.1 Fortalezas
1. **Seguridad por capas:** WAF + SELinux + mínimo privilegio + logging estructurado
2. **Resiliencia probada:** Backups locales + S3 con ciclo de vida optimizado
3. **Cumplimiento auditado:** CIS Benchmarks con remediación documentada
4. **Automatización robusta:** Renovación SSL, backups, despliegues sin intervención manual
5. **Documentación completa:** Desde arquitectura hasta procedimientos de emergencia

### 5.2 Mejoras para Futuros Proyectos
1. **Infraestructura como Código:** Migrar a Terraform/CloudFormation para reproducibilidad
2. **CI/CD Nativo:** Implementar GitHub Actions o CodePipeline para testing automático
3. **Monitoreo de Aplicación:** Añadir métricas de negocio (pedidos/min, tiempo respuesta)
4. **Multi-Región:** Evaluar arquitectura multi-AZ para mayor disponibilidad
5. **Secrets Management:** Migrar credenciales a AWS Secrets Manager

### 5.3 Incidentes de Seguridad Resueltos
- ✅ Validación Let's Encrypt HTTP-01 fallida → Solucionado con DNS-01 + registro TXT
- ✅ SELinux bloqueando httpd → Solucionado con `semanage fcontext` + `restorecon`
- ✅ WAF bloqueando tráfico legítimo → Ajustado reglas a modo "Count" inicial, luego "Block"

### 5.4 Retrabajo y Gestión de Imprevistos ⚠️

**Incidente:** Validación de dominio para Let's Encrypt fallida por resolución DNS incorrecta.

**Impacto:**
- Certificado no pudo obtenerse vía HTTP-01
- Tiempo adicional estimado: +1.5 horas para cambiar a validación DNS-01

**Acciones Correctivas:**
1. ✅ Cambiar método de validación a DNS-01 en certbot
2. ✅ Añadir registro TXT `_acme-challenge` en proveedor DNS
3. ✅ Verificar propagación DNS con `dig _acme-challenge.nexorder.local TXT`
4. ✅ Re-ejecutar `certbot certonly --dns-plugin` con éxito

**Lecciones Aprendidas:**
- 📌 Validar resolución DNS antes de iniciar proceso de certificación
- 📌 Tener preparado método alternativo (DNS-01) si HTTP-01 falla
- 📌 Documentar pasos de validación DNS para futuros renewals
- 📌 Probar renovación automática (`--dry-run`) antes de considerar tarea completada

**Resultado final:** Certificado Let's Encrypt válido, renovación automática configurada, HSTS mantenido.

---

## 6. Acuerdos para Mantenimiento Post-Proyecto

### Tareas de Mantenimiento Recurrente
1. **Victor:** 
   - Revisión mensual de logs CloudWatch y alertas SNS
   - Actualización trimestral de paquetes de seguridad (`dnf update --security`)
   - Auditoría semestral de permisos IAM y Security Groups

2. **Trishan:**
   - Verificación mensual de backups locales y en S3
   - Prueba anual de restauración completa (RTO <30 min)
   - Renovación de certificados (automática, pero verificar logs)

3. **Ambos:**
   - Revisión anual de cumplimiento CIS y actualización de hardening
   - Actualización de documentación ante cambios en infraestructura
   - Capacitación de nuevo personal en procedimientos operativos

### Definición de Done - Mantenimiento
- [ ] Alertas SNS configuradas y probadas para CPU, disco, errores de aplicación
- [ ] Backups verificados mensualmente con checksum MD5/SHA256
- [ ] Documentación de procedimientos actualizada en repositorio central
- [ ] Revisión de seguridad programada cada 6 meses con reporte ejecutivo

---

## 7. Actualización ProfHub

### Tareas Marcadas como Completadas
- [x] T20: Implementar WAF básico con reglas OWASP Top 10 **(Victor)**
- [x] T21: Replicar backups a S3 con ciclo de vida **(Trishan)**
- [x] T22: Hardening kernel + SELinux en modo enforcing **(Victor)**
- [x] T23: Migrar a certificados Let's Encrypt con renovación automática **(Trishan)**
- [x] T24: Logging estructurado PHP en formato JSON **(Ambos)**
- [x] T25: Auditoría CIS Benchmarks y remediación **(Victor)**

### Evidencias Subidas
- [x] Capturas de consola AWS y terminal (17 imágenes organizadas por tarea)
- [x] Documentación técnica final: `docs/docs_tecnic.md`
- [x] Acta de planning: `docs/actas/sprint4_planning.md`
- [x] Acta de review: `docs/actas/sprint4_review.md`
- [x] Scripts actualizados: `backup_nexorder.sh`, `deploy_nexorder.sh`
- [x] Reportes: `cis_audit_report.md`, `remediation_plan.md`

### Comentarios de Retroalimentación
**Victor:**  
"El proyecto NexOrder ha evolucionado de una infraestructura básica a una solución cloud profesional con seguridad por capas, resiliencia probada y cumplimiento auditado. La integración de WAF, SELinux y CIS Benchmarks eleva el estándar de calidad del proyecto."

**Trishan:**  
"La automatización de backups con replicación S3 y la migración a Let's Encrypt garantizan operación continua sin intervención manual. El logging estructurado JSON permite análisis proactivo de incidentes. Proyecto listo para producción."

---

## 8. Métricas del Sprint

| Métrica | Valor |
|---------|-------|
| **Velocidad planificada** | 14 horas |
| **Velocidad real (sin retrabajo)** | ~14 horas |
| **Retrabajo por validación DNS** | +1.5 horas |
| **Velocidad real total** | ~15.5 horas |
| **Desviación** | +10.7% (dentro del margen aceptable <15%) |
| **Tareas completadas** | 6/6 (100%) |
| **Subtareas completadas** | 17/17 (100%) |
| **Defectos encontrados** | 1 (resuelto: validación DNS) |
| **Retrabajo técnico** | 9.7% (configuración Let's Encrypt) |
| **Hallazgos CIS críticos** | 0 (tras remediación) |
| **Disponibilidad estimada** | 99.95% (con WAF + backups S3 + multi-layer security) |

---
