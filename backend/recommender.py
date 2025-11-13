import json
import os
import random
from typing import List, Dict, Any

DATA_PATH = os.path.join(os.path.dirname(__file__), "data", "activities.json")

with open(DATA_PATH, "r", encoding="utf-8") as f:
    DATA = json.load(f)

ACTIVITIES: List[Dict[str, Any]] = DATA["activities"]


def recommend_by_emotion(emotion: str, module: str | None = None) -> List[Dict[str, Any]]:
    em = (emotion or "").lower()
    pool = [a for a in ACTIVITIES if (module is None or a["module"].lower() == module.lower())]
    if not pool:
        pool = ACTIVITIES[:]

    if em in ("frustrated", "confused"):
        filtered = [a for a in pool if a["type"] in ("fun", "practice") and a.get("difficulty", "easy") in ("easy", "medium")]
    elif em == "sad":
        filtered = [a for a in pool if a["type"] == "fun"]
    else:
        filtered = [a for a in pool if a["type"] in ("lesson", "practice")]

    if not filtered:
        filtered = pool

    random.shuffle(filtered)
    return filtered[:3]


def recommend(current_module: str | None, current_activity: str | None, emotion: str, history: Dict[str, Any] | None = None):
    return recommend_by_emotion(emotion, current_module)
