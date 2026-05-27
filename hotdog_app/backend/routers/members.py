from fastapi import APIRouter, Query

from database import fetch_query

router = APIRouter()


@router.get("/")
def get_members(limit: int = Query(default=100, ge=1, le=500)):
    return fetch_query(
        """
        SELECT
            CAST(user_seq AS CHAR) AS id,
            user_name AS name,
            user_id AS email,
            user_phone AS phone,
            CASE
                WHEN user_image = 'Y' THEN '활성'
                ELSE '일반'
            END AS status,
            user_date AS joinedAt
        FROM users
        ORDER BY user_seq DESC
        LIMIT %s
        """,
        (limit,),
    )


@router.get("/{member_id}")
def get_member(member_id: str):
    rows = fetch_query(
        """
        SELECT
            CAST(user_seq AS CHAR) AS id,
            user_name AS name,
            user_id AS email,
            user_phone AS phone,
            CASE
                WHEN user_image = 'Y' THEN '활성'
                ELSE '일반'
            END AS status,
            user_date AS joinedAt
        FROM users
        WHERE user_seq = %s
        LIMIT 1
        """,
        (member_id,),
    )
    return rows[0] if rows else {}
