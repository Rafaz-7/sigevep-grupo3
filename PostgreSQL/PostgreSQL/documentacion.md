# SIGEVEP — Documentación Técnica del Avance Final
## Sistema de Gestión de Voluntarios para Eventos Parroquiales
### Grupo #3 — Sistemas de Bases de Datos 1 — ESPOL — Primer Término 2026-2027

---

## 1. Triggers Implementados

### 1.1 Trigger: `trg_verificar_autorizacion_asignacion`

| Propiedad | Detalle |
|-----------|---------|
| **Tabla** | `asignacion` |
| **Momento** | `BEFORE INSERT` |
| **Función** | `fn_verificar_autorizacion()` |
| **Propósito** | Garantizar la integridad del negocio: un voluntario solo puede ser asignado a un requerimiento si tiene una autorización previa para el rol que dicho requerimiento exige. |

**Lógica:**
1. Obtiene el `id_rol` del requerimiento asociado a la nueva asignación.
2. Verifica que exista un registro en la tabla `autorizacion` con el `id_voluntario` y el `id_rol` correspondiente.
3. Si no existe la autorización, lanza un error con `RAISE EXCEPTION` impidiendo la inserción.

**Ejemplo de uso:**
- Si el voluntario Juan Carlos (ID 1) solo está autorizado para los roles "Guardia de Entrada" (ID 1) y "Logística General" (ID 4), al intentar asignarlo a un requerimiento de "Sonidista" (ID 5), el trigger rechazará la operación.

---

### 1.2 Trigger: `trg_audit_cambio_estado_voluntario`

| Propiedad | Detalle |
|-----------|---------|
| **Tabla** | `voluntario` |
| **Momento** | `AFTER UPDATE` |
| **Función** | `fn_audit_cambio_estado()` |
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

Se crearon procedimientos almacenados para las operaciones de inserción, actualización y eliminación en todas las tablas que implementan CRUD. Cada SP incluye:

- **Validaciones de negocio** (datos no vacíos, existencia de FK, no duplicados)
- **Manejo de errores** con `RAISE EXCEPTION`
- **Control transaccional** mediante bloques `EXCEPTION` de PL/pgSQL (savepoint automático + rollback en caso de error)

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
CREATE OR REPLACE FUNCTION sp_insertar_voluntario(
    p_id_grupo INT, p_nombres VARCHAR, p_apellidos VARCHAR,
    p_telefono VARCHAR, p_fecha_nac DATE, p_estado VARCHAR,
    p_nivel_fisico VARCHAR, p_tipo_limit VARCHAR, p_desc_limit VARCHAR
) RETURNS JSON AS $$
DECLARE
    v_resultado JSON;
BEGIN
    -- Validación: grupo pastoral debe existir
    IF NOT EXISTS (SELECT 1 FROM grupo_pastoral WHERE id_grupo = p_id_grupo) THEN
        RAISE EXCEPTION 'El grupo pastoral ID % no existe', p_id_grupo;
    END IF;

    -- Validación: fecha de nacimiento no puede ser futura
    IF p_fecha_nac > CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de nacimiento no puede ser futura';
    END IF;

    -- Inserción con retorno del registro creado
    INSERT INTO voluntario (id_grupo, nombres, apellidos, telefono,
        fecha_nacimiento, estado_operativo, nivel_capacidad_fisica,
        tipo_limitacion_fisica, descripcion_limitacion)
    VALUES (p_id_grupo, p_nombres, p_apellidos, p_telefono,
        p_fecha_nac, p_estado::enum_estado_operativo,
        p_nivel_fisico::enum_nivel_fisico, p_tipo_limit, p_desc_limit)
    RETURNING row_to_json(voluntario.*) INTO v_resultado;

    RETURN v_resultado;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al insertar voluntario: %', SQLERRM;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Control transaccional:** El bloque `EXCEPTION` crea un savepoint implícito. Si ocurre cualquier error dentro del `BEGIN...EXCEPTION`, PostgreSQL realiza automáticamente un ROLLBACK del savepoint, deshaciendo todos los cambios del SP. Si no hay error, los cambios se confirman (COMMIT implícito).

### Integración con Python (Supabase RPC):

El código del programa fue modificado para llamar a los SPs en lugar de ejecutar SQL directo:

```python
# ANTES (SQL directo):
supabase.table("voluntario").insert({...}).execute()

# AHORA (Stored Procedure via RPC):
supabase.rpc('sp_insertar_voluntario', {
    'p_id_grupo': id_grupo,
    'p_nombres': nombres,
    ...
}).execute()
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
