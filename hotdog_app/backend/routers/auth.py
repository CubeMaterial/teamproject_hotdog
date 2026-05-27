from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from database import get_connection, sanitize_row

router = APIRouter()


class LoginRequest(BaseModel):
    login_id: str
    password: str


@router.post("/login")
def login(request: LoginRequest):
    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT *
                FROM `staff`
                WHERE `staff_id` = %s
                  AND `staff_pw` = %s
                LIMIT 1
                """,
                (request.login_id, request.password),
            )
            staff = cursor.fetchone()

    if staff is None:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    return {"staff": sanitize_row(dict(staff)), "access_token": "temporary-token"}
