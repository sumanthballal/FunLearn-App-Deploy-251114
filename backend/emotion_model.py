# emotion_model.py - placeholder analyze_base64
import base64, io, time
from PIL import Image

def analyze_base64(b64str):
    try:
        # Accept either "data:image/png;base64,..." or raw base64
        if "," in b64str:
            _, data = b64str.split(",", 1)
        else:
            data = b64str
        imgdata = base64.b64decode(data)
        Image.open(io.BytesIO(imgdata))  # validate image
        return {"emotion":"neutral","confidence":0.0,"face_found":False,"timestamp":int(time.time())}
    except Exception:
        return {"emotion":"neutral","confidence":0.0,"face_found":False,"timestamp":int(time.time())}
