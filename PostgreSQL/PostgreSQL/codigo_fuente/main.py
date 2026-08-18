# -*- coding: utf-8 -*-

import os, sys

os.environ["PYTHONIOENCODING"] = "utf-8"
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.text import Text
    from rich import box
except ImportError:
    print("Instale dependencias: pip install supabase rich python-dotenv")
    sys.exit(1)

from db import get_client
from crud import grupo_pastoral, categoria_evento, rol, voluntario, evento
from crud import usuario, requerimiento, autorizacion, asignacion

console = Console()

MENU_OPCIONES = [
    ("Tablas Principales", [
        ("1", "Grupo Pastoral",     grupo_pastoral.menu),
        ("2", "Categoria Evento",   categoria_evento.menu),
        ("3", "Rol",                rol.menu),
        ("4", "Voluntario",         voluntario.menu),
        ("5", "Evento",             evento.menu),
        ("6", "Usuario (Admin/Coord)", usuario.menu),
    ]),
    ("Tablas de Relacion", [
        ("7", "Requerimiento (Evento-Rol)",       requerimiento.menu),
        ("8", "Autorizacion (Voluntario-Rol)",     autorizacion.menu),
        ("9", "Asignacion",                        asignacion.menu),
    ]),
]


def mostrar_banner():
    banner = Text()
    banner.append("SISTEMA DE GESTION DE VOLUNTARIOS\n", style="bold cyan")
    banner.append("SIGEVEP — Grupo #3\n", style="bold white")
    banner.append("Sistemas de Bases de Datos 1 - ESPOL\n", style="dim")
    banner.append("Avance 03", style="dim italic")
    panel = Panel(banner, border_style="bright_cyan", box=box.DOUBLE,
                  padding=(1, 4), title="[bold white]ESPOL[/]",
                  subtitle="[dim]Primer Termino 2026-2027[/]")
    console.print(panel, justify="center")


def menu_principal():
    supabase = get_client()
    console.print("[green]Conexion a Supabase establecida.[/]\n")

    while True:
        console.print("\n[bold bright_cyan]" + "=" * 50 + "[/]")
        console.print("[bold bright_cyan]          MENU PRINCIPAL — SIGEVEP[/]")
        console.print("[bold bright_cyan]" + "=" * 50 + "[/]\n")

        for seccion, items in MENU_OPCIONES:
            console.print(f"  [bold underline]{seccion}[/]")
            for num, nombre, _ in items:
                console.print(f"    [bold]{num}.[/] {nombre}")
            console.print()

        console.print("    [bold]0.[/] Salir del Sistema\n")
        opcion = console.input("[bold cyan]Opcion > [/]").strip()

        if opcion == "0":
            console.print("\n[bold green]Hasta luego![/] Sistema cerrado.\n")
            break

        encontrado = False
        for _, items in MENU_OPCIONES:
            for num, nombre, func in items:
                if opcion == num:
                    try:
                        func(supabase)
                    except KeyboardInterrupt:
                        console.print("\n[yellow]Operacion cancelada.[/]")
                    except Exception as e:
                        console.print(f"\n[bold red]Error:[/] {e}")
                    encontrado = True
                    break
            if encontrado:
                break

        if not encontrado:
            console.print("[red]Opcion no valida.[/]")


if __name__ == "__main__":
    console.clear()
    mostrar_banner()
    menu_principal()
