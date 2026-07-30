"""
Kaggle Unified Hot Dog API

색상 판별, 견종 분류, 한국어 비속어 탐지를 하나의 FastAPI 서버로 실행하는 통합 파일입니다.

Kaggle Notebook 실행 예시:
    import os
    os.environ["API_KEY"] = "hotdog-api-test-key"
    # Kaggle Secrets에 Ngrok_token을 등록해두면 자동으로 읽습니다.
    !python /kaggle/input/your-dataset/Note/kaggle_unified_hotdog_api.py

주요 엔드포인트:
    GET  /
    GET  /health
    POST /breed/predict
    POST /dogkind/predict
    POST /color/extract
    POST /color/remove-background
    POST /curse/predict
    POST /curse/predict-batch
    POST /analyze/image
"""

from __future__ import annotations

import io
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
from functools import lru_cache
from pathlib import Path
from typing import Any, Optional


def _bootstrap_if_needed() -> None:
    """Kaggle에서 바로 실행할 수 있도록 필요한 패키지를 한 번 설치합니다."""
    if os.getenv("HOTDOG_API_BOOTSTRAPPED") == "1" or os.getenv("HOTDOG_API_SKIP_BOOTSTRAP") == "1":
        return

    packages = [
        "transformers>=4.40",
        "safetensors",
        "fastapi",
        "uvicorn",
        "python-multipart",
        "pillow",
        "rembg",
        "onnxruntime",
        "nest-asyncio",
        "pyngrok",
        "opencv-python-headless",
        "numpy",
        "pydantic",
    ]
    print("[bootstrap] installing packages for Kaggle runtime...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "-q", "-U", *packages])
    os.environ["HOTDOG_API_BOOTSTRAPPED"] = "1"
    os.execv(sys.executable, [sys.executable, __file__, *sys.argv[1:]])


if __name__ == "__main__":
    _bootstrap_if_needed()


import cv2
import nest_asyncio
import numpy as np
import torch
import uvicorn
from fastapi import FastAPI, File, Header, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response
from PIL import Image
from pydantic import BaseModel, Field
from rembg import remove
from transformers import AutoModelForImageClassification, ViTImageProcessor, pipeline


# =========================
# 기본 설정
# =========================
CURRENT_FILE = Path(__file__).resolve()
PROJECT_DIR = CURRENT_FILE.parent
PORT = int(os.getenv("PORT", "8000"))
API_KEY = os.getenv("API_KEY", "hotdog-api-test-key")
REQUIRE_API_KEY = os.getenv("REQUIRE_API_KEY", "1").lower() not in {"0", "false", "no"}
CURSE_MODEL_ID = os.getenv("CURSE_MODEL_ID", os.getenv("MODEL_ID", "2tle/korean-curse-detection"))
BREED_MODEL_FILE_NAME = os.getenv("DOG_BREED_MODEL_FILE", "dog_breed_detect.safetensors")
OTHER_THRESHOLD = float(os.getenv("DOG_BREED_OTHER_THRESHOLD", "0.65"))

TORCH_DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
PIPELINE_DEVICE = 0 if torch.cuda.is_available() else -1
DEVICE_NAME = "CUDA GPU" if torch.cuda.is_available() else "CPU"

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp"}


def get_secret_or_env(*names: str) -> str:
    """환경변수 또는 Kaggle Secrets에서 값을 찾습니다."""
    for name in names:
        value = os.getenv(name)
        if value:
            return value

    try:
        from kaggle_secrets import UserSecretsClient

        secrets = UserSecretsClient()
        for name in names:
            try:
                value = secrets.get_secret(name)
            except Exception:
                value = None
            if value:
                return value
    except Exception:
        pass

    return ""


NGROK_AUTH_TOKEN = get_secret_or_env("NGROK_AUTH_TOKEN", "NGROK_AUTHTOKEN", "Ngrok_token", "ngrok_token")

BREED_LABEL_KO = {
    "maltese": "몰티즈",
    "poodle": "푸들",
    "mixed": "믹스견",
    "pomeranian": "포메라니안",
    "bichon_frise": "비숑 프리제",
    "chihuahua": "치와와",
    "shih_tzu": "시츄",
    "jindo": "진돗개",
    "yorkshire_terrier": "요크셔테리어",
    "golden_retriever": "골든 리트리버",
}

# 학습 데이터 폴더 순서 기준의 실제 class id 매핑입니다.
# 현재 Model/config.json의 id2label은 class 0을 jindo로 기록하지만,
# 체크포인트 출력 검증 결과 class 0은 bichon_frise, class 3이 jindo였습니다.
BREED_ID2LABEL_OVERRIDE = {
    0: "bichon_frise",
    1: "chihuahua",
    2: "golden_retriever",
    3: "jindo",
    4: "maltese",
    5: "mixed",
    6: "pomeranian",
    7: "poodle",
    8: "shih_tzu",
    9: "yorkshire_terrier",
}

CURSE_LABEL_MAP = {
    "LABEL_0": "정상 문장",
    "LABEL_1": "비속어/욕설 의심",
}

COLOR_INFO = {
    "black": {"name_ko": "블랙", "hex": "#1c1c1c", "rgb": np.array([20, 20, 20], dtype=np.float32)},
    "white": {"name_ko": "화이트", "hex": "#eeece2", "rgb": np.array([235, 235, 225], dtype=np.float32)},
    "gray": {"name_ko": "그레이", "hex": "#828282", "rgb": np.array([130, 130, 130], dtype=np.float32)},
    "brown": {"name_ko": "브라운", "hex": "#84522d", "rgb": np.array([130, 75, 35], dtype=np.float32)},
}


# =========================
# 요청 모델
# =========================
class TextRequest(BaseModel):
    text: str = Field(..., example="오늘 날씨가 정말 좋네요.")


class BatchTextRequest(BaseModel):
    texts: list[str] = Field(..., example=["오늘 날씨가 정말 좋네요.", "ㅅㅂ 이게 왜 안 되지"])


# =========================
# 공통 유틸
# =========================
def verify_api_key(x_api_key: Optional[str]) -> None:
    """외부 호출용 API Key를 확인합니다. REQUIRE_API_KEY=0이면 인증을 끌 수 있습니다."""
    if REQUIRE_API_KEY and x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API Key")


def validate_image_upload(file: UploadFile) -> None:
    if not file.content_type or file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail="jpg, jpeg, png, webp 이미지 파일만 업로드해 주세요.")


