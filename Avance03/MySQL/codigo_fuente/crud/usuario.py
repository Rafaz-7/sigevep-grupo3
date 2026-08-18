# -*- coding: utf-8 -*-
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from helpers import *

def menu(conn):
    while True:
        opcion = menu_crud("Usuario")
        if opcion == '1': listar_usuarios(conn)
        elif opcion == '2': buscar_usuario(conn)
        elif opcion == '3': agregar_usuario(conn)
        elif opcion == '4': editar_usuario(conn)
        elif opcion == '5': eliminar_usuario(conn)
        elif opcion == '0': break
        else: console.print("[red]Opción no válida.[/red]")

def listar_usuarios(conn):
    titulo_seccion("Lista de Usuarios")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT u.id_usuario, u.nombre_usuario, u.rol_acceso,
                   a.nivel_permiso, c.zona_asignada
            FROM usuario u
            LEFT JOIN administrador a ON u.id_usuario = a.id_usuario
            LEFT JOIN coordinador c ON u.id_usuario = c.id_usuario
        ''')
        datos = cursor.fetchall()
        cursor.close()
        
        for d in datos:
            if not d['nivel_permiso']: d['nivel_permiso'] = '-'
            if not d['zona_asignada']: d['zona_asignada'] = '-'

        columnas = [
            ("ID", "id_usuario"),
            ("Nombre", "nombre_usuario"),
            ("Rol", "rol_acceso"),
            ("Nivel Permiso (Admin)", "nivel_permiso"),
            ("Zona Asignada (Coord)", "zona_asignada")
        ]
        mostrar_tabla(datos, columnas, "Usuarios", "cyan")
    except Exception as e:
        console.print(f"[red]Error al listar usuarios: {e}[/red]")

def buscar_usuario(conn):
    titulo_seccion("Buscar Usuario")
    id_usuario = pedir("Ingrese el ID del usuario a buscar", tipo="int")
    if id_usuario is None: return

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT u.id_usuario, u.nombre_usuario, u.rol_acceso,
                   a.nivel_permiso, c.zona_asignada
            FROM usuario u
            LEFT JOIN administrador a ON u.id_usuario = a.id_usuario
            LEFT JOIN coordinador c ON u.id_usuario = c.id_usuario
            WHERE u.id_usuario = %s
        ''', (id_usuario,))
        usuario = cursor.fetchall()
        cursor.close()
        
        if not usuario:
            console.print("[yellow]Usuario no encontrado.[/yellow]")
            return
            
        u = usuario[0]
        console.print(f"\n[green]ID:[/green] {u['id_usuario']}")
        console.print(f"[green]Nombre:[/green] {u['nombre_usuario']}")
        console.print(f"[green]Rol:[/green] {u['rol_acceso']}")

        if u['rol_acceso'] == 'Administrador' and u['nivel_permiso']:
            console.print(f"[green]Nivel Permiso:[/green] {u['nivel_permiso']}")
        elif u['rol_acceso'] == 'Coordinador' and u['zona_asignada']:
            console.print(f"[green]Zona Asignada:[/green] {u['zona_asignada']}")
                
    except Exception as e:
        console.print(f"[red]Error al buscar usuario: {e}[/red]")

def agregar_usuario(conn):
    titulo_seccion("Añadir Usuario")
    nombre = pedir("Nombre de usuario")
    if not nombre: return
    clave = pedir("Clave de acceso")
    if not clave: return
    rol = pedir("Rol de acceso", opciones=["Administrador", "Coordinador"])
    if not rol: return

    try:
        nivel_permiso = ''
        zona_asignada = ''
        if rol == 'Administrador':
            nivel_permiso = pedir("Nivel de permiso", opciones=["Total", "Parcial"])
        elif rol == 'Coordinador':
            zona_asignada = pedir("Zona asignada")
            
        cursor = conn.cursor()
        cursor.callproc('sp_insertar_usuario', (nombre, clave, rol, nivel_permiso, zona_asignada))
        conn.commit()
        cursor.close()
        
        console.print(f"[bold green]Usuario añadido exitosamente.[/bold green]")
    except Exception as e:
        console.print(f"[red]Error al añadir usuario: {e}[/red]")

def editar_usuario(conn):
    titulo_seccion("Editar Usuario")
    id_usuario = pedir("Ingrese el ID del usuario a editar", tipo="int")
    if id_usuario is None: return

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT u.id_usuario, u.nombre_usuario, u.clave_acceso, u.rol_acceso,
                   a.nivel_permiso, c.zona_asignada
            FROM usuario u
            LEFT JOIN administrador a ON u.id_usuario = a.id_usuario
            LEFT JOIN coordinador c ON u.id_usuario = c.id_usuario
            WHERE u.id_usuario = %s
        ''', (id_usuario,))
        usuario = cursor.fetchall()
        cursor.close()
        
        if not usuario:
            console.print("[yellow]Usuario no encontrado.[/yellow]")
            return
            
        u = usuario[0]
        nuevo_nombre = pedir_edicion("Nombre de usuario", u['nombre_usuario'])
        nueva_clave = pedir_edicion("Clave de acceso", u['clave_acceso'])
        
        nuevo_nivel = u['nivel_permiso'] or ''
        nueva_zona = u['zona_asignada'] or ''
        
        if u['rol_acceso'] == 'Administrador':
            nuevo_nivel = pedir_edicion("Nivel de permiso", u['nivel_permiso'], opciones=["Total", "Parcial"])
        elif u['rol_acceso'] == 'Coordinador':
            nueva_zona = pedir_edicion("Zona asignada", u['zona_asignada'])

        cursor = conn.cursor()
        cursor.callproc('sp_actualizar_usuario', (id_usuario, nuevo_nombre, nueva_clave, nuevo_nivel, nueva_zona))
        conn.commit()
        cursor.close()

        console.print("[bold green]Usuario actualizado exitosamente.[/bold green]")
    except Exception as e:
        console.print(f"[red]Error al editar usuario: {e}[/red]")

def eliminar_usuario(conn):
    titulo_seccion("Eliminar Usuario")
    id_usuario = pedir("Ingrese el ID del usuario a eliminar", tipo="int")
    if id_usuario is None: return

    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM usuario WHERE id_usuario = %s", (id_usuario,))
        usuario = cursor.fetchall()
        cursor.close()
        
        if not usuario:
            console.print("[yellow]Usuario no encontrado.[/yellow]")
            return

        if confirmar(f"¿Está seguro que desea eliminar el usuario ID {id_usuario}?"):
            cursor = conn.cursor()
            cursor.callproc('sp_eliminar_usuario', (id_usuario,))
            conn.commit()
            cursor.close()
            console.print("[bold green]Usuario eliminado exitosamente.[/bold green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al eliminar usuario: {e}[/red]")
