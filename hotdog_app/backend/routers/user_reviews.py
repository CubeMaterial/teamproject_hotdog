from typing import Any, Dict, List

from fastapi import APIRouter, Body, HTTPException

from user_common import fetch_all, fetch_one, get_pool, save_review_image

router = APIRouter(tags=["user-reviews"])

@router.get("/reviews")
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


@router.post("/reviews")
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


@router.post("/reviews/{review_seq}/like")
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


@router.patch("/reviews/{review_seq}")
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


@router.delete("/reviews/{review_seq}")
async def delete_review(review_seq: int, user_seq: int) -> Dict[str, str]:
    return await delete_review_for_user(review_seq, user_seq)


@router.delete("/reviews/{review_seq}/users/{user_seq}")
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