def load_image_from_bytes(image_bytes: bytes) -> Image.Image:
    """업로드 이미지 바이트를 PIL RGB 이미지로 변환합니다."""
    try:
        return Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception as exc:
        raise ValueError("이미지 파일을 읽을 수 없습니다.") from exc


def remove_dog_background_rgba(image: Image.Image) -> Image.Image:
    """rembg를 이용해 배경을 제거하고 RGBA 이미지로 반환합니다."""
    output = remove(image.convert("RGBA"))
    if not isinstance(output, Image.Image):
        output = Image.open(io.BytesIO(output)).convert("RGBA")
    return output.convert("RGBA")


def rgba_to_white_rgb(rgba_image: Image.Image) -> Image.Image:
    """투명 배경을 흰색으로 합성해 ViT 모델 입력용 RGB 이미지로 변환합니다."""
    white_background = Image.new("RGBA", rgba_image.size, (255, 255, 255, 255))
    return Image.alpha_composite(white_background, rgba_image).convert("RGB")


def _candidate_model_dirs() -> list[Path]:
    """로컬 프로젝트와 Kaggle input/working에서 모델 폴더 후보를 찾습니다."""
    candidates = [
        Path(os.getenv("DOG_BREED_MODEL_DIR", "")) if os.getenv("DOG_BREED_MODEL_DIR") else None,
        PROJECT_DIR / "Model",
        PROJECT_DIR.parent / "Model",
        Path.cwd() / "Model",
        Path.cwd().parent / "Model",
        Path("/kaggle/working/Model"),
    ]
    if Path("/kaggle/input").exists():
        candidates.extend(path.parent for path in Path("/kaggle/input").rglob(BREED_MODEL_FILE_NAME))
    return [path for path in candidates if path is not None]


