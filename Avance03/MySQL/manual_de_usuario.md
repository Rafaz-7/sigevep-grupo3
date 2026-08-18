# SIGEVEP — Manual de Usuario
## Sistema de Gestión de Voluntarios para Eventos Parroquiales
### Grupo #3 — Sistemas de Bases de Datos 1 — ESPOL

---

## 1. Requisitos del Sistema

- **Python 3.10 o superior**
- **MySQL Server 8.0** instalado y corriendo
- **MySQL Workbench** (opcional, para administración)

### Dependencias (Python):
```
mysql-connector-python
rich
```

## 2. Instalación

### 2.1 Clonar o descargar el proyecto
Copiar todos los archivos del directorio `codigo_fuente/` a una carpeta local.

### 2.2 Instalar dependencias
```bash
pip install mysql-connector-python rich
```
O usando el archivo de requisitos:
```bash
pip install -r requirements.txt
```

### 2.3 Configurar conexión a MySQL
1. Abrir `db.py`
2. Editar las credenciales de conexión:
```python
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',  # Colocar su contraseña de MySQL
    'database': 'sigevep',
}
```

### 2.4 Ejecutar el schema SQL
1. Abrir **MySQL Workbench**
2. Conectarse al servidor local
3. Abrir el archivo `schema_final.sql`
4. Ejecutar el script completo (esto crea la base de datos, tablas, datos, SPs, triggers, índices y usuarios)

## 3. Ejecución

```bash
python main.py
```

Al iniciar, se muestra el banner del sistema y el menú principal:

```
╔══════════════════ ESPOL ═══════════════════╗
║                                            ║
║     SISTEMA DE GESTION DE VOLUNTARIOS      ║
║             SIGEVEP — Grupo #3             ║
║    Sistemas de Bases de Datos 1 - ESPOL    ║
║     CRUD + SP + Triggers — Avance 03    ║
║                                            ║
╚═════════ Primer Termino 2026-2027 ═════════╝
Conexion a MySQL establecida.
```

## 4. Menú Principal

```
==================================================
          MENU PRINCIPAL — SIGEVEP
==================================================

  Tablas Principales
    1. Grupo Pastoral
    2. Categoria Evento
    3. Rol
    4. Voluntario
    5. Evento
    6. Usuario (Admin/Coord)

  Tablas de Relacion
    7. Requerimiento (Evento-Rol)
    8. Autorizacion (Voluntario-Rol)
    9. Asignacion

    0. Salir del Sistema

Opcion >
```

Ingrese el número de la opción deseada y presione **Enter**.

## 5. Operaciones CRUD

Cada tabla tiene las mismas 5 operaciones disponibles:

### 5.1 Listar Todos (Opción 1)
Muestra todos los registros de la tabla en formato de tabla formateada con colores.
- Se muestran valores descriptivos (nombres en vez de IDs) para claves foráneas.
- Se indica el total de registros al final.

### 5.2 Buscar por ID (Opción 2)
Busca un registro específico por su identificador.
- En tablas con clave primaria compuesta (como Autorización), se piden ambos IDs.

### 5.3 Añadir Nuevo (Opción 3)
Crea un nuevo registro en la base de datos.
- Los campos obligatorios se validan (no se aceptan vacíos).
- Los campos con opciones limitadas muestran las opciones válidas.
- Las claves foráneas muestran los registros disponibles para seleccionar.
- Las operaciones de inserción se ejecutan mediante **Stored Procedures** que incluyen validaciones adicionales del lado de la base de datos.

### 5.4 Editar Existente (Opción 4)
Modifica un registro existente.
- Se muestra el valor actual de cada campo.
- Presione **Enter** sin escribir nada para mantener el valor actual.
- Las actualizaciones se ejecutan mediante Stored Procedures.

### 5.5 Eliminar (Opción 5)
Elimina un registro de la base de datos.
- Se solicita confirmación antes de eliminar (`s/n`).
- Los Stored Procedures validan que no existan dependencias antes de eliminar.
- Si el registro tiene dependencias (ej: un grupo pastoral con voluntarios), se muestra un error explicativo.

