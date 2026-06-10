<?php
session_start();

function requireLogin() {
    if (!isset($_SESSION['usuario_id'])) {
        header("Location: login.php");
        exit;
    }
}

function requireRole($allowedRoles) {
    requireLogin();
    if (!is_array($allowedRoles)) $allowedRoles = [$allowedRoles];
    if (!in_array($_SESSION['rol'], $allowedRoles)) {
        die("� Acceso denegado: Tu rol no tiene permisos para esta sección.");
    }
}
?>
