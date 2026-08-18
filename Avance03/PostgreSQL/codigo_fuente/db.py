# -*- coding: utf-8 -*-
"""Módulo de conexión a Supabase (singleton)."""
import os, sys
os.environ["PYTHONIOENCODING"] = "utf-8"
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()
_client = None

def get_client() -> Client:
    global _client
    if _client is None:
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_KEY")
        if not url or not key:
            print("ERROR: Crea un archivo .env con SUPABASE_URL y SUPABASE_KEY")
            sys.exit(1)
        _client = create_client(url, key)
    return _client
