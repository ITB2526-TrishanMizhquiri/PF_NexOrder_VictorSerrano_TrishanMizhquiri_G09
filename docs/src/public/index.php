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
