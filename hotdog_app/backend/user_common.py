import base64
import random
import re
import secrets
import time
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import aiomysql
from fastapi import HTTPException

from config import settings
from refund_state import RefundState

BASE_DIR = Path(__file__).resolve().parent
UPLOADS_DIR = BASE_DIR / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

pool: Optional[aiomysql.Pool] = None
email_verification_codes: Dict[str, Dict[str, Any]] = {}
verified_emails: Dict[str, float] = {}
email_code_cooldown: Dict[str, float] = {}
require_email_verification_for_signup = settings.REQUIRE_EMAIL_VERIFICATION


def db_config() -> Dict[str, Any]:
    return {
        "host": settings.DB_HOST,
        "port": settings.DB_PORT,
        "user": settings.DB_USER,
        "password": settings.DB_PASSWORD,
        "db": settings.DB_NAME,
        "charset": settings.DB_CHARSET,
        "cursorclass": aiomysql.DictCursor,
        "autocommit": False,
    }


async def get_pool() -> aiomysql.Pool:
    if pool is None:
        raise HTTPException(status_code=500, detail="Database pool is not ready.")
    return pool


def create_verification_code() -> str:
    return str(random.randint(100000, 999999))


def is_valid_email(email: Any) -> bool:
    return (
        isinstance(email, str)
        and re.match(r"^[^\s@]+@[^\s@]+\.[^\s@]+$", email) is not None
    )


def parse_dog_weight(raw_weight: Any) -> Optional[float]:
    if raw_weight is None:
        return None
    match = re.search(r"\d+(\.\d+)?", str(raw_weight))
    return float(match.group(0)) if match else None


def format_date(value: Any) -> Any:
    if hasattr(value, "strftime"):
        return value.strftime("%%Y-%%m-%%d")
    return value


def parse_delivery_address(raw_address: Any) -> Dict[str, str]:
    raw = str(raw_address or "").strip()
    if not raw:
        return {"address_name": "", "address": ""}

    parts = [part.strip() for part in raw.split("/")]
    if len(parts) >= 3:
        return {
            "address_name": f"{parts[0]} / {parts[1]}"[:100],
            "address": " / ".join(parts[2:])[:100],
        }

    return {"address_name": "최근 배송지", "address": raw[:100]}


def sniff_content_type(data: bytes) -> str:
    if data.startswith(b"\x89PNG"):
        return "image/png"
    if data.startswith(b"\xff\xd8\xff"):
        return "image/jpeg"
    if data.startswith(b"GIF8"):
        return "image/gif"
    return "application/octet-stream"


def save_review_image(raw_image: Any) -> Optional[str]:
    if not raw_image or not isinstance(raw_image, str):
        return None

    value = raw_image.strip()
    data_uri_match = re.match(
        r"^data:image/(png|jpe?g);base64,(.+)$", value, re.IGNORECASE | re.DOTALL
    )
    if not data_uri_match:
        return value[:100]

    image_ext = data_uri_match.group(1).lower()
    if image_ext == "jpeg":
        image_ext = "jpg"

    try:
        image_data = base64.b64decode(data_uri_match.group(2), validate=True)
    except Exception as exc:
        raise HTTPException(
            status_code=400, detail="후기 사진 형식이 올바르지 않습니다."
        ) from exc

    review_dir = UPLOADS_DIR / "reviews"
    review_dir.mkdir(parents=True, exist_ok=True)
    file_name = f"review_{int(time.time() * 1000)}_{secrets.token_hex(6)}.{image_ext}"
    file_path = review_dir / file_name
    file_path.write_bytes(image_data)
    return f"/uploads/reviews/{file_name}"[:100]


