from pathlib import Path
from typing import Optional

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    DB_HOST: str
    DB_PORT: int = 3306
    DB_USER: str
    DB_PASSWORD: str
    DB_NAME: str
    DB_CHARSET: str = "utf8mb4"

    FASTAPI_HOST: str = "127.0.0.1"
    ADMIN_WEB_URL: str = "http://127.0.0.1:8000"
    REQUIRE_EMAIL_VERIFICATION: bool = False

    SMTP_HOST: Optional[str] = None
    SMTP_PORT: int = 587
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    SMTP_FROM_EMAIL: Optional[str] = None
    SMTP_FROM_NAME: str = "Hotdog Admin"
    SMTP_USE_TLS: bool = True

    class Config:
        env_file = Path(__file__).with_name(".env")
        env_file_encoding = "utf-8"


settings = Settings()

DB_HOST = settings.DB_HOST
DB_PORT = settings.DB_PORT
DB_USER = settings.DB_USER
DB_PASSWORD = settings.DB_PASSWORD
DB_NAME = settings.DB_NAME
DB_CHARSET = settings.DB_CHARSET
