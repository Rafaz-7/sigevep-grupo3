# SIGEVEP — Documentación Técnica del Avance 03
## Sistema de Gestión de Voluntarios para Eventos Parroquiales
### Grupo #3 — Sistemas de Bases de Datos 1 — ESPOL — Primer Término 2026-2027

---

## 1. Triggers Implementados

### 1.1 Trigger: `trg_verificar_autorizacion_asignacion`

| Propiedad | Detalle |
|-----------|---------|
| **Tabla** | `asignacion` |
| **Momento** | `BEFORE INSERT` |
| **Función** | Lógica directa en el trigger |
| **Propósito** | Garantizar la integridad del negocio: un voluntario solo puede ser asignado a un requerimiento si tiene una autorización previa para el rol que dicho requerimiento exige. |

**Lógica:**
1. Obtiene el `id_rol` del requerimiento asociado a la nueva asignación.
2. Verifica que exista un registro en la tabla `autorizacion` con el `id_voluntario` y el `id_rol` correspondiente.
3. Si no existe la autorización, lanza un error con `SIGNAL SQLSTATE '45000'` impidiendo la inserción.

**Ejemplo de uso:**
- Si el voluntario Juan Carlos (ID 1) solo está autorizado para los roles "Guardia de Entrada" (ID 1) y "Logística General" (ID 4), al intentar asignarlo a un requerimiento de "Sonidista" (ID 5), el trigger rechazará la operación.

---

### 1.2 Trigger: `trg_audit_cambio_estado_voluntario`

| Propiedad | Detalle |
|-----------|---------|
| **Tabla** | `voluntario` |
| **Momento** | `AFTER UPDATE` |
| **Función** | Lógica directa en el trigger |
| **Tabla destino** | `audit_voluntario` |
| **Propósito** | Registrar automáticamente en una tabla de auditoría cada vez que se modifica el estado operativo, nombres o apellidos de un voluntario, conservando el valor anterior, el nuevo valor, la fecha y el usuario de BD que realizó el cambio. |

**Lógica:**
1. Compara el valor anterior (`OLD`) con el nuevo (`NEW`) para los campos `estado_operativo`, `nombres` y `apellidos`.
2. Si detecta un cambio, inserta un registro en `audit_voluntario` con: el ID del voluntario, el campo modificado, el valor anterior, el nuevo valor, la fecha/hora y el usuario de base de datos.

**Tabla de auditoría (`audit_voluntario`):**

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `id_audit` | SERIAL PK | Identificador único del registro de auditoría |
| `id_voluntario` | INT | ID del voluntario afectado |
| `campo_modificado` | VARCHAR(50) | Nombre del campo que cambió |
| `valor_anterior` | TEXT | Valor antes del cambio |
| `valor_nuevo` | TEXT | Valor después del cambio |
| `fecha_cambio` | TIMESTAMP | Fecha y hora del cambio |
| `usuario_bd` | VARCHAR(50) | Usuario de BD que ejecutó la operación |

---

## 2. Reportes Implementados (Vistas)

Cada reporte se implementó como una vista (`VIEW`) que une al menos 3 tablas y muestra valores descriptivos en lugar de IDs.

### 2.1 `reporte_asignaciones_completo`
**Tablas involucradas (8):** asignacion, voluntario, requerimiento, evento, rol, usuario, categoria_evento, grupo_pastoral

| Columna | Descripción |
|---------|-------------|
| `id_asignacion` | ID de la asignación |
| `voluntario` | Nombre completo del voluntario |
| `grupo_pastoral` | Nombre del grupo al que pertenece |
| `evento` | Nombre del evento |
| `categoria` | Categoría del evento |
| `rol_asignado` | Nombre del rol asignado |
| `horario` | Hora inicio y fin |
| `estado` | Estado de la asignación |
| `aprobado_por` | Nombre del usuario aprobador |

**Uso:** Obtener una vista completa de todas las asignaciones con información descriptiva para seguimiento y control.

---

### 2.2 `reporte_voluntarios_por_grupo`
**Tablas involucradas (4):** voluntario, grupo_pastoral, autorizacion, rol

| Columna | Descripción |
|---------|-------------|
| `grupo` | Nombre del grupo pastoral |
| `voluntario` | Nombre completo |
| `edad` | Edad calculada |
| `estado` | Estado operativo |
| `roles_autorizados` | Lista de roles para los que está autorizado |

**Uso:** Ver qué voluntarios pertenecen a cada grupo y qué roles pueden desempeñar.

---

