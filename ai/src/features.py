import os
import numpy as np
import pandas as pd

def create_time_series_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Constructs time-series features grouped by monitoring station:
    1. Calendar & Cyclical features (hour, day_of_week, month, sin/cos transforms)
    2. Historical lags: t-1, t-2, t-3, t-6, t-12, t-24 for PM2.5
    3. Rolling statistics: 3h, 6h, 12h, 24h means; 6h max and std
    4. Target: Next-hour PM2.5 (t + 1 hour)
    """
    df = df.copy()
    
    # Ensure datetime
    if not np.issubdtype(df['timestamp'].dtype, np.datetime64):
        df['timestamp'] = pd.to_datetime(df['timestamp'])
        
    df = df.sort_values(['station', 'timestamp']).reset_index(drop=True)
    
    # 1. Calendar & Cyclical features
    df['hour'] = df['timestamp'].dt.hour
    df['day'] = df['timestamp'].dt.day
    df['month'] = df['timestamp'].dt.month
    df['day_of_week'] = df['timestamp'].dt.dayofweek
    df['is_weekend'] = (df['day_of_week'] >= 5).astype(int)
    
    # Cyclical hour encoding (smooth 23h -> 0h transition)
    df['hour_sin'] = np.sin(2 * np.pi * df['hour'] / 24.0)
    df['hour_cos'] = np.cos(2 * np.pi * df['hour'] / 24.0)
    # Cyclical month encoding (smooth seasonal transition)
    df['month_sin'] = np.sin(2 * np.pi * (df['month'] - 1) / 12.0)
    df['month_cos'] = np.cos(2 * np.pi * (df['month'] - 1) / 12.0)
    
    # Group by station to calculate lag and rolling features independently
    def generate_station_features(st_df):
        st_df = st_df.sort_values('timestamp').copy()
        
        # Historical Lags for PM2.5
        st_df['pm25_lag_1'] = st_df['PM2.5'].shift(1)
        st_df['pm25_lag_2'] = st_df['PM2.5'].shift(2)
        st_df['pm25_lag_3'] = st_df['PM2.5'].shift(3)
        st_df['pm25_lag_6'] = st_df['PM2.5'].shift(6)
        st_df['pm25_lag_12'] = st_df['PM2.5'].shift(12)
        st_df['pm25_lag_24'] = st_df['PM2.5'].shift(24)
        
        # Historical Lags for environmental / combustion proxy (CO, TEMP, humidity)
        st_df['co_lag_1'] = st_df['CO'].shift(1)
        st_df['temp_lag_1'] = st_df['TEMP'].shift(1)
        st_df['humidity_lag_1'] = st_df['humidity'].shift(1)
        
        # Rolling features (using closed='left' so current measurement doesn't leak into historical rolling)
        # rolling over previous windows:
        rolling_series = st_df['PM2.5'].shift(1)
        st_df['pm25_rolling_mean_3h'] = rolling_series.rolling(window=3, min_periods=3).mean()
        st_df['pm25_rolling_mean_6h'] = rolling_series.rolling(window=6, min_periods=6).mean()
        st_df['pm25_rolling_mean_12h'] = rolling_series.rolling(window=12, min_periods=12).mean()
        st_df['pm25_rolling_mean_24h'] = rolling_series.rolling(window=24, min_periods=24).mean()
        st_df['pm25_rolling_max_6h'] = rolling_series.rolling(window=6, min_periods=6).max()
        st_df['pm25_rolling_std_6h'] = rolling_series.rolling(window=6, min_periods=6).std()
        
        # Target: PM2.5 at t + 1 hour
        st_df['target_pm25_1h'] = st_df['PM2.5'].shift(-1)
        
        return st_df
        
    print("[*] Generating lag and rolling features per monitoring station...")
    df_featured = df.groupby('station', group_keys=False).apply(generate_station_features)
    
    # Drop rows with NaN caused by 24h lag warmup or final target shift
    before_drop = len(df_featured)
    df_featured = df_featured.dropna().reset_index(drop=True)
    after_drop = len(df_featured)
    print(f"[+] Feature engineering complete. Observations: {after_drop:,} (warmup dropped: {before_drop - after_drop})")
    
    return df_featured

def split_chronological(df: pd.DataFrame):
    """
    Performs strict chronological splitting without data leakage:
    - Train: 2013-03-01 to 2015-12-31
    - Validation: 2016-01-01 to 2016-12-31
    - Test: 2017-01-01 to 2017-02-28
    """
    train_mask = df['timestamp'] < '2016-01-01'
    val_mask = (df['timestamp'] >= '2016-01-01') & (df['timestamp'] < '2017-01-01')
    test_mask = df['timestamp'] >= '2017-01-01'
    
    train_df = df[train_mask].reset_index(drop=True)
    val_df = df[val_mask].reset_index(drop=True)
    test_df = df[test_mask].reset_index(drop=True)
    
    print("\n" + "="*60)
    print("CHRONOLOGICAL TRAIN / VALIDATION / TEST SPLIT SUMMARY")
    print("="*60)
    print(f"TRAIN Set      : {len(train_df):,} rows ({train_df['timestamp'].min()} to {train_df['timestamp'].max()})")
    print(f"VALIDATION Set : {len(val_df):,} rows ({val_df['timestamp'].min()} to {val_df['timestamp'].max()})")
    print(f"TEST Set       : {len(test_df):,} rows ({test_df['timestamp'].min()} to {test_df['timestamp'].max()})")
    print("="*60)
    
    return train_df, val_df, test_df

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.abspath(os.path.join(current_dir, ".."))
    proc_data_dir = os.path.join(base_dir, "data", "processed")
    cleaned_parquet = os.path.join(proc_data_dir, "beijing_cleaned.parquet")
    
    if not os.path.exists(cleaned_parquet):
        raise FileNotFoundError(f"{cleaned_parquet} does not exist. Run preprocessing.py first.")
        
    print(f"[*] Loading cleaned dataset from {cleaned_parquet}...")
    cleaned_df = pd.read_parquet(cleaned_parquet)
    
    featured_df = create_time_series_features(cleaned_df)
    train_df, val_df, test_df = split_chronological(featured_df)
    
    # Save datasets
    train_path = os.path.join(proc_data_dir, "train.parquet")
    val_path = os.path.join(proc_data_dir, "val.parquet")
    test_path = os.path.join(proc_data_dir, "test.parquet")
    
    print(f"[*] Saving train dataset to {train_path}...")
    train_df.to_parquet(train_path, index=False)
    print(f"[*] Saving validation dataset to {val_path}...")
    val_df.to_parquet(val_path, index=False)
    print(f"[*] Saving test dataset to {test_path}...")
    test_df.to_parquet(test_path, index=False)
    print("[+] Feature datasets successfully generated and saved!")
