-- SCRIPT: modelo relacional para "viveros" (PostgreSQL)
-- Recomendación: ejecutar en psql. El script crea la BD y se conecta a ella.

-- 1) Crear base de datos
DROP DATABASE IF EXISTS viveros;
CREATE DATABASE viveros;
\connect viveros

-- 2) Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS btree_gist;  -- para exclusion constraints

-- 3) Tablas principales

-- VIVERO
CREATE TABLE vivero (
    id_vivero serial PRIMARY KEY,
    nombre text NOT NULL,
    latitud numeric(9,6) NOT NULL CHECK(latitud BETWEEN -90 AND 90),
    longitud numeric(9,6) NOT NULL CHECK(longitud BETWEEN -180 AND 180),
    direccion text
);

-- ZONA
CREATE TABLE zona (
    id_zona serial PRIMARY KEY,
    id_vivero int NOT NULL REFERENCES vivero(id_vivero) ON DELETE CASCADE,
    nombre text NOT NULL,
    latitud numeric(9,6) CHECK(latitud BETWEEN -90 AND 90),
    longitud numeric(9,6) CHECK(longitud BETWEEN -180 AND 180)
);

-- PRODUCTO
CREATE TABLE producto (
    id_producto serial PRIMARY KEY,
    nombre text NOT NULL,
    categoria text,
    precio numeric(12,2) NOT NULL CHECK(precio >= 0)
);

-- Tabla intermedia zona-producto (almacena) con atributo cantidad
CREATE TABLE zona_producto (
    id_zona_producto serial PRIMARY KEY,
    id_zona int NOT NULL REFERENCES zona(id_zona) ON DELETE CASCADE,
    id_producto int NOT NULL REFERENCES producto(id_producto) ON DELETE RESTRICT,
    cantidad int NOT NULL CHECK (cantidad >= 0),
    UNIQUE (id_zona, id_producto)
);

-- EMPLEADO
CREATE TABLE empleado (
    id_empleado serial PRIMARY KEY,
    nombre text NOT NULL,
    apellido text NOT NULL,
    cargo text,
    objetivos_venta numeric(12,2) DEFAULT 0 CHECK(objetivos_venta >= 0)
);

-- Historial de asignaciones empleado → zona con periodo y restricción de solapamiento
CREATE TABLE empleado_zona (
    id_empleado_zona serial PRIMARY KEY,
    id_empleado int NOT NULL REFERENCES empleado(id_empleado) ON DELETE CASCADE,
    id_zona int NOT NULL REFERENCES zona(id_zona) ON DELETE CASCADE,
    fecha_inicio timestamptz NOT NULL,
    fecha_fin timestamptz NOT NULL CHECK (fecha_fin > fecha_inicio)
);

-- Índice GiST para restricción de solapamiento por empleado
CREATE INDEX idx_emp_zona_periodo ON empleado_zona
USING gist (id_empleado, tstzrange(fecha_inicio, fecha_fin, '[]'));

-- Restricción de exclusión para evitar solapamientos
ALTER TABLE empleado_zona
    ADD CONSTRAINT emp_zona_no_solapamiento EXCLUDE USING gist (
        id_empleado WITH =,
        tstzrange(fecha_inicio, fecha_fin, '[]') WITH &&
    );

-- CLIENTE
CREATE TABLE cliente (
    id_cliente serial PRIMARY KEY,
    nombre text NOT NULL,
    apellido text NOT NULL,
    email text UNIQUE
);

-- Subtabla ClienteTajinastePlus (solo clientes que pertenecen al programa)
CREATE TABLE cliente_tajinaste_plus (
    id_cliente int PRIMARY KEY REFERENCES cliente(id_cliente) ON DELETE CASCADE,
    mes smallint NOT NULL CHECK (mes BETWEEN 1 AND 12),
    anio int NOT NULL CHECK (anio >= 2000)
);

-- PEDIDO
-- total será calculado (derivado) por trigger a partir de pedido_item
CREATE TABLE pedido (
    id_pedido serial PRIMARY KEY,
    id_cliente int NOT NULL REFERENCES cliente(id_cliente) ON DELETE RESTRICT,
    id_empleado_gestor int REFERENCES empleado(id_empleado) ON DELETE SET NULL,
    fecha timestamptz NOT NULL DEFAULT now(),
    total numeric(12,2) NOT NULL DEFAULT 0 CHECK(total >= 0)
);

