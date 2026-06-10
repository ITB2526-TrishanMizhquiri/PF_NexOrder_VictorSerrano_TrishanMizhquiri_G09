# Acta de Sprint Retrospective - Sprint 2

**Proyecto:** NexOrder Infrastructure  
**Sprint:** 2 (20 de abril 2026 - 26 de abril 2026)  
**Participantes:** Victor Serrano, Trishan Mizhquiri  
**Facilitador:** [Nombre del Scrum Master o Líder de Proyecto]  
**Estado del Sprint:** Completado Exitosamente (con resolución de incidencias en el mismo sprint)

---

## 1. Resumen Ejecutivo
El Sprint 2 logró el 100% de sus objetivos, entregando un servidor web seguro (Apache/PHP), cifrado SSL/TLS con redirección HTTPS forzada, protección contra fuerza bruta (Fail2ban), control de acceso estricto a la base de datos (mínimo privilegio) y una capa de validación PHP+PDO funcional. El esfuerzo real fue un 10.7% mayor al planificado (15.5h vs 14h estimadas) debido a un bloqueo técnico menor durante la configuración de SSL (puerto 443), el cual fue diagnosticado y resuelto eficientemente sin impactar la fecha de entrega.

---

## 2. Análisis Retrospectivo

### Qué ha funcionado bien (Para mantener / Continue)
1. **Implementación de Seguridad en Profundidad:** La aplicación del principio de mínimo privilegio en la base de datos (usuario 'nexorder_app' sin permisos DROP/DELETE/CREATE) y el ocultamiento de la versión de Apache (ServerTokens Prod) elevaron significativamente la postura de seguridad.
2. **Capacidad de Diagnóstico y Resolución:** El error del puerto 443 se identificó y corrigió rápidamente gracias a la revisión sistemática de módulos de Apache y la validación de la sintaxis de configuración antes de los reinicios.
3. **Validación Funcional Integral:** La creación de la capa de validación web (index.php, connexio.php, panel.php) permitió demostrar de forma tangible y automatizada que la conexión segura entre el frontend (PHP/PDO) y el backend (RDS) funcionaba correctamente.
4. **Documentación Técnica Rigurosa:** El registro detallado de comandos, archivos de configuración modificados y salidas de terminal facilitó la auditoría interna y la resolución del incidente de SSL.

### Qué ha fallado o nos ha frenado (Para abordar / Stop)
1. **Omisión de Dependencias de Módulos en Apache:** Al configurar el VirtualHost SSL, no se verificó inicialmente la carga de módulos esenciales como `mod_headers` y `mod_rewrite`, ni se incluyó explícitamente la directiva `Listen 443` en la configuración principal.
   - **Causa Raíz:** Falta de un checklist de verificación previa al reinicio de servicios críticos. Se asumió que la instalación del paquete `mod_ssl` habilitaba todas las directivas necesarias por defecto.
2. **Uso de Certificados Autofirmados:** Aunque cumple el objetivo técnico del sprint, los certificados autofirmados generan advertencias en el navegador y no son una práctica viable para un entorno de producción real.

### Qué debemos mejorar (Oportunidades / Start)
1. **Checklist de Despliegue de Servicios:** Establecer un protocolo obligatorio de validación de sintaxis (`httpd -t`) y verificación de módulos cargados (`httpd -M`) antes de cualquier reinicio de servicio en el servidor web.
2. **Automatización de Certificados:** Planificar la migración a certificados gestionados automáticamente (ej. Let's Encrypt con Certbot) para eliminar la gestión manual y las advertencias de seguridad en el navegador.
3. **Monitoreo Proactivo y Centralización:** No esperar a que ocurra un error para revisarlo. Implementar CloudWatch Logs para Apache y alertas de métricas (CPU, disco) para detectar anomalías antes de que afecten al servicio.

---

## 3. Plan de Acción Comprometido (Action Items)

| ID | Acción Concreta de Mejora | Responsable | Fecha Límite | Criterio de Éxito (DoD de la mejora) |
|---|---|---|---|---|
| **1** | **Crear Checklist de Despliegue Web:** Documentar y utilizar una lista de verificación para configuraciones de Apache (incluyendo `httpd -t`, `httpd -M` y validación de puertos `ss -tlnp`). | Victor | Inicio del Sprint 3 (27/04/2026) | Checklist añadido a la documentación del proyecto y aplicado en la tarea T13. |
| **2** | **Migración a Certificados Reales:** Investigar e implementar la generación de certificados válidos mediante Let's Encrypt (Certbot) en lugar de autofirmados. | Victor | Sprint 3 (03/05/2026) | Certificado válido instalado, sin advertencias en el navegador y con renovación automática configurada. |
| **3** | **Implementar Monitoreo y Alertas:** Configurar CloudWatch Alarms para umbrales de CPU (>80%) y disco (>90%), y centralizar logs de Apache. | Victor | Sprint 3 (03/05/2026) | Alerta de prueba recibida correctamente y logs de Apache visibles en CloudWatch. |
| **4** | **Automatización de Backups de BD:** Desarrollar y probar un script robusto de backup y restore de MySQL, programado vía cron. | Trishan | Sprint 3 (03/05/2026) | Script ejecutado manualmente con éxito, archivo de backup generado y restaurado en un entorno de prueba. |

---

## 4. Métricas de Salud del Sprint

| Métrica | Valor | Observación |
| :--- | :--- | :--- |
| **Velocidad Planificada** | 14 horas | Estimación precisa y realista para el alcance definido. |
| **Velocidad Real Total** | ~15.5 horas | Desviación del +10.7%, totalmente dentro del margen aceptable y justificado por la resolución del incidente SSL. |
| **Tareas Completadas** | 6 / 6 (100%) | Todas las tareas (T07-T12) y sus 23 subtareas entregadas y validadas. |
| **Defectos Encontrados** | 1 | Error de configuración en puerto 443, detectado y resuelto dentro del mismo sprint (retrabajo técnico del 6.5%). |
| **Retrabajo Técnico** | 6.5% | Mínimo. El tiempo extra se invirtió en corregir la configuración, no en rehacer tareas completas. |