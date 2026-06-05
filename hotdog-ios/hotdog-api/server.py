import base64
import importlib.util
import os
import random
import re
import secrets
import time
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import aiomysql
from app.chatbot.router import router as chatbot_router
from dotenv import load_dotenv
from fastapi import Body, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from fastapi.staticfiles import StaticFiles

BASE_DIR = Path(__file__).resolve().parent
UPLOADS_DIR = BASE_DIR / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

load_dotenv(BASE_DIR / ".env")

app = FastAPI(title="Hotdog API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.mount("/uploads", StaticFiles(directory=str(UPLOADS_DIR)), name="uploads")
app.include_router(chatbot_router)


def load_dog_analysis_router():
    router_path = (
        BASE_DIR.parents[1]
        / "hotdog_app"
        / "backend"
        / "app"
        / "dog_analysis"
        / "router.py"
    )
    if not router_path.exists():
        return None

    spec = importlib.util.spec_from_file_location("hotdog_shared_dog_analysis_router", router_path)
    if spec is None or spec.loader is None:
        return None

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return getattr(module, "router", None)


dog_analysis_router = load_dog_analysis_router()
if dog_analysis_router is not None:
    app.include_router(dog_analysis_router)

pool: Optional[aiomysql.Pool] = None
email_verification_codes: Dict[str, Dict[str, Any]] = {}
verified_emails: Dict[str, float] = {}
email_code_cooldown: Dict[str, float] = {}
require_email_verification_for_signup = (
    os.getenv("REQUIRE_EMAIL_VERIFICATION", "false").lower() == "true"
)


def db_config() -> Dict[str, Any]:
    return {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": int(os.getenv("DB_PORT", "3306")),
        "user": os.getenv("DB_USER", "root"),
        "password": os.getenv("DB_PASSWORD", ""),
        "db": os.getenv("DB_NAME", "hotdog_final"),
        "charset": "utf8mb4",
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
                    refund_state VARCHAR(20) NOT NULL DEFAULT 'requested',
                    UNIQUE KEY uq_refund_buy_seq (buy_seq)
                )
                """
            )

            column_definitions = {
                "buy_seq": "ALTER TABLE refund ADD COLUMN buy_seq INT NOT NULL AFTER refund_seq",
                "user_seq": "ALTER TABLE refund ADD COLUMN user_seq INT NOT NULL AFTER buy_seq",
                "refund_date": "ALTER TABLE refund ADD COLUMN refund_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER user_seq",
                "refund_state": "ALTER TABLE refund ADD COLUMN refund_state VARCHAR(20) NOT NULL DEFAULT 'requested' AFTER refund_date",
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


@app.on_event("startup")
async def startup() -> None:
    global pool
    pool = await aiomysql.create_pool(**db_config())
    await ensure_review_columns()
    await ensure_purchase_columns()
    await ensure_refund_table()
    await ensure_dog_columns()


@app.on_event("shutdown")
async def shutdown() -> None:
    if pool is not None:
        pool.close()
        await pool.wait_closed()


@app.get("/")
async def health() -> Dict[str, str]:
    return {"message": "Hotdog FastAPI server is running."}


@app.get("/products")
async def get_products() -> List[Dict[str, Any]]:
    return await fetch_all("""
        SELECT
            p.product_seq,
            p.product_name,
            p.product_qty,
            p.product_price,
            p.product_category_seq,
            p.product_sub_category_seq,
            pc.product_category_name AS raw_category_name,
            psc.product_sub_category_name AS raw_sub_category_name,
            psc.product_sub_category_name,
            CASE
                WHEN psc.product_sub_category_name LIKE '%사료%' OR p.product_name LIKE '%사료%' THEN '사료'
                WHEN psc.product_sub_category_name LIKE '%간식%' OR p.product_name LIKE '%간식%' THEN '간식'
                WHEN psc.product_sub_category_name LIKE '%목줄%' OR psc.product_sub_category_name LIKE '%리드%' OR p.product_name LIKE '%목줄%' THEN '목줄'
                WHEN psc.product_sub_category_name LIKE '%하네스%' OR p.product_name LIKE '%하네스%' THEN '하네스'
                WHEN psc.product_sub_category_name LIKE '%의류%' OR psc.product_sub_category_name LIKE '%옷%' OR p.product_name LIKE '%옷%' THEN '의류'
                WHEN psc.product_sub_category_name LIKE '%장난감%' OR p.product_name LIKE '%장난감%' OR p.product_name LIKE '%노즈워크%' THEN '장난감'
                ELSE COALESCE(psc.product_sub_category_name, pc.product_category_name, '기타')
            END AS product_category_name
        FROM product p
        LEFT JOIN product_category pc ON pc.product_category_seq = p.product_category_seq
        LEFT JOIN product_sub_category psc ON psc.product_sub_category_seq = p.product_sub_category_seq
        ORDER BY
            CASE WHEN COALESCE(p.product_qty, 0) <= 0 THEN 1 ELSE 0 END ASC,
            p.product_seq DESC
        """)


async def product_image_response(product_seq: int, columns: str) -> Response:
    row = await fetch_one(
        f"SELECT {columns} FROM product WHERE product_seq = %s LIMIT 1", (product_seq,)
    )
    if not row:
        raise HTTPException(status_code=404, detail="상품을 찾을 수 없습니다.")

    image_data = next((value for value in row.values() if value), None)
    if not image_data:
        raise HTTPException(status_code=404, detail="상품 이미지가 없습니다.")

    if isinstance(image_data, memoryview):
        image_data = image_data.tobytes()
    elif not isinstance(image_data, bytes):
        image_data = bytes(image_data)

    return Response(content=image_data, media_type=sniff_content_type(image_data))


@app.get("/products/{product_seq}/image")
async def get_product_image(product_seq: int) -> Response:
    return await product_image_response(product_seq, "product_image, product_thumbnail")


@app.get("/products/{product_seq}/thumbnail")
async def get_product_thumbnail(product_seq: int) -> Response:
    return await product_image_response(product_seq, "product_thumbnail, product_image")


@app.get("/reviews")
async def get_reviews() -> List[Dict[str, Any]]:
    return await fetch_all("""
        SELECT
            r.review_seq,
            r.product_seq,
            r.user_seq,
            r.buy_seq,
            r.review_title,
            r.review_content,
            r.review_image,
            r.review_rating,
            COALESCE(r.review_like, 0) AS review_like,
            DATE_FORMAT(r.review_date, '%Y-%m-%d') AS review_date,
            p.product_name,
            u.user_name
        FROM review r
        LEFT JOIN product p ON p.product_seq = r.product_seq
        LEFT JOIN users u ON u.user_seq = r.user_seq
        ORDER BY COALESCE(r.review_like, 0) DESC, r.review_seq DESC
        """)


@app.post("/reviews")
async def create_review(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    product_seq = int(payload.get("product_seq") or 0)
    user_seq = int(payload.get("user_seq") or 0)
    requested_buy_seq = int(payload.get("buy_seq") or 0)
    title = str(payload.get("review_title") or "").strip()
    content = str(payload.get("review_content") or "").strip()
    rating = int(payload.get("review_rating") or 5)

    if product_seq <= 0 or user_seq <= 0 or not title or not content:
        raise HTTPException(status_code=400, detail="후기 작성 정보가 부족합니다.")

    image_path = save_review_image(payload.get("review_image"))
    db = await get_pool()
    async with db.acquire() as conn:
        try:
            await conn.begin()
            async with conn.cursor() as cur:
                if requested_buy_seq > 0:
                    await cur.execute(
                        """
                        SELECT buy_seq
                        FROM buy
                        WHERE buy_seq = %s AND product_seq = %s AND user_seq = %s
                        LIMIT 1
                        """,
                        (requested_buy_seq, product_seq, user_seq),
                    )
                    purchase = await cur.fetchone()
                else:
                    await cur.execute(
                        """
                        SELECT b.buy_seq
                        FROM buy b
                        LEFT JOIN review r ON r.buy_seq = b.buy_seq
                        WHERE b.product_seq = %s
                          AND b.user_seq = %s
                          AND r.review_seq IS NULL
                        ORDER BY b.buy_seq DESC
                        LIMIT 1
                        """,
                        (product_seq, user_seq),
                    )
                    purchase = await cur.fetchone()

                if not purchase:
                    raise HTTPException(
                        status_code=403,
                        detail="구매했거나 아직 리뷰를 쓰지 않은 주문만 후기를 작성할 수 있습니다.",
                    )

                buy_seq = int(purchase["buy_seq"])
                await cur.execute(
                    "SELECT review_seq FROM review WHERE buy_seq = %s LIMIT 1",
                    (buy_seq,),
                )
                duplicate = await cur.fetchone()
                if duplicate:
                    raise HTTPException(
                        status_code=409,
                        detail="이미 해당 구매건의 후기를 작성했습니다.",
                    )

                await cur.execute(
                    """
                    INSERT INTO review
                        (product_seq, user_seq, buy_seq, review_title, review_content, review_image, review_rating, review_date)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())
                    """,
                    (
                        product_seq,
                        user_seq,
                        buy_seq,
                        title[:100],
                        content,
                        image_path,
                        rating,
                    ),
                )
                review_seq = int(cur.lastrowid)

            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    review = await fetch_one(
        """
        SELECT
            r.review_seq,
            r.product_seq,
            r.user_seq,
            r.buy_seq,
            r.review_title,
            r.review_content,
            r.review_image,
            r.review_rating,
            COALESCE(r.review_like, 0) AS review_like,
            DATE_FORMAT(r.review_date, '%%Y-%%m-%%d') AS review_date,
            p.product_name,
            u.user_name
        FROM review r
        LEFT JOIN product p ON p.product_seq = r.product_seq
        LEFT JOIN users u ON u.user_seq = r.user_seq
        WHERE r.review_seq = %s
        LIMIT 1
        """,
        (review_seq,),
    )
    return review or {"review_seq": review_seq}


@app.post("/reviews/{review_seq}/like")
async def like_review(review_seq: int) -> Dict[str, Any]:
    if review_seq <= 0:
        raise HTTPException(
            status_code=400, detail="좋아요를 누를 후기 정보가 부족합니다."
        )

    db = await get_pool()
    async with db.acquire() as conn:
        try:
            await conn.begin()
            async with conn.cursor() as cur:
                await cur.execute(
                    "UPDATE review SET review_like = COALESCE(review_like, 0) + 1 WHERE review_seq = %s",
                    (review_seq,),
                )
                if cur.rowcount == 0:
                    raise HTTPException(
                        status_code=404, detail="후기를 찾을 수 없습니다."
                    )
            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    review = await fetch_one(
        """
        SELECT
            r.review_seq,
            r.product_seq,
            r.user_seq,
            r.buy_seq,
            r.review_title,
            r.review_content,
            r.review_image,
            r.review_rating,
            COALESCE(r.review_like, 0) AS review_like,
            DATE_FORMAT(r.review_date, '%%Y-%%m-%%d') AS review_date,
            p.product_name,
            u.user_name
        FROM review r
        LEFT JOIN product p ON p.product_seq = r.product_seq
        LEFT JOIN users u ON u.user_seq = r.user_seq
        WHERE r.review_seq = %s
        LIMIT 1
        """,
        (review_seq,),
    )
    return review or {"review_seq": review_seq}


@app.patch("/reviews/{review_seq}")
async def update_review(
    review_seq: int, payload: Dict[str, Any] = Body(...)
) -> Dict[str, Any]:
    user_seq = int(payload.get("user_seq") or 0)
    title = str(payload.get("review_title") or "").strip()
    content = str(payload.get("review_content") or "").strip()
    rating = int(payload.get("review_rating") or 5)

    if review_seq <= 0 or user_seq <= 0 or not title or not content:
        raise HTTPException(status_code=400, detail="후기 수정 정보가 부족합니다.")

    image_path = (
        save_review_image(payload.get("review_image"))
        if payload.get("review_image")
        else None
    )
    db = await get_pool()
    async with db.acquire() as conn:
        try:
            await conn.begin()
            async with conn.cursor() as cur:
                if image_path:
                    await cur.execute(
                        """
                        UPDATE review
                        SET review_title = %s, review_content = %s, review_image = %s, review_rating = %s
                        WHERE review_seq = %s AND user_seq = %s
                        """,
                        (
                            title[:100],
                            content,
                            image_path,
                            rating,
                            review_seq,
                            user_seq,
                        ),
                    )
                else:
                    await cur.execute(
                        """
                        UPDATE review
                        SET review_title = %s, review_content = %s, review_rating = %s
                        WHERE review_seq = %s AND user_seq = %s
                        """,
                        (title[:100], content, rating, review_seq, user_seq),
                    )
                if cur.rowcount == 0:
                    raise HTTPException(
                        status_code=404, detail="수정할 후기를 찾을 수 없습니다."
                    )
            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    review = await fetch_one(
        """
        SELECT
            r.review_seq,
            r.product_seq,
            r.user_seq,
            r.buy_seq,
            r.review_title,
            r.review_content,
            r.review_image,
            r.review_rating,
            COALESCE(r.review_like, 0) AS review_like,
            DATE_FORMAT(r.review_date, '%%Y-%%m-%%d') AS review_date,
            p.product_name,
            u.user_name
        FROM review r
        LEFT JOIN product p ON p.product_seq = r.product_seq
        LEFT JOIN users u ON u.user_seq = r.user_seq
        WHERE r.review_seq = %s
        LIMIT 1
        """,
        (review_seq,),
    )
    return review or {"review_seq": review_seq}


@app.delete("/reviews/{review_seq}")
async def delete_review(review_seq: int, user_seq: int) -> Dict[str, str]:
    return await delete_review_for_user(review_seq, user_seq)


@app.delete("/reviews/{review_seq}/users/{user_seq}")
async def delete_review_with_user_path(
    review_seq: int, user_seq: int
) -> Dict[str, str]:
    return await delete_review_for_user(review_seq, user_seq)


async def delete_review_for_user(review_seq: int, user_seq: int) -> Dict[str, str]:
    if review_seq <= 0 or user_seq <= 0:
        raise HTTPException(status_code=400, detail="삭제할 후기 정보가 부족합니다.")

    db = await get_pool()
    async with db.acquire() as conn:
        try:
            await conn.begin()
            async with conn.cursor() as cur:
                await cur.execute(
                    "DELETE FROM review WHERE review_seq = %s AND user_seq = %s",
                    (review_seq, user_seq),
                )
                if cur.rowcount == 0:
                    raise HTTPException(
                        status_code=404, detail="삭제할 후기를 찾을 수 없습니다."
                    )
            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    return {"message": "후기가 삭제되었습니다."}


async def handle_check_user_id(payload: Dict[str, Any]) -> Dict[str, Any]:
    user_id = str(payload.get("user_id") or "").strip()
    if not is_valid_email(user_id):
        raise HTTPException(
            status_code=400, detail="이메일 형식의 아이디를 입력해주세요."
        )

    row = await fetch_one(
        "SELECT user_seq FROM users WHERE user_id = %s LIMIT 1", (user_id,)
    )
    exists = row is not None
    return {
        "available": not exists,
        "exists": exists,
        "is_duplicate": exists,
        "message": (
            "이미 사용 중인 아이디입니다." if exists else "사용 가능한 아이디입니다."
        ),
    }


@app.post("/auth/check-id")
async def auth_check_id(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    return await handle_check_user_id(payload)


@app.post("/auth/check-user-id")
async def auth_check_user_id(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    return await handle_check_user_id(payload)


@app.post("/users/check-id")
async def users_check_id(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    return await handle_check_user_id(payload)


@app.post("/auth/login")
async def login(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    user_id = str(payload.get("user_id") or "").strip()
    user_pw = str(payload.get("user_pw") or "")

    if not user_id or not user_pw:
        raise HTTPException(status_code=400, detail="아이디와 비밀번호를 확인해주세요.")

    user = await fetch_one(
        """
        SELECT user_seq, user_name, user_id, user_phone, quick_pin_hash
        FROM users
        WHERE user_id = %s AND user_pw = %s
        LIMIT 1
        """,
        (user_id, user_pw),
    )
    if not user:
        raise HTTPException(
            status_code=401, detail="아이디 또는 비밀번호가 올바르지 않습니다."
        )

    return user


@app.post("/auth/find-id")
async def find_id(payload: Dict[str, Any] = Body(...)) -> Dict[str, str]:
    user_name = str(payload.get("user_name") or "").strip()
    user_phone = str(payload.get("user_phone") or "").strip()

    if not user_name or not user_phone:
        raise HTTPException(status_code=400, detail="이름과 전화번호를 입력해주세요.")

    user = await fetch_one(
        """
        SELECT user_id
        FROM users
        WHERE user_name = %s
          AND REPLACE(COALESCE(user_phone, ''), '-', '') = REPLACE(%s, '-', '')
        LIMIT 1
        """,
        (user_name, user_phone),
    )
    if not user:
        raise HTTPException(status_code=404, detail="일치하는 계정을 찾을 수 없습니다.")

    return {"user_id": str(user["user_id"]), "message": "가입 아이디를 찾았습니다."}


@app.post("/auth/reset-password")
async def reset_password(payload: Dict[str, Any] = Body(...)) -> Dict[str, str]:
    user_id = str(payload.get("user_id") or "").strip()
    user_pw = str(payload.get("user_pw") or "")

    if not is_valid_email(user_id) or not user_pw:
        raise HTTPException(
            status_code=400, detail="아이디와 새 비밀번호를 확인해주세요."
        )
    if len(user_pw) < 8 or re.search(r"[A-Za-z]", user_pw) is None:
        raise HTTPException(
            status_code=400, detail="비밀번호는 8자 이상, 영문 포함이어야 합니다."
        )

    verified_at = verified_emails.get(user_id)
    if not verified_at or time.time() - verified_at > 600:
        raise HTTPException(status_code=403, detail="이메일 인증을 먼저 완료해주세요.")

    db = await get_pool()
    async with db.acquire() as conn:
        try:
            await conn.begin()
            async with conn.cursor() as cur:
                await cur.execute(
                    "UPDATE users SET user_pw = %s WHERE user_id = %s",
                    (user_pw, user_id),
                )
                if cur.rowcount == 0:
                    raise HTTPException(
                        status_code=404, detail="일치하는 계정을 찾을 수 없습니다."
                    )
            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    verified_emails.pop(user_id, None)
    return {"message": "비밀번호가 변경되었습니다."}


@app.post("/auth/signup")
async def signup(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    user_id = str(payload.get("user_id") or "").strip()
    user_pw = str(payload.get("user_pw") or "")
    user_name = str(payload.get("user_name") or "").strip()
    user_phone = str(payload.get("user_phone") or "").strip()

    if not is_valid_email(user_id) or not user_pw or not user_name:
        raise HTTPException(status_code=400, detail="회원가입 정보를 확인해주세요.")

    verified_at = verified_emails.get(user_id)
    if require_email_verification_for_signup and (
        not verified_at or time.time() - verified_at > 600
    ):
        raise HTTPException(status_code=403, detail="이메일 인증을 먼저 완료해주세요.")

    db = await get_pool()
    async with db.acquire() as conn:
        try:
            await conn.begin()
            async with conn.cursor() as cur:
                await cur.execute(
                    "SELECT user_seq FROM users WHERE user_id = %s LIMIT 1", (user_id,)
                )
                if await cur.fetchone():
                    raise HTTPException(
                        status_code=409, detail="이미 사용 중인 아이디입니다."
                    )

                await cur.execute(
                    """
                    INSERT INTO users (user_name, user_phone, user_id, user_pw, user_date)
                    VALUES (%s, %s, %s, %s, NOW())
                    """,
                    (user_name, user_phone, user_id, user_pw),
                )
                user_seq = int(cur.lastrowid)
            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    verified_emails.pop(user_id, None)
    user = await fetch_one(
        "SELECT user_seq, user_name, user_id, user_phone, quick_pin_hash FROM users WHERE user_seq = %s LIMIT 1",
        (user_seq,),
    )
    return user


@app.post("/auth/email/send-code")
async def send_email_code(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    email = str(payload.get("email") or "").strip().lower()
    if not is_valid_email(email):
        raise HTTPException(status_code=400, detail="이메일 형식을 확인해주세요.")

    now = time.time()
    last_sent = email_code_cooldown.get(email)
    if last_sent and now - last_sent < 60:
        raise HTTPException(
            status_code=429, detail="인증번호는 60초 후 다시 요청할 수 있습니다."
        )

    code = create_verification_code()
    email_verification_codes[email] = {"code": code, "expires_at": now + 300}
    email_code_cooldown[email] = now
    return {"message": "인증번호가 발송되었습니다.", "verification_code": code}


@app.post("/auth/email/verify-code")
async def verify_email_code(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    email = str(payload.get("email") or "").strip().lower()
    code = str(payload.get("code") or "").strip()
    record = email_verification_codes.get(email)

    if not require_email_verification_for_signup and code:
        verified_emails[email] = time.time()
        email_verification_codes.pop(email, None)
        return {"message": "이메일 인증이 완료되었습니다."}

    if not record or record["expires_at"] < time.time():
        raise HTTPException(status_code=400, detail="인증번호가 만료되었습니다.")
    if record["code"] != code:
        raise HTTPException(status_code=400, detail="인증번호가 올바르지 않습니다.")

    verified_emails[email] = time.time()
    email_verification_codes.pop(email, None)
    return {"message": "이메일 인증이 완료되었습니다."}


@app.get("/users/{user_seq}")
async def get_user(user_seq: int) -> Dict[str, Any]:
    user = await fetch_one(
        """
        SELECT user_seq, user_name, user_id, user_phone, quick_pin_hash
        FROM users
        WHERE user_seq = %s
        LIMIT 1
        """,
        (user_seq,),
    )
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    return user


async def update_quick_pin(user_seq: int, payload: Dict[str, Any]) -> Dict[str, str]:
    quick_pin_hash = str(payload.get("quick_pin_hash") or "").strip()
    if not re.match(r"^[a-fA-F0-9]{64}$", quick_pin_hash):
        raise HTTPException(
            status_code=400, detail="간편 비밀번호 정보가 올바르지 않습니다."
        )

    db = await get_pool()
    async with db.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute(
                "UPDATE users SET quick_pin_hash = %s WHERE user_seq = %s",
                (quick_pin_hash, user_seq),
            )
            await conn.commit()
            if cur.rowcount == 0:
                raise HTTPException(
                    status_code=404, detail="사용자를 찾을 수 없습니다."
                )
    return {"message": "간편 비밀번호가 저장되었습니다."}


@app.patch("/users/{user_seq}/quick-pin")
async def patch_quick_pin(
    user_seq: int, payload: Dict[str, Any] = Body(...)
) -> Dict[str, str]:
    return await update_quick_pin(user_seq, payload)


@app.patch("/users/{user_seq}/pin")
async def patch_pin(
    user_seq: int, payload: Dict[str, Any] = Body(...)
) -> Dict[str, str]:
    return await update_quick_pin(user_seq, payload)


@app.get("/users/{user_seq}/dogs")
async def get_dogs(user_seq: int) -> List[Dict[str, Any]]:
    return await fetch_all(
        """
        SELECT
            d.dog_seq,
            d.dog_name,
            d.dog_image,
            db.dog_breeds_name AS breed_name,
            da.dog_age AS age_name,
            d.dog_weight AS weight_text,
            dc.dog_color_name AS color_name
        FROM dog d
        LEFT JOIN dog_breeds db ON db.dog_breeds_seq = d.dog_breeds_seq
        LEFT JOIN dog_age da ON da.dog_age_seq = d.dog_age_seq
        LEFT JOIN dog_color dc ON dc.dog_color_seq = d.dog_color_seq
        WHERE d.user_seq = %s
        ORDER BY d.dog_seq DESC
        """,
        (user_seq,),
    )


@app.post("/users/{user_seq}/dogs")
async def create_dog(
    user_seq: int, payload: Dict[str, Any] = Body(...)
) -> Dict[str, Any]:
    dog_name = str(payload.get("dog_name") or "").strip()
    breed_name = str(
        payload.get("breed_name") or payload.get("dog_breed") or ""
    ).strip()
    age_name = str(payload.get("age_name") or payload.get("dog_age") or "").strip()
    color_name = str(
        payload.get("color_name") or payload.get("dog_color") or ""
    ).strip()
    weight_text = str(
        payload.get("weight_text") or payload.get("dog_weight") or ""
    ).strip()
    weight = parse_dog_weight(weight_text)
    image_path = save_dog_image(payload.get("dog_image"))

    if not dog_name or not breed_name:
        raise HTTPException(
            status_code=400, detail="강아지 이름과 견종을 입력해주세요."
        )

    db = await get_pool()
    async with db.acquire() as conn:
        try:
            await conn.begin()
            async with conn.cursor() as cur:
                await cur.execute(
                    "SELECT user_seq FROM users WHERE user_seq = %s LIMIT 1",
                    (user_seq,),
                )
                if not await cur.fetchone():
                    raise HTTPException(
                        status_code=404, detail="사용자를 찾을 수 없습니다."
                    )

            breed_seq = await find_or_create_lookup(
                conn, "dog_breeds", "dog_breeds_seq", "dog_breeds_name", breed_name
            )
            age_seq = await find_or_create_lookup(
                conn, "dog_age", "dog_age_seq", "dog_age", age_name
            )
            color_seq = await find_or_create_lookup(
                conn, "dog_color", "dog_color_seq", "dog_color_name", color_name
            )

            async with conn.cursor() as cur:
                await cur.execute(
                    """
                    INSERT INTO dog
                        (dog_name, dog_image, user_seq, dog_weight, dog_breeds_seq, dog_age_seq, dog_color_seq)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        dog_name,
                        image_path,
                        user_seq,
                        weight,
                        breed_seq,
                        age_seq,
                        color_seq,
                    ),
                )
                dog_seq = int(cur.lastrowid)
            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    dog = await fetch_one(
        """
        SELECT
            d.dog_seq,
            d.dog_name,
            d.dog_image,
            db.dog_breeds_name AS breed_name,
            da.dog_age AS age_name,
            d.dog_weight AS weight_text,
            dc.dog_color_name AS color_name
        FROM dog d
        LEFT JOIN dog_breeds db ON db.dog_breeds_seq = d.dog_breeds_seq
        LEFT JOIN dog_age da ON da.dog_age_seq = d.dog_age_seq
        LEFT JOIN dog_color dc ON dc.dog_color_seq = d.dog_color_seq
        WHERE d.dog_seq = %s
        LIMIT 1
        """,
        (dog_seq,),
    )
    if dog:
        dog["weight_text"] = weight_text or str(dog.get("weight_text") or "")
        return dog
    return {"dog_seq": dog_seq, "dog_name": dog_name, "weight_text": weight_text}


