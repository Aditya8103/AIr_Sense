import os
import glob
import numpy as np
import pandas as pd

def calculate_relative_humidity(temp_c: pd.Series, dewp_c: pd.Series) -> pd.Series:
    """
    Computes Relative Humidity (%) from Ambient Temperature and Dew Point Temperature
    using the August-Roche-Magnus approximation formula:
    RH = 100 * exp((17.625 * Td) / (243.04 + Td) - (17.625 * T) / (243.04 + T))
    """
    # Magnus coefficients
    a = 17.625
    b = 243.04
    alpha_dew = (a * dewp_c) / (b + dewp_c)
    alpha_temp = (a * temp_c) / (b + temp_c)
    rh = 100.0 * np.exp(alpha_dew - alpha_temp)
    # Clip physically impossible bounds [0, 100]%
    return rh.clip(lower=0.0, upper=100.0)

def clean_station_dataframe(df: pd.DataFrame, station_name: str = None) -> pd.DataFrame:
    """
    Cleans a single station time-series DataFrame:
    1. Builds unified datetime timestamp from year, month, day, hour.
    2. Sorts chronologically.
    3. Handles missing values via time-series interpolation for short gaps.
    4. Computes Relative Humidity from TEMP and DEWP.
    5. Validates non-negative constraints for physical quantities.
    """
    df = df.copy()
    
    # 1. Unified timestamp
    df['timestamp'] = pd.to_datetime(df[['year', 'month', 'day', 'hour']])
    df = df.sort_values('timestamp').reset_index(drop=True)
    
    # Drop arbitrary index column 'No' if present
    if 'No' in df.columns:
        df = df.drop(columns=['No'])
        
    if station_name is None and 'station' in df.columns:
        station_name = df['station'].iloc[0]
        
    # 2. Compute Relative Humidity before interpolating
    # First linearly interpolate weather variables to ensure smooth humidity
    weather_cols = ['TEMP', 'PRES', 'DEWP', 'WSPM']
    for col in weather_cols:
        if col in df.columns:
            df[col] = df[col].interpolate(method='linear', limit=6, limit_direction='both')
            df[col] = df[col].bfill().ffill()
            
    df['humidity'] = calculate_relative_humidity(df['TEMP'], df['DEWP'])
    
    # Rain missing values are 0.0 mm
    if 'RAIN' in df.columns:
        df['RAIN'] = df['RAIN'].fillna(0.0).clip(lower=0.0)
        
    # Wind direction missing: forward fill
    if 'wd' in df.columns:
        df['wd'] = df['wd'].ffill().bfill()
        
    # 3. Clean Pollutant columns:
    # Linear interpolation for gaps <= 4 hours, then ffill/bfill
    pollutant_cols = ['PM2.5', 'PM10', 'SO2', 'NO2', 'CO', 'O3']
    for col in pollutant_cols:
        if col in df.columns:
            # Interpolate short temporal gaps
            df[col] = df[col].interpolate(method='linear', limit=4, limit_direction='both')
            # For remaining gaps, forward fill then back fill
            df[col] = df[col].ffill().bfill()
            # Physical bounds: pollutant concentrations cannot be negative
            df[col] = df[col].clip(lower=0.0)
            
    df['station'] = station_name
    return df

def process_raw_dataset(raw_dir: str, processed_dir: str) -> pd.DataFrame:
    """
    Processes all 12 raw station CSV files and saves the unified cleaned dataset.
    """
    os.makedirs(processed_dir, exist_ok=True)
    csv_files = sorted(glob.glob(os.path.join(raw_dir, "*.csv")))
    
    if not csv_files:
        raise FileNotFoundError(f"No CSV files found in {raw_dir}")
        
    print(f"[*] Found {len(csv_files)} station files to process.")
    cleaned_station_dfs = []
    
    for f in csv_files:
        station_name = os.path.basename(f).replace("PRSA_Data_", "").replace("_20130301-20170228.csv", "")
        print(f"  -> Processing station: {station_name}...")
        df_raw = pd.read_csv(f)
        df_clean = clean_station_dataframe(df_raw, station_name=station_name)
        cleaned_station_dfs.append(df_clean)
        
    unified_df = pd.concat(cleaned_station_dfs, ignore_index=True)
    print(f"\n[+] Total cleaned observations: {len(unified_df):,}")
    print(f"[+] Null values remaining across dataset:\n{unified_df.isnull().sum()}")
    
    output_parquet = os.path.join(processed_dir, "beijing_cleaned.parquet")
    output_csv = os.path.join(processed_dir, "beijing_cleaned_sample.csv")
    
    print(f"[*] Saving cleaned parquet to {output_parquet}...")
    unified_df.to_parquet(output_parquet, index=False)
    
    # Save first 5000 rows as CSV sample for quick manual inspection
    print(f"[*] Saving sample CSV to {output_csv}...")
    unified_df.head(5000).to_csv(output_csv, index=False)
    
    return unified_df

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.abspath(os.path.join(current_dir, ".."))
    raw_data_dir = os.path.join(base_dir, "data", "raw", "beijing")
    proc_data_dir = os.path.join(base_dir, "data", "processed")
    
    print(f"[*] Raw data path: {raw_data_dir}")
    print(f"[*] Processed data path: {proc_data_dir}")
    process_raw_dataset(raw_data_dir, proc_data_dir)
