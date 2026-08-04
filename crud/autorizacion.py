# -*- coding: utf-8 -*-
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from helpers import *
from datetime import date

def get_voluntario_nombre(d):
    v = d.get('voluntario')
    if v:
        return f"{v.get('nombres', '')} {v.get('apellidos', '')}".strip()
    return "N/A"

def listar(supabase):
    titulo_seccion("Listado de Autorizaciones")
    try:
        response = supabase.table("autorizacion").select("id_voluntario, id_rol, id_usuario_autorizador, fecha_autorizacion, voluntario(nombres, apellidos), rol(nombre_rol), usuario(nombre_usuario)").execute()
        datos = response.data
        if not datos:
            console.print("[yellow]No hay autorizaciones registradas.[/yellow]")
            return

        for d in datos:
            d['voluntario_nombre'] = get_voluntario_nombre(d)
            d['rol_nombre'] = d.get('rol', {}).get('nombre_rol', 'N/A') if d.get('rol') else 'N/A'
            d['autorizador'] = d.get('usuario', {}).get('nombre_usuario', 'N/A') if d.get('usuario') else 'N/A'

        columnas = [
            ("Voluntario", "voluntario_nombre", 25, "cyan"),
            ("Rol", "rol_nombre", 20, "magenta"),
            ("Autorizador", "autorizador", 15, "green"),
            ("Fecha", "fecha_autorizacion", 12, "yellow")
        ]
        mostrar_tabla(datos, columnas, "Autorizaciones", "cyan")
    except Exception as e:
        console.print(f"[red]Error al listar: {e}[/red]")

def agregar(supabase):
    titulo_seccion("Agregar Autorización")
    try:
        id_voluntario = pedir("ID Voluntario: ", tipo="int")
        id_rol = seleccionar_fk(supabase, "rol", "id_rol", "nombre_rol", "Seleccione el Rol")
        if not id_rol: return
        id_usuario = seleccionar_fk(supabase, "usuario", "id_usuario", "nombre_usuario", "Seleccione el Usuario Autorizador")
        if not id_usuario: return
        
        nuevo = {
            "id_voluntario": id_voluntario,
            "id_rol": id_rol,
            "id_usuario_autorizador": id_usuario,
            "fecha_autorizacion": str(date.today())
        }
        supabase.table("autorizacion").insert(nuevo).execute()
        console.print("[green]Autorización agregada exitosamente.[/green]")
    except Exception as e:
        console.print(f"[red]Error al agregar: {e}[/red]")

def buscar(supabase):
    titulo_seccion("Buscar Autorización")
    id_vol = pedir("ID del voluntario: ", tipo="int")
    id_rol = pedir("ID del rol: ", tipo="int")
    try:
        response = supabase.table("autorizacion").select("*, voluntario(nombres, apellidos), rol(nombre_rol), usuario(nombre_usuario)").eq("id_voluntario", id_vol).eq("id_rol", id_rol).execute()
        if response.data:
            d = response.data[0]
            vol_nom = get_voluntario_nombre(d)
            rol_nom = d.get('rol', {}).get('nombre_rol', 'N/A') if d.get('rol') else 'N/A'
            usr_nom = d.get('usuario', {}).get('nombre_usuario', 'N/A') if d.get('usuario') else 'N/A'
            
            console.print(f"\n[cyan]Voluntario:[/cyan] {vol_nom} (ID: {d['id_voluntario']})")
            console.print(f"[cyan]Rol:[/cyan] {rol_nom} (ID: {d['id_rol']})")
            console.print(f"[cyan]Autorizado por:[/cyan] {usr_nom}")
            console.print(f"[cyan]Fecha:[/cyan] {d['fecha_autorizacion']}")
        else:
            console.print("[yellow]Autorización no encontrada.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al buscar: {e}[/red]")

def editar(supabase):
    titulo_seccion("Editar Autorización")
    console.print("Busque la autorización a editar:")
    id_vol = pedir("ID del voluntario: ", tipo="int")
    id_rol = pedir("ID del rol: ", tipo="int")
    try:
        response = supabase.table("autorizacion").select("*").eq("id_voluntario", id_vol).eq("id_rol", id_rol).execute()
        if not response.data:
            console.print("[yellow]Autorización no encontrada.[/yellow]")
            return
        
        actual = response.data[0]
        nuevo_id_usuario = pedir_edicion("ID del usuario autorizador", actual.get('id_usuario_autorizador', ''), tipo="int")
        nueva_fecha = pedir_edicion("Fecha de autorización (YYYY-MM-DD)", actual.get('fecha_autorizacion', ''), tipo="str")
        
        updates = {
            "id_usuario_autorizador": nuevo_id_usuario,
            "fecha_autorizacion": nueva_fecha
        }
        
        supabase.table("autorizacion").update(updates).eq("id_voluntario", id_vol).eq("id_rol", id_rol).execute()
        console.print("[green]Autorización actualizada exitosamente.[/green]")
    except Exception as e:
        console.print(f"[red]Error al editar: {e}[/red]")

def eliminar(supabase):
    titulo_seccion("Eliminar Autorización")
    id_vol = pedir("ID del voluntario: ", tipo="int")
    id_rol = pedir("ID del rol: ", tipo="int")
    try:
        if confirmar("¿Está seguro de eliminar esta autorización?"):
            supabase.table("autorizacion").delete().eq("id_voluntario", id_vol).eq("id_rol", id_rol).execute()
            console.print("[green]Autorización eliminada.[/green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al eliminar: {e}[/red]")

def menu(supabase):
    while True:
        op = menu_crud("Autorización")
        if op == '1': listar(supabase)
        elif op == '2': buscar(supabase)
        elif op == '3': agregar(supabase)
        elif op == '4': editar(supabase)
        elif op == '5': eliminar(supabase)
        elif op == '0': break