@app.patch("/users/{user_seq}/dogs/{dog_seq}")
async def update_dog(
    user_seq: int, dog_seq: int, payload: Dict[str, Any] = Body(...)
) -> Dict[str, Any]:
    dog_name = str(payload.get("dog_name") or "").strip()
    breed_name = str(
        payload.get("breed_name") or payload.get("dog_breed") or ""
    ).strip()
    age_name = str(payload.get("age_name") or payload.get("dog_age") or "").strip()
    color_name = str(
        payload.get("color_name") or payload.get("dog_color") or ""
    ).strip()
    weight_text = str(
        payload.get("weight_text") or payload.get("dog_weight") or ""
    ).strip()
    weight = parse_dog_weight(weight_text)
    has_image_payload = "dog_image" in payload and bool(payload.get("dog_image"))
    image_path = save_dog_image(payload.get("dog_image")) if has_image_payload else None

    if not dog_name or not breed_name:
        raise HTTPException(
            status_code=400, detail="강아지 이름과 견종을 입력해주세요."
        )

    db = await get_pool()
    async with db.acquire() as conn:
        try:
            await conn.begin()
            async with conn.cursor() as cur:
                await cur.execute(
                    "SELECT dog_seq FROM dog WHERE dog_seq = %s AND user_seq = %s LIMIT 1",
                    (dog_seq, user_seq),
                )
                if not await cur.fetchone():
                    raise HTTPException(
                        status_code=404, detail="수정할 강아지를 찾을 수 없습니다."
                    )

            breed_seq = await find_or_create_lookup(
                conn, "dog_breeds", "dog_breeds_seq", "dog_breeds_name", breed_name
            )
            age_seq = await find_or_create_lookup(
                conn, "dog_age", "dog_age_seq", "dog_age", age_name
            )
            color_seq = await find_or_create_lookup(
                conn, "dog_color", "dog_color_seq", "dog_color_name", color_name
            )

            async with conn.cursor() as cur:
                if image_path:
                    await cur.execute(
                        """
                        UPDATE dog
                        SET dog_name = %s,
                            dog_image = %s,
                            dog_weight = %s,
                            dog_breeds_seq = %s,
                            dog_age_seq = %s,
                            dog_color_seq = %s
                        WHERE dog_seq = %s AND user_seq = %s
                        """,
                        (
                            dog_name,
                            image_path,
                            weight,
                            breed_seq,
                            age_seq,
                            color_seq,
                            dog_seq,
                            user_seq,
                        ),
                    )
                else:
                    await cur.execute(
                        """
                        UPDATE dog
                        SET dog_name = %s,
                            dog_weight = %s,
                            dog_breeds_seq = %s,
                            dog_age_seq = %s,
                            dog_color_seq = %s
                        WHERE dog_seq = %s AND user_seq = %s
                        """,
                        (
                            dog_name,
                            weight,
                            breed_seq,
                            age_seq,
                            color_seq,
                            dog_seq,
                            user_seq,
                        ),
                    )
            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    dog = await fetch_one(
        """
        SELECT
            d.dog_seq,
            d.dog_name,
            d.dog_image,
            db.dog_breeds_name AS breed_name,
            da.dog_age AS age_name,
            d.dog_weight AS weight_text,
            dc.dog_color_name AS color_name
        FROM dog d
        LEFT JOIN dog_breeds db ON db.dog_breeds_seq = d.dog_breeds_seq
        LEFT JOIN dog_age da ON da.dog_age_seq = d.dog_age_seq
        LEFT JOIN dog_color dc ON dc.dog_color_seq = d.dog_color_seq
        WHERE d.dog_seq = %s AND d.user_seq = %s
        LIMIT 1
        """,
        (dog_seq, user_seq),
    )
    if dog:
        dog["weight_text"] = weight_text or str(dog.get("weight_text") or "")
        return dog
    return {"dog_seq": dog_seq, "dog_name": dog_name, "weight_text": weight_text}


