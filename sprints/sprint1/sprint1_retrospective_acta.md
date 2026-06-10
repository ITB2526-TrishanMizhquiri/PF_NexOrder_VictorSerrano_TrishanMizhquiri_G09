# Acta de Sprint Retrospective - Sprint 1

**Proyecto:** NexOrder Infrastructure  
**Sprint:** 1 (13 de abril 2026 - 19 de abril 2026)  
**Participantes:** Victor Serrano, Trishan Mizhquiri  
**Facilitador:** [Nombre del Scrum Master o Líder de Proyecto]  
**Estado del Sprint:** Completado Exitosamente (con retrabajo gestionado)

---

## 1. Resumen Ejecutivo
El Sprint 1 logró el 100% de sus objetivos (despliegue de VPC, EC2, RDS, Security Groups y hardening inicial). Sin embargo, el esfuerzo real fue un 35% mayor al planificado (19h vs 14h estimadas) debido a un incidente externo: la caducidad del laboratorio AWS, que obligó a recrear toda la infraestructura desde cero. Gracias a la documentación rigurosa, el impacto en la calidad fue nulo.

---

## 2. Análisis Retrospectivo

### Qué ha funcionado bien (Para mantener / Continue)
1. **Arquitectura y Seguridad Sólidas:** La segregación lógica (pública/privada) y la aplicación estricta del principio de mínimo privilegio en Security Groups y SSH funcionaron perfectamente desde el primer intento.
2. **Documentación en Tiempo Real:** El hábito de documentar cada comando y captura (TA01-TA06) fue el factor crítico que permitió recrear toda la infraestructura perdida en aproximadamente 4 horas, sin errores.
3. **Resiliencia y Trabajo en Equipo:** El equipo mantuvo la calma ante el imprevisto, reasignando tareas y ejecutando el plan de recuperación de manera coordinada y eficiente.
4. **Validación Exhaustiva:** Las pruebas de conectividad EC2 a RDS y la verificación del hardening (`sshd -t`, `visudo -c`) se realizaron sin generar defectos.

### Qué ha fallado o nos ha frenado (Para abordar / Stop)
1. **Pérdida del Entorno de Laboratorio:** El laboratorio AWS caducó a mitad del sprint, eliminando todos los recursos (VPC, EC2, RDS) sin previo aviso.
   - **Causa Raíz:** Falta de verificación proactiva de la fecha de expiración y las cuotas del entorno de laboratorio antes de iniciar tareas de larga duración.
2. **Configuración 100% Manual:** La necesidad de recrear todo manualmente evidenció la fragilidad del proceso ante fallos del entorno. No existía un script o plantilla de Infraestructura como Código (IaC).

### Qué debemos mejorar (Oportunidades / Start)
1. **Automatización del Despliegue:** Migrar la creación de recursos repetitivos (VPC, Subredes, IGW) a plantillas de CloudFormation o Terraform para garantizar la reproducibilidad en minutos, no en horas.
2. **Gestión Proactiva de Riesgos del Entorno:** Establecer un "Checklist Pre-Sprint" para validar la vigencia de los entornos de práctica y los límites de servicio de AWS.
3. **Monitoreo y Respaldo Temprano:** No esperar a sprints avanzados para tener visibilidad del estado del servidor y la seguridad de los datos (backups de RDS).

---

## 3. Plan de Acción Comprometido (Action Items)

| ID | Acción Concreta de Mejora | Responsable | Fecha Límite | Criterio de Éxito (DoD de la mejora) |
|---|---|---|---|---|
| **1** | **Implementar Checklist Pre-Sprint:** Crear y ejecutar una lista de verificación de vigencia de laboratorio, cuotas AWS y acceso a credenciales antes de iniciar cualquier tarea. | Victor y Trishan | Inicio del Sprint 2 (20/04/2026) | Checklist documentado y firmado en el acta de Planning del S2. |
| **2** | **Automatización Básica (IaC):** Crear un script de Bash o plantilla básica de CloudFormation para el despliegue de la VPC, Subredes e IGW. | Victor | Sprint 2 (26/04/2026) | Script probado que despliega la red base en menos de 5 minutos. |
| **3** | **Implementar Monitoreo y Backups:** Configurar alertas básicas de CloudWatch (CPU, Estado de instancia) y programar snapshots automáticos diarios de RDS. | Trishan | Sprint 2 (26/04/2026) | Alerta de prueba recibida por email y snapshot visible en la consola RDS. |
| **4** | **Hardening Avanzado:** Implementar reglas personalizadas de Fail2ban para SSH/MySQL y documentar el protocolo de rotación de claves SSH. | Trishan | Sprint 2 (26/04/2026) | Fail2ban activo (`systemctl status fail2ban`) y documentación actualizada en `docs/`. |

---

## 4. Métricas de Salud del Sprint

| Métrica | Valor | Observación |
| :--- | :--- | :--- |
| **Velocidad Planificada** | 14 horas | Estimación inicial realista para el alcance. |
| **Velocidad Real Total** | 19 horas | Desviación del +35%, totalmente justificada por el incidente externo (caducidad del laboratorio). |
| **Tareas Completadas** | 6 / 6 (100%) | Todas las tareas técnicas (TA01-TA06) entregadas y validadas. |
| **Defectos en Producción** | 0 | Cero errores de seguridad o conectividad post-despliegue. |
| **Retrabajo Técnico** | 0% | El retrabajo fue de "re-creación", no de corrección de errores en la configuración. |