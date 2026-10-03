import os
import shutil
import glob
import pandas as pd
import numpy as np

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(BASE_DIR, "data", "raw")
BEIJING_RAW = os.path.join(RAW_DIR, "beijing")
os.makedirs(BEIJING_RAW, exist_ok=True)

# Find all PRSA csvs
source_prsa = glob.glob(os.path.join(RAW_DIR, "**", "PRSA_Data_*_20130301-20170228.csv"), recursive=True)
print(f"[*] Found {len(source_prsa)} PRSA station CSV files.")

# Copy/move them to BEIJING_RAW if not already there
for f in source_prsa:
    target = os.path.join(BEIJING_RAW, os.path.basename(f))
    if os.path.abspath(f) != os.path.abspath(target):
        shutil.copy2(f, target)

# Clean up temporary extracted folder if exists
temp_extracted = os.path.join(RAW_DIR, "beijing_extracted")
if os.path.exists(temp_extracted):
    shutil.rmtree(temp_extracted, ignore_errors=True)

station_files = sorted(glob.glob(os.path.join(BEIJING_RAW, "*.csv")))
print(f"[+] Total organized station files in {BEIJING_RAW}: {len(station_files)}")

# Detailed inspection
total_records = 0
dfs = []
station_summaries = []

for sf in station_files:
    station_name = os.path.basename(sf).replace("PRSA_Data_", "").replace("_20130301-20170228.csv", "")
    df = pd.read_csv(sf)
    count = len(df)
    total_records += count
    null_pm25 = df['PM2.5'].isnull().sum()
    station_summaries.append({
        "Station": station_name,
        "File Size (MB)": round(os.path.getsize(sf) / (1024 * 1024), 2),
        "Total Rows": count,
        "Null PM2.5": null_pm25,
        "Null PM2.5 (%)": round(null_pm25 / count * 100, 2),
        "Mean PM2.5": round(df['PM2.5'].mean(), 1),
        "Max PM2.5": round(df['PM2.5'].max(), 1)
    })
    if len(dfs) == 0:
        sample_df = df.copy()

summary_table = pd.DataFrame(station_summaries)
print("\n" + "="*80)
print("UCI BEIJING MULTI-SITE AIR QUALITY DATASET SUMMARY")
print("="*80)
print(summary_table.to_string(index=False))
print(f"\n[*] Total Rows across all 12 stations: {total_records:,}")

print("\n" + "="*80)
print(f"SAMPLE STATION DETAILED SCHEMA: {station_summaries[0]['Station']}")
print("="*80)
print("[Shape]:", sample_df.shape)
print("\n[Column Data Types]:")
print(sample_df.dtypes)

print("\n[First 5 Rows]:")
print(sample_df.head())

print("\n[Missing Values Count and Percentage]:")
missing_info = pd.DataFrame({
    'Column': sample_df.columns,
    'Null Count': sample_df.isnull().sum().values,
    'Null %': np.round(sample_df.isnull().sum().values / len(sample_df) * 100, 2)
})
print(missing_info.to_string(index=False))

print("\n[Statistical Distribution (Numeric Columns)]:")
print(sample_df.describe().T[['count', 'mean', 'std', 'min', '25%', '50%', '75%', 'max']])

# Unique wind directions
print("\n[Wind Direction ('wd') categories]:")
print(sample_df['wd'].unique())

# Check timestamp range
sample_df['timestamp'] = pd.to_datetime(sample_df[['year', 'month', 'day', 'hour']])
print(f"\n[Temporal Range]: From {sample_df['timestamp'].min()} To {sample_df['timestamp'].max()}")
print(f"[Sampling Frequency]: Hourly ({len(sample_df)} hours = {len(sample_df)/24:.1f} days = ~4 years)")
