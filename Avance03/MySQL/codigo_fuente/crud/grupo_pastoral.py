# -*- coding: utf-8 -*-
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from helpers import *

def listar(conn):
    titulo_seccion("Lista de Grupos Pastorales")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM grupo_pastoral")
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]No hay grupos pastorales registrados.[/yellow]")
            return

        columnas = [
            ("ID", "id_grupo"),
            ("Nombre", "nombre_grupo"),
            ("Descripción", "descripcion_grupo")
        ]
        mostrar_tabla(datos, columnas, "Grupos Pastorales", "cyan")
    except Exception as e:
        console.print(f"[bold red]Error al listar grupos pastorales:[/bold red] {e}")

def buscar(conn):
    titulo_seccion("Buscar Grupo Pastoral")
    try:
        id_val = pedir("Ingrese el ID", tipo="int")
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM grupo_pastoral WHERE id_grupo = %s", (id_val,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]No se encontró el registro.[/yellow]")
            return
        columnas = [
            ("ID", "id_grupo"),
            ("Nombre", "nombre_grupo"),
            ("Descripción", "descripcion_grupo")
        ]
        mostrar_tabla(datos, columnas, "Resultado", "cyan")
    except Exception as e:
        console.print(f"[bold red]Error:[/bold red] {e}")

def crear(conn):
    titulo_seccion("Crear Grupo Pastoral")
    try:
        nombre = pedir("Nombre del grupo")
        descripcion = pedir("Descripción del grupo", obligatorio=False)

        cursor = conn.cursor()
        cursor.callproc('sp_insertar_grupo_pastoral', (nombre, descripcion or ''))
        conn.commit()
        cursor.close()
        
        console.print("[bold green]Grupo pastoral creado exitosamente.[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al crear el grupo pastoral:[/bold red] {e}")

def editar(conn):
    titulo_seccion("Editar Grupo Pastoral")
    listar(conn)
    try:
        id_grupo = pedir("Ingrese el ID del grupo a editar", tipo="int")
        
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM grupo_pastoral WHERE id_grupo = %s", (id_grupo,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[bold red]Grupo pastoral no encontrado.[/bold red]")
            return

        grupo_actual = datos[0]
        nombre_nuevo = pedir_edicion("Nombre", grupo_actual["nombre_grupo"])
        desc_nueva = pedir_edicion("Descripción", grupo_actual.get("descripcion_grupo", ""))

        cursor = conn.cursor()
        cursor.callproc('sp_actualizar_grupo_pastoral', (id_grupo, nombre_nuevo, desc_nueva or ''))
        conn.commit()
        cursor.close()
        
        console.print("[bold green]Grupo pastoral actualizado exitosamente.[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al actualizar el grupo pastoral:[/bold red] {e}")

def eliminar(conn):
    titulo_seccion("Eliminar Grupo Pastoral")
    listar(conn)
    try:
        id_grupo = pedir("Ingrese el ID del grupo a eliminar", tipo="int")
        
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM grupo_pastoral WHERE id_grupo = %s", (id_grupo,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[bold red]Grupo pastoral no encontrado.[/bold red]")
            return

        grupo = datos[0]
        if confirmar(f"¿Está seguro que desea eliminar el grupo '{grupo['nombre_grupo']}'?"):
            cursor = conn.cursor()
            cursor.callproc('sp_eliminar_grupo_pastoral', (id_grupo,))
            conn.commit()
            cursor.close()
            console.print("[bold green]Grupo pastoral eliminado exitosamente.[/bold green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[bold red]Error al eliminar el grupo pastoral:[/bold red] {e}")

def menu(conn):
    while True:
        opcion = menu_crud("Grupos Pastorales")
        if opcion == "1": listar(conn)
        elif opcion == "2": buscar(conn)
        elif opcion == "3": crear(conn)
        elif opcion == "4": editar(conn)
        elif opcion == "5": eliminar(conn)
        elif opcion == "0": break
        else: console.print("[bold red]Opción no válida.[/bold red]")