-- Items de pedido
CREATE TABLE pedido_item (
    id_pedido_item serial PRIMARY KEY,
    id_pedido int NOT NULL REFERENCES pedido(id_pedido) ON DELETE CASCADE,
    id_producto int NOT NULL REFERENCES producto(id_producto) ON DELETE RESTRICT,
    cantidad int NOT NULL CHECK(cantidad > 0),
    precio_unitario numeric(12,2) NOT NULL CHECK(precio_unitario >= 0)
);
-- Asegurar que no haya dos líneas duplicadas para mismo pedido/producto
CREATE UNIQUE INDEX ux_pedido_producto ON pedido_item (id_pedido, id_producto);

-- BONIFICACIÓN (solo para clientes Tajinaste Plus)
CREATE TABLE bonificacion (
    id_bonificacion serial PRIMARY KEY,
    id_cliente int NOT NULL REFERENCES cliente_tajinaste_plus(id_cliente) ON DELETE CASCADE,
    mes smallint NOT NULL CHECK (mes BETWEEN 1 AND 12),
    anio int NOT NULL CHECK (anio >= 2000),
    monto numeric(12,2) NOT NULL CHECK (monto >= 0),
    UNIQUE (id_cliente, mes, anio)  -- evita duplicados por periodo
);

-- 4) Triggers / funciones: calcular total de pedido (derivado)
CREATE OR REPLACE FUNCTION calcular_total_pedido() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    -- recalcula total sum(cantidad * precio_unitario)
    UPDATE pedido
    SET total = COALESCE((
            SELECT SUM(pi.cantidad * pi.precio_unitario)::numeric(12,2)
            FROM pedido_item pi
            WHERE pi.id_pedido = NEW.id_pedido
        ), 0)
    WHERE id_pedido = NEW.id_pedido;
    RETURN NULL;
END;
$$;

-- Trigger AFTER INSERT OR UPDATE OR DELETE sobre pedido_item.
CREATE TRIGGER trg_calcular_total_after_ins
AFTER INSERT ON pedido_item
FOR EACH ROW EXECUTE FUNCTION calcular_total_pedido();

CREATE TRIGGER trg_calcular_total_after_upd
AFTER UPDATE ON pedido_item
FOR EACH ROW EXECUTE FUNCTION calcular_total_pedido();

-- Para DELETE we need a trigger that has access to OLD row; create separate function
CREATE OR REPLACE FUNCTION calcular_total_pedido_delete() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    UPDATE pedido
    SET total = COALESCE((
            SELECT SUM(pi.cantidad * pi.precio_unitario)::numeric(12,2)
            FROM pedido_item pi
            WHERE pi.id_pedido = OLD.id_pedido
        ), 0)
    WHERE id_pedido = OLD.id_pedido;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_calcular_total_after_del
AFTER DELETE ON pedido_item
FOR EACH ROW EXECUTE FUNCTION calcular_total_pedido_delete();

-- 5) Datos de ejemplo (al menos 5 filas por tabla)

-- Viveros (5)
INSERT INTO vivero (nombre, latitud, longitud, direccion) VALUES
('Vivero Centro', 28.463200, -16.254000, 'Calle Principal 1'),
('Vivero Norte', 28.500000, -16.250000, 'Av. Norte 10'),
('Vivero Sur', 28.440000, -16.260000, 'Camino Sur 5'),
('Vivero Este', 28.470000, -16.240000, 'Paseo Este 7'),
('Vivero Oeste', 28.455000, -16.270000, 'Calle Oeste 2');

-- Zonas (≥5). Distribuidas en viveros, varias por vivero
INSERT INTO zona (id_vivero, nombre, latitud, longitud) VALUES
(1, 'Zona A', 28.463300, -16.254100),
(1, 'Zona B', 28.463400, -16.253900),
(2, 'Zona Norte 1', 28.500100, -16.249900),
(3, 'Zona Sur Principal', 28.439900, -16.260100),
(4, 'Zona Este 1', 28.470200, -16.240100),
(5, 'Zona Oeste 1', 28.455100, -16.269900);

