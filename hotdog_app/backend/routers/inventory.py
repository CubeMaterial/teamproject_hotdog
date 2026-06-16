from typing import Optional

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from database import fetch_one_by_id, fetch_query, get_connection
from ml.inventory_forecast import append_inventory_forecasts

router = APIRouter()


class ProductCreateRequest(BaseModel):
    name: str
    category: str
    maker: Optional[str] = None
    price: int = 0
    stock: int = 0


@router.get("/categories")
def get_inventory_categories():
    return fetch_query(
        """
        SELECT
            product_sub_category_seq AS productSubCategorySeq,
            product_sub_category_name AS category
        FROM product_sub_category
        ORDER BY product_sub_category_seq ASC
        """
    )


@router.get("/makers")
def get_inventory_makers(limit: int = Query(default=500, ge=1, le=1000)):
    return fetch_query(
        """
        SELECT
            maker_seq AS makerSeq,
            maker_name AS makerName
        FROM maker
        ORDER BY maker_name ASC, maker_seq ASC
        LIMIT %s
        """,
        (limit,),
    )


@router.get("/histories")
def get_inventory_histories(limit: int = Query(default=100, ge=1, le=500)):
    return fetch_query(
        """
        SELECT *
        FROM (
            SELECT
                CONCAT('ORD-', o.order_seq) AS id,
                CAST(p.product_seq AS CHAR) AS productSeq,
                p.product_name AS itemName,
                COALESCE(psc.product_sub_category_name, '미분류') AS category,
                '발주' AS type,
                COALESCE(o.order_qty, 0) AS quantity,
                CASE
                    WHEN o.order_done = 1 THEN '처리완료'
                    ELSE '처리대기'
                END AS status,
                o.order_date AS happenedAt
            FROM orders o
            JOIN product p ON p.product_seq = o.product_seq
            LEFT JOIN (
                SELECT
                    product_seq,
                    GROUP_CONCAT(
                        DISTINCT product_sub_category_name
                        ORDER BY product_sub_category_seq
                        SEPARATOR ', '
                    ) AS product_sub_category_name
                FROM product_sub_category
                GROUP BY product_seq
            ) psc ON psc.product_seq = p.product_seq

            UNION ALL

            SELECT
                CONCAT('RCV-', r.receive_seq) AS id,
                CAST(p.product_seq AS CHAR) AS productSeq,
                p.product_name AS itemName,
                COALESCE(psc.product_sub_category_name, '미분류') AS category,
                '입고' AS type,
                COALESCE(r.receive_qty, 0) AS quantity,
                '입고완료' AS status,
                r.receive_date AS happenedAt
            FROM receive r
            JOIN product p ON p.product_seq = r.product_seq
            LEFT JOIN (
                SELECT
                    product_seq,
                    GROUP_CONCAT(
                        DISTINCT product_sub_category_name
                        ORDER BY product_sub_category_seq
                        SEPARATOR ', '
                    ) AS product_sub_category_name
                FROM product_sub_category
                GROUP BY product_seq
            ) psc ON psc.product_seq = p.product_seq
        ) histories
        ORDER BY happenedAt DESC
        LIMIT %s
        """,
        (limit,),
    )


@router.post("/")
def create_inventory_item(request: ProductCreateRequest):
    name = request.name.strip()
    category = request.category.strip()
    maker = (request.maker or "").strip()

    if not name:
        raise HTTPException(status_code=400, detail="상품명을 입력해주세요.")

    if not category:
        raise HTTPException(status_code=400, detail="카테고리를 선택해주세요.")

    if request.price < 0 or request.stock < 0:
        raise HTTPException(status_code=400, detail="가격과 재고는 0 이상이어야 합니다.")

    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT product_sub_category_seq
                    FROM product_sub_category
                    WHERE product_sub_category_name = %s
                    LIMIT 1
                    """,
                    (category,),
                )
                category_exists = cursor.fetchone()

                if category_exists is None:
                    raise HTTPException(status_code=400, detail="존재하지 않는 카테고리입니다.")

                maker_seq = None
                if maker:
                    cursor.execute(
                        """
                        SELECT maker_seq
                        FROM maker
                        WHERE maker_name = %s
                        LIMIT 1
                        """,
                        (maker,),
                    )
                    maker_row = cursor.fetchone()
                    if maker_row is not None:
                        maker_seq = maker_row["maker_seq"]

                cursor.execute(
                    """
                    INSERT INTO product (
                        product_name,
                        product_qty,
                        product_price,
                        maker_seq,
                        product_category_seq
                    )
                    VALUES (%s, %s, %s, %s, 1)
                    """,
                    (
                        name,
                        request.stock,
                        request.price,
                        maker_seq,
                    ),
                )
                product_seq = cursor.lastrowid
                cursor.execute(
                    """
                    INSERT INTO product_sub_category (
                        product_seq,
                        product_sub_category_name
                    )
                    VALUES (%s, %s)
                    """,
                    (product_seq, category),
                )
                connection.commit()

        return fetch_one_by_id("product", "product_seq", product_seq)
    except HTTPException:
        raise
    except Exception as error:
        raise HTTPException(status_code=500, detail=str(error)) from error


@router.get("/")
def get_inventory_items(limit: int = Query(default=1000, ge=1, le=5000)):
    rows = fetch_query(
        """
        SELECT
            CAST(p.product_seq AS CHAR) AS inventorySeq,
            CAST(p.product_seq AS CHAR) AS productSeq,
            CONCAT('PRD-', p.product_seq) AS inventorySerialNumber,
            p.product_name AS name,
            psc.product_sub_category_seq AS productSubCategorySeq,
            COALESCE(psc.product_sub_category_name, '미분류') AS category,
            COALESCE(p.product_qty, 0) AS stock,
            10 AS safeStock,
            CASE
                WHEN COALESCE(p.product_qty, 0) <= 10 THEN '부족'
                WHEN COALESCE(p.product_qty, 0) <= 30 THEN '주의'
                WHEN COALESCE(p.product_qty, 0) > 50 THEN '정상'
                ELSE '보통'
            END AS status
        FROM product p
        LEFT JOIN (
            SELECT
                product_seq,
                MIN(product_sub_category_seq) AS product_sub_category_seq,
                GROUP_CONCAT(
                    DISTINCT product_sub_category_name
                    ORDER BY product_sub_category_seq
                    SEPARATOR ', '
                ) AS product_sub_category_name
            FROM product_sub_category
            GROUP BY product_seq
        ) psc ON psc.product_seq = p.product_seq
        ORDER BY p.product_seq ASC
        LIMIT %s
        """,
        (limit,),
    )

    return append_inventory_forecasts(rows)
