# Acta Sprint Review - Sprint 1
**Proyecto:** NexOrder Infrastructure  
**Semana:** S1  
**Fecha:** 13 de abril 2026 - 19 de abril 2026  
**Responsables:** Victor Serrano, Trishan Mizhquiri  
**Prioridad:** Alta

---

## 📋 Índice
1. [Resumen del Sprint](#1-resumen-del-sprint)
2. [Checklist de Validación de Entregables](#2-checklist-de-validación-de-entregables)
3. [Revisión de Criterios de Aceptación](#3-revisión-de-criterios-de-aceptación)
   - [3.1 Infraestructura de Red](#31-infraestructura-de-red)
   - [3.2 Instancias y Conectividad](#32-instancias-y-conectividad)
   - [3.3 Seguridad](#33-seguridad)
   - [3.4 Documentación](#34-documentación)
4. [Evidencias Adjuntas](#4-evidencias-adjuntas)
5. [Observaciones y Lecciones Aprendidas](#5-observaciones-y-lecciones-aprendidas)
   - [5.1 Fortalezas](#51-fortalezas)
   - [5.2 Mejoras para Siguiente Sprint](#52-mejoras-para-siguiente-sprint)
   - [5.3 Incidentes de Seguridad Resueltos](#53-incidentes-de-seguridad-resueltos)
   - [5.4 Retrabajo y Gestión de Imprevistos](#54-retrabajo-y-gestión-de-imprevistos)
6. [Acuerdos para Sprint 2](#6-acuerdos-para-sprint-2)
7. [Actualización ProfHub](#7-actualización-profhub)
8. [Métricas del Sprint](#8-métricas-del-sprint)

---

## 1. Resumen del Sprint

**Objetivo:** Desplegar infraestructura cloud básica en AWS con VPC, EC2, RDS, Security Groups y hardening inicial.

**Resultado:** ✅ **SPRINT COMPLETADO EXITOSAMENTE**  
Todas las tareas TA01-TA06 completadas y validadas.

**⚠️ Nota importante:** El sprint sufrió un imprevisto: el laboratorio AWS caducó durante la ejecución, lo que obligó a repetir toda la infraestructura desde cero. Gracias a la documentación previa, el retrabajo se completó en ~4 horas adicionales.

---

## 2. Checklist de Validación de Entregables

| ID | Entregable | Estado | Evidencia | Responsable |
|----|------------|--------|-----------|-------------|
| TA01 | VPC creada (10.0.0.0/16) | ✅ Completado | Captura consola AWS | Victor |
| TA01 | Subred pública (10.0.1.0/24) | ✅ Completado | Captura configuración | Victor |
| TA01 | Subred privada (10.0.2.0/24) | ✅ Completado | Captura configuración | Victor |
| TA02 | Internet Gateway creado y asociado | ✅ Completado | Captura IGW + asociación | Victor |
| TA02 | RT-Publica-NexOrder con ruta 0.0.0.0/0 → IGW | ✅ Completado | Captura tabla de rutas | Victor |
| TA02 | RT-Privada-NexOrder sin acceso a Internet | ✅ Completado | Captura tabla de rutas | Victor |
| TA03 | EC2 lanzada (Amazon Linux 2023, t3.micro) | ✅ Completado | Captura instancia + IP 3.86.92.89 | Trishan |
| TA03 | RDS MySQL disponible (db.t3.micro) | ✅ Completado | Captura estado "Available" | Trishan |
| TA03 | Conexión SSH a EC2 validada | ✅ Completado | Captura terminal SSH | Trishan |
| TA04 | SG-Web-NexOrder configurado | ✅ Completado | Captura reglas de entrada | Victor |
| TA04 | SG-DB-NexOrder con referencia a SG-Web | ✅ Completado | Captura reglas MySQL | Victor |
| TA05 | Paquetes de seguridad actualizados | ✅ Completado | Captura dnf update | Trishan |
| TA05 | Usuario nexadmin creado con sudo restringido | ✅ Completado | Captura configuración sudoers | Trishan |
| TA05 | Hardening SSH aplicado (root disabled, key-only) | ✅ Completado | Captura sshd_config | Trishan |
| TA05 | Servicio SSH reiniciado y validado | ✅ Completado | Captura systemctl status | Trishan |
| TA06 | Conexión EC2 → RDS MySQL validada | ✅ Completado | Captura mysql -h endpoint | Ambos |

**Total tareas:** 16  
**Completadas:** 16 ✅  
**Pendientes:** 0  
**Bloqueadas:** 0

---

## 3. Revisión de Criterios de Aceptación

### 3.1 Infraestructura de Red
- [x] VPC con CIDR 10.0.0.0/16 creada y operativa
- [x] Segregación pública/privada implementada correctamente
- [x] Internet Gateway asociado y funcional
- [x] Tablas de enrutamiento configuradas con asociaciones explícitas
- [x] Aislamiento de subred privada garantizado (sin ruta 0.0.0.0/0)

### 3.2 Instancias y Conectividad
- [x] EC2 accesible vía SSH desde IP autorizada (79.116.173.66)
- [x] RDS MySQL en estado "Available"
- [x] Endpoint RDS resoluble desde EC2
- [x] Conexión MySQL establecida exitosamente (connection id 39)

### 3.3 Seguridad
- [x] Security Groups con principio de mínimo privilegio
- [x] SSH restringido a IP específica (no 0.0.0.0/0)
- [x] MySQL solo accesible desde SG-Web-NexOrder (referencia por ID)
- [x] Root login deshabilitado en SSH
- [x] Autenticación solo por claves SSH (PasswordAuthentication no)
- [x] Usuario administrativo restringido (nexadmin) con permisos limitados

### 3.4 Documentación
- [x] Documentación técnica actualizada en `docs/infra_vpc.md`
- [x] Capturas de pantalla de todas las tareas (TA01-TA06)
- [x] Comandos de hardening documentados
- [x] Justificación de criterios M0370 y M0369 incluida

---

## 4. Evidencias Adjuntas

### TA01 - VPC y Subredes
1. ✅ Creación de VPC con CIDR 10.0.0.0/16
2. ✅ Configuración de subred pública 10.0.1.0/24
3. ✅ Configuración de subred privada 10.0.2.0/24
4. ✅ Lista de subredes creadas (Available)

### TA02 - Internet Gateway y Enrutamiento
5. ✅ Creación de Internet Gateway (IGW-NexOrder)
6. ✅ Asociación del IGW a la VPC
7. ✅ Tabla de enrutamiento pública con asociación de subred
8. ✅ Edición de rutas - agregando 0.0.0.0/0 → IGW
9. ✅ Tabla de enrutamiento privada - sin acceso a Internet

### TA03 - Instancias EC2 y RDS
10. ✅ Configuración de lanzamiento de EC2
11. ✅ Detalle de instancia EC2 creada (i-093d338216cd0568d)
12. ✅ Configuración de RDS MySQL
13. ✅ RDS en estado "Available"
14. ✅ Conexión SSH exitosa a EC2
15. ✅ Conexión MySQL desde EC2 a RDS exitosa

### TA04 - Security Groups
16. ✅ Creación de SG-Web-NexOrder con reglas de entrada
17. ✅ Creación de SG-DB-NexOrder con referencia a SG-Web

### TA05 - Hardening del Sistema
18. ✅ Ejecución de dnf update -y
19. ✅ Instalación de herramientas de seguridad (vim, wget, curl, git, fail2ban)
20. ✅ Verificación de versión de kernel actualizado (6.1.168)
21. ✅ Creación de usuario nexadmin y configuración SSH
22. ✅ Configuración de sudoers restringidos y validación
23. ✅ Aplicación de hardening SSH con sed
24. ✅ Verificación de configuración SSH hardening
25. ✅ Reinicio y verificación del servicio SSH
26. ✅ Conexión SSH exitosa con usuario nexadmin

### TA06 - Verificación de Conectividad
27. ✅ Validación final de conexión MySQL desde EC2 a RDS

---

## 5. Observaciones y Lecciones Aprendidas

### 5.1 Fortalezas
1. **Arquitectura bien diseñada:** Segregación clara entre capas web y de datos
2. **Seguridad aplicada:** Mínimo privilegio en Security Groups y SSH
3. **Documentación completa:** Todas las capturas y comandos registrados
4. **Conectividad validada:** Pruebas EC2-RDS exitosas
5. **Resiliencia del equipo:** Capacidad de recuperación ante imprevistos

### 5.2 Mejoras para Siguiente Sprint
1. **Automatización:** Considerar CloudFormation/Terraform para reproducibilidad
2. **Monitoreo:** Habilitar CloudWatch para métricas básicas (CPU, RAM, disco)
3. **Backups:** Configurar snapshots automáticos de RDS
4. **Rotación de claves:** Implementar rotación de claves SSH cada 90 días
5. **Fail2ban:** Configurar reglas específicas para SSH y MySQL

### 5.3 Incidentes de Seguridad Resueltos
- ✅ SSH restringido a IP específica (evita scans masivos)
- ✅ Root login deshabilitado (previene ataques de fuerza bruta a root)
- ✅ Base de datos aislada en subred privada (sin exposición a Internet)
- ✅ Contraseña RDS almacenada en gestor de contraseñas (no en código)

### 5.4 Retrabajo y Gestión de Imprevistos ⚠️

**Incidente:** Caducidad del laboratorio AWS durante la ejecución del Sprint 1.

**Impacto:**
- Pérdida total de recursos creados (VPC, EC2, RDS, SG)
- Tiempo adicional estimado: +4 horas de retrabajo

**Acciones Correctivas:**
1. ✅ Documentación previa permitió recrear infraestructura rápidamente
2. ✅ Scripts de hardening reutilizados sin modificaciones
3. ✅ Validación de conectividad EC2-RDS repetida exitosamente
4. ✅ Capturas de pantalla actualizadas con nuevos IDs de recursos

**Lecciones Aprendidas:**
- 📌 Verificar duración del laboratorio antes de iniciar tareas largas
- 📌 Exportar configuraciones críticas (Terraform/CloudFormation) como backup
- 📌 Mantener documentación en tiempo real para facilitar recuperación
- 📌 Coordinar con el instructor para extensión de laboratorio si es necesario

**Resultado final:** Retrabajo completado sin impacto en la calidad del entregable.

---

## 6. Acuerdos para Sprint 2

### Tareas Prioritarias
1. **Victor:** 
   - Configurar Apache/Nginx en EC2 (T07)
   - Implementar SSL/TLS con Let's Encrypt (T08)
   - Configurar CloudWatch Alerts (T11)

2. **Trishan:**
   - Implementar Fail2ban con reglas personalizadas (T09)
   - Configurar control de acceso MySQL (usuarios, permisos) (T10)
   - Implementar backup automatizado de RDS (T12)

3. **Ambos:**
   - Revisar criterios M0375 (Servicios de red), M0378 (Administración de servidores), C037 (Seguridad)
   - Documentar arquitectura de aplicación web
   - Actualizar ProfHub con entregables de S2

### Definición de Done - Sprint 2
- [ ] Servidor web funcional con HTTPS
- [ ] Fail2ban activo y configurado
- [ ] Base de datos con usuarios y permisos configurados
- [ ] Backups automatizados programados
- [ ] Métricas de monitoreo visibles en CloudWatch
- [ ] Documentación técnica actualizada

---

## 7. Actualización ProfHub

### Tareas Marcadas como Completadas
- [x] TA01: Desplegar arquitectura VPC y subredes
- [x] TA02: Configurar conectividad externa (IGW)
- [x] TA03: Provisionar instancias EC2 y RDS
- [x] TA04: Configurar Security Groups
- [x] TA05: Hardening inicial SO Linux
- [x] TA06: Verificar conectividad EC2-RDS

### Evidencias Subidas
- [x] Capturas de consola AWS (27 imágenes)
- [x] Documentación técnica: `docs/infra_vpc.md`
- [x] Acta de planning: `sprints/sprint1/sprint1_planning_acta.md`
- [x] Acta de review: `sprints/sprint1/sprint1_review_acta.md`

### Comentarios de Retroalimentación
**Victor:**  
"Infraestructura de red sólida y bien documentada. La segregación pública/privada funciona correctamente. El retrabajo por caducidad del laboratorio se gestionó eficientemente gracias a la documentación previa."

**Trishan:**  
"Hardening SSH aplicado correctamente. Conexión EC2-RDS validada sin problemas. La experiencia del retrabajo nos dejó mejores prácticas para futuros sprints."

---

## 8. Métricas del Sprint

| Métrica | Valor |
|---------|-------|
| **Velocidad planificada** | 14 horas |
| **Velocidad real (sin retrabajo)** | ~15 horas |
| **Retrabajo por incidente AWS** | +4 horas |
| **Velocidad real total** | ~19 horas |
| **Desviación** | +35% (justificada por incidente externo) |
| **Tareas completadas** | 6/6 (100%) |
| **Defectos encontrados** | 0 |
| **Retrabajo técnico** | 0% (solo recreación de infraestructura) |

---

**Próxima reunión:** Sprint Planning S2 - Semana del 20 - 26 de abril 2026