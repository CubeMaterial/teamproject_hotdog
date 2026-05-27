import re
import time
from typing import Any, Dict

from fastapi import APIRouter, Body, HTTPException

from user_common import (
    create_verification_code,
    email_code_cooldown,
    email_verification_codes,
    fetch_one,
    get_pool,
    is_valid_email,
    require_email_verification_for_signup,
    verified_emails,
)

router = APIRouter(tags=["user-auth"])

async def handle_check_user_id(payload: Dict[str, Any]) -> Dict[str, Any]:
    user_id = str(payload.get("user_id") or "").strip()
    if not is_valid_email(user_id):
        raise HTTPException(
            status_code=400, detail="이메일 형식의 아이디를 입력해주세요."
        )

    row = await fetch_one(
        "SELECT user_seq FROM users WHERE user_id = %s LIMIT 1", (user_id,)
    )
    exists = row is not None
    return {
        "available": not exists,
        "exists": exists,
        "is_duplicate": exists,
        "message": (
            "이미 사용 중인 아이디입니다." if exists else "사용 가능한 아이디입니다."
        ),
    }


@router.post("/auth/check-id")
async def auth_check_id(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    return await handle_check_user_id(payload)


@router.post("/auth/check-user-id")
async def auth_check_user_id(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    return await handle_check_user_id(payload)


@router.post("/users/check-id")
async def users_check_id(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    return await handle_check_user_id(payload)


@router.post("/auth/login")
async def login(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    user_id = str(payload.get("user_id") or "").strip()
    user_pw = str(payload.get("user_pw") or "")

    if not user_id or not user_pw:
        raise HTTPException(status_code=400, detail="아이디와 비밀번호를 확인해주세요.")

    user = await fetch_one(
        """
        SELECT user_seq, user_name, user_id, user_phone, quick_pin_hash
        FROM users
        WHERE user_id = %s AND user_pw = %s
        LIMIT 1
        """,
        (user_id, user_pw),
    )
    if not user:
        raise HTTPException(
            status_code=401, detail="아이디 또는 비밀번호가 올바르지 않습니다."
        )

    return user


@router.post("/auth/find-id")
async def find_id(payload: Dict[str, Any] = Body(...)) -> Dict[str, str]:
    user_name = str(payload.get("user_name") or "").strip()
    user_phone = str(payload.get("user_phone") or "").strip()

    if not user_name or not user_phone:
        raise HTTPException(status_code=400, detail="이름과 전화번호를 입력해주세요.")

    user = await fetch_one(
        """
        SELECT user_id
        FROM users
        WHERE user_name = %s
          AND REPLACE(COALESCE(user_phone, ''), '-', '') = REPLACE(%s, '-', '')
        LIMIT 1
        """,
        (user_name, user_phone),
    )
    if not user:
        raise HTTPException(status_code=404, detail="일치하는 계정을 찾을 수 없습니다.")

    return {"user_id": str(user["user_id"]), "message": "가입 아이디를 찾았습니다."}


@router.post("/auth/reset-password")
async def reset_password(payload: Dict[str, Any] = Body(...)) -> Dict[str, str]:
    user_id = str(payload.get("user_id") or "").strip()
    user_pw = str(payload.get("user_pw") or "")

    if not is_valid_email(user_id) or not user_pw:
        raise HTTPException(
            status_code=400, detail="아이디와 새 비밀번호를 확인해주세요."
        )
    if len(user_pw) < 8 or re.search(r"[A-Za-z]", user_pw) is None:
        raise HTTPException(
            status_code=400, detail="비밀번호는 8자 이상, 영문 포함이어야 합니다."
        )

    verified_at = verified_emails.get(user_id)
    if not verified_at or time.time() - verified_at > 600:
        raise HTTPException(status_code=403, detail="이메일 인증을 먼저 완료해주세요.")

    db = await get_pool()
    async with db.acquire() as conn:
        try:
            await conn.begin()
            async with conn.cursor() as cur:
                await cur.execute(
                    "UPDATE users SET user_pw = %s WHERE user_id = %s",
                    (user_pw, user_id),
                )
                if cur.rowcount == 0:
                    raise HTTPException(
                        status_code=404, detail="일치하는 계정을 찾을 수 없습니다."
                    )
            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    verified_emails.pop(user_id, None)
    return {"message": "비밀번호가 변경되었습니다."}


@router.post("/auth/signup")
async def signup(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    user_id = str(payload.get("user_id") or "").strip()
    user_pw = str(payload.get("user_pw") or "")
    user_name = str(payload.get("user_name") or "").strip()
    user_phone = str(payload.get("user_phone") or "").strip()

    if not is_valid_email(user_id) or not user_pw or not user_name:
        raise HTTPException(status_code=400, detail="회원가입 정보를 확인해주세요.")

    verified_at = verified_emails.get(user_id)
    if require_email_verification_for_signup and (
        not verified_at or time.time() - verified_at > 600
    ):
        raise HTTPException(status_code=403, detail="이메일 인증을 먼저 완료해주세요.")

    db = await get_pool()
    async with db.acquire() as conn:
        try:
            await conn.begin()
            async with conn.cursor() as cur:
                await cur.execute(
                    "SELECT user_seq FROM users WHERE user_id = %s LIMIT 1", (user_id,)
                )
                if await cur.fetchone():
                    raise HTTPException(
                        status_code=409, detail="이미 사용 중인 아이디입니다."
                    )

                await cur.execute(
                    """
                    INSERT INTO users (user_name, user_phone, user_id, user_pw, user_date)
                    VALUES (%s, %s, %s, %s, NOW())
                    """,
                    (user_name, user_phone, user_id, user_pw),
                )
                user_seq = int(cur.lastrowid)
            await conn.commit()
        except HTTPException:
            await conn.rollback()
            raise
        except Exception as exc:
            await conn.rollback()
            raise HTTPException(status_code=500, detail=str(exc)) from exc

    verified_emails.pop(user_id, None)
    user = await fetch_one(
        "SELECT user_seq, user_name, user_id, user_phone, quick_pin_hash FROM users WHERE user_seq = %s LIMIT 1",
        (user_seq,),
    )
    return user


@router.post("/auth/email/send-code")
async def send_email_code(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    email = str(payload.get("email") or "").strip().lower()
    if not is_valid_email(email):
        raise HTTPException(status_code=400, detail="이메일 형식을 확인해주세요.")

    now = time.time()
    last_sent = email_code_cooldown.get(email)
    if last_sent and now - last_sent < 60:
        raise HTTPException(
            status_code=429, detail="인증번호는 60초 후 다시 요청할 수 있습니다."
        )

    code = create_verification_code()
    email_verification_codes[email] = {"code": code, "expires_at": now + 300}
    email_code_cooldown[email] = now
    return {"message": "인증번호가 발송되었습니다.", "verification_code": code}


@router.post("/auth/email/verify-code")
async def verify_email_code(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    email = str(payload.get("email") or "").strip().lower()
    code = str(payload.get("code") or "").strip()
    record = email_verification_codes.get(email)

    if not require_email_verification_for_signup and code:
        verified_emails[email] = time.time()
        email_verification_codes.pop(email, None)
        return {"message": "이메일 인증이 완료되었습니다."}

    if not record or record["expires_at"] < time.time():
        raise HTTPException(status_code=400, detail="인증번호가 만료되었습니다.")
    if record["code"] != code:
        raise HTTPException(status_code=400, detail="인증번호가 올바르지 않습니다.")

    verified_emails[email] = time.time()
    email_verification_codes.pop(email, None)
    return {"message": "이메일 인증이 완료되었습니다."}
