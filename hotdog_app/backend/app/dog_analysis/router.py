from __future__ import annotations

import hashlib
import io
import os
import shutil
import tempfile
from functools import lru_cache
from pathlib import Path
from typing import Any, Optional

from fastapi import APIRouter, File, Header, HTTPException, Query, UploadFile
from fastapi.responses import JSONResponse, Response
from pydantic import BaseModel, Field


router = APIRouter(tags=["dog-analysis"])

API_KEY = os.getenv("API_KEY", "hotdog-api-test-key")
REQUIRE_API_KEY = os.getenv("REQUIRE_API_KEY", "1").lower() not in {"0", "false", "no"}
CURSE_MODEL_ID = os.getenv("CURSE_MODEL_ID", os.getenv("MODEL_ID", "2tle/korean-curse-detection"))
BREED_MODEL_FILE_NAME = os.getenv("DOG_BREED_MODEL_FILE", "dog_breed_detect.safetensors")
OTHER_THRESHOLD = float(os.getenv("DOG_BREED_OTHER_THRESHOLD", "0.65"))

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/webp"}

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

# The DL repo README notes that the exported config label order is not the
# trained class order. Keep the same override as the source bot.
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
    "black": {"name_ko": "블랙", "hex": "#1c1c1c", "rgb": (20, 20, 20)},
    "white": {"name_ko": "화이트", "hex": "#eeece2", "rgb": (235, 235, 225)},
    "gray": {"name_ko": "그레이", "hex": "#828282", "rgb": (130, 130, 130)},
    "brown": {"name_ko": "브라운", "hex": "#84522d", "rgb": (130, 75, 35)},
}


class TextRequest(BaseModel):
    text: str = Field(..., example="오늘 날씨가 정말 좋네요.")


class BatchTextRequest(BaseModel):
    texts: list[str] = Field(..., example=["오늘 날씨가 정말 좋네요.", "ㅅㅂ 이게 왜 안 되지"])


@lru_cache(maxsize=1)
def get_numpy():
    import numpy as np

    return np


@lru_cache(maxsize=1)
def get_cv2():
    import cv2

    return cv2


@lru_cache(maxsize=1)
def get_image_class():
    from PIL import Image

    return Image


@lru_cache(maxsize=1)
def get_remove_background_function():
    from rembg import remove

    return remove


@lru_cache(maxsize=1)
def get_torch_runtime():
    import torch

    torch_device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    pipeline_device = 0 if torch.cuda.is_available() else -1
    device_name = "CUDA GPU" if torch.cuda.is_available() else "CPU"
    return torch, torch_device, pipeline_device, device_name


def verify_api_key(x_api_key: Optional[str]) -> None:
    if REQUIRE_API_KEY and x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API Key")


def validate_image_upload(file: UploadFile) -> None:
    if not file.content_type or file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(status_code=400, detail="jpg, jpeg, png, webp 이미지 파일만 업로드해 주세요.")


def load_image_from_bytes(image_bytes: bytes) -> Any:
    Image = get_image_class()
    try:
        return Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception as exc:
        raise ValueError("이미지 파일을 읽을 수 없습니다.") from exc


def remove_dog_background_rgba(image: Any) -> Any:
    Image = get_image_class()
    remove = get_remove_background_function()
    output = remove(image.convert("RGBA"))
    if not isinstance(output, Image.Image):
        output = Image.open(io.BytesIO(output)).convert("RGBA")
    return output.convert("RGBA")


def rgba_to_white_rgb(rgba_image: Any) -> Any:
    Image = get_image_class()
    white_background = Image.new("RGBA", rgba_image.size, (255, 255, 255, 255))
    return Image.alpha_composite(white_background, rgba_image).convert("RGB")


def _candidate_model_dirs() -> list[Path]:
    backend_dir = Path(__file__).resolve().parents[2]
    candidates = [
        Path(os.getenv("DOG_BREED_MODEL_DIR", "")) if os.getenv("DOG_BREED_MODEL_DIR") else None,
        backend_dir / "Model",
        backend_dir / "model",
        Path.cwd() / "Model",
        Path.cwd() / "model",
        Path.cwd() / "hotdog_app" / "backend" / "Model",
        Path.cwd().parent / "Model",
        Path("/kaggle/working/Model"),
    ]
    if Path("/kaggle/input").exists():
        candidates.extend(path.parent for path in Path("/kaggle/input").rglob(BREED_MODEL_FILE_NAME))
    return [path for path in candidates if path is not None]


def find_breed_model_dir() -> Path:
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
        "README 기준 Model/dog_breed_detect.safetensors, config.json, preprocessor_config.json를 배치하거나 "
        "DOG_BREED_MODEL_DIR 환경변수를 설정하세요. "
        f"Searched: {searched}"
    )


@lru_cache(maxsize=1)
def file_sha256(path: Path, chunk_size: int = 1024 * 1024) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(chunk_size), b""):
            digest.update(chunk)
    return digest.hexdigest()


@lru_cache(maxsize=1)
def load_breed_model_from_dir(model_dir: Path, model_path: Path) -> Any:
    from transformers import AutoModelForImageClassification

    if model_path.name == "model.safetensors":
        return AutoModelForImageClassification.from_pretrained(model_dir)

    with tempfile.TemporaryDirectory() as temp_dir_name:
        temp_dir = Path(temp_dir_name)
        shutil.copy2(model_dir / "config.json", temp_dir / "config.json")
        try:
            os.symlink(model_path, temp_dir / "model.safetensors")
        except OSError:
            shutil.copy2(model_path, temp_dir / "model.safetensors")
        return AutoModelForImageClassification.from_pretrained(temp_dir)


