--
-- PROCEDURE PARA CREAR CLIENTE
--
DELIMITER //

CREATE PROCEDURE CrearCliente(
    IN p_nombre VARCHAR(120),
    IN p_apellido VARCHAR(120),
    IN p_direccion VARCHAR(120),
    IN p_dni INT
)
BEGIN
    INSERT INTO clientes (nombre, apellido, direccion, dni, fecha_creacion)
    VALUES (p_nombre, p_apellido, p_direccion, p_dni, NOW());
END //

DELIMITER ;

--
-- PROCEDURE PARA ELIMINAR CLIENTE
--

DELIMITER //

CREATE PROCEDURE EliminarCliente(
    IN p_dni INT
)
BEGIN
    DELETE FROM clientes WHERE clientes.dni = p_dni;
END //

DELIMITER ;

--
-- PROCEDURES PARA CREAR PLANES
--

DELIMITER //

CREATE PROCEDURE CrearPlanes(
    IN p_interes FLOAT(10,2),
    IN p_cuotas INT,
)
BEGIN
    INSERT INTO clientes (interes, cuotas)
    VALUES (p_interes, p_cuotas);
END //

DELIMITER ;

--
-- PROCEDURES PARA CREAR PRESTAMO
--

DELIMITER //

CREATE PROCEDURE CrearPrestamo(
    IN p_cliente_id INT,
    IN p_plan_id INT,
    IN p_total FLOAT(10,2),
    IN p_fecha_creacion TIMESTAMP,
    IN p_fecha_cancelacion TIMESTAMP
)
BEGIN
    INSERT INTO prestamos (cliente_id, plan_id, total, fecha_creacion, fecha_cancelacion)
    VALUES (p_cliente_id, p_plan_id, p_total, p_fecha_creacion, p_fecha_cancelacion);
END //

DELIMITER ;


--
-- PROCEDIMIENTO PARA CREAR CUOTAS
--







