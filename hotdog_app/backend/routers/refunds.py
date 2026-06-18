from fastapi import APIRouter, Body, HTTPException, Query

from database import fetch_query, get_connection
from refund_state import REFUND_STATE_LABELS, RefundState

router = APIRouter()


@router.get("/")
def get_refunds(limit: int = Query(default=100, ge=1, le=500)):
    refunds = fetch_query(
        """
        SELECT
            CAST(r.refund_seq AS CHAR) AS id,
            r.refund_seq AS refundSeq,
            r.buy_seq AS buySeq,
            r.user_seq AS userSeq,
            CONCAT('SO-', COALESCE(b.buy_seq, r.buy_seq)) AS orderNumber,
            u.user_name AS memberName,
            p.product_name AS itemName,
            COALESCE(b.buy_qty, 0) AS quantity,
            COALESCE(b.buy_price, 0) AS amount,
            b.buy_date AS orderedAt,
            b.buy_status AS orderStatus,
            r.refund_state AS rawStatus,
            COALESCE(r.refund_details, '') AS refundDetails,
            r.refund_date AS requestedAt
        FROM refund r
        LEFT JOIN buy b ON b.buy_seq = r.buy_seq
        LEFT JOIN users u ON u.user_seq = r.user_seq
        LEFT JOIN product p ON p.product_seq = b.product_seq
        ORDER BY r.refund_date DESC, r.refund_seq DESC
        LIMIT %s
        """,
        (limit,),
    )

    for refund in refunds:
        try:
            state = RefundState(int(refund["rawStatus"]))
        except (KeyError, TypeError, ValueError):
            state = RefundState.REQUESTED
        refund["status"] = REFUND_STATE_LABELS[state]

    return refunds


@router.patch("/{refund_seq}/status")
def update_refund_status(refund_seq: int, payload: dict = Body(...)):
    action = str(payload.get("action") or "").strip().lower()
    state_by_action = {
        "approve": RefundState.CONFIRMED,
        "approved": RefundState.CONFIRMED,
        "process": RefundState.CONFIRMED,
        "hold": RefundState.ON_HOLD,
        "pending": RefundState.ON_HOLD,
        "cancel": RefundState.CANCELED,
        "canceled": RefundState.CANCELED,
    }
    next_state = state_by_action.get(action)

    if next_state is None:
        raise HTTPException(status_code=400, detail="지원하지 않는 환불 처리입니다.")

    buy_status_by_state = {
        RefundState.CONFIRMED: "refunded",
        RefundState.ON_HOLD: "refund_requested",
        RefundState.CANCELED: "confirmed",
    }

    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT refund_seq, buy_seq
                    FROM refund
                    WHERE refund_seq = %s
                    LIMIT 1
                    """,
                    (refund_seq,),
                )
                refund = cursor.fetchone()

                if refund is None:
                    raise HTTPException(status_code=404, detail="환불 건을 찾을 수 없습니다.")

                cursor.execute(
                    """
                    UPDATE refund
                    SET refund_state = %s,
                        refund_date = NOW()
                    WHERE refund_seq = %s
                    """,
                    (next_state.value, refund_seq),
                )
                cursor.execute(
                    """
                    UPDATE buy
                    SET buy_status = %s,
                        status_updated_at = NOW()
                    WHERE buy_seq = %s
                    """,
                    (buy_status_by_state[next_state], refund["buy_seq"]),
                )
            connection.commit()
    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(status_code=500, detail=str(error)) from error

    return {
        "message": "환불 상태가 변경되었습니다.",
        "refund_seq": refund_seq,
        "refund_state": next_state.value,
    }
