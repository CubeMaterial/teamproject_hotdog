from typing import Any, Dict, List

from fastapi import APIRouter, Body, HTTPException

from refund_state import RefundState
from user_common import fetch_all, get_pool, parse_delivery_address

router = APIRouter(tags=["user-purchases"])

@router.get("/users/{user_seq}/purchases")
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


@router.post("/users/{user_seq}/purchases")
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


@router.patch("/users/{user_seq}/purchases/{buy_seq}/status")
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

    refund_details = str(
        payload.get("refund_details")
        or payload.get("refund_reason")
        or payload.get("reason")
        or ""
    ).strip()
    if action == "refund" and not refund_details:
        raise HTTPException(status_code=400, detail="환불 사유를 입력해주세요.")

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
                                refund_state = %s,
                                refund_details = %s
                            WHERE buy_seq = %s
                            """,
                            (
                                user_seq,
                                RefundState.REQUESTED.value,
                                refund_details,
                                buy_seq,
                            ),
                        )
                    else:
                        await cur.execute(
                            """
                            INSERT INTO refund (buy_seq, user_seq, refund_date, refund_state, refund_details)
                            VALUES (%s, %s, NOW(), %s, %s)
                            """,
                            (
                                buy_seq,
                                user_seq,
                                RefundState.REQUESTED.value,
                                refund_details,
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
        "message": "주문 상태가 변경되었습니다.",
        "buy_seq": buy_seq,
        "buy_status": next_status,
    }