@app.delete("/users/{user_seq}/dogs/{dog_seq}")
async def delete_dog(user_seq: int, dog_seq: int) -> Dict[str, str]:
    db = await get_pool()
    async with db.acquire() as conn:
        async with conn.cursor() as cur:
            await cur.execute(
                "DELETE FROM dog WHERE dog_seq = %s AND user_seq = %s",
                (dog_seq, user_seq),
            )
            await conn.commit()
            if cur.rowcount == 0:
                raise HTTPException(
                    status_code=404, detail="삭제할 강아지를 찾을 수 없습니다."
                )
    return {"message": "강아지 정보가 삭제되었습니다."}


@app.get("/users/{user_seq}/purchases")
async def get_purchases(user_seq: int) -> List[Dict[str, Any]]:
    return await fetch_all(
        """
        SELECT
            b.buy_seq,
            DATE_FORMAT(b.buy_date, '%%Y-%%m-%%d') AS buy_date,
            b.buy_qty,
            b.buy_price,
            b.product_seq,
            b.user_seq,
            CASE
                WHEN b.buy_status = 'shipping' AND b.buy_date <= DATE_SUB(NOW(), INTERVAL 1 DAY)
                THEN 'delivered'
                ELSE b.buy_status
            END AS buy_status,
            CASE WHEN r.review_seq IS NULL THEN 0 ELSE 1 END AS has_review
        FROM buy b
        LEFT JOIN review r ON r.buy_seq = b.buy_seq
        WHERE b.user_seq = %s
        ORDER BY b.buy_seq DESC
        """,
        (user_seq,),
    )


