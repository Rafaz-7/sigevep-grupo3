# -*- coding: utf-8 -*-
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from helpers import *

def listar(supabase):
    titulo_seccion("Lista de Categorías de Eventos")
    try:
        respuesta = supabase.table("categoria_evento").select("*").execute()
        datos = respuesta.data
        if not datos:
            console.print("[yellow]No hay categorías registradas.[/yellow]")
            return

        columnas = [
            ("ID", "id_categoria"),
            ("Nombre", "nombre_categoria"),
            ("Descripción", "descripcion_categoria")
        ]
        mostrar_tabla(datos, columnas, "Categorías de Eventos", "magenta")
    except Exception as e:
        console.print(f"[bold red]Error al listar categorías:[/bold red] {e}")

def buscar(supabase):
    titulo_seccion("Buscar Categoría de Evento")
    try:
        id_val = pedir("Ingrese el ID", tipo="int")
        respuesta = supabase.table("categoria_evento").select("*").eq("id_categoria", id_val).execute()
        if not respuesta.data:
            console.print("[yellow]No se encontró el registro.[/yellow]")
            return
        columnas = [
            ("ID", "id_categoria"),
            ("Nombre", "nombre_categoria"),
            ("Descripción", "descripcion_categoria")
        ]
        mostrar_tabla(respuesta.data, columnas, "Resultado", "magenta")
    except Exception as e:
        console.print(f"[bold red]Error:[/bold red] {e}")

def crear(supabase):
    titulo_seccion("Crear Categoría de Evento")
    try:
        nombre = pedir("Nombre de la categoría")
        descripcion = pedir("Descripción de la categoría", obligatorio=False)

        respuesta = supabase.rpc('sp_insertar_categoria_evento', {'p_nombre': nombre, 'p_descripcion': descripcion}).execute()
        console.print("[bold green]Categoría creada exitosamente (Operación ejecutada via SP).[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al crear la categoría:[/bold red] {e}")

def editar(supabase):
    titulo_seccion("Editar Categoría de Evento")
    listar(supabase)
    try:
        id_categoria = pedir("Ingrese el ID de la categoría a editar", tipo="int")
        respuesta = supabase.table("categoria_evento").select("*").eq("id_categoria", id_categoria).execute()
        if not respuesta.data:
            console.print("[bold red]Categoría no encontrada.[/bold red]")
            return

        cat_actual = respuesta.data[0]

        nombre_nuevo = pedir_edicion("Nombre", cat_actual["nombre_categoria"])
        desc_nueva = pedir_edicion("Descripción", cat_actual.get("descripcion_categoria", ""))

        respuesta_update = supabase.rpc('sp_actualizar_categoria_evento', {'p_id': id_categoria, 'p_nombre': nombre_nuevo, 'p_descripcion': desc_nueva}).execute()
        console.print("[bold green]Categoría actualizada exitosamente (Operación ejecutada via SP).[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al actualizar la categoría:[/bold red] {e}")

def eliminar(supabase):
    titulo_seccion("Eliminar Categoría de Evento")
    listar(supabase)
    try:
        id_categoria = pedir("Ingrese el ID de la categoría a eliminar", tipo="int")
        respuesta = supabase.table("categoria_evento").select("*").eq("id_categoria", id_categoria).execute()
        if not respuesta.data:
            console.print("[bold red]Categoría no encontrada.[/bold red]")
            return

        cat = respuesta.data[0]
        if confirmar(f"¿Está seguro que desea eliminar la categoría '{cat['nombre_categoria']}'?"):
            res_delete = supabase.rpc('sp_eliminar_categoria_evento', {'p_id': id_categoria}).execute()
            console.print("[bold green]Categoría eliminada exitosamente (Operación ejecutada via SP).[/bold green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[bold red]Error al eliminar la categoría:[/bold red] {e}")

def menu(supabase):
    while True:
        opcion = menu_crud("Categorías de Eventos")
        
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
