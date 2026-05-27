from fastapi import APIRouter, Query

from database import fetch_query

router = APIRouter()


@router.get("/")
def get_sales_orders(limit: int = Query(default=100, ge=1, le=500)):
    return fetch_query(
        """
        SELECT
            CAST(b.buy_seq AS CHAR) AS id,
            CONCAT('SO-', DATE_FORMAT(b.buy_date, '%%Y%%m%%d'), '-', LPAD(b.buy_seq, 3, '0')) AS orderNumber,
            p.product_name AS itemName,
            u.user_name AS memberName,
            COALESCE(b.buy_price, 0) AS totalPrice,
            '결제완료' AS status,
            b.buy_date AS orderedAt
        FROM buy b
        JOIN product p ON p.product_seq = b.product_seq
        JOIN users u ON u.user_seq = b.user_seq
        ORDER BY b.buy_date DESC, b.buy_seq DESC
        LIMIT %s
        """,
        (limit,),
    )