@app.post("/users/{user_seq}/purchases")
async def create_purchase(
    user_seq: int, payload: Dict[str, Any] = Body(...)
) -> Dict[str, Any]:
    items = payload.get("items")
    if not isinstance(items, list) or not items:
        raise HTTPException(status_code=400, detail="구매할 상품이 없습니다.")

    parsed_address = parse_delivery_address(payload.get("address"))
    inserted_purchases: List[Dict[str, Any]] = []
    db = await get_pool()
    async with db.acquire() as conn:
        try:
            await conn.begin()
            async with conn.cursor() as cur:
                await cur.execute(
                    "SELECT user_seq FROM users WHERE user_seq = %s LIMIT 1",
                    (user_seq,),
                )
                if not await cur.fetchone():
                    raise HTTPException(
                        status_code=404, detail="사용자를 찾을 수 없습니다."
                    )

                for item in items:
                    product_seq = int(item.get("product_seq") or 0)
                    quantity = max(
                        1, int(item.get("quantity") or item.get("buy_qty") or 1)
                    )
                    price = int(
                        item.get("price")
                        or item.get("product_price")
                        or item.get("buy_price")
                        or 0
                    )
                    if product_seq <= 0:
                        raise HTTPException(
                            status_code=400,
                            detail="구매 상품 정보가 올바르지 않습니다.",
                        )

                    await cur.execute(
                        """
                        INSERT INTO buy (buy_date, buy_qty, buy_price, product_seq, user_seq, buy_status, status_updated_at)
                        VALUES (NOW(), %s, %s, %s, %s, 'shipping', NOW())
                        """,
                        (quantity, price * quantity, product_seq, user_seq),
                    )
                    inserted_purchases.append(
                        {
                            "buy_seq": int(cur.lastrowid),
                            "product_seq": product_seq,
                            "user_seq": user_seq,
                            "buy_qty": quantity,
                            "buy_price": price * quantity,
                            "buy_status": "shipping",
                        }
                    )

                if parsed_address["address"]:
                    await cur.execute(
                        """
                        SELECT address_seq
                        FROM address
                        WHERE user_seq = %s AND TRIM(address) = TRIM(%s)
                        LIMIT 1
                        """,
                        (user_seq, parsed_address["address"]),
                    )
                    existing_address = await cur.fetchone()
                    if existing_address:
                        await cur.execute(
                            "UPDATE address SET address_name = %s WHERE address_seq = %s",
                            (
                                parsed_address["address_name"],
                                existing_address["address_seq"],
                            ),
                        )
                    else:
                        await cur.execute(
                            "INSERT INTO address (user_seq, address_name, address) VALUES (%s, %s, %s)",
                            (
                                user_seq,
                                parsed_address["address_name"],
                                parsed_address["address"],
                            ),
                        )

            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    return {
        "message": "구매가 완료되었습니다.",
        "buy_seq_list": [purchase["buy_seq"] for purchase in inserted_purchases],
        "purchases": inserted_purchases,
    }


