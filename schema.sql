-- ============================================================================
-- SISTEMA DE GESTIÓN DE VOLUNTARIOS PARA EVENTOS (SIGEVEP)
-- Grupo #3 — Sistemas de Bases de Datos 1
-- ESPOL — Primer Término 2026-2027
-- 
-- Script SQL para PostgreSQL / Supabase
-- Incluye: DDL (CREATE), Datos de prueba (INSERT), Vistas (VIEW)
-- ============================================================================

-- ============================================================================
-- SECCIÓN 1: LIMPIEZA (DROP en orden inverso de dependencias)
-- ============================================================================
DROP VIEW  IF EXISTS vista_asignaciones CASCADE;
DROP VIEW  IF EXISTS vista_voluntarios CASCADE;
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

DROP TYPE IF EXISTS enum_estado_operativo CASCADE;
DROP TYPE IF EXISTS enum_nivel_fisico CASCADE;
DROP TYPE IF EXISTS enum_rol_acceso CASCADE;
DROP TYPE IF EXISTS enum_estado_asignacion CASCADE;

-- ============================================================================
-- SECCIÓN 2: TIPOS ENUMERADOS
-- ============================================================================
CREATE TYPE enum_estado_operativo   AS ENUM ('Activo', 'Inactivo', 'Suspendido');
CREATE TYPE enum_nivel_fisico       AS ENUM ('Alto', 'Medio', 'Bajo');
CREATE TYPE enum_rol_acceso         AS ENUM ('Administrador', 'Coordinador');
CREATE TYPE enum_estado_asignacion  AS ENUM ('Programada', 'Completada', 'Ausente', 'Cancelada');

-- ============================================================================
-- SECCIÓN 3: CREACIÓN DE TABLAS (DDL)
-- ============================================================================

-- 1. GRUPO_PASTORAL
CREATE TABLE grupo_pastoral (
    id_grupo          SERIAL       PRIMARY KEY,
    nombre_grupo      VARCHAR(100) NOT NULL UNIQUE,
    descripcion_grupo VARCHAR(255)
);

