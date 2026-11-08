from contextlib import contextmanager
from typing import Iterator

import psycopg
from psycopg import Connection
from psycopg.rows import dict_row

from config.settings import settings


@contextmanager
def get_connection() -> Iterator[Connection]:
    """Yield a short-lived connection; transaction commits/rolls back on exit."""
    conn = psycopg.connect(settings.database_url, row_factory=dict_row, connect_timeout=5)
    try:
        with conn:
            yield conn
    finally:
        conn.close()


def health_check() -> tuple[bool, str]:
    try:
        with get_connection() as conn:
            conn.execute("SELECT 1")
        return True, "PostgreSQL connection is healthy."
    except psycopg.Error as exc:
        code = f" (SQLSTATE {exc.sqlstate})" if exc.sqlstate else ""
        return False, f"PostgreSQL is unavailable (connection failed{code}). Check the database settings and server status."
