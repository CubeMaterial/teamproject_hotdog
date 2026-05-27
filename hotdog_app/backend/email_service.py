from dataclasses import dataclass
from email.message import EmailMessage
import smtplib

from config import settings


@dataclass(frozen=True)
class StaffInvitationEmail:
    to_email: str
    subject: str
    body: str
    sent: bool
    warning: str = ""


def build_staff_invitation_email(
    *,
    staff_name: str,
    staff_id: str,
    staff_email: str,
    temporary_password: str,
) -> tuple[str, str]:
    subject = "[Hotdog Admin] 직원 계정이 생성되었습니다"
    body = "\n".join(
        [
            f"{staff_name}님, 안녕하세요.",
            "",
            "Hotdog 관리자 포털 직원 계정이 생성되었습니다.",
            "",
            # f"로그인 주소: {settings.ADMIN_WEB_URL}",
            f"직원 ID: {staff_id}",
            f"임시 비밀번호: {temporary_password}",
            "",
            "처음 로그인한 뒤 내 정보 수정 메뉴에서 비밀번호를 변경해 주세요.",
            "본인이 요청하지 않은 계정이라면 관리자에게 문의해 주세요.",
        ]
    )

    return subject, body


def send_staff_invitation_email(
    *,
    staff_name: str,
    staff_id: str,
    staff_email: str,
    temporary_password: str,
) -> StaffInvitationEmail:
    subject, body = build_staff_invitation_email(
        staff_name=staff_name,
        staff_id=staff_id,
        staff_email=staff_email,
        temporary_password=temporary_password,
    )

    if not settings.SMTP_HOST or not settings.SMTP_FROM_EMAIL:
        return StaffInvitationEmail(
            to_email=staff_email,
            subject=subject,
            body=body,
            sent=False,
            warning="SMTP 설정이 없어 이메일을 발송하지 않았습니다.",
        )

    message = EmailMessage()
    message["Subject"] = subject
    message["From"] = f"{settings.SMTP_FROM_NAME} <{settings.SMTP_FROM_EMAIL}>"
    message["To"] = staff_email
    message.set_content(body)

    try:
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=10) as smtp:
            if settings.SMTP_USE_TLS:
                smtp.starttls()
            if settings.SMTP_USER and settings.SMTP_PASSWORD:
                smtp.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            smtp.send_message(message)
    except Exception as error:
        return StaffInvitationEmail(
            to_email=staff_email,
            subject=subject,
            body=body,
            sent=False,
            warning=f"이메일 발송 실패: {error}",
        )

    return StaffInvitationEmail(
        to_email=staff_email,
        subject=subject,
        body=body,
        sent=True,
    )
