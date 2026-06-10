# Análisis de Costes del Proyecto

## 1. Resumen Ejecutivo
El proyecto se estructura en un modelo de coste mixto: una inversión inicial (CAPEX) para configuración y despliegue, y un coste operativo recurrente (OPEX) principalmente ligado a la infraestructura en la nube y licencias.

## 2. Costes de Infraestructura AWS (OPEX Mensual)
Estimación basada en una arquitectura de alta disponibilidad para una tienda con ~1000 tickets/día.

| Servicio AWS | Especificaciones | Coste Mensual Estimado |
|--------------|------------------|------------------------|
| **EC2** | 2x instancias t3.medium (Auto-scaling) | 70,00 € |
| **RDS** | PostgreSQL db.t3.medium (Multi-AZ) | 100,00 € |
| **ElastiCache** | Redis t3.small (Caché y colas) | 15,00 € |
| **S3** | 50 GB (Backups, imágenes de productos) | 1,50 € |
| **Route 53 + CloudFront** | DNS y CDN para assets estáticos | 5,00 € |
| **CloudWatch + Backup** | Monitorización y copias de seguridad automatizadas | 10,00 € |
| **Transferencia de Datos** | Salida de datos estimada (100 GB/mes) | 9,00 € |
| **TOTAL MENSUAL AWS** | | **~210,50 €** |

## 3. Otros Costes Operativos (OPEX)
- **Licencia Odoo Enterprise:** ~25,00 € / usuario / mes (ej. 3 usuarios = 75,00 €/mes). *Nota: Si se usa Community, este coste es 0 €, pero se asume coste de mantenimiento técnico.*
- **Mantenimiento y Soporte Técnico:** Estimado en 10 horas/mes a 40€/h = 400,00 €/mes.

## 4. Inversión Inicial (CAPEX)
- **Hardware (Tablets, impresoras, cajones):** ~1.500,00 € (pago único).
- **Desarrollo y Configuración Inicial (Victor/Trishan):** 80 horas estimadas = 3.200,00 € (coste interno/oportunidad).

## 5. Proyección Anual y Contingencia
- **Coste Operativo Anual Base:** (210,50 + 75 + 400) * 12 = **8.226,00 €**.
- **Fondo de Contingencia (15%):** 1.233,90 € (para picos de tráfico o subidas de precio AWS).
- **Presupuesto Anual Total Recomendado:** **~9.460,00 €**.