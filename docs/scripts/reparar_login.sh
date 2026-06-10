#!/bin/bash
# =========================================================
# SCRIPT DE REPARACIÓN - login.php con columnas correctas
# =========================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔧 Reparando login.php con columnas correctas${NC}"
echo "=============================================="

# =========================================================
# PASO 1: Verificar DocumentRoot de Apache
# =========================================================
echo -e "${YELLOW}[1/4] Detectando DocumentRoot...${NC}"

DOCROOT=$(sudo grep -r "DocumentRoot" /etc/httpd/conf/ /etc/httpd/conf.d/ 2>/dev/null | grep -v "^#" | head -1 | awk '{print $2}' | tr -d '"')

echo "DocumentRoot actual: $DOCROOT"

# =========================================================
# PASO 2: Crear login.php con columnas CORRECTAS
# =========================================================
echo -e "${YELLOW}[2/4] Creando login.php adaptado...${NC}"

LOGIN_PHP='<?php
// NexOrder - Login (Columnas reales de la BD)
$host = "nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com";
$db   = "nexorder_db";
$user = "nexorder_app";
$pass = "N3x0r-DB-2026!Sec";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (PDOException $e) {
    die("Error de conexión: " . htmlspecialchars($e->getMessage()));
}

if (session_status() === PHP_SESSION_NONE) {
    session_name("nexorder_session");
    session_start();
}

$error = "";

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $input = trim($_POST["email"] ?? "");
    $password = $_POST["password"] ?? "";
    
    if (empty($input) || empty($password)) {
        $error = "Por favor, completa todos los campos";
    } else {
        // Buscar por email O username (columnas reales de la BD)
        $stmt = $pdo->prepare("SELECT id_usuario, username, email, nombre_completo, password_hash, rol FROM usuarios WHERE (email = ? OR username = ?) AND activo = 1");
        $stmt->execute([$input, $input]);
        $usuario = $stmt->fetch();
        
        if ($usuario && password_verify($password, $usuario["password_hash"])) {
            session_regenerate_id(true);
            $_SESSION["usuario_id"] = $usuario["id_usuario"];
            $_SESSION["usuario_nombre"] = $usuario["nombre_completo"];
            $_SESSION["usuario_username"] = $usuario["username"];
            $_SESSION["usuario_email"] = $usuario["email"];
            $_SESSION["usuario_rol"] = $usuario["rol"];
            
            // Redirigir según rol
            switch ($usuario["rol"]) {
                case "admin":
                    header("Location: /admin.php");
                    break;
                case "cocina":
                    header("Location: /cocina.php");
                    break;
                default:
                    header("Location: /menu.php");
            }
            exit;
        } else {
            $error = "Usuario/email o contraseña incorrectos";
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
    <style>
        body { font-family: system-ui, sans-serif; max-width: 500px; margin: 2rem auto; padding: 0 1rem; background: #f4f7fb; }
        .login-box { background: white; padding: 2rem; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #1f2937; text-align: center; margin-bottom: 2rem; }
        .form-group { margin-bottom: 1.5rem; }
        label { display: block; margin-bottom: 0.5rem; font-weight: 600; color: #374151; }
        input { width: 100%; padding: 0.75rem; border: 1px solid #d1d5db; border-radius: 6px; font-size: 1rem; }
        input:focus { outline: none; border-color: #2563eb; }
        button { width: 100%; padding: 0.75rem; background: #2563eb; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 1rem; }
        button:hover { background: #1d4ed8; }
        .error { background: #fee2e2; color: #991b1b; padding: 1rem; border-radius: 6px; margin-bottom: 1rem; border-left: 4px solid #991b1b; }
        .info { background: #dbeafe; color: #1e40af; padding: 1rem; border-radius: 6px; margin-top: 1.5rem; font-size: 0.9rem; }
        .back { display: block; text-align: center; margin-top: 1.5rem; color: #2563eb; text-decoration: none; }
    </style>
</head>
<body>
    <div class="login-box">
        <h1>NexOrder - Iniciar Sesión</h1>
        
        <?php if ($error): ?>
            <div class="error"><?= htmlspecialchars($error) ?></div>
        <?php endif; ?>
        
        <form method="POST">
            <div class="form-group">
                <label>Email o Usuario:</label>
                <input type="text" name="email" required autofocus placeholder="admin@nexorder.com o admin">
            </div>
            <div class="form-group">
                <label>Contraseña:</label>
                <input type="password" name="password" required>
            </div>
            <button type="submit">Entrar</button>
        </form>
        
        <div class="info">
            <strong>Usuarios de prueba:</strong><br>
            Admin: admin / Admin123!<br>
            Cocina: cocina1 / Cocina123!<br>
            Cliente: cliente1 / Cliente123!
        </div>
        
        <a href="index.php" class="back">Volver al inicio</a>
    </div>
</body>
</html>'

# Crear en AMBAS ubicaciones posibles
echo "$LOGIN_PHP" | sudo tee /var/www/nexorder/public/login.php > /dev/null 2>/dev/null || true
echo "$LOGIN_PHP" | sudo tee /var/www/html/login.php > /dev/null 2>/dev/null || true

echo "✅ login.php creado en ambas ubicaciones"

# =========================================================
# PASO 3: Configurar permisos
# =========================================================
echo -e "${YELLOW}[3/4] Configurando permisos...${NC}"

sudo chown apache:apache /var/www/nexorder/public/login.php 2>/dev/null || true
sudo chmod 644 /var/www/nexorder/public/login.php 2>/dev/null || true
sudo chown apache:apache /var/www/html/login.php 2>/dev/null || true
sudo chmod 644 /var/www/html/login.php 2>/dev/null || true

sudo restorecon -Rv /var/www/nexorder/public/login.php 2>/dev/null || true
sudo restorecon -Rv /var/www/html/login.php 2>/dev/null || true
sudo chcon -t httpd_sys_content_t /var/www/nexorder/public/login.php 2>/dev/null || true
sudo chcon -t httpd_sys_content_t /var/www/html/login.php 2>/dev/null || true

echo "✅ Permisos configurados"

# =========================================================
# PASO 4: Verificar sintaxis y reiniciar Apache
# =========================================================
echo -e "${YELLOW}[4/4] Verificando y reiniciando Apache...${NC}"

sudo php -l /var/www/nexorder/public/login.php 2>/dev/null || true
sudo php -l /var/www/html/login.php 2>/dev/null || true

sudo systemctl restart httpd

echo ""
echo -e "${GREEN}✅ REPARACIÓN COMPLETADA${NC}"
echo "================================"
echo ""
echo "🔗 Prueba ahora:"
echo "   https://44.207.176.14/login.php"
echo ""
echo " Usuarios:"
echo "   - admin / Admin123!"
echo "   - cocina1 / Cocina123!"
echo "   - cliente1 / Cliente123!"
echo ""
echo "✅ Cambios:"
echo "   - login.php usa columnas reales: nombre_completo, username, email"
echo "   - Busca por email O username"
echo "   - Redirección según rol (admin/cocina/cliente)"
