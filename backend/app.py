from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import base64, io, time, os, json, logging, sqlite3
from datetime import datetime
from typing import Any, Dict
from PIL import Image
import numpy as np

BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(BASE_DIR, "data")
ACTIVITIES_PATH = os.path.join(DATA_DIR, "activities.json")
PROGRESS_PATH = os.path.join(DATA_DIR, "progress.json")
DB_PATH = os.path.join(DATA_DIR, "emotions.sqlite3")
FRONTEND_DIST = os.path.abspath(os.path.join(BASE_DIR, "..", "frontend", "dist"))

app = Flask(__name__, static_folder=None)
CORS(app, resources={r"/*": {"origins": "*"}})
logging.basicConfig(level=logging.INFO)

@app.route("/health")
def health():
    return {"status":"ok"}

@app.route("/detect", methods=["POST"])
def detect():
    try:
        data = request.get_json(force=True)
        b64 = data.get("image_base64") if data else None
        if not b64:
            return jsonify({"emotion":"neutral","confidence":0.0,"face_found":False,"timestamp":int(time.time()),"error":"no_image"}),200
        try:
            if "," in b64:
                b64 = b64.split(",",1)[1]
            img = Image.open(io.BytesIO(base64.b64decode(b64)))
        except Exception as e:
            return jsonify({"emotion":"neutral","confidence":0.0,"face_found":False,"timestamp":int(time.time()),"error":f"decode:{e}"}),200
        try:
            from emotion_model import analyze_base64
            return jsonify(analyze_base64(data["image_base64"])),200
        except Exception as e:
            return jsonify({"emotion":"neutral","confidence":0.0,"face_found":True,"timestamp":int(time.time()),"error":f"model:{e}"}),200
    except Exception as e:
        return jsonify({"emotion":"neutral","confidence":0.0,"face_found":False,"timestamp":int(time.time()),"error":f"server:{e}"}),500

#############################################
# Utilities
#############################################
def _db_conn():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    return sqlite3.connect(DB_PATH)

def init_db():
    try:
        with _db_conn() as conn:
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS emotions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user TEXT,
                    module TEXT,
                    activity TEXT,
                    emotion TEXT,
                    timestamp TEXT,
                    session TEXT
                )
                """
            )
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    email TEXT UNIQUE,
                    password TEXT
                )
                """
            )
            conn.execute(
                """
                CREATE TABLE IF NOT EXISTS sessions (
                    id TEXT PRIMARY KEY,
                    user_email TEXT,
                    created_at TEXT
                )
                """
            )
            conn.commit()
    except Exception:
        logging.exception("init_db failed")

def read_json(path: str) -> Any:
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8-sig") as f:
        return json.load(f)

def write_json(path: str, data: Any) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def save_emotion(user: str | None, module: str | None, activity: str | None, emotion: str, timestamp: str, session: str | None = None):
    try:
        with _db_conn() as conn:
            conn.execute(
                "INSERT INTO emotions (user, module, activity, emotion, timestamp, session) VALUES (?,?,?,?,?,?)",
                [user or "guest", module or None, activity or None, emotion, timestamp, session or None],
            )
            conn.commit()
    except Exception:
        logging.exception("save_emotion failed")

def create_session(email: str) -> str:
    import uuid
    sid = uuid.uuid4().hex
    try:
        with _db_conn() as conn:
            conn.execute("INSERT OR REPLACE INTO users (email, password) VALUES (?, COALESCE((SELECT password FROM users WHERE email=?), ''))", [email, email])
            conn.execute("INSERT INTO sessions (id, user_email, created_at) VALUES (?,?,?)", [sid, email, datetime.utcnow().isoformat()+"Z"])
            conn.commit()
    except Exception:
        logging.exception("create_session failed")
    return sid

#############################################
# Content APIs
#############################################
@app.route("/api/modules")
def api_modules():
    data = read_json(ACTIVITIES_PATH) or {}
    modules = data.get("modules", ["Math", "Science", "Reading", "Art"])
    return jsonify({"modules": modules})

