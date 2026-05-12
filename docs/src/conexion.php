<?php
$host    = 'nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com';
$db      = 'nexorder_db';
$user    = 'nexorder_app';
$pass    = 'N3x0r-DB-2026!Sec';
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,   // Sentencias preparadas reales
    PDO::ATTR_TIMEOUT            => 5,        // Timeout para no bloquear
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
    echo "<h1>✅ Conexión exitosa a RDS MySQL 8.0</h1>";
    echo "<p>Host: " . htmlspecialchars($host) . "</p>";
} catch (PDOException $e) {
    echo "<h1>❌ Error PDO: " . htmlspecialchars($e->getMessage()) . "</h1>";
}
?>