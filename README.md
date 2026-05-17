#  NexOrder: Sistema Digital para Restaurantes en AWS

> **Estado del Proyecto:**  Operativo en AWS (us-east-1)  
> **Autores:** Victor Serrano & Trishan Mizhquiri | Grupo 09  
> **Ciclo:** ASIX - Administración de Sistemas Informáticos en Red

---

##  Índice
- [ Sobre el Proyecto](#-sobre-el-proyecto)
- [ Arquitectura en la Nube](-arquitectura-en-la-nube)
- [ Sprint Timeline](#-sprint-timeline)
- [ Estructura del Repositorio](#-estructura-del-repositorio)
- [ Documentación Técnica](#-documentación-técnica)
- [ Manual Técnico Completo](#-manual-técnico-completo)
- [ Equipo](#-equipo)
- [ Conclusión](#-conclusión)

---

##  Sobre el Proyecto

**NexOrder** es una plataforma web completa diseñada para reemplazar los procesos manuales de toma de pedidos en restaurantes. Permite a los clientes consultar menús digitales y realizar pedidos, mientras que la cocina visualiza las comandas en un panel de control en tiempo real.

###  Beneficios Clave
| Beneficio | Descripción |
|:---|:---|
|  **Reducción de errores** | Eliminación de comandas perdidas o mal interpretadas. |
|  **Accesibilidad** | Interfaz responsive (Móvil, Tablet, Desktop). |
|  **Control en tiempo real** | Gestión dinámica de estados (Pendiente → Preparación → Listo). |
|  **Sostenibilidad** | Drástica reducción del consumo de papel. |

---

##  Arquitectura en la Nube

El sistema se despliega en **Amazon Web Services (AWS)** siguiendo las mejores prácticas de seguridad y escalabilidad.

### Diagrama de Infraestructura
```text
                  INTERNET
                      |
                [HTTPS / 443]
                      |
          +-----------v------------+
          |   VPC (10.0.0.0/16)    |
          |                        |
          |  +------------------+  |
          |  |  SUBNET PÚBLICA  |  |
          |  |  (10.0.1.0/24)   |  |
          |  |                  |  |
          |  |    EC2 (Web)   |  |  <--- Amazon Linux 2023
          |  |   Apache + PHP   |  |       PHP 8.5, Fail2ban
          |  +--------+---------+  |
          |           |            |
          |      (Tráfico)         |
          |           |            |
          |  +--------v---------+  |
          |  |  SUBNET PRIVADA  |  |
          |  |  (10.0.2.0/24)   |  |
          |  |                  |  |
          |  |    RDS MySQL   |  |  <--- MySQL 8.0
          |  |   nexorder-db    |  |       Aislada, cifrada
          |  +------------------+  |
          +------------------------+
```

###  Stack Tecnológico
- **Infraestructura:** AWS VPC, EC2 (t3.micro), RDS (db.t3.micro), S3 (Backups).
- **Sistema Operativo:** Amazon Linux 2023 (Hardened).
- **Backend:** PHP 8.5 con Apache 2.4.
- **Base de Datos:** MySQL 8.0 (Gestión relacional y normalización).
- **Seguridad:** SSL/TLS (Autofirmado/Let's Encrypt), Fail2ban, Security Groups restrictivos, IAM Roles.

---

##  Sprint Timeline

El desarrollo se ha organizado en Sprints ágiles semanales:

###  Sprint 1: Infraestructura Base (13-19 Abril)
 Creación de VPC, Subredes (Pública/Privada) y Route Tables.  
 Despliegue de EC2 y RDS MySQL.  
 Configuración de Security Groups (Mínimo privilegio).  
 Hardening inicial del SO y SSH.  
 *Ver documentación: [Infraestructura VPC](docs/infra_vpc.md)*

###  Sprint 2: Servicios Web y Seguridad (20-26 Abril)
 Instalación de Stack LAMP (Apache + PHP).  
 Implementación de SSL/TLS y redirección HTTPS.  
 Configuración de Fail2ban (Protección fuerza bruta).  
 Hardening de MySQL (Usuario app con permisos limitados).  
 *Ver documentación: [Servicios Web](docs/infra_webserver.md)*

###  Sprint 3: Monitorización y Resiliencia (27 Abril - 03 Mayo)
 Automatización de Backups (Scripts Bash + Cron).  
 Configuración de CloudWatch (Alarmas CPU, Dashboard EBS).  
 Pruebas de Restauración (RTO: 24 min 01s).  
 Auditoría externa con Nmap.  
*Ver documentación: [Monitorización](docs/infra_monitoring.md)*

###  Sprint 4: Cierre y Auditoría Final (04-12 Mayo)
 Migración a certificados SSL reales (Let's Encrypt).  
 Replicación de backups a S3.  
 Auditoría final de Compliance y entrega del proyecto.

---

##  Estructura del Repositorio

```bash
.
├── 📂 docs/                  # Documentación técnica
│   ├── 📂 src/               # Scripts y configuraciones clave
│   │   ├── backup_nexorder.sh
│   │   ├── deploy_nexorder.sh
│   │   └── nexorder-ssl.conf
│   ├── infra_vpc.md          # Doc Sprint 1
│   ├── infra_webserver.md    # Doc Sprint 2
│   ├── infra_monitoring.md   # Doc Sprint 3
│   └── docs_tecnic.md        # Manual Técnico Completo
├──  img/                   # Evidencias gráficas (Capturas AWS/Terminal)
├── 📂 sprints/               # Actas de Planning y Review
│   ├── sprint1/
│   ├── sprint2/
│   └── sprint3/
└── README.md                 # Este archivo
```

---

##  Documentación Técnica

Acceso directo a la documentación detallada por fases:

| Fase | Documento | Enlace |
|:---|:---|:---|
|  **Infraestructura** | Configuración de Red, VPC y EC2 | [`docs/infra_vpc.md`](docs/infra_vpc.md) |
|  **Web Server** | Apache, SSL/TLS y Hardening | [`docs/infra_webserver.md`](docs/infra_webserver.md) |
|  **Monitorización** | Backups, CloudWatch y Despliegue | [`docs/infra_monitoring.md`](docs/infra_monitoring.md) |
|  **Manual Cliente** | Guía de uso para usuarios finales | [`docs/docs_client.md`](docs/docs_client.md) |

---

##  Manual Técnico Completo

Documentación técnica unificada que consolida toda la arquitectura, configuración y procedimientos operativos del proyecto NexOrder.

###  Contenido del Manual Técnico

El manual técnico completo incluye:

#### **Parte I: Infraestructura Cloud (Sprint 1)**
- Arquitectura de red VPC con segregación pública/privada
- Configuración de subredes, Internet Gateway y route tables
- Despliegue de instancias EC2 y RDS MySQL
- Security Groups con principio de mínimo privilegio
- Hardening del sistema operativo (SSH, usuarios, permisos)

#### **Parte II: Servicios Web y Seguridad (Sprint 2)**
- Instalación y configuración de Apache 2.4 + PHP 8.5
- Implementación de SSL/TLS con certificados autofirmados
- Redirección HTTP→HTTPS y cabeceras HSTS
- Fail2ban para protección contra fuerza bruta SSH
- Control de acceso MySQL con usuario restringido (nexorder_app)
- Hardening del servidor web (ServerTokens, ServerSignature)
- Capa de validación web con PHP+PDO

#### **Parte III: Monitorización y Resiliencia (Sprint 3)**
- Script de backup automatizado con mysqldump + gzip
- Programación de tareas con cron (backup diario 03:00 AM)
- Rotación de logs con logrotate (Apache y MySQL)
- CloudWatch: alarmas CPU (>80%) y dashboard personalizado
- Script de despliegue continuo con rsync
- Prueba de restauración y cálculo de RTO (24 min 01s)
- Auditoría de seguridad con nmap

#### **Anexos**
- Justificación de criterios ASIXc (M0370, M0369, M0375, M0378, M0374, M0377, C037)
- Scripts completos: backup_nexorder.sh, deploy_nexorder.sh
- Configuraciones: nexorder-ssl.conf, jail.local, httpd.conf
- Esquema de base de datos completo (nexorder_schema.sql)
- Procedimientos de emergencia y troubleshooting

###  Acceso al Manual

 **Documento completo:** [`docs/docs_tecnic.md`](docs/docs_tecnic.md)

> Nota: El manual técnico está diseñado como referencia completa para administradores de sistemas, desarrolladores y auditores. Incluye diagramas de arquitectura, comandos exactos, justificaciones técnicas y evidencias de implementación.

---

##  Equipo

| Miembro | Rol Principal | GitHub / Contacto |
|:---|:---|:---|
| **Victor Serrano** | Infraestructura, Backend y Scripts | [GitHub](#) |
| **Trishan Mizhquiri** | Base de Datos, Seguridad y Despliegue | [GitHub](#) |

---

## Conclusión

Este proyecto demuestra la evolución de procesos manuales a una solución cloud escalable, resiliente y segura. NexOrder integra competencias clave en administración de sistemas, desarrollo web y seguridad, cumpliendo con los estándares profesionales del sector.

---

<div align="center">

**"Innovar es servir mejor"** — NexOrder

Llevamos la experiencia de tu restaurante al siguiente nivel con una plataforma cloud segura, escalable y diseñada para el sector HORECA.

</div>