@app.patch("/users/{user_seq}/purchases/{buy_seq}/status")
async def update_purchase_status(
    user_seq: int, buy_seq: int, payload: Dict[str, Any] = Body(...)
) -> Dict[str, Any]:
    action = str(payload.get("action") or "").strip().lower()
    status_by_action = {
        "cancel": "canceled",
        "receive": "delivered",
        "deliver": "delivered",
        "confirm": "confirmed",
        "refund": "refund_requested",
    }
    next_status = status_by_action.get(action)
    if next_status is None:
        raise HTTPException(
            status_code=400, detail="지원하지 않는 주문 상태 변경입니다."
        )

    db = await get_pool()
    async with db.acquire() as conn:
        try:
            await conn.begin()
            async with conn.cursor() as cur:
                await cur.execute(
                    """
                    SELECT
                        buy_seq,
                        buy_status,
                        buy_date,
                        CASE
                            WHEN buy_status = 'shipping' AND buy_date <= DATE_SUB(NOW(), INTERVAL 1 DAY)
                            THEN 'delivered'
                            ELSE buy_status
                        END AS effective_status
                    FROM buy
                    WHERE buy_seq = %s AND user_seq = %s
                    LIMIT 1
                    """,
                    (buy_seq, user_seq),
                )
                row = await cur.fetchone()
                if not row:
                    raise HTTPException(
                        status_code=404, detail="주문을 찾을 수 없습니다."
                    )

                effective_status = row.get("effective_status")
                if action == "cancel" and effective_status != "shipping":
                    raise HTTPException(
                        status_code=400,
                        detail="배송 완료 후에는 주문 취소를 할 수 없습니다.",
                    )
                if action in {"receive", "deliver"} and effective_status != "shipping":
                    raise HTTPException(
                        status_code=400,
                        detail="배송 중인 주문만 수령 완료로 변경할 수 있습니다.",
                    )
                if action in {"confirm", "refund"} and effective_status not in {
                    "delivered",
                    "confirmed",
                }:
                    raise HTTPException(
                        status_code=400, detail="배송 완료 후에 처리할 수 있습니다."
                    )
                if effective_status in {"canceled", "refunded", "refund_requested"}:
                    raise HTTPException(
                        status_code=400, detail="이미 처리된 주문입니다."
                    )

                await cur.execute(
                    "UPDATE buy SET buy_status = %s, status_updated_at = NOW() WHERE buy_seq = %s AND user_seq = %s",
                    (next_status, buy_seq, user_seq),
                )
                if action == "refund":
                    await cur.execute(
                        "SELECT refund_seq FROM refund WHERE buy_seq = %s LIMIT 1",
                        (buy_seq,),
                    )
                    existing_refund = await cur.fetchone()
                    if existing_refund:
                        await cur.execute(
                            """
                            UPDATE refund
                            SET user_seq = %s,
                                refund_date = NOW(),
                                refund_state = 'requested'
                            WHERE buy_seq = %s
                            """,
                            (user_seq, buy_seq),
                        )
                    else:
                        await cur.execute(
                            """
                            INSERT INTO refund (buy_seq, user_seq, refund_date, refund_state)
                            VALUES (%s, %s, NOW(), 'requested')
                            """,
                            (buy_seq, user_seq),
                        )
            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    return {
        "message": "주문 상태가 변경되었습니다.",
        "buy_seq": buy_seq,
        "buy_status": next_status,
    }


