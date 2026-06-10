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
