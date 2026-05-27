"""
Voiceover Generator für CasandarOS

Primär: ElevenLabs API (hohe Qualität, cineastisch)
Fallback: gTTS (Google TTS, Offline-kompatibel)

ElevenLabs-Empfehlungen für "dunkel, ruhig, leicht dystopisch":
  - Voice: "Adam" (ID: pNInz6obpgDQGcFmaJgB) — tief, männlich, englisch
  - Voice: "Daniel" (ID: onwK4e9ZLuTAKqWW03F9) — tief, britisch
  - Voice: "Antoni" (ID: ErXwobaYiN019PkySvjV) — warm, männlich
  - Für Deutsch: "Arnold" oder custom voice empfohlen

Usage:
  python3 generate_voiceover.py [--elevenlabs] [--output new_voiceover.mp3]
"""

import os
import sys
import json
import time
import argparse
import subprocess
from pathlib import Path

# ─── KONFIGURATION ────────────────────────────────────────────────────────────

# ╔══════════════════════════════════════════════════════════════════╗
# ║  HIER: ElevenLabs API-Key eintragen                              ║
# ║  Holen unter: https://elevenlabs.io/app/settings/api-keys       ║
ELEVENLABS_API_KEY = os.getenv("ELEVENLABS_API_KEY", "YOUR_API_KEY_HERE")
# ╚══════════════════════════════════════════════════════════════════╝

# ╔══════════════════════════════════════════════════════════════════╗
# ║  HIER: ElevenLabs Voice-ID eintragen                             ║
# ║  Empfehlung für "dunkel, cineastisch, Deutsch":                  ║
# ║    Adam:    pNInz6obpgDQGcFmaJgB                                 ║
# ║    Daniel:  onwK4e9ZLuTAKqWW03F9                                 ║
# ║  Eigene Voices: https://elevenlabs.io/app/voice-lab              ║
ELEVENLABS_VOICE_ID = os.getenv("ELEVENLABS_VOICE_ID", "pNInz6obpgDQGcFmaJgB")
# ╚══════════════════════════════════════════════════════════════════╝

# ElevenLabs Voice-Settings (cineastisch, ruhig, dunkel)
VOICE_SETTINGS = {
    "stability": 0.75,          # Höher = konsistenter, weniger expressiv
    "similarity_boost": 0.80,   # Nähe zur Original-Voice
    "style": 0.15,              # Wenig Style-Exaggeration
    "use_speaker_boost": True
}

MODEL_ID = "eleven_multilingual_v2"  # Unterstützt Deutsch nativ

# ─── VOICEOVER-TEXT ────────────────────────────────────────────────────────────
SCRIPT_PATH = Path(__file__).parent / "renders" / "voiceover_script.txt"
OUTPUT_PATH = Path(__file__).parent / "renders" / "new_voiceover.mp3"
VIDEO_DURATION = 137.80  # Sekunden — aus ffprobe

# ─── ELEVENLABS TTS ───────────────────────────────────────────────────────────
def generate_elevenlabs(text: str, output_path: Path) -> bool:
    """Generiert Voiceover via ElevenLabs API."""
    try:
        import requests
    except ImportError:
        subprocess.run([sys.executable, "-m", "pip", "install", "requests"], check=True)
        import requests

    if ELEVENLABS_API_KEY == "YOUR_API_KEY_HERE":
        print("FEHLER: ElevenLabs API-Key nicht konfiguriert.")
        print("  → Trage deinen Key in generate_voiceover.py ein oder setze:")
        print("    export ELEVENLABS_API_KEY=dein_key_hier")
        return False

    url = f"https://api.elevenlabs.io/v1/text-to-speech/{ELEVENLABS_VOICE_ID}"
    headers = {
        "xi-api-key": ELEVENLABS_API_KEY,
        "Content-Type": "application/json"
    }
    payload = {
        "text": text,
        "model_id": MODEL_ID,
        "voice_settings": VOICE_SETTINGS
    }

    print(f"  Sende Request an ElevenLabs (Voice: {ELEVENLABS_VOICE_ID})...")
    response = requests.post(url, headers=headers, json=payload, timeout=120)

    if response.status_code == 200:
        output_path.write_bytes(response.content)
        print(f"  ElevenLabs-Voiceover gespeichert: {output_path}")
        return True
    else:
        print(f"  ElevenLabs Fehler {response.status_code}: {response.text[:200]}")
        return False


