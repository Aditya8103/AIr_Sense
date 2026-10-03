import os
import json
import time
import joblib
import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression, Ridge
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_absolute_error, root_mean_squared_error, r2_score
import xgboost as xgb

FEATURE_COLUMNS = [
    # Current environmental & pollutant features
    'PM2.5', 'PM10', 'SO2', 'NO2', 'CO', 'O3',
    'TEMP', 'PRES', 'humidity', 'WSPM', 'RAIN',
    # Calendar & Cyclical
    'hour_sin', 'hour_cos', 'month_sin', 'month_cos', 'day_of_week', 'is_weekend',
    # Lags
    'pm25_lag_1', 'pm25_lag_2', 'pm25_lag_3', 'pm25_lag_6', 'pm25_lag_12', 'pm25_lag_24',
    'co_lag_1', 'temp_lag_1', 'humidity_lag_1',
    # Rolling statistics
    'pm25_rolling_mean_3h', 'pm25_rolling_mean_6h', 'pm25_rolling_mean_12h', 'pm25_rolling_mean_24h',
    'pm25_rolling_max_6h', 'pm25_rolling_std_6h'
]

TARGET_COLUMN = 'target_pm25_1h'

def evaluate_predictions(y_true, y_pred, set_name="Test"):
    mae = mean_absolute_error(y_true, y_pred)
    rmse = root_mean_squared_error(y_true, y_pred)
    r2 = r2_score(y_true, y_pred)
    return {
        f"{set_name}_MAE": round(float(mae), 3),
        f"{set_name}_RMSE": round(float(rmse), 3),
        f"{set_name}_R2": round(float(r2), 4)
    }