### 2.3 `reporte_cobertura_eventos`
**Tablas involucradas (6):** evento, categoria_evento, grupo_pastoral, requerimiento, rol, asignacion

| Columna | Descripción |
|---------|-------------|
| `evento` | Nombre del evento |
| `categoria` | Categoría |
| `grupo` | Grupo pastoral organizador |
| `fecha` | Fecha programada |
| `rol` | Rol requerido |
| `requeridos` | Cantidad de voluntarios requeridos |
| `asignados` | Cantidad de voluntarios asignados |
| `porcentaje_cobertura` | % de cobertura (asignados/requeridos) |

**Uso:** Identificar eventos con déficit de voluntarios y planificar la cobertura.

---

### 2.4 `reporte_actividad_usuarios`
**Tablas involucradas (4+):** usuario, administrador, coordinador, asignacion, autorizacion

| Columna | Descripción |
|---------|-------------|
| `usuario` | Nombre de usuario |
| `tipo` | Rol de acceso (Administrador/Coordinador) |
| `info_subtipo` | Nivel de permiso o zona asignada |
| `total_aprobaciones` | Cantidad de asignaciones aprobadas |
| `total_autorizaciones` | Cantidad de autorizaciones otorgadas |

**Uso:** Medir la actividad y participación de cada usuario del sistema.

---

## 3. Stored Procedures (Procedimientos Almacenados)

Se crearon procedimientos almacenados (MySQL `PROCEDURE`) para las operaciones de inserción, actualización y eliminación en todas las tablas que implementan CRUD. Cada SP incluye:

- **Validaciones de negocio** (datos no vacíos, existencia de FK, no duplicados)
- **Manejo de errores** con `SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '...'`
- **Control transaccional** con `START TRANSACTION` / `COMMIT` / `ROLLBACK` y `DECLARE EXIT HANDLER FOR SQLEXCEPTION`

### Resumen de Stored Procedures

| Tabla | SP Inserción | SP Actualización | SP Eliminación |
|-------|-------------|------------------|----------------|
| grupo_pastoral | `sp_insertar_grupo_pastoral` | `sp_actualizar_grupo_pastoral` | `sp_eliminar_grupo_pastoral` |
| categoria_evento | `sp_insertar_categoria_evento` | `sp_actualizar_categoria_evento` | `sp_eliminar_categoria_evento` |
| rol | `sp_insertar_rol` | `sp_actualizar_rol` | `sp_eliminar_rol` |
| voluntario | `sp_insertar_voluntario` | `sp_actualizar_voluntario` | `sp_eliminar_voluntario` |
| evento | `sp_insertar_evento` | `sp_actualizar_evento` | `sp_eliminar_evento` |
| usuario | `sp_insertar_usuario` | `sp_actualizar_usuario` | `sp_eliminar_usuario` |
| requerimiento | `sp_insertar_requerimiento` | `sp_actualizar_requerimiento` | `sp_eliminar_requerimiento` |
| autorizacion | `sp_insertar_autorizacion` | — | `sp_eliminar_autorizacion` |
| asignacion | `sp_insertar_asignacion` | `sp_actualizar_asignacion` | `sp_eliminar_asignacion` |

### Ejemplo de SP con transacción y validación:

```sql
DELIMITER //
CREATE PROCEDURE sp_insertar_voluntario(
    IN p_id_grupo INT, IN p_nombres VARCHAR(80), IN p_apellidos VARCHAR(80),
    IN p_telefono VARCHAR(15), IN p_fecha_nac DATE, IN p_estado VARCHAR(15),
    IN p_nivel_fisico VARCHAR(10), IN p_tipo_limit VARCHAR(100), IN p_desc_limit VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM grupo_pastoral WHERE id_grupo = p_id_grupo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El grupo pastoral no existe';
    END IF;

    IF p_fecha_nac > CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La fecha de nacimiento no puede ser futura';
    END IF;

    INSERT INTO voluntario (id_grupo, nombres, apellidos, telefono,
        fecha_nacimiento, estado_operativo, nivel_capacidad_fisica,
        tipo_limitacion_fisica, descripcion_limitacion)
    VALUES (p_id_grupo, p_nombres, p_apellidos, p_telefono,
        p_fecha_nac, p_estado, p_nivel_fisico, p_tipo_limit, p_desc_limit);

    COMMIT;
END //
DELIMITER ;
```

**Control transaccional:** El `DECLARE EXIT HANDLER FOR SQLEXCEPTION` captura cualquier error. Si ocurre un error, ejecuta `ROLLBACK` y propaga el error con `RESIGNAL`. Si no hay error, `COMMIT` confirma los cambios.

