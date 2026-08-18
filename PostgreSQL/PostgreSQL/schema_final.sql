-- ==========================================
-- SCRIPT DE BASE DE DATOS SIGEVEP
-- PostgreSQL / Supabase
-- ==========================================

-- ==========================================
-- SECCIÓN 1: LIMPIEZA (DROP)
-- ==========================================
-- Eliminar triggers y funciones (si existen)
DROP TRIGGER IF EXISTS trg_verificar_autorizacion_asignacion ON asignacion CASCADE;
DROP TRIGGER IF EXISTS trg_audit_cambio_estado_voluntario ON voluntario CASCADE;
DROP FUNCTION IF EXISTS fn_verificar_autorizacion() CASCADE;
DROP FUNCTION IF EXISTS fn_audit_cambio_estado() CASCADE;

-- Eliminar Stored Procedures (Funciones CRUD)
DROP FUNCTION IF EXISTS sp_insertar_grupo_pastoral CASCADE;
DROP FUNCTION IF EXISTS sp_actualizar_grupo_pastoral CASCADE;
DROP FUNCTION IF EXISTS sp_eliminar_grupo_pastoral CASCADE;
DROP FUNCTION IF EXISTS sp_insertar_categoria_evento CASCADE;
DROP FUNCTION IF EXISTS sp_actualizar_categoria_evento CASCADE;
DROP FUNCTION IF EXISTS sp_eliminar_categoria_evento CASCADE;
DROP FUNCTION IF EXISTS sp_insertar_rol CASCADE;
DROP FUNCTION IF EXISTS sp_actualizar_rol CASCADE;
DROP FUNCTION IF EXISTS sp_eliminar_rol CASCADE;
DROP FUNCTION IF EXISTS sp_insertar_voluntario CASCADE;
DROP FUNCTION IF EXISTS sp_actualizar_voluntario CASCADE;
DROP FUNCTION IF EXISTS sp_eliminar_voluntario CASCADE;
DROP FUNCTION IF EXISTS sp_insertar_evento CASCADE;
DROP FUNCTION IF EXISTS sp_actualizar_evento CASCADE;
DROP FUNCTION IF EXISTS sp_eliminar_evento CASCADE;
DROP FUNCTION IF EXISTS sp_insertar_usuario CASCADE;
DROP FUNCTION IF EXISTS sp_actualizar_usuario CASCADE;
DROP FUNCTION IF EXISTS sp_eliminar_usuario CASCADE;
DROP FUNCTION IF EXISTS sp_insertar_requerimiento CASCADE;
DROP FUNCTION IF EXISTS sp_actualizar_requerimiento CASCADE;
DROP FUNCTION IF EXISTS sp_eliminar_requerimiento CASCADE;
DROP FUNCTION IF EXISTS sp_insertar_autorizacion CASCADE;
DROP FUNCTION IF EXISTS sp_eliminar_autorizacion CASCADE;
DROP FUNCTION IF EXISTS sp_insertar_asignacion CASCADE;
DROP FUNCTION IF EXISTS sp_actualizar_asignacion CASCADE;
DROP FUNCTION IF EXISTS sp_eliminar_asignacion CASCADE;

-- Eliminar Vistas (nuevas y originales)
DROP VIEW IF EXISTS reporte_asignaciones_completo CASCADE;
DROP VIEW IF EXISTS reporte_voluntarios_por_grupo CASCADE;
DROP VIEW IF EXISTS reporte_cobertura_eventos CASCADE;
DROP VIEW IF EXISTS reporte_actividad_usuarios CASCADE;
DROP VIEW IF EXISTS vista_asignaciones CASCADE;
DROP VIEW IF EXISTS vista_voluntarios CASCADE;

-- Eliminar Índices
DROP INDEX IF EXISTS idx_voluntario_id_grupo CASCADE;
DROP INDEX IF EXISTS idx_voluntario_estado CASCADE;
DROP INDEX IF EXISTS idx_evento_fecha CASCADE;
DROP INDEX IF EXISTS idx_asignacion_estado CASCADE;
DROP INDEX IF EXISTS idx_autorizacion_voluntario CASCADE;
DROP INDEX IF EXISTS idx_requerimiento_evento CASCADE;

-- Eliminar Tabla de Auditoría
DROP TABLE IF EXISTS audit_voluntario CASCADE;

-- Eliminar Tablas Originales (en orden inverso de dependencias)
DROP TABLE IF EXISTS asignacion CASCADE;
DROP TABLE IF EXISTS autorizacion CASCADE;
DROP TABLE IF EXISTS requerimiento CASCADE;
DROP TABLE IF EXISTS coordinador CASCADE;
DROP TABLE IF EXISTS administrador CASCADE;
DROP TABLE IF EXISTS usuario CASCADE;
DROP TABLE IF EXISTS evento CASCADE;
DROP TABLE IF EXISTS voluntario CASCADE;
DROP TABLE IF EXISTS rol CASCADE;
DROP TABLE IF EXISTS categoria_evento CASCADE;
DROP TABLE IF EXISTS grupo_pastoral CASCADE;