def find_breed_model_dir() -> Path:
    """dog_breed_detect.safetensors, config.json, preprocessor_config.json가 있는 폴더를 반환합니다."""
    for model_dir in _candidate_model_dirs():
        if (
            model_dir.exists()
            and (model_dir / BREED_MODEL_FILE_NAME).exists()
            and (model_dir / "config.json").exists()
            and (model_dir / "preprocessor_config.json").exists()
        ):
            return model_dir

    searched = [str(path) for path in _candidate_model_dirs()]
    raise FileNotFoundError(
        "견종 분류 모델 폴더를 찾지 못했습니다. "
        "Model/dog_breed_detect.safetensors, config.json, preprocessor_config.json를 Kaggle Input에 추가하거나 "
        "DOG_BREED_MODEL_DIR 환경변수를 설정하세요. "
        f"Searched: {searched}"
    )


# =========================
# 견종 분류
# =========================
@lru_cache(maxsize=1)
def file_sha256(path: Path, chunk_size: int = 1024 * 1024) -> str:
    """모델 파일이 실제로 교체됐는지 확인할 수 있는 SHA256 지문을 계산합니다."""
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(chunk_size), b""):
            digest.update(chunk)
    return digest.hexdigest()


@lru_cache(maxsize=1)
def load_breed_model_from_dir(model_dir: Path, model_path: Path) -> AutoModelForImageClassification:
    """Transformers 호환 변환 로직을 타도록 from_pretrained로 모델을 로드합니다."""
    if model_path.name == "model.safetensors":
        return AutoModelForImageClassification.from_pretrained(model_dir)

    # from_pretrained는 기본적으로 model.safetensors 이름을 찾습니다.
    # 업로드 파일명이 dog_breed_detect.safetensors인 경우 임시 폴더에 표준 이름으로 연결합니다.
    with tempfile.TemporaryDirectory() as temp_dir_name:
        temp_dir = Path(temp_dir_name)
        shutil.copy2(model_dir / "config.json", temp_dir / "config.json")
        try:
            os.symlink(model_path, temp_dir / "model.safetensors")
        except OSError:
            shutil.copy2(model_path, temp_dir / "model.safetensors")
        return AutoModelForImageClassification.from_pretrained(temp_dir)


@lru_cache(maxsize=1)
def get_breed_runtime() -> tuple[AutoModelForImageClassification, ViTImageProcessor, dict[int, str], Path, str]:
    """견종 분류 모델을 첫 요청 때 한 번만 로드합니다."""
    model_dir = find_breed_model_dir()
    model_path = model_dir / BREED_MODEL_FILE_NAME
    model_sha256 = file_sha256(model_path)
    print(f"[breed] loading model: {model_path} on {DEVICE_NAME}")
    print(f"[breed] model sha256: {model_sha256}")

    processor = ViTImageProcessor.from_pretrained(model_dir)
    model = load_breed_model_from_dir(model_dir, model_path)
    model.to(TORCH_DEVICE)
    model.eval()

    id2label = BREED_ID2LABEL_OVERRIDE.copy()
    return model, processor, id2label, model_dir, model_sha256


def predict_breed_from_bytes(image_bytes: bytes, top_k: int = 3, remove_background: bool = True) -> dict[str, Any]:
    """이미지 배경을 제거한 뒤 견종을 분류합니다."""
    model, processor, id2label, model_dir, model_sha256 = get_breed_runtime()
    original_image = load_image_from_bytes(image_bytes)
    if remove_background:
        dog_rgba = remove_dog_background_rgba(original_image)
        input_image = rgba_to_white_rgb(dog_rgba)
    else:
        input_image = original_image

    inputs = processor(images=input_image, return_tensors="pt")
    inputs = {key: value.to(TORCH_DEVICE) for key, value in inputs.items()}

    with torch.no_grad():
        logits = model(**inputs).logits
        probabilities = torch.softmax(logits, dim=-1)[0].detach().cpu()

    best_id = int(torch.argmax(probabilities).item())
    best_label = id2label[best_id]
    best_confidence = float(probabilities[best_id].item())
    is_other = best_confidence < OTHER_THRESHOLD

    top_indices = torch.topk(probabilities, k=min(top_k, len(probabilities))).indices.tolist()
    top_predictions = []
    for class_id in top_indices:
        label = id2label[int(class_id)]
        top_predictions.append(
            {
                "label": label,
                "breed": BREED_LABEL_KO.get(label, label),
                "confidence": round(float(probabilities[class_id].item()), 6),
            }
        )

    return {
        "breed": "기타" if is_other else BREED_LABEL_KO.get(best_label, best_label),
        "label": "other" if is_other else best_label,
        "confidence": round(best_confidence, 6),
        "is_other": is_other,
        "other_threshold": OTHER_THRESHOLD,
        "top_predictions": top_predictions,
        "background_removed": remove_background,
        "image_size": {"width": original_image.width, "height": original_image.height},
        "model_dir": str(model_dir),
        "model_file": str(model_dir / BREED_MODEL_FILE_NAME),
        "model_sha256": model_sha256,
        "device": DEVICE_NAME,
    }


