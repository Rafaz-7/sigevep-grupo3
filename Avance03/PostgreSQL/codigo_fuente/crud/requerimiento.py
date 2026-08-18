# -*- coding: utf-8 -*-
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from helpers import *

def listar(supabase):
    titulo_seccion("Listado de Requerimientos")
    try:
        response = supabase.table("requerimiento").select("id_requerimiento, id_evento, id_rol, cantidad_requerida, evento(nombre_evento), rol(nombre_rol)").execute()
        datos = response.data
        if not datos:
            console.print("[yellow]No hay requerimientos registrados.[/yellow]")
            return

        for d in datos:
            d['evento_nombre'] = d.get('evento', {}).get('nombre_evento', 'N/A') if d.get('evento') else 'N/A'
            d['rol_nombre'] = d.get('rol', {}).get('nombre_rol', 'N/A') if d.get('rol') else 'N/A'

        columnas = [
            ("ID", "id_requerimiento", 5, "cyan"),
            ("Evento", "evento_nombre", 20, "magenta"),
            ("Rol", "rol_nombre", 20, "green"),
            ("Cantidad", "cantidad_requerida", 10, "yellow")
        ]
        mostrar_tabla(datos, columnas, "Requerimientos Registrados", "cyan")
    except Exception as e:
        console.print(f"[red]Error al listar: {e}[/red]")

def agregar(supabase):
    titulo_seccion("Agregar Requerimiento")
    try:
        id_evento = seleccionar_fk(supabase, "evento", "id_evento", "nombre_evento", "Seleccione el Evento")
        if not id_evento: return
        id_rol = seleccionar_fk(supabase, "rol", "id_rol", "nombre_rol", "Seleccione el Rol")
        if not id_rol: return
        
        cantidad = pedir("Cantidad requerida: ", tipo="int")
        
        supabase.rpc('sp_insertar_requerimiento', {'p_id_evento': id_evento, 'p_id_rol': id_rol, 'p_cantidad': cantidad}).execute()
        console.print("[green]Requerimiento agregado exitosamente (Operación ejecutada via SP).[/green]")
    except Exception as e:
        console.print(f"[red]Error al agregar: {e}[/red]")

def buscar(supabase):
    titulo_seccion("Buscar Requerimiento")
    id_req = pedir("ID del requerimiento a buscar: ", tipo="int")
    try:
        response = supabase.table("requerimiento").select("id_requerimiento, cantidad_requerida, evento(nombre_evento), rol(nombre_rol)").eq("id_requerimiento", id_req).execute()
        if response.data:
            d = response.data[0]
            evento_nom = d.get('evento', {}).get('nombre_evento', 'N/A') if d.get('evento') else 'N/A'
            rol_nom = d.get('rol', {}).get('nombre_rol', 'N/A') if d.get('rol') else 'N/A'
            console.print(f"\n[cyan]ID:[/cyan] {d['id_requerimiento']}")
            console.print(f"[cyan]Evento:[/cyan] {evento_nom}")
            console.print(f"[cyan]Rol:[/cyan] {rol_nom}")
            console.print(f"[cyan]Cantidad requerida:[/cyan] {d['cantidad_requerida']}")
        else:
            console.print("[yellow]Requerimiento no encontrado.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al buscar: {e}[/red]")

def editar(supabase):
    titulo_seccion("Editar Requerimiento")
    id_req = pedir("ID del requerimiento a editar: ", tipo="int")
    try:
        response = supabase.table("requerimiento").select("*").eq("id_requerimiento", id_req).execute()
        if not response.data:
            console.print("[yellow]Requerimiento no encontrado.[/yellow]")
            return
        
        actual = response.data[0]
        
        nueva_cantidad = pedir_edicion("Cantidad requerida", actual['cantidad_requerida'], tipo="int")
        
        supabase.rpc('sp_actualizar_requerimiento', {'p_id': id_req, 'p_cantidad': nueva_cantidad}).execute()
        console.print("[green]Requerimiento actualizado exitosamente (Operación ejecutada via SP).[/green]")
    except Exception as e:
        console.print(f"[red]Error al editar: {e}[/red]")

def eliminar(supabase):
    titulo_seccion("Eliminar Requerimiento")
    id_req = pedir("ID del requerimiento a eliminar: ", tipo="int")
    try:
        if confirmar("¿Está seguro de eliminar este requerimiento?"):
            supabase.rpc('sp_eliminar_requerimiento', {'p_id': id_req}).execute()
            console.print("[green]Requerimiento eliminado (Operación ejecutada via SP).[/green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al eliminar: {e}[/red]")

def menu(supabase):
    while True:
        op = menu_crud("Requerimiento")
        if op == '1': listar(supabase)
        elif op == '2': buscar(supabase)
        elif op == '3': agregar(supabase)
        elif op == '4': editar(supabase)
        elif op == '5': eliminar(supabase)
        elif op == '0': break
