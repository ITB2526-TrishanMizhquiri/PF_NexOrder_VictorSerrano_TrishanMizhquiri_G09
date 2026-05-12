# Acta Sprint Planning - Sprint 2
**Proyecto:** NexOrder Infrastructure  
**Semana:** S2  
**Fecha:** 20 de abril 2026 - 26 de abril 2026  
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
   - [6.2 Avanços intermedis (21 d'abril)](#62-avanços-intermedis-21-dabril)
   - [6.3 Finalització del Sprint](#63-finalització-del-sprint)

---

## 1. Objetivo del Sprint
Desplegar servicios de red y seguridad sobre la infraestructura existente: instalar servidor web (Apache/PHP), implementar SSL/TLS y forzar HTTPS, proteger SSH con Fail2ban, configurar control de acceso a MySQL (mínimo privilegio), aplicar hardening al servidor web y desplegar capa de validación web (PHP+PDO).

---

## 2. Alcance del Sprint (Scope)

### 2.1 Tareas Planificadas

| ID | Tarea | Descripción | Responsable | Esfuerzo (h) | Dependencias |
|----|-------|-------------|-------------|--------------|--------------|
| T07 | Instalar y configurar servidor web | Instalar `httpd` y `php`, habilitar servicio, verificar puerto 80 y respuesta local | Victor | 2h | EC2 (S1) |
| T08 | Implementar SSL/TLS y forzar HTTPS | Generar certificado autofirmado, configurar VirtualHost 443, redirect 301 HTTP→HTTPS, HSTS | Victor | 3h | T07 |
| T09 | Desplegar Fail2ban y protección SSH | Instalar/configurar `fail2ban`, regla `sshd` (3 intentos, 1h bloqueo), verificar `jail` status | Trishan | 2h | EC2 (S1) |
| T10 | Configurar control acceso MySQL | Crear BD `nexorder_db`, usuario `nexorder_app` con permisos SELECT/INSERT/UPDATE, eliminar test | Trishan | 2h | RDS (S1) |
| T11 | Hardening servidor web | Configurar `ServerTokens Prod`, `ServerSignature Off` en Apache, validar ocultación de versión | Victor | 1.5h | T08 |
| T12 | Desplegar capa web mínima validación | Crear `index.php`, `connexio.php`, `panel.php` para probar conectividad PDO y estado del servidor | Ambos | 3.5h | T08, T10 |

**Total esfuerzo estimado:** 14 horas

---

## 3. Dependencias Críticas
1. **T07** requiere que la **EC2 del S1** esté operativa y accesible vía SSH.
2. **T08** requiere que **T07** esté completada (Apache debe estar instalado y corriendo para configurar SSL).
3. **T11** requiere que **T08** esté completada (hardening aplicado sobre configuración Apache final).
4. **T10** requiere que la **RDS del S1** esté disponible y accesible desde la EC2.
5. **T12** requiere que **T08** (HTTPS activo) y **T10** (usuario DB creado) estén finalizados para validar la conexión segura PDO.
6. **T09** es paralela a las de red pero debe probarse antes de cerrar el hardening final.

---

## 4. Agenda de la Reunión Planning

1. **Revisión de objetivos del Sprint** (10 min)
   - Presentar alcance, entregables esperados y alineación con criterios M0375 y M0378.
   
2. **Análisis de tareas y asignación** (20 min)
   - Revisar cada tarea (T07-T12)
   - Confirmar responsables, estimaciones de esfuerzo y recursos necesarios
   
3. **Identificación de dependencias y riesgos** (15 min)
   - Mapear dependencias críticas entre servicios web y base de datos
   - Discutir posibles bloqueos (ej. resolución de módulos Apache `mod_ssl`, `mod_headers`, permisos MySQL)
   
4. **Acuerdos y definición de Done** (10 min)
   - Establecer criterios de aceptación para SSL, Fail2ban y control de acceso DB
   - Definir formato y ubicación de evidencias

---

## 5. Acuerdos del Sprint

### 5.1 Criterios Técnicos
- **Servidor Web:** Apache 2.4 (`httpd`) + PHP 8.x habilitados y activos en arranque
- **SSL/TLS:** Certificado autofirmado válido 365 días (`nexorder.crt`, `nexorder.key`)
- **Redirección y Seguridad:** HTTP→HTTPS forzado (301), cabecera `Strict-Transport-Security` activa
- **Fail2ban:** Regla `sshd` con `maxretry=3`, `bantime=1h`, servicio activo y monitoreando logs
- **MySQL Acceso:** Usuario `nexorder_app` con permisos **SELECT, INSERT, UPDATE** (sin DELETE/DROP/CREATE)
- **Hardening Apache:** `ServerTokens Prod`, `ServerSignature Off` (versión oculta en cabeceras y errores)
- **Capa Web:** Archivos `index.php`, `connexio.php`, `panel.php` funcionando y validando conexión PDO segura

### 5.2 Evidencias Requeridas
- Capturas de terminal instalando `httpd`, `php`, `mod_ssl`, `fail2ban`
- Comandos de generación de certificado y configuración de VirtualHost
- Pruebas de `curl -I http://localhost` (301) y `curl -Ik https://localhost` (200 + HSTS)
- Estado de Fail2ban (`fail2ban-client status sshd`)
- Salida de `SHOW GRANTS FOR 'nexorder_app'@'%';` y prueba de fallo al crear tablas
- Captura de cabeceras HTTP ocultando versión de Apache
- Capturas de navegador/web validando los 3 archivos PHP funcionando

### 5.3 Definición de Done
- [ ] Servidor web activo respondiendo en puerto 80 y 443
- [ ] Redirección HTTP→HTTPS funcional con cabecera HSTS
- [ ] Fail2ban bloqueando IPs tras 3 intentos fallidos SSH
- [ ] Usuario `nexorder_app` creado con permisos limitados y verificados
- [ ] Apache configurado con `ServerTokens Prod` y `ServerSignature Off`
- [ ] Capa PHP validada: conexión PDO exitosa, `panel.php` muestra info segura
- [ ] Documentación técnica y actas actualizadas en el repositorio

---

## 6. Seguiment Visual a ProofHub

### 6.1 Estat inicial de la planificació (ProofHub)
A continuació es mostra el tauler de gestió amb totes les tasques T07-T12 creades i assignades abans de l'inici de les execucions:

![ProofHub - Tasques inicials S2](/img/sprint2/proofhub/proofhub-inicial-1.png)
![ProofHub - Tasques inicials S2](/img/sprint2/proofhub/proofhub-inicial-2.png)
![ProofHub - Tasques inicials S2](/img/sprint2/proofhub/proofhub-inicial-3.png)

> 📸 **Figura 6.1:** Estat inicial del tauler ProofHub amb tasques T07-T12 en estat "Per fer".

---

### 6.2 Avanços intermedis (21 d'abril)
Estat del projecte a mitjan sprint, amb la configuració del servidor web, SSL i Fail2ban en procés de validació.

![ProofHub - Tasques en curs S2](/img/sprint2/proofhub/proofhub-21abril-1.png)
![ProofHub - Tasques en curs S2](/img/sprint2/proofhub/proofhub-21abril-2.png)
![ProofHub - Tasques en curs S2](/img/sprint2/proofhub/proofhub-21abril-3.png)

> 📸 **Figura 6.2:** Avanç a 22 d'abril. T07, T08 i T09 completades, T10 i T11 en execució.

---

### 6.3 Finalització del Sprint
Tauler completat amb totes les tasques T07-T12 marcades com a completades i evidències de validació web i DB adjuntes.

![ProofHub - Tasques finalitzades S2](/img/sprint2/proofhub/proofhub-final-1.png)
![ProofHub - Tasques finalitzades S2](/img/sprint2/proofhub/proofhub-final-2.png)
![ProofHub - Tasques finalitzades S2](/img/sprint2/proofhub/proofhub-final-3.png)

> 📸 **Figura 6.3:** Sprint 2 tancat. Totes les tasques a "Completat" amb servidor web segur i validat.

---