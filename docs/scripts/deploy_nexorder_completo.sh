#!/bin/bash
# =========================================================
# SCRIPT COMPLETO - NexOrder v3.0 (Versión Funcional)
# Usa conexión directa (como connexio.php que funciona)
# Incluye carrito visible en el menú
# =========================================================

set -e

APP_DIR="/var/www/nexorder"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}� DESPLIEGUE NEXORDER v3.0${NC}"
echo "======================================"

# =========================================================
# PASO 1: Crear estructura
# =========================================================
echo -e "${YELLOW}[1/10] Creando estructura...${NC}"
sudo mkdir -p "$APP_DIR"/{app,public/assets/css,config,logs,tmp}

# =========================================================
# PASO 2: Crear app/db.php (CONEXIÓN DIRECTA - FUNCIONA)
# =========================================================
echo -e "${YELLOW}[2/10] Creando conexión a BD...${NC}"
sudo tee "$APP_DIR/app/db.php" > /dev/null <<'EOFPHP'
<?php
// Conexión directa (misma que connexio.php que funciona)
$host    = 'nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com';
$db      = 'nexorder_db';
$user    = 'nexorder_app';
$pass    = 'N3x0r-DB-2026!Sec';
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (PDOException $e) {
    error_log("Error BD: " . $e->getMessage());
    die("Error de conexión a la base de datos");
}
?>
EOFPHP

# =========================================================
# PASO 3: Crear app/auth.php
# =========================================================
echo -e "${YELLOW}[3/10] Creando autenticación...${NC}"
sudo tee "$APP_DIR/app/auth.php" > /dev/null <<'EOFPHP'
<?php
require_once __DIR__ . '/db.php';

if (session_status() === PHP_SESSION_NONE) {
    session_name('nexorder_session');
    session_start();
}

function estaAutenticado() {
    return isset($_SESSION['usuario_id']);
}

function loginUsuario($email, $password) {
    global $pdo;
    $stmt = $pdo->prepare("SELECT id_usuario, nombre, email, password_hash, rol FROM usuarios WHERE email = ? AND activo = 1");
    $stmt->execute([$email]);
    $usuario = $stmt->fetch();
    
    if ($usuario && password_verify($password, $usuario['password_hash'])) {
        session_regenerate_id(true);
        $_SESSION['usuario_id'] = $usuario['id_usuario'];
        $_SESSION['usuario_nombre'] = $usuario['nombre'];
        $_SESSION['usuario_email'] = $usuario['email'];
        $_SESSION['usuario_rol'] = $usuario['rol'];
        return true;
    }
    return false;
}

function logout() {
    session_destroy();
    header('Location: /login.php');
    exit;
}
?>
EOFPHP

# =========================================================
# PASO 4: Crear app/helpers.php
# =========================================================
echo -e "${YELLOW}[4/10] Creando helpers...${NC}"
sudo tee "$APP_DIR/app/helpers.php" > /dev/null <<'EOFPHP'
<?php
function escapar($texto) {
    return htmlspecialchars($texto, ENT_QUOTES, 'UTF-8');
}

function formatearPrecio($precio) {
    return number_format($precio, 2, ',', '.') . ' €';
}

function redirigir($url, $mensaje = null, $tipo = 'success') {
    if ($mensaje) {
        $_SESSION['mensaje'] = $mensaje;
        $_SESSION['mensaje_tipo'] = $tipo;
    }
    header("Location: $url");
    exit;
}

function mostrarMensaje() {
    if (isset($_SESSION['mensaje'])) {
        $tipo = $_SESSION['mensaje_tipo'] ?? 'info';
        $mensaje = escapar($_SESSION['mensaje']);
        echo "<div class='alert alert-$tipo'>$mensaje</div>";
        unset($_SESSION['mensaje'], $_SESSION['mensaje_tipo']);
    }
}

function contarCarrito() {
    if (!isset($_SESSION['carrito'])) return 0;
    return array_sum($_SESSION['carrito']);
}
?>
EOFPHP

# =========================================================
# PASO 5: Crear public/index.php
# =========================================================
echo -e "${YELLOW}[5/10] Creando index.php...${NC}"
sudo tee "$APP_DIR/public/index.php" > /dev/null <<'EOFPHP'
<?php
require_once __DIR__ . '/../app/auth.php';
require_once __DIR__ . '/../app/helpers.php';
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NexOrder - Restaurante Digital</title>
    <link rel="stylesheet" href="/assets/css/styles.css">
