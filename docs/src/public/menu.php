<?php
// NexOrder - Menú con Cesta Visible
require_once __DIR__ . "/../app/db.php";
require_once __DIR__ . "/../app/auth.php";
require_once __DIR__ . "/../app/helpers.php";

iniciarSesion();

// Procesar acciones del carrito
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['add_to_cart'])) {
        $id = (int)$_POST['id_producto'];
        $_SESSION['carrito'][$id] = ($_SESSION['carrito'][$id] ?? 0) + 1;
        header('Location: /menu.php?msg=added');
        exit;
    } elseif (isset($_POST['remove_from_cart'])) {
        $id = (int)$_POST['id_producto'];
        unset($_SESSION['carrito'][$id]);
        header('Location: /menu.php?msg=removed');
        exit;
    } elseif (isset($_POST['vaciar_carrito'])) {
        unset($_SESSION['carrito']);
        header('Location: /menu.php?msg=cleared');
        exit;
    }
}

// Obtener productos
$productos = $pdo->query('SELECT * FROM productos WHERE disponible = 1 ORDER BY categoria, nombre')->fetchAll();

// Calcular carrito
$carrito = $_SESSION['carrito'] ?? [];
$items_carrito = [];
$total_carrito = 0;
$total_items = 0;

if (!empty($carrito)) {
    foreach ($carrito as $id => $cantidad) {
        $stmt = $pdo->prepare('SELECT * FROM productos WHERE id_producto = ?');
        $stmt->execute([$id]);
        $producto = $stmt->fetch();
        if ($producto) {
            $subtotal = $producto['precio'] * $cantidad;
            $total_carrito += $subtotal;
            $total_items += $cantidad;
            $items_carrito[] = [
                'id' => $producto['id_producto'],
                'nombre' => $producto['nombre'],
                'cantidad' => $cantidad,
                'precio' => $producto['precio'],
                'subtotal' => $subtotal
            ];
        }
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Menú - NexOrder</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: system-ui, sans-serif; background: #f4f7fb; }
        .header { background: #0f172a; color: white; padding: 1rem 2rem; }
        .header-content { max-width: 1200px; margin: 0 auto; display: flex; justify-content: space-between; align-items: center; }
        .logo h1 { font-size: 1.5rem; }
        .nav a { color: white; text-decoration: none; margin-left: 1.5rem; }
        .nav a:hover { color: #60a5fa; }
        .container { max-width: 1200px; margin: 0 auto; padding: 2rem; }
        h2 { color: #1f2937; margin-bottom: 1.5rem; }
        
        /* CESTA VISIBLE - Siempre visible */
        .cesta-container { 
            background: white; 
            padding: 1.5rem; 
            border-radius: 12px; 
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            margin-bottom: 2rem;
            border: 2px solid #2563eb;
        }
        .cesta-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1rem;
            padding-bottom: 1rem;
            border-bottom: 2px solid #e5e7eb;
        }
        .cesta-header h3 { color: #1f2937; font-size: 1.5rem; }
        .cesta-total { font-size: 1.25rem; color: #2563eb; font-weight: bold; }
        .tabla { width: 100%; border-collapse: collapse; }
        .tabla th, .tabla td { padding: 0.75rem; text-align: left; border-bottom: 1px solid #e5e7eb; }
        .tabla th { background: #f9fafb; font-weight: 600; }
        .btn { display: inline-block; padding: 0.5rem 1rem; border: none; border-radius: 6px; font-weight: 600; cursor: pointer; text-decoration: none; }
        .btn-danger { background: #dc2626; color: white; }
        .btn-secondary { background: #6b7280; color: white; }
        .btn-primary { background: #2563eb; color: white; }
        .btn-sm { padding: 0.25rem 0.75rem; font-size: 0.875rem; }
        .alert { padding: 1rem; border-radius: 6px; margin-bottom: 1rem; }
        .alert-success { background: #d1fae5; color: #065f46; }
        .alert-info { background: #dbeafe; color: #1e40af; }
        .empty-cart { color: #6b7280; font-style: italic; padding: 1rem; text-align: center; }
        
        /* Grid de productos */
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.5rem; }
        .card { background: white; border-radius: 12px; padding: 1.5rem; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
        .card h4 { color: #1f2937; margin-bottom: 0.5rem; }
        .categoria { color: #6b7280; font-size: 0.875rem; font-style: italic; margin-bottom: 0.5rem; }
        .descripcion { color: #6b7280; margin-bottom: 1rem; }
        .precio-accion { display: flex; justify-content: space-between; align-items: center; }
        .precio { font-size: 1.25rem; color: #2563eb; font-weight: bold; }
        .cesta-actions { margin-top: 1.5rem; text-align: right; }
    </style>
</head>
<body>
    <header class="header">
        <div class="header-content">
            <div class="logo"><h1>NexOrder</h1></div>
            <nav class="nav">
                <a href="/">Inicio</a>
                <a href="/menu.php">Menú</a>
                <?php if (estaAutenticado()): ?>
                    <a href="/pedido.php">Mis Pedidos</a>
                    <a href="/logout.php">Salir</a>
                <?php else: ?>
                    <a href="/login.php">Login</a>
                <?php endif; ?>
            </nav>
        </div>
    </header>

    <div class="container">
        <?php if (isset($_GET['msg'])): ?>
            <?php if ($_GET['msg'] === 'added'): ?>
                <div class="alert alert-success">✅ Producto añadido a la cesta</div>
            <?php elseif ($_GET['msg'] === 'removed'): ?>
                <div class="alert alert-info">Producto eliminado de la cesta</div>
            <?php elseif ($_GET['msg'] === 'cleared'): ?>
                <div class="alert alert-info">Cesta vaciada</div>
            <?php endif; ?>
        <?php endif; ?>

        <!-- CESTA SIEMPRE VISIBLE -->
        <div class="cesta-container">
            <div class="cesta-header">
                <h3>🛒 Tu Cesta (<?= $total_items ?> productos)</h3>
                <div class="cesta-total">Total: <?= number_format($total_carrito, 2, ',', '.') ?> €</div>
            </div>
            
            <?php if (empty($items_carrito)): ?>
                <div class="empty-cart">
                    <p>🛒 Tu cesta está vacía</p>
                    <p style="font-size: 0.875rem; margin-top: 0.5rem;">Añade productos del menú de abajo</p>
                </div>
            <?php else: ?>
                <table class="tabla">
                    <thead>
                        <tr>
                            <th>Producto</th>
                            <th>Cantidad</th>
                            <th>Precio</th>
                            <th>Subtotal</th>
                            <th>Acción</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($items_carrito as $item): ?>
                            <tr>
                                <td><?= htmlspecialchars($item['nombre']) ?></td>
                                <td><?= $item['cantidad'] ?></td>
                                <td><?= number_format($item['precio'], 2, ',', '.') ?> €</td>
                                <td><strong><?= number_format($item['subtotal'], 2, ',', '.') ?> €</strong></td>
                                <td>
                                    <form method="POST" style="display:inline;">
                                        <input type="hidden" name="id_producto" value="<?= $item['id'] ?>">
                                        <button type="submit" name="remove_from_cart" class="btn btn-danger btn-sm">Eliminar</button>
                                    </form>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
                
                <div class="cesta-actions">
                    <form method="POST" style="display:inline;">
                        <button type="submit" name="vaciar_carrito" class="btn btn-secondary">Vaciar Cesta</button>
                    </form>
                    <?php if (estaAutenticado()): ?>
                        <a href="/pedido.php" class="btn btn-primary">Confirmar Pedido</a>
                    <?php else: ?>
                        <a href="/login.php" class="btn btn-primary">Inicia sesión para confirmar</a>
                    <?php endif; ?>
                </div>
            <?php endif; ?>
        </div>

        <!-- MENÚ DE PRODUCTOS -->
        <h2>Nuestro Menú</h2>
        <div class="grid">
            <?php foreach ($productos as $p): ?>
                <article class="card">
                    <h4><?= htmlspecialchars($p['nombre']) ?></h4>
                    <p class="categoria"><?= ucfirst(htmlspecialchars($p['categoria'])) ?></p>
                    <p class="descripcion"><?= htmlspecialchars($p['descripcion']) ?></p>
                    <div class="precio-accion">
                        <span class="precio"><?= number_format($p['precio'], 2, ',', '.') ?> €</span>
                        <form method="POST">
                            <input type="hidden" name="id_producto" value="<?= $p['id_producto'] ?>">
                            <button type="submit" name="add_to_cart" class="btn btn-primary btn-sm">Añadir</button>
                        </form>
                    </div>
                </article>
            <?php endforeach; ?>
        </div>
    </div>
</body>
</html>
