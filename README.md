# PF_NexOrder_VictorSerrano_TrishanMizhquiri_G09
Este proyecto consiste en el desarrollo de NexOrder, un sistema digital de gestión de
pedidos para restaurantes, implementado en la nube mediante Amazon Web Services
(AWS). La aplicación web, desarrollada con HTML5, CSS3, JavaScript y PHP, permitirá a
los clientes consultar el menú y realizar pedidos a través de una interfaz intuitiva, mientras
que el personal de cocina gestionará las comandas en tiempo real mediante un panel de
control con estados dinámicos (pendiente, en preparación y finalizado), optimizando el
flujo de trabajo del establecimiento.
El sistema se basará en una arquitectura cliente-servidor desplegada en AWS. Se
configurará una VPC con subredes públicas y privadas, un Internet Gateway para la
conectividad externa y Security Groups como cortafuegos para restringir el tráfico por
puertos. La capa de cómputo residirá en una instancia EC2 con distribución Linux, donde
se instalará y configurará el stack LAMP (Apache/Nginx, MySQL client, PHP), se
gestionarán usuarios y permisos, se habilitará el acceso remoto seguro mediante claves
SSH, y se automatizarán tareas de mantenimiento y copias de seguridad mediante scripts
Bash y cron. La capa de datos se alojará en Amazon RDS (MySQL), donde se realizará
el diseño lógico y físico normalizado (diagrama E-R), se ejecutarán consultas SQL (CRUD,
JOINs), se crearán índices para optimizar consultas, se configurará el control de acceso
con privilegios limitados y se activarán los backups automáticos con política de retención.
En el ámbito del desarrollo y la seguridad, se implementará un backend en PHP que
consuma la base de datos mediante PDO y sentencias preparadas, se generará una API
REST básica con intercambio de datos en JSON, y se validará la entrada de formularios
en cliente y servidor. Se aplicarán medidas de hardening como la instalación de Fail2ban,
la configuración de certificados SSL/TLS para forzar HTTPS, la desactivación de firmas
del servidor web y la auditoría de logs de acceso. Todo ello alineado con la normativa de
protección de datos (GDPR/LOPD) y complementado con un análisis básico de
ciberseguridad (escaneo de puertos, revisión de vulnerabilidades comunes).
NexOrder representa una solución de digitalización y transformación tecnológica para
el sector HORECA, sustituyendo procesos manuales por un entorno cloud escalable,
reduciendo el consumo de papel y optimizando el uso de recursos según criterios de
sostenibilidad y economía circular. El proyecto integrará competencias transversales
como la documentación técnica con terminología estándar en inglés, el control de
versiones y portafolio profesional mediante GitHub, el trabajo colaborativo ágil y el análisis
del entorno socioeconómico del sector, cumpliendo con los requisitos académicos y
profesionales del ciclo formativo.