-- Productos (5)
INSERT INTO producto (nombre, categoria, precio) VALUES
('Maceta 1L','macetas', 1.50),
('Maceta 3L','macetas', 2.50),
('Rosal','plantas_flor', 12.00),
('Abono General','insumos', 8.75),
('Regadera','herramientas', 6.20);

-- zona_producto (stock) (≥5)
INSERT INTO zona_producto (id_zona, id_producto, cantidad) VALUES
(1, 1, 100),  -- Zona A tiene 100 Maceta 1L
(1, 3, 10),   -- Zona A tiene 10 Rosales
(2, 2, 50),   -- Zona B tiene Maceta 3L
(3, 4, 25),   -- Zona Norte 1 tiene Abono
(4, 5, 15),   -- Zona Este 1 tiene Regaderas
(6, 1, 20);   -- Zona Oeste 1 tiene Maceta 1L

-- Empleados (5)
INSERT INTO empleado (nombre, apellido, cargo, objetivos_venta) VALUES
('Ana','Gómez','Encargada', 2000),
('Luis','Martín','Vendedor', 1500),
('Marta','Pérez','Técnica', 1000),
('Rosa','Díaz','Vendedora', 1500),
('Jorge','Silva','Operario', 0);

-- empleado_zona (historial, ≥5). No solapamientos por empleado
-- Ana: Zona A (1) desde 2024-01 hasta 2024-12
INSERT INTO empleado_zona (id_empleado, id_zona, fecha_inicio, fecha_fin) VALUES
(1, 1, '2024-01-01 08:00:00+00', '2024-12-31 17:00:00+00'),
-- Luis: Zona B 2024 primero semestre, luego Zona Norte 2024 segundo semestre (no solapan)
(2, 2, '2024-01-01 08:00:00+00', '2024-06-30 17:00:00+00'),
(2, 3, '2024-07-01 08:00:00+00', '2024-12-31 17:00:00+00'),
-- Marta: Zona Sur pero en dos periodos no solapantes
(3, 4, '2023-05-01 08:00:00+00', '2023-12-31 17:00:00+00'),
(3, 4, '2024-01-01 08:00:00+00', '2024-12-31 17:00:00+00');

-- Clientes (5)
INSERT INTO cliente (nombre, apellido, email) VALUES
('Carlos','Ruiz','c.ruiz@example.com'),
('Laura','Morales','l.morales@example.com'),
('Pedro','Santos','p.santos@example.com'),
('Sofia','Lopez','s.lopez@example.com'),
('Diego','Ortega','d.ortega@example.com');

-- ClienteTajinastePlus: hagamos 5 clientes pertenecientes al programa (cumple requisito >=5)
INSERT INTO cliente_tajinaste_plus (id_cliente, mes, anio) VALUES
(1, 9, 2024),
(2, 9, 2024),
(3, 8, 2024),
(4, 10, 2024),
(5, 9, 2024);

-- Pedidos (≥5). Algunos con gestor, algunos sin gestor (gestor NULL)
INSERT INTO pedido (id_cliente, id_empleado_gestor, fecha) VALUES
(1, 2, '2024-09-10 10:00:00+00'),  -- cliente 1 pedido 1, gestionado por Luis
(2, 1, '2024-09-11 11:00:00+00'),  -- cliente 2 por Ana
(3, NULL, '2024-08-05 09:30:00+00'),-- cliente 3 sin gestor asignado
(4, 4, '2024-10-01 14:00:00+00'),  -- cliente 4 por Rosa
(5, 2, '2024-09-15 12:00:00+00');  -- cliente 5 por Luis

-- Pedido items (≥5 rows across pedidos). Estos dispararán trigger para calcular total.
-- Pedido 1 (id_pedido = 1)
INSERT INTO pedido_item (id_pedido, id_producto, cantidad, precio_unitario) VALUES
(1, 1, 10, 1.50),  -- 10 Maceta 1L
(1, 3, 1, 12.00),  -- 1 Rosal
-- Pedido 2
(2, 4, 2, 8.75),
(2, 5, 1, 6.20),
-- Pedido 3
(3, 2, 5, 2.50),
-- Pedido 4
(4, 3, 2, 12.00),
(4, 5, 2, 6.20),
-- Pedido 5
(5, 1, 4, 1.50);