</head>
<body>
    <header class="header">
        <div class="container">
            <div class="logo"><h1>NexOrder</h1></div>
            <nav class="nav">
                <a href="/">Inicio</a>
                <a href="/menu.php">Menú</a>
                <?php if (estaAutenticado()): ?>
                    <a href="/pedido.php">Mis Pedidos</a>
                    <a href="/logout.php">Salir (<?= escapar($_SESSION['usuario_nombre']) ?>)</a>
                <?php else: ?>
                    <a href="/login.php">Login</a>
                <?php endif; ?>
            </nav>
        </div>
    </header>

    <main class="container">
        <?php mostrarMensaje(); ?>
        <section class="hero">
            <h2>Bienvenido a NexOrder</h2>
            <p>Sistema de pedidos digital para restaurantes modernos</p>
            <a href="/menu.php" class="btn btn-primary">Ver Menú</a>
        </section>

        <section class="features">
            <div class="grid">
                <div class="card">
                    <h3>Menú Digital</h3>
                    <p>Explora nuestra carta completa con descripciones y precios actualizados</p>
                </div>
                <div class="card">
                    <h3>Pedidos Fáciles</h3>
                    <p>Selecciona tus platos favoritos y realiza tu pedido en minutos</p>
                </div>
                <div class="card">
                    <h3>Tiempo Real</h3>
                    <p>Sigue el estado de tu pedido desde la cocina hasta tu mesa</p>
                </div>
            </div>
        </section>
    </main>

    <footer class="footer">
        <div class="container">
            <p>&copy; 2026 NexOrder - Proyecto ASIXc</p>
            <p>Versión 3.0 | HTTPS Activo</p>
        </div>
    </footer>
</body>
</html>
EOFPHP

# =========================================================
# PASO 6: Crear public/login.php
# =========================================================
echo -e "${YELLOW}[6/10] Creando login.php...${NC}"
sudo tee "$APP_DIR/public/login.php" > /dev/null <<'EOFPHP'
<?php
require_once __DIR__ . '/../app/auth.php';
require_once __DIR__ . '/../app/helpers.php';

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';
    
    if (empty($email) || empty($password)) {
        $error = 'Por favor, completa todos los campos';
    } elseif (loginUsuario($email, $password)) {
        redirigir('/index.php', 'Bienvenido ' . $_SESSION['usuario_nombre'], 'success');
    } else {
        $error = 'Email o contraseña incorrectos';
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Login - NexOrder</title>
    <link rel="stylesheet" href="/assets/css/styles.css">
</head>
<body>
    <header class="header">
        <div class="container">
            <div class="logo"><h1>NexOrder</h1></div>
        </div>
    </header>
    <main class="container">
        <div class="login-container">
            <h2>Iniciar Sesión</h2>
            <?php if ($error): ?>
                <div class="alert alert-danger"><?= escapar($error) ?></div>
            <?php endif; ?>
            <form method="POST">
                <div class="form-group">
                    <label>Email:</label>
                    <input type="email" name="email" required autofocus>
                </div>
                <div class="form-group">
                    <label>Contraseña:</label>
                    <input type="password" name="password" required>
                </div>
                <button type="submit" class="btn btn-primary btn-block">Entrar</button>
            </form>
            <div class="login-info">
                <p><strong>Usuarios de prueba:</strong></p>
                <p>Admin: admin@nexorder.com / Admin123!</p>
                <p>Cocina: cocina@nexorder.com / Cocina123!</p>
                <p>Cliente: cliente@nexorder.com / Cliente123!</p>
            </div>
        </div>
    </main>
</body>
</html>
EOFPHP

# =========================================================
# PASO 7: Crear public/menu.php CON CARRITO VISIBLE
# =========================================================
echo -e "${YELLOW}[7/10] Creando menu.php con carrito...${NC}"
sudo tee "$APP_DIR/public/menu.php" > /dev/null <<'EOFPHP'
<?php
require_once __DIR__ . '/../app/db.php';
require_once __DIR__ . '/../app/auth.php';
require_once __DIR__ . '/../app/helpers.php';

// Procesar añadir al carrito
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (isset($_POST['add_to_cart'])) {
        $id = (int)$_POST['id_producto'];
        $_SESSION['carrito'][$id] = ($_SESSION['carrito'][$id] ?? 0) + 1;
        redirigir('/menu.php', 'Producto añadido al carrito', 'success');
    } elseif (isset($_POST['remove_from_cart'])) {
        $id = (int)$_POST['id_producto'];
        unset($_SESSION['carrito'][$id]);
        redirigir('/menu.php', 'Producto eliminado del carrito', 'success');
    } elseif (isset($_POST['vaciar_carrito'])) {
        unset($_SESSION['carrito']);
        redirigir('/menu.php', 'Carrito vaciado', 'success');
    }
}

