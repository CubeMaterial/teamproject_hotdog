#
#  Adapted from hot_dog_chatbot/app/chatbot/ollama_chat.py.
#  This version avoids requiring a separate chatbot FastAPI process.
#

from __future__ import annotations

import json
import os
from functools import lru_cache
from urllib.error import URLError
from urllib.request import Request, urlopen

from pydantic import BaseModel

from app.chatbot.memory import ChatHistoryMessage
from app.chatbot.options import SYSTEM_PROMPT


DEFAULT_OLLAMA_BASE_URL = "http://localhost:11434"
DEFAULT_OLLAMA_MODEL = "gemma3:4b"
REQUEST_TIMEOUT = 120.0
TEMPERATURE = 0


class OllamaSettings(BaseModel):
    base_url: str
    model: str
    request_timeout: float
    temperature: int


@lru_cache(maxsize=1)
def get_ollama_settings() -> OllamaSettings:
    return OllamaSettings(
        base_url=os.getenv("OLLAMA_BASE_URL", DEFAULT_OLLAMA_BASE_URL),
        model=os.getenv("OLLAMA_MODEL", DEFAULT_OLLAMA_MODEL),
        request_timeout=REQUEST_TIMEOUT,
        temperature=TEMPERATURE,
    )


def generate_chat_response(
    message: str,
    history: list[ChatHistoryMessage] | None = None,
    product_context: str | None = None,
) -> str:
    settings = get_ollama_settings()
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    messages.extend(
        {"role": history_message.role, "content": history_message.content}
        for history_message in history or []
    )
    if product_context:
        messages.append({"role": "system", "content": product_context})
    messages.append({"role": "user", "content": message})

    payload = {
        "model": settings.model,
        "messages": messages,
        "stream": False,
        "options": {"temperature": settings.temperature},
    }
    request = Request(
        f"{settings.base_url.rstrip('/')}/api/chat",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urlopen(request, timeout=settings.request_timeout) as response:
            raw = json.loads(response.read().decode("utf-8"))
    except (OSError, URLError) as exc:
        raise RuntimeError("ollama request failed") from exc

    content = raw.get("message", {}).get("content")
    if content is None:
        content = raw.get("response")
    return str(content or "").strip()
