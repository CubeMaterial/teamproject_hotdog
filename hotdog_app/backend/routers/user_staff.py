from typing import Any, Dict

from fastapi import APIRouter, HTTPException

from refund_state import RefundState
from user_common import get_pool

router = APIRouter(tags=["user-staff"])

@router.patch("/staff/refunds/{buy_seq}/approve")
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
                    SET refund_state = %s,
                        refund_date = NOW()
                    WHERE buy_seq = %s
                    """,
                    (RefundState.CONFIRMED.value, buy_seq),
                )
                if cur.rowcount == 0:
                    await cur.execute(
                        """
                        INSERT INTO refund (buy_seq, user_seq, refund_date, refund_state)
                        VALUES (%s, %s, NOW(), %s)
                        """,
                        (
                            buy_seq,
                            row["user_seq"],
                            RefundState.CONFIRMED.value,
                        ),
                    )
            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    return {"message": "환불이 승인되었습니다.", "buy_seq": buy_seq, "buy_status": "refunded"}
