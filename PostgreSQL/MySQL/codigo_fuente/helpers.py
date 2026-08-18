# -*- coding: utf-8 -*-
"""Utilidades compartidas para todos los módulos CRUD."""
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich import box

console = Console()

def mostrar_tabla(datos, columnas, titulo="", color_header="bold white on dark_blue"):
    """Muestra datos como tabla Rich. columnas = [(nombre, key, width?, style?), ...]"""
    if not datos:
        console.print("[yellow]  No se encontraron registros.[/]\n")
        return
    tabla = Table(title=titulo, box=box.ROUNDED, show_lines=True,
                  header_style=color_header, border_style="bright_blue")
    for col in columnas:
        name = col[0]
        opts = {}
        if len(col) > 2 and col[2]:
            opts["min_width"] = col[2]
        if len(col) > 3 and col[3]:
            opts["style"] = col[3]
        tabla.add_column(name, **opts)
    for row in datos:
        vals = []
        for col in columnas:
            key = col[1]
            val = row.get(key, "")
            if isinstance(val, dict):
                val = next((v for v in val.values() if isinstance(v, str)), str(val))
            vals.append(str(val) if val is not None else "—")
        tabla.add_row(*vals)
    console.print(tabla)
    console.print(f"  [dim]Total: {len(datos)} registros[/]\n")

def pedir(prompt, obligatorio=True, tipo="str", opciones=None):
    """Pide input al usuario con validación básica."""
    while True:
        valor = console.input(f"  [cyan]{prompt}:[/] ").strip()
        if not valor:
            if not obligatorio:
                return None
            console.print("  [red]Este campo es obligatorio.[/]")
            continue
        if tipo == "int":
            try:
                return int(valor)
            except ValueError:
                console.print("  [red]Debe ser un número entero.[/]")
                continue
        if tipo == "date":
            import re
            if not re.match(r'^\d{4}-\d{2}-\d{2}$', valor):
                console.print("  [red]Formato: YYYY-MM-DD[/]")
                continue
        if tipo == "time":
            import re
            if not re.match(r'^\d{2}:\d{2}$', valor):
                console.print("  [red]Formato: HH:MM[/]")
                continue
        if tipo == "bool":
            if valor.lower() in ('s', 'si', 'sí', 'true', '1', 'yes'):
                return True
            elif valor.lower() in ('n', 'no', 'false', '0'):
                return False
            else:
                console.print("  [red]Responda s/n[/]")
                continue
        if opciones and valor not in opciones:
            console.print(f"  [red]Opciones válidas: {', '.join(opciones)}[/]")
            continue
        return valor

def pedir_edicion(prompt, valor_actual, tipo="str", opciones=None):
    """Pide input para editar; Enter mantiene valor actual."""
    display = valor_actual if valor_actual is not None else "—"
    raw = console.input(f"  [cyan]{prompt}[/] [dim](actual: {display})[/]: ").strip()
    if not raw:
        return valor_actual
    if tipo == "int":
        try:
            return int(raw)
        except ValueError:
            console.print("  [yellow]Valor inválido, se mantiene el actual.[/]")
            return valor_actual
    if tipo == "bool":
        if raw.lower() in ('s', 'si', 'sí', 'true', '1'):
            return True
        elif raw.lower() in ('n', 'no', 'false', '0'):
            return False
        return valor_actual
    if opciones and raw not in opciones:
        console.print(f"  [yellow]Opciones: {', '.join(opciones)}. Se mantiene actual.[/]")
        return valor_actual
    return raw

def confirmar(msg="¿Está seguro?"):
    r = console.input(f"  [bold yellow]{msg} (s/n):[/] ").strip().lower()
    return r in ('s', 'si', 'sí')

def seleccionar_fk(conn, tabla, campo_id, campo_display, prompt="Seleccione"):
    """Muestra registros de una tabla FK y pide seleccionar uno por ID."""
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(f"SELECT {campo_id}, {campo_display} FROM {tabla} ORDER BY {campo_id}")
        data = cursor.fetchall()
        cursor.close()
    except Exception:
        data = []
    if not data:
        console.print(f"  [yellow]No hay registros en {tabla}.[/]")
        return None
    console.print(f"\n  [dim]— {tabla} disponibles —[/]")
    for r in data:
        console.print(f"    [bold]{r[campo_id]}[/] → {r[campo_display]}")
    while True:
        val = pedir(f"{prompt} (ID)", tipo="int")
        if any(r[campo_id] == val for r in data):
            return val
        console.print(f"  [red]ID {val} no existe en {tabla}.[/]")

def titulo_seccion(nombre):
    console.print()
    console.rule(f"[bold cyan]{nombre}[/]", style="cyan")
    console.print()

def menu_crud(nombre, opciones_extra=None):
    """Muestra menú CRUD estándar y retorna la opción."""
    console.print(f"\n[bold bright_cyan]═══ {nombre.upper()} ═══[/]\n")
    console.print("  [bold]1.[/] Listar todos")
    console.print("  [bold]2.[/] Buscar por ID")
    console.print("  [bold]3.[/] Añadir nuevo")
    console.print("  [bold]4.[/] Editar existente")
    console.print("  [bold]5.[/] Eliminar")
    console.print("  [bold]0.[/] Volver al menú principal\n")
    return console.input("[bold cyan]Opción > [/]").strip()
