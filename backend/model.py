"""
model.py - thin wrapper to load the emotion model if present,
or use a lightweight fallback heuristic for demo purposes.

Place your model weights (e.g. model.h5 or model.pt) in backend/models/
and update the load_model_block below if needed.
"""

import os
import numpy as np

# Optional: Keras import if you will use a Keras model
try:
    from tensorflow.keras.models import load_model
    _HAS_KERAS = True
except Exception:
    _HAS_KERAS = False

MODEL_PATH_H5 = os.path.join(os.path.dirname(__file__), "models", "model.h5")
MODEL = None

def try_load_model():
    global MODEL
    if MODEL is not None:
        return MODEL
    if os.path.exists(MODEL_PATH_H5) and _HAS_KERAS:
        try:
            print(f"Loading Keras model from {MODEL_PATH_H5} ...")
            MODEL = load_model(MODEL_PATH_H5)
            print("Model loaded.")
            return MODEL
        except Exception as e:
            print("Failed to load keras model:", e)
    # No model found or cannot load
    return None

def map_to_four(emotion_label):
    """Map model/third-party labels to our four: happy, neutral, sad, frustrated."""
    em = str(emotion_label).lower()
    if em in ("happy", "joy", "smile"):
        return "happy"
    if em in ("neutral", "surprise", "calm"):
        return "neutral"
    if em in ("sad", "down"):
        return "sad"
    if em in ("angry", "anger", "fear", "disgust", "contempt", "frustrated", "frustration"):
        return "frustrated"
    # fallback
    return "neutral"

def infer_emotion(image_np):
    """
    image_np: HxWx3 uint8 RGB image
    returns: one of ["happy", "neutral", "sad", "frustrated"]
    """
    # Try real model first
    mdl = try_load_model()
    if mdl is not None:
        try:
            # Example preprocessing for Keras model - adapt to your model
            import cv2
            img = cv2.cvtColor(image_np, cv2.COLOR_RGB2GRAY)
            img = cv2.resize(img, (48,48))
            img = img.astype("float32") / 255.0
            img = np.expand_dims(img, axis=0)
            img = np.expand_dims(img, axis=-1)  # if model expects (1,48,48,1)
            preds = mdl.predict(img)
            idx = int(np.argmax(preds))
            # If model has label mapping file, load & map. For now make best-effort:
            label = str(idx)
            # Map numeric labels to names if your model supports it - otherwise adjust here
            return map_to_four(label)
        except Exception as e:
            print("Model inference failed, falling back:", e)

    # Fallback heuristic (works without model) - fast for demos:
    # Uses brightness (mean) and contrast/texture (std) over the detected face region.
    try:
        # Prefer computing features on the detected face region (more robust)
        try:
            import cv2
            gray_full = cv2.cvtColor(image_np, cv2.COLOR_RGB2GRAY)
            cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
            if os.path.exists(cascade_path):
                face_cascade = cv2.CascadeClassifier(cascade_path)
                faces = face_cascade.detectMultiScale(gray_full, scaleFactor=1.1, minNeighbors=5)
                if len(faces) > 0:
                    # pick the largest face
                    faces = sorted(faces, key=lambda f: f[2]*f[3], reverse=True)
                    x,y,w,h = faces[0]
                    # add small margin
                    pad = int(max(10, 0.15 * max(w,h)))
                    x0 = max(0, x-pad); y0 = max(0, y-pad); x1 = min(gray_full.shape[1], x+w+pad); y1 = min(gray_full.shape[0], y+h+pad)
                    crop = gray_full[y0:y1, x0:x1]

                    # Smile detection on the face crop — strong signal for 'happy'
                    try:
                        smile_cascade_path = cv2.data.haarcascades + 'haarcascade_smile.xml'
                        if os.path.exists(smile_cascade_path):
                            smile_cascade = cv2.CascadeClassifier(smile_cascade_path)
                            # Equalize histogram to improve detection contrast
                            crop_eq = cv2.equalizeHist(crop)
                            smiles = smile_cascade.detectMultiScale(
                                crop_eq,
                                scaleFactor=1.2,
                                minNeighbors=18,
                                minSize=(int(0.15*w), int(0.10*h))
                            )
                            if len(smiles) > 0:
                                return "happy"
                    except Exception:
                        pass

                    gray = crop.astype('float32')
                else:
                    gray = gray_full.astype('float32')
            else:
                # fallback if cascade not found
                gray = cv2.cvtColor(image_np, cv2.COLOR_RGB2GRAY).astype('float32')
        except Exception:
            # if cv2 not available or detection fails, fallback to numpy conversion
            gray = np.dot(image_np[...,:3], [0.2989, 0.5870, 0.1140])
        mean = float(np.mean(gray))
        std = float(np.std(gray))
        # Tuned thresholds for four classes (slightly widened to avoid constant 'neutral')
        # Happy: bright and some texture
        if mean >= 150 and std >= 22:
            return "happy"
        # Sad: darker image with low-mid variance
        if mean < 100 and std < 30:
            return "sad"
        # Frustrated: very noisy/harsh contrast or very dark but textured
        if std > 55 or (mean < 85 and std >= 26):
            return "frustrated"
        # Neutral: low variance or mid-range values
        if std < 10 or (105 <= mean <= 150 and std <= 26):
            return "neutral"
        # Default to neutral instead of confused to avoid ambiguity
        return "neutral"
    except Exception as e:
        print("Fallback heuristic failed:", e)
        return "neutral"

