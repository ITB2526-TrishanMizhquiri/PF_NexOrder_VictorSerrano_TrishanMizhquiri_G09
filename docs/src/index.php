<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexOrder - Infraestructura ASIXc</title>
    <style>
        body { font-family: system-ui, sans-serif; max-width: 800px; margin: 2rem auto; padding: 0 1rem; line-height: 1.6; }
        .card { background: #f8f9fa; padding: 1.5rem; border-radius: 8px; margin-bottom: 1rem; border-left: 4px solid #0d6efd; }
        .badge { background: #198754; color: white; padding: 0.2rem 0.6rem; border-radius: 4px; font-size: 0.85rem; }
        a { color: #0d6efd; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>🍽️ NexOrder <span class="badge">HTTPS Activo</span></h1>
    <p>Entorno de validación de infraestructura AWS (EC2 + RDS) para el proyecto ASIXc 25-26.</p>
    
    <div class="card">
        <h3>🔌 Pruebas de Conectividad</h3>
        <ul>
            <li><a href="connexio.php">Verificar conexión PDO a RDS</a></li>
            <li><a href="panel.php">Panel de estado del servidor y BD</a></li>
        </ul>
    </div>
    
    <div class="card" style="border-left-color: #6c757d;">
        <h3>📋 Características Técnicas</h3>
        <ul>
            <li>Apache 2.4 + PHP 8.x (Amazon Linux 2023)</li>
            <li>MySQL 8.0 RDS (Usuario restringido <code>nexorder_app</code>)</li>
            <li>SSL/TLS forzado + Cabecera HSTS</li>
            <li>Principio de mínimo privilegio aplicado</li>
        </ul>
    </div>
    
    <p><small>🔒 Acceso seguro vía HTTPS | Sin datos sensibles expuestos</small></p>
</body>
</html>
