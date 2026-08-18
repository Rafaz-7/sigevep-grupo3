-- Section 1: Database creation
DROP DATABASE IF EXISTS sigevep;
CREATE DATABASE sigevep CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sigevep;

-- Section 2: Tables
CREATE TABLE grupo_pastoral (
    id_grupo INT AUTO_INCREMENT PRIMARY KEY,
    nombre_grupo VARCHAR(100) NOT NULL UNIQUE,
    descripcion_grupo VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE categoria_evento (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL UNIQUE,
    descripcion_categoria VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE rol (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre_rol VARCHAR(80) NOT NULL UNIQUE,
    descripcion_rol VARCHAR(255) NOT NULL,
    requiere_epp BOOLEAN NOT NULL DEFAULT FALSE,
    nivel_demanda_fisica ENUM('Alto','Medio','Bajo') NOT NULL
) ENGINE=InnoDB;

CREATE TABLE voluntario (
    id_voluntario INT AUTO_INCREMENT PRIMARY KEY,
    id_grupo INT NOT NULL,
    nombres VARCHAR(80) NOT NULL,
    apellidos VARCHAR(80) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    fecha_ingreso DATE NOT NULL DEFAULT (CURRENT_DATE),
    estado_operativo ENUM('Activo','Inactivo','Suspendido') NOT NULL DEFAULT 'Activo',
    nivel_capacidad_fisica ENUM('Alto','Medio','Bajo') NOT NULL,
    tipo_limitacion_fisica VARCHAR(100),
    descripcion_limitacion VARCHAR(255),
    FOREIGN KEY (id_grupo) REFERENCES grupo_pastoral(id_grupo)
) ENGINE=InnoDB;

CREATE TABLE evento (
    id_evento INT AUTO_INCREMENT PRIMARY KEY,
    id_grupo INT NOT NULL,
    id_categoria INT NOT NULL,
    nombre_evento VARCHAR(120) NOT NULL,
    fecha_programada DATE NOT NULL,
    ubicacion VARCHAR(150) NOT NULL,
    FOREIGN KEY (id_grupo) REFERENCES grupo_pastoral(id_grupo),
    FOREIGN KEY (id_categoria) REFERENCES categoria_evento(id_categoria)
) ENGINE=InnoDB;

CREATE TABLE usuario (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre_usuario VARCHAR(50) NOT NULL UNIQUE,
    clave_acceso VARCHAR(255) NOT NULL,
    rol_acceso ENUM('Administrador','Coordinador') NOT NULL
) ENGINE=InnoDB;

CREATE TABLE administrador (
    id_usuario INT PRIMARY KEY,
    nivel_permiso VARCHAR(20) NOT NULL DEFAULT 'Total' CHECK (nivel_permiso IN ('Total','Parcial')),
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE coordinador (
    id_usuario INT PRIMARY KEY,
    zona_asignada VARCHAR(50) NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE requerimiento (
    id_requerimiento INT AUTO_INCREMENT PRIMARY KEY,
    id_evento INT NOT NULL,
    id_rol INT NOT NULL,
    cantidad_requerida INT NOT NULL CHECK (cantidad_requerida > 0),
    UNIQUE (id_evento, id_rol),
    FOREIGN KEY (id_evento) REFERENCES evento(id_evento),
    FOREIGN KEY (id_rol) REFERENCES rol(id_rol)
) ENGINE=InnoDB;

CREATE TABLE autorizacion (
    id_voluntario INT NOT NULL,
    id_rol INT NOT NULL,
    id_usuario_autorizador INT NOT NULL,
    fecha_autorizacion DATE NOT NULL DEFAULT (CURRENT_DATE),
    PRIMARY KEY (id_voluntario, id_rol),
    FOREIGN KEY (id_voluntario) REFERENCES voluntario(id_voluntario),
    FOREIGN KEY (id_rol) REFERENCES rol(id_rol),
    FOREIGN KEY (id_usuario_autorizador) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE asignacion (
    id_asignacion INT AUTO_INCREMENT PRIMARY KEY,
    id_voluntario INT NOT NULL,
    id_requerimiento INT NOT NULL,
    id_usuario_aprobador INT NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    estado_asignacion ENUM('Programada','Completada','Ausente','Cancelada') NOT NULL DEFAULT 'Programada',
    justificacion_cancelacion VARCHAR(500),
    fecha_cancelacion DATE,
    CHECK (hora_fin > hora_inicio),
    FOREIGN KEY (id_voluntario) REFERENCES voluntario(id_voluntario),
    FOREIGN KEY (id_requerimiento) REFERENCES requerimiento(id_requerimiento),
    FOREIGN KEY (id_usuario_aprobador) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

CREATE TABLE audit_voluntario (
    id_audit INT AUTO_INCREMENT PRIMARY KEY,
    id_voluntario INT NOT NULL,
    campo_modificado VARCHAR(50) NOT NULL,
    valor_anterior TEXT,
    valor_nuevo TEXT,
    fecha_cambio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_bd VARCHAR(50) NOT NULL DEFAULT (CURRENT_USER())
) ENGINE=InnoDB;

-- Section 3: INSERT DATA
INSERT INTO grupo_pastoral (nombre_grupo, descripcion_grupo) VALUES
('Pastoral Juvenil San José', 'Formación espiritual y humana de jóvenes de 15 a 25 años'),
('Pastoral Familiar Santa Ana', 'Acompañamiento integral a familias de la comunidad'),
('Pastoral Social Cristo Rey', 'Servicio social y desarrollo comunitario'),
('Pastoral de Liturgia', 'Organización y coordinación de celebraciones litúrgicas'),
('Pastoral de Catequesis', 'Enseñanza y formación en la doctrina cristiana'),
('Pastoral de Misiones', 'Evangelización y acompañamiento en comunidades remotas'),
('Pastoral Universitaria', 'Apoyo espiritual y académico a estudiantes universitarios'),
('Pastoral de Jóvenes Adultos', 'Actividades de crecimiento para adultos jóvenes 25-35'),
('Pastoral Comunitaria San Pablo', 'Desarrollo integral de la comunidad parroquial'),
('Pastoral de Servicio Social', 'Asistencia directa a población vulnerable y en riesgo');

INSERT INTO categoria_evento (nombre_categoria, descripcion_categoria) VALUES
('Religioso', 'Celebraciones litúrgicas, sacramentales y de oración'),
('Social', 'Actividades de integración y convivencia comunitaria'),
('Deportivo', 'Eventos deportivos, recreativos y de actividad física'),
('Cultural', 'Actividades artísticas, educativas y de formación cultural'),
('Comunitario', 'Jornadas de servicio directo a la comunidad'),
('Educativo', 'Talleres, charlas y actividades de formación académica'),
('Benéfico', 'Eventos de recaudación de fondos y ayuda humanitaria'),
('Misionero', 'Actividades de evangelización y misión pastoral'),
('Litúrgico', 'Celebraciones sacramentales y oficios litúrgicos especiales'),
('Ecológico', 'Jornadas de cuidado ambiental y conciencia ecológica');

INSERT INTO rol (nombre_rol, descripcion_rol, requiere_epp, nivel_demanda_fisica) VALUES
('Guardia de Entrada', 'Control de acceso e identificación de asistentes', TRUE, 'Alto'),
('Guardia de Parqueo', 'Organización y control del estacionamiento vehicular', TRUE, 'Alto'),
('Acomodador', 'Guía y ubicación de asistentes en el recinto', FALSE, 'Medio'),
('Logística General', 'Coordinación operativa de recursos y materiales', FALSE, 'Alto'),
('Sonidista', 'Manejo y operación de equipos de audio y amplificación', FALSE, 'Bajo'),
('Primeros Auxilios', 'Atención médica básica y respuesta a emergencias', TRUE, 'Medio'),
('Registro y Control', 'Registro digital de asistentes e inventario del evento', FALSE, 'Bajo'),
('Apoyo en Cocina', 'Preparación y distribución de alimentos para voluntarios', TRUE, 'Medio'),
('Decoración y Montaje', 'Preparación, ambientación y montaje de espacios del evento', FALSE, 'Alto'),
('Coordinador de Área', 'Supervisión directa de un grupo de voluntarios en campo', FALSE, 'Medio');

INSERT INTO voluntario (id_grupo, nombres, apellidos, telefono, fecha_nacimiento, fecha_ingreso, estado_operativo, nivel_capacidad_fisica, tipo_limitacion_fisica, descripcion_limitacion) VALUES
(1, 'Juan Carlos', 'Pérez Gómez', '0991234567', '1998-04-15', '2024-01-10', 'Activo', 'Alto', NULL, NULL),
(1, 'María Elena', 'Rodríguez López', '0987654321', '2000-08-22', '2023-06-15', 'Activo', 'Medio', NULL, NULL),
(2, 'Carlos Alberto', 'Mendoza Ruiz', '0995551234', '1995-12-03', '2023-03-20', 'Activo', 'Alto', NULL, NULL),
(3, 'Ana Sofía', 'Vargas Torres', '0993214567', '2002-06-18', '2024-02-14', 'Activo', 'Medio', 'Movilidad reducida', 'No puede cargar objetos pesados de más de 10 kg'),
(2, 'Pedro José', 'García Salazar', '0998765432', '1990-11-07', '2023-01-05', 'Activo', 'Alto', NULL, NULL),
(4, 'Daniela Patricia', 'Herrera Figueroa', '0994567890', '2003-03-25', '2024-05-10', 'Activo', 'Alto', NULL, NULL),
(5, 'Roberto Luis', 'Castillo Morán', '0991112233', '1988-09-14', '2023-08-22', 'Activo', 'Medio', 'Cardiopatía leve', 'Control periódico; evitar esfuerzos extremos prolongados'),
(3, 'Gabriela Fernanda', 'Ortiz Vera', '0996667788', '2001-01-30', '2024-03-18', 'Activo', 'Alto', NULL, NULL),
(6, 'Miguel Ángel', 'Zambrano Cruz', '0993334455', '2010-07-12', '2025-09-01', 'Activo', 'Medio', NULL, NULL),
(7, 'Laura Isabel', 'Figueroa Bravo', '0997778899', '1997-05-28', '2023-11-30', 'Inactivo', 'Bajo', 'Asma crónica', 'Evitar ambientes con polvo, humo o productos químicos'),
(8, 'Andrés Felipe', 'Morales Rojas', '0992223344', '1999-10-05', '2024-07-20', 'Activo', 'Alto', NULL, NULL),
(9, 'Valentina Carmen', 'Delgado Ponce', '0995556677', '2004-02-14', '2025-01-15', 'Activo', 'Medio', NULL, NULL),
(10, 'Fernando José', 'Real Vargas', '0998889900', '1996-08-19', '2023-04-12', 'Suspendido', 'Alto', NULL, NULL),
(4, 'Isabella María', 'Chávez León', '0991234890', '2005-11-22', '2025-06-01', 'Activo', 'Medio', NULL, NULL),
(5, 'Santiago David', 'Rivas Aguirre', '0994445566', '1993-03-09', '2023-02-28', 'Activo', 'Alto', NULL, NULL);

INSERT INTO evento (id_grupo, id_categoria, nombre_evento, fecha_programada, ubicacion) VALUES
(1, 1, 'Misa de Navidad 2026', '2026-12-25', 'Iglesia San José Central'),
(1, 3, 'Jornada Deportiva Juvenil', '2026-08-15', 'Complejo Deportivo Parroquial'),
(2, 1, 'Retiro Espiritual Familiar', '2026-09-20', 'Centro de Retiros Santa María'),
(3, 4, 'Festival Cultural Comunitario', '2026-10-12', 'Plaza Central del Barrio'),
(3, 5, 'Jornada de Servicio Social', '2026-07-30', 'Barrio Las Flores'),
(4, 1, 'Celebración de Semana Santa', '2026-04-05', 'Iglesia Cristo Rey'),
(6, 3, 'Torneo Fútbol Interparroquial', '2026-11-08', 'Cancha Municipal Norte'),
(9, 2, 'Cena Benéfica Anual', '2026-09-15', 'Salón Parroquial San Pablo'),
(6, 5, 'Misión Evangelizadora', '2026-08-01', 'Comunidad Rural El Progreso'),
(4, 4, 'Concierto Sacro Navideño', '2026-12-20', 'Auditorio Parroquial Central'),
(7, 2, 'Campamento Juvenil de Verano', '2026-07-15', 'Finca Pastoral Los Olivos'),
(5, 1, 'Bautizos Comunitarios', '2026-10-05', 'Iglesia San José Central');

INSERT INTO usuario (nombre_usuario, clave_acceso, rol_acceso) VALUES
('cadmin', 'pbkdf2_sha256$admin01hash', 'Administrador'),
('madmin', 'pbkdf2_sha256$admin02hash', 'Administrador'),
('jadmin', 'pbkdf2_sha256$admin03hash', 'Administrador'),
('aadmin', 'pbkdf2_sha256$admin04hash', 'Administrador'),
('fadmin', 'pbkdf2_sha256$admin05hash', 'Administrador'),
('gadmin', 'pbkdf2_sha256$admin06hash', 'Administrador'),
('hadmin', 'pbkdf2_sha256$admin07hash', 'Administrador'),
('radmin', 'pbkdf2_sha256$admin08hash', 'Administrador'),
('sadmin', 'pbkdf2_sha256$admin09hash', 'Administrador'),
('tadmin', 'pbkdf2_sha256$admin10hash', 'Administrador'),
('lcoord', 'pbkdf2_sha256$coord11hash', 'Coordinador'),
('scoord', 'pbkdf2_sha256$coord12hash', 'Coordinador'),
('pcoord', 'pbkdf2_sha256$coord13hash', 'Coordinador'),
('ecoord', 'pbkdf2_sha256$coord14hash', 'Coordinador'),
('dcoord', 'pbkdf2_sha256$coord15hash', 'Coordinador'),
('ccoord', 'pbkdf2_sha256$coord16hash', 'Coordinador'),
('mcoord', 'pbkdf2_sha256$coord17hash', 'Coordinador'),
('ncoord', 'pbkdf2_sha256$coord18hash', 'Coordinador'),
('ocoord', 'pbkdf2_sha256$coord19hash', 'Coordinador'),
('qcoord', 'pbkdf2_sha256$coord20hash', 'Coordinador');

INSERT INTO administrador (id_usuario, nivel_permiso) VALUES
(1, 'Total'), (2, 'Total'), (3, 'Parcial'), (4, 'Parcial'), (5, 'Parcial'),
(6, 'Total'), (7, 'Parcial'), (8, 'Total'), (9, 'Parcial'), (10, 'Total');

INSERT INTO coordinador (id_usuario, zona_asignada) VALUES
(11, 'Zona Norte'), (12, 'Zona Sur'), (13, 'Zona Este'), (14, 'Zona Oeste'), (15, 'Zona Central'),
(16, 'Zona Rural'), (17, 'Zona Noreste'), (18, 'Zona Sureste'), (19, 'Zona Noroeste'), (20, 'Zona Industrial');

INSERT INTO requerimiento (id_evento, id_rol, cantidad_requerida) VALUES
(1, 1, 3), (1, 3, 5), (1, 5, 2), (2, 2, 2), (2, 4, 4),
(3, 3, 3), (3, 6, 2), (4, 9, 4), (4, 5, 1), (5, 4, 5),
(5, 8, 3), (6, 1, 4), (7, 2, 3), (8, 8, 4), (8, 7, 2);

INSERT INTO autorizacion (id_voluntario, id_rol, id_usuario_autorizador, fecha_autorizacion) VALUES
(1, 1, 1, '2024-02-01'), (1, 4, 1, '2024-02-01'),
(2, 3, 1, '2023-07-01'), (2, 7, 1, '2023-07-01'),
(3, 1, 2, '2023-04-15'), (3, 4, 2, '2023-04-15'),
(4, 3, 2, '2024-03-01'), (4, 7, 2, '2024-03-01'),
(5, 1, 1, '2023-02-10'), (5, 2, 1, '2023-02-10'),
(6, 4, 3, '2024-06-01'), (6, 9, 3, '2024-06-01'),
(7, 5, 3, '2023-09-15'), (7, 7, 3, '2023-09-15'),
(8, 4, 4, '2024-04-01'), (8, 9, 4, '2024-04-01'),
(11, 1, 2, '2024-08-15'), (11, 4, 2, '2024-08-15'),
(15, 1, 4, '2023-03-15'), (15, 2, 4, '2023-03-15');

INSERT INTO asignacion (id_voluntario, id_requerimiento, id_usuario_aprobador, hora_inicio, hora_fin, estado_asignacion, justificacion_cancelacion, fecha_cancelacion) VALUES
(1, 1, 11, '07:00', '12:00', 'Programada', NULL, NULL),
(5, 1, 11, '07:00', '12:00', 'Programada', NULL, NULL),
(15, 1, 12, '12:00', '17:00', 'Programada', NULL, NULL),
(2, 2, 11, '08:00', '13:00', 'Completada', NULL, NULL),
(3, 5, 13, '06:00', '14:00', 'Completada', NULL, NULL),
(5, 4, 13, '06:00', '14:00', 'Ausente', NULL, NULL),
(4, 6, 14, '09:00', '17:00', 'Completada', NULL, NULL),
(6, 8, 15, '07:00', '15:00', 'Programada', NULL, NULL),
(8, 8, 15, '07:00', '15:00', 'Programada', NULL, NULL),
(7, 9, 15, '08:00', '14:00', 'Completada', NULL, NULL),
(1, 10, 12, '06:00', '14:00', 'Cancelada', 'Emergencia familiar imprevista', '2026-07-28'),
(11, 10, 12, '06:00', '14:00', 'Completada', NULL, NULL),
(3, 12, 11, '06:00', '12:00', 'Ausente', NULL, NULL),
(15, 13, 13, '08:00', '16:00', 'Completada', NULL, NULL),
(4, 15, 16, '09:00', '13:00', 'Programada', NULL, NULL);

-- Section 4: INDEXES
CREATE INDEX idx_voluntario_id_grupo ON voluntario(id_grupo);
CREATE INDEX idx_voluntario_estado ON voluntario(estado_operativo);
CREATE INDEX idx_evento_fecha ON evento(fecha_programada);
CREATE INDEX idx_asignacion_estado ON asignacion(estado_asignacion);
CREATE INDEX idx_autorizacion_voluntario ON autorizacion(id_voluntario);
CREATE INDEX idx_requerimiento_evento ON requerimiento(id_evento);

-- Section 5: VIEWS
CREATE OR REPLACE VIEW vista_voluntarios AS
SELECT v.id_voluntario, v.nombres, v.apellidos, v.telefono, v.fecha_nacimiento, 
       TIMESTAMPDIFF(YEAR, v.fecha_nacimiento, CURDATE()) AS edad, 
       v.fecha_ingreso, v.estado_operativo, v.nivel_capacidad_fisica, 
       COALESCE(v.tipo_limitacion_fisica, 'Ninguna') AS tipo_limitacion_fisica, 
       COALESCE(v.descripcion_limitacion, 'N/A') AS descripcion_limitacion, 
       g.nombre_grupo
FROM voluntario v
JOIN grupo_pastoral g ON v.id_grupo = g.id_grupo
ORDER BY v.apellidos, v.nombres;

CREATE OR REPLACE VIEW vista_asignaciones AS
SELECT a.id_asignacion, CONCAT(v.nombres, ' ', v.apellidos) AS voluntario, 
       e.nombre_evento, e.fecha_programada, ce.nombre_categoria AS categoria_evento, 
       r.nombre_rol, a.hora_inicio, a.hora_fin, a.estado_asignacion, 
       u.nombre_usuario AS aprobado_por, 
       COALESCE(a.justificacion_cancelacion, '') AS justificacion_cancelacion, 
       a.fecha_cancelacion
FROM asignacion a
JOIN voluntario v ON a.id_voluntario = v.id_voluntario
JOIN requerimiento req ON a.id_requerimiento = req.id_requerimiento
JOIN evento e ON req.id_evento = e.id_evento
JOIN categoria_evento ce ON e.id_categoria = ce.id_categoria
JOIN rol r ON req.id_rol = r.id_rol
JOIN usuario u ON a.id_usuario_aprobador = u.id_usuario
ORDER BY e.fecha_programada, a.hora_inicio;

CREATE OR REPLACE VIEW reporte_asignaciones_completo AS
SELECT a.id_asignacion, CONCAT(v.nombres, ' ', v.apellidos) AS voluntario, 
       g.nombre_grupo, e.nombre_evento, ce.nombre_categoria AS categoria, 
       r.nombre_rol AS rol, a.hora_inicio, a.hora_fin, a.estado_asignacion, 
       u.nombre_usuario AS aprobador
FROM asignacion a
JOIN voluntario v ON a.id_voluntario = v.id_voluntario
JOIN grupo_pastoral g ON v.id_grupo = g.id_grupo
JOIN requerimiento req ON a.id_requerimiento = req.id_requerimiento
JOIN evento e ON req.id_evento = e.id_evento
JOIN categoria_evento ce ON e.id_categoria = ce.id_categoria
JOIN rol r ON req.id_rol = r.id_rol
JOIN usuario u ON a.id_usuario_aprobador = u.id_usuario;

CREATE OR REPLACE VIEW reporte_voluntarios_por_grupo AS
SELECT g.nombre_grupo AS grupo, CONCAT(v.nombres, ' ', v.apellidos) AS voluntario, 
       TIMESTAMPDIFF(YEAR, v.fecha_nacimiento, CURDATE()) AS edad, 
       v.estado_operativo AS estado, 
       GROUP_CONCAT(DISTINCT r.nombre_rol ORDER BY r.nombre_rol SEPARATOR ', ') AS roles_autorizados
FROM voluntario v
JOIN grupo_pastoral g ON v.id_grupo = g.id_grupo
LEFT JOIN autorizacion aut ON v.id_voluntario = aut.id_voluntario
LEFT JOIN rol r ON aut.id_rol = r.id_rol
GROUP BY v.id_voluntario, g.nombre_grupo
ORDER BY g.nombre_grupo;

CREATE OR REPLACE VIEW reporte_cobertura_eventos AS
SELECT e.nombre_evento AS evento, ce.nombre_categoria AS categoria, 
       g.nombre_grupo AS grupo, e.fecha_programada AS fecha, 
       r.nombre_rol AS rol, req.cantidad_requerida AS requeridos, 
       COUNT(a.id_asignacion) AS asignados, 
       ROUND(COUNT(a.id_asignacion) * 100.0 / req.cantidad_requerida, 1) AS porcentaje_cobertura
FROM evento e
JOIN categoria_evento ce ON e.id_categoria = ce.id_categoria
JOIN grupo_pastoral g ON e.id_grupo = g.id_grupo
JOIN requerimiento req ON e.id_evento = req.id_evento
JOIN rol r ON req.id_rol = r.id_rol
LEFT JOIN asignacion a ON req.id_requerimiento = a.id_requerimiento
GROUP BY req.id_requerimiento;

CREATE OR REPLACE VIEW reporte_actividad_usuarios AS
SELECT u.nombre_usuario AS usuario, u.rol_acceso AS tipo, 
       COALESCE(adm.nivel_permiso, coord.zona_asignada, 'N/A') AS info_subtipo, 
       (SELECT COUNT(*) FROM asignacion WHERE id_usuario_aprobador = u.id_usuario) AS total_aprobaciones, 
       (SELECT COUNT(*) FROM autorizacion WHERE id_usuario_autorizador = u.id_usuario) AS total_autorizaciones
FROM usuario u
LEFT JOIN administrador adm ON u.id_usuario = adm.id_usuario
LEFT JOIN coordinador coord ON u.id_usuario = coord.id_usuario;

-- Section 6: STORED PROCEDURES
DELIMITER //
CREATE PROCEDURE sp_insertar_grupo_pastoral(IN p_nombre VARCHAR(100), IN p_descripcion VARCHAR(255))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nombre de grupo no puede estar vacio';
    END IF;
    INSERT INTO grupo_pastoral (nombre_grupo, descripcion_grupo) VALUES (p_nombre, p_descripcion);
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_grupo_pastoral(IN p_id INT, IN p_nombre VARCHAR(100), IN p_descripcion VARCHAR(255))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF NOT EXISTS(SELECT 1 FROM grupo_pastoral WHERE id_grupo = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El grupo no existe';
    END IF;
    UPDATE grupo_pastoral SET nombre_grupo = p_nombre, descripcion_grupo = p_descripcion WHERE id_grupo = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_eliminar_grupo_pastoral(IN p_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF EXISTS(SELECT 1 FROM voluntario WHERE id_grupo = p_id) OR EXISTS(SELECT 1 FROM evento WHERE id_grupo = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar porque tiene dependencias';
    END IF;
    DELETE FROM grupo_pastoral WHERE id_grupo = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_insertar_categoria_evento(IN p_nombre VARCHAR(50), IN p_descripcion VARCHAR(255))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    INSERT INTO categoria_evento (nombre_categoria, descripcion_categoria) VALUES (p_nombre, p_descripcion);
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_categoria_evento(IN p_id INT, IN p_nombre VARCHAR(50), IN p_descripcion VARCHAR(255))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    UPDATE categoria_evento SET nombre_categoria = p_nombre, descripcion_categoria = p_descripcion WHERE id_categoria = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_eliminar_categoria_evento(IN p_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF EXISTS(SELECT 1 FROM evento WHERE id_categoria = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar porque tiene eventos';
    END IF;
    DELETE FROM categoria_evento WHERE id_categoria = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_insertar_rol(IN p_nombre VARCHAR(80), IN p_descripcion VARCHAR(255), IN p_requiere_epp BOOLEAN, IN p_nivel_fisico VARCHAR(10))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    INSERT INTO rol (nombre_rol, descripcion_rol, requiere_epp, nivel_demanda_fisica) VALUES (p_nombre, p_descripcion, p_requiere_epp, p_nivel_fisico);
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_rol(IN p_id INT, IN p_nombre VARCHAR(80), IN p_descripcion VARCHAR(255), IN p_requiere_epp BOOLEAN, IN p_nivel_fisico VARCHAR(10))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    UPDATE rol SET nombre_rol = p_nombre, descripcion_rol = p_descripcion, requiere_epp = p_requiere_epp, nivel_demanda_fisica = p_nivel_fisico WHERE id_rol = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_eliminar_rol(IN p_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF EXISTS(SELECT 1 FROM requerimiento WHERE id_rol = p_id) OR EXISTS(SELECT 1 FROM autorizacion WHERE id_rol = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar porque tiene dependencias';
    END IF;
    DELETE FROM rol WHERE id_rol = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_insertar_voluntario(IN p_id_grupo INT, IN p_nombres VARCHAR(80), IN p_apellidos VARCHAR(80), IN p_telefono VARCHAR(15), IN p_fecha_nac DATE, IN p_estado VARCHAR(15), IN p_nivel_fisico VARCHAR(10), IN p_tipo_limit VARCHAR(100), IN p_desc_limit VARCHAR(255))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF NOT EXISTS(SELECT 1 FROM grupo_pastoral WHERE id_grupo = p_id_grupo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Grupo no existe';
    END IF;
    IF p_fecha_nac > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fecha de nacimiento no valida';
    END IF;
    INSERT INTO voluntario (id_grupo, nombres, apellidos, telefono, fecha_nacimiento, estado_operativo, nivel_capacidad_fisica, tipo_limitacion_fisica, descripcion_limitacion) 
    VALUES (p_id_grupo, p_nombres, p_apellidos, p_telefono, p_fecha_nac, p_estado, p_nivel_fisico, p_tipo_limit, p_desc_limit);
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_voluntario(IN p_id INT, IN p_id_grupo INT, IN p_nombres VARCHAR(80), IN p_apellidos VARCHAR(80), IN p_telefono VARCHAR(15), IN p_fecha_nac DATE, IN p_estado VARCHAR(15), IN p_nivel_fisico VARCHAR(10), IN p_tipo_limit VARCHAR(100), IN p_desc_limit VARCHAR(255))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    UPDATE voluntario SET id_grupo = p_id_grupo, nombres = p_nombres, apellidos = p_apellidos, telefono = p_telefono, fecha_nacimiento = p_fecha_nac, estado_operativo = p_estado, nivel_capacidad_fisica = p_nivel_fisico, tipo_limitacion_fisica = p_tipo_limit, descripcion_limitacion = p_desc_limit WHERE id_voluntario = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_eliminar_voluntario(IN p_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF EXISTS(SELECT 1 FROM autorizacion WHERE id_voluntario = p_id) OR EXISTS(SELECT 1 FROM asignacion WHERE id_voluntario = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar porque tiene asignaciones';
    END IF;
    DELETE FROM voluntario WHERE id_voluntario = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_insertar_evento(IN p_id_grupo INT, IN p_id_categoria INT, IN p_nombre VARCHAR(120), IN p_fecha DATE, IN p_ubicacion VARCHAR(150))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    INSERT INTO evento (id_grupo, id_categoria, nombre_evento, fecha_programada, ubicacion) VALUES (p_id_grupo, p_id_categoria, p_nombre, p_fecha, p_ubicacion);
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_evento(IN p_id INT, IN p_id_grupo INT, IN p_id_categoria INT, IN p_nombre VARCHAR(120), IN p_fecha DATE, IN p_ubicacion VARCHAR(150))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    UPDATE evento SET id_grupo = p_id_grupo, id_categoria = p_id_categoria, nombre_evento = p_nombre, fecha_programada = p_fecha, ubicacion = p_ubicacion WHERE id_evento = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_eliminar_evento(IN p_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF EXISTS(SELECT 1 FROM requerimiento WHERE id_evento = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar evento con requerimientos';
    END IF;
    DELETE FROM evento WHERE id_evento = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_insertar_usuario(IN p_nombre VARCHAR(50), IN p_clave VARCHAR(255), IN p_rol VARCHAR(15), IN p_nivel_permiso VARCHAR(20), IN p_zona VARCHAR(50))
BEGIN
    DECLARE v_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    INSERT INTO usuario (nombre_usuario, clave_acceso, rol_acceso) VALUES (p_nombre, p_clave, p_rol);
    SET v_id = LAST_INSERT_ID();
    IF p_rol = 'Administrador' THEN
        INSERT INTO administrador (id_usuario, nivel_permiso) VALUES (v_id, p_nivel_permiso);
    ELSEIF p_rol = 'Coordinador' THEN
        INSERT INTO coordinador (id_usuario, zona_asignada) VALUES (v_id, p_zona);
    END IF;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_usuario(IN p_id INT, IN p_nombre VARCHAR(50), IN p_clave VARCHAR(255), IN p_nivel_permiso VARCHAR(20), IN p_zona VARCHAR(50))
BEGIN
    DECLARE v_rol VARCHAR(15);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    SELECT rol_acceso INTO v_rol FROM usuario WHERE id_usuario = p_id;
    UPDATE usuario SET nombre_usuario = p_nombre, clave_acceso = p_clave WHERE id_usuario = p_id;
    IF v_rol = 'Administrador' THEN
        UPDATE administrador SET nivel_permiso = p_nivel_permiso WHERE id_usuario = p_id;
    ELSEIF v_rol = 'Coordinador' THEN
        UPDATE coordinador SET zona_asignada = p_zona WHERE id_usuario = p_id;
    END IF;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_eliminar_usuario(IN p_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    DELETE FROM administrador WHERE id_usuario = p_id;
    DELETE FROM coordinador WHERE id_usuario = p_id;
    DELETE FROM usuario WHERE id_usuario = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_insertar_requerimiento(IN p_id_evento INT, IN p_id_rol INT, IN p_cantidad INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    INSERT INTO requerimiento (id_evento, id_rol, cantidad_requerida) VALUES (p_id_evento, p_id_rol, p_cantidad);
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_requerimiento(IN p_id INT, IN p_cantidad INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    UPDATE requerimiento SET cantidad_requerida = p_cantidad WHERE id_requerimiento = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_eliminar_requerimiento(IN p_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF EXISTS(SELECT 1 FROM asignacion WHERE id_requerimiento = p_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede eliminar por tener asignaciones';
    END IF;
    DELETE FROM requerimiento WHERE id_requerimiento = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_insertar_autorizacion(IN p_id_vol INT, IN p_id_rol INT, IN p_id_autorizador INT, IN p_fecha DATE)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    INSERT INTO autorizacion (id_voluntario, id_rol, id_usuario_autorizador, fecha_autorizacion) VALUES (p_id_vol, p_id_rol, p_id_autorizador, p_fecha);
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_eliminar_autorizacion(IN p_id_vol INT, IN p_id_rol INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    DELETE FROM autorizacion WHERE id_voluntario = p_id_vol AND id_rol = p_id_rol;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_autorizacion(IN p_id_vol INT, IN p_id_rol INT, IN p_id_autorizador INT, IN p_fecha DATE)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    IF NOT EXISTS (SELECT 1 FROM autorizacion WHERE id_voluntario = p_id_vol AND id_rol = p_id_rol) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La autorizacion no existe';
    END IF;
    UPDATE autorizacion SET id_usuario_autorizador = p_id_autorizador, fecha_autorizacion = p_fecha
        WHERE id_voluntario = p_id_vol AND id_rol = p_id_rol;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_insertar_asignacion(IN p_id_vol INT, IN p_id_req INT, IN p_id_aprobador INT, IN p_hora_ini TIME, IN p_hora_fin TIME, IN p_estado VARCHAR(15))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    INSERT INTO asignacion (id_voluntario, id_requerimiento, id_usuario_aprobador, hora_inicio, hora_fin, estado_asignacion) VALUES (p_id_vol, p_id_req, p_id_aprobador, p_hora_ini, p_hora_fin, p_estado);
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_actualizar_asignacion(IN p_id INT, IN p_hora_ini TIME, IN p_hora_fin TIME, IN p_estado VARCHAR(15), IN p_justificacion VARCHAR(500), IN p_fecha_cancel DATE)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    UPDATE asignacion SET hora_inicio = p_hora_ini, hora_fin = p_hora_fin, estado_asignacion = p_estado, justificacion_cancelacion = p_justificacion, fecha_cancelacion = p_fecha_cancel WHERE id_asignacion = p_id;
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE PROCEDURE sp_eliminar_asignacion(IN p_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    DELETE FROM asignacion WHERE id_asignacion = p_id;
    COMMIT;
END //
DELIMITER ;

-- Section 7: TRIGGERS
DELIMITER //
CREATE TRIGGER trg_verificar_autorizacion_asignacion
    BEFORE INSERT ON asignacion
    FOR EACH ROW
BEGIN
    DECLARE v_id_rol INT;
    DECLARE v_count INT;
    SELECT id_rol INTO v_id_rol FROM requerimiento WHERE id_requerimiento = NEW.id_requerimiento;
    SELECT COUNT(*) INTO v_count FROM autorizacion WHERE id_voluntario = NEW.id_voluntario AND id_rol = v_id_rol;
    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El voluntario no esta autorizado para este rol';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_audit_cambio_estado_voluntario
    AFTER UPDATE ON voluntario
    FOR EACH ROW
BEGIN
    IF OLD.estado_operativo <> NEW.estado_operativo THEN
        INSERT INTO audit_voluntario (id_voluntario, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (NEW.id_voluntario, 'estado_operativo', OLD.estado_operativo, NEW.estado_operativo);
    END IF;
    IF OLD.nombres <> NEW.nombres THEN
        INSERT INTO audit_voluntario (id_voluntario, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (NEW.id_voluntario, 'nombres', OLD.nombres, NEW.nombres);
    END IF;
    IF OLD.apellidos <> NEW.apellidos THEN
        INSERT INTO audit_voluntario (id_voluntario, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (NEW.id_voluntario, 'apellidos', OLD.apellidos, NEW.apellidos);
    END IF;
END //
DELIMITER ;

-- Section 8: USERS AND PERMISSIONS
CREATE USER IF NOT EXISTS 'admin_sigevep'@'localhost' IDENTIFIED BY 'Admin2026!';
CREATE USER IF NOT EXISTS 'coordinador_sigevep'@'localhost' IDENTIFIED BY 'Coord2026!';
CREATE USER IF NOT EXISTS 'consultor_sigevep'@'localhost' IDENTIFIED BY 'Consul2026!';
CREATE USER IF NOT EXISTS 'operador_sigevep'@'localhost' IDENTIFIED BY 'Oper2026!';
CREATE USER IF NOT EXISTS 'auditor_sigevep'@'localhost' IDENTIFIED BY 'Audit2026!';

GRANT ALL PRIVILEGES ON sigevep.* TO 'admin_sigevep'@'localhost';

GRANT SELECT, INSERT, UPDATE ON sigevep.asignacion TO 'coordinador_sigevep'@'localhost';
GRANT SELECT, INSERT, UPDATE ON sigevep.autorizacion TO 'coordinador_sigevep'@'localhost';
GRANT EXECUTE ON PROCEDURE sigevep.sp_insertar_asignacion TO 'coordinador_sigevep'@'localhost';
GRANT EXECUTE ON PROCEDURE sigevep.sp_insertar_autorizacion TO 'coordinador_sigevep'@'localhost';
GRANT SELECT ON sigevep.reporte_asignaciones_completo TO 'coordinador_sigevep'@'localhost';
GRANT SELECT ON sigevep.reporte_cobertura_eventos TO 'coordinador_sigevep'@'localhost';

GRANT SELECT ON sigevep.reporte_asignaciones_completo TO 'consultor_sigevep'@'localhost';
GRANT SELECT ON sigevep.reporte_voluntarios_por_grupo TO 'consultor_sigevep'@'localhost';
GRANT SELECT ON sigevep.reporte_cobertura_eventos TO 'consultor_sigevep'@'localhost';
GRANT SELECT ON sigevep.reporte_actividad_usuarios TO 'consultor_sigevep'@'localhost';
GRANT EXECUTE ON PROCEDURE sigevep.sp_insertar_grupo_pastoral TO 'consultor_sigevep'@'localhost';

GRANT EXECUTE ON PROCEDURE sigevep.sp_insertar_voluntario TO 'operador_sigevep'@'localhost';
GRANT EXECUTE ON PROCEDURE sigevep.sp_actualizar_voluntario TO 'operador_sigevep'@'localhost';
GRANT EXECUTE ON PROCEDURE sigevep.sp_insertar_evento TO 'operador_sigevep'@'localhost';
GRANT SELECT ON sigevep.vista_voluntarios TO 'operador_sigevep'@'localhost';
GRANT SELECT ON sigevep.reporte_voluntarios_por_grupo TO 'operador_sigevep'@'localhost';

GRANT SELECT ON sigevep.audit_voluntario TO 'auditor_sigevep'@'localhost';
GRANT SELECT ON sigevep.reporte_asignaciones_completo TO 'auditor_sigevep'@'localhost';
GRANT SELECT ON sigevep.reporte_voluntarios_por_grupo TO 'auditor_sigevep'@'localhost';
GRANT SELECT ON sigevep.reporte_cobertura_eventos TO 'auditor_sigevep'@'localhost';
GRANT SELECT ON sigevep.reporte_actividad_usuarios TO 'auditor_sigevep'@'localhost';
GRANT EXECUTE ON PROCEDURE sigevep.sp_insertar_autorizacion TO 'auditor_sigevep'@'localhost';

FLUSH PRIVILEGES;