def train_and_compare_models(proc_data_dir: str, models_dir: str):
    os.makedirs(models_dir, exist_ok=True)
    
    print("[*] Loading chronological datasets...")
    train_df = pd.read_parquet(os.path.join(proc_data_dir, "train.parquet"))
    val_df = pd.read_parquet(os.path.join(proc_data_dir, "val.parquet"))
    test_df = pd.read_parquet(os.path.join(proc_data_dir, "test.parquet"))
    
    X_train = train_df[FEATURE_COLUMNS]
    y_train = train_df[TARGET_COLUMN]
    
    X_val = val_df[FEATURE_COLUMNS]
    y_val = val_df[TARGET_COLUMN]
    
    X_test = test_df[FEATURE_COLUMNS]
    y_test = test_df[TARGET_COLUMN]
    
    print(f"[*] Training features: {len(FEATURE_COLUMNS)}")
    print(f"[*] Train shape: {X_train.shape}, Val shape: {X_val.shape}, Test shape: {X_test.shape}")
    
    results = {}
    trained_models = {}
    scaler = StandardScaler().fit(X_train)
    
    # -------------------------------------------------------------
    # Model 1: Linear Regression (Baseline Pipeline)
    # -------------------------------------------------------------
    print("\n" + "-"*50)
    print("1. Training Model 1: Linear Regression (Baseline Pipeline)...")
    from sklearn.pipeline import Pipeline
    t0 = time.time()
    lr = Pipeline([
        ('scaler', StandardScaler()),
        ('model', Ridge(alpha=1.0))
    ])
    lr.fit(X_train, y_train)
    t_train = time.time() - t0
    
    val_pred_lr = lr.predict(X_val)
    test_pred_lr = lr.predict(X_test)
    
    m1_val = evaluate_predictions(y_val, val_pred_lr, "Val")
    m1_test = evaluate_predictions(y_test, test_pred_lr, "Test")
    results["Linear Regression"] = {**m1_val, **m1_test, "Train_Time_s": round(t_train, 2)}
    trained_models["Linear Regression"] = lr
    print(f"   -> Val  MAE: {m1_val['Val_MAE']} | RMSE: {m1_val['Val_RMSE']} | R2: {m1_val['Val_R2']}")
    print(f"   -> Test MAE: {m1_test['Test_MAE']} | RMSE: {m1_test['Test_RMSE']} | R2: {m1_test['Test_R2']}")
    
    # -------------------------------------------------------------
    # Model 2: Random Forest
    # -------------------------------------------------------------
    print("\n" + "-"*50)
    print("2. Training Model 2: Random Forest Regressor...")
    t0 = time.time()
    rf = RandomForestRegressor(
        n_estimators=100,
        max_depth=16,
        min_samples_split=10,
        max_features='sqrt',
        n_jobs=-1,
        random_state=42
    )
    rf.fit(X_train, y_train)
    t_train = time.time() - t0
    
    val_pred_rf = rf.predict(X_val)
    test_pred_rf = rf.predict(X_test)
    
    m2_val = evaluate_predictions(y_val, val_pred_rf, "Val")
    m2_test = evaluate_predictions(y_test, test_pred_rf, "Test")
    results["Random Forest"] = {**m2_val, **m2_test, "Train_Time_s": round(t_train, 2)}
    trained_models["Random Forest"] = rf
    print(f"   -> Val  MAE: {m2_val['Val_MAE']} | RMSE: {m2_val['Val_RMSE']} | R2: {m2_val['Val_R2']}")
    print(f"   -> Test MAE: {m2_test['Test_MAE']} | RMSE: {m2_test['Test_RMSE']} | R2: {m2_test['Test_R2']}")
    
    # -------------------------------------------------------------
    # Model 3: XGBoost (Gradient Boosting)
    # -------------------------------------------------------------
    print("\n" + "-"*50)
    print("3. Training Model 3: XGBoost Regressor...")
    t0 = time.time()
    xgb_reg = xgb.XGBRegressor(
        n_estimators=250,
        max_depth=6,
        learning_rate=0.06,
        subsample=0.85,
        colsample_bytree=0.85,
        tree_method='hist',
        random_state=42,
        n_jobs=-1
    )
    xgb_reg.fit(
        X_train, y_train,
        eval_set=[(X_val, y_val)],
        verbose=False
    )
    t_train = time.time() - t0
    
    val_pred_xgb = xgb_reg.predict(X_val)
    test_pred_xgb = xgb_reg.predict(X_test)
    
    m3_val = evaluate_predictions(y_val, val_pred_xgb, "Val")
    m3_test = evaluate_predictions(y_test, test_pred_xgb, "Test")
    results["XGBoost"] = {**m3_val, **m3_test, "Train_Time_s": round(t_train, 2)}
    trained_models["XGBoost"] = xgb_reg
    print(f"   -> Val  MAE: {m3_val['Val_MAE']} | RMSE: {m3_val['Val_RMSE']} | R2: {m3_val['Val_R2']}")
    print(f"   -> Test MAE: {m3_test['Test_MAE']} | RMSE: {m3_test['Test_RMSE']} | R2: {m3_test['Test_R2']}")
    
    # -------------------------------------------------------------
    # Model Comparison & Best Selection
    # -------------------------------------------------------------
    print("\n" + "="*80)
    print("MODEL COMPARISON (CHRONOLOGICAL TEST SET: 2017)")
    print("="*80)
    comparison_df = pd.DataFrame(results).T
    print(comparison_df.to_string())
    
    # Best model chosen by lowest Test RMSE
    best_model_name = min(results.keys(), key=lambda m: results[m]['Test_RMSE'])
    best_model = trained_models[best_model_name]
    print(f"\n[+] Selected Best Model: {best_model_name} (Lowest Test RMSE: {results[best_model_name]['Test_RMSE']})")
    
    # Save artifacts
    best_model_path = os.path.join(models_dir, "best_pm25_model.pkl")
    scaler_path = os.path.join(models_dir, "scaler.pkl")
    feature_cols_path = os.path.join(models_dir, "feature_columns.json")
    metrics_path = os.path.join(models_dir, "model_metrics.json")
    
    print(f"[*] Saving best model to {best_model_path}...")
    joblib.dump(best_model, best_model_path)
    
    print(f"[*] Saving scaler to {scaler_path}...")
    joblib.dump(scaler, scaler_path)
    
    print(f"[*] Saving feature columns to {feature_cols_path}...")
    with open(feature_cols_path, "w") as f:
        json.dump({
            "features": FEATURE_COLUMNS,
            "target": TARGET_COLUMN,
            "best_model_name": best_model_name
        }, f, indent=2)
        
    print(f"[*] Saving metrics summary to {metrics_path}...")
    with open(metrics_path, "w") as f:
        json.dump({
            "best_model": best_model_name,
            "metrics": results
        }, f, indent=2)
        
    print("[+] All model artifacts successfully saved!")
    return results, best_model_name

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.abspath(os.path.join(current_dir, ".."))
    proc_data_dir = os.path.join(base_dir, "data", "processed")
    models_dir = os.path.join(base_dir, "models")
    
    train_and_compare_models(proc_data_dir, models_dir)
