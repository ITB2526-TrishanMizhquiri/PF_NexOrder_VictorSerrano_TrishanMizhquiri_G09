-- Script para crear tablas y usuarios de NexOrder
-- Ejecutar en RDS: mysql -h nexorder-db.cijbieo4judf.us-east-1.rds.amazonaws.com -u nexorder_app -p nexorder_db < setup_database.sql

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('cliente', 'cocina', 'admin') DEFAULT 'cliente',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de productos
CREATE TABLE IF NOT EXISTS productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10,2) NOT NULL,
    categoria ENUM('entrante', 'principal', 'postre', 'bebida') DEFAULT 'principal',
    disponible BOOLEAN DEFAULT TRUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de pedidos
CREATE TABLE IF NOT EXISTS pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT,
    total DECIMAL(10,2) NOT NULL,
    estado ENUM('pendiente', 'en_preparacion', 'listo', 'entregado', 'cancelado') DEFAULT 'pendiente',
    notas TEXT,
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insertar usuarios (contraseñas hasheadas con password_hash)
-- Admin: Admin123!
INSERT INTO usuarios (nombre, email, password_hash, rol) VALUES 
('Administrador', 'admin@nexorder.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin')
ON DUPLICATE KEY UPDATE password_hash = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';

-- Cocina: Cocina123!
INSERT INTO usuarios (nombre, email, password_hash, rol) VALUES 
('Chef Principal', 'cocina@nexorder.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'cocina')
ON DUPLICATE KEY UPDATE password_hash = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';

-- Cliente: Cliente123!
INSERT INTO usuarios (nombre, email, password_hash, rol) VALUES 
('Cliente Demo', 'cliente@nexorder.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'cliente')
ON DUPLICATE KEY UPDATE password_hash = '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi';

-- Insertar productos de ejemplo
INSERT INTO productos (nombre, descripcion, precio, categoria) VALUES
('Ensalada César', 'Lechuga romana, crutones, parmesano y salsa César', 8.50, 'entrante'),
('Croquetas de jamón', '8 unidades de croquetas caseras de jamón ibérico', 7.00, 'entrante'),
('Solomillo a la pimienta', 'Solomillo de ternera con salsa de pimienta verde', 18.50, 'principal'),
('Paella valenciana', 'Paella tradicional con pollo, conejo y verduras', 14.00, 'principal'),
('Pizza Margarita', 'Tomate, mozzarella fresca y albahaca', 11.00, 'principal'),
('Tiramisú', 'Postre italiano con café y mascarpone', 6.50, 'postre'),
('Tarta de queso', 'Tarta de queso al horno con frutos rojos', 5.50, 'postre'),
('Agua mineral', 'Botella 50cl', 2.50, 'bebida'),
('Cerveza artesana', 'IPA local 33cl', 4.00, 'bebida'),
('Vino tinto Rioja', 'Copa de vino Rioja crianza', 5.00, 'bebida')
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);
