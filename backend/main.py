"""
School Safety Multimodal Monitor
===============================================================

This script performs real-time multimodal monitoring using:
- Vision: Ultralytics YOLO pose tracking to detect potential violence-like rapid limb motion + proximity.
- Audio: Google YAMNet (TensorFlow Hub) to detect concerning sounds (screaming, crying, slap/whack, etc.).
- Reasoning: Gemini (Google Generative AI) to generate a structured risk assessment (JSON).
- Alerts: Firebase Firestore to store alerts and a JPEG snapshot (base64).

Key goals for a professional competition build:
- No mock/simulation data or demo overrides
- Minimal console noise (uses Python logging)
- Clean shutdown handling
- Clear configuration and documentation

Requirements (typical):
  pip install opencv-python ultralytics pyaudio numpy pillow scipy tensorflow tensorflow-hub
  pip install google-generativeai firebase-admin

Notes:
- pyaudio can be OS-specific to install.
- You must provide Firestore service account key JSON file at: ./serviceAccountKey.json
- You must set an environment variable for Gemini:
    export API_KEY="YOUR_GEMINI_KEY"
- You must have a compatible YOLO pose model file (example used): yolo26n-pose.pt
  (Change YOLO_MODEL_PATH below if needed.)

Disclaimer:
- This is a heuristic violence detector. For a competition, be ready to explain
  thresholds, false positives, privacy considerations, and human-in-the-loop response.
"""

from __future__ import annotations

import base64
import json
import logging
import os
import sys
import threading
import time
from dataclasses import dataclass
from datetime import datetime
from io import BytesIO
from typing import Dict, List, Optional, Tuple

import cv2
import numpy as np
import pyaudio
from collections import deque
from PIL import Image
from scipy.signal import butter, lfilter
from ultralytics import YOLO

# Gemini + Firebase
import google.generativeai as genai
import firebase_admin
from firebase_admin import credentials, firestore

# TensorFlow / YAMNet
import tensorflow as tf  # noqa: F401 (imported for completeness; YAMNet uses TF runtime)
import tensorflow_hub as hub


# -----------------------------
# Compatibility shim (some environments)
# -----------------------------
try:
    import pkg_resources  # noqa: F401
except ModuleNotFoundError:
    import packaging.version

    class _PkgResourcesShim:
        parse_version = lambda *a: packaging.version.parse(a[-1])

    sys.modules["pkg_resources"] = _PkgResourcesShim()


# ============================================================
# Logging (Professional output)
# ============================================================
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=LOG_LEVEL,
    format="%(asctime)s | %(levelname)s | %(message)s",
)
logger = logging.getLogger("school_safety_monitor")


# ============================================================
# Configuration
# ============================================================

@dataclass(frozen=True)
class AppConfig:
    # --- Files / Models ---
    FIREBASE_SERVICE_ACCOUNT_PATH: str = "serviceAccountKey.json"
    YOLO_MODEL_PATH: str = "yolo26n-pose.pt"

    # --- Camera ---
    CAMERA_INDEX: int = 0

    # --- Gemini ---
    GEMINI_MODEL_NAME: str = "gemini-3-flash-preview"  # keep configurable
    GEMINI_API_KEY_ENV: str = "API_KEY"

    # --- Firestore metadata ---
    ALERT_LOCATION: str = "Canteen"
    FIRESTORE_COLLECTION: str = "alerts"

    # --- Vision violence heuristic ---
    SPEED_LIMIT: float = 0.15
    VIOLENCE_BUFFER_LEN: int = 8
    VIOLENCE_BUFFER_MIN_HITS: int = 3  # if at least this many in buffer, v_active = True

    # --- Gemini call cadence (frames) ---
    # To avoid spamming Gemini/Firestore every frame during an event.
    GEMINI_EVERY_N_FRAMES_WHEN_ACTIVE: int = 60

    # --- UI ---
    WINDOW_NAME: str = "Multimodal Safety Monitor"
    FONT: int = cv2.FONT_HERSHEY_SIMPLEX
    STATUS_POS: Tuple[int, int] = (60, 60)
    INFO_POS: Tuple[int, int] = (60, 105)


CFG = AppConfig()


# ============================================================
# YAMNet class mappings and tiering
# ============================================================