def infer_emotion_detailed(image_np):
    """
    Returns a tuple: (emotion: str, confidence: float, face_found: bool)
    Uses face detection + heuristic; if Keras model available, can be extended to use softmax confidence.
    """
    face_found = False
    try:
        import cv2
        gray_full = cv2.cvtColor(image_np, cv2.COLOR_RGB2GRAY)
        cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
        face_detected = False
        crop = gray_full
        if os.path.exists(cascade_path):
            face_cascade = cv2.CascadeClassifier(cascade_path)
            faces = face_cascade.detectMultiScale(gray_full, scaleFactor=1.1, minNeighbors=5)
            if len(faces) > 0:
                faces = sorted(faces, key=lambda f: f[2]*f[3], reverse=True)
                x,y,w,h = faces[0]
                pad = int(max(10, 0.15 * max(w,h)))
                x0 = max(0, x-pad); y0 = max(0, y-pad); x1 = min(gray_full.shape[1], x+w+pad); y1 = min(gray_full.shape[0], y+h+pad)
                crop = gray_full[y0:y1, x0:x1]
                face_detected = True
        face_found = bool(face_detected)

        # Contrast normalization (CLAHE) improves robustness across lighting
        try:
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
            norm = clahe.apply(crop)
        except Exception:
            norm = cv2.equalizeHist(crop)

        gray = norm.astype('float32')
        mean = float(np.mean(gray))
        std = float(np.std(gray))

        # Smile detection boosts happy (run on normalized crop)
        happy_bonus = 0.0
        try:
            smile_cascade_path = cv2.data.haarcascades + 'haarcascade_smile.xml'
            if os.path.exists(smile_cascade_path):
                smile_cascade = cv2.CascadeClassifier(smile_cascade_path)
                smiles = smile_cascade.detectMultiScale(norm, scaleFactor=1.15, minNeighbors=16)
                if len(smiles) > 0:
                    # Strong signal for happy when a smile is detected
                    happy_bonus = 0.35
                    return 'happy', float(min(1.0, 0.85 + happy_bonus)), face_found
        except Exception:
            pass

        # Class decision
        emotion = 'neutral'
        conf = 0.5
        # Favor non-neutral classes a bit more to avoid constant neutral
        if mean >= 142 and std >= 18:
            emotion = 'happy'; conf = 0.72 + happy_bonus
        elif mean < 108 and std < 28:
            emotion = 'sad'; conf = 0.66
        elif std > 50 or (mean < 95 and std >= 24):
            emotion = 'frustrated'; conf = 0.64
        elif std < 9.5 or (110 <= mean <= 145 and std <= 24):
            emotion = 'neutral'; conf = 0.56

        # Bound confidence
        conf = float(max(0.0, min(1.0, conf)))
        return emotion, conf, face_found
    except Exception as e:
        print("infer_emotion_detailed failed:", e)
        return 'neutral', 0.0, False