@lru_cache(maxsize=1)
def get_breed_runtime() -> tuple[Any, Any, dict[int, str], Path, str]:
    _, torch_device, _, _ = get_torch_runtime()
    from transformers import ViTImageProcessor

    model_dir = find_breed_model_dir()
    model_path = model_dir / BREED_MODEL_FILE_NAME
    model_sha256 = file_sha256(model_path)
    processor = ViTImageProcessor.from_pretrained(model_dir)
    model = load_breed_model_from_dir(model_dir, model_path)
    model.to(torch_device)
    model.eval()
    return model, processor, BREED_ID2LABEL_OVERRIDE.copy(), model_dir, model_sha256


def predict_breed_from_bytes(image_bytes: bytes, top_k: int = 3, remove_background: bool = True) -> dict[str, Any]:
    torch, torch_device, _, device_name = get_torch_runtime()
    model, processor, id2label, model_dir, model_sha256 = get_breed_runtime()
    original_image = load_image_from_bytes(image_bytes)
    if remove_background:
        dog_rgba = remove_dog_background_rgba(original_image)
        input_image = rgba_to_white_rgb(dog_rgba)
    else:
        input_image = original_image

    inputs = processor(images=input_image, return_tensors="pt")
    inputs = {key: value.to(torch_device) for key, value in inputs.items()}
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
        "device": device_name,
    }


def get_dog_pixels(rgba_image: Any, alpha_threshold: int = 40) -> np.ndarray:
    np = get_numpy()
    rgba = np.array(rgba_image)
    rgb = rgba[:, :, :3]
    alpha = rgba[:, :, 3]
    pixels = rgb[alpha > alpha_threshold]
    if len(pixels) == 0:
        raise ValueError("배경 제거 후 분석할 강아지 픽셀이 없습니다.")
    return pixels


def classify_pixels_to_four_colors(pixels: np.ndarray) -> dict[str, Any]:
    np = get_numpy()
    cv2 = get_cv2()
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
        centers = np.array([COLOR_INFO[label]["rgb"] for label in labels], dtype=np.float32)
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
    image = load_image_from_bytes(image_bytes)
    dog_rgba = remove_dog_background_rgba(image)
    dog_pixels = get_dog_pixels(dog_rgba)
    result = classify_pixels_to_four_colors(dog_pixels)
    result["background_removed"] = True
    result["image_size"] = {"width": image.width, "height": image.height}
    return result


def remove_background_png_from_bytes(image_bytes: bytes) -> bytes:
    image = load_image_from_bytes(image_bytes)
    dog_rgba = remove_dog_background_rgba(image)
    buffer = io.BytesIO()
    dog_rgba.save(buffer, format="PNG")
    return buffer.getvalue()


@lru_cache(maxsize=1)
def get_curse_classifier():
    _, _, pipeline_device, _ = get_torch_runtime()
    from transformers import pipeline

    return pipeline(
        task="text-classification",
        model=CURSE_MODEL_ID,
        tokenizer=CURSE_MODEL_ID,
        device=pipeline_device,
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


@router.get("/dog-analysis/health")
def dog_analysis_health() -> dict[str, Any]:
    return {
        "success": True,
        "data": {
            "status": "ok",
            "device": "lazy",
            "breed_model_file": BREED_MODEL_FILE_NAME,
            "curse_model": CURSE_MODEL_ID,
            "auth": "Header x-api-key is required" if REQUIRE_API_KEY else "disabled",
        },
    }


@router.post("/breed/predict")
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


@router.post("/dogkind/predict")
async def predict_dogkind_alias(
    image: UploadFile = File(...),
    top_k: int = Query(default=3, ge=1, le=10),
    remove_background: bool = Query(default=True),
    x_api_key: Optional[str] = Header(None),
):
    return await predict_breed(
        image=image,
        top_k=top_k,
        remove_background=remove_background,
        x_api_key=x_api_key,
    )


@router.post("/color/extract")
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


@router.post("/color/remove-background")
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


@router.post("/curse/predict")
def predict_curse(request: TextRequest, x_api_key: Optional[str] = Header(None)):
    verify_api_key(x_api_key)
    if not request.text.strip():
        raise HTTPException(status_code=400, detail="text 값이 비어 있습니다.")
    try:
        return detect_curse(request.text)
    except Exception as error:
        return JSONResponse(status_code=500, content={"success": False, "error": repr(error)})


@router.post("/curse/predict-batch")
def predict_curse_batch(request: BatchTextRequest, x_api_key: Optional[str] = Header(None)):
    verify_api_key(x_api_key)
    texts = [text for text in request.texts if text and text.strip()]
    if not texts:
        raise HTTPException(status_code=400, detail="texts 리스트에 검사할 문장이 없습니다.")
    try:
        return {"count": len(texts), "results": detect_curse_batch(texts)}
    except Exception as error:
        return JSONResponse(status_code=500, content={"success": False, "error": repr(error)})


@router.post("/analyze/image")
async def analyze_image(
    image: UploadFile = File(...),
    top_k: int = Query(default=3, ge=1, le=10),
    remove_background: bool = Query(default=True),
    x_api_key: Optional[str] = Header(None),
):
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
