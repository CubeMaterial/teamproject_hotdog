from datetime import datetime

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from database import fetch_query, get_connection
from email_service import send_staff_invitation_email

router = APIRouter()


class StaffCreateRequest(BaseModel):
    staffName: str
    staffId: str
    staffLevel: int
    staffPhone: str = ""


class StaffPhoneUpdateRequest(BaseModel):
    staffPhone: str


class StaffPasswordUpdateRequest(BaseModel):
    currentPassword: str
    newPassword: str


class StaffPasswordVerifyRequest(BaseModel):
    currentPassword: str


@router.get("/")
def get_staffs(limit: int = Query(default=100, ge=1, le=500)):
    return fetch_query(
        """
            SELECT
                CAST(staff_seq AS CHAR) AS staffSeq,
                staff_name AS staffName,
                staff_phone AS staffPhone,
                staff_id AS staffId,
                '' AS staffPw,
                staff_date AS staffDate,
                COALESCE(staff_level, 0) AS staffLevel,
                COALESCE(CAST(staff_super_seq AS CHAR), '') AS staffSuperSeq,
                CONCAT(staff_id, '@hotdog.com') AS staffEmail,
                TRUE AS isActive
            FROM staff
            ORDER BY staff_seq DESC
            LIMIT %s
            """,
        (limit,),
    )


@router.post("/")
def create_staff(request: StaffCreateRequest):
    staff_name = request.staffName.strip()
    staff_id = request.staffId.strip()
    staff_phone = request.staffPhone.strip()
    staff_email = f"{staff_id}@hotdog.com"

    if not staff_name or not staff_id:
        raise HTTPException(status_code=400, detail="Required staff fields are missing")
    if request.staffLevel < 1:
        raise HTTPException(status_code=400, detail="Invalid staff level")

    initial_password = staff_id
    staff_date = datetime.now()

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute("SHOW COLUMNS FROM staff")
            columns = {row["Field"] for row in cursor.fetchall()}

            if "staff_id" not in columns or "staff_name" not in columns:
                raise HTTPException(status_code=500, detail="Invalid staff table schema")

            cursor.execute(
                "SELECT COUNT(*) AS count FROM staff WHERE staff_id = %s",
                (staff_id,),
            )
            if cursor.fetchone()["count"] > 0:
                raise HTTPException(status_code=409, detail="Staff ID already exists")

            insert_columns = ["staff_name", "staff_id"]
            insert_values = [staff_name, staff_id]

            optional_values = {
                "staff_phone": staff_phone,
                "staff_pw": initial_password,
                "staff_date": staff_date,
                "staff_level": request.staffLevel,
                "staff_super_seq": None,
            }

            for column, value in optional_values.items():
                if column in columns:
                    insert_columns.append(column)
                    insert_values.append(value)

            placeholders = ", ".join(["%s"] * len(insert_columns))
            column_sql = ", ".join(f"`{column}`" for column in insert_columns)
            cursor.execute(
                f"INSERT INTO staff ({column_sql}) VALUES ({placeholders})",
                tuple(insert_values),
            )
            connection.commit()

            staff_seq = str(cursor.lastrowid)

    invitation = send_staff_invitation_email(
        staff_name=staff_name,
        staff_id=staff_id,
        staff_email=staff_email,
        temporary_password=initial_password,
    )

    return {
        "staff": {
            "staffSeq": staff_seq,
            "staffName": staff_name,
            "staffPhone": staff_phone,
            "staffId": staff_id,
            "staffPw": "",
            "staffDate": staff_date.isoformat(),
            "staffLevel": request.staffLevel,
            "staffSuperSeq": "",
            "staffEmail": staff_email,
        },
        "email": {
            "to": invitation.to_email,
            "subject": invitation.subject,
            "body": invitation.body,
            "sent": invitation.sent,
            "warning": invitation.warning,
        },
    }


@router.patch("/{staff_seq}/phone")
def update_staff_phone(staff_seq: int, request: StaffPhoneUpdateRequest):
    staff_phone = request.staffPhone.strip()

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT 1 FROM staff WHERE staff_seq = %s LIMIT 1",
                (staff_seq,),
            )
            if cursor.fetchone() is None:
                raise HTTPException(status_code=404, detail="Staff not found")

            cursor.execute(
                "UPDATE staff SET staff_phone = %s WHERE staff_seq = %s",
                (staff_phone, staff_seq),
            )
            connection.commit()

    rows = fetch_query(
        """
            SELECT
                CAST(staff_seq AS CHAR) AS staffSeq,
                staff_name AS staffName,
                staff_phone AS staffPhone,
                staff_id AS staffId,
                '' AS staffPw,
                staff_date AS staffDate,
                COALESCE(staff_level, 0) AS staffLevel,
                COALESCE(CAST(staff_super_seq AS CHAR), '') AS staffSuperSeq,
                CONCAT(staff_id, '@hotdog.com') AS staffEmail,
                TRUE AS isActive
            FROM staff
            WHERE staff_seq = %s
            LIMIT 1
            """,
        (staff_seq,),
    )

    return {"staff": rows[0]}


@router.post("/{staff_seq}/password/verify")
def verify_staff_password(staff_seq: int, request: StaffPasswordVerifyRequest):
    current_password = request.currentPassword

    if not current_password:
        raise HTTPException(status_code=400, detail="현재 비밀번호를 입력해 주세요")

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT staff_pw
                FROM staff
                WHERE staff_seq = %s
                LIMIT 1
                """,
                (staff_seq,),
            )
            staff = cursor.fetchone()

    if staff is None:
        raise HTTPException(status_code=404, detail="Staff not found")

    if staff["staff_pw"] != current_password:
        raise HTTPException(status_code=400, detail="현재 비밀번호가 올바르지 않습니다")

    return {"verified": True, "staffSeq": str(staff_seq)}


@router.patch("/{staff_seq}/password")
def update_staff_password(staff_seq: int, request: StaffPasswordUpdateRequest):
    current_password = request.currentPassword
    new_password = request.newPassword

    if not current_password or not new_password:
        raise HTTPException(status_code=400, detail="비밀번호를 입력해 주세요")
    if len(new_password) < 4:
        raise HTTPException(status_code=400, detail="새 비밀번호는 4자 이상이어야 합니다")

    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT staff_pw
                FROM staff
                WHERE staff_seq = %s
                LIMIT 1
                """,
                (staff_seq,),
            )
            staff = cursor.fetchone()

            if staff is None:
                raise HTTPException(status_code=404, detail="Staff not found")

            if staff["staff_pw"] != current_password:
                raise HTTPException(
                    status_code=400,
                    detail="현재 비밀번호가 올바르지 않습니다",
                )

            cursor.execute(
                "UPDATE staff SET staff_pw = %s WHERE staff_seq = %s",
                (new_password, staff_seq),
            )
            connection.commit()

    return {"updated": True, "staffSeq": str(staff_seq)}


@router.delete("/{staff_seq}")
def delete_staff(staff_seq: int):
    with get_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute("DELETE FROM staff WHERE staff_seq = %s", (staff_seq,))
            if cursor.rowcount == 0:
                raise HTTPException(status_code=404, detail="Staff not found")
            connection.commit()

    return {"deleted": True, "staffSeq": str(staff_seq)}
