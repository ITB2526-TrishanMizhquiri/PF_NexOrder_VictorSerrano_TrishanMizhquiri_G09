# Acta Sprint Review - Sprint 2
**Proyecto:** NexOrder Infrastructure  
**Semana:** S2  
**Fecha:** 20 de abril 2026 - 26 de abril 2026  
**Responsables:** Victor Serrano, Trishan Mizhquiri  
**Prioridad:** Alta

---

## 📋 Índice
1. [Resumen del Sprint](#1-resumen-del-sprint)
2. [Checklist de Validación de Entregables](#2-checklist-de-validación-de-entregables)
3. [Revisión de Criterios de Aceptación](#3-revisión-de-criterios-de-aceptación)
   - [3.1 Servicios de Red](#31-servicios-de-red)
   - [3.2 Seguridad Aplicada](#32-seguridad-aplicada)
   - [3.3 Base de Datos](#33-base-de-datos)
   - [3.4 Documentación](#34-documentación)
4. [Evidencias Adjuntas](#4-evidencias-adjuntas)
5. [Observaciones y Lecciones Aprendidas](#5-observaciones-y-lecciones-aprendidas)
   - [5.1 Fortalezas](#51-fortalezas)
   - [5.2 Mejoras para Siguiente Sprint](#52-mejoras-para-siguiente-sprint)
   - [5.3 Incidentes de Seguridad Resueltos](#53-incidentes-de-seguridad-resueltos)
   - [5.4 Retrabajo y Gestión de Imprevistos](#54-retrabajo-y-gestión-de-imprevistos)
6. [Acuerdos para Sprint 3](#6-acuerdos-para-sprint-3)
7. [Actualización ProfHub](#7-actualización-profhub)
8. [Métricas del Sprint](#8-métricas-del-sprint)

---

## 1. Resumen del Sprint

**Objetivo:** Desplegar servicios de red y seguridad sobre la infraestructura existente: instalar servidor web (Apache/PHP), implementar SSL/TLS y forzar HTTPS, proteger SSH con Fail2ban, configurar control de acceso a MySQL (mínimo privilegio), aplicar hardening al servidor web y desplegar capa de validación web (PHP+PDO).

**Resultado:** ✅ **SPRINT COMPLETADO EXITOSAMENTE**  
Todas las tareas T07-T12 completadas y validadas.

**⚠️ Nota importante:** Se encontró un error con el puerto 443 durante la configuración SSL, solucionado añadiendo `mod_headers` y habilitando `Listen 443` en la configuración de Apache.

---

## 2. Checklist de Validación de Entregables

| ID | Entregable | Estado | Evidencia | Responsable |
|----|------------|--------|-----------|-------------|
| T07 | httpd y PHP instalados | ✅ Completado | Captura dnf install | Victor |
| T07 | Servicio httpd activo (running) | ✅ Completado | Captura systemctl status | Victor |
| T07 | Puerto 80 escuchando | ✅ Completado | Captura ss -tlnp | Victor |
| T07 | curl localhost responde correctamente | ✅ Completado | Captura terminal | Victor |
| T08 | mod_ssl instalado | ✅ Completado | Captura instalación | Victor |
| T08 | Certificado autofirmado generado | ✅ Completado | Captura openssl | Victor |
| T08 | VirtualHost HTTPS configurado (443) | ✅ Completado | Captura nexorder-ssl.conf | Victor |
| T08 | Redirección HTTP→HTTPS (301) | ✅ Completado | Captura curl -I http://localhost | Victor |
| T08 | Cabecera HSTS activa | ✅ Completado | Captura curl -Ik https://localhost | Victor |
| T09 | Fail2ban instalado | ✅ Completado | Captura dnf install | Trishan |
| T09 | Servicio fail2ban activo | ✅ Completado | Captura systemctl status | Trishan |
| T09 | jail.local configurado (maxretry=3, bantime=1h) | ✅ Completado | Captura archivo config | Trishan |
| T09 | fail2ban-client status sshd validado | ✅ Completado | Captura terminal | Trishan |
| T10 | Base de datos nexorder_db creada | ✅ Completado | Captura MySQL | Trishan |
| T10 | Usuario nexorder_app creado | ✅ Completado | Captura CREATE USER | Trishan |
| T10 | Permisos limitados (SELECT, INSERT, UPDATE) | ✅ Completado | Captura SHOW GRANTS | Trishan |
| T10 | Prueba CREATE TABLE fallida (seguridad) | ✅ Completado | Captura ERROR 1142 | Trishan |
| T11 | ServerTokens Prod configurado | ✅ Completado | Captura httpd.conf | Victor |
| T11 | ServerSignature Off configurado | ✅ Completado | Captura httpd.conf | Victor |
| T11 | curl -I localhost muestra solo Apache | ✅ Completado | Captura cabeceras | Victor |
| T12 | index.php creado y funcional | ✅ Completado | Captura navegador/curl | Ambos |
| T12 | connexio.php validado (PDO exitoso) | ✅ Completado | Captura conexión RDS | Ambos |
| T12 | panel.php muestra info segura | ✅ Completado | Captura consulta MySQL | Ambos |

**Total tareas:** 23  
**Completadas:** 23 ✅  
**Pendientes:** 0  
**Bloqueadas:** 0

---

## 3. Revisión de Criterios de Aceptación

### 3.1 Servicios de Red
- [x] Apache 2.4 instalado y activo en puerto 80 y 443
- [x] PHP 8.x habilitado y funcionando
- [x] Redirección HTTP→HTTPS forzada (301)
- [x] Cabecera Strict-Transport-Security presente
- [x] Certificado SSL válido (365 días)

### 3.2 Seguridad Aplicada
- [x] Fail2ban activo y monitoreando SSH
- [x] Regla sshd configurada (3 intentos, 1h bloqueo)
- [x] ServerTokens Prod (versión oculta)
- [x] ServerSignature Off (sin footer en errores)
- [x] SSH protegido contra fuerza bruta

### 3.3 Base de Datos
- [x] Usuario nexorder_app creado con plugin mysql_native_password
- [x] Permisos restringidos: SELECT, INSERT, UPDATE (sin DELETE/DROP/CREATE)
- [x] Base de datos test eliminada
- [x] Principio de mínimo privilegio validado (CREATE TABLE falla)
- [x] Conexión PDO desde PHP funcional

### 3.4 Documentación
- [x] Documentación técnica actualizada en `docs/infra_webserver.md`
- [x] Capturas de pantalla de todas las tareas (T07-T12)
- [x] Comandos de configuración documentados
- [x] Justificación de criterios M0375, M0378 y C037 incluida

---

## 4. Evidencias Adjuntas

### T07 - Instalar y configurar servidor web
1. ✅ Instalación de httpd y PHP (dnf install)
2. ✅ Habilitación de servicio httpd (systemctl enable)
3. ✅ Verificación de estado active (running)
4. ✅ Puerto 80 escuchando (ss -tlnp)
5. ✅ curl localhost responde correctamente

### T08 - Implementar SSL/TLS y forzar HTTPS
6. ✅ Instalación de mod_ssl y openssl
7. ✅ Generación de certificado autofirmado (openssl req)
8. ✅ Configuración de VirtualHost HTTPS (nexorder-ssl.conf)
9. ✅ Redirección HTTP→HTTPS (curl -I http://localhost → 301)
10. ✅ Cabecera HSTS verificada (curl -Ik https://localhost)
11. ✅ Resolución error puerto 443 (mod_headers + Listen 443)
12. ✅ Puertos 80 y 443 activos (ss -tlnp | grep httpd)

### T09 - Desplegar Fail2ban y protección SSH
13. ✅ Instalación de fail2ban (dnf install)
14. ✅ Habilitación y arranque del servicio
15. ✅ Configuración de jail.local (maxretry=3, bantime=1h)
16. ✅ fail2ban-client status sshd (monitoreo activo)
17. ✅ Currently banned: 0 (sin ataques detectados)

### T10 - Configurar control acceso MySQL
18. ✅ Conexión a RDS como admin
19. ✅ Creación de BD nexorder_db (CREATE DATABASE)
20. ✅ Creación de usuario nexorder_app (CREATE USER)
21. ✅ Asignación de permisos limitados (GRANT SELECT, INSERT, UPDATE)
22. ✅ Eliminación de BD test (DROP DATABASE)
23. ✅ SHOW GRANTS FOR 'nexorder_app'@'%' (verificación)
24. ✅ Prueba CREATE TABLE fallida (ERROR 1142 - seguridad validada)

### T11 - Hardening servidor web
25. ✅ Edición de /etc/httpd/conf/httpd.conf
26. ✅ ServerTokens Prod añadido
27. ✅ ServerSignature Off añadido
28. ✅ curl -I localhost muestra solo "Server: Apache" (sin versión)

### T12 - Desplegar capa web mínima validación
29. ✅ Creación de index.php (menú principal)
30. ✅ Creación de connexio.php (conexión PDO a RDS)
31. ✅ Creación de panel.php (consulta segura + info sistema)
32. ✅ curl -k https://localhost/ responde (index.php)
33. ✅ curl -k https://localhost/connexio.php → ✅ Conexión exitosa
34. ✅ curl -k https://localhost/panel.php → Info MySQL visible

---

## 5. Observaciones y Lecciones Aprendidas

### 5.1 Fortalezas
1. **Servidor web seguro:** HTTPS forzado + HSTS + ocultación de versión
2. **Protección SSH robusta:** Fail2ban bloquea IPs tras 3 intentos
3. **Base de datos protegida:** Usuario app con permisos mínimos (sin DROP/DELETE)
4. **Validación funcional:** Capa PHP conectando exitosamente con RDS
5. **Resolución de incidencias:** Error puerto 443 solucionado rápidamente

### 5.2 Mejoras para Siguiente Sprint
1. **Certificados reales:** Migrar de autofirmado a Let's Encrypt
2. **Monitoreo proactivo:** Configurar CloudWatch Alerts para CPU, RAM, disco
3. **Backups automatizados:** Implementar snapshots RDS programados
4. **WAF:** Considerar AWS WAF para protección capa aplicación
5. **Logs centralizados:** Implementar CloudWatch Logs para Apache

### 5.3 Incidentes de Seguridad Resueltos
- ✅ Puerto 443 no escuchando → Solucionado con mod_headers + Listen 443
- ✅ Versión Apache visible → Ocultada con ServerTokens Prod
- ✅ Usuario DB con permisos excesivos → Limitado a SELECT/INSERT/UPDATE
- ✅ SSH expuesto a fuerza bruta → Fail2ban activo con bantime=1h

### 5.4 Retrabajo y Gestión de Imprevistos ⚠️

**Incidente:** Error con el puerto 443 durante configuración SSL/TLS.

**Impacto:**
- Apache no escuchaba en puerto 443
- HTTPS no funcional inicialmente
- Tiempo adicional estimado: +1.5 horas

**Acciones Correctivas:**
1. ✅ Añadido `LoadModule headers_module modules/mod_headers.so`
2. ✅ Añadido `LoadModule rewrite_module modules/mod_rewrite.so`
3. ✅ Verificado `Listen 443` en configuración SSL
4. ✅ Ejecutado `httpd -M | grep ssl_module` para confirmar mod_ssl
5. ✅ Reiniciado Apache y verificado puertos (ss -tlnp)

**Lecciones Aprendidas:**
- 📌 Verificar módulos Apache cargados antes de configurar VirtualHost
- 📌 Siempre añadir `Listen 443` explícitamente
- 📌 Probar `httpd -t` antes de reiniciar servicio
- 📌 Documentar dependencias de módulos (mod_ssl, mod_headers, mod_rewrite)

**Resultado final:** HTTPS funcional con redirección 301 y cabecera HSTS activa.

---

## 6. Acuerdos para Sprint 3

### Tareas Prioritarias
1. **Victor:** 
   - Configurar CloudWatch Metrics y Alarms (T13)
   - Implementar snapshots automáticos RDS (T14)
   - Configurar rotación de claves SSH (T15)

2. **Trishan:**
   - Crear script de backup/restore MySQL (T16)
   - Implementar monitoreo de logs Apache (T17)
   - Configurar alertas por email (SNS) (T18)

3. **Ambos:**
   - Revisar criterios C037 (Seguridad y Resiliencia)
   - Documentar procedimientos de recuperación ante desastres (DR)
   - Actualizar ProfHub con entregables de S3

### Definición de Done - Sprint 3
- [ ] CloudWatch Alerts configurados (CPU >80%, disco >90%)
- [ ] Snapshots RDS automáticos diarios
- [ ] Procedimiento de rotación SSH documentado y probado
- [ ] Script backup/restore funcional y validado
- [ ] Logs Apache monitorizados en CloudWatch
- [ ] Documentación técnica actualizada

---

## 7. Actualización ProfHub

### Tareas Marcadas como Completadas
- [x] T07: Instalar y configurar servidor web
- [x] T08: Implementar SSL/TLS y forzar HTTPS
- [x] T09: Desplegar Fail2ban y protección SSH
- [x] T10: Configurar control acceso MySQL
- [x] T11: Hardening servidor web
- [x] T12: Desplegar capa web mínima validación

### Evidencias Subidas
- [x] Capturas de consola AWS y terminal (34 imágenes)
- [x] Documentación técnica: `docs/infra_webserver.md`
- [x] Acta de planning: `/sprints/sprint2/sprint2_planning_acta.md`
- [x] Acta de review: `/sprints/sprint2/sprint2_review_acta.md`
- [x] Archivos PHP: index.php, connexio.php, panel.php

### Comentarios de Retroalimentación
**Victor:**  
"Servidor web configurado correctamente con HTTPS forzado y hardening aplicado. La resolución del error 443 fue rápida gracias a la documentación de módulos Apache. Fail2ban añade una capa de seguridad importante."

**Trishan:**  
"Control de acceso MySQL implementado con éxito. El usuario nexorder_app tiene permisos limitados validados (CREATE TABLE falla como esperado). Conexión PDO desde PHP funcionando perfectamente."

---

## 8. Métricas del Sprint

| Métrica | Valor |
|---------|-------|
| **Velocidad planificada** | 14 horas |
| **Velocidad real (sin retrabajo)** | ~14 horas |
| **Retrabajo por error 443** | +1.5 horas |
| **Velocidad real total** | ~15.5 horas |
| **Desviación** | +10.7% (dentro del margen aceptable) |
| **Tareas completadas** | 6/6 (100%) |
| **Subtareas completadas** | 23/23 (100%) |
| **Defectos encontrados** | 1 (resuelto) |
| **Retrabajo técnico** | 6.5% (configuración SSL) |

---

**Próxima reunión:** Sprint Planning S3 - Semana del 27 de abril - 3 de mayo 2026