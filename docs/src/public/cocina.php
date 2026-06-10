<?php
require_once __DIR__ . "/../app/auth.php";
require_once __DIR__ . "/../app/helpers.php";
verificarRol(["cocina", "admin"]);

$col_nombre = "nombre";
$col_id = "id_estado";

if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_POST["cambiar_estado"])) {
    $id_pedido = (int)$_POST["id_pedido"];
    $nuevo_estado = (int)$_POST["id_estado"];
    
    $stmt = $pdo->prepare("UPDATE pedidos SET id_estado = ? WHERE id_pedido = ?");
    $stmt->execute([$nuevo_estado, $id_pedido]);
    header("Location: /cocina.php?msg=updated");
    exit;
}

$stmt = $pdo->query("SELECT p.*, u.nombre_completo as cliente, e.$col_nombre as estado_nombre 
                     FROM pedidos p 
                     LEFT JOIN usuarios u ON p.id_usuario = u.id_usuario 
                     LEFT JOIN estados e ON p.id_estado = e.$col_id 
                     WHERE p.id_estado IN (1, 2) 
                     ORDER BY p.fecha_pedido ASC");
$pedidos_activos = $stmt->fetchAll();

$estados = $pdo->query("SELECT * FROM estados ORDER BY $col_id")->fetchAll();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Cocina - NexOrder</title>
    <style>
        body { font-family: system-ui, sans-serif; max-width: 1200px; margin: 0 auto; padding: 2rem; background: #f4f7fb; }
        .header { background: #0f172a; color: white; padding: 1rem 2rem; border-radius: 12px; margin-bottom: 2rem; display: flex; justify-content: space-between; align-items: center; }
        .header h1 { margin: 0; font-size: 1.5rem; }
        .nav a { color: white; text-decoration: none; margin-left: 1.5rem; }
        h2 { color: #1f2937; margin-bottom: 1.5rem; }
        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 1.5rem; }
        .card { background: white; border-radius: 12px; padding: 1.5rem; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
        .pedido-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; padding-bottom: 1rem; border-bottom: 2px solid #e5e7eb; }
        .pedido-info p { margin-bottom: 0.5rem; }
        .pedido-detalles { margin: 1rem 0; padding: 1rem; background: #f9fafb; border-radius: 8px; }
        .pedido-detalles ul { list-style: none; padding: 0; }
        .pedido-detalles li { padding: 0.25rem 0; }
        .form-estado { display: flex; gap: 0.5rem; margin-top: 1rem; }
        .form-estado select { flex: 1; padding: 0.5rem; border: 1px solid #d1d5db; border-radius: 6px; }
        .btn { padding: 0.5rem 1rem; background: #2563eb; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: 600; }
        .alert { padding: 1rem; border-radius: 6px; margin-bottom: 1rem; background: #d1fae5; color: #065f46; }
    </style>
</head>
<body>
    <header class="header">
        <h1>NexOrder - Cocina</h1>
        <nav class="nav">
            <a href="/">Inicio</a>
            <a href="/admin.php">Admin</a>
            <a href="/logout.php">Salir</a>
        </nav>
    </header>

    <?php if (isset($_GET["msg"])): ?>
        <div class="alert">Estado actualizado correctamente</div>
    <?php endif; ?>

    <h2>Pedidos en Cocina</h2>

    <?php if (empty($pedidos_activos)): ?>
        <div class="alert">No hay pedidos pendientes</div>
    <?php else: ?>
        <div class="grid">
            <?php foreach ($pedidos_activos as $pedido): ?>
                <div class="card">
                    <div class="pedido-header">
                        <h3>Pedido #<?= $pedido["id_pedido"] ?></h3>
                        <span><?= htmlspecialchars($pedido["estado_nombre"]) ?></span>
                    </div>
                    <div class="pedido-info">
                        <p><strong>Cliente:</strong> <?= htmlspecialchars($pedido["cliente"] ?? "Invitado") ?></p>
                        <p><strong>Hora:</strong> <?= date("H:i", strtotime($pedido["fecha_pedido"])) ?></p>
                        <p><strong>Total:</strong> <?= number_format($pedido["total"], 2, ",", ".") ?> €</p>
                        <?php if (!empty($pedido["notas"])): ?>
                            <p><strong>Notas:</strong> <?= htmlspecialchars($pedido["notas"]) ?></p>
                        <?php endif; ?>
                    </div>
                    <?php
                    $stmt = $pdo->prepare("SELECT dp.*, p.nombre FROM detalle_pedidos dp JOIN productos p ON dp.id_producto = p.id_producto WHERE dp.id_pedido = ?");
                    $stmt->execute([$pedido["id_pedido"]]);
                    $detalles = $stmt->fetchAll();
                    ?>
                    <div class="pedido-detalles">
                        <h4>Productos:</h4>
                        <ul>
                            <?php foreach ($detalles as $d): ?>
                                <li><?= $d["cantidad"] ?>x <?= htmlspecialchars($d["nombre"]) ?></li>
                            <?php endforeach; ?>
                        </ul>
                    </div>
                    <form method="POST" class="form-estado">
                        <input type="hidden" name="id_pedido" value="<?= $pedido["id_pedido"] ?>">
                        <select name="id_estado" required>
                            <?php foreach ($estados as $e): ?>
                                <option value="<?= $e[$col_id] ?>"><?= htmlspecialchars($e[$col_nombre]) ?></option>
                            <?php endforeach; ?>
                        </select>
                        <button type="submit" name="cambiar_estado" class="btn">Actualizar</button>
                    </form>
                </div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
</body>
</html>