-- Eliminar Tipos de Datos
DROP TYPE IF EXISTS enum_estado_operativo CASCADE;
DROP TYPE IF EXISTS enum_nivel_fisico CASCADE;
DROP TYPE IF EXISTS enum_rol_acceso CASCADE;
DROP TYPE IF EXISTS enum_estado_asignacion CASCADE;


-- ==========================================
-- SECCIÓN 2: TIPOS
-- ==========================================
CREATE TYPE enum_estado_operativo AS ENUM ('Activo', 'Inactivo', 'Suspendido');
CREATE TYPE enum_nivel_fisico AS ENUM ('Alto', 'Medio', 'Bajo');
CREATE TYPE enum_rol_acceso AS ENUM ('Administrador', 'Coordinador');
CREATE TYPE enum_estado_asignacion AS ENUM ('Programada', 'Completada', 'Ausente', 'Cancelada');


-- ==========================================
-- SECCIÓN 3: TABLAS
-- ==========================================
CREATE TABLE grupo_pastoral (
    id_grupo SERIAL PRIMARY KEY,
    nombre_grupo VARCHAR(100) NOT NULL UNIQUE,
    descripcion_grupo VARCHAR(255)
);

CREATE TABLE categoria_evento (
    id_categoria SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL UNIQUE,
    descripcion_categoria VARCHAR(255)
);

CREATE TABLE rol (
    id_rol SERIAL PRIMARY KEY,
    nombre_rol VARCHAR(80) NOT NULL UNIQUE,
    descripcion_rol VARCHAR(255) NOT NULL,
    requiere_epp BOOLEAN NOT NULL DEFAULT FALSE,
    nivel_demanda_fisica enum_nivel_fisico NOT NULL
);

CREATE TABLE voluntario (
    id_voluntario SERIAL PRIMARY KEY,
    id_grupo INT NOT NULL REFERENCES grupo_pastoral(id_grupo),
    nombres VARCHAR(80) NOT NULL,
    apellidos VARCHAR(80) NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    fecha_ingreso DATE NOT NULL DEFAULT CURRENT_DATE,
    estado_operativo enum_estado_operativo NOT NULL DEFAULT 'Activo',
    nivel_capacidad_fisica enum_nivel_fisico NOT NULL,
    tipo_limitacion_fisica VARCHAR(100),
    descripcion_limitacion VARCHAR(255)
);

CREATE TABLE evento (
    id_evento SERIAL PRIMARY KEY,
    id_grupo INT NOT NULL REFERENCES grupo_pastoral(id_grupo),
    id_categoria INT NOT NULL REFERENCES categoria_evento(id_categoria),
    nombre_evento VARCHAR(120) NOT NULL,
    fecha_programada DATE NOT NULL,
    ubicacion VARCHAR(150) NOT NULL
);

CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nombre_usuario VARCHAR(50) NOT NULL UNIQUE,
    clave_acceso VARCHAR(255) NOT NULL,
    rol_acceso enum_rol_acceso NOT NULL
);

CREATE TABLE administrador (
    id_usuario INT PRIMARY KEY REFERENCES usuario(id_usuario),
    nivel_permiso VARCHAR(20) NOT NULL DEFAULT 'Total'
        CHECK (nivel_permiso IN ('Total', 'Parcial'))
);

CREATE TABLE coordinador (
    id_usuario INT PRIMARY KEY REFERENCES usuario(id_usuario),
    zona_asignada VARCHAR(50) NOT NULL
);

CREATE TABLE requerimiento (
    id_requerimiento SERIAL PRIMARY KEY,
    id_evento INT NOT NULL REFERENCES evento(id_evento),
    id_rol INT NOT NULL REFERENCES rol(id_rol),
    cantidad_requerida INT NOT NULL CHECK (cantidad_requerida > 0),
    UNIQUE (id_evento, id_rol)
);

CREATE TABLE autorizacion (
    id_voluntario INT NOT NULL REFERENCES voluntario(id_voluntario),
    id_rol INT NOT NULL REFERENCES rol(id_rol),
    id_usuario_autorizador INT NOT NULL REFERENCES usuario(id_usuario),
    fecha_autorizacion DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (id_voluntario, id_rol)
);

CREATE TABLE asignacion (
    id_asignacion SERIAL PRIMARY KEY,
    id_voluntario INT NOT NULL REFERENCES voluntario(id_voluntario),
    id_requerimiento INT NOT NULL REFERENCES requerimiento(id_requerimiento),
    id_usuario_aprobador INT NOT NULL REFERENCES usuario(id_usuario),
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    estado_asignacion enum_estado_asignacion NOT NULL DEFAULT 'Programada',
    justificacion_cancelacion VARCHAR(500),
    fecha_cancelacion DATE,
    CHECK (hora_fin > hora_inicio)
);

