# -*- coding: utf-8 -*-
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from helpers import *

def crear(supabase):
    titulo_seccion("Crear Evento")
    
    id_grupo = seleccionar_fk(supabase, "grupo_pastoral", "id_grupo", "nombre_grupo", "Seleccione el Grupo Pastoral: ")
    if not id_grupo:
        return
        
    id_categoria = seleccionar_fk(supabase, "categoria_evento", "id_categoria", "nombre_categoria", "Seleccione la Categoría de Evento: ")
    if not id_categoria:
        return

    nombre_evento = pedir("Nombre del Evento: ")
    fecha_programada = pedir("Fecha Programada (YYYY-MM-DD): ")
    ubicacion = pedir("Ubicación: ")
        
    try:
        res = supabase.rpc('sp_insertar_evento', {'p_id_grupo': id_grupo, 'p_id_categoria': id_categoria, 'p_nombre': nombre_evento, 'p_fecha': fecha_programada, 'p_ubicacion': ubicacion}).execute()
        console.print("[bold green]Evento creado exitosamente (Operación ejecutada via SP).[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al crear evento: {e}[/bold red]")

def listar(supabase):
    titulo_seccion("Lista de Eventos")
    try:
        res = supabase.table("evento").select("*, grupo_pastoral(nombre_grupo), categoria_evento(nombre_categoria)").execute()
        datos = res.data
        if not datos:
            console.print("[yellow]No hay eventos registrados.[/yellow]")
            return
            
        for d in datos:
            d["nombre_grupo"] = d.get("grupo_pastoral", {}).get("nombre_grupo", "N/A") if d.get("grupo_pastoral") else "N/A"
            d["nombre_categoria"] = d.get("categoria_evento", {}).get("nombre_categoria", "N/A") if d.get("categoria_evento") else "N/A"
                
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

def buscar(supabase):
    titulo_seccion("Buscar Evento")
    try:
        id_val = pedir("Ingrese el ID", tipo="int")
        res = supabase.table("evento").select("*, grupo_pastoral(nombre_grupo), categoria_evento(nombre_categoria)").eq("id_evento", id_val).execute()
        if not res.data:
            console.print("[yellow]No se encontró el registro.[/yellow]")
            return
            
        datos = res.data
        for d in datos:
            d["nombre_grupo"] = d.get("grupo_pastoral", {}).get("nombre_grupo", "N/A") if d.get("grupo_pastoral") else "N/A"
            d["nombre_categoria"] = d.get("categoria_evento", {}).get("nombre_categoria", "N/A") if d.get("categoria_evento") else "N/A"
                
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

def actualizar(supabase):
    titulo_seccion("Actualizar Evento")
    id_evento = pedir("ID del evento a actualizar: ", tipo="int")
    
    try:
        res = supabase.table("evento").select("*").eq("id_evento", id_evento).execute()
        if not res.data:
            console.print("[yellow]Evento no encontrado.[/yellow]")
            return
            
        actual = res.data[0]
        
        id_grupo_str = pedir_edicion("ID Grupo", str(actual.get("id_grupo")))
        id_categoria_str = pedir_edicion("ID Categoría", str(actual.get("id_categoria")))
        nombre_evento = pedir_edicion("Nombre", actual.get("nombre_evento"))
        fecha_programada = pedir_edicion("Fecha Programada", actual.get("fecha_programada"))
        ubicacion = pedir_edicion("Ubicación", actual.get("ubicacion"))
        
        res = supabase.rpc('sp_actualizar_evento', {'p_id': id_evento, 'p_id_grupo': int(id_grupo_str) if id_grupo_str.isdigit() else actual.get("id_grupo"), 'p_id_categoria': int(id_categoria_str) if id_categoria_str.isdigit() else actual.get("id_categoria"), 'p_nombre': nombre_evento, 'p_fecha': fecha_programada, 'p_ubicacion': ubicacion}).execute()
        console.print("[bold green]Evento actualizado exitosamente (Operación ejecutada via SP).[/bold green]")
        
    except Exception as e:
        console.print(f"[bold red]Error al actualizar evento: {e}[/bold red]")

def eliminar(supabase):
    titulo_seccion("Eliminar Evento")
    id_evento = pedir("ID del evento a eliminar: ", tipo="int")
    
    if confirmar(f"¿Está seguro de eliminar el evento {id_evento}?"):
        try:
            supabase.rpc('sp_eliminar_evento', {'p_id': id_evento}).execute()
            console.print("[bold green]Evento eliminado exitosamente (Operación ejecutada via SP).[/bold green]")
        except Exception as e:
            console.print(f"[bold red]Error al eliminar evento: {e}[/bold red]")

def menu(supabase):
    while True:
        opc = menu_crud("Evento")
        if opc == "1":
            listar(supabase)
        elif opc == "2":
            buscar(supabase)
        elif opc == "3":
            crear(supabase)
        elif opc == "4":
            actualizar(supabase)
        elif opc == "5":
            eliminar(supabase)
        elif opc == "0":
            break
