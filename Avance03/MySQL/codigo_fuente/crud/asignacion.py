# -*- coding: utf-8 -*-
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from helpers import *

def listar(conn):
    titulo_seccion("Listado de Asignaciones")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT a.id_asignacion, a.hora_inicio, a.hora_fin, a.estado_asignacion,
                   v.nombres as v_nombres, v.apellidos as v_apellidos,
                   e.nombre_evento, r.nombre_rol, u.nombre_usuario
            FROM asignacion a
            LEFT JOIN voluntario v ON a.id_voluntario = v.id_voluntario
            LEFT JOIN requerimiento req ON a.id_requerimiento = req.id_requerimiento
            LEFT JOIN evento e ON req.id_evento = e.id_evento
            LEFT JOIN rol r ON req.id_rol = r.id_rol
            LEFT JOIN usuario u ON a.id_usuario_aprobador = u.id_usuario
        ''')
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]No hay asignaciones registradas.[/yellow]")
            return

        for d in datos:
            d['voluntario_nombre'] = f"{d.get('v_nombres', '')} {d.get('v_apellidos', '')}".strip()
            d['evento'] = d.get('nombre_evento', 'N/A')
            d['rol'] = d.get('nombre_rol', 'N/A')
            d['horario'] = f"{d.get('hora_inicio', '')} - {d.get('hora_fin', '')}"
            
        columnas = [
            ("ID", "id_asignacion", 5, "cyan"),
            ("Voluntario", "voluntario_nombre", 20, "magenta"),
            ("Evento", "evento", 15, "green"),
            ("Rol", "rol", 15, "yellow"),
            ("Horario", "horario", 15, "blue"),
            ("Estado", "estado_asignacion", 12, "white")
        ]
        mostrar_tabla(datos, columnas, "Asignaciones", "cyan")
    except Exception as e:
        console.print(f"[red]Error al listar: {e}[/red]")

def agregar(conn):
    titulo_seccion("Agregar Asignación")
    try:
        id_voluntario = pedir("ID Voluntario: ", tipo="int")
        id_requerimiento = pedir("ID Requerimiento: ", tipo="int")
        id_aprobador = pedir("ID Usuario Aprobador: ", tipo="int")
        hora_inicio = pedir("Hora inicio (HH:MM): ")
        hora_fin = pedir("Hora fin (HH:MM): ")
        estado = pedir("Estado (Programada/Completada/Ausente/Cancelada): ", opciones=['Programada', 'Completada', 'Ausente', 'Cancelada'])
        
        cursor = conn.cursor()
        cursor.callproc('sp_insertar_asignacion', (id_voluntario, id_requerimiento, id_aprobador, hora_inicio, hora_fin, estado))
        conn.commit()
        cursor.close()
        
        console.print("[green]Asignación agregada exitosamente.[/green]")
    except Exception as e:
        console.print(f"[red]Error al agregar: {e}[/red]")

def buscar(conn):
    titulo_seccion("Buscar Asignación")
    id_asig = pedir("ID de la asignación: ", tipo="int")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT a.*,
                   v.nombres as v_nombres, v.apellidos as v_apellidos,
                   e.nombre_evento, r.nombre_rol, u.nombre_usuario
            FROM asignacion a
            LEFT JOIN voluntario v ON a.id_voluntario = v.id_voluntario
            LEFT JOIN requerimiento req ON a.id_requerimiento = req.id_requerimiento
            LEFT JOIN evento e ON req.id_evento = e.id_evento
            LEFT JOIN rol r ON req.id_rol = r.id_rol
            LEFT JOIN usuario u ON a.id_usuario_aprobador = u.id_usuario
            WHERE a.id_asignacion = %s
        ''', (id_asig,))
        datos = cursor.fetchall()
        cursor.close()
        
        if datos:
            d = datos[0]
            vol_nom = f"{d.get('v_nombres', '')} {d.get('v_apellidos', '')}".strip()
            
            console.print(f"\n[cyan]ID:[/cyan] {d['id_asignacion']}")
            console.print(f"[cyan]Voluntario:[/cyan] {vol_nom}")
            console.print(f"[cyan]Evento:[/cyan] {d.get('nombre_evento', 'N/A')}")
            console.print(f"[cyan]Rol:[/cyan] {d.get('nombre_rol', 'N/A')}")
            console.print(f"[cyan]Horario:[/cyan] {d.get('hora_inicio')} a {d.get('hora_fin')}")
            console.print(f"[cyan]Estado:[/cyan] {d.get('estado_asignacion')}")
            if d.get('justificacion_cancelacion'):
                console.print(f"[cyan]Justificación Cancelación:[/cyan] {d.get('justificacion_cancelacion')}")
        else:
            console.print("[yellow]Asignación no encontrada.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al buscar: {e}[/red]")

def editar(conn):
    titulo_seccion("Editar Asignación")
    id_asig = pedir("ID de la asignación a editar: ", tipo="int")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM asignacion WHERE id_asignacion = %s", (id_asig,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]Asignación no encontrada.[/yellow]")
            return
        
        actual = datos[0]
        
        n_inicio = pedir_edicion("Hora inicio", actual.get('hora_inicio', ''))
        n_fin = pedir_edicion("Hora fin", actual.get('hora_fin', ''))
        n_estado = pedir_edicion("Estado", actual.get('estado_asignacion', ''), opciones=['Programada', 'Completada', 'Ausente', 'Cancelada'])
        
        n_just = actual.get('justificacion_cancelacion', '')
        n_fecha = actual.get('fecha_cancelacion', None)
        
        if n_estado == 'Cancelada':
            n_just = pedir_edicion("Justificación cancelación", n_just)
            n_fecha = pedir_edicion("Fecha cancelación (YYYY-MM-DD)", str(n_fecha) if n_fecha else '')
            
        cursor = conn.cursor()
        cursor.callproc('sp_actualizar_asignacion', (id_asig, n_inicio, n_fin, n_estado, n_just or '', n_fecha or None))
        conn.commit()
        cursor.close()
        
        console.print("[green]Asignación actualizada exitosamente.[/green]")
    except Exception as e:
        console.print(f"[red]Error al editar: {e}[/red]")

def eliminar(conn):
    titulo_seccion("Eliminar Asignación")
    id_asig = pedir("ID de la asignación a eliminar: ", tipo="int")
    try:
        if confirmar("¿Está seguro de eliminar esta asignación?"):
            cursor = conn.cursor()
            cursor.callproc('sp_eliminar_asignacion', (id_asig,))
            conn.commit()
            cursor.close()
            console.print("[green]Asignación eliminada.[/green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al eliminar: {e}[/red]")

def menu(conn):
    while True:
        op = menu_crud("Asignación")
        if op == '1': listar(conn)
        elif op == '2': buscar(conn)
        elif op == '3': agregar(conn)
        elif op == '4': editar(conn)
        elif op == '5': eliminar(conn)
        elif op == '0': break
