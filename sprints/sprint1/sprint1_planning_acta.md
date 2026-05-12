# Acta Sprint Planning - Sprint 1
**Proyecto:** NexOrder Infrastructure  
**Semana:** S1  
**Fecha:** 13 de abril 2026 - 19 de abril 2026  
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
   - [6.2 Avanços intermedis (14 d'abril)](#62-avanços-intermedis-14-dabril)
   - [6.3 Finalització del Sprint](#63-finalització-del-sprint)

---

## 1. Objetivo del Sprint
Desplegar infraestructura cloud básica en AWS: VPC con subredes pública/privada, instancias EC2 y RDS, Security Groups con política de mínimo privilegio, y hardening inicial del sistema operativo Linux.

---

## 2. Alcance del Sprint (Scope)

### 2.1 Tareas Planificadas

| ID | Tarea | Descripción | Responsable | Esfuerzo (h) | Dependencias |
|----|-------|-------------|-------------|--------------|--------------|
| TA01 | Desplegar arquitectura VPC y subredes | Crear VPC (10.0.0.0/16), subred pública (10.0.1.0/24) y privada (10.0.2.0/24) | Victor | 3h | - |
| TA02 | Configurar conectividad externa (IGW) | Crear Internet Gateway y tablas de enrutamiento pública/privada | Victor | 2h | TA01 |
| TA03 | Provisionar instancias EC2 y RDS | Lanzar EC2 en subred pública y RDS MySQL en subred privada | Trishan | 3h | TA01, TA02 |
| TA04 | Configurar Security Groups | Crear SG-Web-NexOrder y SG-DB-NexOrder con reglas de mínimo privilegio | Victor | 2h | TA03 |
| TA05 | Hardening inicial SO Linux | Deshabilitar root SSH, crear usuario restringido, actualizar paquetes | Trishan | 3h | TA03 |
| TA06 | Verificar conectividad EC2-RDS | Validar conexión desde EC2 a RDS MySQL | Ambos | 1h | TA03, TA04, TA05 |

**Total esfuerzo estimado:** 14 horas

---

## 3. Dependencias Críticas
1. **TA02** requiere que **TA01** esté completada (la VPC debe existir antes de crear y asociar el IGW)
2. **TA03** requiere **TA01** y **TA02** (las subredes y rutas deben estar configuradas antes de lanzar instancias)
3. **TA04** requiere **TA03** (las instancias deben estar creadas para asociar y probar los Security Groups)
4. **TA05** requiere **TA03** (la EC2 debe estar activa y accesible vía SSH para aplicar hardening)
5. **TA06** requiere todas las tareas anteriores (solo se puede validar la conectividad una vez finalizada la infraestructura y seguridad)

---

## 4. Agenda de la Reunión Planning

1. **Revisión de objetivos del Sprint** (10 min)
   - Presentar alcance, entregables esperados y alineación con criterios M0370 y M0369
   
2. **Análisis de tareas y asignación** (20 min)
   - Revisar cada tarea (TA01-TA06)
   - Confirmar responsables, estimaciones de esfuerzo y recursos necesarios
   
3. **Identificación de dependencias y riesgos** (15 min)
   - Mapear dependencias críticas entre tareas
   - Discutir posibles bloqueos (ej. caducidad de laboratorio AWS, límites de servicio)
   
4. **Acuerdos y definición de Done** (10 min)
   - Establecer criterios de aceptación
   - Definir formato y ubicación de evidencias

---

## 5. Acuerdos del Sprint

### 5.1 Criterios Técnicos
- **VPC:** CIDR `10.0.0.0/16` con segregación lógica pública/privada
- **Subredes:** 
  - Pública: `10.0.1.0/24` (us-east-1a) → Servidor Web
  - Privada: `10.0.2.0/24` (us-east-1a) → Base de Datos
- **EC2:** Amazon Linux 2023, `t3.micro`, subred pública, key pair `NexOrder-SSH-Key.pem`
- **RDS:** MySQL Community 8.0, `db.t3.micro`, subred privada, endpoint DNS interno
- **Security Groups:** 
  - SSH solo desde IP administrativa (`79.116.173.66/32`)
  - HTTP/HTTPS abierto (`0.0.0.0/0`)
  - MySQL solo accesible mediante referencia a `SG-Web-NexOrder` (no IPs fijas)
- **Hardening:** 
  - `PermitRootLogin no`
  - `PasswordAuthentication no` / `PubkeyAuthentication yes`
  - Usuario `nexadmin` con permisos sudo restringidos vía `/etc/sudoers.d/nexadmin`

### 5.2 Evidencias Requeridas
- Capturas de consola AWS de cada paso de configuración (TA01-TA06)
- Documentación técnica centralizada en `docs/infra_vpc.md`
- Registro de comandos de hardening y verificación (`sed`, `visudo -c`, `sshd -t`)
- Captura de terminal validando conexión `mysql -h <endpoint> -u admin -p` desde EC2

### 5.3 Definición de Done
- [ ] Todas las tareas TA01-TA06 completadas y probadas
- [ ] Evidencias documentadas con capturas y comandos ejecutados
- [ ] Conectividad EC2 → RDS validada exitosamente
- [ ] Hardening SSH aplicado, verificado y servicio reiniciado sin errores
- [ ] Documentación técnica y actas actualizadas en el repositorio

---

## 6. Seguiment Visual a ProofHub

### 6.1 Estat inicial de la planificació (ProofHub)
A continuació es mostra el tauler de gestió amb totes les tasques creades i assignades abans de l'inici de les execucions:

![ProofHub - Tasques inicials](/img/sprint1/proofhub/proofhub-inicial-1.png)
![ProofHub - Tasques inicials](/img/sprint1/proofhub/proofhub-inicial-2.png)
![ProofHub - Tasques inicials](/img/sprint1/proofhub/proofhub-inicial-3.png)
![ProofHub - Tasques inicials](/img/sprint1/proofhub/proofhub-inicial-4.png)

> 📸 **Figura 6.1:** Estat inicial del tauler ProofHub amb tasques TA00-TA06 en estat "Per fer" o "En curs"

---

### 6.2 Avanços intermedis (14 d'abril)
Estat del projecte a mitjan sprint, amb les tasques de configuració de xarxa i provisionament en procés de validació.

![ProofHub - Tasques finalitzades Setmana 1](/img/sprint1/proofhub/proofhub-14abril-1.png)
![ProofHub - Tasques finalitzades Setmana 1](/img/sprint1/proofhub/proofhub-14abril-2.png)
![ProofHub - Tasques finalitzades Setmana 1](/img/sprint1/proofhub/proofhub-14abril-3.png)

> 📸 **Figura 6.2:** Avanç a 14 d'abril. TA01 i TA02 completades, TA03 en execució.

---

### 6.3 Finalització del Sprint
Tauler completat amb totes les tasques TA01-TA06 marcades com a completades i evidències adjuntes.

![ProofHub - Tasques finalitzades](/img/sprint1/proofhub/proofhub-final-1.png)
![ProofHub - Tasques finalitzades](/img/sprint1/proofhub/proofhub-final-2.png)
![ProofHub - Tasques finalitzades](/img/sprint1/proofhub/proofhub-final-3.png)

> 📸 **Figura 6.3:** Sprint 1 tancat. Totes les tasques a "Completat" amb entregables validats.

---