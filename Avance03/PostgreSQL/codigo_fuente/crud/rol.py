# -*- coding: utf-8 -*-
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from helpers import *

def listar(supabase):
    titulo_seccion("Lista de Roles")
    try:
        respuesta = supabase.table("rol").select("*").execute()
        datos = respuesta.data
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

def buscar(supabase):
    titulo_seccion("Buscar Rol")
    try:
        id_val = pedir("Ingrese el ID", tipo="int")
        respuesta = supabase.table("rol").select("*").eq("id_rol", id_val).execute()
        if not respuesta.data:
            console.print("[yellow]No se encontró el registro.[/yellow]")
            return
        columnas = [
            ("ID", "id_rol"),
            ("Nombre", "nombre_rol"),
            ("Descripción", "descripcion_rol"),
            ("Requiere EPP", "requiere_epp"),
            ("Demanda Física", "nivel_demanda_fisica")
        ]
        mostrar_tabla(respuesta.data, columnas, "Resultado", "blue")
    except Exception as e:
        console.print(f"[bold red]Error:[/bold red] {e}")

def crear(supabase):
    titulo_seccion("Crear Rol")
    try:
        nombre = pedir("Nombre del rol")
        descripcion = pedir("Descripción del rol")
        requiere_epp = pedir("¿Requiere EPP (Equipo de Protección Personal)?", tipo="bool")
        demanda = pedir("Nivel de demanda física", opciones=['Alto', 'Medio', 'Bajo'])

        respuesta = supabase.rpc('sp_insertar_rol', {'p_nombre': nombre, 'p_descripcion': descripcion, 'p_requiere_epp': requiere_epp, 'p_nivel_fisico': demanda}).execute()
        console.print("[bold green]Rol creado exitosamente (Operación ejecutada via SP).[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al crear el rol:[/bold red] {e}")

def editar(supabase):
    titulo_seccion("Editar Rol")
    listar(supabase)
    try:
        id_rol = pedir("Ingrese el ID del rol a editar", tipo="int")
        respuesta = supabase.table("rol").select("*").eq("id_rol", id_rol).execute()
        if not respuesta.data:
            console.print("[bold red]Rol no encontrado.[/bold red]")
            return

        rol_actual = respuesta.data[0]

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

        respuesta_update = supabase.rpc('sp_actualizar_rol', {'p_id': id_rol, 'p_nombre': nombre_nuevo, 'p_descripcion': desc_nueva, 'p_requiere_epp': req_epp_nuevo, 'p_nivel_fisico': demanda_nueva}).execute()
        console.print("[bold green]Rol actualizado exitosamente (Operación ejecutada via SP).[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al actualizar el rol:[/bold red] {e}")

def eliminar(supabase):
    titulo_seccion("Eliminar Rol")
    listar(supabase)
    try:
        id_rol = pedir("Ingrese el ID del rol a eliminar", tipo="int")
        respuesta = supabase.table("rol").select("*").eq("id_rol", id_rol).execute()
        if not respuesta.data:
            console.print("[bold red]Rol no encontrado.[/bold red]")
            return

        rol = respuesta.data[0]
        if confirmar(f"¿Está seguro que desea eliminar el rol '{rol['nombre_rol']}'?"):
            res_delete = supabase.rpc('sp_eliminar_rol', {'p_id': id_rol}).execute()
            console.print("[bold green]Rol eliminado exitosamente (Operación ejecutada via SP).[/bold green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[bold red]Error al eliminar el rol:[/bold red] {e}")

def menu(supabase):
    while True:
        opcion = menu_crud("Roles")
        
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
