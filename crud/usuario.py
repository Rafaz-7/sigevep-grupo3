# -*- coding: utf-8 -*-
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from helpers import *

def menu(supabase):
    while True:
        opcion = menu_crud("Usuario")
        
        if opcion == '1':
            listar_usuarios(supabase)
        elif opcion == '2':
            buscar_usuario(supabase)
        elif opcion == '3':
            agregar_usuario(supabase)
        elif opcion == '4':
            editar_usuario(supabase)
        elif opcion == '5':
            eliminar_usuario(supabase)
        elif opcion == '0':
            break
        else:
            console.print("[red]Opción no válida.[/red]")

def listar_usuarios(supabase):
    titulo_seccion("Lista de Usuarios")
    try:
        usuarios = supabase.table('usuario').select('*').execute().data
        admins = {a['id_usuario']: a for a in supabase.table('administrador').select('*').execute().data}
        coords = {c['id_usuario']: c for c in supabase.table('coordinador').select('*').execute().data}

        datos = []
        for u in usuarios:
            fila = u.copy()
            fila['nivel_permiso'] = '-'
            fila['zona_asignada'] = '-'
            
            if u['rol_acceso'] == 'Administrador' and u['id_usuario'] in admins:
                fila['nivel_permiso'] = admins[u['id_usuario']].get('nivel_permiso', '-')
            elif u['rol_acceso'] == 'Coordinador' and u['id_usuario'] in coords:
                fila['zona_asignada'] = coords[u['id_usuario']].get('zona_asignada', '-')
                
            datos.append(fila)

        columnas = [
            ("ID", "id_usuario"),
            ("Nombre", "nombre_usuario"),
            ("Rol", "rol_acceso"),
            ("Nivel Permiso (Admin)", "nivel_permiso"),
            ("Zona Asignada (Coord)", "zona_asignada")
        ]
        mostrar_tabla(datos, columnas, "Usuarios", "cyan")
    except Exception as e:
        console.print(f"[red]Error al listar usuarios: {e}[/red]")

def buscar_usuario(supabase):
    titulo_seccion("Buscar Usuario")
    id_usuario = pedir("Ingrese el ID del usuario a buscar", tipo="int")
    if id_usuario is None: return

    try:
        usuario = supabase.table('usuario').select('*').eq('id_usuario', id_usuario).execute().data
        if not usuario:
            console.print("[yellow]Usuario no encontrado.[/yellow]")
            return
            
        u = usuario[0]
        console.print(f"\n[green]ID:[/green] {u['id_usuario']}")
        console.print(f"[green]Nombre:[/green] {u['nombre_usuario']}")
        console.print(f"[green]Rol:[/green] {u['rol_acceso']}")

        if u['rol_acceso'] == 'Administrador':
            admin = supabase.table('administrador').select('*').eq('id_usuario', id_usuario).execute().data
            if admin:
                console.print(f"[green]Nivel Permiso:[/green] {admin[0]['nivel_permiso']}")
        elif u['rol_acceso'] == 'Coordinador':
            coord = supabase.table('coordinador').select('*').eq('id_usuario', id_usuario).execute().data
            if coord:
                console.print(f"[green]Zona Asignada:[/green] {coord[0]['zona_asignada']}")
                
    except Exception as e:
        console.print(f"[red]Error al buscar usuario: {e}[/red]")

