# SIGEVEP — Sistema de Gestion de Voluntarios para Eventos

**Grupo #3** — Sistemas de Bases de Datos 1 — ESPOL — Primer Termino 2026-2027

## Descripcion

Aplicacion de consola para la gestion integral de voluntarios en eventos parroquiales. Permite realizar operaciones CRUD (Crear, Leer, Actualizar, Eliminar) sobre las 11 tablas del sistema, conectada a una base de datos PostgreSQL en Supabase.

## Requisitos

- Python 3.10+
- Cuenta en [Supabase](https://supabase.com) con el schema ejecutado

## Instalacion

```bash
# 1. Clonar el repositorio
git clone https://github.com/tu-usuario/sigevep-grupo3.git
cd sigevep-grupo3

# 2. Instalar dependencias
pip install -r requirements.txt

# 3. Configurar credenciales
# Copiar .env.example como .env y reemplazar con tus credenciales
cp .env.example .env
# Editar .env con tu URL y KEY de Supabase

# 4. Ejecutar la base de datos
# Abrir schema.sql en el SQL Editor de Supabase y ejecutar

# 5. Ejecutar la aplicacion
python main.py
```

## Estructura del Proyecto

```
sigevep-grupo3/
├── main.py              # Punto de entrada y menu principal
├── db.py                # Conexion a Supabase
├── helpers.py           # Utilidades compartidas (tablas, inputs, validaciones)
├── schema.sql           # Script completo de BD (DDL + datos de prueba)
├── requirements.txt     # Dependencias Python
├── .env.example         # Plantilla de credenciales
├── .gitignore           # Archivos ignorados por Git
└── crud/                # Modulos CRUD por tabla
    ├── grupo_pastoral.py
    ├── categoria_evento.py
    ├── rol.py
    ├── voluntario.py
    ├── evento.py
    ├── usuario.py        # Incluye Administrador y Coordinador
    ├── requerimiento.py
    ├── autorizacion.py
    └── asignacion.py
```

## Manual de Usuario

### Menu Principal

Al ejecutar `python main.py`, se muestra el menu principal con 9 opciones organizadas en dos secciones:

**Tablas Principales (6):**
| Opcion | Tabla | Descripcion |
|--------|-------|-------------|
| 1 | Grupo Pastoral | Grupos parroquiales que organizan eventos |
| 2 | Categoria Evento | Tipos de evento (Religioso, Social, etc.) |
| 3 | Rol | Roles que pueden desempenar los voluntarios |
| 4 | Voluntario | Personas inscritas como voluntarios |
| 5 | Evento | Eventos programados por los grupos |
| 6 | Usuario | Usuarios del sistema (Administradores y Coordinadores) |

**Tablas de Relacion (3):**
| Opcion | Tabla | Relacion |
|--------|-------|----------|
| 7 | Requerimiento | Evento ↔ Rol (cuantos voluntarios se necesitan por rol) |
| 8 | Autorizacion | Voluntario ↔ Rol (que roles puede desempenar cada voluntario) |
| 9 | Asignacion | Voluntario asignado a un requerimiento especifico |

### Operaciones CRUD

Al seleccionar cualquier tabla, se despliega un submenu con las siguientes operaciones:

#### 1. Listar todos
Muestra todos los registros de la tabla en formato de tabla con colores y formato profesional. Incluye datos de tablas relacionadas (por ejemplo, al listar voluntarios se muestra el nombre del grupo pastoral).

#### 2. Buscar por ID
Permite buscar un registro especifico ingresando su ID. Muestra todos los campos del registro encontrado.

#### 3. Anadir nuevo
Formulario interactivo que solicita cada campo:
- Los campos obligatorios se validan automaticamente
- Los campos opcionales pueden dejarse vacios (Enter)
- Los campos con opciones fijas muestran las opciones disponibles
- Las claves foraneas muestran una lista de registros disponibles para seleccionar

#### 4. Editar existente
Selecciona un registro por ID y permite modificar cada campo:
- Presionar Enter mantiene el valor actual
- Se muestran los valores actuales como referencia

#### 5. Eliminar
Selecciona un registro por ID, muestra los datos actuales y solicita confirmacion antes de eliminar. Verifica dependencias para evitar errores de integridad referencial.

### Tablas Especiales

#### Usuario (Opcion 6)
Maneja la herencia supertipo-subtipo:
- Al crear un usuario, se pregunta primero el rol (Administrador/Coordinador)
- Automaticamente crea el registro en la tabla del subtipo correspondiente
- Al eliminar, borra primero el subtipo y luego el supertipo

#### Autorizacion (Opcion 8)
Tiene clave primaria compuesta (id_voluntario + id_rol):
- Para buscar o eliminar, se solicitan ambos valores
- Registra que usuario del sistema realizo la autorizacion

## Base de Datos

### Modelo de Datos (11 tablas)

```
GRUPO_PASTORAL (10 reg)  →  VOLUNTARIO (15 reg)
                          →  EVENTO (12 reg)
CATEGORIA_EVENTO (10 reg) →  EVENTO
ROL (10 reg)              →  REQUERIMIENTO (15 reg)  ←  EVENTO
USUARIO (20 reg)          →  ADMINISTRADOR (10 reg)  [subtipo]
                          →  COORDINADOR (10 reg)    [subtipo]
                          →  AUTORIZACION (20 reg)   ←  VOLUNTARIO + ROL
                          →  ASIGNACION (15 reg)     ←  VOLUNTARIO + REQUERIMIENTO
```

### Total: 147 registros de prueba (minimo 10 por tabla)

## Integrantes

| # | Nombre | Modulos |
|---|--------|---------|
| 1 | Integrante 1 | main.py, db.py, grupo_pastoral, categoria_evento |
| 2 | Integrante 2 | voluntario, evento |
| 3 | Integrante 3 | rol, usuario (admin + coordinador) |
| 4 | Integrante 4 | requerimiento, autorizacion, asignacion |

## Tecnologias

- **Python 3.12** — Lenguaje principal
- **Supabase** — Base de datos PostgreSQL en la nube
- **Rich** — Interfaz de consola con formato profesional
- **python-dotenv** — Manejo de variables de entorno
