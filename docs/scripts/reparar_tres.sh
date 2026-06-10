#!/bin/bash
# =========================================================
# SCRIPT DE REPARACIÓN COMPLETA - cocina.php, pedido.php, admin.php
# Soluciona: verificarRol() + columnas reales de la BD
# =========================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🔧 REPARACIÓN COMPLETA - 3 archivos${NC}"
echo "============================================="

APP_DIR="/var/www/nexorder"

# =========================================================
# PASO 1: Crear app/db.php
# =========================================================
echo -e "${YELLOW}[1/7] Creando app/db.php...${NC}"

sudo mkdir -p "$APP_DIR/app"

sudo tee "$APP_DIR/app/db.php" > /dev/null <<'EOFPHP'
<?php
// NexOrder - Conexión a Base de Datos
$host = "nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com";
$db   = "nexorder_db";
$user = "nexorder_app";
$pass = "N3x0r-DB-2026!Sec";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
} catch (PDOException $e) {
    error_log("Error BD: " . $e->getMessage());
    die("Error de conexión a la base de datos");
}
?>
EOFPHP

echo "✅ app/db.php creado"

# =========================================================
# PASO 2: Crear app/auth.php con verificarRol()
# =========================================================
echo -e "${YELLOW}[2/7] Creando app/auth.php...${NC}"

sudo tee "$APP_DIR/app/auth.php" > /dev/null <<'EOFPHP'
<?php
// NexOrder - Autenticación y Autorización
require_once __DIR__ . "/db.php";

function iniciarSesion() {
    if (session_status() === PHP_SESSION_NONE) {
        session_name("nexorder_session");
        session_start();
    }
}

function estaAutenticado() {
    iniciarSesion();
    return isset($_SESSION["usuario_id"]);
}

function verificarRol($roles_permitidos) {
    iniciarSesion();
    if (!estaAutenticado()) {
        header("Location: /login.php");
        exit;
    }
    if (!in_array($_SESSION["usuario_rol"], (array)$roles_permitidos)) {
        header("Location: /index.php?error=acceso_denegado");
        exit;
    }
}

function loginUsuario($email, $password) {
    global $pdo;
    $stmt = $pdo->prepare("SELECT id_usuario, username, email, nombre_completo, password_hash, rol FROM usuarios WHERE (email = ? OR username = ?) AND activo = 1");
    $stmt->execute([$email, $email]);
    $usuario = $stmt->fetch();
    
    if ($usuario && password_verify($password, $usuario["password_hash"])) {
        session_regenerate_id(true);
        $_SESSION["usuario_id"] = $usuario["id_usuario"];
        $_SESSION["usuario_nombre"] = $usuario["nombre_completo"];
        $_SESSION["usuario_username"] = $usuario["username"];
        $_SESSION["usuario_email"] = $usuario["email"];
        $_SESSION["usuario_rol"] = $usuario["rol"];
        return true;
    }
    return false;
}

function logout() {
    iniciarSesion();
    session_destroy();
    header("Location: /login.php");
    exit;
}
?>
EOFPHP

echo "✅ app/auth.php creado (con verificarRol)"

# =========================================================
# PASO 3: Crear app/helpers.php
# =========================================================
echo -e "${YELLOW}[3/7] Creando app/helpers.php...${NC}"

sudo tee "$APP_DIR/app/helpers.php" > /dev/null <<'EOFPHP'
<?php
function escapar($texto) {
    return htmlspecialchars($texto, ENT_QUOTES, "UTF-8");
}

function formatearPrecio($precio) {
    return number_format($precio, 2, ",", ".") . " €";
}

function redirigir($url, $mensaje = null, $tipo = "success") {
    if ($mensaje) {
        $_SESSION["mensaje"] = $mensaje;
        $_SESSION["mensaje_tipo"] = $tipo;
    }
    header("Location: $url");
    exit;
}

function mostrarMensaje() {
    if (isset($_SESSION["mensaje"])) {
        $tipo = $_SESSION["mensaje_tipo"] ?? "info";
        $mensaje = escapar($_SESSION["mensaje"]);
        echo "<div class='alert alert-$tipo'>$mensaje</div>";
        unset($_SESSION["mensaje"], $_SESSION["mensaje_tipo"]);
    }
}

function contarCarrito() {
    if (!isset($_SESSION["carrito"])) return 0;
    return array_sum($_SESSION["carrito"]);
}
?>
EOFPHP

echo "✅ app/helpers.php creado"

# =========================================================
# PASO 4: Reescribir cocina.php (usa id_estado y tabla estados)
# =========================================================
echo -e "${YELLOW}[4/7] Reescribiendo cocina.php...${NC}"

sudo tee "$APP_DIR/public/cocina.php" > /dev/null <<'EOFPHP'
<?php
// NexOrder - Panel de Cocina
require_once __DIR__ . "/../app/auth.php";
require_once __DIR__ . "/../app/helpers.php";
verificarRol(["cocina", "admin"]);

