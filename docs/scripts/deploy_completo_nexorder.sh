#!/bin/bash
# =========================================================
# SCRIPT COMPLETO DE DESPLIEGUE - NexOrder v2.0
# Crea estructura, archivos, configura y despliega TODO
# =========================================================

set -e

APP_DIR="/var/www/nexorder"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}� DESPLIEGUE COMPLETO DE NEXORDER v2.0${NC}"
echo "================================================"

# =========================================================
# PASO 1: Crear estructura de directorios
# =========================================================
echo -e "${YELLOW}[1/8] Creando estructura de directorios...${NC}"
sudo mkdir -p "$APP_DIR"/{app,public/assets/{css,js,images},config,logs,tmp}

# =========================================================
# PASO 2: Crear archivo .env
# =========================================================
echo -e "${YELLOW}[2/8] Creando configuración .env...${NC}"
sudo tee "$APP_DIR/config/.env" > /dev/null <<'EOF'
DB_HOST=nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com
DB_USER=nexorder_app
DB_PASS=N3x0r-DB-2026!Sec
DB_NAME=nexorder_db
SESSION_NAME=nexorder_session
SESSION_LIFETIME=3600
SESSION_SECURE=1
SESSION_HTTPONLY=1
APP_NAME=NexOrder
APP_ENV=production
APP_DEBUG=0
EOF

# =========================================================
# PASO 3: Crear archivos de la carpeta app/
# =========================================================
echo -e "${YELLOW}[3/8] Creando archivos de aplicación (app/)...${NC}"

# app/db.php
sudo tee "$APP_DIR/app/db.php" > /dev/null <<'EOFPHP'
<?php
function loadEnv($path) {
    if (!file_exists($path)) {
        throw new Exception('Archivo .env no encontrado');
    }
    foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        if (str_starts_with(trim($line), '#')) continue;
        [$name, $value] = array_map('trim', explode('=', $line, 2));
        $_ENV[$name] = $value;
    }
}

loadEnv(__DIR__ . '/../config/.env');
$dsn = 'mysql:host=' . $_ENV['DB_HOST'] . ';dbname=' . $_ENV['DB_NAME'] . ';charset=utf8mb4';

