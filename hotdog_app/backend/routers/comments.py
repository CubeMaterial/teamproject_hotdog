from fastapi import APIRouter, HTTPException, Query

from database import fetch_query, get_connection

router = APIRouter()


@router.get("/")
def get_comments(limit: int = Query(default=100, ge=1, le=500)):
    return fetch_query(
        """
        SELECT
            CAST(r.review_seq AS CHAR) AS id,
            p.product_name AS postTitle,
            COALESCE(u.user_name, '회원') AS authorName,
            r.review_content AS content,
            r.review_image AS contentImageUrl,
            '공개' AS status,
            r.review_date AS createdAt
        FROM review r
        LEFT JOIN product p ON p.product_seq = r.product_seq
        LEFT JOIN users u ON u.user_seq = r.user_seq
        ORDER BY r.review_date DESC, r.review_seq DESC
        LIMIT %s
        """,
        (limit,),
    )


@router.delete("/{comment_id}")
def delete_comment(comment_id: int):
    try:
        with get_connection() as connection:
            with connection.cursor() as cursor:
                deleted_count = cursor.execute(
                    "DELETE FROM review WHERE review_seq = %s",
                    (comment_id,),
                )
            connection.commit()
    except Exception as error:
        raise HTTPException(status_code=500, detail=str(error)) from error

    if deleted_count == 0:
        raise HTTPException(status_code=404, detail="Comment not found")

    return {"deleted": True, "id": str(comment_id)}
