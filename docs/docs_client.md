#  NexOrder Infrastructure - Resumen para Clientes
Fecha de actualización: 12 de mayo de 2026  

Propósito: Documento informativo para clientes y partes interesadas. Para detalles técnicos, consultar la documentación interna enlazada al final.

---

##  ¿Qué es NexOrder Infrastructure?

NexOrder es una plataforma de gestión de pedidos diseñada para restaurantes y servicios de alimentación, alojada en una infraestructura cloud segura y escalable en AWS.

### Beneficios Clave para tu Negocio

| Beneficio | Impacto para ti |
|-----------|----------------|
|  **Seguridad por diseño** | Tus datos y los de tus clientes están protegidos con cifrado y controles de acceso estrictos |
|  **Alta disponibilidad** | Sistema operativo 24/7 con monitorización proactiva y recuperación ante fallos |
|  **Escalabilidad automática** | La infraestructura crece contigo: sin interrupciones cuando aumentan los pedidos |
|  **Backups automáticos** | Copias de seguridad diarias con capacidad de restauración en <30 minutos |
|  **Acceso seguro desde cualquier lugar** | Conexión HTTPS cifrada para administradores y usuarios finales |

---

##  Arquitectura Simplificada

```
┌─────────────────────────────────┐
│         USUARIOS FINALES         │
│   (Navegador · Móvil · Tablet)   │
└─────────┬───────────────────────┘
          │ HTTPS (cifrado)
          ▼
┌─────────────────────────────────┐
│      SERVIDOR WEB (PÚBLICO)      │
│  • Apache + PHP                  │
│  • Certificado SSL/TLS activo    │
│  • Protección contra ataques     │
└─────────┬───────────────────────┘
          │  Conexión interna segura
          ▼
┌─────────────────────────────────┐
│    BASE DE DATOS (PRIVADA)       │
│  • MySQL 8.0 gestionado          │
│  • Sin acceso directo a Internet │
│  • Backups automáticos diarios   │
└─────────────────────────────────┘
```

![Arquitectura simplificada](/img/sprint1/0-diagrama-logico.png)

Figura 1 – Vista conceptual de la infraestructura: capa pública (web) + capa privada (datos)

---

## Seguridad y Cumplimiento

### Medidas de Protección Implementadas

 Cifrado de datos en tránsito  
Todo el tráfico entre usuarios y el sistema viaja cifrado con TLS 1.2+.

 Acceso restringido por roles  
Cada usuario (administrador, cocina, cliente) tiene solo los permisos necesarios.

Protección contra fuerza bruta  
Sistema automático que bloquea intentos de acceso no autorizados.

Aislamiento de la base de datos  
La información crítica nunca está expuesta directamente a Internet.

Monitorización 24/7 
Alertas automáticas ante cualquier anomalía en el sistema.

![Dashboard de monitorización](/img/sprint3/27-dashboard-final.png)

**Figura 2** – Panel de control con métricas en tiempo real (CPU, disco, alertas)

---

##  Fiabilidad y Rendimiento

### Compromisos de Servicio

| Métrica | Compromiso | Estado Actual |
|---------|-----------|---------------|
| **Disponibilidad** | ≥ 99.9% mensual |  100% (último mes) |
| **Tiempo de respuesta** | < 2 segundos (p95) |  0.8s promedio |
| **Recuperación ante fallos (RTO)** | < 30 minutos |  24 minutos (probado) |
| **Frecuencia de backups** | Diario a las 03:00 |  Automático y verificado |
| **Retención de backups** | 7 días mínimos |  Configurado |

### Pruebas de Recuperación Realizadas

 **Simulación de caída de base de datos** → Restauración exitosa en 24 min 01 s  
 **Validación de integridad de datos** → Todas las tablas y registros recuperados  
 **Prueba de conectividad end-to-end** → Flujo completo web → BD funcionando

![Prueba de restauración](/img/sprint3/42-restore-gunzip-mysql.png)

**Figura 3** – Validación de restauración: datos íntegros tras recuperación

---

##  Acceso y Soporte

### Para Usuarios Finales
 **URL de acceso:** `https://<tu-dominio-nexorder>/`  
 **Requisitos:** Navegador moderno con HTTPS habilitado  
 **Compatible con:** Desktop, tablet y móvil

---

##  Próximas Mejoras (Roadmap)

| Feature | Beneficio | Fecha Estimada |
|---------|-----------|---------------|
|  Certificados SSL automáticos (Let's Encrypt) | Renovación sin intervención manual | Sprint 4 |
|  Backups replicados en otra región | Mayor resiliencia ante fallos regionales | Sprint 4 |
|  Protección WAF básica | Bloqueo proactivo de ataques web comunes | Sprint 4 |
|  Métricas de negocio en dashboard | Visibilidad de pedidos, ingresos, tendencias | Sprint 4 |

---

##  Información Legal y Contacto

**Proveedor de Infraestructura:** Amazon Web Services (AWS)  
**Región de Alojamiento:** us-east-1 (Norte de Virginia, EE.UU.)  
**Cumplimiento:** Buenas prácticas de seguridad cloud (CIS Benchmarks, principio de mínimo privilegio)

Contacto Comercial: 
 comercial@nexorder.local  
 www.nexorder.local  

---

> Nota: Este documento es informativo y no constituye un contrato de nivel de servicio (SLA). Para acuerdos formales de disponibilidad y soporte, consultar el contrato específico firmado con NexOrder.