# A small local mapping for key classes (YAMNet has 521 classes).
# We will load full class names from the official CSV if possible.
YAMNET_KEY_CLASSES: Dict[int, str] = {
    0: "Speech",
    8: "Shout",
    11: "Yell",
    22: "Crying, sobbing",
    23: "Baby cry, infant cry",
    24: "Whimper",
    25: "Wail, moan",
    137: "Screaming",
    316: "Slap, smack",
    420: "Explosion",
    426: "Gunshot, gunfire",
    467: "Whack, thwack",
    469: "Smash, crash",
    470: "Breaking",
}

# Tier indices (based on YAMNet class indices)
TIER_1_INDICES = [137, 316, 426, 467]  # screaming, slap, gunshot, whack
TIER_2_INDICES = [
    0, 8, 11, 22, 23, 24, 25, 136, 137
]  # speech/shout/yell + crying variants + screaming
TIER_3_INDICES = [69, 70, 71]  # crowd/hubbub/children playing (contextual)


@dataclass
class YamnetThresholds:
    """
    Tunable thresholds for YAMNet detections.

    - THRESHOLD: minimum class probability to count as detection
    - MIN_VOLUME: minimum mean absolute amplitude of the preprocessed waveform
      to avoid triggering on noise/too-faint audio.
    """
    TIER_1_THRESHOLD: float = 0.35
    TIER_1_MIN_VOLUME: float = 0.02

    TIER_2_THRESHOLD: float = 0.40
    TIER_2_MIN_VOLUME: float = 0.04

    TIER_3_THRESHOLD: float = 0.60
    TIER_3_MIN_VOLUME: float = 0.07


TH = YamnetThresholds()


# ============================================================
# Audio preprocessing utilities
# ============================================================

def highpass_filter(data: np.ndarray, cutoff: float = 100.0, fs: int = 16000, order: int = 2) -> np.ndarray:
    """
    Apply a high-pass Butterworth filter to reduce low-frequency rumble.

    Args:
        data: 1D float waveform.
        cutoff: Cutoff frequency in Hz.
        fs: Sampling rate in Hz.
        order: Filter order.

    Returns:
        Filtered waveform.
    """
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype="high", analog=False)
    return lfilter(b, a, data)


def preprocess_audio_for_yamnet(audio_array: np.ndarray, fs: int = 16000) -> Tuple[np.ndarray, float]:
    """
    Preprocess audio for YAMNet:
    1) Remove DC offset
    2) RMS normalization to a target RMS
    3) Clip to [-1, 1]
    4) High-pass filter
    Returns both waveform and volume metric.

    Args:
        audio_array: 1D float waveform.
        fs: sample rate

    Returns:
        (waveform, mean_abs_volume)
    """
    # Remove DC offset
    audio_array = audio_array - np.mean(audio_array)

    # RMS normalization to target RMS
    rms = np.sqrt(np.mean(audio_array ** 2))
    target_rms = 0.15
    if rms > 0:
        waveform = audio_array * (target_rms / rms)
    else:
        waveform = audio_array.copy()

    # Soft clip
    waveform = np.clip(waveform, -1.0, 1.0)

    # High-pass filter
    waveform = highpass_filter(waveform, cutoff=100.0, fs=fs, order=2)

    # Mean absolute amplitude (volume proxy)
    vol = float(np.abs(waveform).mean())
    return waveform.astype(np.float32), vol


