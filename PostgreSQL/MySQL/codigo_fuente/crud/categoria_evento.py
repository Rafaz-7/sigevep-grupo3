# -*- coding: utf-8 -*-
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from helpers import *

def listar(conn):
    titulo_seccion("Lista de Categorías de Eventos")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM categoria_evento")
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]No hay categorías registradas.[/yellow]")
            return

        columnas = [
            ("ID", "id_categoria"),
            ("Nombre", "nombre_categoria"),
            ("Descripción", "descripcion_categoria")
        ]
        mostrar_tabla(datos, columnas, "Categorías de Eventos", "magenta")
    except Exception as e:
        console.print(f"[bold red]Error al listar categorías:[/bold red] {e}")

def buscar(conn):
    titulo_seccion("Buscar Categoría de Evento")
    try:
        id_val = pedir("Ingrese el ID", tipo="int")
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM categoria_evento WHERE id_categoria = %s", (id_val,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]No se encontró el registro.[/yellow]")
            return
        columnas = [
            ("ID", "id_categoria"),
            ("Nombre", "nombre_categoria"),
            ("Descripción", "descripcion_categoria")
        ]
        mostrar_tabla(datos, columnas, "Resultado", "magenta")
    except Exception as e:
        console.print(f"[bold red]Error:[/bold red] {e}")

def crear(conn):
    titulo_seccion("Crear Categoría de Evento")
    try:
        nombre = pedir("Nombre de la categoría")
        descripcion = pedir("Descripción de la categoría", obligatorio=False)

        cursor = conn.cursor()
        cursor.callproc('sp_insertar_categoria_evento', (nombre, descripcion or ''))
        conn.commit()
        cursor.close()
        
        console.print("[bold green]Categoría creada exitosamente.[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al crear la categoría:[/bold red] {e}")

def editar(conn):
    titulo_seccion("Editar Categoría de Evento")
    listar(conn)
    try:
        id_categoria = pedir("Ingrese el ID de la categoría a editar", tipo="int")
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM categoria_evento WHERE id_categoria = %s", (id_categoria,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[bold red]Categoría no encontrada.[/bold red]")
            return

        cat_actual = datos[0]
        nombre_nuevo = pedir_edicion("Nombre", cat_actual["nombre_categoria"])
        desc_nueva = pedir_edicion("Descripción", cat_actual.get("descripcion_categoria", ""))

        cursor = conn.cursor()
        cursor.callproc('sp_actualizar_categoria_evento', (id_categoria, nombre_nuevo, desc_nueva or ''))
        conn.commit()
        cursor.close()
        
        console.print("[bold green]Categoría actualizada exitosamente.[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al actualizar la categoría:[/bold red] {e}")

def eliminar(conn):
    titulo_seccion("Eliminar Categoría de Evento")
    listar(conn)
    try:
        id_categoria = pedir("Ingrese el ID de la categoría a eliminar", tipo="int")
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM categoria_evento WHERE id_categoria = %s", (id_categoria,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[bold red]Categoría no encontrada.[/bold red]")
            return

        cat = datos[0]
        if confirmar(f"¿Está seguro que desea eliminar la categoría '{cat['nombre_categoria']}'?"):
            cursor = conn.cursor()
            cursor.callproc('sp_eliminar_categoria_evento', (id_categoria,))
            conn.commit()
            cursor.close()
            console.print("[bold green]Categoría eliminada exitosamente.[/bold green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[bold red]Error al eliminar la categoría:[/bold red] {e}")

def menu(conn):
    while True:
        opcion = menu_crud("Categorías de Eventos")
        if opcion == "1": listar(conn)
        elif opcion == "2": buscar(conn)
        elif opcion == "3": crear(conn)
        elif opcion == "4": editar(conn)
        elif opcion == "5": eliminar(conn)
        elif opcion == "0": break
        else: console.print("[bold red]Opción no válida.[/bold red]")
