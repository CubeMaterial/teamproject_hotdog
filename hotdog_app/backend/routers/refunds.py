from fastapi import APIRouter, Query

from database import fetch_query

router = APIRouter()


@router.get("/")
def get_refunds(limit: int = Query(default=100, ge=1, le=500)):
    return fetch_query(
        """
        SELECT
            CAST(r.refund_seq AS CHAR) AS id,
            CONCAT('SO-', COALESCE(b.buy_seq, r.buy_seq)) AS orderNumber,
            u.user_name AS memberName,
            COALESCE(b.buy_price, 0) AS amount,
            CASE
                WHEN r.refund_state = 1 THEN '완료'
                WHEN r.refund_state = 2 THEN '거절'
                ELSE '대기'
            END AS status,
            r.refund_date AS requestedAt
        FROM refund r
        LEFT JOIN buy b ON b.buy_seq = r.buy_seq
        LEFT JOIN users u ON u.user_seq = r.user_seq
        ORDER BY r.refund_date DESC, r.refund_seq DESC
        LIMIT %s
        """,
        (limit,),
    )