CREATE TABLE audit_voluntario (
    id_audit SERIAL PRIMARY KEY,
    id_voluntario INT NOT NULL,
    campo_modificado VARCHAR(50) NOT NULL,
    valor_anterior TEXT,
    valor_nuevo TEXT,
    fecha_cambio TIMESTAMP NOT NULL DEFAULT NOW(),
    usuario_bd VARCHAR(50) NOT NULL DEFAULT CURRENT_USER
);


-- ==========================================
-- SECCIÓN 4: INSERT DATA
-- ==========================================

-- GRUPO_PASTORAL (10)
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

-- CATEGORIA_EVENTO (10)
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

-- ROL (10)
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

-- VOLUNTARIO (15)
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

-- EVENTO (12)
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

-- USUARIO (20)
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

-- ADMINISTRADOR (10)
INSERT INTO administrador (id_usuario, nivel_permiso) VALUES
(1, 'Total'), (2, 'Total'), (3, 'Parcial'), (4, 'Parcial'), (5, 'Parcial'),
(6, 'Total'), (7, 'Parcial'), (8, 'Total'), (9, 'Parcial'), (10, 'Total');

-- COORDINADOR (10)
INSERT INTO coordinador (id_usuario, zona_asignada) VALUES
(11, 'Zona Norte'), (12, 'Zona Sur'), (13, 'Zona Este'), (14, 'Zona Oeste'), (15, 'Zona Central'),
(16, 'Zona Rural'), (17, 'Zona Noreste'), (18, 'Zona Sureste'), (19, 'Zona Noroeste'), (20, 'Zona Industrial');

-- REQUERIMIENTO (15)
INSERT INTO requerimiento (id_evento, id_rol, cantidad_requerida) VALUES
(1, 1, 3), (1, 3, 5), (1, 5, 2), (2, 2, 2), (2, 4, 4),
(3, 3, 3), (3, 6, 2), (4, 9, 4), (4, 5, 1), (5, 4, 5),
(5, 8, 3), (6, 1, 4), (7, 2, 3), (8, 8, 4), (8, 7, 2);

-- AUTORIZACION (20)
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

-- ASIGNACION (15)
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


-- ==========================================
-- SECCIÓN 5: ÍNDICES
-- ==========================================
-- 1. Acelera JOINs al listar voluntarios por grupo pastoral
CREATE INDEX idx_voluntario_id_grupo ON voluntario(id_grupo);

-- 2. Acelera filtros por estado activo/inactivo
CREATE INDEX idx_voluntario_estado ON voluntario(estado_operativo);

-- 3. Acelera búsquedas y reportes por rango de fechas
CREATE INDEX idx_evento_fecha ON evento(fecha_programada);

-- 4. Acelera filtros por estado de asignación en reportes
CREATE INDEX idx_asignacion_estado ON asignacion(estado_asignacion);

-- 5. Acelera verificación de autorizaciones por voluntario
CREATE INDEX idx_autorizacion_voluntario ON autorizacion(id_voluntario);

-- 6. Acelera consultas de requerimientos por evento
CREATE INDEX idx_requerimiento_evento ON requerimiento(id_evento);


-- ==========================================
-- SECCIÓN 6: VISTAS
-- ==========================================

-- Vistas Originales
CREATE OR REPLACE VIEW vista_voluntarios AS
SELECT v.id_voluntario, v.nombres, v.apellidos, v.telefono, v.fecha_nacimiento,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, v.fecha_nacimiento))::INT AS edad,
    v.fecha_ingreso, v.estado_operativo::TEXT, v.nivel_capacidad_fisica::TEXT,
    COALESCE(v.tipo_limitacion_fisica, 'Ninguna') AS tipo_limitacion_fisica,
    COALESCE(v.descripcion_limitacion, 'N/A') AS descripcion_limitacion,
    g.nombre_grupo
FROM voluntario v
JOIN grupo_pastoral g ON v.id_grupo = g.id_grupo
ORDER BY v.apellidos, v.nombres;

CREATE OR REPLACE VIEW vista_asignaciones AS
SELECT a.id_asignacion,
    v.nombres || ' ' || v.apellidos AS voluntario,
    e.nombre_evento, e.fecha_programada,
    ce.nombre_categoria AS categoria_evento,
    r.nombre_rol, a.hora_inicio, a.hora_fin,
    a.estado_asignacion::TEXT, u.nombre_usuario AS aprobado_por,
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

