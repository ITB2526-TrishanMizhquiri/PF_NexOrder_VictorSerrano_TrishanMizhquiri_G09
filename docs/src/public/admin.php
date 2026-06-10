<?php
require_once __DIR__ . "/../app/auth.php";
require_once __DIR__ . "/../app/helpers.php";
verificarRol(["admin"]);

$col_nombre = "nombre";
$col_id = "id_estado";

$total_pedidos = $pdo->query("SELECT COUNT(*) as total FROM pedidos")->fetch()["total"];
$total_usuarios = $pdo->query("SELECT COUNT(*) as total FROM usuarios WHERE activo = 1")->fetch()["total"];
$total_productos = $pdo->query("SELECT COUNT(*) as total FROM productos WHERE disponible = 1")->fetch()["total"];
$ingresos = $pdo->query("SELECT COALESCE(SUM(total), 0) as total FROM pedidos")->fetch()["total"];

$stmt = $pdo->query("SELECT p.*, u.nombre_completo as cliente, e.$col_nombre as estado_nombre 
                     FROM pedidos p 
                     LEFT JOIN usuarios u ON p.id_usuario = u.id_usuario 
                     LEFT JOIN estados e ON p.id_estado = e.$col_id 
                     ORDER BY p.fecha_pedido DESC LIMIT 10");
$ultimos_pedidos = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Admin - NexOrder</title>
    <style>
        body { font-family: system-ui, sans-serif; max-width: 1200px; margin: 0 auto; padding: 2rem; background: #f4f7fb; }
        .header { background: #0f172a; color: white; padding: 1rem 2rem; border-radius: 12px; margin-bottom: 2rem; display: flex; justify-content: space-between; align-items: center; }
        .header h1 { margin: 0; font-size: 1.5rem; }
        .nav a { color: white; text-decoration: none; margin-left: 1.5rem; }
        h2 { color: #1f2937; margin-bottom: 1.5rem; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1.5rem; margin-bottom: 2rem; }
        .stat-card { background: white; padding: 2rem; border-radius: 12px; text-align: center; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
        .stat-card h3 { font-size: 2.5rem; color: #2563eb; margin-bottom: 0.5rem; }
        .stat-card p { color: #6b7280; font-weight: 600; }
        .tabla { width: 100%; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
        .tabla th, .tabla td { padding: 1rem; text-align: left; border-bottom: 1px solid #e5e7eb; }
        .tabla thead { background: #0f172a; color: white; }
        .badge { display: inline-block; padding: 0.25rem 0.75rem; border-radius: 12px; font-size: 0.875rem; font-weight: 600; background: #dbeafe; color: #1e40af; }
    </style>
</head>
<body>
    <header class="header">
        <h1>NexOrder - Admin</h1>
        <nav class="nav">
            <a href="/">Inicio</a>
            <a href="/cocina.php">Cocina</a>
            <a href="/logout.php">Salir</a>
        </nav>
    </header>

    <h2>Panel de Administración</h2>

    <div class="grid">
        <div class="stat-card"><h3><?= $total_pedidos ?></h3><p>Pedidos Totales</p></div>
        <div class="stat-card"><h3><?= $total_usuarios ?></h3><p>Usuarios Activos</p></div>
        <div class="stat-card"><h3><?= $total_productos ?></h3><p>Productos Disponibles</p></div>
        <div class="stat-card"><h3><?= number_format($ingresos, 2, ",", ".") ?> €</h3><p>Ingresos Totales</p></div>
    </div>

    <h3>Últimos Pedidos</h3>
    <table class="tabla">
        <thead>
            <tr><th>ID</th><th>Cliente</th><th>Fecha</th><th>Total</th><th>Estado</th></tr>
        </thead>
        <tbody>
            <?php foreach ($ultimos_pedidos as $p): ?>
                <tr>
                    <td>#<?= $p["id_pedido"] ?></td>
                    <td><?= htmlspecialchars($p["cliente"] ?? "Invitado") ?></td>
                    <td><?= date("d/m/Y H:i", strtotime($p["fecha_pedido"])) ?></td>
                    <td><?= number_format($p["total"], 2, ",", ".") ?> €</td>
                    <td><span class="badge"><?= htmlspecialchars($p["estado_nombre"] ?? "Pendiente") ?></span></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</body>
</html>
