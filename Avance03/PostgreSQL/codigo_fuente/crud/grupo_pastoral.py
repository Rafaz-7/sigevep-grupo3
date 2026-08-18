# -*- coding: utf-8 -*-
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from helpers import *

def listar(supabase):
    titulo_seccion("Lista de Grupos Pastorales")
    try:
        respuesta = supabase.table("grupo_pastoral").select("*").execute()
        datos = respuesta.data
        if not datos:
            console.print("[yellow]No hay grupos pastorales registrados.[/yellow]")
            return

        columnas = [
            ("ID", "id_grupo"),
            ("Nombre", "nombre_grupo"),
            ("Descripción", "descripcion_grupo")
        ]
        mostrar_tabla(datos, columnas, "Grupos Pastorales", "cyan")
    except Exception as e:
        console.print(f"[bold red]Error al listar grupos pastorales:[/bold red] {e}")

def buscar(supabase):
    titulo_seccion("Buscar Grupo Pastoral")
    try:
        id_val = pedir("Ingrese el ID", tipo="int")
        respuesta = supabase.table("grupo_pastoral").select("*").eq("id_grupo", id_val).execute()
        if not respuesta.data:
            console.print("[yellow]No se encontró el registro.[/yellow]")
            return
        columnas = [
            ("ID", "id_grupo"),
            ("Nombre", "nombre_grupo"),
            ("Descripción", "descripcion_grupo")
        ]
        mostrar_tabla(respuesta.data, columnas, "Resultado", "cyan")
    except Exception as e:
        console.print(f"[bold red]Error:[/bold red] {e}")

def crear(supabase):
    titulo_seccion("Crear Grupo Pastoral")
    try:
        nombre = pedir("Nombre del grupo")
        descripcion = pedir("Descripción del grupo", obligatorio=False)

        respuesta = supabase.rpc('sp_insertar_grupo_pastoral', {'p_nombre': nombre, 'p_descripcion': descripcion}).execute()
        console.print("[bold green]Grupo pastoral creado exitosamente (Operación ejecutada via SP).[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al crear el grupo pastoral:[/bold red] {e}")

def editar(supabase):
    titulo_seccion("Editar Grupo Pastoral")
    listar(supabase)
    try:
        id_grupo = pedir("Ingrese el ID del grupo a editar", tipo="int")
        respuesta = supabase.table("grupo_pastoral").select("*").eq("id_grupo", id_grupo).execute()
        if not respuesta.data:
            console.print("[bold red]Grupo pastoral no encontrado.[/bold red]")
            return

        grupo_actual = respuesta.data[0]

        nombre_nuevo = pedir_edicion("Nombre", grupo_actual["nombre_grupo"])
        desc_nueva = pedir_edicion("Descripción", grupo_actual.get("descripcion_grupo", ""))

        respuesta_update = supabase.rpc('sp_actualizar_grupo_pastoral', {'p_id': id_grupo, 'p_nombre': nombre_nuevo, 'p_descripcion': desc_nueva}).execute()
        console.print("[bold green]Grupo pastoral actualizado exitosamente (Operación ejecutada via SP).[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al actualizar el grupo pastoral:[/bold red] {e}")

def eliminar(supabase):
    titulo_seccion("Eliminar Grupo Pastoral")
    listar(supabase)
    try:
        id_grupo = pedir("Ingrese el ID del grupo a eliminar", tipo="int")
        respuesta = supabase.table("grupo_pastoral").select("*").eq("id_grupo", id_grupo).execute()
        if not respuesta.data:
            console.print("[bold red]Grupo pastoral no encontrado.[/bold red]")
            return

        grupo = respuesta.data[0]
        if confirmar(f"¿Está seguro que desea eliminar el grupo '{grupo['nombre_grupo']}'?"):
            res_delete = supabase.rpc('sp_eliminar_grupo_pastoral', {'p_id': id_grupo}).execute()
            console.print("[bold green]Grupo pastoral eliminado exitosamente (Operación ejecutada via SP).[/bold green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[bold red]Error al eliminar el grupo pastoral:[/bold red] {e}")

def menu(supabase):
    while True:
        opcion = menu_crud("Grupos Pastorales")
        
        if opcion == "1":
            listar(supabase)
        elif opcion == "2":
            buscar(supabase)
        elif opcion == "3":
            crear(supabase)
        elif opcion == "4":
            editar(supabase)
        elif opcion == "5":
            eliminar(supabase)
        elif opcion == "0":
            break
        else:
            console.print("[bold red]Opción no válida.[/bold red]")