-- Nuevas Vistas (Reportes)
CREATE OR REPLACE VIEW reporte_asignaciones_completo AS
SELECT 
    v.nombres || ' ' || v.apellidos AS nombre_voluntario,
    e.nombre_evento,
    ce.nombre_categoria AS categoria,
    g.nombre_grupo AS grupo_pastoral,
    r.nombre_rol AS rol_asignado,
    a.hora_inicio || ' - ' || a.hora_fin AS horario,
    a.estado_asignacion,
    u.nombre_usuario AS aprobador
FROM asignacion a
JOIN voluntario v ON a.id_voluntario = v.id_voluntario
JOIN requerimiento req ON a.id_requerimiento = req.id_requerimiento
JOIN evento e ON req.id_evento = e.id_evento
JOIN categoria_evento ce ON e.id_categoria = ce.id_categoria
JOIN grupo_pastoral g ON v.id_grupo = g.id_grupo
JOIN rol r ON req.id_rol = r.id_rol
JOIN usuario u ON a.id_usuario_aprobador = u.id_usuario;

CREATE OR REPLACE VIEW reporte_voluntarios_por_grupo AS
SELECT 
    g.nombre_grupo,
    v.nombres || ' ' || v.apellidos AS nombre_voluntario,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, v.fecha_nacimiento))::INT AS edad,
    v.estado_operativo,
    STRING_AGG(r.nombre_rol, ', ') AS roles_autorizados
FROM voluntario v
JOIN grupo_pastoral g ON v.id_grupo = g.id_grupo
LEFT JOIN autorizacion aut ON v.id_voluntario = aut.id_voluntario
LEFT JOIN rol r ON aut.id_rol = r.id_rol
GROUP BY g.nombre_grupo, v.nombres, v.apellidos, v.fecha_nacimiento, v.estado_operativo;

CREATE OR REPLACE VIEW reporte_cobertura_eventos AS
SELECT 
    e.nombre_evento,
    ce.nombre_categoria AS categoria,
    g.nombre_grupo AS grupo_organizador,
    r.nombre_rol AS rol_requerido,
    req.cantidad_requerida,
    COUNT(a.id_asignacion) AS cantidad_asignada,
    ROUND((COUNT(a.id_asignacion) * 100.0) / req.cantidad_requerida, 2) AS porcentaje_cobertura
FROM evento e
JOIN categoria_evento ce ON e.id_categoria = ce.id_categoria
JOIN grupo_pastoral g ON e.id_grupo = g.id_grupo
JOIN requerimiento req ON e.id_evento = req.id_evento
JOIN rol r ON req.id_rol = r.id_rol
LEFT JOIN asignacion a ON req.id_requerimiento = a.id_requerimiento
GROUP BY e.nombre_evento, ce.nombre_categoria, g.nombre_grupo, r.nombre_rol, req.cantidad_requerida;

CREATE OR REPLACE VIEW reporte_actividad_usuarios AS
SELECT 
    u.nombre_usuario,
    u.rol_acceso,
    COALESCE(adm.nivel_permiso, c.zona_asignada, 'N/A') AS detalle_subtipo,
    COUNT(DISTINCT a.id_asignacion) AS total_aprobaciones,
    COUNT(DISTINCT aut.id_voluntario || '-' || aut.id_rol) AS total_autorizaciones
FROM usuario u
LEFT JOIN administrador adm ON u.id_usuario = adm.id_usuario
LEFT JOIN coordinador c ON u.id_usuario = c.id_usuario
LEFT JOIN asignacion a ON u.id_usuario = a.id_usuario_aprobador
LEFT JOIN autorizacion aut ON u.id_usuario = aut.id_usuario_autorizador
GROUP BY u.nombre_usuario, u.rol_acceso, adm.nivel_permiso, c.zona_asignada;


-- ==========================================
-- SECCIÓN 7: STORED PROCEDURES (CRUD)
-- ==========================================

-- GRUPO PASTORAL
CREATE OR REPLACE FUNCTION sp_insertar_grupo_pastoral(p_nombre VARCHAR, p_descripcion VARCHAR)
RETURNS JSON AS $$
DECLARE v_result RECORD;
BEGIN
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        RAISE EXCEPTION 'El nombre del grupo no puede estar vacío';
    END IF;
    INSERT INTO grupo_pastoral(nombre_grupo, descripcion_grupo)
    VALUES (p_nombre, p_descripcion) RETURNING * INTO v_result;
    RETURN row_to_json(v_result);
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_actualizar_grupo_pastoral(p_id INT, p_nombre VARCHAR, p_descripcion VARCHAR)
RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM grupo_pastoral WHERE id_grupo = p_id) THEN
        RAISE EXCEPTION 'El grupo pastoral % no existe', p_id;
    END IF;
    UPDATE grupo_pastoral
    SET nombre_grupo = p_nombre, descripcion_grupo = p_descripcion
    WHERE id_grupo = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_eliminar_grupo_pastoral(p_id INT)
