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