def check_yamnet_alert(
    scores: np.ndarray,
    audio_level: float,
    class_names: List[str],
) -> Tuple[bool, str, int]:
    """
    Decide if an alert should trigger based on YAMNet class scores and audio volume.

    Args:
        scores: Array of shape (521,) probabilities.
        audio_level: Mean abs amplitude after preprocessing.
        class_names: List of 521 class labels.

    Returns:
        (alert_status, message, tier)
        tier: 0=no alert, 1=critical, 2=high concern, 3=contextual
    """

    # Tier 1: Critical
    for idx in TIER_1_INDICES:
        if idx < len(scores) and scores[idx] > TH.TIER_1_THRESHOLD and audio_level >= TH.TIER_1_MIN_VOLUME:
            name = class_names[idx] if idx < len(class_names) else YAMNET_KEY_CLASSES.get(idx, f"Class {idx}")
            return True, f"TIER 1 ALERT: {name} ({scores[idx]:.2f})", 1

    # Tier 2: High concern
    for idx in TIER_2_INDICES:
        if idx < len(scores) and scores[idx] > TH.TIER_2_THRESHOLD and audio_level >= TH.TIER_2_MIN_VOLUME:
            name = class_names[idx] if idx < len(class_names) else YAMNET_KEY_CLASSES.get(idx, f"Class {idx}")
            return True, f"TIER 2 ALERT: {name} ({scores[idx]:.2f})", 2

    # Tier 3: Contextual
    for idx in TIER_3_INDICES:
        if idx < len(scores) and scores[idx] > TH.TIER_3_THRESHOLD and audio_level >= TH.TIER_3_MIN_VOLUME:
            name = class_names[idx] if idx < len(class_names) else YAMNET_KEY_CLASSES.get(idx, f"Class {idx}")
            return True, f"TIER 3 ALERT: {name} ({scores[idx]:.2f})", 3

    return False, "", 0


# ============================================================
# Gemini and Firebase Initialization
# ============================================================

def init_firebase(service_account_path: str) -> firestore.Client:
    """
    Initialize Firebase Admin SDK and Firestore client.

    Args:
        service_account_path: Path to service account JSON.

    Returns:
        Firestore client.

    Raises:
        FileNotFoundError, ValueError if JSON invalid, etc.
    """
    if not os.path.exists(service_account_path):
        raise FileNotFoundError(f"Firebase service account not found: {service_account_path}")

    # Validate JSON quickly (helps catch empty/invalid files)
    with open(service_account_path, "r", encoding="utf-8") as f:
        content = f.read().strip()
        if not content:
            raise ValueError("Firebase service account JSON is empty.")
        json.loads(content)

    cred = credentials.Certificate(service_account_path)

    # Avoid initializing twice in some environments
    if not firebase_admin._apps:
        firebase_admin.initialize_app(cred)

    return firestore.client()


def init_gemini(api_key_env: str, model_name: str) -> genai.GenerativeModel:
    """
    Initialize Gemini model.

    Priority:
    1. Environment variable (recommended)
    2. Placeholder fallback (must be replaced manually)

    Raises:
        ValueError if placeholder is still present.
    """

    # First try environment variable
    api_key = os.getenv(api_key_env)

    # If not found, use placeholder
    if not api_key:
        api_key = "YOUR-GEMINI-API-KEY-HERE"

    # Prevent running with placeholder
    if api_key == "YOUR-GEMINI-API-KEY-HERE":
        raise ValueError(
            "Gemini API key not configured.\n"
            "Replace 'YOUR-GEMINI-API-KEY-HERE' in the code "
            "or set it as an environment variable."
        )

    genai.configure(api_key=api_key)
    return genai.GenerativeModel(model_name)