RETURNS VOID AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM voluntario WHERE id_grupo = p_id) OR EXISTS (SELECT 1 FROM evento WHERE id_grupo = p_id) THEN
        RAISE EXCEPTION 'No se puede eliminar el grupo porque tiene voluntarios o eventos asociados';
    END IF;
    DELETE FROM grupo_pastoral WHERE id_grupo = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

-- CATEGORIA EVENTO
CREATE OR REPLACE FUNCTION sp_insertar_categoria_evento(p_nombre VARCHAR, p_descripcion VARCHAR)
RETURNS JSON AS $$
DECLARE v_result RECORD;
BEGIN
    INSERT INTO categoria_evento(nombre_categoria, descripcion_categoria)
    VALUES (p_nombre, p_descripcion) RETURNING * INTO v_result;
    RETURN row_to_json(v_result);
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_actualizar_categoria_evento(p_id INT, p_nombre VARCHAR, p_descripcion VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE categoria_evento
    SET nombre_categoria = p_nombre, descripcion_categoria = p_descripcion
    WHERE id_categoria = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_eliminar_categoria_evento(p_id INT)
RETURNS VOID AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM evento WHERE id_categoria = p_id) THEN
        RAISE EXCEPTION 'No se puede eliminar la categoría porque tiene eventos asociados';
    END IF;
    DELETE FROM categoria_evento WHERE id_categoria = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

-- ROL
CREATE OR REPLACE FUNCTION sp_insertar_rol(p_nombre VARCHAR, p_descripcion VARCHAR, p_requiere_epp BOOLEAN, p_nivel_fisico VARCHAR)
RETURNS JSON AS $$
DECLARE v_result RECORD;
BEGIN
    INSERT INTO rol(nombre_rol, descripcion_rol, requiere_epp, nivel_demanda_fisica)
    VALUES (p_nombre, p_descripcion, p_requiere_epp, p_nivel_fisico::enum_nivel_fisico) RETURNING * INTO v_result;
    RETURN row_to_json(v_result);
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_actualizar_rol(p_id INT, p_nombre VARCHAR, p_descripcion VARCHAR, p_requiere_epp BOOLEAN, p_nivel_fisico VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE rol
    SET nombre_rol = p_nombre, descripcion_rol = p_descripcion, requiere_epp = p_requiere_epp, nivel_demanda_fisica = p_nivel_fisico::enum_nivel_fisico
    WHERE id_rol = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_eliminar_rol(p_id INT)
RETURNS VOID AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM requerimiento WHERE id_rol = p_id) OR EXISTS (SELECT 1 FROM autorizacion WHERE id_rol = p_id) THEN
        RAISE EXCEPTION 'No se puede eliminar el rol porque está en uso en requerimientos o autorizaciones';
    END IF;
    DELETE FROM rol WHERE id_rol = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

-- VOLUNTARIO
CREATE OR REPLACE FUNCTION sp_insertar_voluntario(p_id_grupo INT, p_nombres VARCHAR, p_apellidos VARCHAR, p_telefono VARCHAR, p_fecha_nac DATE, p_estado VARCHAR, p_nivel_fisico VARCHAR, p_tipo_limit VARCHAR, p_desc_limit VARCHAR)
RETURNS JSON AS $$
DECLARE v_result RECORD;
BEGIN
    IF p_fecha_nac > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de nacimiento no puede estar en el futuro';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM grupo_pastoral WHERE id_grupo = p_id_grupo) THEN
        RAISE EXCEPTION 'El grupo pastoral no existe';
    END IF;
    INSERT INTO voluntario(id_grupo, nombres, apellidos, telefono, fecha_nacimiento, estado_operativo, nivel_capacidad_fisica, tipo_limitacion_fisica, descripcion_limitacion)
    VALUES (p_id_grupo, p_nombres, p_apellidos, p_telefono, p_fecha_nac, p_estado::enum_estado_operativo, p_nivel_fisico::enum_nivel_fisico, p_tipo_limit, p_desc_limit)
    RETURNING * INTO v_result;
    RETURN row_to_json(v_result);
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_actualizar_voluntario(p_id INT, p_id_grupo INT, p_nombres VARCHAR, p_apellidos VARCHAR, p_telefono VARCHAR, p_fecha_nac DATE, p_estado VARCHAR, p_nivel_fisico VARCHAR, p_tipo_limit VARCHAR, p_desc_limit VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE voluntario
    SET id_grupo = p_id_grupo, nombres = p_nombres, apellidos = p_apellidos, telefono = p_telefono, fecha_nacimiento = p_fecha_nac, estado_operativo = p_estado::enum_estado_operativo, nivel_capacidad_fisica = p_nivel_fisico::enum_nivel_fisico, tipo_limitacion_fisica = p_tipo_limit, descripcion_limitacion = p_desc_limit
    WHERE id_voluntario = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_eliminar_voluntario(p_id INT)
RETURNS VOID AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM autorizacion WHERE id_voluntario = p_id) OR EXISTS (SELECT 1 FROM asignacion WHERE id_voluntario = p_id) THEN
        RAISE EXCEPTION 'No se puede eliminar el voluntario por tener autorizaciones o asignaciones asociadas';
    END IF;
    DELETE FROM voluntario WHERE id_voluntario = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