## 6. Descripción de Tablas

### 6.1 Tablas Principales

| Tabla | Descripción | Campos Principales |
|-------|-------------|-------------------|
| **Grupo Pastoral** | Agrupaciones parroquiales | nombre, descripción |
| **Categoría Evento** | Clasificación de eventos | nombre, descripción |
| **Rol** | Roles asignables a voluntarios | nombre, descripción, requiere EPP, nivel demanda física |
| **Voluntario** | Personas registradas | nombres, apellidos, teléfono, fecha nacimiento, estado, grupo pastoral |
| **Evento** | Actividades planificadas | nombre, fecha, ubicación, grupo pastoral, categoría |
| **Usuario** | Usuarios del sistema | nombre de usuario, clave, rol (Admin/Coordinador) |

### 6.2 Tablas de Relación

| Tabla | Relación | Descripción |
|-------|----------|-------------|
| **Requerimiento** | Evento ↔ Rol | Cuántos voluntarios de cada rol necesita un evento |
| **Autorización** | Voluntario ↔ Rol | Qué roles puede desempeñar cada voluntario |
| **Asignación** | Voluntario ↔ Requerimiento | Asignación concreta de un voluntario a un turno |

## 7. Validaciones Automáticas

El sistema incluye las siguientes validaciones automáticas:

### 7.1 Desde Stored Procedures:
- No se permiten nombres duplicados en grupo pastoral, categoría, rol.
- No se pueden eliminar registros con dependencias (ej: un rol que tiene autorizaciones).
- Se valida la existencia de claves foráneas antes de insertar.
- La fecha de nacimiento del voluntario no puede ser futura.
- La hora de fin debe ser posterior a la hora de inicio en asignaciones.

### 7.2 Desde Triggers:
- **Verificación de autorización:** Al crear una asignación, se verifica automáticamente que el voluntario tenga autorización para el rol requerido.
- **Auditoría:** Al modificar un voluntario, los cambios en estado operativo, nombres y apellidos se registran automáticamente en la tabla de auditoría.

## 8. Reportes

Los reportes están implementados como vistas SQL accesibles desde MySQL Workbench:

| Reporte | Vista | Descripción |
|---------|-------|-------------|
| Asignaciones Completo | `reporte_asignaciones_completo` | Todas las asignaciones con información detallada |
| Voluntarios por Grupo | `reporte_voluntarios_por_grupo` | Voluntarios organizados por grupo pastoral |
| Cobertura de Eventos | `reporte_cobertura_eventos` | Porcentaje de cobertura de cada evento |
| Actividad de Usuarios | `reporte_actividad_usuarios` | Actividad de aprobaciones/autorizaciones por usuario |

## 9. Solución de Problemas

| Problema | Solución |
|----------|----------|
| `Error: getaddrinfo failed` | MySQL no está corriendo. Iniciar el servicio MySQL80. |
| `Error: invalid input value for enum` | Verificar que el valor ingresado coincida exactamente con las opciones (ej: 'Alto', no 'alto'). |
| `Error al eliminar: Cannot delete` | El registro tiene dependencias. Eliminar primero los registros dependientes. |
| `ModuleNotFoundError` | Ejecutar `pip install mysql-connector-python rich`. |
| Caracteres especiales no se muestran | Ejecutar con `$env:PYTHONIOENCODING='utf-8'; python main.py` |

## 10. Estructura de Archivos

```
codigo_fuente/
├── main.py                # Punto de entrada y menú principal
├── db.py                  # Módulo de conexión a MySQL (Singleton)
├── helpers.py             # Utilidades compartidas (tablas, validación, UI)
├── requirements.txt       # Dependencias Python
└── crud/                  # Módulos CRUD (uno por tabla)
    ├── __init__.py
    ├── grupo_pastoral.py
    ├── categoria_evento.py
    ├── rol.py
    ├── voluntario.py
    ├── evento.py
    ├── usuario.py
    ├── requerimiento.py
    ├── autorizacion.py
    └── asignacion.py
```
