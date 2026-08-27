import asyncio
import base64
from concurrent.futures import ThreadPoolExecutor
from typing import List

import cv2
import numpy as np
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from ultralytics import YOLO

app = FastAPI(
    title = "CloudeEco - Plastic in River Detection API"
)

# Thread pool to run blocking YOLO inference without freezing the async event loop
executor = ThreadPoolExecutor(max_workers=4)
# Load the pre-trained YOLO model once at startup 
MODEL_PATH = "best.pt"
model = YOLO(MODEL_PATH)

# Map YOLO class IDs to human-readable labels
CLASS_NAMES = {
    0: "PLASTIC_BAG",
    1: "PLASTIC_BOTTLE",
    2: "OTHER_PLASTIC_WASTE",
    3: "NOT_PLASTIC_WASTE"
}

# Map YOLO class IDs to human-readable labels
class ImageRequest(BaseModel):
    """Client sends a UUID and a base64-encoded image string."""
    uuid: str
    image: str    # base64-encoded image

class BoundingBox(BaseModel):
    """Coordinates and confidence score for one detected object."""
    x: float                # top-left x (pixels)
    y: float                # top-left y (pixels)
    width: float            # box width (pixels)
    height: float           # box height (pixels)
    probability: float      # confidence score 0.0 - 1.0


class PredictResponse(BaseModel):
    """Structured JSON response for /api/predict."""
    uuid: str
    count: int
    detections: List[str]
    boxes: List[BoundingBox]
    speed_preprocess_ms: float
    speed_inference_ms: float
    speed_postprocess_ms: float

class AnnotateResponse(BaseModel):
    """Response for /api/annotate contains the annotated image as base64."""
    uuid: str
    annotated_image: str 

@app.post("/api/predict", response_model=PredictResponse)
async def predict(request: ImageRequest):
    """
    Accepts a base64 image, runs YOLO inference, and returns detection results.
    """
    # Decode base64 to image array
    try:
        img_bytes = base64.b64decode(request.image)
        img_array = np.frombuffer(img_bytes, dtype=np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

    # Run YOLO in thread pool (avoids blocking the async event loop)
    loop = asyncio.get_event_loop()
    result = await loop.run_in_executor(
        executor, lambda: model.predict(img, verbose=False)[0]  
    )

    # Extract results
    detections = []
    boxes = []

    if result.boxes is not None:
        for box in result.boxes:
            x1, y1, x2, y2 = box.xyxy[0].tolist()
            probability = float(box.conf[0])
            class_id = int(box.cls[0])
            class_name = result.names[class_id]
            detections.append(class_name)

            one_box = BoundingBox(
                x=float(x1),
                y=float(y1),
                width=float(x2 - x1),
                height=float(y2 - y1),
                probability=probability
            )
            boxes.append(one_box)

    # return JSON 
    speed = result.speed
    return {
        "uuid": request.uuid,
        "count": len(detections),
        "detections": detections,
        "boxes": boxes,
        "speed_preprocess_ms": speed.get("preprocess", 0.0),
        "speed_inference_ms": speed.get("inference", 0.0),
        "speed_postprocess_ms": speed.get("postprocess", 0.0)
    }

@app.post("/api/annotate", response_model=AnnotateResponse)
async def annotate(request: ImageRequest):
    """
    Accepts a base64 image, runs YOLO inference, draws bounding boxes,
    and returns the annotated image as a base64 string.
    """
    # Decode base64 to image
    try:
        img_bytes = base64.b64decode(request.image)
        img_array = np.frombuffer(img_bytes, dtype=np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    
    # Run YOLO in thread pool
    loop = asyncio.get_event_loop()
    result = await loop.run_in_executor(
        executor, lambda: model.predict(img, verbose=False)[0]
    )

    # Annotate and encode
    annotated_img = result.plot(line_width=1)
    _, buffer = cv2.imencode(".jpg", annotated_img)
    
    return {
        "uuid": request.uuid,
        "annotated_image": base64.b64encode(buffer).decode("utf-8")
    }