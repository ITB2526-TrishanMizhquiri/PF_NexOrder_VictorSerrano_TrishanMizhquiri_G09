# Documentación Técnica Completa - NexOrder Infrastructure
**Proyecto:** NexOrder Infrastructure  
**Autores:** Victor Serrano & Trishan Mizhquiri  
**Período:** 13 de abril 2026 – 12 de mayo 2026  
**Módulos:** M0370, M0369, M0375, M0378, M0374, M0377, C037

> ℹ️ **Propósito:** Documento de referencia rápida para técnicos. Para detalles completos, consultar los documentos fuente enlazados.

---

## 🔗 Documentos Fuente (Referencia Completa)

| Sprint | Documento Técnico | Enlace |
|--------|------------------|--------|
| **S1** | Infraestructura VPC, EC2, RDS, Hardening | [`docs/sprint1/infra_vpc.md`](docs/infra_vpc.md) |
| **S2** | Servicios Web, SSL, Fail2ban, MySQL | [`docs/sprint2/infra_webserver.md`](docs/infra_webserver.md) |
| **S3** | Backups, CloudWatch, Deploy, DR | [`docs/sprint3/infra_monitoring.md`](docs/infra_monitoring.md) |

---

## 🗂️ Acceso Rápido a Scripts y Configuraciones

/docs/src/

├── [backup_nexorder.sh](/docs/src/backup_nexorder.sh)     # Script backup automatizado (T13)

├── [deploy_nexorder.sh](/docs/src/desploy_nexorder.sh)     # Script despliegue continuo (T17)

├── [restore_test.md](/docs/src/restore_test.md)           # Informe prueba DR + RTO (T18)

├── [jail.local](/docs/src/jail.local)                     # Configuración Fail2ban (T09)

├── [nexorder-ssl.conf](/docs/src/nexorder-ssl.conf)       # VirtualHost HTTPS + HSTS (T08)

├── [nexorder_schema.sql](/docs/src/nexorder_schema.sql)   # Esquema completo BD (T10)

├── [connexio.php](/docs/src/connexio.php)                 # Motor conexión PDO (T12)

├── [panel.php](/docs/src/panel.php)                       # Panel estado + consulta segura (T12)

└── [index.php](/docs/src/index.php)                       # Página principal menú (T12)

---

## 🌐 Infraestructura de Red (Sprint 1) - Resumen Crítico

### Arquitectura de Red
![Arquitectura lógica VPC](/img/sprint1/0-diagrama-logico.png)

📸 **Figura 1** – Arquitectura de red con segregación pública/privada y defensa en profundidad

### Componentes Clave
| Recurso | ID / Valor | Propósito |
|---------|-----------|-----------|
| **VPC** | `vpc-0905a60eb17e6565f` | Contenedor lógico, CIDR `10.0.0.0/16` |
| **Subred Pública** | `subnet-0b18a1ba9a8bbb7ad` (`10.0.1.0/24`) | EC2 Web, acceso Internet |
| **Subred Privada** | `subnet-06db775e1d4b17a88` (`10.0.2.0/24`) | RDS MySQL, sin acceso directo |
| **IGW** | `igw-099e10b6c7e172a25` | Conectividad VPC ↔ Internet |
| **EC2** | `i-093d338216cd0568d` · IP: `3.86.92.89` | Servidor web Amazon Linux 2023 |
| **RDS** | `nexorder-db` · Endpoint: `...rds.amazonaws.com` | MySQL 8.0.40, subred privada |

### Tablas de Enrutamiento
![Tabla de enrutamiento pública](/img/sprint1/8-rt-publica.png)

📸 **Figura 2** – RT-Publica-NexOrder con ruta `0.0.0.0/0 → IGW` para acceso a Internet

### Security Groups
| Grupo | Reglas Clave | Propósito |
|-------|-------------|-----------|
| **SG-Web-NexOrder** | HTTP(80), HTTPS(443) `0.0.0.0/0`; SSH(22) `79.116.173.66/32` | Firewall servidor web |
| **SG-DB-NexOrder** | MySQL(3306) desde `sg-0e0334685744195e2` | Solo EC2 puede conectar a RDS |

![Creación de SG-DB-NexOrder](/img/sprint1/18-sg-db.png)

📸 **Figura 3** – SG-DB-NexOrder referenciando SG-Web (no IPs fijas) para mayor seguridad

