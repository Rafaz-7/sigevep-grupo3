# -*- coding: utf-8 -*-
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from helpers import *

def listar(conn):
    titulo_seccion("Lista de Roles")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM rol")
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]No hay roles registrados.[/yellow]")
            return

        columnas = [
            ("ID", "id_rol"),
            ("Nombre", "nombre_rol"),
            ("Descripción", "descripcion_rol"),
            ("Requiere EPP", "requiere_epp"),
            ("Demanda Física", "nivel_demanda_fisica")
        ]
        mostrar_tabla(datos, columnas, "Roles", "blue")
    except Exception as e:
        console.print(f"[bold red]Error al listar roles:[/bold red] {e}")

def buscar(conn):
    titulo_seccion("Buscar Rol")
    try:
        id_val = pedir("Ingrese el ID", tipo="int")
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM rol WHERE id_rol = %s", (id_val,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]No se encontró el registro.[/yellow]")
            return
        columnas = [
            ("ID", "id_rol"),
            ("Nombre", "nombre_rol"),
            ("Descripción", "descripcion_rol"),
            ("Requiere EPP", "requiere_epp"),
            ("Demanda Física", "nivel_demanda_fisica")
        ]
        mostrar_tabla(datos, columnas, "Resultado", "blue")
    except Exception as e:
        console.print(f"[bold red]Error:[/bold red] {e}")

def crear(conn):
    titulo_seccion("Crear Rol")
    try:
        nombre = pedir("Nombre del rol")
        descripcion = pedir("Descripción del rol")
        requiere_epp = pedir("¿Requiere EPP (Equipo de Protección Personal)?", tipo="bool")
        demanda = pedir("Nivel de demanda física", opciones=['Alto', 'Medio', 'Bajo'])

        cursor = conn.cursor()
        cursor.callproc('sp_insertar_rol', (nombre, descripcion, requiere_epp, demanda))
        conn.commit()
        cursor.close()
        
        console.print("[bold green]Rol creado exitosamente.[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al crear el rol:[/bold red] {e}")

def editar(conn):
    titulo_seccion("Editar Rol")
    listar(conn)
    try:
        id_rol = pedir("Ingrese el ID del rol a editar", tipo="int")
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM rol WHERE id_rol = %s", (id_rol,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[bold red]Rol no encontrado.[/bold red]")
            return

        rol_actual = datos[0]

        nombre_nuevo = pedir_edicion("Nombre", rol_actual["nombre_rol"])
        desc_nueva = pedir_edicion("Descripción", rol_actual["descripcion_rol"])
        
        if confirmar(f"¿Editar requerimiento de EPP? (Actual: {rol_actual['requiere_epp']})"):
            req_epp_nuevo = pedir("¿Requiere EPP?", tipo="bool")
        else:
            req_epp_nuevo = rol_actual["requiere_epp"]
            
        if confirmar(f"¿Editar demanda física? (Actual: {rol_actual['nivel_demanda_fisica']})"):
            demanda_nueva = pedir("Nivel de demanda física", opciones=['Alto', 'Medio', 'Bajo'])
        else:
            demanda_nueva = rol_actual["nivel_demanda_fisica"]

        cursor = conn.cursor()
        cursor.callproc('sp_actualizar_rol', (id_rol, nombre_nuevo, desc_nueva, req_epp_nuevo, demanda_nueva))
        conn.commit()
        cursor.close()
        
        console.print("[bold green]Rol actualizado exitosamente.[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al actualizar el rol:[/bold red] {e}")

def eliminar(conn):
    titulo_seccion("Eliminar Rol")
    listar(conn)
    try:
        id_rol = pedir("Ingrese el ID del rol a eliminar", tipo="int")
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM rol WHERE id_rol = %s", (id_rol,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[bold red]Rol no encontrado.[/bold red]")
            return

        rol = datos[0]
        if confirmar(f"¿Está seguro que desea eliminar el rol '{rol['nombre_rol']}'?"):
            cursor = conn.cursor()
            cursor.callproc('sp_eliminar_rol', (id_rol,))
            conn.commit()
            cursor.close()
            console.print("[bold green]Rol eliminado exitosamente.[/bold green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[bold red]Error al eliminar el rol:[/bold red] {e}")

def menu(conn):
    while True:
        opcion = menu_crud("Roles")
        if opcion == "1": listar(conn)
        elif opcion == "2": buscar(conn)
        elif opcion == "3": crear(conn)
        elif opcion == "4": editar(conn)
        elif opcion == "5": eliminar(conn)
        elif opcion == "0": break
        else: console.print("[bold red]Opción no válida.[/bold red]")