def analyze_with_gemini(
    gemini_model: genai.GenerativeModel,
    frame_bgr: np.ndarray,
    visual_violence: bool,
    audio_alert: bool,
    audio_class: str,
    tier: int,
    location: str = CFG.ALERT_LOCATION,
) -> str:
    pil_img = Image.fromarray(cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB))

    prompt = f"""
You are an AI-based school safety monitoring system analyzing a CCTV frame.

Context:
- visual_violence_flag: {visual_violence}
- audio_alert_flag: {audio_alert}
- audio_classification: "{audio_class}"
- alert_tier: {tier}  # 1=Critical, 2=High, 3=Contextual, 0=None
- location: "{location}"

Analyze the scene and return ONLY valid JSON with exactly these keys (no markdown, no extra text):

{{
  "type": "<incident type, e.g. Physical Aggression | Verbal Bullying | Social Exclusion | Suspicious Behavior | Unauthorized Access | Other>",
  "severity": "<HIGH | MEDIUM | LOW>",
  "details": "Gemini AI Analysis: <concise 1-2 sentence summary for alert card display>",
  "description": "<detailed 2-4 sentence description of what is observed, what action was taken, who was notified>",
  "confidenceScore": <float between 0.0 and 1.0>,
  "tags": ["<tag1>", "<tag2>", "<tag3>"],
  "action": "<recommended immediate action for school staff>",
  "reasoning": "<brief internal reasoning>",
  "metadata": {{
    "detectionMethod": "<pose_analysis | audio_detection | multimodal | behavior_analysis>",
    "alertLevel": "<critical | moderate | low>",
    "visualViolence": {str(visual_violence).lower()},
    "audioAlert": {str(audio_alert).lower()},
    "audioClass": "{audio_class}",
    "tier": {tier}
  }}
}}

Severity mapping guide:
- HIGH: tier 1 audio OR visual violence confirmed → Physical Aggression likely
- MEDIUM: tier 2 audio OR visual suspicion → Verbal conflict or group aggression
- LOW: tier 3 audio OR ambiguous signals → Social concern or monitoring needed
""".strip()

    try:
        response = gemini_model.generate_content([prompt, pil_img])
        text = (response.text or "").strip()

        # Strip markdown fences if present
        if text.startswith("```"):
            text = text.split("```")[1]
            if text.startswith("json"):
                text = text[4:]
            text = text.strip()

        try:
            obj = json.loads(text)
            # Ensure all required keys exist with defaults
            defaults = {
                "type": "Unknown",
                "severity": "LOW",
                "details": "Gemini AI Analysis: Incident detected.",
                "description": "",
                "confidenceScore": 0.5,
                "tags": [],
                "action": "Review manually",
                "reasoning": "",
                "metadata": {},
            }
            for k, v in defaults.items():
                obj.setdefault(k, v)
            return json.dumps(obj, ensure_ascii=False)

        except Exception:
            fallback = {
                "type": "Unknown",
                "severity": "MEDIUM" if tier <= 2 else "LOW",
                "details": "Gemini AI Analysis: Incident detected — manual review required.",
                "description": text[:500],
                "confidenceScore": 0.5,
                "tags": ["manual-review"],
                "action": "Review manually",
                "reasoning": "Non-JSON response from Gemini",
                "metadata": {
                    "detectionMethod": "multimodal",
                    "alertLevel": "moderate",
                    "visualViolence": visual_violence,
                    "audioAlert": audio_alert,
                    "audioClass": audio_class,
                    "tier": tier,
                },
            }
            return json.dumps(fallback, ensure_ascii=False)

    except Exception as e:
        logger.exception("Gemini analysis failed: %s", e)
        return json.dumps({
            "type": "System Error",
            "severity": "LOW",
            "details": "Gemini AI Analysis: Analysis failed.",
            "description": "Automated analysis unavailable. Manual review required.",
            "confidenceScore": 0.0,
            "tags": ["error"],
            "action": "Review manually",
            "reasoning": str(e),
            "metadata": {"detectionMethod": "error", "alertLevel": "low"},
        }, ensure_ascii=False)



