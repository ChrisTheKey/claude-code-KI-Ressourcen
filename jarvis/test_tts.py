#!/usr/bin/env python3
"""Quick TTS test — run this to verify ElevenLabs works."""
import json, httpx, asyncio, os

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")
with open(CONFIG_PATH) as f:
    config = json.load(f)

API_KEY = config["elevenlabs_api_key"]
VOICE_ID = config["elevenlabs_voice_id"]

async def test():
    print(f"Testing voice ID: {VOICE_ID}")
    async with httpx.AsyncClient(timeout=15) as http:
        resp = await http.post(
            f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}",
            headers={"xi-api-key": API_KEY, "Content-Type": "application/json"},
            json={"text": "Guten Tag, Sir. Jarvis ist einsatzbereit.", "model_id": "eleven_turbo_v2_5"},
        )
        print(f"Status: {resp.status_code}")
        if resp.status_code == 200:
            with open("/tmp/jarvis_test.mp3", "wb") as f:
                f.write(resp.content)
            print(f"OK — {len(resp.content)} bytes. Datei: /tmp/jarvis_test.mp3")
            print("Abspielen mit: mpv /tmp/jarvis_test.mp3")
        else:
            print(f"FEHLER: {resp.text[:300]}")
            print()
            print("Mögliche Ursache: Voice ID nicht im Account.")
            print("Fix: https://elevenlabs.io/voice-library → Voice suchen → 'Add to My Voices'")
            print("Oder Daniel (eingebaut) nutzen: onwK4e9ZLuTAKqWW03F9")

asyncio.run(test())