@app.patch("/staff/refunds/{buy_seq}/approve")
async def approve_refund(buy_seq: int) -> Dict[str, Any]:
    db = await get_pool()
    async with db.acquire() as conn:
        try:
            await conn.begin()
            async with conn.cursor() as cur:
                await cur.execute(
                    """
                    SELECT buy_seq, user_seq, buy_status
                    FROM buy
                    WHERE buy_seq = %s
                    LIMIT 1
                    """,
                    (buy_seq,),
                )
                row = await cur.fetchone()
                if not row:
                    raise HTTPException(status_code=404, detail="주문을 찾을 수 없습니다.")
                if row.get("buy_status") != "refund_requested":
                    raise HTTPException(status_code=400, detail="환불 요청 상태의 주문만 승인할 수 있습니다.")

                await cur.execute(
                    """
                    UPDATE buy
                    SET buy_status = 'refunded',
                        status_updated_at = NOW()
                    WHERE buy_seq = %s
                    """,
                    (buy_seq,),
                )
                await cur.execute(
                    """
                    UPDATE refund
                    SET refund_state = 'approved',
                        refund_date = NOW()
                    WHERE buy_seq = %s
                    """,
                    (buy_seq,),
                )
                if cur.rowcount == 0:
                    await cur.execute(
                        """
                        INSERT INTO refund (buy_seq, user_seq, refund_date, refund_state)
                        VALUES (%s, %s, NOW(), 'approved')
                        """,
                        (buy_seq, row["user_seq"]),
                    )
            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    return {"message": "환불이 승인되었습니다.", "buy_seq": buy_seq, "buy_status": "refunded"}