# =========================
# 색상 판별
# =========================
def get_dog_pixels(rgba_image: Image.Image, alpha_threshold: int = 40) -> np.ndarray:
    """투명하지 않은 영역만 강아지 픽셀로 간주해 RGB 배열로 반환합니다."""
    rgba = np.array(rgba_image)
    rgb = rgba[:, :, :3]
    alpha = rgba[:, :, 3]
    pixels = rgb[alpha > alpha_threshold]
    if len(pixels) == 0:
        raise ValueError("배경 제거 후 분석할 강아지 픽셀이 없습니다.")
    return pixels


def classify_pixels_to_four_colors(pixels: np.ndarray) -> dict[str, Any]:
    """강아지 픽셀을 black, white, gray, brown 네 가지 색상으로 분류합니다."""
    pixels = pixels.astype(np.uint8)
    r = pixels[:, 0].astype(np.int16)
    g = pixels[:, 1].astype(np.int16)
    b = pixels[:, 2].astype(np.int16)

    hsv = cv2.cvtColor(pixels.reshape(-1, 1, 3), cv2.COLOR_RGB2HSV).reshape(-1, 3)
    h = hsv[:, 0].astype(np.int16)
    s = hsv[:, 1].astype(np.int16)
    v = hsv[:, 2].astype(np.int16)
    channel_range = np.maximum.reduce([r, g, b]) - np.minimum.reduce([r, g, b])

    black_mask = v < 65
    white_mask = (v >= 190) & (s < 45)
    gray_mask = (s < 55) & (channel_range < 45) & ~black_mask & ~white_mask
    brown_mask = (
        (h >= 5)
        & (h <= 35)
        & (s >= 35)
        & (v >= 45)
        & (r >= g - 15)
        & (g >= b - 10)
        & ~black_mask
        & ~white_mask
        & ~gray_mask
    )

    counts = {
        "black": int(black_mask.sum()),
        "white": int(white_mask.sum()),
        "gray": int(gray_mask.sum()),
        "brown": int(brown_mask.sum()),
    }

    assigned_mask = black_mask | white_mask | gray_mask | brown_mask
    unassigned_pixels = pixels[~assigned_mask].astype(np.float32)
    if len(unassigned_pixels) > 0:
        labels = list(COLOR_INFO.keys())
        centers = np.stack([COLOR_INFO[label]["rgb"] for label in labels], axis=0)
        distances = np.linalg.norm(unassigned_pixels[:, None, :] - centers[None, :, :], axis=2)
        nearest = np.argmin(distances, axis=1)
        for index in nearest:
            counts[labels[int(index)]] += 1

    total = sum(counts.values())
    if total == 0:
        raise ValueError("분류 가능한 픽셀이 없습니다.")

    colors = []
    for color, count in sorted(counts.items(), key=lambda item: item[1], reverse=True):
        info = COLOR_INFO[color]
        colors.append(
            {
                "color": color,
                "color_ko": info["name_ko"],
                "hex": info["hex"],
                "ratio": round(count / total, 6),
                "percentage": round(count / total * 100, 2),
                "pixel_count": count,
            }
        )

    return {
        "total_pixels": total,
        "dominant_color": colors[0]["color"],
        "dominant_color_ko": colors[0]["color_ko"],
        "main_hex": colors[0]["hex"],
        "colors": colors,
    }