### Hardening SSH Aplicado
```bash
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
Usuario: nexadmin (sudo restringido)
```

🔗 **Más detalles:** [`docs/infra_vpc.md`](docs/infra_vpc.md)

---

## 🌐 Servicios Web y Seguridad (Sprint 2) - Resumen Crítico

### Arquitectura de Servicios
![Arquitectura de servicios web](/img/sprint2/0-arquitectura-web.png)

📸 **Figura 4** – Stack completo de aplicación web con seguridad en cada capa

### Stack de Aplicación
| Componente | Versión / Configuración | Propósito |
|-----------|------------------------|-----------|
| **Apache** | 2.4.66 (`httpd`) | Servidor web principal |
| **PHP** | 8.5.4 | Motor de ejecución NexOrder |
| **SSL/TLS** | Certificado autofirmado RSA 2048, 365 días | Cifrado en tránsito |
| **Fail2ban** | 1.1.0, jail `sshd` (maxretry=3, bantime=1h) | Protección fuerza bruta SSH |

### Configuraciones Críticas
| Archivo | Ruta | Función |
|---------|------|---------|
| VirtualHost SSL | `/etc/httpd/conf.d/nexorder-ssl.conf` | Redirección 301 HTTP→HTTPS + HSTS |
| Fail2ban Jail | `/etc/fail2ban/jail.local` | Regla SSH con bloqueo automático |
| Hardening Apache | `/etc/httpd/conf/httpd.conf` | `ServerTokens Prod`, `ServerSignature Off` |

![Configuración VirtualHost SSL](/img/sprint2/9-ssl-config.png)

📸 **Figura 5** – nexorder-ssl.conf con redirección 301 y cabecera HSTS

### Control de Acceso MySQL
```sql
Usuario: nexorder_app@'%'
Permisos: SELECT, INSERT, UPDATE (sin CREATE/DROP/DELETE)
Plugin: mysql_native_password
BD: nexorder_db (utf8mb4)
```

✅ **Validación:** `CREATE TABLE` falla con `ERROR 1142` → mínimo privilegio activo

![Verificación de permisos MySQL](/img/sprint2/25-show-grants.png)

📸 **Figura 6** – SHOW GRANTS confirmando permisos restringidos de nexorder_app

🔗 **Más detalles:** [`docs/infra_webserver.md`](docs/infra_webserver.md)

---

## 🌐 Monitorización y Resiliencia (Sprint 3) - Resumen Crítico

### Arquitectura de Operaciones
![Arquitectura de monitorización](/img/sprint3/0-arquitectura.png)

📸 **Figura 7** – Diagrama de flujos de backup, monitorización y despliegue continuo

### Automatización de Backups
| Parámetro | Valor |
|-----------|-------|
| **Script** | `/usr/local/bin/backup_nexorder.sh` |
| **Cron** | `0 3 * * *` (03:00 AM diario) |
| **Formato** | `mysqldump \| gzip` → `nexorder_db_YYYYMMDD_HHMMSS.sql.gz` |
| **Retención** | 7 días (`find -mtime +7 -delete`) |
| **Log** | `/var/log/nexorder_backup.log` (auditoría timestamped) |

![Script de backup automatizado](/img/sprint3/2-backup-script-nano.png)

📸 **Figura 8** – backup_nexorder.sh con pipeline mysqldump | gzip y control de errores

### Rotación de Logs (Logrotate)
| Servicio | Configuración | Propósito |
|----------|--------------|-----------|
| **Apache** | `daily`, `rotate 7`, `compress`, `postrotate reload` | Evita llenado de disco |
| **MySQL** | `daily`, `rotate 7`, `copytruncate`, `compress` | Rotación sin reiniciar RDS |

### CloudWatch y Alertas
| Métrica | Umbral | Acción |
|---------|--------|--------|
| **CPUUtilization** | > 80% (período 1 min) | SNS → Email a administradores |
| **VolumeReadBytes** | Widget Número (dashboard) | Monitorización disco en tiempo real |
| **VolumeWriteBytes** | Widget Número (dashboard) | Detección temprana de saturación |

![Dashboard CloudWatch](/img/sprint3/27-dashboard-final.png)

📸 **Figura 9** – Dashboard con CPU (línea) y métricas EBS (números) en tiempo real

