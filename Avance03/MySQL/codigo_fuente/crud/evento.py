# -*- coding: utf-8 -*-
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from helpers import *

def crear(conn):
    titulo_seccion("Crear Evento")
    
    id_grupo = seleccionar_fk(conn, "grupo_pastoral", "id_grupo", "nombre_grupo", "Seleccione el Grupo Pastoral: ")
    if not id_grupo:
        return
        
    id_categoria = seleccionar_fk(conn, "categoria_evento", "id_categoria", "nombre_categoria", "Seleccione la Categoría de Evento: ")
    if not id_categoria:
        return

    nombre_evento = pedir("Nombre del Evento: ")
    fecha_programada = pedir("Fecha Programada (YYYY-MM-DD): ")
    ubicacion = pedir("Ubicación: ")
    
    try:
        cursor = conn.cursor()
        cursor.callproc('sp_insertar_evento', (id_grupo, id_categoria, nombre_evento, fecha_programada, ubicacion))
        conn.commit()
        cursor.close()
        console.print("[bold green]Evento creado exitosamente.[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al crear evento: {e}[/bold red]")

def listar(conn):
    titulo_seccion("Lista de Eventos")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT e.*, g.nombre_grupo, c.nombre_categoria 
            FROM evento e
            LEFT JOIN grupo_pastoral g ON e.id_grupo = g.id_grupo
            LEFT JOIN categoria_evento c ON e.id_categoria = c.id_categoria
        ''')
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]No hay eventos registrados.[/yellow]")
            return
                
        columnas = [
            ("ID", "id_evento"),
            ("Grupo", "nombre_grupo"),
            ("Categoría", "nombre_categoria"),
            ("Nombre", "nombre_evento"),
            ("Fecha", "fecha_programada"),
            ("Ubicación", "ubicacion")
        ]
        mostrar_tabla(datos, columnas, "Eventos", "magenta")
    except Exception as e:
        console.print(f"[bold red]Error al listar eventos: {e}[/bold red]")

def buscar(conn):
    titulo_seccion("Buscar Evento")
    try:
        id_val = pedir("Ingrese el ID", tipo="int")
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT e.*, g.nombre_grupo, c.nombre_categoria 
            FROM evento e
            LEFT JOIN grupo_pastoral g ON e.id_grupo = g.id_grupo
            LEFT JOIN categoria_evento c ON e.id_categoria = c.id_categoria
            WHERE e.id_evento = %s
        ''', (id_val,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]No se encontró el registro.[/yellow]")
            return
                
        columnas = [
            ("ID", "id_evento"),
            ("Grupo", "nombre_grupo"),
            ("Categoría", "nombre_categoria"),
            ("Nombre", "nombre_evento"),
            ("Fecha", "fecha_programada"),
            ("Ubicación", "ubicacion")
        ]
        mostrar_tabla(datos, columnas, "Resultado", "magenta")
    except Exception as e:
        console.print(f"[bold red]Error:[/bold red] {e}")

def actualizar(conn):
    titulo_seccion("Actualizar Evento")
    id_evento = pedir("ID del evento a actualizar: ", tipo="int")
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM evento WHERE id_evento = %s", (id_evento,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]Evento no encontrado.[/yellow]")
            return
            
        actual = datos[0]
        
        id_grupo_str = pedir_edicion("ID Grupo", str(actual.get("id_grupo")))
        id_categoria_str = pedir_edicion("ID Categoría", str(actual.get("id_categoria")))
        nombre_evento = pedir_edicion("Nombre", actual.get("nombre_evento"))
        fecha_programada = pedir_edicion("Fecha Programada", actual.get("fecha_programada"))
        ubicacion = pedir_edicion("Ubicación", actual.get("ubicacion"))
        
        id_grupo = int(id_grupo_str) if id_grupo_str.isdigit() else actual.get("id_grupo")
        id_categoria = int(id_categoria_str) if id_categoria_str.isdigit() else actual.get("id_categoria")
        
        cursor = conn.cursor()
        cursor.callproc('sp_actualizar_evento', (id_evento, id_grupo, id_categoria, nombre_evento, fecha_programada, ubicacion))
        conn.commit()
        cursor.close()
        console.print("[bold green]Evento actualizado exitosamente.[/bold green]")
        
    except Exception as e:
        console.print(f"[bold red]Error al actualizar evento: {e}[/bold red]")

def eliminar(conn):
    titulo_seccion("Eliminar Evento")
    id_evento = pedir("ID del evento a eliminar: ", tipo="int")
    
    if confirmar(f"¿Está seguro de eliminar el evento {id_evento}?"):
        try:
            cursor = conn.cursor()
            cursor.callproc('sp_eliminar_evento', (id_evento,))
            conn.commit()
            cursor.close()
            console.print("[bold green]Evento eliminado exitosamente.[/bold green]")
        except Exception as e:
            console.print(f"[bold red]Error al eliminar evento: {e}[/bold red]")

def menu(conn):
    while True:
        opc = menu_crud("Evento")
        if opc == "1": listar(conn)
        elif opc == "2": buscar(conn)
        elif opc == "3": crear(conn)
        elif opc == "4": actualizar(conn)
        elif opc == "5": eliminar(conn)
        elif opc == "0": break