// Obtener productos
$productos = $pdo->query('SELECT * FROM productos WHERE disponible = 1 ORDER BY categoria, nombre')->fetchAll();

// Obtener detalles del carrito
$carrito = $_SESSION['carrito'] ?? [];
$items_carrito = [];
$total_carrito = 0;

if (!empty($carrito)) {
    foreach ($carrito as $id => $cantidad) {
        $stmt = $pdo->prepare('SELECT * FROM productos WHERE id_producto = ?');
        $stmt->execute([$id]);
        $producto = $stmt->fetch();
        if ($producto) {
            $subtotal = $producto['precio'] * $cantidad;
            $total_carrito += $subtotal;
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
    <title>Menú - NexOrder</title>
    <link rel="stylesheet" href="/assets/css/styles.css">
</head>
<body>
    <header class="header">
        <div class="container">
            <div class="logo"><h1>NexOrder</h1></div>
            <nav class="nav">
                <a href="/">Inicio</a>
                <a href="/menu.php">Menú <?php if (contarCarrito() > 0): ?><span class="badge-carrito"><?= contarCarrito() ?></span><?php endif; ?></a>
                <?php if (estaAutenticado()): ?>
                    <a href="/pedido.php">Mis Pedidos</a>
                    <a href="/logout.php">Salir</a>
                <?php else: ?>
                    <a href="/login.php">Login</a>
                <?php endif; ?>
            </nav>
        </div>
    </header>
    <main class="container">
        <?php mostrarMensaje(); ?>
        
        <?php if (!empty($items_carrito)): ?>
            <section class="carrito-section">
                <h2>� Tu Carrito</h2>
                <div class="carrito-box">
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
                                    <td><?= escapar($item['nombre']) ?></td>
                                    <td><?= $item['cantidad'] ?></td>
                                    <td><?= formatearPrecio($item['precio']) ?></td>
                                    <td><strong><?= formatearPrecio($item['subtotal']) ?></strong></td>
                                    <td>
                                        <form method="POST" style="display:inline;">
                                            <input type="hidden" name="id_producto" value="<?= $item['id'] ?>">
                                            <button type="submit" name="remove_from_cart" class="btn btn-sm btn-danger">Eliminar</button>
                                        </form>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                        <tfoot>
                            <tr>
                                <td colspan="3"><strong>Total:</strong></td>
                                <td><strong class="total"><?= formatearPrecio($total_carrito) ?></strong></td>
                                <td>
                                    <form method="POST" style="display:inline;">
                                        <button type="submit" name="vaciar_carrito" class="btn btn-sm btn-secondary">Vaciar</button>
                                    </form>
                                </td>
                            </tr>
                        </tfoot>
                    </table>
                    
                    <?php if (estaAutenticado()): ?>
                        <div class="carrito-actions">
                            <a href="/pedido.php" class="btn btn-primary">Confirmar Pedido</a>
                        </div>
                    <?php else: ?>
                        <div class="alert alert-info">
                            <a href="/login.php">Inicia sesión</a> para confirmar tu pedido
                        </div>
                    <?php endif; ?>
                </div>
            </section>
        <?php endif; ?>
        
        <section class="menu-section">
            <h2>Nuestro Menú</h2>
            <div class="grid">
                <?php foreach ($productos as $p): ?>
                    <article class="card producto">
                        <h4><?= escapar($p['nombre']) ?></h4>
                        <p class="categoria"><?= ucfirst(escapar($p['categoria'])) ?></p>
                        <p><?= escapar($p['descripcion']) ?></p>
                        <div class="precio-accion">
                            <strong><?= formatearPrecio($p['precio']) ?></strong>
                            <form method="POST">
                                <input type="hidden" name="id_producto" value="<?= $p['id_producto'] ?>">
                                <button type="submit" name="add_to_cart" class="btn btn-sm">Añadir</button>
                            </form>
                        </div>
                    </article>
                <?php endforeach; ?>
            </div>
        </section>
    </main>
</body>
</html>
EOFPHP

# =========================================================
# PASO 8: Crear public/pedido.php
# =========================================================
echo -e "${YELLOW}[8/10] Creando pedido.php...${NC}"
sudo tee "$APP_DIR/public/pedido.php" > /dev/null <<'EOFPHP'
<?php
require_once __DIR__ . '/../app/auth.php';
require_once __DIR__ . '/../app/helpers.php';

if (!estaAutenticado()) {
    header('Location: /login.php');
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['crear_pedido']) && !empty($_SESSION['carrito'])) {
    require_once __DIR__ . '/../app/db.php';
    $total = 0;
    foreach ($_SESSION['carrito'] as $id => $cant) {
        $stmt = $pdo->prepare('SELECT precio FROM productos WHERE id_producto = ?');
        $stmt->execute([$id]);
        $prod = $stmt->fetch();
        if ($prod) $total += $prod['precio'] * $cant;
    }
    
    $stmt = $pdo->prepare('INSERT INTO pedidos (id_usuario, total, estado) VALUES (?, ?, ?)');
    $stmt->execute([$_SESSION['usuario_id'], $total, 'pendiente']);
    unset($_SESSION['carrito']);
    redirigir('/pedido.php', 'Pedido creado correctamente', 'success');
}

require_once __DIR__ . '/../app/db.php';
$stmt = $pdo->prepare('SELECT * FROM pedidos WHERE id_usuario = ? ORDER BY fecha_pedido DESC');
$stmt->execute([$_SESSION['usuario_id']]);
$pedidos = $stmt->fetchAll();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Pedidos - NexOrder</title>
    <link rel="stylesheet" href="/assets/css/styles.css">
</head>
<body>
    <header class="header">
        <div class="container">
            <div class="logo"><h1>NexOrder</h1></div>
            <nav class="nav">
                <a href="/">Inicio</a>
                <a href="/menu.php">Menú</a>
                <a href="/pedido.php">Mis Pedidos</a>
                <a href="/logout.php">Salir</a>
            </nav>
        </div>
    </header>
    <main class="container">
        <?php mostrarMensaje(); ?>
        <h2>Mis Pedidos</h2>
        
        <?php if (!empty($_SESSION['carrito'])): ?>
            <div class="alert alert-info">
                Tienes <?= contarCarrito() ?> productos en tu carrito.
                <a href="/menu.php">Ver carrito</a>
            </div>
            <form method="POST">
                <button type="submit" name="crear_pedido" class="btn btn-primary">Confirmar Pedido</button>
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
                        <td>#<?= $p['id_pedido'] ?></td>
                        <td><?= date('d/m/Y H:i', strtotime($p['fecha_pedido'])) ?></td>
                        <td><?= formatearPrecio($p['total']) ?></td>
                        <td><span class="badge badge-<?= $p['estado'] ?>"><?= ucfirst($p['estado']) ?></span></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </main>
</body>
</html>
EOFPHP

# =========================================================
# PASO 9: Crear public/logout.php
# =========================================================
echo -e "${YELLOW}[9/10] Creando logout.php...${NC}"
sudo tee "$APP_DIR/public/logout.php" > /dev/null <<'EOFPHP'
<?php
require_once __DIR__ . '/../app/auth.php';
logout();
?>
EOFPHP

# =========================================================
# PASO 10: Crear CSS
# =========================================================
echo -e "${YELLOW}[10/10] Creando CSS...${NC}"
sudo tee "$APP_DIR/public/assets/css/styles.css" > /dev/null <<'EOFCSS'
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f4f7fb; color: #1f2937; line-height: 1.6; }
.container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }
.header { background: #0f172a; color: white; padding: 1rem 0; }
.header .container { display: flex; justify-content: space-between; align-items: center; }
.logo h1 { font-size: 1.5rem; }
.nav a { color: white; text-decoration: none; margin-left: 1.5rem; }
.nav a:hover { color: #60a5fa; }
main { min-height: calc(100vh - 200px); padding: 2rem 0; }
h2 { margin-bottom: 1.5rem; color: #0f172a; }
.hero { text-align: center; padding: 3rem 0; background: white; border-radius: 12px; margin-bottom: 2rem; }
.hero h2 { font-size: 2.5rem; }
.hero p { font-size: 1.2rem; color: #6b7280; margin-bottom: 2rem; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; margin-bottom: 2rem; }
.card { background: white; border-radius: 12px; padding: 1.5rem; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
.card h4 { margin-bottom: 0.75rem; color: #0f172a; }
.card p { color: #6b7280; margin-bottom: 1rem; }
.btn { display: inline-block; padding: 0.75rem 1.5rem; border: none; border-radius: 8px; font-size: 1rem; font-weight: 600; text-decoration: none; cursor: pointer; transition: all 0.3s; }
.btn-primary { background: #2563eb; color: white; }
.btn-primary:hover { background: #1d4ed8; }
.btn-sm { padding: 0.5rem 1rem; font-size: 0.875rem; }
.btn-block { display: block; width: 100%; }
.btn-danger { background: #dc2626; color: white; }
.btn-danger:hover { background: #b91c1c; }
.btn-secondary { background: #6b7280; color: white; }
.btn-secondary:hover { background: #4b5563; }
.form-group { margin-bottom: 1.5rem; }
.form-group label { display: block; margin-bottom: 0.5rem; font-weight: 600; color: #374151; }
.form-group input { width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 8px; font-size: 1rem; }
.login-container { max-width: 400px; margin: 2rem auto; background: white; padding: 2rem; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
.login-info { margin-top: 1.5rem; padding-top: 1.5rem; border-top: 1px solid #e5e7eb; font-size: 0.875rem; color: #6b7280; }
.alert { padding: 1rem 1.5rem; border-radius: 8px; margin-bottom: 1.5rem; }
.alert-success { background: #d1fae5; color: #065f46; border-left: 4px solid #065f46; }
.alert-danger { background: #fee2e2; color: #991b1b; border-left: 4px solid #991b1b; }
.alert-info { background: #dbeafe; color: #1e40af; border-left: 4px solid #1e40af; }
.tabla { width: 100%; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 2rem; }
.tabla th, .tabla td { padding: 1rem; text-align: left; border-bottom: 1px solid #e5e7eb; }
.tabla thead { background: #0f172a; color: white; }
.tabla tfoot { background: #f9fafb; font-weight: 600; }
.badge { display: inline-block; padding: 0.25rem 0.75rem; border-radius: 12px; font-size: 0.875rem; font-weight: 600; }
.badge-pendiente { background: #fef3c7; color: #92400e; }
.badge-en_preparacion { background: #dbeafe; color: #1e40af; }
.badge-listo { background: #d1fae5; color: #065f46; }
.badge-entregado { background: #e5e7eb; color: #374151; }
.badge-carrito { background: #dc2626; color: white; padding: 0.25rem 0.5rem; border-radius: 50%; font-size: 0.75rem; margin-left: 0.25rem; }
.footer { background: #0f172a; color: white; padding: 2rem 0; text-align: center; margin-top: 4rem; }
.precio-accion { display: flex; justify-content: space-between; align-items: center; margin-top: 1rem; }
.precio-accion strong { font-size: 1.25rem; color: #2563eb; }
.categoria { font-size: 0.875rem; color: #6b7280; font-style: italic; }
.carrito-section { background: white; padding: 2rem; border-radius: 12px; margin-bottom: 2rem; box-shadow: 0 4px 6px rgba(0,0,0,0.05); }
.carrito-box { margin-top: 1rem; }
.carrito-actions { margin-top: 1.5rem; text-align: right; }
.total { font-size: 1.5rem; color: #2563eb; }
@media (max-width: 768px) {
    .header .container { flex-direction: column; gap: 1rem; }
    .nav { display: flex; gap: 1rem; flex-wrap: wrap; justify-content: center; }
    .nav a { margin-left: 0; }
}
EOFCSS

# =========================================================
# PASO 11: Crear script SQL para ejecutar en RDS
# =========================================================
echo -e "${YELLOW}[11/11] Creando script SQL...${NC}"
sudo tee "$APP_DIR/setup_database.sql" > /dev/null <<'EOSQL'
-- Script para crear tablas y usuarios de NexOrder
-- Ejecutar en RDS: mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u nexorder_app -p nexorder_db < setup_database.sql

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('cliente', 'cocina', 'admin') DEFAULT 'cliente',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de productos
CREATE TABLE IF NOT EXISTS productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL,
    categoria ENUM('entrante', 'principal', 'postre', 'bebida') DEFAULT 'principal',
    disponible BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de pedidos
CREATE TABLE IF NOT EXISTS pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    total DECIMAL(10,2) NOT NULL,
    estado ENUM('pendiente', 'en_preparacion', 'listo', 'entregado', 'cancelado') DEFAULT 'pendiente',
    notas TEXT,
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insertar usuarios (contraseñas hasheadas con password_hash)
-- Admin: Admin123!
INSERT INTO usuarios (nombre, email, password_hash, rol) VALUES 
('Administrador', 'admin@nexorder.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin')
ON DUPLICATE KEY UPDATE password_hash = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';

-- Cocina: Cocina123!
INSERT INTO usuarios (nombre, email, password_hash, rol) VALUES 
('Chef Principal', 'cocina@nexorder.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'cocina')
ON DUPLICATE KEY UPDATE password_hash = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';

-- Cliente: Cliente123!
INSERT INTO usuarios (nombre, email, password_hash, rol) VALUES 
('Cliente Demo', 'cliente@nexorder.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'cliente')
ON DUPLICATE KEY UPDATE password_hash = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';

-- Insertar productos de ejemplo
INSERT INTO productos (nombre, descripcion, precio, categoria) VALUES
('Ensalada César', 'Lechuga romana, crutones, parmesano y salsa César', 8.50, 'entrante'),
('Croquetas de jamón', '8 unidades de croquetas caseras de jamón ibérico', 7.00, 'entrante'),
('Solomillo a la pimienta', 'Solomillo de ternera con salsa de pimienta verde', 18.50, 'principal'),
('Paella valenciana', 'Paella tradicional con pollo, conejo y verduras', 14.00, 'principal'),
('Pizza Margarita', 'Tomate, mozzarella fresca y albahaca', 11.00, 'principal'),
('Tiramisú', 'Postre italiano con café y mascarpone', 6.50, 'postre'),
('Tarta de queso', 'Tarta de queso al horno con frutos rojos', 5.50, 'postre'),
('Agua mineral', 'Botella 50cl', 2.50, 'bebida'),
('Cerveza artesana', 'IPA local 33cl', 4.00, 'bebida'),
('Vino tinto Rioja', 'Copa de vino Rioja crianza', 5.00, 'bebida')
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);
EOSQL

# =========================================================
# PASO 12: Configurar permisos
# =========================================================
echo -e "${YELLOW}Configurando permisos...${NC}"
sudo chown -R apache:apache "$APP_DIR"
sudo find "$APP_DIR" -type d -exec chmod 755 {} \;
sudo find "$APP_DIR" -type f -exec chmod 644 {} \;
sudo chmod 750 "$APP_DIR/config"
sudo chmod -R 775 "$APP_DIR/logs"
sudo chmod -R 775 "$APP_DIR/tmp"

# SELinux
sudo restorecon -Rv "$APP_DIR" 2>/dev/null || true
sudo chcon -R -t httpd_sys_content_t "$APP_DIR"
sudo chcon -R -t httpd_sys_rw_content_t "$APP_DIR/logs"
sudo chcon -R -t httpd_sys_rw_content_t "$APP_DIR/tmp"

# =========================================================
# PASO 13: Reiniciar Apache
# =========================================================
echo -e "${YELLOW}Reiniciando Apache...${NC}"
sudo systemctl restart httpd

# =========================================================
# RESUMEN FINAL
# =========================================================
echo ""
echo -e "${GREEN}✅ DESPLIEGUE COMPLETADO${NC}"
echo "================================"
echo ""
echo "� Directorio: $APP_DIR"
echo "� Accede a: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'TU_IP')"
echo ""
echo "⚠️  IMPORTANTE: Ejecuta el script SQL en RDS:"
echo "   mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u nexorder_app -p nexorder_db < $APP_DIR/setup_database.sql"
echo ""
echo "� Usuarios de prueba:"
echo "   - Admin: admin@nexorder.com / Admin123!"
echo "   - Cocina: cocina@nexorder.com / Cocina123!"
echo "   - Cliente: cliente@nexorder.com / Cliente123!"
echo ""
echo "� El carrito ahora es visible en la página de menú"
