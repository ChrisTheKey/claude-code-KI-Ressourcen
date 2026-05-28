"""
CasandarOS — ElevenLabs Synchronized Voiceover Generator
=========================================================
Führe dieses Skript LOKAL auf deinem PC aus.

Voraussetzungen:
  pip install requests pydub
  ffmpeg installiert (https://ffmpeg.org/download.html)

Usage:
  python casandaros_voiceover_local.py

Output:
  casandaros_final_with_voice.mp4
"""

import os
import re
import subprocess
import tempfile
import time
from pathlib import Path

# ── KONFIGURATION ──────────────────────────────────────────────────────────────
API_KEY   = "sk_d034b08e2739a816a4b7acdff416569091afcf0d0cba02b0"

# Empfohlene männliche Stimmen (dunkel, cineastisch):
#   Adam:   pNInz6obpgDQGcFmaJgB  — tief, männlich, Englisch (funktioniert gut für DE)
#   Antoni: ErXwobaYiN019PkySvjV  — warm, männlich
#   Daniel: onwK4e9ZLuTAKqWW03F9  — tief, britisch
VOICE_ID  = "pNInz6obpgDQGcFmaJgB"  # Adam — ändere das wenn du eine andere Stimme willst

MODEL_ID  = "eleven_multilingual_v2"  # Deutsch-Support

VOICE_SETTINGS = {
    "stability": 0.72,
    "similarity_boost": 0.80,
    "style": 0.10,
    "use_speaker_boost": True,
}

# Pfade — passe an dein System an
INPUT_VIDEO = "casandaros_subtitled_noaudio.mp4"   # dein Video ohne Ton
OUTPUT_VIDEO = "casandaros_final_with_voice.mp4"
TEMP_DIR = Path(tempfile.mkdtemp(prefix="casandaros_"))

VIDEO_DURATION = 143.28  # Sekunden

# ── SUBTITLE TIMING (exakt aus subtitles.ass) ──────────────────────────────────
# Format: (start_seconds, end_seconds, text)
CUES = [
    (1.00,  4.20,  "Jede Nacht sah gleich aus"),
    (5.00,  8.20,  "Das ganze Haus schlief"),
    (9.00,  12.20, "Bis auf Sektor Vier"),
    (14.00, 17.50, "Vögel klingen wie psychologische Kriegsführung"),
    (18.30, 21.50, "Autos wie orbitaler Bombenbeschuss"),
    (22.30, 26.10, "Jeder Schritt im Flur, ein kompletter Systemabsturz"),
    (26.90, 30.40, "Tagsüber wird die Welt einfach zu laut zum Denken"),
    (31.20, 34.20, "Aber nachts"),
    (36.00, 39.00, "ändert sich alles"),
    (39.80, 43.00, "Die Welt fährt endlich runter"),
    (43.80, 47.00, "Die eigentliche Arbeit beginnt"),
    (47.80, 50.80, "Drei Uhr morgens"),
    (52.60, 56.40, "Build-Logs. Kaputte ISOs"),
    (57.20, 61.20, "Entscheidungen. Die langsam nach Raumfahrt aussehen"),
    (62.00, 65.00, "Linux ist wie Lego"),
    (65.80, 69.00, "Ubuntu ist das vorgefertigte Set"),
    (69.80, 73.00, "Windows ist ein versiegeltes System"),
    (73.80, 77.80, "Aber Arch. Kippt dir zwölf Millionen Teile auf den Boden"),
    (78.60, 82.60, "CasandarOS"),
    (84.80, 88.30, "Ein Sternenschiff aus Code"),
    (90.30, 93.80, "Warum entführen Aliens eigentlich Kühe"),
    (94.60, 98.60, "Was wenn irgendwo unter Genf etwas entdeckt wurde"),
    (99.40, 103.40,"Ein schlafloser Ingenieur versucht diesen Wahnsinn nachzubauen"),
    (104.20,107.70,"Normalerweise bauen ganze Teams solche Systeme"),
    (108.50,112.50,"Und ich sitze allein. In einem leuchtenden Zimmer"),
    (113.00,117.00,"in Bern"),
    (119.00,123.00,"Ab irgendeinem Punkt. Fühlt sich das nicht mehr wie Informatik an"),
    (123.80,127.80,"Es fühlt sich an. Wie der Maschinenraum eines Raumschiffs"),
    (128.60,132.60,"CasandarOS"),
    (134.50,137.50,"Entwickelt dort"),
    (139.30,142.80,"wo die meisten längst offline sind"),
]


# ── ELEVENLABS TTS ─────────────────────────────────────────────────────────────
def tts_elevenlabs(text: str, out_path: Path) -> bool:
    import requests
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}"
    headers = {"xi-api-key": API_KEY, "Content-Type": "application/json"}
    payload = {"text": text, "model_id": MODEL_ID, "voice_settings": VOICE_SETTINGS}
    r = requests.post(url, headers=headers, json=payload, timeout=60)
    if r.status_code == 200:
        out_path.write_bytes(r.content)
        return True
    print(f"  ElevenLabs Fehler {r.status_code}: {r.text[:200]}")
    return False


