"""
Simple test script to run model inference on a sample image.
Place an image at frontend/test_images/happy.jpg before running,
or edit the path below.
Run: python backend/test_infer.py
"""
import sys
from PIL import Image
import numpy as np
from model import infer_emotion

def main():
    path = "frontend/test_images/happy.jpg"
    try:
        img = Image.open(path).convert("RGB")
    except Exception as e:
        print("Failed to open", path, e)
        sys.exit(1)
    arr = np.array(img)
    print("Running inference...")
    print("Result:", infer_emotion(arr))

if __name__ == "__main__":
    main()