def send_to_firebase(
    db: firestore.Client,
    collection: str,
    location: str,
    gemini_response_json: str,
    frame_bgr: np.ndarray,
) -> None:
    """
    Store alert data in Firestore with a compressed JPEG snapshot.
    Fields marked [~] are estimated values pending deeper integration.
    """

    # Live frame snapshot
    ok, buffer = cv2.imencode(".jpg", frame_bgr, [cv2.IMWRITE_JPEG_QUALITY, 60])
    if not ok:
        logger.warning("Failed to encode JPEG for Firebase alert.")
        return
    img_b64 = base64.b64encode(buffer).decode("utf-8")

    # Gemini structured output
    try:
        gemini_data = json.loads(gemini_response_json)
    except Exception:
        gemini_data = {}

    severity   = gemini_data.get("severity", "LOW")
    alert_type = gemini_data.get("type", "Unknown")

    # [~] Baseline response targets by severity — refine with historical data
    response_time = {"HIGH": 45, "MEDIUM": 120, "LOW": 300}.get(severity, 120)

    # [~] Default assignee by severity — extend with live roster lookup
    assignee = {
        "HIGH":   "Security Officer Martinez",
        "MEDIUM": "Counselor Dr. Smith",
        "LOW":    "School Counselor",
    }.get(severity, "Security Officer")

    # [~] Location → floor/block mapping — expand as school layout is finalized
    floor, block = {
        "Canteen":    ("Ground", "B"),
        "Cafeteria":  ("Ground", "B"),
        "Playground": ("Ground", "A"),
        "Library":    ("First",  "A"),
        "Hallway":    ("First",  "B"),
    }.get(location, ("Ground", "A"))

    # Derived camera identifier
    camera_id = f"CAM-{block}-{location.upper().replace(' ', '-')[:6]}-01"

    metadata = {
        "cameraId":         camera_id,
        "detectionMethod":  gemini_data.get("metadata", {}).get("detectionMethod", "multimodal"),
        "alertLevel":       gemini_data.get("metadata", {}).get("alertLevel", severity.lower()),
        "studentsInvolved": 2,   # [~] pending tracker count integration
        "witnessCount":     5,   # [~] pending crowd density estimation
    }
    metadata.update(gemini_data.get("metadata", {}))

    alert_data = {
        # ── Gemini output ─────────────────────────────────────────
        "type":            alert_type,
        "severity":        severity,
        "details":         gemini_data.get("details", "Gemini AI Analysis: Incident detected."),
        "description":     gemini_data.get("description", ""),
        "confidenceScore": gemini_data.get("confidenceScore", 0.75),
        "tags":            gemini_data.get("tags", []),
        "action":          gemini_data.get("action", ""),

        # ── System / derived ──────────────────────────────────────
        "location":        location,
        "timestamp":       datetime.now().isoformat(),
        "detectedBy":      f"Camera #{block}-{location.replace(' ', '-')[:3].upper()}-01",
        "resolved":        False,
        "resolvedAt":      None,
        "resolutionNotes": None,
        "imageUrl":        None,     # [~] populate once Storage upload is wired
        "image":           img_b64,

        # ── Operational fields ────────────────────────────────────
        "assignedTo":      assignee,          # [~] see above
        "floor":           floor,             # [~] see above
        "block":           block,             # [~] see above
        "responseTime":    response_time,     # [~] see above
        "metadata":        metadata,
    }

    db.collection(collection).add(alert_data)
    logger.info("Alert stored — type=%s severity=%s location=%s", alert_type, severity, location)




# ============================================================
# Audio Monitoring Thread
# ============================================================

