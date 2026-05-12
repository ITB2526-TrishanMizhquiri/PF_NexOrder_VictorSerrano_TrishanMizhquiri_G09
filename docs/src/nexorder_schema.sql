-- ========================================================
-- NEXORDER - Esquema de Base de Datos
-- Proyecto ASIXc 25-26 | Trishan Mizhquiri, Victor Serrano
-- =========================================================

USE nexorder_db;

-- 2. Tabla: Estados de pedido (normalizada)
CREATE TABLE estados (
    id_estado INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(255),
    color VARCHAR(20) DEFAULT 'gray',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 3. Tabla: Usuarios (clientes, cocina, admin)
CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    nombre_completo VARCHAR(100) NOT NULL,
    rol ENUM('cliente', 'cocina', 'admin') NOT NULL DEFAULT 'cliente',
    telefono VARCHAR(20),
    direccion VARCHAR(255),
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email)
) ENGINE=InnoDB;

-- 4. Tabla: Productos (menú del restaurante)
CREATE TABLE productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
    categoria ENUM('entrada', 'principal', 'postre', 'bebida') NOT NULL,
    imagen_url VARCHAR(255),
    disponible BOOLEAN DEFAULT TRUE,
    tiempo_preparacion_min INT DEFAULT 15,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_categoria (categoria),
    INDEX idx_disponible (disponible)
) ENGINE=InnoDB;

-- 5. Tabla: Pedidos
CREATE TABLE pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_estado INT NOT NULL DEFAULT 1,
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega TIMESTAMP NULL,
    total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
    notas TEXT,
    direccion_entrega VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,
    FOREIGN KEY (id_estado) REFERENCES estados(id_estado) ON DELETE RESTRICT,
    INDEX idx_usuario (id_usuario),
    INDEX idx_estado (id_estado),
    INDEX idx_fecha (fecha_pedido)
) ENGINE=InnoDB;

-- 6. Tabla: Detalle_Pedidos (relación muchos-a-muchos)
CREATE TABLE detalle_pedidos (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    notas VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto) ON DELETE RESTRICT,
    INDEX idx_pedido (id_pedido),
    INDEX idx_producto (id_producto)
) ENGINE=InnoDB;

-- 7. Insertar datos iniciales - Estados
INSERT INTO estados (nombre, descripcion, color) VALUES
('pendiente', 'Pedido recién creado, esperando confirmación', 'yellow'),
('en_preparacion', 'El personal de cocina está preparando el pedido', 'orange'),
('listo', 'Pedido terminado, listo para entregar', 'blue'),
('entregado', 'Pedido entregado al cliente', 'green'),
('cancelado', 'Pedido cancelado', 'red');

-- 8. Insertar datos de prueba - Productos
INSERT INTO productos (nombre, descripcion, precio, categoria, tiempo_preparacion_min) VALUES
('Ensalada César', 'Lechuga, pollo, crutones, aderezo césar', 8.50, 'entrada', 10),
('Pizza Margarita', 'Tomate, mozzarella, albahaca fresca', 12.00, 'principal', 20),
('Hamburguesa Clásica', 'Carne 200g, queso, lechuga, tomate, cebolla', 10.50, 'principal', 15),
('Pasta Carbonara', 'Espaguetis, huevo, panceta, queso pecorino', 11.00, 'principal', 18),
('Tarta de Chocolate', 'Chocolate negro, nata, frutos rojos', 6.00, 'postre', 5),
('Coca-Cola 330ml', 'Refresco de cola', 2.50, 'bebida', 2),
('Agua Mineral', 'Agua sin gas 500ml', 1.50, 'bebida', 2);

-- 9. Insertar usuario admin de prueba (password: admin123 - HASHEAR EN PRODUCCIÓN)
INSERT INTO usuarios (username, password_hash, email, nombre_completo, rol) VALUES
('admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin@nexorder.com', 'Administrador Sistema', 'admin'),
('cocina1', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'cocina@nexorder.com', 'Personal Cocina', 'cocina');

-- 10. Verificar creación de tablas
SHOW TABLES;

-- 11. Verificar datos insertados
SELECT 'Estados' AS tabla, COUNT(*) as registros FROM estados
UNION ALL
SELECT 'Productos', COUNT(*) FROM productos
UNION ALL
SELECT 'Usuarios', COUNT(*) FROM usuarios;

-- 12. Consulta de prueba: Ver menú disponible
SELECT 
    categoria,
    nombre,
    CONCAT('$', FORMAT(precio, 2)) AS precio,
    CONCAT(tiempo_preparacion_min, ' min') AS tiempo
FROM productos
WHERE disponible = TRUE
ORDER BY categoria, nombre;
