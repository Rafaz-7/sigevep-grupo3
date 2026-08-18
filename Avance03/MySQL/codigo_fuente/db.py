import mysql.connector
from mysql.connector import Error
import sys, os

os.environ['PYTHONIOENCODING'] = 'utf-8'
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')

_connection = None

DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'sigevep',
    'charset': 'utf8mb4',
    'autocommit': False
}

def get_connection():
    global _connection
    if _connection is None or not _connection.is_connected():
        _connection = mysql.connector.connect(**DB_CONFIG)
    return _connection

def get_cursor():
    conn = get_connection()
    return conn.cursor(dictionary=True)