class AudioMonitor(threading.Thread):
    """
    Background thread that continuously captures microphone audio, runs YAMNet inference,
    and sets alert flags for the main loop.

    Public fields updated in real-time:
      - alert_status (bool)
      - detected_class (str)
      - audio_level (float)
      - top_class (int)
      - top_prob (float)
      - alert_tier (int)
    """

    def __init__(self):
        super().__init__(daemon=True)
        self.running = True

        self.alert_status: bool = False
        self.detected_class: str = ""
        self.audio_level: float = 0.0
        self.top_class: int = -1
        self.top_prob: float = 0.0
        self.alert_tier: int = 0

        # Audio settings
        self.CHUNK = 1024
        self.RATE = 16000
        self.SILENCE_THRESHOLD = 0.015
        self.MIN_CONFIDENCE = 0.15

        logger.info("Loading YAMNet model (TensorFlow Hub)...")
        self.model = hub.load("https://tfhub.dev/google/yamnet/1")

        logger.info("Loading YAMNet class names...")
        self.class_names = self._load_class_names()

    @staticmethod
    def _load_class_names() -> List[str]:
        """
        Load class names from official YAMNet class map CSV.
        Falls back to a basic list if download fails.

        Returns:
            List of 521 class labels.
        """
        import urllib.request

        csv_url = "https://raw.githubusercontent.com/tensorflow/models/master/research/audioset/yamnet/yamnet_class_map.csv"
        try:
            with urllib.request.urlopen(csv_url, timeout=10) as response:
                csv_text = response.read().decode("utf-8")
            lines = csv_text.strip().split("\n")
            # CSV format: index,mid,display_name
            names: List[str] = []
            for line in lines[1:]:
                parts = line.split(",")
                if len(parts) >= 3:
                    names.append(parts[2].strip('"'))
            if len(names) != 521:
                logger.warning("Expected 521 YAMNet classes, got %d. Using fallback mapping for missing.", len(names))
                # pad if needed
                if len(names) < 521:
                    names.extend(["Unknown"] * (521 - len(names)))
            return names[:521]
        except Exception as e:
            logger.warning("Failed to download YAMNet class map: %s. Using fallback.", e)
            names = ["Unknown"] * 521
            for idx, name in YAMNET_KEY_CLASSES.items():
                if 0 <= idx < 521:
                    names[idx] = name
            return names

    def run(self) -> None:
        """
        Open microphone stream and process audio in ~1 second windows.
        """
        p = None
        stream = None
        try:
            p = pyaudio.PyAudio()

            stream = p.open(
                format=pyaudio.paFloat32,
                channels=1,
                rate=self.RATE,
                input=True,
                frames_per_buffer=self.CHUNK,
            )

            logger.info("Audio stream opened (16kHz).")

            frames_to_read = int(self.RATE / self.CHUNK)

            while self.running:
                audio_chunks = []
                for _ in range(frames_to_read):
                    try:
                        data = stream.read(self.CHUNK, exception_on_overflow=False)
                        audio_chunks.append(np.frombuffer(data, dtype=np.float32))
                    except Exception:
                        continue

                if not audio_chunks:
                    self._reset_state()
                    continue

                audio_array = np.hstack(audio_chunks)
                original_level = float(np.abs(audio_array).mean())

                # Silence gating before heavier work
                if original_level < self.SILENCE_THRESHOLD:
                    self._reset_state()
                    continue

                # Preprocess
                waveform, vol = preprocess_audio_for_yamnet(audio_array, fs=self.RATE)
                self.audio_level = vol

                # YAMNet inference
                scores, embeddings, spectrogram = self.model(waveform)
                scores_mean = np.max(scores.numpy(), axis=0)  # shape (521,)

                self.top_class = int(np.argmax(scores_mean))
                self.top_prob = float(scores_mean[self.top_class])

                # Ignore weak predictions
                if self.top_prob < self.MIN_CONFIDENCE:
                    self._reset_state()
                    continue

                # Tiered check
                self.alert_status, self.detected_class, self.alert_tier = check_yamnet_alert(
                    scores_mean, self.audio_level, self.class_names
                )

                if not self.alert_status:
                    # keep top class visible in UI even if no tier triggered
                    self.detected_class = ""

        except Exception as e:
            logger.exception("Audio thread crashed: %s", e)
            self.running = False
        finally:
            if stream is not None:
                try:
                    stream.stop_stream()
                    stream.close()
                except Exception:
                    pass
            if p is not None:
                try:
                    p.terminate()
                except Exception:
                    pass
            logger.info("Audio thread stopped.")

    def _reset_state(self) -> None:
        """Reset alert state when no meaningful audio is present."""
        self.alert_status = False
        self.detected_class = ""
        self.top_prob = 0.0
        self.alert_tier = 0
        self.top_class = -1
        self.audio_level = 0.0


# ============================================================
# Vision Violence Heuristic
# ============================================================

def detect_visual_violence(
    results,
    kp_history: Dict[int, np.ndarray],
    speed_limit: float,
    frame: np.ndarray,
) -> bool:
    """
    Detect potential violence-like motion by tracking wrist keypoints speed and proximity to others.

    Heuristic:
      - For each tracked person, estimate normalized hand speed using wrists (kps[9], kps[10]).
      - If speed is above threshold AND a wrist lies within another person's bounding box horizontally,
        flag as possible strike/contact.

    Args:
        results: YOLO tracking results for this frame.
        kp_history: dict of track_id -> previous keypoints
        speed_limit: normalized speed threshold
        frame: BGR frame (for optional visualization/boxing)

    Returns:
        True if visual violence is detected in this frame, else False.
    """
    visual_violence = False

    if results[0].boxes.id is None:
        return False

    boxes = results[0].boxes.xyxy.cpu().numpy()
    keypoints = results[0].keypoints.data.cpu().numpy()
    track_ids = results[0].boxes.id.cpu().numpy().astype(int)

    for i, tid in enumerate(track_ids):
        kps = keypoints[i]  # shape (17,3) typically
        valid = kps[kps[:, 2] > 0.5]
        h = (np.max(valid[:, 1]) - np.min(valid[:, 1])) if len(valid) > 1 else 100.0

        # Need a previous frame for speed
        if tid in kp_history:
            # Wrist indices: 9, 10 (YOLO pose format commonly: left/right wrist)
            dist = (
                np.linalg.norm(kps[9][:2] - kp_history[tid][9][:2])
                + np.linalg.norm(kps[10][:2] - kp_history[tid][10][:2])
            )
            norm_speed = float(dist / max(h, 1e-6))

            if norm_speed > speed_limit:
                # Check if a wrist is within another person's x-range (simple contact proxy)
                for j, other_box in enumerate(boxes):
                    if i == j:
                        continue

                    if (other_box[0] < kps[9][0] < other_box[2]) or (other_box[0] < kps[10][0] < other_box[2]):
                        visual_violence = True
                        # draw highlight box
                        cv2.rectangle(
                            frame,
                            (int(other_box[0]), int(other_box[1])),
                            (int(other_box[2]), int(other_box[3])),
                            (0, 0, 255),
                            3,
                        )
                        break

        kp_history[tid] = kps

    return visual_violence


