<?php

$host = "nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com";
$db   = "nexorder_db";
$user = "nexorder_app";
$pass = "N3x0r-DB-2026!Sec";
$charset = "utf8mb4";

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES   => false,
];

$status_msg = "";
$status_class = "success";

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
    $status_msg = "✅ Conexión activa a RDS MySQL";
} catch (PDOException $e) {
    $status_msg = "❌ Error de conexión: " . htmlspecialchars($e->getMessage());
    $status_class = "error";
    $pdo = null;
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>NexOrder - Panel de Estado</title>
    <style>
        body { font-family: system-ui, sans-serif; max-width: 900px; margin: 2rem auto; padding: 0 1rem; }
        table { width: 100%; border-collapse: collapse; margin: 1rem 0; }
        th, td { padding: 0.75rem; border: 1px solid #dee2e6; text-align: left; }
        th { background: #f8f9fa; }
        .back { display: inline-block; margin-top: 1rem; color: #0d6efd; text-decoration: none; }
        .success { background: #d1e7dd; color: #0f5132; padding: 1rem; border-radius: 6px; }
        .error { background: #f8d7da; color: #842029; padding: 1rem; border-radius: 6px; }
    </style>
</head>
<body>
    <h1>📊 Panel de Validación</h1>

    <div class="<?= $status_class ?>">
        <?= $status_msg ?>
    </div>

    <?php if ($pdo): ?>
    <h3>🔍 Información del Sistema</h3>
    <table>
        <thead>
            <tr><th>Parámetro</th><th>Valor</th></tr>
        </thead>
        <tbody>
            <?php
            // Consulta compatible con MySQL 8.0 (sin palabras reservadas conflictivas)
            $stmt = $pdo->query("SELECT VERSION() AS mysql_ver, USER() AS db_user, DATABASE() AS active_db");
            $row = $stmt->fetch();
            ?>
            <tr><td>Versión MySQL</td><td><?= htmlspecialchars($row['mysql_ver']) ?></td></tr>
            <tr><td>Usuario Conectado</td><td><?= htmlspecialchars($row['db_user']) ?></td></tr>
            <tr><td>Base de Datos Activa</td><td><?= htmlspecialchars($row['active_db']) ?></td></tr>
        </tbody>
    </table>
    <p><small>✅ Consulta ejecutada mediante PDO seguro</small></p>
    <?php endif; ?>

    <a href="index.php" class="back">⬅️ Volver al menú principal</a>
</body>
</html>