-- EVENTO
CREATE OR REPLACE FUNCTION sp_insertar_evento(p_id_grupo INT, p_id_categoria INT, p_nombre VARCHAR, p_fecha DATE, p_ubicacion VARCHAR)
RETURNS JSON AS $$
DECLARE v_result RECORD;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM grupo_pastoral WHERE id_grupo = p_id_grupo) THEN
        RAISE EXCEPTION 'El grupo pastoral no existe';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM categoria_evento WHERE id_categoria = p_id_categoria) THEN
        RAISE EXCEPTION 'La categoria no existe';
    END IF;
    INSERT INTO evento(id_grupo, id_categoria, nombre_evento, fecha_programada, ubicacion)
    VALUES (p_id_grupo, p_id_categoria, p_nombre, p_fecha, p_ubicacion)
    RETURNING * INTO v_result;
    RETURN row_to_json(v_result);
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_actualizar_evento(p_id INT, p_id_grupo INT, p_id_categoria INT, p_nombre VARCHAR, p_fecha DATE, p_ubicacion VARCHAR)
RETURNS VOID AS $$
BEGIN
    UPDATE evento
    SET id_grupo = p_id_grupo, id_categoria = p_id_categoria, nombre_evento = p_nombre, fecha_programada = p_fecha, ubicacion = p_ubicacion
    WHERE id_evento = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_eliminar_evento(p_id INT)
RETURNS VOID AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM requerimiento WHERE id_evento = p_id) THEN
        RAISE EXCEPTION 'No se puede eliminar el evento porque tiene requerimientos asociados';
    END IF;
    DELETE FROM evento WHERE id_evento = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

-- USUARIO (con control de subtipos)
CREATE OR REPLACE FUNCTION sp_insertar_usuario(p_nombre VARCHAR, p_clave VARCHAR, p_rol VARCHAR, p_nivel_permiso VARCHAR DEFAULT NULL, p_zona VARCHAR DEFAULT NULL)
RETURNS JSON AS $$
DECLARE 
    v_id_usuario INT;
    v_result RECORD;
BEGIN
    INSERT INTO usuario (nombre_usuario, clave_acceso, rol_acceso)
    VALUES (p_nombre, p_clave, p_rol::enum_rol_acceso)
    RETURNING id_usuario INTO v_id_usuario;

    IF p_rol = 'Administrador' THEN
        INSERT INTO administrador (id_usuario, nivel_permiso)
        VALUES (v_id_usuario, COALESCE(p_nivel_permiso, 'Total'));
    ELSIF p_rol = 'Coordinador' THEN
        IF p_zona IS NULL THEN
            RAISE EXCEPTION 'Un coordinador debe tener una zona asignada';
        END IF;
        INSERT INTO coordinador (id_usuario, zona_asignada)
        VALUES (v_id_usuario, p_zona);
    END IF;

    SELECT * INTO v_result FROM usuario WHERE id_usuario = v_id_usuario;
    RETURN row_to_json(v_result);
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_actualizar_usuario(p_id INT, p_nombre VARCHAR, p_clave VARCHAR, p_nivel_permiso VARCHAR DEFAULT NULL, p_zona VARCHAR DEFAULT NULL)
RETURNS VOID AS $$
DECLARE v_rol enum_rol_acceso;
BEGIN
    SELECT rol_acceso INTO v_rol FROM usuario WHERE id_usuario = p_id;
    UPDATE usuario SET nombre_usuario = p_nombre, clave_acceso = p_clave WHERE id_usuario = p_id;
    
    IF v_rol = 'Administrador' AND p_nivel_permiso IS NOT NULL THEN
        UPDATE administrador SET nivel_permiso = p_nivel_permiso WHERE id_usuario = p_id;
    ELSIF v_rol = 'Coordinador' AND p_zona IS NOT NULL THEN
        UPDATE coordinador SET zona_asignada = p_zona WHERE id_usuario = p_id;
    END IF;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_eliminar_usuario(p_id INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM administrador WHERE id_usuario = p_id;
    DELETE FROM coordinador WHERE id_usuario = p_id;
    DELETE FROM usuario WHERE id_usuario = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

-- REQUERIMIENTO
CREATE OR REPLACE FUNCTION sp_insertar_requerimiento(p_id_evento INT, p_id_rol INT, p_cantidad INT)
RETURNS JSON AS $$
DECLARE v_result RECORD;
BEGIN
    IF NOT EXISTS(SELECT 1 FROM evento WHERE id_evento = p_id_evento) THEN RAISE EXCEPTION 'Evento no existe'; END IF;
    IF NOT EXISTS(SELECT 1 FROM rol WHERE id_rol = p_id_rol) THEN RAISE EXCEPTION 'Rol no existe'; END IF;
    IF EXISTS(SELECT 1 FROM requerimiento WHERE id_evento = p_id_evento AND id_rol = p_id_rol) THEN RAISE EXCEPTION 'Este requerimiento ya existe para este evento'; END IF;
    IF p_cantidad <= 0 THEN RAISE EXCEPTION 'La cantidad debe ser mayor a cero'; END IF;

    INSERT INTO requerimiento(id_evento, id_rol, cantidad_requerida)
    VALUES (p_id_evento, p_id_rol, p_cantidad) RETURNING * INTO v_result;
    RETURN row_to_json(v_result);
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_actualizar_requerimiento(p_id INT, p_cantidad INT)
RETURNS VOID AS $$
BEGIN
    IF p_cantidad <= 0 THEN RAISE EXCEPTION 'La cantidad debe ser mayor a cero'; END IF;
    UPDATE requerimiento SET cantidad_requerida = p_cantidad WHERE id_requerimiento = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_eliminar_requerimiento(p_id INT)
RETURNS VOID AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM asignacion WHERE id_requerimiento = p_id) THEN
        RAISE EXCEPTION 'No se puede eliminar el requerimiento porque tiene asignaciones';
    END IF;
    DELETE FROM requerimiento WHERE id_requerimiento = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