def save_dog_image(raw_image: Any) -> Optional[str]:
    if not raw_image or not isinstance(raw_image, str):
        return None

    value = raw_image.strip()
    data_uri_match = re.match(
        r"^data:image/(png|jpe?g);base64,(.+)$", value, re.IGNORECASE | re.DOTALL
    )
    if not data_uri_match:
        return value[:255]

    image_ext = data_uri_match.group(1).lower()
    if image_ext == "jpeg":
        image_ext = "jpg"

    try:
        image_data = base64.b64decode(data_uri_match.group(2), validate=True)
    except Exception as exc:
        raise HTTPException(
            status_code=400, detail="강아지 사진 형식이 올바르지 않습니다."
        ) from exc

    dog_dir = UPLOADS_DIR / "dogs"
    dog_dir.mkdir(parents=True, exist_ok=True)
    file_name = f"dog_{int(time.time() * 1000)}_{secrets.token_hex(6)}.{image_ext}"
    file_path = dog_dir / file_name
    file_path.write_bytes(image_data)
    return f"/uploads/dogs/{file_name}"[:255]


async def fetch_all(sql: str, params: Tuple[Any, ...] = ()) -> List[Dict[str, Any]]:
    db = await get_pool()
    async with db.acquire() as conn:
        async with conn.cursor() as cur:
            ## Error 발생. GT modified.
            if len(params) > 0:
                await cur.execute(sql, params)
            else:
                await cur.execute(sql)
            rows = await cur.fetchall()
            return list(rows)


async def fetch_one(sql: str, params: Tuple[Any, ...] = ()) -> Optional[Dict[str, Any]]:
    rows = await fetch_all(sql, params)
    return rows[0] if rows else None


async def find_or_create_lookup(
    conn: aiomysql.Connection,
    table_name: str,
    id_column: str,
    name_column: str,
    raw_name: Any,
) -> Optional[int]:
    name = str(raw_name or "").strip()
    if not name:
        return None

    async with conn.cursor() as cur:
        await cur.execute(
            f"SELECT `{id_column}` AS id FROM `{table_name}` WHERE `{name_column}` = %s LIMIT 1",
            (name,),
        )
        existing = await cur.fetchone()
        if existing:
            return int(existing["id"])

        await cur.execute(
            f"INSERT INTO `{table_name}` (`{name_column}`) VALUES (%s)", (name,)
        )
        return int(cur.lastrowid)


async def ensure_review_columns() -> None:
    db = await get_pool()
    async with db.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute("""
                SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = 'review'
                  AND COLUMN_NAME = 'buy_seq'
                """)
            has_column = await cur.fetchone()
            if not has_column:
                await cur.execute(
                    "ALTER TABLE review ADD COLUMN buy_seq INT NULL AFTER user_seq"
                )
                await cur.execute("CREATE INDEX idx_review_buy_seq ON review (buy_seq)")

            await cur.execute("""
                SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = 'review'
                  AND COLUMN_NAME = 'review_like'
                """)
            has_like_column = await cur.fetchone()
            if not has_like_column:
                await cur.execute(
                    "ALTER TABLE review ADD COLUMN review_like INT NOT NULL DEFAULT 0"
                )

            if not has_column or not has_like_column:
                await conn.commit()


async def ensure_purchase_columns() -> None:
    db = await get_pool()
    async with db.acquire() as conn:
        changed = False
        async with conn.cursor() as cur:
            await cur.execute("""
                SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = 'buy'
                  AND COLUMN_NAME = 'buy_status'
                """)
            if not await cur.fetchone():
                await cur.execute(
                    "ALTER TABLE buy ADD COLUMN buy_status VARCHAR(20) NOT NULL DEFAULT 'shipping' AFTER user_seq"
                )
                changed = True

            await cur.execute("""
                SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = 'buy'
                  AND COLUMN_NAME = 'status_updated_at'
                """)
            if not await cur.fetchone():
                await cur.execute(
                    "ALTER TABLE buy ADD COLUMN status_updated_at DATETIME NULL AFTER buy_status"
                )
                changed = True

        if changed:
            await conn.commit()


