import os
import json
import joblib
import numpy as np
import pandas as pd
from typing import Dict, Any, List, Optional

class AirSensePredictor:
    """
    Production-ready AirSense AI inference engine.
    Loads trained ML models and provides 1-hour PM2.5 forecasting,
    trend analysis, risk classification, and action recommendations.
    """
    def __init__(self, models_dir: Optional[str] = None):
        if models_dir is None:
            current_dir = os.path.dirname(os.path.abspath(__file__))
            models_dir = os.path.abspath(os.path.join(current_dir, "..", "models"))
            
        self.models_dir = models_dir
        self.model_path = os.path.join(models_dir, "best_pm25_model.pkl")
        self.scaler_path = os.path.join(models_dir, "scaler.pkl")
        self.features_path = os.path.join(models_dir, "feature_columns.json")
        self.metrics_path = os.path.join(models_dir, "model_metrics.json")
        
        self.model = None
        self.scaler = None
        self.feature_names = []
        self.model_name = "Unknown"
        self._load_artifacts()
        
    def _load_artifacts(self):
        if not os.path.exists(self.model_path):
            raise FileNotFoundError(f"Model file not found at {self.model_path}. Run train.py first.")
            
        self.model = joblib.load(self.model_path)
        if os.path.exists(self.scaler_path):
            self.scaler = joblib.load(self.scaler_path)
            
        if os.path.exists(self.features_path):
            with open(self.features_path, "r") as f:
                meta = json.load(f)
                self.feature_names = meta.get("features", [])
                self.model_name = meta.get("best_model_name", "BestModel")
                
    def _determine_risk_level(self, pm25: float) -> str:
        """
        Categorizes PM2.5 into standardized health risk tiers:
        - LOW: 0 - 30 ug/m3 (Good / Satisfactory)
        - MODERATE: 31 - 60 ug/m3 (Moderate)
        - HIGH: 61 - 120 ug/m3 (Unhealthy / Poor)
        - CRITICAL: > 120 ug/m3 (Severe / Hazardous)
        """
        if pm25 <= 30.0:
            return "LOW"
        elif pm25 <= 60.0:
            return "MODERATE"
        elif pm25 <= 120.0:
            return "HIGH"
        else:
            return "CRITICAL"
            
    def _determine_trend(self, current_pm25: float, predicted_pm25: float, threshold_pct: float = 4.0) -> str:
        """
        Computes trend direction: RISING, FALLING, or STABLE.
        """
        if current_pm25 <= 0.001:
            return "STABLE"
        pct_change = ((predicted_pm25 - current_pm25) / current_pm25) * 100.0
        if pct_change >= threshold_pct:
            return "RISING"
        elif pct_change <= -threshold_pct:
            return "FALLING"
        else:
            return "STABLE"

    def _generate_action_recommendation(self, risk_level: str, trend: str, location: str = "Area") -> str:
        """
        Generates actionable intervention recommendations (The 'ACT' component).
        """
        if risk_level == "CRITICAL":
            if trend == "RISING":
                return f"[CRITICAL ACTION REQUIRED] Severe pollution spike imminent in {location}. Deploy emergency traffic rerouting, activate municipal mist canons, and alert sensitive individuals."
            else:
                return f"[CRITICAL ADVISORY] Pollution remains at hazardous levels in {location}. Maintain dust suppression and restrict heavy diesel transit."
        elif risk_level == "HIGH":
            if trend == "RISING":
                return f"[PRECAUTIONARY ACTION] Air quality deteriorating rapidly in {location}. Recommend adaptive traffic light cycle extension, active junction ventilation, and public outdoor warnings."
            else:
                return f"[ADVISORY] High particulate matter present in {location}. Limit outdoor exertion and monitor corridor congestion."
        elif risk_level == "MODERATE":
            if trend == "RISING":
                return f"[WATCH] Moderate pollution trending upward in {location}. Pre-emptively inspect corridor idling and monitor adjacent junctions."
            else:
                return f"[NORMAL] Moderate air quality with improving trend in {location}. Normal operational mode."
        else:
            return f"[OPTIMAL] Air quality is clean and healthy in {location}. No intervention required."

    def predict(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Accepts sensor / environmental reading dictionary, executes feature construction,
        and generates the 1-hour PM2.5 prediction payload.
        """
        def safe_float(val, default):
            return default if val is None else float(val)

        def safe_int(val, default):
            return default if val is None else int(val)

        current_pm25 = safe_float(data.get("pm25", data.get("PM2.5")), 80.0)
        current_pm10 = safe_float(data.get("pm10", data.get("PM10")), current_pm25 * 1.3)
        current_co = safe_float(data.get("co", data.get("CO")), 1000.0)
        current_no2 = safe_float(data.get("no2", data.get("NO2")), 45.0)
        current_so2 = safe_float(data.get("so2", data.get("SO2")), 15.0)
        current_o3 = safe_float(data.get("o3", data.get("O3")), 50.0)
        
        temp = safe_float(data.get("temperature", data.get("TEMP")), 25.0)
        humidity = safe_float(data.get("humidity"), 60.0)
        pres = safe_float(data.get("pressure", data.get("PRES")), 1010.0)
        wspm = safe_float(data.get("wind_speed", data.get("WSPM")), 1.8)
        rain = safe_float(data.get("rain", data.get("RAIN")), 0.0)
        
        from datetime import datetime
        now = datetime.now()
        hour = safe_int(data.get("hour"), now.hour)
        day = safe_int(data.get("day"), now.day)
        month = safe_int(data.get("month"), now.month)
        day_of_week = safe_int(data.get("day_of_week"), now.weekday())
        is_weekend = safe_int(data.get("is_weekend"), 1 if day_of_week >= 5 else 0)
        
        # History series if provided, otherwise sensible lag defaults based on current
        history = data.get("history_pm25") or []
        if len(history) >= 24:
            pm25_l1 = float(history[-1])
            pm25_l2 = float(history[-2])
            pm25_l3 = float(history[-3])
            pm25_l6 = float(history[-6])
            pm25_l12 = float(history[-12])
            pm25_l24 = float(history[-24])
            roll_3h = float(np.mean(history[-3:]))
            roll_6h = float(np.mean(history[-6:]))
            roll_12h = float(np.mean(history[-12:]))
            roll_24h = float(np.mean(history[-24:]))
            roll_max6h = float(np.max(history[-6:]))
            roll_std6h = float(np.std(history[-6:]))
        else:
            # Fallback estimation when high-frequency history is starting
            pm25_l1 = safe_float(data.get("pm25_lag_1"), current_pm25 * 0.98)
            pm25_l2 = safe_float(data.get("pm25_lag_2"), current_pm25 * 0.96)
            pm25_l3 = safe_float(data.get("pm25_lag_3"), current_pm25 * 0.94)
            pm25_l6 = safe_float(data.get("pm25_lag_6"), current_pm25 * 0.92)
            pm25_l12 = safe_float(data.get("pm25_lag_12"), current_pm25 * 0.90)
            pm25_l24 = safe_float(data.get("pm25_lag_24"), current_pm25 * 0.88)
            roll_3h = (pm25_l1 + pm25_l2 + pm25_l3) / 3.0
            roll_6h = (pm25_l1 + pm25_l2 + pm25_l3 + pm25_l6) / 4.0
            roll_12h = (roll_6h + pm25_l12) / 2.0
            roll_24h = (roll_12h + pm25_l24) / 2.0
            roll_max6h = max(pm25_l1, pm25_l2, pm25_l3, pm25_l6, current_pm25)
            roll_std6h = float(np.std([pm25_l1, pm25_l2, pm25_l3, pm25_l6, current_pm25]))

        feature_dict = {
            'PM2.5': current_pm25,
            'PM10': current_pm10,
            'SO2': current_so2,
            'NO2': current_no2,
            'CO': current_co,
            'O3': current_o3,
            'TEMP': temp,
            'PRES': pres,
            'humidity': humidity,
            'WSPM': wspm,
            'RAIN': rain,
            'hour_sin': np.sin(2 * np.pi * hour / 24.0),
            'hour_cos': np.cos(2 * np.pi * hour / 24.0),
            'month_sin': np.sin(2 * np.pi * (month - 1) / 12.0),
            'month_cos': np.cos(2 * np.pi * (month - 1) / 12.0),
            'day_of_week': day_of_week,
            'is_weekend': is_weekend,
            'pm25_lag_1': pm25_l1,
            'pm25_lag_2': pm25_l2,
            'pm25_lag_3': pm25_l3,
            'pm25_lag_6': pm25_l6,
            'pm25_lag_12': pm25_l12,
            'pm25_lag_24': pm25_l24,
            'co_lag_1': safe_float(data.get("co_lag_1"), current_co),
            'temp_lag_1': safe_float(data.get("temp_lag_1"), temp),
            'humidity_lag_1': safe_float(data.get("humidity_lag_1"), humidity),
            'pm25_rolling_mean_3h': roll_3h,
            'pm25_rolling_mean_6h': roll_6h,
            'pm25_rolling_mean_12h': roll_12h,
            'pm25_rolling_mean_24h': roll_24h,
            'pm25_rolling_max_6h': roll_max6h,
            'pm25_rolling_std_6h': roll_std6h
        }
        
        feature_df = pd.DataFrame([feature_dict])[self.feature_names]
        
        # Predict
        predicted_val = float(self.model.predict(feature_df)[0])
        # Ensure non-negative physical concentration
        predicted_val = max(0.0, round(predicted_val, 1))
        
        trend = self._determine_trend(current_pm25, predicted_val)
        risk = self._determine_risk_level(predicted_val)
        device_id = data.get("device_id", data.get("deviceId", "ESP32_AIR_01"))
        location = data.get("location", "Urban Node")
        recommendation = self._generate_action_recommendation(risk, trend, location)
        
        return {
            "device_id": device_id,
            "location": location,
            "current_pm25": round(current_pm25, 1),
            "predicted_pm25": predicted_val,
            "prediction_horizon": "1 hour",
            "trend": trend,
            "risk_level": risk,
            "recommended_action": recommendation,
            "model_version": "v1.0-uci-trained",
            "algorithm": self.model_name
        }

if __name__ == "__main__":
    predictor = AirSensePredictor()
    sample_input = {
        "device_id": "ESP32_CORRIDOR_01",
        "location": "Junction Central",
        "pm25": 86.4,
        "pm10": 124.2,
        "no2": 42.1,
        "co": 1200.0,
        "o3": 35.2,
        "temperature": 28.5,
        "humidity": 62.0,
        "pressure": 1008.0,
        "wind_speed": 1.5,
        "hour": 18
    }
    
    print("\n" + "="*60)
    print("AIRSENSE LOCAL PREDICTION DEMO (ZERO FLUTTER / STANDALONE)")
    print("="*60)
    result = predictor.predict(sample_input)
    print(json.dumps(result, indent=2))
