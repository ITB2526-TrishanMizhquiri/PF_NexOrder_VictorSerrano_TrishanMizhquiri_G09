<?php
require_once __DIR__ . "/../app/auth.php";
require_once __DIR__ . "/../app/helpers.php";
verificarRol(["cliente"]);

$col_nombre = "nombre";
$col_id = "id_estado";

if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_POST["crear_pedido"]) && !empty($_SESSION["carrito"])) {
    try {
        $pdo->beginTransaction();
        
        $total = 0;
        foreach ($_SESSION["carrito"] as $id => $cant) {
            $stmt = $pdo->prepare("SELECT precio FROM productos WHERE id_producto = ?");
            $stmt->execute([$id]);
            $prod = $stmt->fetch();
            if ($prod) $total += $prod["precio"] * $cant;
        }
        
        $stmt = $pdo->prepare("INSERT INTO pedidos (id_usuario, id_estado, total, notas) VALUES (?, 1, ?, ?)");
        $stmt->execute([$_SESSION["usuario_id"], $total, $_POST["notas"] ?? ""]);
        $id_pedido = $pdo->lastInsertId();
        
        $stmt = $pdo->prepare("INSERT INTO detalle_pedidos (id_pedido, id_producto, cantidad, precio_unitario) VALUES (?, ?, ?, ?)");
        foreach ($_SESSION["carrito"] as $id => $cant) {
            $stmt2 = $pdo->prepare("SELECT precio FROM productos WHERE id_producto = ?");
            $stmt2->execute([$id]);
            $prod = $stmt2->fetch();
            if ($prod) {
                $stmt->execute([$id_pedido, $id, $cant, $prod["precio"]]);
            }
        }
        
        $pdo->commit();
        unset($_SESSION["carrito"]);
        header("Location: /pedido.php?msg=created");
        exit;
    } catch (Exception $e) {
        $pdo->rollBack();
        error_log("Error al crear pedido: " . $e->getMessage());
        header("Location: /pedido.php?msg=error");
        exit;
    }
}

$stmt = $pdo->prepare("SELECT p.*, e.$col_nombre as estado_nombre FROM pedidos p LEFT JOIN estados e ON p.id_estado = e.$col_id WHERE p.id_usuario = ? ORDER BY p.fecha_pedido DESC");
$stmt->execute([$_SESSION["usuario_id"]]);
$pedidos = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Mis Pedidos - NexOrder</title>
    <style>
        body { font-family: system-ui, sans-serif; max-width: 1200px; margin: 0 auto; padding: 2rem; background: #f4f7fb; }
        .header { background: #0f172a; color: white; padding: 1rem 2rem; border-radius: 12px; margin-bottom: 2rem; display: flex; justify-content: space-between; align-items: center; }
        .header h1 { margin: 0; font-size: 1.5rem; }
        .nav a { color: white; text-decoration: none; margin-left: 1.5rem; }
        h2 { color: #1f2937; margin-bottom: 1.5rem; }
        .tabla { width: 100%; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 2rem; }
        .tabla th, .tabla td { padding: 1rem; text-align: left; border-bottom: 1px solid #e5e7eb; }
        .tabla thead { background: #0f172a; color: white; }
        .btn { display: inline-block; padding: 0.75rem 1.5rem; background: #2563eb; color: white; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; }
        .alert { padding: 1rem; border-radius: 6px; margin-bottom: 1rem; }
        .alert-success { background: #d1fae5; color: #065f46; }
        .alert-info { background: #dbeafe; color: #1e40af; }
        .alert-danger { background: #fee2e2; color: #991b1b; }
        .form-group { margin-bottom: 1rem; }
        textarea { width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 6px; }
        .badge { display: inline-block; padding: 0.25rem 0.75rem; border-radius: 12px; font-size: 0.875rem; font-weight: 600; background: #dbeafe; color: #1e40af; }
    </style>
</head>
<body>
    <header class="header">
        <h1>NexOrder</h1>
        <nav class="nav">
            <a href="/">Inicio</a>
            <a href="/menu.php">Menú</a>
            <a href="/pedido.php">Mis Pedidos</a>
            <a href="/logout.php">Salir</a>
        </nav>
    </header>

    <?php if (isset($_GET["msg"])): ?>
        <?php if ($_GET["msg"] === "created"): ?>
            <div class="alert alert-success">✅ Pedido creado correctamente</div>
        <?php elseif ($_GET["msg"] === "error"): ?>
            <div class="alert alert-danger">❌ Error al crear el pedido</div>
        <?php endif; ?>
    <?php endif; ?>

    <h2>Mis Pedidos</h2>

    <?php if (!empty($_SESSION["carrito"])): ?>
        <div class="alert alert-info">
            Tienes <?= contarCarrito() ?> productos en tu carrito.
            <a href="/menu.php">Ver carrito</a>
        </div>
        <form method="POST">
            <div class="form-group">
                <label>Notas adicionales:</label>
                <textarea name="notas" rows="3" placeholder="Ej: Sin gluten, mesa 5..."></textarea>
            </div>
            <button type="submit" name="crear_pedido" class="btn">Confirmar Pedido</button>
        </form>
    <?php endif; ?>

    <table class="tabla">
        <thead>
            <tr><th>ID</th><th>Fecha</th><th>Total</th><th>Estado</th></tr>
        </thead>
        <tbody>
            <?php foreach ($pedidos as $p): ?>
                <tr>
                    <td>#<?= $p["id_pedido"] ?></td>
                    <td><?= date("d/m/Y H:i", strtotime($p["fecha_pedido"])) ?></td>
                    <td><?= number_format($p["total"], 2, ",", ".") ?> €</td>
                    <td><span class="badge"><?= htmlspecialchars($p["estado_nombre"] ?? "Pendiente") ?></span></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</body>
</html>
