from fastapi import APIRouter, Query

from database import fetch_query

router = APIRouter()


@router.get("/")
def get_purchase_orders(limit: int = Query(default=100, ge=1, le=500)):
    return fetch_query(
        """
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
        ORDER BY o.order_date DESC, o.order_seq DESC
        LIMIT %s
        """,
        (limit,),
    )
