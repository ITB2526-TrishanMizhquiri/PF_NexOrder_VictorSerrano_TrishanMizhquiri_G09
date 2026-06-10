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