async def ensure_refund_table() -> None:
    db = await get_pool()
    async with db.acquire() as conn:
        changed = False
        async with conn.cursor() as cur:
            await cur.execute(
                """
                CREATE TABLE IF NOT EXISTS refund (
                    refund_seq INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
                    buy_seq INT NOT NULL,
                    user_seq INT NOT NULL,
                    refund_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    refund_state TINYINT NOT NULL DEFAULT 0,
                    refund_details TEXT NULL,
                    UNIQUE KEY uq_refund_buy_seq (buy_seq)
                )
                """
            )

            column_definitions = {
                "buy_seq": "ALTER TABLE refund ADD COLUMN buy_seq INT NOT NULL AFTER refund_seq",
                "user_seq": "ALTER TABLE refund ADD COLUMN user_seq INT NOT NULL AFTER buy_seq",
                "refund_date": "ALTER TABLE refund ADD COLUMN refund_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER user_seq",
                "refund_state": "ALTER TABLE refund ADD COLUMN refund_state TINYINT NOT NULL DEFAULT 0 AFTER refund_date",
                "refund_details": "ALTER TABLE refund ADD COLUMN refund_details TEXT NULL AFTER refund_state",
            }
            for column_name, alter_sql in column_definitions.items():
                await cur.execute(
                    """
                    SELECT COLUMN_NAME
                    FROM INFORMATION_SCHEMA.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'refund'
                      AND COLUMN_NAME = %s
                    """,
                    (column_name,),
                )
                if not await cur.fetchone():
                    await cur.execute(alter_sql)
                    changed = True

            await cur.execute(
                """
                SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = 'refund'
                  AND COLUMN_NAME = 'refund_status'
                """
            )
            has_refund_status = await cur.fetchone()
            if has_refund_status:
                await cur.execute(
                    """
                    UPDATE refund
                    SET refund_state = COALESCE(NULLIF(refund_state, ''), refund_status)
                    """
                )
                await cur.execute("ALTER TABLE refund DROP COLUMN refund_status")
                changed = True

            await cur.execute(
                """
                SELECT DATA_TYPE
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = 'refund'
                  AND COLUMN_NAME = 'refund_state'
                """
            )
            refund_state_column = await cur.fetchone()
            if (
                refund_state_column
                and refund_state_column.get("DATA_TYPE") != "tinyint"
            ):
                await cur.execute(
                    """
                    UPDATE refund
                    SET refund_state = CASE
                        WHEN LOWER(TRIM(CAST(refund_state AS CHAR))) IN
                            ('pending', 'hold', 'on_hold')
                            THEN %s
                        WHEN LOWER(TRIM(CAST(refund_state AS CHAR))) IN
                            ('1', 'approved', 'complete', 'completed', 'refunded')
                            THEN %s
                        WHEN LOWER(TRIM(CAST(refund_state AS CHAR))) IN
                            ('2', '3', 'rejected', 'denied', 'canceled', 'cancelled')
                            THEN %s
                        ELSE %s
                    END
                    """,
                    (
                        RefundState.ON_HOLD.value,
                        RefundState.CONFIRMED.value,
                        RefundState.CANCELED.value,
                        RefundState.REQUESTED.value,
                    ),
                )
                await cur.execute(
                    """
                    ALTER TABLE refund
                    MODIFY COLUMN refund_state TINYINT NOT NULL DEFAULT 0
                    """
                )
                changed = True

            await cur.execute(
                """
                UPDATE refund r
                INNER JOIN buy b ON b.buy_seq = r.buy_seq
                SET r.refund_state = %s
                WHERE b.buy_status = 'refunded'
                  AND r.refund_state <> %s
                """,
                (
                    RefundState.CONFIRMED.value,
                    RefundState.CONFIRMED.value,
                ),
            )
            if cur.rowcount > 0:
                changed = True

        if changed:
            await conn.commit()


async def ensure_dog_columns() -> None:
    db = await get_pool()
    async with db.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute("""
                SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = 'dog'
                  AND COLUMN_NAME = 'dog_image'
                """)
            if not await cur.fetchone():
                await cur.execute(
                    "ALTER TABLE dog ADD COLUMN dog_image VARCHAR(255) NULL AFTER dog_name"
                )
                await conn.commit()


async def startup_user_api() -> None:
    global pool
    pool = await aiomysql.create_pool(**db_config())
    await ensure_review_columns()
    await ensure_purchase_columns()
    await ensure_refund_table()
    await ensure_dog_columns()


async def shutdown_user_api() -> None:
    if pool is not None:
        pool.close()
        await pool.wait_closed()
