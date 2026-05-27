import re
from typing import Any, Dict, List

from fastapi import APIRouter, Body, HTTPException

from user_common import (
    fetch_all,
    fetch_one,
    find_or_create_lookup,
    get_pool,
    parse_dog_weight,
    save_dog_image,
)

router = APIRouter(tags=["user-users"])

@router.get("/users/{user_seq}")
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


@router.patch("/users/{user_seq}/quick-pin")
async def patch_quick_pin(
    user_seq: int, payload: Dict[str, Any] = Body(...)
) -> Dict[str, str]:
    return await update_quick_pin(user_seq, payload)


@router.patch("/users/{user_seq}/pin")
async def patch_pin(
    user_seq: int, payload: Dict[str, Any] = Body(...)
) -> Dict[str, str]:
    return await update_quick_pin(user_seq, payload)


@router.get("/users/{user_seq}/dogs")
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


@router.post("/users/{user_seq}/dogs")
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


@router.patch("/users/{user_seq}/dogs/{dog_seq}")
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


@router.delete("/users/{user_seq}/dogs/{dog_seq}")
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

@router.get("/users/{user_seq}/addresses")
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


@router.get("/users/{user_seq}/notifications")
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
