# -*- coding: utf-8 -*-
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from helpers import *

def crear(conn):
    titulo_seccion("Crear Voluntario")
    
    id_grupo = seleccionar_fk(conn, "grupo_pastoral", "id_grupo", "nombre_grupo", "Seleccione el Grupo Pastoral: ")
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
        cursor = conn.cursor()
        cursor.callproc('sp_insertar_voluntario', (
            id_grupo, nombres, apellidos, telefono, fecha_nacimiento,
            estado_operativo, nivel_capacidad_fisica,
            tipo_limitacion_fisica or '', descripcion_limitacion or ''
        ))
        conn.commit()
        cursor.close()
        console.print("[bold green]Voluntario creado exitosamente.[/bold green]")
    except Exception as e:
        console.print(f"[bold red]Error al crear voluntario: {e}[/bold red]")

def listar(conn):
    titulo_seccion("Lista de Voluntarios")
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT v.*, g.nombre_grupo 
            FROM voluntario v 
            LEFT JOIN grupo_pastoral g ON v.id_grupo = g.id_grupo
        ''')
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]No hay voluntarios registrados.[/yellow]")
            return
                
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

def buscar(conn):
    titulo_seccion("Buscar Voluntario")
    try:
        id_val = pedir("Ingrese el ID", tipo="int")
        cursor = conn.cursor(dictionary=True)
        cursor.execute('''
            SELECT v.*, g.nombre_grupo 
            FROM voluntario v 
            LEFT JOIN grupo_pastoral g ON v.id_grupo = g.id_grupo
            WHERE v.id_voluntario = %s
        ''', (id_val,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]No se encontró el registro.[/yellow]")
            return
                
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

def actualizar(conn):
    titulo_seccion("Actualizar Voluntario")
    id_voluntario = pedir("ID del voluntario a actualizar: ", tipo="int")
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM voluntario WHERE id_voluntario = %s", (id_voluntario,))
        datos = cursor.fetchall()
        cursor.close()
        
        if not datos:
            console.print("[yellow]Voluntario no encontrado.[/yellow]")
            return
            
        actual = datos[0]
        
        id_grupo_str = pedir_edicion("ID Grupo", str(actual.get("id_grupo")))
        nombres = pedir_edicion("Nombres", actual.get("nombres"))
        apellidos = pedir_edicion("Apellidos", actual.get("apellidos"))
        telefono = pedir_edicion("Teléfono", actual.get("telefono"))
        fecha_nacimiento = pedir_edicion("Fecha Nacimiento", actual.get("fecha_nacimiento"))
        estado_operativo = pedir_edicion("Estado", actual.get("estado_operativo"), opciones=["Activo", "Inactivo", "Suspendido"])
        nivel_capacidad_fisica = pedir_edicion("Capacidad", actual.get("nivel_capacidad_fisica"), opciones=["Alto", "Medio", "Bajo"])
        tipo_limitacion_fisica = pedir_edicion("Tipo Limitación", actual.get("tipo_limitacion_fisica") or "")
        descripcion_limitacion = pedir_edicion("Descripción Limitación", actual.get("descripcion_limitacion") or "")
        
        id_grupo = int(id_grupo_str) if id_grupo_str.isdigit() else actual.get("id_grupo")
        
        cursor = conn.cursor()
        cursor.callproc('sp_actualizar_voluntario', (
            id_voluntario, id_grupo, nombres, apellidos, telefono, fecha_nacimiento,
            estado_operativo, nivel_capacidad_fisica,
            tipo_limitacion_fisica or '', descripcion_limitacion or ''
        ))
        conn.commit()
        cursor.close()
        console.print("[bold green]Voluntario actualizado exitosamente.[/bold green]")
        
    except Exception as e:
        console.print(f"[bold red]Error al actualizar voluntario: {e}[/bold red]")

def eliminar(conn):
    titulo_seccion("Eliminar Voluntario")
    id_voluntario = pedir("ID del voluntario a eliminar: ", tipo="int")
    
    if confirmar(f"¿Está seguro de eliminar el voluntario {id_voluntario}?"):
        try:
            cursor = conn.cursor()
            cursor.callproc('sp_eliminar_voluntario', (id_voluntario,))
            conn.commit()
            cursor.close()
            console.print("[bold green]Voluntario eliminado exitosamente.[/bold green]")
        except Exception as e:
            console.print(f"[bold red]Error al eliminar voluntario: {e}[/bold red]")

def menu(conn):
    while True:
        opc = menu_crud("Voluntario")
        if opc == "1": listar(conn)
        elif opc == "2": buscar(conn)
        elif opc == "3": crear(conn)
        elif opc == "4": actualizar(conn)
        elif opc == "5": eliminar(conn)
        elif opc == "0": break