-- 2. CATEGORIA_EVENTO  (CORRECCIÓN #4: categoría como entidad separada)
CREATE TABLE categoria_evento (
    id_categoria          SERIAL       PRIMARY KEY,
    nombre_categoria      VARCHAR(50)  NOT NULL UNIQUE,
    descripcion_categoria VARCHAR(255)
);

-- 3. ROL
CREATE TABLE rol (
    id_rol              SERIAL           PRIMARY KEY,
    nombre_rol          VARCHAR(80)      NOT NULL UNIQUE,
    descripcion_rol     VARCHAR(255)     NOT NULL,
    requiere_epp        BOOLEAN          NOT NULL DEFAULT FALSE,
    nivel_demanda_fisica enum_nivel_fisico NOT NULL
);

-- 4. VOLUNTARIO
CREATE TABLE voluntario (
    id_voluntario          SERIAL                PRIMARY KEY,
    id_grupo               INT                   NOT NULL REFERENCES grupo_pastoral(id_grupo),
    nombres                VARCHAR(80)           NOT NULL,
    apellidos              VARCHAR(80)           NOT NULL,
    telefono               VARCHAR(15)           NOT NULL,
    fecha_nacimiento       DATE                  NOT NULL,
    fecha_ingreso          DATE                  NOT NULL DEFAULT CURRENT_DATE,
    estado_operativo       enum_estado_operativo NOT NULL DEFAULT 'Activo',
    nivel_capacidad_fisica enum_nivel_fisico     NOT NULL,
    tipo_limitacion_fisica VARCHAR(100),
    descripcion_limitacion VARCHAR(255)
);

-- 5. EVENTO  (CORRECCIÓN #4: FK a categoria_evento en vez de ENUM)
CREATE TABLE evento (
    id_evento        SERIAL       PRIMARY KEY,
    id_grupo         INT          NOT NULL REFERENCES grupo_pastoral(id_grupo),
    id_categoria     INT          NOT NULL REFERENCES categoria_evento(id_categoria),
    nombre_evento    VARCHAR(120) NOT NULL,
    fecha_programada DATE         NOT NULL,
    ubicacion        VARCHAR(150) NOT NULL
);

-- 6. USUARIO (Supertipo)  (CORRECCIÓN #3: supertipo-subtipo)
CREATE TABLE usuario (
    id_usuario      SERIAL          PRIMARY KEY,
    nombre_usuario  VARCHAR(50)     NOT NULL UNIQUE,
    clave_acceso    VARCHAR(255)    NOT NULL,
    rol_acceso      enum_rol_acceso NOT NULL
);

-- 7. ADMINISTRADOR (Subtipo)  (CORRECCIÓN #3)
CREATE TABLE administrador (
    id_usuario    INT          PRIMARY KEY REFERENCES usuario(id_usuario),
    nivel_permiso VARCHAR(20)  NOT NULL DEFAULT 'Total'
        CHECK (nivel_permiso IN ('Total', 'Parcial'))
);

-- 8. COORDINADOR (Subtipo)  (CORRECCIÓN #3)
CREATE TABLE coordinador (
    id_usuario    INT          PRIMARY KEY REFERENCES usuario(id_usuario),
    zona_asignada VARCHAR(50)  NOT NULL
);

-- 9. REQUERIMIENTO
CREATE TABLE requerimiento (
    id_requerimiento  SERIAL PRIMARY KEY,
    id_evento         INT    NOT NULL REFERENCES evento(id_evento),
    id_rol            INT    NOT NULL REFERENCES rol(id_rol),
    cantidad_requerida INT   NOT NULL CHECK (cantidad_requerida > 0),
    UNIQUE (id_evento, id_rol)
);

-- 10. AUTORIZACION  (CORRECCIÓN #5: quién autoriza al voluntario)
CREATE TABLE autorizacion (
    id_voluntario          INT  NOT NULL REFERENCES voluntario(id_voluntario),
    id_rol                 INT  NOT NULL REFERENCES rol(id_rol),
    id_usuario_autorizador INT  NOT NULL REFERENCES usuario(id_usuario),
    fecha_autorizacion     DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (id_voluntario, id_rol)
);

-- 11. ASIGNACION
CREATE TABLE asignacion (
    id_asignacion            SERIAL                 PRIMARY KEY,
    id_voluntario            INT                    NOT NULL REFERENCES voluntario(id_voluntario),
    id_requerimiento         INT                    NOT NULL REFERENCES requerimiento(id_requerimiento),
    id_usuario_aprobador     INT                    NOT NULL REFERENCES usuario(id_usuario),
    hora_inicio              TIME                   NOT NULL,
    hora_fin                 TIME                   NOT NULL,
    estado_asignacion        enum_estado_asignacion NOT NULL DEFAULT 'Programada',
    justificacion_cancelacion VARCHAR(500),
    fecha_cancelacion        DATE,
    CHECK (hora_fin > hora_inicio)
);

-- ============================================================================
-- SECCIÓN 4: DATOS DE PRUEBA (INSERT — mínimo 10 registros por tabla)
-- ============================================================================

-- GRUPO_PASTORAL (10 registros)
INSERT INTO grupo_pastoral (nombre_grupo, descripcion_grupo) VALUES
('Pastoral Juvenil San José',       'Formación espiritual y humana de jóvenes de 15 a 25 años'),
('Pastoral Familiar Santa Ana',     'Acompañamiento integral a familias de la comunidad'),
('Pastoral Social Cristo Rey',      'Servicio social y desarrollo comunitario'),
('Pastoral de Liturgia',            'Organización y coordinación de celebraciones litúrgicas'),
('Pastoral de Catequesis',          'Enseñanza y formación en la doctrina cristiana'),
('Pastoral de Misiones',            'Evangelización y acompañamiento en comunidades remotas'),
('Pastoral Universitaria',          'Apoyo espiritual y académico a estudiantes universitarios'),
('Pastoral de Jóvenes Adultos',     'Actividades de crecimiento para adultos jóvenes 25-35'),
('Pastoral Comunitaria San Pablo',  'Desarrollo integral de la comunidad parroquial'),
('Pastoral de Servicio Social',     'Asistencia directa a población vulnerable y en riesgo');

-- CATEGORIA_EVENTO (10 registros — entidad nueva por corrección #4)
INSERT INTO categoria_evento (nombre_categoria, descripcion_categoria) VALUES
('Religioso',   'Celebraciones litúrgicas, sacramentales y de oración'),
('Social',      'Actividades de integración y convivencia comunitaria'),
('Deportivo',   'Eventos deportivos, recreativos y de actividad física'),
('Cultural',    'Actividades artísticas, educativas y de formación cultural'),
('Comunitario', 'Jornadas de servicio directo a la comunidad'),
('Educativo',   'Talleres, charlas y actividades de formación académica'),
('Benéfico',    'Eventos de recaudación de fondos y ayuda humanitaria'),
('Misionero',   'Actividades de evangelización y misión pastoral'),
('Litúrgico',   'Celebraciones sacramentales y oficios litúrgicos especiales'),
('Ecológico',   'Jornadas de cuidado ambiental y conciencia ecológica');

-- ROL (10 registros)
INSERT INTO rol (nombre_rol, descripcion_rol, requiere_epp, nivel_demanda_fisica) VALUES
('Guardia de Entrada',    'Control de acceso e identificación de asistentes',           TRUE,  'Alto'),
('Guardia de Parqueo',    'Organización y control del estacionamiento vehicular',       TRUE,  'Alto'),
('Acomodador',            'Guía y ubicación de asistentes en el recinto',               FALSE, 'Medio'),
('Logística General',     'Coordinación operativa de recursos y materiales',            FALSE, 'Alto'),
('Sonidista',             'Manejo y operación de equipos de audio y amplificación',     FALSE, 'Bajo'),
('Primeros Auxilios',     'Atención médica básica y respuesta a emergencias',           TRUE,  'Medio'),
('Registro y Control',    'Registro digital de asistentes e inventario del evento',     FALSE, 'Bajo'),
('Apoyo en Cocina',       'Preparación y distribución de alimentos para voluntarios',   TRUE,  'Medio'),
('Decoración y Montaje',  'Preparación, ambientación y montaje de espacios del evento', FALSE, 'Alto'),
('Coordinador de Área',   'Supervisión directa de un grupo de voluntarios en campo',    FALSE, 'Medio');

-- VOLUNTARIO (15 registros)
INSERT INTO voluntario (id_grupo, nombres, apellidos, telefono, fecha_nacimiento, fecha_ingreso, estado_operativo, nivel_capacidad_fisica, tipo_limitacion_fisica, descripcion_limitacion) VALUES
(1,  'Juan Carlos',      'Pérez Gómez',        '0991234567', '1998-04-15', '2024-01-10', 'Activo',     'Alto',  NULL, NULL),
(1,  'María Elena',      'Rodríguez López',     '0987654321', '2000-08-22', '2023-06-15', 'Activo',     'Medio', NULL, NULL),
(2,  'Carlos Alberto',   'Mendoza Ruiz',        '0995551234', '1995-12-03', '2023-03-20', 'Activo',     'Alto',  NULL, NULL),
(3,  'Ana Sofía',        'Vargas Torres',       '0993214567', '2002-06-18', '2024-02-14', 'Activo',     'Medio', 'Movilidad reducida', 'No puede cargar objetos pesados de más de 10 kg'),
(2,  'Pedro José',       'García Salazar',      '0998765432', '1990-11-07', '2023-01-05', 'Activo',     'Alto',  NULL, NULL),
(4,  'Daniela Patricia', 'Herrera Figueroa',    '0994567890', '2003-03-25', '2024-05-10', 'Activo',     'Alto',  NULL, NULL),
(5,  'Roberto Luis',     'Castillo Morán',      '0991112233', '1988-09-14', '2023-08-22', 'Activo',     'Medio', 'Cardiopatía leve', 'Control periódico; evitar esfuerzos extremos prolongados'),
(3,  'Gabriela Fernanda','Ortiz Vera',          '0996667788', '2001-01-30', '2024-03-18', 'Activo',     'Alto',  NULL, NULL),
(6,  'Miguel Ángel',     'Zambrano Cruz',       '0993334455', '2010-07-12', '2025-09-01', 'Activo',     'Medio', NULL, NULL),
(7,  'Laura Isabel',     'Figueroa Bravo',      '0997778899', '1997-05-28', '2023-11-30', 'Inactivo',   'Bajo',  'Asma crónica', 'Evitar ambientes con polvo, humo o productos químicos'),
(8,  'Andrés Felipe',    'Morales Rojas',       '0992223344', '1999-10-05', '2024-07-20', 'Activo',     'Alto',  NULL, NULL),
(9,  'Valentina Carmen', 'Delgado Ponce',       '0995556677', '2004-02-14', '2025-01-15', 'Activo',     'Medio', NULL, NULL),
(10, 'Fernando José',    'Real Vargas',         '0998889900', '1996-08-19', '2023-04-12', 'Suspendido', 'Alto',  NULL, NULL),
(4,  'Isabella María',   'Chávez León',         '0991234890', '2005-11-22', '2025-06-01', 'Activo',     'Medio', NULL, NULL),
(5,  'Santiago David',   'Rivas Aguirre',       '0994445566', '1993-03-09', '2023-02-28', 'Activo',     'Alto',  NULL, NULL);

-- EVENTO (12 registros)
INSERT INTO evento (id_grupo, id_categoria, nombre_evento, fecha_programada, ubicacion) VALUES
(1, 1, 'Misa de Navidad 2026',             '2026-12-25', 'Iglesia San José Central'),
(1, 3, 'Jornada Deportiva Juvenil',        '2026-08-15', 'Complejo Deportivo Parroquial'),
(2, 1, 'Retiro Espiritual Familiar',       '2026-09-20', 'Centro de Retiros Santa María'),
(3, 4, 'Festival Cultural Comunitario',    '2026-10-12', 'Plaza Central del Barrio'),
(3, 5, 'Jornada de Servicio Social',       '2026-07-30', 'Barrio Las Flores'),
(4, 1, 'Celebración de Semana Santa',      '2026-04-05', 'Iglesia Cristo Rey'),
(6, 3, 'Torneo Fútbol Interparroquial',    '2026-11-08', 'Cancha Municipal Norte'),
(9, 2, 'Cena Benéfica Anual',              '2026-09-15', 'Salón Parroquial San Pablo'),
(6, 5, 'Misión Evangelizadora',            '2026-08-01', 'Comunidad Rural El Progreso'),
(4, 4, 'Concierto Sacro Navideño',         '2026-12-20', 'Auditorio Parroquial Central'),
(7, 2, 'Campamento Juvenil de Verano',     '2026-07-15', 'Finca Pastoral Los Olivos'),
(5, 1, 'Bautizos Comunitarios',            '2026-10-05', 'Iglesia San José Central');

-- USUARIO (20 registros — supertipo: 10 administradores + 10 coordinadores)
INSERT INTO usuario (nombre_usuario, clave_acceso, rol_acceso) VALUES
('cadmin',  'pbkdf2_sha256$admin01hash', 'Administrador'),
('madmin',  'pbkdf2_sha256$admin02hash', 'Administrador'),
('jadmin',  'pbkdf2_sha256$admin03hash', 'Administrador'),
('aadmin',  'pbkdf2_sha256$admin04hash', 'Administrador'),
('fadmin',  'pbkdf2_sha256$admin05hash', 'Administrador'),
('gadmin',  'pbkdf2_sha256$admin06hash', 'Administrador'),
('hadmin',  'pbkdf2_sha256$admin07hash', 'Administrador'),
('radmin',  'pbkdf2_sha256$admin08hash', 'Administrador'),
('sadmin',  'pbkdf2_sha256$admin09hash', 'Administrador'),
('tadmin',  'pbkdf2_sha256$admin10hash', 'Administrador'),
('lcoord',  'pbkdf2_sha256$coord11hash', 'Coordinador'),
('scoord',  'pbkdf2_sha256$coord12hash', 'Coordinador'),
('pcoord',  'pbkdf2_sha256$coord13hash', 'Coordinador'),
('ecoord',  'pbkdf2_sha256$coord14hash', 'Coordinador'),
('dcoord',  'pbkdf2_sha256$coord15hash', 'Coordinador'),
('ccoord',  'pbkdf2_sha256$coord16hash', 'Coordinador'),
('mcoord',  'pbkdf2_sha256$coord17hash', 'Coordinador'),
('ncoord',  'pbkdf2_sha256$coord18hash', 'Coordinador'),
('ocoord',  'pbkdf2_sha256$coord19hash', 'Coordinador'),
('qcoord',  'pbkdf2_sha256$coord20hash', 'Coordinador');

-- ADMINISTRADOR (10 registros — subtipo)
INSERT INTO administrador (id_usuario, nivel_permiso) VALUES
(1,  'Total'),
(2,  'Total'),
(3,  'Parcial'),
(4,  'Parcial'),
(5,  'Parcial'),
(6,  'Total'),
(7,  'Parcial'),
(8,  'Total'),
(9,  'Parcial'),
(10, 'Total');

-- COORDINADOR (10 registros — subtipo)
INSERT INTO coordinador (id_usuario, zona_asignada) VALUES
(11, 'Zona Norte'),
(12, 'Zona Sur'),
(13, 'Zona Este'),
(14, 'Zona Oeste'),
(15, 'Zona Central'),
(16, 'Zona Rural'),
(17, 'Zona Noreste'),
(18, 'Zona Sureste'),
(19, 'Zona Noroeste'),
(20, 'Zona Industrial');

-- REQUERIMIENTO (15 registros)
INSERT INTO requerimiento (id_evento, id_rol, cantidad_requerida) VALUES
(1,  1, 3),   -- Misa Navidad: 3 Guardias de Entrada
(1,  3, 5),   -- Misa Navidad: 5 Acomodadores
(1,  5, 2),   -- Misa Navidad: 2 Sonidistas
(2,  2, 2),   -- Jornada Deportiva: 2 Guardias Parqueo
(2,  4, 4),   -- Jornada Deportiva: 4 Logística
(3,  3, 3),   -- Retiro Espiritual: 3 Acomodadores
(3,  6, 2),   -- Retiro Espiritual: 2 Primeros Auxilios
(4,  9, 4),   -- Festival Cultural: 4 Decoración
(4,  5, 1),   -- Festival Cultural: 1 Sonidista
(5,  4, 5),   -- Jornada Servicio: 5 Logística
(5,  8, 3),   -- Jornada Servicio: 3 Apoyo Cocina
(6,  1, 4),   -- Semana Santa: 4 Guardias Entrada
(7,  2, 3),   -- Torneo Fútbol: 3 Guardias Parqueo
(8,  8, 4),   -- Cena Benéfica: 4 Apoyo Cocina
(8,  7, 2);   -- Cena Benéfica: 2 Registro

-- AUTORIZACION (20 registros — CORRECCIÓN #5: incluye quién autorizó)
INSERT INTO autorizacion (id_voluntario, id_rol, id_usuario_autorizador, fecha_autorizacion) VALUES
(1,  1,  1, '2024-02-01'),  -- Juan Carlos → Guardia Entrada, por cadmin
(1,  4,  1, '2024-02-01'),  -- Juan Carlos → Logística
(2,  3,  1, '2023-07-01'),  -- María Elena → Acomodador
(2,  7,  1, '2023-07-01'),  -- María Elena → Registro
(3,  1,  2, '2023-04-15'),  -- Carlos Alberto → Guardia Entrada, por madmin
(3,  4,  2, '2023-04-15'),  -- Carlos Alberto → Logística
(4,  3,  2, '2024-03-01'),  -- Ana Sofía → Acomodador
(4,  7,  2, '2024-03-01'),  -- Ana Sofía → Registro
(5,  1,  1, '2023-02-10'),  -- Pedro José → Guardia Entrada
(5,  2,  1, '2023-02-10'),  -- Pedro José → Guardia Parqueo
(6,  4,  3, '2024-06-01'),  -- Daniela → Logística, por jadmin
(6,  9,  3, '2024-06-01'),  -- Daniela → Decoración
(7,  5,  3, '2023-09-15'),  -- Roberto → Sonidista
(7,  7,  3, '2023-09-15'),  -- Roberto → Registro
(8,  4,  4, '2024-04-01'),  -- Gabriela → Logística, por aadmin
(8,  9,  4, '2024-04-01'),  -- Gabriela → Decoración
(11, 1,  2, '2024-08-15'),  -- Andrés → Guardia Entrada
(11, 4,  2, '2024-08-15'),  -- Andrés → Logística
(15, 1,  4, '2023-03-15'),  -- Santiago → Guardia Entrada
(15, 2,  4, '2023-03-15');  -- Santiago → Guardia Parqueo

-- ASIGNACION (15 registros)
INSERT INTO asignacion (id_voluntario, id_requerimiento, id_usuario_aprobador, hora_inicio, hora_fin, estado_asignacion, justificacion_cancelacion, fecha_cancelacion) VALUES
(1,  1,  11, '07:00', '12:00', 'Programada',  NULL, NULL),                           -- Juan Carlos → Guardia Entrada en Misa Navidad
(5,  1,  11, '07:00', '12:00', 'Programada',  NULL, NULL),                           -- Pedro José → Guardia Entrada en Misa Navidad
(15, 1,  12, '12:00', '17:00', 'Programada',  NULL, NULL),                           -- Santiago → Guardia Entrada en Misa Navidad
(2,  2,  11, '08:00', '13:00', 'Completada',  NULL, NULL),                           -- María Elena → Acomodador en Misa Navidad
(3,  5,  13, '06:00', '14:00', 'Completada',  NULL, NULL),                           -- Carlos Alberto → Logística Jornada Deportiva
(5,  4,  13, '06:00', '14:00', 'Ausente',     NULL, NULL),                           -- Pedro José → Guardia Parqueo Jornada Deportiva
(4,  6,  14, '09:00', '17:00', 'Completada',  NULL, NULL),                           -- Ana Sofía → Acomodador Retiro Espiritual
(6,  8,  15, '07:00', '15:00', 'Programada',  NULL, NULL),                           -- Daniela → Decoración Festival Cultural
(8,  8,  15, '07:00', '15:00', 'Programada',  NULL, NULL),                           -- Gabriela → Decoración Festival Cultural
(7,  9,  15, '08:00', '14:00', 'Completada',  NULL, NULL),                           -- Roberto → Sonidista Festival Cultural
(1,  10, 12, '06:00', '14:00', 'Cancelada',   'Emergencia familiar imprevista', '2026-07-28'),  -- Juan Carlos canceló Logística
(11, 10, 12, '06:00', '14:00', 'Completada',  NULL, NULL),                           -- Andrés → Logística Jornada Servicio
(3,  12, 11, '06:00', '12:00', 'Ausente',     NULL, NULL),                           -- Carlos Alberto → Guardia Semana Santa
(15, 13, 13, '08:00', '16:00', 'Completada',  NULL, NULL),                           -- Santiago → Guardia Parqueo Torneo Fútbol
(4,  15, 16, '09:00', '13:00', 'Programada',  NULL, NULL);                           -- Ana Sofía → Registro Cena Benéfica

-- ============================================================================
-- SECCIÓN 5: VISTAS (para la aplicación Python)
-- ============================================================================

-- Vista 1: Voluntarios con su grupo pastoral
CREATE OR REPLACE VIEW vista_voluntarios AS
SELECT
    v.id_voluntario,
    v.nombres,
    v.apellidos,
    v.telefono,
    v.fecha_nacimiento,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, v.fecha_nacimiento))::INT AS edad,
    v.fecha_ingreso,
    v.estado_operativo::TEXT,
    v.nivel_capacidad_fisica::TEXT,
    COALESCE(v.tipo_limitacion_fisica, 'Ninguna') AS tipo_limitacion_fisica,
    COALESCE(v.descripcion_limitacion, 'N/A') AS descripcion_limitacion,
    g.nombre_grupo
FROM voluntario v
JOIN grupo_pastoral g ON v.id_grupo = g.id_grupo
ORDER BY v.apellidos, v.nombres;

-- Vista 2: Asignaciones completas con evento, rol, voluntario y aprobador
CREATE OR REPLACE VIEW vista_asignaciones AS
SELECT
    a.id_asignacion,
    v.nombres || ' ' || v.apellidos AS voluntario,
    e.nombre_evento,
    e.fecha_programada,
    ce.nombre_categoria AS categoria_evento,
    r.nombre_rol,
    a.hora_inicio,
    a.hora_fin,
    a.estado_asignacion::TEXT,
    u.nombre_usuario AS aprobado_por,
    COALESCE(a.justificacion_cancelacion, '') AS justificacion_cancelacion,
    a.fecha_cancelacion
FROM asignacion a
JOIN voluntario v      ON a.id_voluntario = v.id_voluntario
JOIN requerimiento req ON a.id_requerimiento = req.id_requerimiento
JOIN evento e          ON req.id_evento = e.id_evento
JOIN categoria_evento ce ON e.id_categoria = ce.id_categoria
JOIN rol r             ON req.id_rol = r.id_rol
JOIN usuario u         ON a.id_usuario_aprobador = u.id_usuario
ORDER BY e.fecha_programada, a.hora_inicio;

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================