### Integración con Python (MySQL):

El código del programa fue modificado para llamar a los SPs mediante `cursor.callproc()`:

```python
# ANTES (SQL directo):
cursor.execute('INSERT INTO voluntario (...) VALUES (...)', params)

# AHORA (Stored Procedure):
cursor.callproc('sp_insertar_voluntario', (id_grupo, nombres, apellidos, ...))
conn.commit()
```

---

## 4. Índices Implementados

| # | Índice | Tabla | Columna(s) | Justificación |
|---|--------|-------|-----------|---------------|
| 1 | `idx_voluntario_id_grupo` | `voluntario` | `id_grupo` | Acelera los JOINs con `grupo_pastoral` al listar voluntarios por grupo. Es la consulta más frecuente en el reporte `reporte_voluntarios_por_grupo`. |
| 2 | `idx_voluntario_estado` | `voluntario` | `estado_operativo` | Acelera los filtros por estado (Activo/Inactivo/Suspendido), muy usados para determinar voluntarios disponibles para asignación. |
| 3 | `idx_evento_fecha` | `evento` | `fecha_programada` | Optimiza búsquedas por rango de fechas en reportes de cobertura y planificación de eventos futuros. |
| 4 | `idx_asignacion_estado` | `asignacion` | `estado_asignacion` | Acelera filtros por estado de asignación (Programada, Completada, Ausente, Cancelada) en el reporte de asignaciones. |
| 5 | `idx_autorizacion_voluntario` | `autorizacion` | `id_voluntario` | Optimiza la verificación de autorizaciones del trigger `trg_verificar_autorizacion_asignacion` y las consultas del reporte de voluntarios. |
| 6 | `idx_requerimiento_evento` | `requerimiento` | `id_evento` | Acelera la búsqueda de requerimientos por evento, usado intensamente en el reporte de cobertura. |

---

## 5. Usuarios y Permisos de Base de Datos

### Tabla de permisos por usuario:

| # | Usuario | Contraseña | Permisos a Tablas | Permisos a Vistas | Permisos a SP |
|---|---------|------------|-------------------|--------------------|----|
| 1 | `admin_sigevep` | Admin2026! | ALL en todas las tablas | SELECT en todas las vistas | EXECUTE en todos los SP |
| 2 | `coordinador_sigevep` | Coord2026! | SELECT, INSERT, UPDATE en asignacion y autorizacion | SELECT en `reporte_asignaciones_completo`, `reporte_cobertura_eventos` | EXECUTE en `sp_insertar_asignacion`, `sp_insertar_autorizacion` |
| 3 | `consultor_sigevep` | Consul2026! | — | SELECT en `reporte_asignaciones_completo`, `reporte_voluntarios_por_grupo`, `reporte_cobertura_eventos`, `reporte_actividad_usuarios` | EXECUTE en `sp_insertar_grupo_pastoral` |
| 4 | `operador_sigevep` | Oper2026! | — | SELECT en `vista_voluntarios`, `reporte_voluntarios_por_grupo` | EXECUTE en `sp_insertar_voluntario`, `sp_actualizar_voluntario`, `sp_insertar_evento` |
| 5 | `auditor_sigevep` | Audit2026! | SELECT en `audit_voluntario` | SELECT en `reporte_asignaciones_completo`, `reporte_voluntarios_por_grupo`, `reporte_cobertura_eventos`, `reporte_actividad_usuarios` | EXECUTE en `sp_insertar_autorizacion` |

### Justificación de los roles:

- **admin_sigevep:** Administrador total del sistema. Necesita acceso completo para mantenimiento.
- **coordinador_sigevep:** Gestiona asignaciones y autorizaciones de voluntarios en su zona. Necesita ver reportes de asignaciones y cobertura.
- **consultor_sigevep:** Perfil de solo lectura para directivos que necesitan ver reportes sin modificar datos.
- **operador_sigevep:** Personal de registro que ingresa voluntarios y eventos. No necesita acceso a reportes avanzados.
- **auditor_sigevep:** Perfil de auditoría que revisa cambios (tabla audit) y reportes para verificar la integridad operativa.

---

## 6. Diagrama del Schema

Ver archivo adjunto: `diagrama_schema.pdf`

El diagrama incluye:
- Las 11 tablas del modelo con sus columnas, tipos de datos y restricciones
- La tabla de auditoría `audit_voluntario`
- Relaciones de clave foránea entre tablas
- Cardinalidades (1:N, M:N)
- Identificación de supertipos/subtipos (usuario → administrador, coordinador)
