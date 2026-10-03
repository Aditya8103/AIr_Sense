import os
import json
from src.predict import AirSensePredictor

def run_demo():
    print("="*80)
    print("      AIRSENSE AI EVALUATION & LIVE DEMONSTRATION")
    print("   Model: Ridge Regression Pipeline | Version: v1.0-uci-trained")
    print("="*80)
    
    predictor = AirSensePredictor()
    
    # -------------------------------------------------------------
    # DEMO 1: THREE CORE AIR-QUALITY SCENARIOS
    # -------------------------------------------------------------
    print("\n" + "="*80)
    print("PART 1: THREE CORE AIR-QUALITY LEVEL DEMONSTRATIONS")
    print("="*80)
    
    scenarios = [
        {
            "title": "CASE 1 — Normal / Clean Urban Conditions",
            "data": {
                "deviceId": "ESP32_RESIDENTIAL_01",
                "location": "Green Park Residential Zone",
                "pm25": 25.0,
                "pm10": 35.0,
                "temperature": 24.0,
                "humidity": 50.0,
                "pressure": 1012.0,
                "wind_speed": 2.2,
                "co": 450.0,
                "hour": 10
            }
        },
        {
            "title": "CASE 2 — Rising Pollution / Peak Commute Hours",
            "data": {
                "deviceId": "ESP32_JUNCTION_02",
                "location": "Commercial Boulevard",
                "pm25": 80.0,
                "pm10": 115.0,
                "temperature": 28.5,
                "humidity": 62.0,
                "pressure": 1008.0,
                "wind_speed": 1.4,
                "co": 1300.0,
                "hour": 18
            }
        },
        {
            "title": "CASE 3 — Severe / Hazardous Pollution Episode",
            "data": {
                "deviceId": "ESP32_INDUSTRIAL_03",
                "location": "Industrial Corridor",
                "pm25": 165.0,
                "pm10": 240.0,
                "temperature": 31.0,
                "humidity": 45.0,
                "pressure": 1004.0,
                "wind_speed": 0.8,
                "co": 2800.0,
                "hour": 21
            }
        }
    ]
    
    for sc in scenarios:
        print(f"\n>>> {sc['title']}")
        print(f"    Inputs  : Current PM2.5 = {sc['data']['pm25']} ug/m3 | Temp = {sc['data']['temperature']}C | CO = {sc['data']['co']}")
        res = predictor.predict(sc['data'])
        print(f"    Results : Predicted PM2.5 (1h) = {res['predicted_pm25']} ug/m3")
        print(f"              Risk Level           = {res['risk_level']}")
        print(f"              Trend Direction      = {res['trend']}")
        print(f"              Action Plan          = {res['recommended_action']}")
        print(f"              Version / Algorithm  = {res['model_version']} ({res['algorithm']})")
        
    # -------------------------------------------------------------
    # DEMO 2: REALISTIC MULTI-NODE HOTSPOT ANALYSIS
    # -------------------------------------------------------------
    print("\n" + "="*80)
    print("PART 2: REALISTIC MULTI-NODE POLLUTION HOTSPOT DETECTION")
    print("="*80)
    
    nodes_data = [
        {
            "deviceId": "ESP32_NODE_01",
            "location": "Junction A (Suburban Entry)",
            "pm25": 42.0,
            "temperature": 26.5,
            "humidity": 55.0,
            "co": 600.0,
            "hour": 18
        },
        {
            "deviceId": "ESP32_NODE_02",
            "location": "Junction B (Central Market)",
            "pm25": 51.0,
            "temperature": 27.8,
            "humidity": 58.0,
            "co": 850.0,
            "hour": 18
        },
        {
            "deviceId": "ESP32_NODE_03",
            "location": "Junction C (Bus Terminal)",
            "pm25": 118.0,
            "temperature": 29.2,
            "humidity": 65.0,
            "co": 1850.0,
            "hour": 18
        },
        {
            "deviceId": "ESP32_NODE_04",
            "location": "Junction D (Industrial Bypass)",
            "pm25": 145.0,
            "temperature": 30.5,
            "humidity": 60.0,
            "co": 2500.0,
            "hour": 18
        }
    ]
    
    predictions = [predictor.predict(n) for n in nodes_data]
    ranked = sorted(predictions, key=lambda x: x["predicted_pm25"], reverse=True)
    hotspots = [
        n for n in ranked
        if n["predicted_pm25"] >= 100.0 or (n["risk_level"] in ["HIGH", "CRITICAL"] and n["trend"] == "RISING")
    ]
    
    print("\nRANKED POLLUTION SENSITIVITY TABLE:")
    print(f"{'Rank':<6}{'Node ID':<16}{'Location':<32}{'Current':<10}{'Predicted':<12}{'Risk Tier':<12}{'Hotspot?'}")
    print("-" * 95)
    for i, p in enumerate(ranked, 1):
        is_spot = "YES [HOTSPOT]" if p in hotspots else "No"
        print(f"{i:<6}{p['device_id']:<16}{p['location']:<32}{p['current_pm25']:<10}{p['predicted_pm25']:<12}{p['risk_level']:<12}{is_spot}")
        
    print("\nSYSTEM ACTIONABLE INTERVENTIONS:")
    print(f"Primary Hotspot Identified : {ranked[0]['location']} ({ranked[0]['device_id']})")
    print(f"Primary Hotspot Risk Level : {ranked[0]['risk_level']}")
    print(f"Recommended Intervention   : {ranked[0]['recommended_action']}")
    print("="*80)

if __name__ == "__main__":
    run_demo()
