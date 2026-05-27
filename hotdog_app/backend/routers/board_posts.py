from fastapi import APIRouter, Query

from database import fetch_query

router = APIRouter()


@router.get("/")
def get_board_posts(limit: int = Query(default=100, ge=1, le=500)):
    return fetch_query(
        """
        SELECT
            CAST(w.warning_seq AS CHAR) AS id,
            w.warning_content AS title,
            w.warning_content AS content,
            COALESCE(w.user_seq, 0) AS authorName,
            TRUE AS status,
            w.warning_date AS createdAt
        FROM warning w
        ORDER BY w.warning_date DESC, w.warning_seq DESC
        LIMIT %s
        """,
        (limit,),
    )