def analyze_color_from_bytes(image_bytes: bytes) -> dict[str, Any]:
    """이미지 바이트를 받아 배경 제거 후 강아지 털색 비율을 반환합니다."""
    image = load_image_from_bytes(image_bytes)
    dog_rgba = remove_dog_background_rgba(image)
    dog_pixels = get_dog_pixels(dog_rgba)
    result = classify_pixels_to_four_colors(dog_pixels)
    result["background_removed"] = True
    result["image_size"] = {"width": image.width, "height": image.height}
    return result


def remove_background_png_from_bytes(image_bytes: bytes) -> bytes:
    """배경 제거 결과 이미지를 PNG 바이트로 반환합니다."""
    image = load_image_from_bytes(image_bytes)
    dog_rgba = remove_dog_background_rgba(image)
    buffer = io.BytesIO()
    dog_rgba.save(buffer, format="PNG")
    return buffer.getvalue()


# =========================
# 비속어 탐지
# =========================
@lru_cache(maxsize=1)
def get_curse_classifier():
    """비속어 탐지 모델을 첫 요청 때 한 번만 로드합니다."""
    print(f"[curse] loading model: {CURSE_MODEL_ID} on {DEVICE_NAME}")
    return pipeline(
        task="text-classification",
        model=CURSE_MODEL_ID,
        tokenizer=CURSE_MODEL_ID,
        device=PIPELINE_DEVICE,
    )


def format_curse_prediction(text: str, prediction: dict[str, Any]) -> dict[str, Any]:
    label = prediction["label"]
    return {
        "text": text,
        "label": label,
        "result": CURSE_LABEL_MAP.get(label, label),
        "is_curse": label == "LABEL_1",
        "score": round(float(prediction["score"]), 4),
    }


def detect_curse(text: str) -> dict[str, Any]:
    prediction = get_curse_classifier()(text)[0]
    return format_curse_prediction(text, prediction)


def detect_curse_batch(texts: list[str]) -> list[dict[str, Any]]:
    predictions = get_curse_classifier()(texts)
    return [format_curse_prediction(text, prediction) for text, prediction in zip(texts, predictions)]


# =========================
# FastAPI
# =========================
app = FastAPI(
    title="Unified Hot Dog API",
    description="강아지 색상 판별, 견종 분류, 한국어 비속어 탐지를 통합 제공하는 Kaggle용 API입니다.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root() -> dict[str, Any]:
    return {
        "status": "running",
        "device": DEVICE_NAME,
        "docs": "/docs",
        "auth": "Header x-api-key is required" if REQUIRE_API_KEY else "disabled",
        "endpoints": {
            "breed": ["POST /breed/predict", "POST /dogkind/predict"],
            "color": ["POST /color/extract", "POST /color/remove-background"],
            "curse": ["POST /curse/predict", "POST /curse/predict-batch"],
            "combined": ["POST /analyze/image"],
        },
    }


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "success": True,
        "data": {
            "status": "ok",
            "device": DEVICE_NAME,
            "port": PORT,
            "breed_model_file": BREED_MODEL_FILE_NAME,
            "curse_model": CURSE_MODEL_ID,
        },
    }


@app.post("/breed/predict")
async def predict_breed(
    image: UploadFile = File(...),
    top_k: int = Query(default=3, ge=1, le=10),
    remove_background: bool = Query(default=True),
    x_api_key: Optional[str] = Header(None),
):
    verify_api_key(x_api_key)
    validate_image_upload(image)
    try:
        return predict_breed_from_bytes(await image.read(), top_k=top_k, remove_background=remove_background)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except Exception as error:
        return JSONResponse(status_code=500, content={"success": False, "error": repr(error)})


@app.post("/dogkind/predict")
async def predict_dogkind_alias(
    image: UploadFile = File(...),
    top_k: int = Query(default=3, ge=1, le=10),
    remove_background: bool = Query(default=True),
    x_api_key: Optional[str] = Header(None),
):
    """기존 프로젝트 호환용 견종 분류 별칭 엔드포인트입니다."""
    return await predict_breed(
        image=image,
        top_k=top_k,
        remove_background=remove_background,
        x_api_key=x_api_key,
    )


