<?php
session_name('nexorder_session');
session_start();

echo "<h2>Test de Sesión</h2>";
echo "<p>Estado de sesión: " . session_status() . "</p>";
echo "<p>ID de sesión: " . session_id() . "</p>";
echo "<p>Contenido de \$_SESSION:</p>";
echo "<pre>";
print_r($_SESSION);
echo "</pre>";

if (isset($_SESSION['carrito'])) {
    echo "<p style='color:green'>✅ Carrito existe con " . count($_SESSION['carrito']) . " productos</p>";
    echo "<pre>";
    print_r($_SESSION['carrito']);
    echo "</pre>";
} else {
    echo "<p style='color:orange'>⚠️ Carrito no existe en sesión</p>";
}

if (isset($_SESSION['usuario_id'])) {
    echo "<p style='color:green'>✅ Usuario logueado: " . $_SESSION['usuario_nombre'] . "</p>";
} else {
    echo "<p style='color:red'>❌ No hay usuario logueado</p>";
}
?>
<p><a href="menu.php">Volver al menú</a></p>
