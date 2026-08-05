# -*- coding: utf-8 -*-
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from helpers import *

def get_voluntario_nombre(d):
    v = d.get('voluntario')
    if v:
        return f"{v.get('nombres', '')} {v.get('apellidos', '')}".strip()
    return "N/A"

def listar(supabase):
    titulo_seccion("Listado de Asignaciones")
    try:
        query = "id_asignacion, hora_inicio, hora_fin, estado_asignacion, voluntario(nombres, apellidos), requerimiento(evento(nombre_evento), rol(nombre_rol)), usuario:id_usuario_aprobador(nombre_usuario)"
        
        response = supabase.table("asignacion").select(query).execute()
        datos = response.data
        if not datos:
            console.print("[yellow]No hay asignaciones registradas.[/yellow]")
            return

        for d in datos:
            d['voluntario_nombre'] = get_voluntario_nombre(d)
            req = d.get('requerimiento', {})
            evento = req.get('evento', {}) if req else {}
            rol = req.get('rol', {}) if req else {}
            
            d['evento'] = evento.get('nombre_evento', 'N/A')
            d['rol'] = rol.get('nombre_rol', 'N/A')
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

def agregar(supabase):
    titulo_seccion("Agregar Asignación")
    try:
        id_voluntario = pedir("ID Voluntario: ", tipo="int")
        id_requerimiento = pedir("ID Requerimiento: ", tipo="int")
        id_aprobador = pedir("ID Usuario Aprobador: ", tipo="int")
        hora_inicio = pedir("Hora inicio (HH:MM): ")
        hora_fin = pedir("Hora fin (HH:MM): ")
        estado = pedir("Estado (Programada/Completada/Ausente/Cancelada): ", opciones=['Programada', 'Completada', 'Ausente', 'Cancelada'])
        
        nuevo = {
            "id_voluntario": id_voluntario,
            "id_requerimiento": id_requerimiento,
            "id_usuario_aprobador": id_aprobador,
            "hora_inicio": hora_inicio,
            "hora_fin": hora_fin,
            "estado_asignacion": estado
        }
        supabase.table("asignacion").insert(nuevo).execute()
        console.print("[green]Asignación agregada exitosamente.[/green]")
    except Exception as e:
        console.print(f"[red]Error al agregar: {e}[/red]")

def buscar(supabase):
    titulo_seccion("Buscar Asignación")
    id_asig = pedir("ID de la asignación: ", tipo="int")
    try:
        query = "*, voluntario(nombres, apellidos), requerimiento(evento(nombre_evento), rol(nombre_rol)), usuario:id_usuario_aprobador(nombre_usuario)"
        response = supabase.table("asignacion").select(query).eq("id_asignacion", id_asig).execute()
        if response.data:
            d = response.data[0]
            vol_nom = get_voluntario_nombre(d)
            req = d.get('requerimiento', {})
            evento = req.get('evento', {}) if req else {}
            rol = req.get('rol', {}) if req else {}
            
            console.print(f"\n[cyan]ID:[/cyan] {d['id_asignacion']}")
            console.print(f"[cyan]Voluntario:[/cyan] {vol_nom}")
            console.print(f"[cyan]Evento:[/cyan] {evento.get('nombre_evento', 'N/A')}")
            console.print(f"[cyan]Rol:[/cyan] {rol.get('nombre_rol', 'N/A')}")
            console.print(f"[cyan]Horario:[/cyan] {d.get('hora_inicio')} a {d.get('hora_fin')}")
            console.print(f"[cyan]Estado:[/cyan] {d.get('estado_asignacion')}")
            if d.get('justificacion_cancelacion'):
                console.print(f"[cyan]Justificación Cancelación:[/cyan] {d.get('justificacion_cancelacion')}")
        else:
            console.print("[yellow]Asignación no encontrada.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al buscar: {e}[/red]")

def editar(supabase):
    titulo_seccion("Editar Asignación")
    id_asig = pedir("ID de la asignación a editar: ", tipo="int")
    try:
        response = supabase.table("asignacion").select("*").eq("id_asignacion", id_asig).execute()
        if not response.data:
            console.print("[yellow]Asignación no encontrada.[/yellow]")
            return
        
        actual = response.data[0]
        
        n_inicio = pedir_edicion("Hora inicio", actual.get('hora_inicio', ''))
        n_fin = pedir_edicion("Hora fin", actual.get('hora_fin', ''))
        n_estado = pedir_edicion("Estado", actual.get('estado_asignacion', ''), opciones=['Programada', 'Completada', 'Ausente', 'Cancelada'])
        
        updates = {
            "hora_inicio": n_inicio,
            "hora_fin": n_fin,
            "estado_asignacion": n_estado
        }
        
        if n_estado == 'Cancelada':
            n_just = pedir_edicion("Justificación cancelación", actual.get('justificacion_cancelacion', ''))
            n_fecha = pedir_edicion("Fecha cancelación (YYYY-MM-DD)", actual.get('fecha_cancelacion', ''))
            updates['justificacion_cancelacion'] = n_just
            updates['fecha_cancelacion'] = n_fecha
            
        supabase.table("asignacion").update(updates).eq("id_asignacion", id_asig).execute()
        console.print("[green]Asignación actualizada exitosamente.[/green]")
    except Exception as e:
        console.print(f"[red]Error al editar: {e}[/red]")

def eliminar(supabase):
    titulo_seccion("Eliminar Asignación")
    id_asig = pedir("ID de la asignación a eliminar: ", tipo="int")
    try:
        if confirmar("¿Está seguro de eliminar esta asignación?"):
            supabase.table("asignacion").delete().eq("id_asignacion", id_asig).execute()
            console.print("[green]Asignación eliminada.[/green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al eliminar: {e}[/red]")

def menu(supabase):
    while True:
        op = menu_crud("Asignación")
        if op == '1': listar(supabase)
        elif op == '2': buscar(supabase)
        elif op == '3': agregar(supabase)
        elif op == '4': editar(supabase)
        elif op == '5': eliminar(supabase)
        elif op == '0': break