# ── AUDIO DURATION ─────────────────────────────────────────────────────────────
def audio_duration(path: Path) -> float:
    r = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration",
         "-of", "csv=p=0", str(path)],
        capture_output=True, text=True
    )
    return float(r.stdout.strip())


# ── MAIN ────────────────────────────────────────────────────────────────────────
def main():
    import requests  # check import

    print(f"\n{'='*60}")
    print(f"CasandarOS Voiceover Generator")
    print(f"Voice: {VOICE_ID} | Model: {MODEL_ID}")
    print(f"Cues: {len(CUES)} | Video: {VIDEO_DURATION}s")
    print(f"Temp dir: {TEMP_DIR}")
    print(f"{'='*60}\n")

    if not Path(INPUT_VIDEO).exists():
        print(f"FEHLER: Input-Video nicht gefunden: {INPUT_VIDEO}")
        print("Bitte lege casandaros_subtitled_noaudio.mp4 in denselben Ordner.")
        return

    # 1. TTS für jeden Cue generieren
    clip_paths = []
    for i, (start, end, text) in enumerate(CUES):
        slot_duration = end - start
        out_mp3 = TEMP_DIR / f"cue_{i:02d}.mp3"
        print(f"[{i+1:02d}/{len(CUES)}] {start:.2f}s → {end:.2f}s | {text[:55]}")

        if not tts_elevenlabs(text, out_mp3):
            print("  ABBRUCH: TTS fehlgeschlagen.")
            return

        # Clip-Dauer prüfen und auf Slot-Länge anpassen
        clip_dur = audio_duration(out_mp3)
        if clip_dur > slot_duration + 0.05:
            # Leicht beschleunigen damit es in den Slot passt (max 20%)
            speed = min(clip_dur / slot_duration, 1.20)
            adjusted = TEMP_DIR / f"cue_{i:02d}_adj.mp3"
            subprocess.run([
                "ffmpeg", "-i", str(out_mp3),
                "-af", f"atempo={speed:.4f}",
                str(adjusted), "-y"
            ], capture_output=True)
            out_mp3 = adjusted
            print(f"  Beschleunigt: {clip_dur:.2f}s → ~{slot_duration:.2f}s (×{speed:.3f})")

        clip_paths.append((start, out_mp3))
        time.sleep(0.3)  # Rate-Limit schonen

    # 2. Alle Clips zu einer Audiospur zusammensetzen (silence + clips)
    print("\nSetze Audiospur zusammen...")
    filter_parts = []
    inputs = []

    for i, (start, mp3_path) in enumerate(clip_paths):
        inputs += ["-i", str(mp3_path)]

    # ffmpeg filter_complex: Silence-Basis + alle Clips überlappen
    # Erstelle zuerst eine Stille in Videolänge
    silence_path = TEMP_DIR / "silence.wav"
    subprocess.run([
        "ffmpeg", "-f", "lavfi", "-i",
        f"anullsrc=channel_layout=mono:sample_rate=44100",
        "-t", str(VIDEO_DURATION),
        str(silence_path), "-y"
    ], capture_output=True, check=True)

    # Mix: Stille + alle Clips mit delay
    filter_inputs = ["-i", str(silence_path)]
    for _, mp3 in clip_paths:
        filter_inputs += ["-i", str(mp3)]

    # adelay filter für jeden Clip
    delays = []
    for i, (start, _) in enumerate(clip_paths):
        delay_ms = int(start * 1000)
        delays.append(f"[{i+1}]adelay={delay_ms}|{delay_ms}[d{i}]")

    mix_inputs = "".join(f"[d{i}]" for i in range(len(clip_paths)))
    mix_filter = f"[0]{mix_inputs}amix=inputs={len(clip_paths)+1}:normalize=0[aout]"
    full_filter = ";".join(delays) + ";" + mix_filter

    audio_out = TEMP_DIR / "voiceover_final.aac"
    cmd = ["ffmpeg"] + filter_inputs + [
        "-filter_complex", full_filter,
        "-map", "[aout]",
        "-c:a", "aac", "-b:a", "128k",
        "-t", str(VIDEO_DURATION),
        str(audio_out), "-y"
    ]
    print("  Mixe Audio...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  ffmpeg Fehler: {result.stderr[-500:]}")
        return

    # 3. Audio mit Video zusammenführen
    print(f"\nErstelle finales Video: {OUTPUT_VIDEO}")
    cmd = [
        "ffmpeg",
        "-i", INPUT_VIDEO,
        "-i", str(audio_out),
        "-map", "0:v:0",
        "-map", "1:a:0",
        "-c:v", "copy",
        "-c:a", "aac",
        "-shortest",
        OUTPUT_VIDEO, "-y"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ffmpeg Fehler: {result.stderr[-300:]}")
        return

    size_mb = Path(OUTPUT_VIDEO).stat().st_size / 1024 / 1024
    print(f"\n{'='*60}")
    print(f"FERTIG: {OUTPUT_VIDEO} ({size_mb:.1f} MB)")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
