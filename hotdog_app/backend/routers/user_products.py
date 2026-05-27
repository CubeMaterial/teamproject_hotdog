from typing import Any, Dict, List

from fastapi import APIRouter, HTTPException
from fastapi.responses import Response

from user_common import fetch_all, fetch_one, sniff_content_type

router = APIRouter(tags=["user-products"])

@router.get("/products")
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


@router.get("/products/{product_seq}/image")
async def get_product_image(product_seq: int) -> Response:
    return await product_image_response(product_seq, "product_image, product_thumbnail")


@router.get("/products/{product_seq}/thumbnail")
async def get_product_thumbnail(product_seq: int) -> Response:
    return await product_image_response(product_seq, "product_thumbnail, product_image")