def _gen_padding_questions(module: str, need: int, *, activity_id: str = "", existing: set | None = None):
    qs = []
    m = (module or '').lower()
    import random, hashlib
    seed_src = f"{m}|{activity_id}|funlearn-v1"
    seed_int = int(hashlib.sha256(seed_src.encode('utf-8')).hexdigest()[:8], 16)
    rnd = random.Random(seed_int)
    existing = existing or set()
    if m == 'math':
        templates = [
            (lambda a,b: (f"What is {a} + {b}?", str(a+b))),
            (lambda a,b: (f"{a} apples + {b} apples = ?", str(a+b))),
            (lambda a,b: (f"Sum of {a} and {b}?", str(a+b))),
        ]
        for _ in range(need*3):
            a, b = rnd.randint(1,9), rnd.randint(1,9)
            ans = a + b
            qtext, corr = rnd.choice(templates)(a,b)
            if qtext in existing:
                continue
            opts = sorted({ans, ans+1, ans-1 if ans>1 else ans+2, ans+2})
            opts = [str(o) for o in opts][:4]
            rnd.shuffle(opts)
            qs.append({'question': qtext, 'options': opts, 'correct': corr, 'feedback': 'Addition practice!'})
            existing.add(qtext)
            if len(qs) >= need:
                break
    elif m == 'science':
        bank = [
            ("What do plants need to grow?", ["Sunlight","Phone","Plastic","Stone"], "Sunlight"),
            ("Water turns to clouds due to?", ["Sun","Moon","Wind","Sound"], "Sun"),
            ("Snow is which form of water?", ["Solid","Liquid","Gas","Plasma"], "Solid"),
            ("What cycle moves water from earth to sky and back?", ["Water cycle","Rock cycle","Life cycle","Day cycle"], "Water cycle"),
            ("Which one is a gas?", ["Water vapor","Ice","Rock","Wood"], "Water vapor"),
        ]
        rnd.shuffle(bank)
        for q, opts, corr in bank:
            if q in existing: 
                continue
            opts = opts[:]
            rnd.shuffle(opts)
            qs.append({ 'question': q, 'options': opts, 'correct': corr, 'feedback': 'Good science!' })
            existing.add(q)
            if len(qs) >= need:
                break
    elif m == 'reading':
        bank = [
            ("Which word rhymes with 'cat'?", ["hat","tree","dog","sun"], "hat"),
            ("What word do c-a-t make?", ["cat","dog","car","cup"], "cat"),
            ("Which is a sight word?", ["the","giraffe","mountain","banana"], "the"),
            ("Pick the noun:", ["dog","run","quickly","blue"], "dog"),
            ("Which two words rhyme?", ["bat-hat","sun-car","tree-dog","blue-eat"], "bat-hat"),
        ]
        rnd.shuffle(bank)
        for q, opts, corr in bank:
            if q in existing: 
                continue
            opts = opts[:]
            rnd.shuffle(opts)
            qs.append({ 'question': q, 'options': opts, 'correct': corr, 'feedback': 'Nice reading!' })
            existing.add(q)
            if len(qs) >= need:
                break
    else:
        bank = [
            ("Which color do you get by mixing blue and yellow?", ["Green","Purple","Orange","Brown"], "Green"),
            ("Which shape is round?", ["Circle","Square","Triangle","Rectangle"], "Circle"),
            ("Primary colors are:", ["Red Blue Yellow","Green Blue Purple","Red Green Orange","Black White Grey"], "Red Blue Yellow"),
            ("What do you use to glue paper?", ["Glue","Eraser","Ruler","Staple remover"], "Glue"),
        ]
        rnd.shuffle(bank)
        for q, opts, corr in bank:
            if q in existing: 
                continue
            opts = opts[:]
            rnd.shuffle(opts)
            qs.append({ 'question': q, 'options': opts, 'correct': corr, 'feedback': 'Art basics!' })
            existing.add(q)
            if len(qs) >= need:
                break
    return qs