-- AUTORIZACION
CREATE OR REPLACE FUNCTION sp_insertar_autorizacion(p_id_vol INT, p_id_rol INT, p_id_autorizador INT, p_fecha DATE DEFAULT CURRENT_DATE)
RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM voluntario WHERE id_voluntario = p_id_vol) THEN RAISE EXCEPTION 'Voluntario no existe'; END IF;
    IF NOT EXISTS(SELECT 1 FROM rol WHERE id_rol = p_id_rol) THEN RAISE EXCEPTION 'Rol no existe'; END IF;
    IF NOT EXISTS(SELECT 1 FROM usuario WHERE id_usuario = p_id_autorizador) THEN RAISE EXCEPTION 'Usuario autorizador no existe'; END IF;
    IF EXISTS(SELECT 1 FROM autorizacion WHERE id_voluntario = p_id_vol AND id_rol = p_id_rol) THEN RAISE EXCEPTION 'Ya existe esta autorización'; END IF;

    INSERT INTO autorizacion(id_voluntario, id_rol, id_usuario_autorizador, fecha_autorizacion)
    VALUES (p_id_vol, p_id_rol, p_id_autorizador, p_fecha);
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_eliminar_autorizacion(p_id_vol INT, p_id_rol INT)
RETURNS VOID AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM asignacion a 
        JOIN requerimiento r ON a.id_requerimiento = r.id_requerimiento
        WHERE a.id_voluntario = p_id_vol AND r.id_rol = p_id_rol
    ) THEN
        RAISE EXCEPTION 'No se puede revocar la autorizacion porque el voluntario tiene asignaciones con este rol';
    END IF;
    DELETE FROM autorizacion WHERE id_voluntario = p_id_vol AND id_rol = p_id_rol;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