def agregar_usuario(supabase):
    titulo_seccion("Añadir Usuario")
    nombre = pedir("Nombre de usuario")
    if not nombre: return
    clave = pedir("Clave de acceso")
    if not clave: return
    rol = pedir("Rol de acceso", opciones=["Administrador", "Coordinador"])
    if not rol: return

    try:
        nuevo_usuario = {
            "nombre_usuario": nombre,
            "clave_acceso": clave,
            "rol_acceso": rol
        }
        res_usuario = supabase.table('usuario').insert(nuevo_usuario).execute().data
        
        if res_usuario:
            id_usuario = res_usuario[0]['id_usuario']
            
            if rol == 'Administrador':
                nivel = pedir("Nivel de permiso", opciones=["Total", "Parcial"])
                supabase.table('administrador').insert({
                    "id_usuario": id_usuario,
                    "nivel_permiso": nivel
                }).execute()
            elif rol == 'Coordinador':
                zona = pedir("Zona asignada")
                supabase.table('coordinador').insert({
                    "id_usuario": id_usuario,
                    "zona_asignada": zona
                }).execute()
                
            console.print(f"[bold green]Usuario añadido exitosamente con ID {id_usuario}.[/bold green]")
    except Exception as e:
        console.print(f"[red]Error al añadir usuario: {e}[/red]")

def editar_usuario(supabase):
    titulo_seccion("Editar Usuario")
    id_usuario = pedir("Ingrese el ID del usuario a editar", tipo="int")
    if id_usuario is None: return

    try:
        usuario = supabase.table('usuario').select('*').eq('id_usuario', id_usuario).execute().data
        if not usuario:
            console.print("[yellow]Usuario no encontrado.[/yellow]")
            return
            
        u = usuario[0]
        nuevo_nombre = pedir_edicion("Nombre de usuario", u['nombre_usuario'])
        nueva_clave = pedir_edicion("Clave de acceso", u['clave_acceso'])
        
        update_data = {}
        if nuevo_nombre != u['nombre_usuario']: update_data['nombre_usuario'] = nuevo_nombre
        if nueva_clave != u['clave_acceso']: update_data['clave_acceso'] = nueva_clave
        
        if update_data:
            supabase.table('usuario').update(update_data).eq('id_usuario', id_usuario).execute()
            
        if u['rol_acceso'] == 'Administrador':
            admin = supabase.table('administrador').select('*').eq('id_usuario', id_usuario).execute().data
            if admin:
                nuevo_nivel = pedir_edicion("Nivel de permiso", admin[0]['nivel_permiso'], opciones=["Total", "Parcial"])
                if nuevo_nivel != admin[0]['nivel_permiso']:
                    supabase.table('administrador').update({'nivel_permiso': nuevo_nivel}).eq('id_usuario', id_usuario).execute()
                    
        elif u['rol_acceso'] == 'Coordinador':
            coord = supabase.table('coordinador').select('*').eq('id_usuario', id_usuario).execute().data
            if coord:
                nueva_zona = pedir_edicion("Zona asignada", coord[0]['zona_asignada'])
                if nueva_zona != coord[0]['zona_asignada']:
                    supabase.table('coordinador').update({'zona_asignada': nueva_zona}).eq('id_usuario', id_usuario).execute()

        console.print("[bold green]Usuario actualizado exitosamente.[/bold green]")
    except Exception as e:
        console.print(f"[red]Error al editar usuario: {e}[/red]")

def eliminar_usuario(supabase):
    titulo_seccion("Eliminar Usuario")
    id_usuario = pedir("Ingrese el ID del usuario a eliminar", tipo="int")
    if id_usuario is None: return

    try:
        usuario = supabase.table('usuario').select('*').eq('id_usuario', id_usuario).execute().data
        if not usuario:
            console.print("[yellow]Usuario no encontrado.[/yellow]")
            return

        if confirmar(f"¿Está seguro que desea eliminar el usuario ID {id_usuario}?"):
            # Eliminar de subtipos primero por integridad referencial
            supabase.table('administrador').delete().eq('id_usuario', id_usuario).execute()
            supabase.table('coordinador').delete().eq('id_usuario', id_usuario).execute()
            
            # Eliminar de tabla padre
            supabase.table('usuario').delete().eq('id_usuario', id_usuario).execute()
            console.print("[bold green]Usuario eliminado exitosamente.[/bold green]")
        else:
            console.print("[yellow]Operación cancelada.[/yellow]")
    except Exception as e:
        console.print(f"[red]Error al eliminar usuario: {e}[/red]")
