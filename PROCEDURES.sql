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

-- DROP PROCEDURE IF EXISTS CrearPrestamo

DELIMITER //

CREATE PROCEDURE CrearPrestamo(
    IN p_cliente_dni INT,
    IN p_cuotas INT,
    IN p_total FLOAT(10,2),
    IN p_fecha_creacion TIMESTAMP,
    IN p_fecha_cancelacion TIMESTAMP
)
BEGIN
    DECLARE v_cliente_id INT;
    DECLARE v_plan_id INT;
    DECLARE v_prestamo_id INT;
    DECLARE v_nro_cuota INT;
    DECLARE v_fecha_vencimiento DATE;

    -- Obtener el ID del cliente
    SELECT id INTO v_cliente_id 
    FROM clientes 
    WHERE dni = p_cliente_dni;
    
    -- Obtener el ID del plan
    SELECT id INTO v_plan_id 
    FROM planes 
    WHERE cuotas = p_cuotas;
    
    -- Insertar el nuevo prestamo
    INSERT INTO prestamos (cliente_id, plan_id, total, fecha_creacion, fecha_cancelacion)
    VALUES (v_cliente_id, v_plan_id, p_total, p_fecha_creacion, p_fecha_cancelacion);
    
    -- Obtener el ID del prestamo recién creado
    SET v_prestamo_id = LAST_INSERT_ID();
    
    -- Calcular las fechas de vencimiento y crear las cuotas
    SET v_nro_cuota = 1;
    WHILE v_nro_cuota <= p_cuotas DO
        -- Calcular la fecha de vencimiento para cada cuota
        SET v_fecha_vencimiento = DATE_ADD(LAST_DAY(p_fecha_creacion), INTERVAL v_nro_cuota MONTH);
        SET v_fecha_vencimiento = DATE_FORMAT(v_fecha_vencimiento + INTERVAL 5 DAY, '%Y-%m-05');
        
        CALL CrearCuotas(v_nro_cuota, p_total / p_cuotas, v_prestamo_id, v_fecha_vencimiento);

        SET v_nro_cuota = v_nro_cuota + 1;
    END WHILE;
END //

DELIMITER ;


--
-- PROCEDIMIENTO PARA CREAR CUOTAS
--

DELIMITER //

CREATE PROCEDURE CrearCuotas(
    IN p_nro_cuota INT,
    IN p_total FLOAT(10,2),
    IN p_prestamo_id INT,
    IN p_fecha_vencimiento TIMESTAMP
) 

BEGIN

    INSERT INTO cuotas (nro_cuota, total, prestamo_id, fecha_vencimiento, fecha_pago)
    VALUES (p_nro_cuota, p_total, p_prestamo_id, p_fecha_vencimiento, NULL);

END //

DELIMITER ;

--
-- PROCEDIMIENTO PARA CALCULAR INTERESES
--

DELIMITER //

CREATE PROCEDURE CalcularInteresesVencidos()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_cuotas_id INT;
    DECLARE v_nro_cuota INT;
    DECLARE v_total FLOAT(10,2);
    DECLARE v_prestamo_id INT;
    DECLARE v_fecha_vencimiento DATE;
    DECLARE v_interes FLOAT(10,2);
    DECLARE v_dias_retraso INT;
    DECLARE v_interes_diario FLOAT(5,4) DEFAULT 0.038;

    -- Cursor para recorrer las cuotas vencidas
    DECLARE cuotas_cursor CURSOR FOR
        SELECT id, nro_cuota, total, prestamo_id, fecha_vencimiento
        FROM cuotas
        WHERE fecha_vencimiento < CURDATE() AND fecha_pago IS NULL;

    -- Manejo del final del cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Abrir el cursor
    OPEN cuotas_cursor;

    -- Iterar sobre cada cuota vencida
    read_loop: LOOP
        FETCH cuotas_cursor INTO v_cuotas_id, v_nro_cuota, v_total, v_prestamo_id, v_fecha_vencimiento;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Calcular los días de retraso
        SET v_dias_retraso = DATEDIFF(CURDATE(), v_fecha_vencimiento);

        -- Calcular el interés acumulado
        SET v_interes = v_total * v_interes_diario * v_dias_retraso;

        -- Insertar el interés calculado en la tabla intereses
        INSERT INTO intereses (cuotas_id, prestamo_id, dias_vencidos, interes, fecha_calculo)
        VALUES (v_cuotas_id, v_prestamo_id, v_dias_retraso, v_interes, CURDATE());
    END LOOP;

    -- Cerrar el cursor
    CLOSE cuotas_cursor;
END //

DELIMITER ;


--
-- PROCEDIMIENTO PARA OBTENER DEUDA CLIENTE
--

DELIMITER //

CREATE PROCEDURE ObtenerDeudaCliente(
    IN p_cliente_dni INT
)
BEGIN
    DECLARE v_cliente_id INT;
    DECLARE v_deuda_total FLOAT(10, 2);
    DECLARE v_deuda_a_vencer FLOAT(10, 2);
    DECLARE v_prestamo_total FLOAT(10, 2);
    DECLARE v_prestamo_id INT;
    DECLARE v_total_pagado FLOAT(10, 2);
    DECLARE v_total_cuotas FLOAT(10, 2);
    DECLARE v_fecha_pago TIMESTAMP;
    DECLARE v_fecha_vencimiento TIMESTAMP;
    DECLARE done INT DEFAULT 0;

    SELECT id INTO v_cliente_id 
    FROM clientes 
    WHERE dni = p_cliente_dni;

    IF v_cliente_id IS NOT NULL THEN
        SELECT SUM(p.total) INTO v_prestamo_total
        FROM prestamos p
        WHERE p.cliente_id = v_cliente_id;

        -- Inicializar variables
        SET v_total_pagado = 0;
        SET v_deuda_total = 0;
        SET v_deuda_a_vencer = 0;

        DECLARE cuotas_cursor CURSOR FOR
            SELECT c.id, c.total, c.fecha_pago, c.fecha_vencimiento
            FROM cuotas c
            JOIN prestamos p ON c.prestamo_id = p.id
            WHERE p.cliente_id = v_cliente_id;

        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

        OPEN cuotas_cursor;

        read_loop: LOOP
            FETCH cuotas_cursor INTO v_prestamo_id, v_total_cuotas, v_fecha_pago, v_fecha_vencimiento;
            IF done THEN
                LEAVE read_loop;
            END IF;

            IF v_fecha_pago IS NOT NULL THEN
                SET v_total_pagado = v_total_pagado + v_total_cuotas;
            ELSE
                DECLARE v_intereses FLOAT(10,2);
                SELECT IFNULL(SUM(i.total), 0) INTO v_intereses
                FROM intereses i
                WHERE i.cuotas_id = v_prestamo_id;

                SET v_deuda_total = v_deuda_total + v_total_cuotas + v_intereses;

                IF v_fecha_vencimiento <= CURDATE() THEN
                    SET v_deuda_a_vencer = v_deuda_a_vencer + v_total_cuotas + v_intereses;
                END IF;
            END IF;
        END LOOP;

        CLOSE cuotas_cursor;

        SET v_deuda_total = v_prestamo_total - v_total_pagado + v_deuda_total;

        SELECT v_deuda_total AS deuda_total, v_deuda_a_vencer AS deuda_a_vencer;
    ELSE
        SELECT 'El cliente con el DNI proporcionado no existe.' AS mensaje_error;
    END IF;
END //

DELIMITER ;





