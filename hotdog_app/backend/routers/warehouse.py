from fastapi import APIRouter, Query

from database import fetch_query

router = APIRouter()


@router.get("/")
def get_warehouse_products(limit: int = Query(default=100, ge=1, le=500)):
    return fetch_query(
        """
        SELECT
            CAST(p.product_seq AS CHAR) AS productSeq,
            p.product_name AS productName,
            COALESCE(pc.product_category_name, '미분류') AS productCategory,
            COALESCE(w.warehouse_name, '미지정') AS location,
            COALESCE(p.product_qty, 0) AS quantity,
            CURRENT_TIMESTAMP AS updatedAt
        FROM product p
        LEFT JOIN product_category pc ON pc.product_category_seq = p.product_category_seq
        LEFT JOIN inventory i ON i.product_seq = p.product_seq
        LEFT JOIN warehouse w ON w.warehouse_seq = i.warehouse_seq
        ORDER BY p.product_seq DESC
        LIMIT %s
        """,
        (limit,),
    )
