# -*- coding: utf-8 -*-
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from helpers import *

def listar(conn):
    titulo_seccion("Listado de Requerimientos")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT r.id_requerimiento, r.id_evento, r.id_rol, r.cantidad_requerida,
                   e.nombre_evento as evento_nombre, rl.nombre_rol as rol_nombre
            FROM requerimiento r
            LEFT JOIN evento e ON r.id_evento = e.id_evento
            LEFT JOIN rol rl ON r.id_rol = rl.id_rol
        ''')
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]No hay requerimientos registrados.[/yellow]")
            return

        columnas = [
            ("ID", "id_requerimiento", 5, "cyan"),
            ("Evento", "evento_nombre", 20, "magenta"),
            ("Rol", "rol_nombre", 20, "green"),
            ("Cantidad", "cantidad_requerida", 10, "yellow")
        ]
        mostrar_tabla(datos, columnas, "Requerimientos Registrados", "cyan")
    except Exception as e:
        console.print(f"[red]Error al listar: {e}[/red]")

def agregar(conn):
    titulo_seccion("Agregar Requerimiento")
    try:
        id_evento = seleccionar_fk(conn, "evento", "id_evento", "nombre_evento", "Seleccione el Evento")
        if not id_evento: return
        id_rol = seleccionar_fk(conn, "rol", "id_rol", "nombre_rol", "Seleccione el Rol")
        if not id_rol: return
        
        cantidad = pedir("Cantidad requerida: ", tipo="int")
        
        cursor = conn.cursor()
        cursor.callproc('sp_insertar_requerimiento', (id_evento, id_rol, cantidad))
        conn.commit()
        cursor.close()
        
        console.print("[green]Requerimiento agregado exitosamente.[/green]")
    except Exception as e:
        console.print(f"[red]Error al agregar: {e}[/red]")

def buscar(conn):
    titulo_seccion("Buscar Requerimiento")
    id_req = pedir("ID del requerimiento a buscar: ", tipo="int")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT r.id_requerimiento, r.cantidad_requerida,
                   e.nombre_evento as evento_nombre, rl.nombre_rol as rol_nombre
            FROM requerimiento r
            LEFT JOIN evento e ON r.id_evento = e.id_evento
            LEFT JOIN rol rl ON r.id_rol = rl.id_rol
            WHERE r.id_requerimiento = %s
        ''', (id_req,))
        datos = cursor.fetchall()
        cursor.close()
        
        if datos:
            d = datos[0]
            console.print(f"\n[cyan]ID:[/cyan] {d['id_requerimiento']}")
            console.print(f"[cyan]Evento:[/cyan] {d.get('evento_nombre', 'N/A')}")
            console.print(f"[cyan]Rol:[/cyan] {d.get('rol_nombre', 'N/A')}")
            console.print(f"[cyan]Cantidad requerida:[/cyan] {d['cantidad_requerida']}")
        else:
            console.print("[yellow]Requerimiento no encontrado.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al buscar: {e}[/red]")

def editar(conn):
    titulo_seccion("Editar Requerimiento")
    id_req = pedir("ID del requerimiento a editar: ", tipo="int")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM requerimiento WHERE id_requerimiento = %s", (id_req,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]Requerimiento no encontrado.[/yellow]")
            return
        
        actual = datos[0]
        nueva_cantidad = pedir_edicion("Cantidad requerida", actual['cantidad_requerida'], tipo="int")
        
        cursor = conn.cursor()
        cursor.callproc('sp_actualizar_requerimiento', (id_req, nueva_cantidad))
        conn.commit()
        cursor.close()
        
        console.print("[green]Requerimiento actualizado exitosamente.[/green]")
    except Exception as e:
        console.print(f"[red]Error al editar: {e}[/red]")

def eliminar(conn):
    titulo_seccion("Eliminar Requerimiento")
    id_req = pedir("ID del requerimiento a eliminar: ", tipo="int")
    try:
        if confirmar("¿Está seguro de eliminar este requerimiento?"):
            cursor = conn.cursor()
            cursor.callproc('sp_eliminar_requerimiento', (id_req,))
            conn.commit()
            cursor.close()
            console.print("[green]Requerimiento eliminado.[/green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al eliminar: {e}[/red]")

def menu(conn):
    while True:
        op = menu_crud("Requerimiento")
        if op == '1': listar(conn)
        elif op == '2': buscar(conn)
        elif op == '3': agregar(conn)
        elif op == '4': editar(conn)
        elif op == '5': eliminar(conn)
        elif op == '0': break
