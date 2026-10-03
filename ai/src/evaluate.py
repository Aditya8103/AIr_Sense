import os
import json
import joblib
import numpy as np
import pandas as pd
from sklearn.metrics import mean_absolute_error, root_mean_squared_error, r2_score, classification_report, confusion_matrix

def categorize_risk(pm25_series: pd.Series) -> pd.Series:
    conditions = [
        pm25_series <= 30.0,
        (pm25_series > 30.0) & (pm25_series <= 60.0),
        (pm25_series > 60.0) & (pm25_series <= 120.0),
        pm25_series > 120.0
    ]
    choices = ['LOW', 'MODERATE', 'HIGH', 'CRITICAL']
    return pd.Series(np.select(conditions, choices, default='MODERATE'), index=pm25_series.index)

def run_comprehensive_evaluation(models_dir: str, proc_data_dir: str):
    model_path = os.path.join(models_dir, "best_pm25_model.pkl")
    features_path = os.path.join(models_dir, "feature_columns.json")
    test_path = os.path.join(proc_data_dir, "test.parquet")
    
    print("[*] Loading best model and test data...")
    model = joblib.load(model_path)
    with open(features_path, "r") as f:
        meta = json.load(f)
        features = meta["features"]
        target_col = meta["target"]
        model_name = meta["best_model_name"]
        
    test_df = pd.read_parquet(test_path)
    X_test = test_df[features]
    y_test = test_df[target_col]
    
    print(f"[*] Evaluating on {len(test_df):,} test records (Year 2017)...")
    y_pred = model.predict(X_test)
    y_pred = np.clip(y_pred, a_min=0.0, a_max=None)
    
    mae = mean_absolute_error(y_test, y_pred)
    rmse = root_mean_squared_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)
    
    # Residuals
    residuals = y_test - y_pred
    errors = np.abs(residuals)
    
    # Risk categorization evaluation
    actual_risk = categorize_risk(y_test)
    pred_risk = categorize_risk(pd.Series(y_pred, index=y_test.index))
    
    risk_labels = ['LOW', 'MODERATE', 'HIGH', 'CRITICAL']
    clf_report = classification_report(actual_risk, pred_risk, labels=risk_labels, output_dict=True)
    
    print("\n" + "="*80)
    print(f"FINAL MODEL EVALUATION REPORT ({model_name.upper()})")
    print("="*80)
    print(f"Test MAE   : {mae:.3f} ug/m3")
    print(f"Test RMSE  : {rmse:.3f} ug/m3")
    print(f"Test R^2   : {r2:.4f}")
    print(f"Median AE  : {np.median(errors):.3f} ug/m3")
    print(f"90th %ile  : {np.percentile(errors, 90):.3f} ug/m3")
    print(f"95th %ile  : {np.percentile(errors, 95):.3f} ug/m3")
    
    print("\n" + "-"*80)
    print("RISK LEVEL CLASSIFICATION PERFORMANCE")
    print("-"*80)
    risk_summary = []
    for r in risk_labels:
        risk_summary.append({
            "Risk Tier": r,
            "Precision": round(clf_report[r]['precision'], 3),
            "Recall": round(clf_report[r]['recall'], 3),
            "F1-Score": round(clf_report[r]['f1-score'], 3),
            "Support": clf_report[r]['support']
        })
    print(pd.DataFrame(risk_summary).to_string(index=False))
    print(f"\nOverall Risk Accuracy: {clf_report['accuracy'] * 100:.2f}%")
    
    # Feature importance extraction
    feature_importance_dict = {}
    if hasattr(model, 'feature_importances_'):
        importances = model.feature_importances_
        feature_importance_dict = dict(sorted(zip(features, [round(float(x), 4) for x in importances]), key=lambda x: x[1], reverse=True))
    elif hasattr(model, 'named_steps') and hasattr(model.named_steps.get('model'), 'coef_'):
        coefs = np.abs(model.named_steps['model'].coef_)
        feature_importance_dict = dict(sorted(zip(features, [round(float(x), 4) for x in coefs]), key=lambda x: x[1], reverse=True))
        
    if feature_importance_dict:
        print("\n" + "-"*80)
        print("TOP 10 MOST INFLUENTIAL FEATURES IN FORECASTING")
        print("-"*80)
        top10 = list(feature_importance_dict.items())[:10]
        for rank, (feat, score) in enumerate(top10, 1):
            print(f"  {rank:2d}. {feat:<26} : {score:.4f}")
            
    # Save full evaluation artifact
    eval_artifact = {
        "model_name": model_name,
        "test_dataset_size": len(test_df),
        "regression_metrics": {
            "mae": round(float(mae), 3),
            "rmse": round(float(rmse), 3),
            "r2": round(float(r2), 4),
            "median_absolute_error": round(float(np.median(errors)), 3),
            "p90_error": round(float(np.percentile(errors, 90)), 3)
        },
        "risk_classification_accuracy": round(float(clf_report['accuracy']), 4),
        "risk_tier_metrics": risk_summary,
        "top_features": dict(list(feature_importance_dict.items())[:15])
    }
    
    eval_file = os.path.join(models_dir, "evaluation_report.json")
    with open(eval_file, "w") as f:
        json.dump(eval_artifact, f, indent=2)
    print(f"\n[+] Detailed evaluation saved to {eval_file}")

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.abspath(os.path.join(current_dir, ".."))
    models_dir = os.path.join(base_dir, "models")
    proc_data_dir = os.path.join(base_dir, "data", "processed")
    
    run_comprehensive_evaluation(models_dir, proc_data_dir)