// Cambiar estado de pedido
if ($_SERVER["REQUEST_METHOD"] === "POST" && isset($_POST["cambiar_estado"])) {
    $id_pedido = (int)$_POST["id_pedido"];
    $nuevo_estado = (int)$_POST["id_estado"];
    
    $stmt = $pdo->prepare("UPDATE pedidos SET id_estado = ? WHERE id_pedido = ?");
    $stmt->execute([$nuevo_estado, $id_pedido]);
    header("Location: /cocina.php?msg=updated");
    exit;
}

// Obtener pedidos activos (estados 1=Pendiente, 2=En preparación)
$stmt = $pdo->query("SELECT p.*, u.nombre_completo as cliente, e.nombre_estado 
                     FROM pedidos p 
                     LEFT JOIN usuarios u ON p.id_usuario = u.id_usuario 
                     LEFT JOIN estados e ON p.id_estado = e.id_estado 
                     WHERE p.id_estado IN (1, 2) 
                     ORDER BY p.fecha_pedido ASC");
$pedidos_activos = $stmt->fetchAll();

// Obtener todos los estados
$estados = $pdo->query("SELECT * FROM estados ORDER BY id_estado")->fetchAll();
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
                        <span><?= htmlspecialchars($pedido["nombre_estado"]) ?></span>
                    </div>
                    <div class="pedido-info">
                        <p><strong>Cliente:</strong> <?= htmlspecialchars($pedido["cliente"] ?? "Invitado") ?></p>
                        <p><strong>Hora:</strong> <?= date("H:i", strtotime($pedido["fecha_pedido"])) ?></p>
                        <p><strong>Total:</strong> <?= number_format($pedido["total"], 2, ",", ".") ?> €</p>
                        <?php if ($pedido["notas"]): ?>
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
                                <option value="<?= $e["id_estado"] ?>"><?= htmlspecialchars($e["nombre_estado"]) ?></option>
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
EOFPHP

echo "✅ cocina.php reescrito"

# =========================================================
# PASO 5: Reescribir pedido.php (usa id_estado en lugar de estado)
# =========================================================
echo -e "${YELLOW}[5/7] Reescribiendo pedido.php...${NC}"

sudo tee "$APP_DIR/public/pedido.php" > /dev/null <<'EOFPHP'
<?php
// NexOrder - Mis Pedidos
require_once __DIR__ . "/../app/auth.php";
require_once __DIR__ . "/../app/helpers.php";
verificarRol(["cliente"]);

// Crear pedido
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
        
        // id_estado = 1 (Pendiente)
        $stmt = $pdo->prepare("INSERT INTO pedidos (id_usuario, id_estado, total, notas) VALUES (?, 1, ?, ?)");
        $stmt->execute([$_SESSION["usuario_id"], $total, $_POST["notas"] ?? ""]);
        $id_pedido = $pdo->lastInsertId();
        
        // Crear detalles
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

// Obtener pedidos del usuario con JOIN a estados
$stmt = $pdo->prepare("SELECT p.*, e.nombre_estado FROM pedidos p LEFT JOIN estados e ON p.id_estado = e.id_estado WHERE p.id_usuario = ? ORDER BY p.fecha_pedido DESC");
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
        .badge { display: inline-block; padding: 0.25rem 0.75rem; border-radius: 12px; font-size: 0.875rem; font-weight: 600; }
        .badge-pendiente { background: #fef3c7; color: #92400e; }
        .badge-en_preparacion { background: #dbeafe; color: #1e40af; }
        .badge-listo { background: #d1fae5; color: #065f46; }
        .badge-entregado { background: #e5e7eb; color: #374151; }
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
            <div class="alert alert-success">Pedido creado correctamente</div>
        <?php elseif ($_GET["msg"] === "error"): ?>
            <div class="alert alert-danger">Error al crear el pedido</div>
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
            <tr>
                <th>ID</th>
                <th>Fecha</th>
                <th>Total</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($pedidos as $p): ?>
                <tr>
                    <td>#<?= $p["id_pedido"] ?></td>
                    <td><?= date("d/m/Y H:i", strtotime($p["fecha_pedido"])) ?></td>
                    <td><?= number_format($p["total"], 2, ",", ".") ?> €</td>
                    <td><span class="badge badge-<?= str_replace("_", "-", $p["nombre_estado"] ?? "pendiente") ?>"><?= htmlspecialchars($p["nombre_estado"] ?? "Pendiente") ?></span></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</body>
</html>
EOFPHP

echo "✅ pedido.php reescrito"

# =========================================================
# PASO 6: Reescribir admin.php
# =========================================================
echo -e "${YELLOW}[6/7] Reescribiendo admin.php...${NC}"

sudo tee "$APP_DIR/public/admin.php" > /dev/null <<'EOFPHP'
<?php
// NexOrder - Panel de Administración
require_once __DIR__ . "/../app/auth.php";
require_once __DIR__ . "/../app/helpers.php";
verificarRol(["admin"]);

// Estadísticas
$total_pedidos = $pdo->query("SELECT COUNT(*) as total FROM pedidos")->fetch()["total"];
$total_usuarios = $pdo->query("SELECT COUNT(*) as total FROM usuarios WHERE activo = 1")->fetch()["total"];
$total_productos = $pdo->query("SELECT COUNT(*) as total FROM productos WHERE disponible = 1")->fetch()["total"];
$ingresos = $pdo->query("SELECT COALESCE(SUM(total), 0) as total FROM pedidos")->fetch()["total"];

// Últimos pedidos
$stmt = $pdo->query("SELECT p.*, u.nombre_completo as cliente, e.nombre_estado 
                     FROM pedidos p 
                     LEFT JOIN usuarios u ON p.id_usuario = u.id_usuario 
                     LEFT JOIN estados e ON p.id_estado = e.id_estado 
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
        .badge { display: inline-block; padding: 0.25rem 0.75rem; border-radius: 12px; font-size: 0.875rem; font-weight: 600; }
        .badge-pendiente { background: #fef3c7; color: #92400e; }
        .badge-en_preparacion { background: #dbeafe; color: #1e40af; }
        .badge-listo { background: #d1fae5; color: #065f46; }
        .badge-entregado { background: #e5e7eb; color: #374151; }
    </style>
</head>
<body>
    <header class="header">
        <h1>NexOrder - Admin</h1>
        <nav class="nav">
            <a href="/">Inicio</a>
            <a href="/logout.php">Salir</a>
        </nav>
    </header>

    <h2>Panel de Administración</h2>

    <div class="grid">
        <div class="stat-card">
            <h3><?= $total_pedidos ?></h3>
            <p>Pedidos Totales</p>
        </div>
        <div class="stat-card">
            <h3><?= $total_usuarios ?></h3>
            <p>Usuarios Activos</p>
        </div>
        <div class="stat-card">
            <h3><?= $total_productos ?></h3>
            <p>Productos Disponibles</p>
        </div>
        <div class="stat-card">
            <h3><?= number_format($ingresos, 2, ",", ".") ?> €</h3>
            <p>Ingresos Totales</p>
        </div>
    </div>

    <h3>Últimos Pedidos</h3>
    <table class="tabla">
        <thead>
            <tr>
                <th>ID</th>
                <th>Cliente</th>
                <th>Fecha</th>
                <th>Total</th>
                <th>Estado</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($ultimos_pedidos as $p): ?>
                <tr>
                    <td>#<?= $p["id_pedido"] ?></td>
                    <td><?= htmlspecialchars($p["cliente"] ?? "Invitado") ?></td>
                    <td><?= date("d/m/Y H:i", strtotime($p["fecha_pedido"])) ?></td>
                    <td><?= number_format($p["total"], 2, ",", ".") ?> €</td>
                    <td><span class="badge badge-<?= str_replace("_", "-", $p["nombre_estado"] ?? "pendiente") ?>"><?= htmlspecialchars($p["nombre_estado"] ?? "Pendiente") ?></span></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</body>
</html>
EOFPHP

echo "✅ admin.php reescrito"

# =========================================================
# PASO 7: Permisos y reinicio
# =========================================================
echo -e "${YELLOW}[7/7] Configurando permisos y reiniciando...${NC}"

sudo chown -R apache:apache "$APP_DIR/app"
sudo find "$APP_DIR/app" -type d -exec chmod 755 {} \;
sudo find "$APP_DIR/app" -type f -exec chmod 644 {} \;

sudo chown apache:apache "$APP_DIR/public/cocina.php"
sudo chown apache:apache "$APP_DIR/public/pedido.php"
sudo chown apache:apache "$APP_DIR/public/admin.php"
sudo chmod 644 "$APP_DIR/public/cocina.php"
sudo chmod 644 "$APP_DIR/public/pedido.php"
sudo chmod 644 "$APP_DIR/public/admin.php"

sudo restorecon -Rv "$APP_DIR/app" 2>/dev/null || true
sudo restorecon -Rv "$APP_DIR/public" 2>/dev/null || true
sudo chcon -R -t httpd_sys_content_t "$APP_DIR/app" 2>/dev/null || true
sudo chcon -R -t httpd_sys_content_t "$APP_DIR/public" 2>/dev/null || true

sudo systemctl restart httpd

echo ""
echo -e "${GREEN}✅ REPARACIÓN COMPLETA${NC}"
echo "================================"
echo ""
echo "📋 Archivos reparados:"
echo "   ✅ app/db.php - Conexión a BD"
echo "   ✅ app/auth.php - Función verificarRol() + login"
echo "   ✅ app/helpers.php - Funciones auxiliares"
echo "   ✅ public/cocina.php - Usa id_estado y tabla estados"
echo "   ✅ public/pedido.php - Usa id_estado (no 'estado')"
echo "   ✅ public/admin.php - Usa verificarRol() correctamente"
echo ""
echo "🔗 Prueba ahora:"
echo "   https://44.207.176.14/admin.php"
echo "   https://44.207.176.14/cocina.php"
echo "   https://44.207.176.14/pedido.php"
echo ""
echo "📋 Usuarios:"
echo "   - admin / Admin123!"
echo "   - cocina1 / Cocina123!"
echo "   - cliente1 / Cliente123!"