-- Bonificaciones (≥5). Vienen solo para clientes TajinastePlus (FK asegura eso)
INSERT INTO bonificacion (id_cliente, mes, anio, monto) VALUES
(1, 9, 2024, 5.00),
(2, 9, 2024, 7.50),
(3, 8, 2024, 4.00),
(4, 10, 2024, 6.25),
(5, 9, 2024, 3.00);

-- Forzar recalculo manual inicial de totales por si hubiera filas creadas antes del trigger
-- (Triggers sobre pedido_item ya ejecutaron en inserciones anteriores,
--  pero en caso manual ejecutar una vez)
UPDATE pedido p
SET total = COALESCE((
    SELECT SUM(pi.cantidad * pi.precio_unitario)::numeric(12,2)
    FROM pedido_item pi WHERE pi.id_pedido = p.id_pedido
), 0);

-- 6) Comprobaciones y ejemplos de SELECTs para verificar
-- Totales de pedidos
SELECT id_pedido, id_cliente, id_empleado_gestor, fecha, total FROM pedido ORDER BY id_pedido;
-- SELECT de cada tabla principal
SELECT * FROM vivero;
SELECT * FROM zona;
SELECT * FROM producto;
SELECT * FROM zona_producto;
SELECT * FROM empleado;
SELECT * FROM empleado_zona;
SELECT * FROM cliente;
SELECT * FROM cliente_tajinaste_plus;
SELECT * FROM pedido;
SELECT * FROM pedido_item;
SELECT * FROM bonificacion;

-- 7) Ejemplos de operaciones DELETE (representativos)
-- a) Borrar un vivero: se propaga en cascada a sus zonas y a sus registros de zona_producto.
--    Esto simula la eliminación física del vivero y todo su inventario/zonas.
-- Ejemplo: eliminar "Vivero Oeste" (id_vivero = 5)
-- (Descomentar para ejecutar)
DELETE FROM vivero WHERE id_vivero = 5;

-- b) Borrar un empleado: por FK en pedido, id_empleado_gestor se pone a NULL (ON DELETE SET NULL)
--    lo que preserva el pedido pero quita la referencia al gestor eliminado.
-- Ejemplo: eliminar empleado Jorge (id_empleado = 5)
DELETE FROM empleado WHERE id_empleado = 5;

-- c) Intentar borrar un cliente con pedidos: la FK pedido.id_cliente es RESTRICT.
--    El borrado fallará si existen pedidos asociados. Muestra comportamiento de integridad.
-- Ejemplo: intentar borrar cliente 1 que tiene pedidos -> provocará error.
-- (Descomentar para probar y ver el error)
DELETE FROM cliente WHERE id_cliente = 1;

-- d) Borrar un cliente TajinastePlus: al borrar en cliente, cascada borra la fila en cliente_tajinaste_plus
--    y sus bonificaciones (por FK ON DELETE CASCADE en cliente_tajinaste_plus y bonificacion).
-- Ejemplo: borrar cliente 3 (si no tiene pedidos o se fuerza)
DELETE FROM cliente WHERE id_cliente = 3;

-- e) Borrar un pedido: cascada borra sus pedido_item
DELETE FROM pedido WHERE id_pedido = 2;

-- 8) Observaciones y decisiones de modelado (resumen breve)
-- - La relación Zona-Producto se implementa con tabla zona_producto y atributo cantidad.
-- - El total de pedido es derivado y se mantiene por triggers sobre pedido_item.
-- - Las asignaciones empleado→zona se modelan como historial con período y restricción
--   de no-solapamiento por empleado usando exclusion constraint.
-- - Eliminaciones:
--     * Vivero -> Zonas -> zona_producto se eliminan en cascada.
--     * Empleado eliminado -> pedidos quedan con id_empleado_gestor = NULL.
--     * Cliente -> pedidos es RESTRICT (no se permite borrar cliente con pedidos).
--     * Cliente TajinastePlus -> bonificaciones se eliminan en cascada al borrar cliente_tajinaste_plus.

-- FIN DEL SCRIPT