@app.get("/users/{user_seq}/addresses")
async def get_addresses(user_seq: int) -> List[Dict[str, Any]]:
    rows = await fetch_all(
        """
        SELECT address_seq, address_name, address
        FROM address
        WHERE user_seq = %s
          AND address IS NOT NULL
          AND TRIM(address) <> ''
        ORDER BY address_seq DESC
        """,
        (user_seq,),
    )
    seen = set()
    unique_rows = []
    for row in rows:
        key = str(row.get("address") or "").strip()
        if key and key not in seen:
            seen.add(key)
            unique_rows.append(row)
    return unique_rows


@app.get("/users/{user_seq}/notifications")
async def get_notifications(user_seq: int) -> List[Dict[str, Any]]:
    purchases = await fetch_all(
        """
        SELECT
            b.buy_seq,
            DATE_FORMAT(b.buy_date, '%%Y-%%m-%%d') AS buy_date,
            b.buy_qty,
            p.product_name
        FROM buy b
        LEFT JOIN product p ON p.product_seq = b.product_seq
        WHERE b.user_seq = %s
        ORDER BY b.buy_seq DESC
        LIMIT 5
        """,
        (user_seq,),
    )
    reviews = await fetch_all(
        """
        SELECT
            r.review_seq,
            DATE_FORMAT(r.review_date, '%%Y-%%m-%%d') AS review_date,
            r.review_content,
            p.product_name
        FROM review r
        LEFT JOIN product p ON p.product_seq = r.product_seq
        WHERE r.user_seq = %s
        ORDER BY r.review_seq DESC
        LIMIT 5
        """,
        (user_seq,),
    )

    notifications: List[Dict[str, Any]] = []
    for purchase in purchases:
        notifications.append(
            {
                "id": f"buy-{purchase['buy_seq']}",
                "category": "주문",
                "title": f"{purchase.get('product_name') or '상품'} 주문 내역",
                "detail": f"{purchase.get('buy_date') or ''} · {purchase.get('buy_qty') or 1}개 구매",
                "is_new": 1,
            }
        )

    for review in reviews:
        content = str(review.get("review_content") or "")
        notifications.append(
            {
                "id": f"review-{review['review_seq']}",
                "category": "리뷰",
                "title": f"{review.get('product_name') or '상품'} 리뷰 등록",
                "detail": content[:30],
                "is_new": 0,
            }
        )

    return notifications[:10]


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("server:app", host="0.0.0.0", port=8000, reload=True)