try {
    $pdo = new PDO($dsn, $_ENV['DB_USER'], $_ENV['DB_PASS'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $e) {
    error_log("Error de conexión a BD: " . $e->getMessage());
    throw new Exception("Error de conexión a la base de datos");
}
?>
EOFPHP

# app/auth.php
sudo tee "$APP_DIR/app/auth.php" > /dev/null <<'EOFPHP'
<?php
require_once __DIR__ . '/db.php';

function iniciarSesionSegura() {
    if (session_status() === PHP_SESSION_NONE) {
        ini_set('session.cookie_httponly', 1);
        ini_set('session.cookie_secure', $_ENV['SESSION_SECURE'] ?? 1);
        ini_set('session.use_strict_mode', 1);
        session_name($_ENV['SESSION_NAME'] ?? 'nexorder_session');
        session_start();
    }
}

function estaAutenticado() {
    iniciarSesionSegura();
    return isset($_SESSION['usuario_id']) && isset($_SESSION['usuario_rol']);
}

function verificarRol($roles_permitidos) {
    iniciarSesionSegura();
    if (!estaAutenticado()) {
        header('Location: /login.php');
        exit;
    }
    if (!in_array($_SESSION['usuario_rol'], (array)$roles_permitidos)) {
        header('Location: /index.php?error=acceso_denegado');
        exit;
    }
}

function loginUsuario($email, $password) {
    global $pdo;
    $stmt = $pdo->prepare("SELECT id_usuario, nombre, email, password_hash, rol, activo FROM usuarios WHERE email = ? AND activo = 1");
    $stmt->execute([$email]);
    $usuario = $stmt->fetch();
    
    if ($usuario && password_verify($password, $usuario['password_hash'])) {
        iniciarSesionSegura();
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
    iniciarSesionSegura();
    session_destroy();
    header('Location: /login.php');
    exit;
}

function obtenerUsuarioActual() {
    iniciarSesionSegura();
    if (!estaAutenticado()) return null;
    return [
        'id' => $_SESSION['usuario_id'],
        'nombre' => $_SESSION['usuario_nombre'],
        'email' => $_SESSION['usuario_email'],
        'rol' => $_SESSION['usuario_rol']
    ];
}
?>
EOFPHP

# app/csrf.php
sudo tee "$APP_DIR/app/csrf.php" > /dev/null <<'EOFPHP'
<?php
function generarTokenCSRF() {
    if (session_status() === PHP_SESSION_NONE) session_start();
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function verificarTokenCSRF($token) {
    if (session_status() === PHP_SESSION_NONE) session_start();
    return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
}

function campoCSRF() {
    return '<input type="hidden" name="csrf_token" value="' . generarTokenCSRF() . '">';
}
?>
EOFPHP

# app/helpers.php
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

function obtenerEstadoBadge($estado) {
    $colores = [
        'pendiente' => 'warning',
        'en_preparacion' => 'info',
        'listo' => 'success',
        'entregado' => 'secondary',
        'cancelado' => 'danger'
    ];
    $color = $colores[$estado] ?? 'secondary';
    return "<span class='badge bg-$color'>" . ucfirst(str_replace('_', ' ', $estado)) . "</span>";
}
?>
EOFPHP

# =========================================================
# PASO 4: Crear archivos públicos principales
# =========================================================
echo -e "${YELLOW}[4/8] Creando archivos públicos...${NC}"

# public/index.php
sudo tee "$APP_DIR/public/index.php" > /dev/null <<'EOFPHP'
<?php
require_once __DIR__ . '/../app/auth.php';
require_once __DIR__ . '/../app/helpers.php';
iniciarSesionSegura();
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
                    <?php if ($_SESSION['usuario_rol'] === 'cocina'): ?>
                        <a href="/cocina.php">Cocina</a>
                    <?php elseif ($_SESSION['usuario_rol'] === 'admin'): ?>
                        <a href="/admin.php">Administración</a>
                    <?php endif; ?>
                    <a href="/logout.php">Cerrar Sesión</a>
                <?php else: ?>
                    <a href="/login.php">Iniciar Sesión</a>
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
            <p>Versión 2.0 | HTTPS Activo</p>
        </div>
    </footer>
</body>
</html>
EOFPHP

# public/login.php (versión simplificada)
sudo tee "$APP_DIR/public/login.php" > /dev/null <<'EOFPHP'
<?php
require_once __DIR__ . '/../app/auth.php';
require_once __DIR__ . '/../app/csrf.php';
require_once __DIR__ . '/../app/helpers.php';

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!verificarTokenCSRF($_POST['csrf_token'] ?? '')) {
        $error = 'Error de seguridad';
    } else {
        $email = filter_input(INPUT_POST, 'email', FILTER_VALIDATE_EMAIL);
        $password = $_POST['password'] ?? '';
        if ($email && $password && loginUsuario($email, $password)) {
            redirigir('/index.php', 'Bienvenido ' . $_SESSION['usuario_nombre'], 'success');
        } else {
            $error = 'Email o contraseña incorrectos';
        }
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - NexOrder</title>
    <link rel="stylesheet" href="/assets/css/styles.css">
</head>
<body>
    <header class="header"><div class="container"><div class="logo"><h1>NexOrder</h1></div></div></header>
    <main class="container">
        <div class="login-container">
            <h2>Iniciar Sesión</h2>
            <?php if ($error): ?><div class="alert alert-danger"><?= escapar($error) ?></div><?php endif; ?>
            <form method="POST" class="form-login">
                <?= campoCSRF() ?>
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
                <p><strong>Usuarios:</strong></p>
                <p>Admin: admin@nexorder.com / Admin123!</p>
                <p>Cocina: cocina@nexorder.com / Cocina123!</p>
            </div>
        </div>
    </main>
</body>
</html>
EOFPHP

# public/logout.php
sudo tee "$APP_DIR/public/logout.php" > /dev/null <<'EOFPHP'
<?php
require_once __DIR__ . '/../app/auth.php';
logout();
?>
EOFPHP

# public/menu.php (versión simplificada)
sudo tee "$APP_DIR/public/menu.php" > /dev/null <<'EOFPHP'
<?php
require_once __DIR__ . '/../app/db.php';
require_once __DIR__ . '/../app/auth.php';
require_once __DIR__ . '/../app/helpers.php';
iniciarSesionSegura();

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['add_to_cart'])) {
    $id_producto = filter_input(INPUT_POST, 'id_producto', FILTER_VALIDATE_INT);
    if ($id_producto) {
        $_SESSION['carrito'][$id_producto] = ($_SESSION['carrito'][$id_producto] ?? 0) + 1;
        redirigir('/menu.php', 'Producto añadido', 'success');
    }
}

$stmt = $pdo->query('SELECT id_producto, nombre, descripcion, precio, categoria FROM productos WHERE disponible = 1 ORDER BY categoria, nombre');
$productos = $stmt->fetchAll();
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
                <a href="/menu.php">Menú</a>
                <?php if (estaAutenticado()): ?>
                    <a href="/pedido.php">Pedidos</a>
                    <a href="/logout.php">Salir</a>
                <?php else: ?>
                    <a href="/login.php">Login</a>
                <?php endif; ?>
            </nav>
        </div>
    </header>
    <main class="container">
        <?php mostrarMensaje(); ?>
        <h2>Nuestro Menú</h2>
        <div class="grid">
            <?php foreach ($productos as $p): ?>
                <article class="card producto">
                    <h4><?= escapar($p['nombre']) ?></h4>
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
    </main>
</body>
</html>
EOFPHP

# =========================================================
# PASO 5: Crear CSS
# =========================================================
echo -e "${YELLOW}[5/8] Creando estilos CSS...${NC}"

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
.card h3, .card h4 { margin-bottom: 0.75rem; color: #0f172a; }
.card p { color: #6b7280; margin-bottom: 1rem; }
.btn { display: inline-block; padding: 0.75rem 1.5rem; border: none; border-radius: 8px; font-size: 1rem; font-weight: 600; text-decoration: none; cursor: pointer; }
.btn-primary { background: #2563eb; color: white; }
.btn-primary:hover { background: #1d4ed8; }
.btn-sm { padding: 0.5rem 1rem; font-size: 0.875rem; }
.btn-block { display: block; width: 100%; }
.form-group { margin-bottom: 1.5rem; }
.form-group label { display: block; margin-bottom: 0.5rem; font-weight: 600; }
.form-group input, .form-group textarea { width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 8px; font-size: 1rem; }
.login-container { max-width: 400px; margin: 2rem auto; background: white; padding: 2rem; border-radius: 12px; }
.login-info { margin-top: 1.5rem; padding-top: 1.5rem; border-top: 1px solid #e5e7eb; font-size: 0.875rem; color: #6b7280; }
.alert { padding: 1rem 1.5rem; border-radius: 8px; margin-bottom: 1.5rem; }
.alert-success { background: #d1fae5; color: #065f46; }
.alert-danger { background: #fee2e2; color: #991b1b; }
.alert-warning { background: #fef3c7; color: #92400e; }
.alert-info { background: #dbeafe; color: #1e40af; }
.footer { background: #0f172a; color: white; padding: 2rem 0; text-align: center; margin-top: 4rem; }
.precio-accion { display: flex; justify-content: space-between; align-items: center; margin-top: 1rem; }
.precio-accion strong { font-size: 1.25rem; color: #2563eb; }
@media (max-width: 768px) {
    .header .container { flex-direction: column; gap: 1rem; }
    .nav { display: flex; gap: 1rem; flex-wrap: wrap; justify-content: center; }
    .nav a { margin-left: 0; }
}
EOFCSS

# =========================================================
# PASO 6: Configurar permisos y SELinux
# =========================================================
echo -e "${YELLOW}[6/8] Configurando permisos y SELinux...${NC}"

sudo chown -R apache:apache "$APP_DIR"
sudo find "$APP_DIR" -type d -exec chmod 755 {} \;
sudo find "$APP_DIR" -type f -exec chmod 644 {} \;
sudo chmod 750 "$APP_DIR/config"
sudo chmod 640 "$APP_DIR/config/.env"
sudo chmod -R 775 "$APP_DIR/logs"
sudo chmod -R 775 "$APP_DIR/tmp"

# SELinux
sudo restorecon -Rv "$APP_DIR" 2>/dev/null || true
sudo chcon -R -t httpd_sys_content_t "$APP_DIR"
sudo chcon -R -t httpd_sys_rw_content_t "$APP_DIR/logs"
sudo chcon -R -t httpd_sys_rw_content_t "$APP_DIR/tmp"

# =========================================================
# PASO 7: Configurar PHP y Apache
# =========================================================
echo -e "${YELLOW}[7/8] Configurando PHP y Apache...${NC}"

sudo sed -i 's/display_errors = Off/display_errors = On/' /etc/php.ini
sudo sed -i 's/error_reporting = .*/error_reporting = E_ALL/' /etc/php.ini

# =========================================================
# PASO 8: Reiniciar Apache
# =========================================================
echo -e "${YELLOW}[8/8] Reiniciando Apache...${NC}"
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
echo "� Próximos pasos:"
echo "1. Ejecuta el SQL en RDS para crear las tablas"
echo "2. Prueba la página en tu navegador"
echo "3. Si hay errores, revisa: sudo tail -20 /var/log/httpd/error_log"
echo ""
echo " Usuarios de prueba:"
echo "   - Admin: admin@nexorder.com / Admin123!"
echo "   - Cocina: cocina@nexorder.com / Cocina123!"