# ─── GTTS FALLBACK ─────────────────────────────────────────────────────────────
def generate_gtts(text: str, output_path: Path) -> bool:
    """Generiert Voiceover via Google TTS (kostenlos, Fallback)."""
    try:
        from gtts import gTTS
    except ImportError:
        subprocess.run([sys.executable, "-m", "pip", "install", "gtts"], check=True)
        from gtts import gTTS

    print("  Generiere via Google TTS (Fallback)...")
    tts = gTTS(text=text, lang="de", slow=False)
    tts.save(str(output_path))
    print(f"  gTTS-Voiceover gespeichert: {output_path}")
    return True


# ─── LÄNGE ANPASSEN ───────────────────────────────────────────────────────────
def adjust_to_video_length(audio_path: Path, target_duration: float) -> None:
    """Passt Voiceover-Länge an Videolänge an (Stille auffüllen oder minimal beschleunigen)."""
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
         "-of", "csv=p=0", str(audio_path)],
        capture_output=True, text=True
    )
    audio_duration = float(result.stdout.strip())
    diff = target_duration - audio_duration

    print(f"  Audio-Dauer: {audio_duration:.2f}s | Video-Dauer: {target_duration:.2f}s | Diff: {diff:+.2f}s")

    tmp_path = audio_path.with_suffix(".tmp.mp3")

    if diff > 0:
        # Zu kurz → Stille am Ende auffüllen
        print(f"  Fülle {diff:.2f}s Stille am Ende ein...")
        subprocess.run([
            "ffmpeg", "-i", str(audio_path),
            "-af", f"apad=pad_dur={diff}",
            "-t", str(target_duration),
            str(tmp_path), "-y"
        ], check=True, capture_output=True)
    elif diff < -2:
        # Signifikant zu lang → Tempo minimal erhöhen (max 15% schneller)
        speed_factor = min(audio_duration / target_duration, 1.15)
        print(f"  Erhöhe Tempo um Faktor {speed_factor:.3f}...")
        subprocess.run([
            "ffmpeg", "-i", str(audio_path),
            "-af", f"atempo={speed_factor:.4f}",
            str(tmp_path), "-y"
        ], check=True, capture_output=True)
    else:
        print("  Länge passt — keine Anpassung nötig.")
        return

    tmp_path.replace(audio_path)
    print(f"  Länge angepasst: {audio_path}")


# ─── MAIN ─────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="CasandarOS Voiceover Generator")
    parser.add_argument("--elevenlabs", action="store_true", help="ElevenLabs statt gTTS verwenden")
    parser.add_argument("--output", default=str(OUTPUT_PATH), help="Output-Pfad für MP3")
    args = parser.parse_args()

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Text laden
    text = SCRIPT_PATH.read_text(encoding="utf-8")
    print(f"\nVoiceover-Text geladen ({len(text)} Zeichen)")

    # TTS generieren
    success = False
    if args.elevenlabs:
        print("\n[ElevenLabs TTS]")
        success = generate_elevenlabs(text, output_path)
        if not success:
            print("  Fallback auf gTTS...")

    if not success:
        print("\n[Google TTS Fallback]")
        success = generate_gtts(text, output_path)

    if not success:
        print("\nFEHLER: Voiceover konnte nicht generiert werden.")
        sys.exit(1)

    # Länge anpassen
    print("\n[Längenanpassung]")
    adjust_to_video_length(output_path, VIDEO_DURATION)

    print(f"\nFertig: {output_path}")


if __name__ == "__main__":
    main()
