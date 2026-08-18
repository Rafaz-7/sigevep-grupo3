# -*- coding: utf-8 -*-
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from helpers import *
from datetime import date

def listar(conn):
    titulo_seccion("Listado de Autorizaciones")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT a.id_voluntario, a.id_rol, a.id_usuario_autorizador, a.fecha_autorizacion,
                   v.nombres as v_nombres, v.apellidos as v_apellidos,
                   r.nombre_rol as rol_nombre,
                   u.nombre_usuario as autorizador
            FROM autorizacion a
            LEFT JOIN voluntario v ON a.id_voluntario = v.id_voluntario
            LEFT JOIN rol r ON a.id_rol = r.id_rol
            LEFT JOIN usuario u ON a.id_usuario_autorizador = u.id_usuario
        ''')
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]No hay autorizaciones registradas.[/yellow]")
            return

        for d in datos:
            d['voluntario_nombre'] = f"{d.get('v_nombres', '')} {d.get('v_apellidos', '')}".strip()

        columnas = [
            ("Voluntario", "voluntario_nombre", 25, "cyan"),
            ("Rol", "rol_nombre", 20, "magenta"),
            ("Autorizador", "autorizador", 15, "green"),
            ("Fecha", "fecha_autorizacion", 12, "yellow")
        ]
        mostrar_tabla(datos, columnas, "Autorizaciones", "cyan")
    except Exception as e:
        console.print(f"[red]Error al listar: {e}[/red]")

def agregar(conn):
    titulo_seccion("Agregar Autorización")
    try:
        id_voluntario = pedir("ID Voluntario: ", tipo="int")
        id_rol = seleccionar_fk(conn, "rol", "id_rol", "nombre_rol", "Seleccione el Rol")
        if not id_rol: return
        id_usuario = seleccionar_fk(conn, "usuario", "id_usuario", "nombre_usuario", "Seleccione el Usuario Autorizador")
        if not id_usuario: return
        
        fecha_auth = str(date.today())
        
        cursor = conn.cursor()
        cursor.callproc('sp_insertar_autorizacion', (id_voluntario, id_rol, id_usuario, fecha_auth))
        conn.commit()
        cursor.close()
        
        console.print("[green]Autorización agregada exitosamente.[/green]")
    except Exception as e:
        console.print(f"[red]Error al agregar: {e}[/red]")

def buscar(conn):
    titulo_seccion("Buscar Autorización")
    id_vol = pedir("ID del voluntario: ", tipo="int")
    id_rol = pedir("ID del rol: ", tipo="int")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT a.*,
                   v.nombres as v_nombres, v.apellidos as v_apellidos,
                   r.nombre_rol as rol_nombre,
                   u.nombre_usuario as autorizador
            FROM autorizacion a
            LEFT JOIN voluntario v ON a.id_voluntario = v.id_voluntario
            LEFT JOIN rol r ON a.id_rol = r.id_rol
            LEFT JOIN usuario u ON a.id_usuario_autorizador = u.id_usuario
            WHERE a.id_voluntario = %s AND a.id_rol = %s
        ''', (id_vol, id_rol))
        datos = cursor.fetchall()
        cursor.close()
        
        if datos:
            d = datos[0]
            vol_nom = f"{d.get('v_nombres', '')} {d.get('v_apellidos', '')}".strip()
            
            console.print(f"\n[cyan]Voluntario:[/cyan] {vol_nom} (ID: {d['id_voluntario']})")
            console.print(f"[cyan]Rol:[/cyan] {d.get('rol_nombre', 'N/A')} (ID: {d['id_rol']})")
            console.print(f"[cyan]Autorizado por:[/cyan] {d.get('autorizador', 'N/A')}")
            console.print(f"[cyan]Fecha:[/cyan] {d['fecha_autorizacion']}")
        else:
            console.print("[yellow]Autorización no encontrada.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al buscar: {e}[/red]")

def editar(conn):
    titulo_seccion("Editar Autorización")
    console.print("Busque la autorización a editar:")
    id_vol = pedir("ID del voluntario: ", tipo="int")
    id_rol = pedir("ID del rol: ", tipo="int")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM autorizacion WHERE id_voluntario = %s AND id_rol = %s", (id_vol, id_rol))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]Autorización no encontrada.[/yellow]")
            return
        
        actual = datos[0]
        nuevo_id_usuario = pedir_edicion("ID del usuario autorizador", actual.get('id_usuario_autorizador', ''), tipo="int")
        nueva_fecha = pedir_edicion("Fecha de autorización (YYYY-MM-DD)", actual.get('fecha_autorizacion', ''), tipo="str")
        
        cursor = conn.cursor()
        cursor.callproc('sp_actualizar_autorizacion', (id_vol, id_rol, nuevo_id_usuario, nueva_fecha))
        conn.commit()
        cursor.close()
        
        console.print("[green]Autorización actualizada exitosamente.[/green]")
    except Exception as e:
        console.print(f"[red]Error al editar: {e}[/red]")

def eliminar(conn):
    titulo_seccion("Eliminar Autorización")
    id_vol = pedir("ID del voluntario: ", tipo="int")
    id_rol = pedir("ID del rol: ", tipo="int")
    try:
        if confirmar("¿Está seguro de eliminar esta autorización?"):
            cursor = conn.cursor()
            cursor.callproc('sp_eliminar_autorizacion', (id_vol, id_rol))
            conn.commit()
            cursor.close()
            console.print("[green]Autorización eliminada.[/green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al eliminar: {e}[/red]")

def menu(conn):
    while True:
        op = menu_crud("Autorización")
        if op == '1': listar(conn)
        elif op == '2': buscar(conn)
        elif op == '3': agregar(conn)
        elif op == '4': editar(conn)
        elif op == '5': eliminar(conn)
        elif op == '0': break