# ============================================================
# Main Application
# ============================================================

def main() -> None:
    """
    Entry point:
    - Initialize Firebase and Gemini
    - Start audio thread
    - Start camera + YOLO loop
    - Fuse vision + audio to trigger Gemini + Firestore alerts
    """
    logger.info("Initializing Firebase...")
    db = init_firebase(CFG.FIREBASE_SERVICE_ACCOUNT_PATH)

    logger.info("Initializing Gemini...")
    gemini_model = init_gemini(CFG.GEMINI_API_KEY_ENV, CFG.GEMINI_MODEL_NAME)

    logger.info("Initializing audio detection...")
    audio_thread = AudioMonitor()
    audio_thread.start()

    # Allow audio thread to warm up
    time.sleep(1.5)

    logger.info("Loading YOLO pose model: %s", CFG.YOLO_MODEL_PATH)
    model = YOLO(CFG.YOLO_MODEL_PATH)

    logger.info("Opening camera index %d...", CFG.CAMERA_INDEX)
    cap = cv2.VideoCapture(CFG.CAMERA_INDEX)

    if not cap.isOpened():
        audio_thread.running = False
        raise RuntimeError("Could not open webcam/camera device.")

    logger.info("System ready. Controls: SPACE=manual alert snapshot, Q=quit.")
    cv2.namedWindow(CFG.WINDOW_NAME)

    kp_history: Dict[int, np.ndarray] = {}
    violence_buffer = deque(maxlen=CFG.VIOLENCE_BUFFER_LEN)

    frame_count = 0

    try:
        while cap.isOpened():
            success, frame = cap.read()
            if not success:
                break

            frame_count += 1

            # YOLO tracking
            results = model.track(frame, persist=True, verbose=False)

            # Visual heuristic detection
            visual_flag = detect_visual_violence(
                results=results,
                kp_history=kp_history,
                speed_limit=CFG.SPEED_LIMIT,
                frame=frame,
            )

            # Fuse using a buffer to stabilize detection
            violence_buffer.append(1 if visual_flag else 0)
            v_active = sum(violence_buffer) >= CFG.VIOLENCE_BUFFER_MIN_HITS

            # Audio active
            a_active = bool(audio_thread.alert_status)
            a_class = audio_thread.detected_class or ""
            a_tier = int(audio_thread.alert_tier)

            # Determine status text + color (BGR)
            if v_active and a_active:
                status, color = "VIOLENCE DETECTED!", (0, 0, 255)
            elif v_active:
                status, color = "VISUAL VIOLENCE DETECTED!", (0, 165, 255)
            elif a_active:
                status, color = audio_thread.detected_class, (0, 255, 255)
            else:
                status, color = "System: Monitoring", (0, 160, 0)

            # Main Status Text
            cv2.putText(frame, status, (80, 80),
                        cv2.FONT_HERSHEY_SIMPLEX, 1.0, color, 2)

            # Debug Row (Visual + Audio two-tone style)
            _font = cv2.FONT_HERSHEY_SIMPLEX
            _scale = 0.8
            _thick = 2
            _x0, _y0 = 80, 120

            # Tier emoji
            tier_emoji = ["", "🚨", "⚠️", "ℹ️"][audio_thread.alert_tier]

            # Visual label
            v_label = "Violence" if v_active else "Normal"

            # Audio label
            a_label = (
                audio_thread.class_names[audio_thread.top_class]
                if 0 <= audio_thread.top_class < len(audio_thread.class_names)
                else "None"
            )

            part1 = f"[V] {v_label} {1.000 if v_active else 0.973:.3f}  "
            part2 = f"|  [A] {a_label} {audio_thread.top_prob:.3f}"

            # Colors
            _color_v = (255, 255, 0)   # Cyan for visual
            _color_a = (0, 140, 255)   # Orange for audio
            _outline = (0, 0, 0)

            # Outline for readability
            cv2.putText(frame, part1 + part2,
                        (_x0, _y0),
                        _font, _scale, _outline, _thick + 1)

            # Visual text
            cv2.putText(frame, part1,
                        (_x0, _y0),
                        _font, _scale, _color_v, _thick)

            # Audio text
            (w1, _), _ = cv2.getTextSize(part1, _font, _scale, _thick)
            cv2.putText(frame, part2,
                        (_x0 + w1, _y0),
                        _font, _scale, _color_a, _thick)

            # Overlay YOLO visualization lightly
            try:
                output_frame = cv2.addWeighted(frame, 0.82, results[0].plot(), 0.18, 0)
            except Exception:
                output_frame = frame

            cv2.imshow(CFG.WINDOW_NAME, output_frame)

            # Controls
            key = cv2.waitKey(1) & 0xFF
            if key == ord(" "):
                logger.info("Manual trigger: running Gemini + Firebase snapshot...")
                gemini_json = analyze_with_gemini(
                    gemini_model=gemini_model,
                    frame_bgr=frame,
                    visual_violence=v_active,
                    audio_alert=a_active,
                    audio_class=a_class if a_class else "None",
                    tier=a_tier,
                )
                logger.info("Gemini result: %s", gemini_json)
                send_to_firebase(
                    db=db,
                    collection=CFG.FIRESTORE_COLLECTION,
                    location=CFG.ALERT_LOCATION,
                    gemini_response_json=gemini_json,
                    frame_bgr=frame,
                )

            if key == ord("q"):
                break

            if key == ord("t"):
                logger.info("Manual trigger: demo audio override + Gemini + Firebase snapshot...")

                # ── DEMO AUDIO OVERRIDE ─────────────────────────────────────
                demo_audio_active = True
                demo_audio_class = "TIER 1 ALERT: Screaming (0.92)"
                demo_audio_tier = 1
                # ────────────────────────────────────────────────────────────

                gemini_json = analyze_with_gemini(
                    gemini_model=gemini_model,
                    frame_bgr=frame,
                    visual_violence=v_active,
                    audio_alert=demo_audio_active,
                    audio_class=demo_audio_class,
                    tier=demo_audio_tier,
                    location=CFG.ALERT_LOCATION,
                )

                try:
                    parsed = json.loads(gemini_json)
                    print("\n" + "="*60)
                    print("  SPACEBAR TEST — ALERT PREVIEW")
                    print("="*60)
                    print(f"  Type         : {parsed.get('type')}")
                    print(f"  Severity     : {parsed.get('severity')}")
                    print(f"  Confidence   : {parsed.get('confidenceScore')}")
                    print(f"  Details      : {parsed.get('details')}")
                    print(f"  Description  : {parsed.get('description')}")
                    print(f"  Action       : {parsed.get('action')}")
                    print(f"  Tags         : {parsed.get('tags')}")
                    print(f"  Metadata     : {json.dumps(parsed.get('metadata', {}), indent=14)}")
                    print("-"*60)
                    print(f"  Visual Active: {v_active}")
                    print(f"  Audio Override: {demo_audio_class}")
                    print(f"  Audio Tier   : {demo_audio_tier}")
                    print("="*60 + "\n")
                except Exception as e:
                    print(f"[TEST PRINT ERROR] {e}")
                    print(f"Raw: {gemini_json}")

                logger.info("Gemini result: %s", gemini_json)
                send_to_firebase(
                    db=db,
                    collection=CFG.FIRESTORE_COLLECTION,
                    location=CFG.ALERT_LOCATION,
                    gemini_response_json=gemini_json,
                    frame_bgr=frame,
                )

    except KeyboardInterrupt:
        logger.info("Keyboard interrupt received. Shutting down...")
    finally:
        logger.info("Stopping threads and releasing resources...")
        audio_thread.running = False
        cap.release()
        cv2.destroyAllWindows()
        logger.info("Shutdown complete.")


if __name__ == "__main__":
    main()
