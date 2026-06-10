<?php
function escapar($texto) {
    return htmlspecialchars($texto, ENT_QUOTES, "UTF-8");
}

function formatearPrecio($precio) {
    return number_format($precio, 2, ",", ".") . " €";
}

function redirigir($url, $mensaje = null, $tipo = "success") {
    if ($mensaje) {
        $_SESSION["mensaje"] = $mensaje;
        $_SESSION["mensaje_tipo"] = $tipo;
    }
    header("Location: $url");
    exit;
}

function mostrarMensaje() {
    if (isset($_SESSION["mensaje"])) {
        $tipo = $_SESSION["mensaje_tipo"] ?? "info";
        $mensaje = escapar($_SESSION["mensaje"]);
        echo "<div class='alert alert-$tipo'>$mensaje</div>";
        unset($_SESSION["mensaje"], $_SESSION["mensaje_tipo"]);
    }
}

function contarCarrito() {
    if (!isset($_SESSION["carrito"])) return 0;
    return array_sum($_SESSION["carrito"]);
}
?>
