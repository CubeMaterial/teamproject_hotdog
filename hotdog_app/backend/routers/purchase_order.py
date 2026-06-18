from datetime import date

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from database import fetch_query, get_connection

router = APIRouter()


class PurchaseOrderCreateRequest(BaseModel):
    vendor: str
    item_name: str
    quantity: int
    created_at: date


def _purchase_order_query(where_clause: str = "") -> str:
    return f"""
        SELECT
            CAST(o.order_seq AS CHAR) AS id,
            COALESCE(m.maker_name, '미지정') AS vendor,
            p.product_name AS itemName,
            COALESCE(o.order_qty, 0) AS quantity,
            CASE
                WHEN o.order_done = 1 THEN '입고완료'
                ELSE '발주'
            END AS status,
            o.order_date AS createdAt
        FROM orders o
        JOIN product p ON p.product_seq = o.product_seq
        LEFT JOIN maker m ON m.maker_seq = o.maker_seq
        {where_clause}
    """


@router.get("/")
def get_purchase_orders(limit: int = Query(default=100, ge=1, le=500)):
    return fetch_query(
        _purchase_order_query(
            "ORDER BY o.order_date DESC, o.order_seq DESC LIMIT %s"
        ),
        (limit,),
    )


@router.post("/")
def create_purchase_order(request: PurchaseOrderCreateRequest):
    vendor = request.vendor.strip()
    item_name = request.item_name.strip()

    if not vendor:
        raise HTTPException(status_code=400, detail="거래처를 입력해주세요.")
    if not item_name:
        raise HTTPException(status_code=400, detail="품목을 입력해주세요.")
    if request.quantity <= 0:
        raise HTTPException(status_code=400, detail="수량은 1 이상이어야 합니다.")

    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT maker_seq
                    FROM maker
                    WHERE maker_name = %s
                    LIMIT 1
                    """,
                    (vendor,),
                )
                maker = cursor.fetchone()
                if maker is None:
                    raise HTTPException(
                        status_code=400,
                        detail="등록된 거래처명을 정확히 입력해주세요.",
                    )

                cursor.execute(
                    """
                    SELECT product_seq
                    FROM product
                    WHERE product_name = %s
                    LIMIT 1
                    """,
                    (item_name,),
                )
                product = cursor.fetchone()
                if product is None:
                    raise HTTPException(
                        status_code=400,
                        detail="등록된 품목명을 정확히 입력해주세요.",
                    )

                cursor.execute(
                    """
                    INSERT INTO orders (
                        order_date,
                        order_qty,
                        maker_seq,
                        order_done,
                        product_seq
                    )
                    VALUES (%s, %s, %s, 0, %s)
                    """,
                    (
                        request.created_at,
                        request.quantity,
                        maker["maker_seq"],
                        product["product_seq"],
                    ),
                )
                order_seq = cursor.lastrowid
            connection.commit()
    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(status_code=500, detail=str(error)) from error

    rows = fetch_query(
        _purchase_order_query("WHERE o.order_seq = %s LIMIT 1"),
        (order_seq,),
    )
    return rows[0]
