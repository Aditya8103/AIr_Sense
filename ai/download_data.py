import os
import sys
import zipfile
import urllib.request
import pandas as pd

DATA_URL = "https://archive.ics.uci.edu/static/public/501/beijing+multi+site+air+quality+data.zip"
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
RAW_DIR = os.path.join(BASE_DIR, "data", "raw")
PROCESSED_DIR = os.path.join(BASE_DIR, "data", "processed")
MODELS_DIR = os.path.join(BASE_DIR, "models")
SRC_DIR = os.path.join(BASE_DIR, "src")
NOTEBOOKS_DIR = os.path.join(BASE_DIR, "notebooks")

os.makedirs(RAW_DIR, exist_ok=True)
os.makedirs(PROCESSED_DIR, exist_ok=True)
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(SRC_DIR, exist_ok=True)
os.makedirs(NOTEBOOKS_DIR, exist_ok=True)

zip_dest = os.path.join(RAW_DIR, "beijing_air_quality.zip")

print(f"[*] Checking/Downloading UCI Beijing Multi-Site Air Quality dataset...")
print(f"[*] Source: {DATA_URL}")

if not os.path.exists(zip_dest) or os.path.getsize(zip_dest) < 1000:
    def reporthook(blocknum, blocksize, totalsize):
        readsofar = blocknum * blocksize
        if totalsize > 0:
            percent = readsofar * 1e2 / totalsize
            s = f"\r[->] Download progress: {percent:5.1f}% ({readsofar / (1024 * 1024):.2f} MB / {totalsize / (1024 * 1024):.2f} MB)"
            sys.stderr.write(s)
            if readsofar >= totalsize:
                sys.stderr.write("\n")
        else:
            sys.stderr.write(f"\r[->] Downloaded {readsofar / (1024 * 1024):.2f} MB")
            
    urllib.request.urlretrieve(DATA_URL, zip_dest, reporthook)
    print(f"\n[+] Download complete! Saved to {zip_dest}")
else:
    print(f"[+] Zip file already exists ({os.path.getsize(zip_dest) / (1024 * 1024):.2f} MB)")

# Extract zip
extract_dir = os.path.join(RAW_DIR, "beijing_extracted")
os.makedirs(extract_dir, exist_ok=True)
print(f"[*] Extracting to {extract_dir}...")
with zipfile.ZipFile(zip_dest, 'r') as zip_ref:
    zip_ref.extractall(extract_dir)

# Check if there is an inner zip or folder
extracted_files = []
for root, dirs, files in os.walk(extract_dir):
    for f in files:
        full_p = os.path.join(root, f)
        if f.endswith('.zip'):
            print(f"[*] Found nested zip: {f}, extracting...")
            with zipfile.ZipFile(full_p, 'r') as inner_zip:
                inner_zip.extractall(extract_dir)
        elif f.endswith('.csv'):
            extracted_files.append(full_p)

print(f"\n[+] Total CSV files found: {len(extracted_files)}")
for f in extracted_files:
    fname = os.path.basename(f)
    fsize = os.path.getsize(f) / (1024 * 1024)
    print(f"  - {fname} ({fsize:.2f} MB)")

# Inspect the first CSV
if extracted_files:
    sample_csv = extracted_files[0]
    print(f"\n=======================================================")
    print(f"INSPECTING SAMPLE FILE: {os.path.basename(sample_csv)}")
    print(f"=======================================================")
    df = pd.read_csv(sample_csv)
    print("\n[Shape]:", df.shape)
    print("\n[Columns and Types]:")
    print(df.dtypes)
    print("\n[First 5 Rows]:")
    print(df.head())
    print("\n[Missing Values Summary]:")
    print(df.isnull().sum())
    print("\n[Statistical Summary of Numeric Columns]:")
    print(df.describe().T[['count', 'mean', 'std', 'min', '50%', 'max']])
