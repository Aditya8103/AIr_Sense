import time
import requests
import json

BASE_URL = "http://localhost:8000"

def test_api():
    print("="*70)
    print("AIRSENSE AI FASTAPI TEST SUITE")
    print("="*70)
    
    # 1. Root / Metadata
    print("\n[1] Testing GET / (Root Service Info)...")
    res = requests.get(f"{BASE_URL}/")
    print(f"Status Code: {res.status_code}")
    print(json.dumps(res.json(), indent=2))
    assert res.status_code == 200
    
    # 2. Health check
    print("\n[2] Testing GET /health...")
    res = requests.get(f"{BASE_URL}/health")
    print(f"Status Code: {res.status_code}")
    print(json.dumps(res.json(), indent=2))
    assert res.status_code == 200
    assert res.json().get("model_loaded") is True
    
    # 3. Single Prediction
    print("\n[3] Testing POST /predict (Single Device Telemetry)...")
    with open("sample_request.json") as f:
        payload = json.load(f)
    res = requests.post(f"{BASE_URL}/predict", json=payload)
    print(f"Status Code: {res.status_code}")
    pred_data = res.json()
    print(json.dumps(pred_data, indent=2))
    assert res.status_code == 200
    assert "predicted_pm25" in pred_data
    assert "risk_level" in pred_data
    assert "trend" in pred_data
    
    # 4. Multi-node Hotspot Analysis
    print("\n[4] Testing POST /hotspots (Multi-Node Hotspot Detection & Action)...")
    with open("sample_hotspot_request.json") as f:
        hotspot_payload = json.load(f)
    res = requests.post(f"{BASE_URL}/hotspots", json=hotspot_payload)
    print(f"Status Code: {res.status_code}")
    hotspot_data = res.json()
    print(json.dumps(hotspot_data, indent=2))
    assert res.status_code == 200
    assert hotspot_data["hotspots_detected_count"] > 0
    
    # 5. Model Metrics
    print("\n[5] Testing GET /metrics...")
    res = requests.get(f"{BASE_URL}/metrics")
    print(f"Status Code: {res.status_code}")
    print(json.dumps(res.json(), indent=2))
    assert res.status_code == 200
    
    print("\n" + "="*70)
    print("[SUCCESS] ALL 5 API ENDPOINTS TESTED AND VALIDATED SUCCESSFULLY!")
    print("="*70)

if __name__ == "__main__":
    test_api()
