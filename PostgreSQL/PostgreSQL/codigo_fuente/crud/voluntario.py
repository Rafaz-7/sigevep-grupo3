# -*- coding: utf-8 -*-
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from helpers import *

def crear(supabase):
    titulo_seccion("Crear Voluntario")
    
    id_grupo = seleccionar_fk(supabase, "grupo_pastoral", "id_grupo", "nombre_grupo", "Seleccione el Grupo Pastoral: ")
    if not id_grupo:
        return

    nombres = pedir("Nombres: ")
    apellidos = pedir("Apellidos: ")
    telefono = pedir("Teléfono: ")
    fecha_nacimiento = pedir("Fecha de nacimiento (YYYY-MM-DD): ")
    
    estado_operativo = pedir("Estado Operativo (Activo/Inactivo/Suspendido) [Activo]: ", obligatorio=False) or "Activo"
    nivel_capacidad_fisica = pedir("Nivel Capacidad Física (Alto/Medio/Bajo): ", opciones=["Alto", "Medio", "Bajo"])
    tipo_limitacion_fisica = pedir("Tipo Limitación Física (Opcional): ", obligatorio=False)
    descripcion_limitacion = pedir("Descripción Limitación Física (Opcional): ", obligatorio=False)
        
    try:
        res = supabase.rpc('sp_insertar_voluntario', {'p_id_grupo': id_grupo, 'p_nombres': nombres, 'p_apellidos': apellidos, 'p_telefono': telefono, 'p_fecha_nac': fecha_nacimiento, 'p_estado': estado_operativo, 'p_nivel_fisico': nivel_capacidad_fisica, 'p_tipo_limit': tipo_limitacion_fisica, 'p_desc_limit': descripcion_limitacion}).execute()
        console.print("[bold green]Voluntario creado exitosamente (Operación ejecutada via SP).[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al crear voluntario: {e}[/bold red]")

def listar(supabase):
    titulo_seccion("Lista de Voluntarios")
    try:
        res = supabase.table("voluntario").select("*, grupo_pastoral(nombre_grupo)").execute()
        datos = res.data
        if not datos:
            console.print("[yellow]No hay voluntarios registrados.[/yellow]")
            return
            
        for d in datos:
            if d.get("grupo_pastoral"):
                d["nombre_grupo"] = d["grupo_pastoral"].get("nombre_grupo", "")
            else:
                d["nombre_grupo"] = "N/A"
                
        columnas = [
            ("ID", "id_voluntario"),
            ("Grupo", "nombre_grupo"),
            ("Nombres", "nombres"),
            ("Apellidos", "apellidos"),
            ("Teléfono", "telefono"),
            ("Estado", "estado_operativo"),
            ("Capacidad", "nivel_capacidad_fisica")
        ]
        mostrar_tabla(datos, columnas, "Voluntarios", "cyan")
    except Exception as e:
        console.print(f"[bold red]Error al listar voluntarios: {e}[/bold red]")

def buscar(supabase):
    titulo_seccion("Buscar Voluntario")
    try:
        id_val = pedir("Ingrese el ID", tipo="int")
        res = supabase.table("voluntario").select("*, grupo_pastoral(nombre_grupo)").eq("id_voluntario", id_val).execute()
        if not res.data:
            console.print("[yellow]No se encontró el registro.[/yellow]")
            return
        
        datos = res.data
        for d in datos:
            if d.get("grupo_pastoral"):
                d["nombre_grupo"] = d["grupo_pastoral"].get("nombre_grupo", "")
            else:
                d["nombre_grupo"] = "N/A"
                
        columnas = [
            ("ID", "id_voluntario"),
            ("Grupo", "nombre_grupo"),
            ("Nombres", "nombres"),
            ("Apellidos", "apellidos"),
            ("Teléfono", "telefono"),
            ("Estado", "estado_operativo"),
            ("Capacidad", "nivel_capacidad_fisica")
        ]
        mostrar_tabla(datos, columnas, "Resultado", "cyan")
    except Exception as e:
        console.print(f"[bold red]Error:[/bold red] {e}")

def actualizar(supabase):
    titulo_seccion("Actualizar Voluntario")
    id_voluntario = pedir("ID del voluntario a actualizar: ", tipo="int")
    
    try:
        res = supabase.table("voluntario").select("*").eq("id_voluntario", id_voluntario).execute()
        if not res.data:
            console.print("[yellow]Voluntario no encontrado.[/yellow]")
            return
            
        actual = res.data[0]
        
        id_grupo_str = pedir_edicion("ID Grupo", str(actual.get("id_grupo")))
        nombres = pedir_edicion("Nombres", actual.get("nombres"))
        apellidos = pedir_edicion("Apellidos", actual.get("apellidos"))
        telefono = pedir_edicion("Teléfono", actual.get("telefono"))
        fecha_nacimiento = pedir_edicion("Fecha Nacimiento", actual.get("fecha_nacimiento"))
        estado_operativo = pedir_edicion("Estado", actual.get("estado_operativo"), opciones=["Activo", "Inactivo", "Suspendido"])
        nivel_capacidad_fisica = pedir_edicion("Capacidad", actual.get("nivel_capacidad_fisica"), opciones=["Alto", "Medio", "Bajo"])
        tipo_limitacion_fisica = pedir_edicion("Tipo Limitación", actual.get("tipo_limitacion_fisica") or "")
        descripcion_limitacion = pedir_edicion("Descripción Limitación", actual.get("descripcion_limitacion") or "")
        
        res = supabase.rpc('sp_actualizar_voluntario', {'p_id': id_voluntario, 'p_id_grupo': int(id_grupo_str) if id_grupo_str.isdigit() else actual.get("id_grupo"), 'p_nombres': nombres, 'p_apellidos': apellidos, 'p_telefono': telefono, 'p_fecha_nac': fecha_nacimiento, 'p_estado': estado_operativo, 'p_nivel_fisico': nivel_capacidad_fisica, 'p_tipo_limit': tipo_limitacion_fisica if tipo_limitacion_fisica else None, 'p_desc_limit': descripcion_limitacion if descripcion_limitacion else None}).execute()
        console.print("[bold green]Voluntario actualizado exitosamente (Operación ejecutada via SP).[/bold green]")
        
    except Exception as e:
        console.print(f"[bold red]Error al actualizar voluntario: {e}[/bold red]")

def eliminar(supabase):
    titulo_seccion("Eliminar Voluntario")
    id_voluntario = pedir("ID del voluntario a eliminar: ", tipo="int")
    
    if confirmar(f"¿Está seguro de eliminar el voluntario {id_voluntario}?"):
        try:
            supabase.rpc('sp_eliminar_voluntario', {'p_id': id_voluntario}).execute()
            console.print("[bold green]Voluntario eliminado exitosamente (Operación ejecutada via SP).[/bold green]")
        except Exception as e:
            console.print(f"[bold red]Error al eliminar voluntario: {e}[/bold red]")

def menu(supabase):
    while True:
        opc = menu_crud("Voluntario")
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
