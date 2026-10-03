import os
import json
from contextlib import asynccontextmanager
from typing import List, Optional, Dict, Any
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, ConfigDict
import uvicorn

from src.predict import AirSensePredictor

# Initialize Predictor Singleton
predictor: Optional[AirSensePredictor] = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global predictor
    try:
        current_dir = os.path.dirname(os.path.abspath(__file__))
        models_dir = os.path.join(current_dir, "models")
        predictor = AirSensePredictor(models_dir=models_dir)
        print(f"[+] Loaded AI Predictor with model: {predictor.model_name}")
    except Exception as e:
        print(f"[!] Warning: Could not initialize model on startup ({e}). Will load on first request.")
    yield

# Initialize FastAPI application
app = FastAPI(
    title="AirSense AI Microservice",
    description="Standalone Machine Learning Service for 1-Hour PM2.5 Air Pollution Forecasting, Risk Categorization, and Intervention Recommendations.",
    version="1.0.0",
    lifespan=lifespan
)

# Enable Cross-Origin Resource Sharing (CORS) for Spring Boot and Web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -------------------------------------------------------------
# Request & Response Schemas
# -------------------------------------------------------------
class PredictionRequest(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,
        json_schema_extra={
            "example": {
                "device_id": "ESP32_JUNCTION_A",
                "location": "Junction Central",
                "pm25": 84.5,
                "pm10": 118.0,
                "temperature": 28.2,
                "humidity": 60.5,
                "pressure": 1009.0,
                "wind_speed": 1.4,
                "hour": 18
            }
        }
    )
    device_id: Optional[str] = Field("ESP32_AIR_01", alias="deviceId", description="Unique identifier of sensor node")
    location: Optional[str] = Field("City Central", description="Physical location or junction name")
    pm25: Optional[float] = Field(75.0, description="Current PM2.5 concentration (ug/m3)")
    pm10: Optional[float] = Field(None, description="Optional PM10 concentration (ug/m3)")
    temperature: Optional[float] = Field(27.0, description="Ambient temperature (Celsius)")
    humidity: Optional[float] = Field(55.0, description="Relative humidity (%)")
    pressure: Optional[float] = Field(1012.0, description="Atmospheric pressure (hPa)")
    wind_speed: Optional[float] = Field(1.8, description="Wind speed (m/s)")
    rain: Optional[float] = Field(0.0, description="Precipitation (mm)")
    co: Optional[float] = Field(1000.0, description="Carbon monoxide concentration (ug/m3) or MQ135 proxy")
    no2: Optional[float] = Field(45.0, description="Nitrogen dioxide concentration (ug/m3)")
    so2: Optional[float] = Field(15.0, description="Sulfur dioxide concentration (ug/m3)")
    o3: Optional[float] = Field(50.0, description="Ozone concentration (ug/m3)")
    hour: Optional[int] = Field(None, description="Hour of the day (0-23)")
    month: Optional[int] = Field(None, description="Month of the year (1-12)")
    history_pm25: Optional[List[float]] = Field(None, description="Historical PM2.5 readings (hourly)")

class PredictionResponse(BaseModel):
    device_id: str
    location: str
    current_pm25: float
    predicted_pm25: float
    prediction_horizon: str
    trend: str
    risk_level: str
    recommended_action: str
    model_version: str
    algorithm: str

class HotspotAnalysisRequest(BaseModel):
    nodes: List[PredictionRequest]

# -------------------------------------------------------------
# REST Endpoints
# -------------------------------------------------------------
@app.get("/", tags=["Info"])
def root():
    return {
        "service": "AirSense AI Prediction API",
        "status": "ONLINE",
        "version": "1.0.0",
        "description": "Short-term Air Quality & PM2.5 Forecasting Engine",
        "endpoints": {
            "predict": "POST /predict",
            "hotspots": "POST /hotspots",
            "metrics": "GET /metrics",
            "health": "GET /health"
        }
    }

@app.get("/health", tags=["Health"])
def health_check():
    return {"status": "HEALTHY", "model_loaded": predictor is not None and predictor.model is not None}

@app.post("/predict", response_model=PredictionResponse, tags=["Forecasting"])
def predict_air_quality(payload: PredictionRequest):
    global predictor
    if predictor is None or predictor.model is None:
        try:
            current_dir = os.path.dirname(os.path.abspath(__file__))
            models_dir = os.path.join(current_dir, "models")
            predictor = AirSensePredictor(models_dir=models_dir)
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Model not loaded: {str(e)}")
            
    input_dict = payload.model_dump(by_alias=False)
    prediction = predictor.predict(input_dict)
    return prediction

@app.post("/hotspots", tags=["Hotspots & Action"])
def analyze_hotspots(batch: HotspotAnalysisRequest):
    """
    Evaluates multi-node sensor telemetry to identify geographic pollution hotspots
    and prioritize actionable municipal/traffic interventions.
    """
    global predictor
    if predictor is None:
        current_dir = os.path.dirname(os.path.abspath(__file__))
        models_dir = os.path.join(current_dir, "models")
        predictor = AirSensePredictor(models_dir=models_dir)
        
    predictions = []
    for node in batch.nodes:
        pred = predictor.predict(node.model_dump())
        predictions.append(pred)
        
    # Sort nodes by predicted PM2.5 descending
    ranked_nodes = sorted(predictions, key=lambda x: x["predicted_pm25"], reverse=True)
    
    # Identify hotspots (nodes with predicted PM2.5 >= 100 or CRITICAL/HIGH risk with RISING trend)
    hotspots = [
        n for n in ranked_nodes
        if n["predicted_pm25"] >= 100.0 or (n["risk_level"] in ["HIGH", "CRITICAL"] and n["trend"] == "RISING")
    ]
    
    return {
        "total_nodes_analyzed": len(ranked_nodes),
        "hotspots_detected_count": len(hotspots),
        "primary_hotspot": hotspots[0] if hotspots else None,
        "ranked_nodes": ranked_nodes,
        "system_status": "CRITICAL HOTSPOTS IDENTIFIED" if hotspots else "NORMAL URBAN DISPERSION"
    }

@app.get("/metrics", tags=["Model Quality"])
def get_model_metrics():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    metrics_file = os.path.join(current_dir, "models", "model_metrics.json")
    if not os.path.exists(metrics_file):
        raise HTTPException(status_code=404, detail="Model metrics file not found. Ensure train.py has run.")
    with open(metrics_file, "r") as f:
        return json.load(f)

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=False)
