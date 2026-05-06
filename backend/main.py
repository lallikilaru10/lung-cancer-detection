"""
Lung Cancer Detection - FastAPI Backend Server

Provides a REST API for uploading CT scan images and getting
predictions from the trained hybrid ensemble model.
"""

import io
import os
import torch
import torch.nn.functional as F
from torchvision import transforms
from PIL import Image
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from model import NovelHybridEnsembleImproved

# =========================
# CONFIG
# =========================
MODEL_PATH = os.environ.get("MODEL_PATH", "best_model.pth")
NUM_CLASSES = 4
CLASSES = [
    "adenocarcinoma_left.lower.lobe_T2_N0_M0_Ib",
    "large.cell.carcinoma_left.hilum_T2_N2_M0_IIIa",
    "normal",
    "squamous.cell.carcinoma_left.hilum_T1_N2_M0_IIIa",
]

# Friendly display names for the UI
CLASS_DISPLAY_NAMES = {
    "adenocarcinoma_left.lower.lobe_T2_N0_M0_Ib": "Adenocarcinoma (Left Lower Lobe)",
    "large.cell.carcinoma_left.hilum_T2_N2_M0_IIIa": "Large Cell Carcinoma (Left Hilum)",
    "normal": "Normal (No Cancer Detected)",
    "squamous.cell.carcinoma_left.hilum_T1_N2_M0_IIIa": "Squamous Cell Carcinoma (Left Hilum)",
}

CLASS_SEVERITY = {
    "adenocarcinoma_left.lower.lobe_T2_N0_M0_Ib": "high",
    "large.cell.carcinoma_left.hilum_T2_N2_M0_IIIa": "critical",
    "normal": "none",
    "squamous.cell.carcinoma_left.hilum_T1_N2_M0_IIIa": "critical",
}

CLASS_DESCRIPTIONS = {
    "adenocarcinoma_left.lower.lobe_T2_N0_M0_Ib": "Adenocarcinoma is the most common type of lung cancer. This classification indicates Stage Ib cancer located in the left lower lobe. Tumor size is T2 with no lymph node involvement (N0) and no metastasis (M0).",
    "large.cell.carcinoma_left.hilum_T2_N2_M0_IIIa": "Large Cell Carcinoma is an aggressive non-small cell lung cancer. This classification indicates Stage IIIa cancer located in the left hilum with regional lymph node involvement (N2) but no distant metastasis (M0).",
    "normal": "No signs of lung cancer detected. The CT scan appears normal. However, please consult with a medical professional for a definitive diagnosis.",
    "squamous.cell.carcinoma_left.hilum_T1_N2_M0_IIIa": "Squamous Cell Carcinoma originates in the flat cells lining the airways. This classification indicates Stage IIIa cancer located in the left hilum with regional lymph node involvement (N2) but no distant metastasis (M0).",
}

CONFIDENCE_THRESHOLD = 0.5

# =========================
# IMAGE TRANSFORM (same as notebook test_transform)
# =========================
test_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
])

# =========================
# DEVICE & MODEL LOADING
# =========================
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = None


def load_model():
    """Load the trained model weights. Falls back to demo mode if weights are missing."""
    global model
    model = NovelHybridEnsembleImproved(num_classes=NUM_CLASSES, use_pretrained=False)

    if os.path.exists(MODEL_PATH):
        try:
            state_dict = torch.load(MODEL_PATH, map_location=device, weights_only=True)
            model.load_state_dict(state_dict)
            print(f"[INFO] Model loaded from {MODEL_PATH}")
        except Exception as e:
            print(f"[WARN] Could not load weights: {e}")
            print("[INFO] Running in DEMO mode with random weights.")
    else:
        print(f"[WARN] Model file '{MODEL_PATH}' not found.")
        print("[INFO] Running in DEMO mode with random weights.")
        print("[INFO] To use trained weights, place 'best_model.pth' in the backend directory.")

    model.to(device)
    model.eval()
    return model


# =========================
# FASTAPI APP
# =========================
app = FastAPI(
    title="Lung Cancer Detection API",
    description="Upload a chest CT scan image to classify lung cancer type using a hybrid ensemble deep learning model.",
    version="1.0.0",
)

# Allow Flutter web app to make requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup():
    load_model()


@app.get("/health")
async def health_check():
    return {"status": "ok", "model_loaded": model is not None}


@app.get("/classes")
async def get_classes():
    """Return available classification classes with metadata."""
    return {
        "classes": [
            {
                "id": cls,
                "display_name": CLASS_DISPLAY_NAMES[cls],
                "severity": CLASS_SEVERITY[cls],
                "description": CLASS_DESCRIPTIONS[cls],
            }
            for cls in CLASSES
        ]
    }


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    """
    Upload a CT scan image and receive a lung cancer classification prediction.
    
    Returns:
        - predicted_class: Raw class name
        - display_name: Human-readable class name  
        - confidence: Prediction confidence (0-1)
        - severity: Risk severity (none/high/critical)
        - description: Detailed medical description
        - all_probabilities: Confidence scores for all classes
        - is_confident: Whether prediction exceeds confidence threshold
    """
    # Validate file type
    if file.content_type and not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Uploaded file is not an image.")

    try:
        image_bytes = await file.read()
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception:
        raise HTTPException(status_code=400, detail="Could not open the uploaded image. Please upload a valid image file.")

    # Preprocess
    input_tensor = test_transform(image).unsqueeze(0).to(device)

    # Predict
    with torch.no_grad():
        outputs = model(input_tensor)
        probabilities = F.softmax(outputs, dim=1)
        max_prob, predicted_idx = torch.max(probabilities, 1)

    max_prob_value = max_prob.item()
    predicted_class = CLASSES[predicted_idx.item()]

    # Build per-class probabilities
    all_probs = probabilities[0].cpu().tolist()
    all_probabilities = [
        {
            "class": CLASSES[i],
            "display_name": CLASS_DISPLAY_NAMES[CLASSES[i]],
            "probability": round(all_probs[i], 4),
            "severity": CLASS_SEVERITY[CLASSES[i]],
        }
        for i in range(NUM_CLASSES)
    ]
    # Sort by probability descending
    all_probabilities.sort(key=lambda x: x["probability"], reverse=True)

    is_confident = max_prob_value >= CONFIDENCE_THRESHOLD

    return JSONResponse(content={
        "predicted_class": predicted_class,
        "display_name": CLASS_DISPLAY_NAMES[predicted_class],
        "confidence": round(max_prob_value, 4),
        "severity": CLASS_SEVERITY[predicted_class],
        "description": CLASS_DESCRIPTIONS[predicted_class],
        "all_probabilities": all_probabilities,
        "is_confident": is_confident,
        "warning": None if is_confident else "Low confidence prediction. The image may not be a valid lung CT scan or could be of poor quality.",
    })