@app.post("/color/extract")
async def extract_color(
    image: UploadFile = File(...),
    x_api_key: Optional[str] = Header(None),
):
    verify_api_key(x_api_key)
    validate_image_upload(image)
    try:
        return analyze_color_from_bytes(await image.read())
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except Exception as error:
        return JSONResponse(status_code=500, content={"success": False, "error": repr(error)})


@app.post("/color/remove-background")
async def remove_background_endpoint(
    image: UploadFile = File(...),
    x_api_key: Optional[str] = Header(None),
):
    verify_api_key(x_api_key)
    validate_image_upload(image)
    try:
        png_bytes = remove_background_png_from_bytes(await image.read())
        return Response(content=png_bytes, media_type="image/png")
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except Exception as error:
        return JSONResponse(status_code=500, content={"success": False, "error": repr(error)})


@app.post("/curse/predict")
def predict_curse(request: TextRequest, x_api_key: Optional[str] = Header(None)):
    verify_api_key(x_api_key)
    if not request.text.strip():
        raise HTTPException(status_code=400, detail="text 값이 비어 있습니다.")
    try:
        return detect_curse(request.text)
    except Exception as error:
        return JSONResponse(status_code=500, content={"success": False, "error": repr(error)})


@app.post("/curse/predict-batch")
def predict_curse_batch(request: BatchTextRequest, x_api_key: Optional[str] = Header(None)):
    verify_api_key(x_api_key)
    texts = [text for text in request.texts if text and text.strip()]
    if not texts:
        raise HTTPException(status_code=400, detail="texts 리스트에 검사할 문장이 없습니다.")
    try:
        return {
            "count": len(texts),
            "results": detect_curse_batch(texts),
        }
    except Exception as error:
        return JSONResponse(status_code=500, content={"success": False, "error": repr(error)})


@app.post("/analyze/image")
async def analyze_image(
    image: UploadFile = File(...),
    top_k: int = Query(default=3, ge=1, le=10),
    remove_background: bool = Query(default=True),
    x_api_key: Optional[str] = Header(None),
):
    """이미지 하나로 견종 분류와 색상 판별을 함께 실행합니다."""
    verify_api_key(x_api_key)
    validate_image_upload(image)
    image_bytes = await image.read()
    try:
        return {
            "breed": predict_breed_from_bytes(image_bytes, top_k=top_k, remove_background=remove_background),
            "color": analyze_color_from_bytes(image_bytes),
        }
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error
    except Exception as error:
        return JSONResponse(status_code=500, content={"success": False, "error": repr(error)})


def start_server() -> None:
    """ngrok 공개 URL이 있으면 만들고, FastAPI 서버를 시작합니다."""
    public_url = ""
    if NGROK_AUTH_TOKEN:
        from pyngrok import ngrok

        ngrok.set_auth_token(NGROK_AUTH_TOKEN)
        # 이전 실행에서 남은 터널이 있으면 새 URL 확인을 헷갈리게 만들 수 있어 정리합니다.
        ngrok.kill()
        ngrok_domain = os.getenv("NGROK_DOMAIN", "")
        connect_options = {"bind_tls": True}
        if ngrok_domain:
            connect_options["domain"] = ngrok_domain
        tunnel = ngrok.connect(PORT, **connect_options)
        public_url = tunnel.public_url
    else:
        public_url = f"http://127.0.0.1:{PORT}"
        print("[ngrok] NGROK_AUTH_TOKEN이 없어 로컬 URL만 출력합니다.")

    print("=" * 72)
    print("Unified Hot Dog API 실행 완료")
    print("Public URL:", public_url)
    print("Docs:", f"{public_url}/docs")
    print("Health:", f"{public_url}/health")
    print("API_KEY:", API_KEY if REQUIRE_API_KEY else "(disabled)")
    print("Breed:", f"{public_url}/breed/predict")
    print("Dogkind alias:", f"{public_url}/dogkind/predict")
    print("Color:", f"{public_url}/color/extract")
    print("Remove background:", f"{public_url}/color/remove-background")
    print("Curse:", f"{public_url}/curse/predict")
    print("Image analyze:", f"{public_url}/analyze/image")
    print("=" * 72)

    nest_asyncio.apply()
    uvicorn.run(app, host="0.0.0.0", port=PORT)


if __name__ == "__main__":
    start_server()
