import os
import shutil

SOURCE_DIR = os.path.dirname(os.path.abspath(__file__))
RELEASE_DIR = os.path.abspath(os.path.join(SOURCE_DIR, "..", "AirSense-AI-Release"))

print(f"[*] Packaging AirSense AI Release to: {RELEASE_DIR}")
if os.path.exists(RELEASE_DIR):
    shutil.rmtree(RELEASE_DIR)
os.makedirs(RELEASE_DIR, exist_ok=True)

# 1. Models
os.makedirs(os.path.join(RELEASE_DIR, "models"), exist_ok=True)
for item in os.listdir(os.path.join(SOURCE_DIR, "models")):
    src_p = os.path.join(SOURCE_DIR, "models", item)
    if os.path.isfile(src_p):
        shutil.copy2(src_p, os.path.join(RELEASE_DIR, "models", item))

# 2. Source Code
os.makedirs(os.path.join(RELEASE_DIR, "src"), exist_ok=True)
for item in os.listdir(os.path.join(SOURCE_DIR, "src")):
    src_p = os.path.join(SOURCE_DIR, "src", item)
    if os.path.isfile(src_p) and item.endswith('.py'):
        shutil.copy2(src_p, os.path.join(RELEASE_DIR, "src", item))

# 3. Root Runtime Files
root_files = [
    "app.py",
    "requirements.txt",
    "run_service.bat",
    "demo_scenarios.py",
    "sample_request.json",
    "sample_hotspot_request.json",
    "test_api.py",
    "README.md"
]

for rf in root_files:
    src_p = os.path.join(SOURCE_DIR, rf)
    if os.path.exists(src_p):
        shutil.copy2(src_p, os.path.join(RELEASE_DIR, rf))

# Calculate total package size
total_size_bytes = 0
file_count = 0
for root, dirs, files in os.walk(RELEASE_DIR):
    for f in files:
        fp = os.path.join(root, f)
        total_size_bytes += os.path.getsize(fp)
        file_count += 1

print(f"[+] AirSense AI Handover Package Created Successfully!")
print(f"[+] Total Files: {file_count}")
print(f"[+] Total Package Size: {total_size_bytes / 1024:.2f} KB ({total_size_bytes / (1024*1024):.2f} MB)")