-- ASIGNACION
CREATE OR REPLACE FUNCTION sp_insertar_asignacion(p_id_vol INT, p_id_req INT, p_id_aprobador INT, p_hora_ini TIME, p_hora_fin TIME, p_estado VARCHAR)
RETURNS JSON AS $$
DECLARE v_result RECORD;
BEGIN
    IF p_hora_fin <= p_hora_ini THEN RAISE EXCEPTION 'La hora de fin debe ser posterior a la de inicio'; END IF;
    -- Nota: La validacion de la autorizacion se hace via trigger.
    INSERT INTO asignacion(id_voluntario, id_requerimiento, id_usuario_aprobador, hora_inicio, hora_fin, estado_asignacion)
    VALUES (p_id_vol, p_id_req, p_id_aprobador, p_hora_ini, p_hora_fin, p_estado::enum_estado_asignacion)
    RETURNING * INTO v_result;
    RETURN row_to_json(v_result);
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_actualizar_asignacion(p_id INT, p_hora_ini TIME, p_hora_fin TIME, p_estado VARCHAR, p_justificacion VARCHAR DEFAULT NULL, p_fecha_cancel DATE DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
    UPDATE asignacion
    SET hora_inicio = p_hora_ini, hora_fin = p_hora_fin, estado_asignacion = p_estado::enum_estado_asignacion, justificacion_cancelacion = p_justificacion, fecha_cancelacion = p_fecha_cancel
    WHERE id_asignacion = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sp_eliminar_asignacion(p_id INT)
RETURNS VOID AS $$
BEGIN
    DELETE FROM asignacion WHERE id_asignacion = p_id;
EXCEPTION WHEN OTHERS THEN RAISE;
END;
$$ LANGUAGE plpgsql;


-- ==========================================
-- SECCIÓN 8: TRIGGERS
-- ==========================================

-- Trigger 1: Verificar autorización en asignación
CREATE OR REPLACE FUNCTION fn_verificar_autorizacion()
RETURNS TRIGGER AS $$
DECLARE
    v_id_rol INT;
    v_autorizado BOOLEAN;
BEGIN
    -- Obtener el rol del requerimiento
    SELECT id_rol INTO v_id_rol FROM requerimiento WHERE id_requerimiento = NEW.id_requerimiento;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Requerimiento ID % no existe', NEW.id_requerimiento;
    END IF;
    -- Verificar autorizacion
    SELECT EXISTS(
        SELECT 1 FROM autorizacion 
        WHERE id_voluntario = NEW.id_voluntario AND id_rol = v_id_rol
    ) INTO v_autorizado;
    IF NOT v_autorizado THEN
        RAISE EXCEPTION 'El voluntario ID % no está autorizado para el rol ID %', NEW.id_voluntario, v_id_rol;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_verificar_autorizacion_asignacion
    BEFORE INSERT ON asignacion
    FOR EACH ROW
    EXECUTE FUNCTION fn_verificar_autorizacion();

-- Trigger 2: Auditoría de cambios en estado y nombre de voluntario
CREATE OR REPLACE FUNCTION fn_audit_cambio_estado()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.estado_operativo IS DISTINCT FROM NEW.estado_operativo THEN
        INSERT INTO audit_voluntario (id_voluntario, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (NEW.id_voluntario, 'estado_operativo', OLD.estado_operativo::TEXT, NEW.estado_operativo::TEXT);
    END IF;
    IF OLD.nombres IS DISTINCT FROM NEW.nombres THEN
        INSERT INTO audit_voluntario (id_voluntario, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (NEW.id_voluntario, 'nombres', OLD.nombres, NEW.nombres);
    END IF;
    IF OLD.apellidos IS DISTINCT FROM NEW.apellidos THEN
        INSERT INTO audit_voluntario (id_voluntario, campo_modificado, valor_anterior, valor_nuevo)
        VALUES (NEW.id_voluntario, 'apellidos', OLD.apellidos, NEW.apellidos);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_audit_cambio_estado_voluntario
    AFTER UPDATE ON voluntario
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_cambio_estado();


-- ==========================================
-- SECCIÓN 9: USUARIOS DE BD Y PERMISOS
-- ==========================================
DO $$ 
BEGIN
    -- Crear roles si no existen
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'admin_sigevep') THEN
        CREATE ROLE admin_sigevep LOGIN PASSWORD 'Admin2026!';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'coordinador_sigevep') THEN
        CREATE ROLE coordinador_sigevep LOGIN PASSWORD 'Coord2026!';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'consultor_sigevep') THEN
        CREATE ROLE consultor_sigevep LOGIN PASSWORD 'Consul2026!';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'operador_sigevep') THEN
        CREATE ROLE operador_sigevep LOGIN PASSWORD 'Oper2026!';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'auditor_sigevep') THEN
        CREATE ROLE auditor_sigevep LOGIN PASSWORD 'Audit2026!';
    END IF;
END $$;

-- Permisos admin_sigevep
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_sigevep;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO admin_sigevep;

-- Permisos coordinador_sigevep
GRANT SELECT, INSERT, UPDATE ON asignacion, autorizacion TO coordinador_sigevep;
GRANT EXECUTE ON FUNCTION sp_insertar_asignacion, sp_insertar_autorizacion TO coordinador_sigevep;
GRANT SELECT ON reporte_asignaciones_completo, reporte_cobertura_eventos TO coordinador_sigevep;

-- Permisos consultor_sigevep
GRANT SELECT ON reporte_asignaciones_completo, reporte_voluntarios_por_grupo, reporte_cobertura_eventos, reporte_actividad_usuarios TO consultor_sigevep;
GRANT EXECUTE ON FUNCTION sp_insertar_grupo_pastoral TO consultor_sigevep;

-- Permisos operador_sigevep
GRANT EXECUTE ON FUNCTION sp_insertar_voluntario, sp_actualizar_voluntario, sp_insertar_evento TO operador_sigevep;
GRANT SELECT ON vista_voluntarios, reporte_voluntarios_por_grupo TO operador_sigevep;

-- Permisos auditor_sigevep
GRANT SELECT ON audit_voluntario, reporte_asignaciones_completo, reporte_voluntarios_por_grupo, reporte_cobertura_eventos, reporte_actividad_usuarios TO auditor_sigevep;
GRANT EXECUTE ON FUNCTION sp_insertar_autorizacion TO auditor_sigevep;