@app.route("/api/activities/<module>")
def api_activities_by_module(module: str):
    data = read_json(ACTIVITIES_PATH) or {"activities": []}
    acts = [a for a in data.get("activities", []) if a.get("module", "").lower() == module.lower()]
    def ensure_min_questions(act, min_q=8):
        try:
            quiz = act.get('content', {}).get('quiz')
            if not quiz or not isinstance(quiz.get('questions', None), list):
                return act
            qs = quiz['questions']
            if len(qs) < min_q:
                needed = min_q - len(qs)
                existing = { (q.get('question') or '') for q in qs }
                qs.extend(_gen_padding_questions(act.get('module',''), needed, activity_id=act.get('id',''), existing=existing))
        except Exception:
            pass
        return act
    acts = [ensure_min_questions(a) for a in acts]
    return jsonify({"activities": acts})

@app.route("/api/activity/<aid>")
def api_activity_by_id(aid: str):
    data = read_json(ACTIVITIES_PATH) or {"activities": []}
    for a in data.get("activities", []):
        if a.get("id") == aid:
            try:
                quiz = a.get('content', {}).get('quiz')
                if quiz and isinstance(quiz.get('questions', None), list):
                    if len(quiz['questions']) < 8:
                        needed = 8 - len(quiz['questions'])
                        existing = { (q.get('question') or '') for q in quiz['questions'] }
                        quiz['questions'].extend(_gen_padding_questions(a.get('module',''), needed, activity_id=a.get('id',''), existing=existing))
            except Exception:
                pass
            return jsonify(a)
    return jsonify({"error": "Not found"}), 404

#############################################
# Emotion detection APIs
#############################################
_SMOOTH_CACHE: dict[str, list[str]] = {}

@app.route("/detect_emotion", methods=["POST"])
def detect_emotion():
    try:
        payload = request.get_json(force=True)
    except Exception:
        return jsonify({"error": "Invalid JSON"}), 400

    image_b64 = (payload or {}).get("image") or (payload or {}).get("image_b64") or (payload or {}).get("image_base64")
    user = (payload or {}).get("user") or "guest"
    module = (payload or {}).get("module")
    activity = (payload or {}).get("activity")
    session_id = (payload or {}).get("session_id")
    if not image_b64:
        return jsonify({"error": "No image provided"}), 400

    ts_epoch = int(datetime.utcnow().timestamp())
    face_found = False
    confidence = 0.0
    label = "neutral"
    try:
        if "," in image_b64:
            image_b64 = image_b64.split(",", 1)[1]
        image_bytes = base64.b64decode(image_b64)
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        img_np = np.array(image)
        try:
            try:
                from model import infer_emotion_detailed as _detailed
            except Exception:
                from backend.model import infer_emotion_detailed as _detailed
            d_label, d_conf, d_face = _detailed(img_np)
            label, confidence, face_found = d_label, float(d_conf), bool(d_face)
        except Exception:
            try:
                try:
                    from model import infer_emotion
                except Exception:
                    from backend.model import infer_emotion
                label = infer_emotion(img_np)
                confidence = 0.5
                face_found = False
            except Exception:
                pass
    except Exception:
        logging.exception("/detect_emotion failed, using fallback")
        import random
        label = random.choice(["happy", "neutral", "sad", "frustrated"]) 
        confidence = 0.3
        face_found = False

    try:
        save_emotion(user, module, activity, label, datetime.utcfromtimestamp(ts_epoch).isoformat()+"Z", session=session_id)
    except Exception:
        pass

    try:
        key = f"{user}|{module}|{activity}"
        arr = _SMOOTH_CACHE.get(key, [])
        arr.append(label)
        if len(arr) > 3:
            arr = arr[-3:]
        _SMOOTH_CACHE[key] = arr
        from collections import Counter
        counts = Counter(arr)
        label = counts.most_common(1)[0][0]
    except Exception:
        pass

    try:
        logging.info(f"detect_emotion user={user} module={module} activity={activity} face_found={face_found} label={label} conf={confidence}")
    except Exception:
        pass
    return jsonify({"emotion": label, "confidence": confidence, "timestamp": ts_epoch, "face_found": face_found})

@app.route("/detect", methods=["POST"])
def detect_alias():
    return detect_emotion()

#############################################
# Auth & Progress APIs
#############################################
@app.route("/login", methods=["POST"])
def login_route():
    try:
        data = request.get_json(force=True)
    except Exception:
        return jsonify({"error": "Invalid JSON"}), 400
    email = (data or {}).get("email") or (data or {}).get("user") or "guest@example.com"
    _ = (data or {}).get("password") or ""
    sid = create_session(email)
    return jsonify({"ok": True, "session_id": sid, "user": email})

