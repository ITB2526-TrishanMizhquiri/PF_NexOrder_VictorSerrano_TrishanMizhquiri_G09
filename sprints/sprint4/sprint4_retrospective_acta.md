# Acta de Sprint Retrospective - Sprint 4

**Proyecto:** NexOrder Infrastructure  
**Sprint:** 4 (4 de mayo 2026 - 12 de mayo 2026)  
**Participantes:** Victor Serrano, Trishan Mizhquiri  
**Facilitador:** [Nombre del Scrum Master o Líder de Proyecto]  
**Estado del Sprint:** Completado Exitosamente (con resolución de incidencias en el mismo sprint)

---

## 1. Resumen Ejecutivo
El Sprint 4 logró el 100% de sus objetivos, completando la entrega final del proyecto: implementación de WAF con reglas OWASP Top 10, replicación de backups a S3 con ciclo de vida, hardening avanzado con SELinux, logging estructurado en JSON y auditoría CIS Benchmarks con remediación. El esfuerzo real fue un 10.7% mayor al planificado (15.5h vs 14h estimadas) debido a un bloqueo técnico durante la obtención del certificado Let's Encrypt. La validación HTTP-01 falló por una resolución DNS incorrecta del dominio temporal, lo que obligó a cambiar al método de validación DNS-01. Este imprevisto se gestionó eficientemente sin impactar la fecha de entrega final.

---

## 2. Análisis Retrospectivo

### Qué ha funcionado bien (Para mantener / Continue)
1. **Seguridad por Capas (Defense in Depth):** La combinación de WAF a nivel de aplicación, SELinux en modo enforcing a nivel de kernel y el principio de mínimo privilegio en la base de datos ha elevado el estándar de seguridad del proyecto a un nivel empresarial.
2. **Resiliencia y Recuperación Probada:** La replicación de backups a S3 con política de ciclo de vida (7 días Standard a 30 días Glacier) garantiza la redundancia geográfica y la optimización de costes a largo plazo.
3. **Automatización Robusta:** La renovación automática de certificados, los scripts de backup con auditoría en logs y el despliegue continuo mediante rsync funcionan sin intervención manual, reduciendo el riesgo de error humano.
4. **Cumplimiento Auditado:** La ejecución de la auditoría CIS Benchmarks y la documentación de un plan de remediación para los hallazgos restantes demuestran un compromiso real con los estándares de la industria.

### Qué ha fallado o nos ha frenado (Para abordar / Stop)
1. **Fallo Inicial en la Validación de Let's Encrypt:** El proceso de obtención del certificado falló inicialmente al usar el método HTTP-01.
   - **Causa Raíz:** No se verificó la resolución DNS del dominio temporal antes de iniciar el proceso de certbot. Asumimos que el dominio resolvía correctamente a la IP de la instancia EC2, lo cual no era cierto en ese momento.
2. **Despliegue Manual vía Script Local:** Aunque el script `deploy_nexorder.sh` con rsync funciona, carece de la trazabilidad, el historial de ejecuciones y el control de versiones que ofrece un sistema de CI/CD nativo en la nube.

### Qué debemos mejorar (Oportunidades / Start)
1. **Checklist de Pre-vuelo (Pre-flight Checks):** Establecer un protocolo obligatorio para verificar la resolución DNS (ej. `dig +short`) y la accesibilidad de puertos antes de iniciar procesos de certificación o despliegue.
2. **Infraestructura como Código (IaC):** Migrar toda la infraestructura desplegada manualmente a Terraform o AWS CloudFormation para garantizar una reproducibilidad total en minutos y facilitar la gestión de cambios.
3. **Pipeline de CI/CD Nativo:** Evaluar la implementación de GitHub Actions o AWS CodePipeline para reemplazar los scripts de despliegue locales, ganando trazabilidad, pruebas automatizadas y mayor control.
4. **Gestión Centralizada de Secretos:** Migrar las credenciales de base de datos y claves API desde archivos de configuración locales a AWS Secrets Manager o Systems Manager Parameter Store.

---

## 3. Plan de Acción Comprometido (Action Items)

| ID | Acción Concreta de Mejora | Responsable | Fecha Límite | Criterio de Éxito (DoD de la mejora) |
|---|---|---|---|---|
| **1** | **Implementar Checklist de Validación DNS:** Crear y documentar un script o checklist que verifique la resolución DNS y la propagación antes de ejecutar certbot. | Trishan | Mantenimiento Post-Proyecto | Checklist documentado y aplicado en la próxima renovación o cambio de dominio. |
| **2** | **Migrar a Infraestructura como Código (IaC):** Crear un módulo de Terraform o plantilla de CloudFormation que replique la VPC, EC2, RDS y WAF del proyecto. | Victor | Futuro / Mantenimiento | Script de IaC capaz de desplegar la infraestructura base en un entorno nuevo en menos de 15 minutos. |
| **3** | **Implementar Pipeline CI/CD Básico:** Configurar un workflow de GitHub Actions que ejecute linting de scripts y despliegue vía rsync de forma automatizada ante un push a la rama principal. | Ambos | Futuro / Mantenimiento | Pipeline ejecutado con éxito, mostrando logs de despliegue y validación en la consola de GitHub. |
| **4** | **Centralizar Gestión de Secretos:** Migrar las credenciales de `connexio.php` para que se lean desde AWS Systems Manager Parameter Store en lugar de estar hardcodeadas o en archivos planos. | Trishan | Futuro / Mantenimiento | Aplicación PHP funcionando correctamente leyendo credenciales desde Parameter Store, sin archivos de texto plano con contraseñas. |

---

## 4. Métricas de Salud del Sprint

| Métrica | Valor | Observación |
| :--- | :--- | :--- |
| **Velocidad Planificada** | 14 horas | Estimación precisa y realista para el alcance de cierre definido. |
| **Velocidad Real Total** | ~15.5 horas | Desviación del +10.7%, totalmente dentro del margen aceptable (<15%) y justificada por la investigación y cambio a validación DNS-01. |
| **Tareas Completadas** | 6 / 6 (100%) | Todas las tareas (T20-T25) entregadas y validadas. |
| **Subtareas Completadas** | 17 / 17 (100%) | Todos los criterios de aceptación y evidencias adjuntas correctamente. |
| **Defectos Encontrados** | 1 | Fallo de validación DNS en Let's Encrypt, detectado y resuelto dentro del mismo sprint. |
| **Retrabajo Técnico** | 9.7% | Mínimo. El tiempo extra se invirtió en ajustar el método de validación del certificado, no en rehacer la arquitectura. |
| **Hallazgos CIS Críticos** | 0 | Tras la remediación, no quedaron hallazgos de alta severidad, cumpliendo el objetivo de <5. |
| **Disponibilidad Estimada** | 99.95% | Lograda gracias a la combinación de WAF, backups en S3, monitorización proactiva y seguridad por capas. |