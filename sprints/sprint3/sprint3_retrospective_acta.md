# Acta de Sprint Retrospective - Sprint 3

**Proyecto:** NexOrder Infrastructure  
**Sprint:** 3 (27 de abril 2026 - 3 de mayo 2026)  
**Participantes:** Victor Serrano, Trishan Mizhquiri  
**Facilitador:** [Nombre del Scrum Master o Líder de Proyecto]  
**Estado del Sprint:** Completado Exitosamente (con resolución de incidencias en el mismo sprint)

---

## 1. Resumen Ejecutivo
El Sprint 3 logró el 100% de sus objetivos, entregando automatización de backups lógicos, rotación de logs, monitorización proactiva con CloudWatch/SNS, despliegue continuo mediante rsync y una prueba de recuperación ante desastres exitosa. El esfuerzo real fue un 10.7% mayor al planificado (15.5h vs 14h estimadas) debido a un bloqueo técnico durante la restauración del backup en RDS, causado por restricciones de privilegios SUPER en el servicio gestionado. Este incidente fue diagnosticado y resuelto eficientemente mediante el filtrado de metadatos de sesión, sin impactar la fecha de entrega final.

---

## 2. Análisis Retrospectivo

### Qué ha funcionado bien (Para mantener / Continue)
1. **Resiliencia y Recuperación Probada:** La simulación de caída y restauración de la base de datos fue un éxito, logrando un RTO (Recovery Time Objective) de 24 minutos y 1 segundo, cumpliendo holgadamente con el objetivo de menos de 30 minutos.
2. **Monitorización Proactiva:** La implementación de CloudWatch junto con SNS ha transformado la infraestructura de reactiva a proactiva, permitiendo una respuesta inmediata ante picos de CPU o fallos de disco.
3. **Automatización Robusta:** Los scripts de backup y despliegue (rsync) funcionan sin intervención manual, incluyen validación de códigos de salida y generan auditoría completa en los logs.
4. **Auditoría de Seguridad Externa:** El escaneo con nmap desde Kali Linux validó de forma independiente que la superficie de ataque es mínima, exponiendo únicamente los puertos 22, 80 y 443.
5. **Gestión Eficiente de Logs:** La configuración de logrotate previene el llenado del disco de manera automática y transparente, sin requerir reinicios manuales de los servicios.

### Qué ha fallado o nos ha frenado (Para abordar / Stop)
1. **Fallo Inicial en Restauración de Backup RDS:** El proceso de restore falló al intentar importar sentencias como `SET @@SESSION.SQL_LOG_BIN` y `SET @@GLOBAL`, las cuales son bloqueadas por las restricciones de privilegios de Amazon RDS.
   - **Causa Raíz:** Asumir que un dump de mysqldump de una base de datos estándar se restauraría directamente en un servicio gestionado (PaaS) sin tener en cuenta las limitaciones de privilegios SUPER propias de estos entornos.
2. **Uso de Rutas Relativas en Cron:** Inicialmente, el trabajo programado en cron no se ejecutaba correctamente porque el script dependía del directorio de trabajo actual o variables de entorno no cargadas en el contexto de cron.
   - **Causa Raíz:** Falta de estandarización en el uso de rutas absolutas y redirección de errores (`2>&1`) en la programación inicial de tareas automatizadas.

### Qué debemos mejorar (Oportunidades / Start)
1. **Backups con Redundancia Geográfica:** No depender únicamente del almacenamiento local de la instancia EC2. Replicar los archivos de backup a un bucket de Amazon S3 para garantizar la supervivencia de los datos ante una caída total de la instancia.
2. **Certificados SSL de Confianza:** Migrar de certificados autofirmados a certificados gestionados automáticamente (Let's Encrypt con Certbot) para eliminar las advertencias de seguridad en los navegadores de los usuarios finales.
3. **Protección a Nivel de Aplicación:** Implementar un Web Application Firewall (WAF) básico para proteger la capa de aplicación contra vectores de ataque comunes como SQLi o XSS (OWASP Top 10).
4. **Evolución hacia CI/CD Nativo:** Evaluar la migración del script de despliegue local (`deploy.sh`) a un pipeline nativo (como GitHub Actions o AWS CodePipeline) para ganar trazabilidad, historial de ejecuciones y mayor control de versiones.

---

## 3. Plan de Acción Comprometido (Action Items)

| ID | Acción Concreta de Mejora | Responsable | Fecha Límite | Criterio de Éxito (DoD de la mejora) |
|---|---|---|---|---|
| **1** | **Replicación de Backups a S3:** Modificar el script de backup para ejecutar `aws s3 sync` tras la generación local, configurando una política de ciclo de vida en el bucket. | Trishan | Sprint 4 (10/05/2026) | Backup local y copia en S3 verificada. Política de transición a Glacier configurada. |
| **2** | **Migración a Let's Encrypt:** Implementar Certbot en la instancia EC2 para obtener un certificado válido y configurar la renovación automática mediante cron. | Victor | Sprint 4 (10/05/2026) | Certificado válido instalado, sin advertencias en navegador y renew configurado. |
| **3** | **Implementación de WAF Básico:** Configurar AWS WAF asociado al balanceador o distribución, con reglas básicas de OWASP Top 10 activadas. | Victor | Sprint 4 (10/05/2026) | WAF activo y bloqueando una petición de prueba maliciosa simulada. |
| **4** | **Documentación Formal de DR:** Consolidar el procedimiento de restauración (incluyendo el filtro `grep -v` para RDS) en un runbook oficial de Recuperación ante Desastres con RTO/RPO definidos. | Trishan | Sprint 4 (10/05/2026) | Documento `DR_Runbook.md` aprobado, con pasos claros y tiempos estimados. |

---

## 4. Métricas de Salud del Sprint

| Métrica | Valor | Observación |
| :--- | :--- | :--- |
| **Velocidad Planificada** | 14 horas | Estimación precisa y realista para el alcance definido. |
| **Velocidad Real Total** | ~15.5 horas | Desviación del +10.7%, totalmente dentro del margen aceptable y justificado por la investigación del fallo de restore en RDS. |
| **Tareas Completadas** | 7 / 7 (100%) | Todas las tareas (T13-T19) y sus 22 subtareas entregadas y validadas. |
| **Defectos Encontrados** | 1 | Fallo en el script de restore por privilegios SUPER, detectado y resuelto dentro del mismo sprint. |
| **Retrabajo Técnico** | 6.5% | Mínimo. El tiempo extra se invirtió en ajustar el filtro del dump, no en rehacer la arquitectura. |
| **RTO Medido** | 24 min 01s | Objetivo: < 30 min. Cumplido exitosamente, validando la resiliencia del sistema. |