### Despliegue Continuo
```bash
Script: /usr/local/bin/deploy_nexorder.sh
Método: rsync -avz --delete staging/ → /var/www/html/
Validación: $? == 0 → systemctl reload httpd
Log: /var/log/deploy_nexorder.log
```

### Prueba de Restauración (DR)
| Métrica | Valor |
|---------|-------|
| **RTO Medido** | 24 min 01 s |
| **Objetivo** | < 30 min ✅ |
| **Procedimiento** | `DROP DB` → `gunzip \| grep -v "SET@@" \| mysql` → `SHOW TABLES` + `COUNT(*)` |
| **Nota RDS** | Filtrar `SET @@SESSION.SQL_LOG_BIN` y `SET @@GLOBAL` por restricciones `SUPER` |

![Restauración de base de datos](/img/sprint3/42-restore-gunzip-mysql.png)

📸 **Figura 10** – Restauración con filtrado grep -v para compatibilidad con RDS

### Auditoría de Seguridad (nmap)
```bash
Comando: nmap -sV -T4 <IP_EC2>
Resultado: Puertos abiertos → 22/tcp (SSH), 80/tcp (HTTP), 443/tcp (HTTPS)
Interpretación: Superficie de exposición mínima, consistente con mínimo privilegio
```

![Escaneo nmap de seguridad](/img/sprint3/46-nmap-scan-result.png)

📸 **Figura 11** – nmap confirmando solo 3 puertos expuestos (superficie mínima)

🔗 **Más detalles:** [`docs/infra_monitoring.md`](docs/infra_monitoring.md)

---

## 📊 Resumen de Criterios Cumplidos

| Código | Descripción | Sprint | Estado |
|--------|-------------|--------|--------|
| **M0370** | Planificación de redes: VPC, subredes, enrutamiento | S1 | ✅ |
| **M0369** | Integración de ordenadores en red: conectividad EC2-RDS | S1 | ✅ |
| **M0375** | Servicios de red: HTTP/HTTPS, SSL/TLS, HSTS | S2 | ✅ |
| **M0378** | Administración de servidores: Apache, MySQL, Fail2ban | S2, S3 | ✅ |
| **M0374** | Automatización: scripts Bash, cron, rsync | S3 | ✅ |
| **M0377** | Backups lógicos con rotación y verificación | S3 | ✅ |
| **C037** | Seguridad: mínimo privilegio, hardening, monitorización proactiva | S1, S2, S3 | ✅ |

---

## 🚨 Comandos de Emergencia (Quick Reference)

### Restaurar Base de Datos
```bash
# 1. Verificar backup disponible
ls -lh /backups/*.sql.gz | tail -1

# 2. Restaurar (filtrando sentencias incompatibles con RDS)
gunzip -c /backups/nexorder_db_*.sql.gz \
  | grep -v "SET@@SESSION.SQL_LOG_BIN" \
  | grep -v "SET@@GLOBAL" \
  | mysql -h <ENDPOINT> -u admin -p nexorder_db

# 3. Verificar integridad
mysql -h <ENDPOINT> -u admin -p -e "USE nexorder_db; SHOW TABLES; SELECT COUNT(*) FROM productos;"
```

### Revertir Despliegue (Rollback)
```bash
# 1. Copiar versión anterior desde backup o staging
sudo rsync -avz --delete /home/ec2-user/web-staging-backup/ /var/www/html/

# 2. Recargar Apache
sudo systemctl reload httpd

# 3. Verificar
curl -k https://localhost/
```

### Desbloquear IP en Fail2ban
```bash
# Ver IPs bloqueadas
sudo fail2ban-client status sshd

# Desbanear IP específica
sudo fail2ban-client set sshd unbanip <IP>

# Reiniciar jail si es necesario
sudo fail2ban-client reload
```

### Verificar Estado de Servicios
```bash
# Servicios críticos
systemctl status httpd crond fail2ban

# Puertos activos
ss -tlnp | grep -E ':(80|443|22|3306)'

# Espacio en disco
df -h / /backups /var/log
```

---

## 📞 Contacto del Equipo

| Rol | Nombre | Canal |
|-----|--------|-------|
| Responsable Infraestructura | Victor Serrano | victor.serrano@nexorder.local |
| Responsable Seguridad | Trishan Mizhquiri | trishan.mizhquiri@email.com |
| Emergencias 24/7 | Equipo NexOrder | SNS Topic: `NexOrder_Alerts` |

---