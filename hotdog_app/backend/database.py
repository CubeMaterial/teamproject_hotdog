from contextlib import contextmanager
from typing import Any, Union

from fastapi import HTTPException

from config import settings


def _quote_identifier(identifier: str) -> str:
    if not identifier.replace("_", "").isalnum():
        raise HTTPException(status_code=500, detail="Invalid database identifier")

    return f"`{identifier}`"


def sanitize_row(row: dict[str, Any]) -> dict[str, Any]:
    sensitive_keys = {"password", "user_pw", "staff_pw"}

    return {
        key: value
        for key, value in row.items()
        if key.lower() not in sensitive_keys and not key.lower().endswith("_password")
    }


@contextmanager
def get_connection():
    try:
        import pymysql
    except ImportError as error:
        raise HTTPException(
            status_code=500,
            detail="pymysql is not installed. Run: pip install -r backend/requirements.txt",
        ) from error

    connection = pymysql.connect(
        host=settings.DB_HOST,
        port=settings.DB_PORT,
        user=settings.DB_USER,
        password=settings.DB_PASSWORD,
        database=settings.DB_NAME,
        charset=settings.DB_CHARSET,
        cursorclass=pymysql.cursors.DictCursor,
    )

    try:
        yield connection
    finally:
        connection.close()


def fetch_all(table_name: str, limit: int = 100) -> list[dict[str, Any]]:
    safe_limit = max(1, min(limit, 500))

    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    f"SELECT * FROM {_quote_identifier(table_name)} LIMIT %s",
                    (safe_limit,),
                )
                return [sanitize_row(dict(row)) for row in cursor.fetchall()]
    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(status_code=500, detail=str(error)) from error


def fetch_one_by_id(
    table_name: str,
    id_column: str,
    item_id: Union[int, str],
) -> dict[str, Any]:
    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    (
                        f"SELECT * FROM {_quote_identifier(table_name)} "
                        f"WHERE {_quote_identifier(id_column)} = %s LIMIT 1"
                    ),
                    (item_id,),
                )
                row = cursor.fetchone()
    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(status_code=500, detail=str(error)) from error

    if row is None:
        raise HTTPException(status_code=404, detail="Item not found")

    return sanitize_row(dict(row))


def fetch_query(query: str, params: tuple[Any, ...] = ()) -> list[dict[str, Any]]:
    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(query, params)
                return [sanitize_row(dict(row)) for row in cursor.fetchall()]
    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(status_code=500, detail=str(error)) from error


def fetch_single_value(query: str, params: tuple[Any, ...] = ()) -> Any:
    rows = fetch_query(query, params)

    if not rows:
        return None

    return next(iter(rows[0].values()))