@app.route("/api/login", methods=["POST"])
def api_login_alias():
    return login_route()

@app.route("/api/progress", methods=["POST"])
def api_progress_post():
    try:
        data = request.get_json(force=True)
    except Exception:
        return jsonify({"error": "Invalid JSON"}), 400
    user = (data or {}).get("user", "guest")
    module = (data or {}).get("module")
    activity = (data or {}).get("activity")
    if not module or not activity:
        return jsonify({"error": "module and activity required"}), 400
    score = (data or {}).get("score")
    total = (data or {}).get("total")
    entry: Dict[str, Any] = {
        "user": user,
        "module": module,
        "activity": activity,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "score": int(score) if isinstance(score, (int, float, str)) and str(score).isdigit() else None,
        "total": int(total) if isinstance(total, (int, float, str)) and str(total).isdigit() else None,
    }
    items = read_json(PROGRESS_PATH)
    if not isinstance(items, list):
        items = []
    items.append(entry)
    write_json(PROGRESS_PATH, items)
    return jsonify({"ok": True, "saved": entry})

@app.route("/api/progress/<user>")
def api_progress_get(user: str):
    items = read_json(PROGRESS_PATH)
    if not isinstance(items, list):
        items = []
    user_items = [x for x in items if (x.get("user") or "guest") == user]
    return jsonify({"progress": user_items})

@app.route("/api/badges/<user>")
def api_badges(user: str):
    def compute_badges_for_user(user: str):
        items = read_json(PROGRESS_PATH)
        if not isinstance(items, list):
            items = []
        done = [x for x in items if (x.get("user") or "guest") == user]
        done_ids = list({x.get("activity") for x in done if x.get("activity")})
        data = read_json(ACTIVITIES_PATH) or {"activities": [], "modules": []}
        activities = data.get("activities", [])
        module_map = {}
        for a in activities:
            mod = a.get("module") or ""
            module_map.setdefault(mod, set()).add(a.get("id"))
        badges = []
        total_done = len(done_ids)
        if total_done >= 1:
            badges.append({"id": "first-step", "name": "First Step", "emoji": "👣", "description": "Completed your first activity"})
        if total_done >= 3:
            badges.append({"id": "getting-going", "name": "Getting Going", "emoji": "🚀", "description": "Completed 3 activities"})
        if total_done >= 5:
            badges.append({"id": "super-learner", "name": "Super Learner", "emoji": "🌟", "description": "Completed 5 activities"})
        for mod, ids in module_map.items():
            if len(ids) == 0:
                continue
            completed = len([i for i in done_ids if i in ids])
            if completed >= len(ids):
                badges.append({"id": f"master-{mod.lower()}", "name": f"Master of {mod}", "emoji": "🎓", "description": f"Completed all activities in {mod}"})
        return badges
    try:
        badges = compute_badges_for_user(user)
        return jsonify({"badges": badges})
    except Exception:
        logging.exception("/api/badges failed")
        return jsonify({"badges": []}), 200

#############################################
# Serve built frontend (if present)
#############################################
@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve_frontend(path: str):
    # Do not intercept API and service routes
    if path.startswith(('api/', 'detect', 'login', 'emotions')):
        return jsonify({"error": "Not found"}), 404
    try:
        if os.path.exists(FRONTEND_DIST):
            full = os.path.join(FRONTEND_DIST, path)
            if path and os.path.exists(full) and os.path.isfile(full):
                return send_from_directory(FRONTEND_DIST, path)
            index_path = os.path.join(FRONTEND_DIST, 'index.html')
            if os.path.exists(index_path):
                return send_from_directory(FRONTEND_DIST, 'index.html')
    except Exception:
        pass
    return jsonify({"error": "frontend not built", "hint": "Run: cd frontend && npm install && npm run build"}), 500


if __name__ == "__main__":
    init_db()
    try:
        port = int(os.environ.get("PORT", "80"))
    except Exception:
        port = 80
    app.run(host="0.0.0.0", port=port, debug=True)
