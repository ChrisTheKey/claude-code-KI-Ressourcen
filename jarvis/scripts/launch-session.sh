#!/usr/bin/env bash
# Jarvis Launch Session — CachyOS / Arch Linux

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JARVIS_DIR="$(dirname "$SCRIPT_DIR")"

# Start browser (Chromium/Firefox)
if command -v chromium &>/dev/null; then
    chromium --new-window "http://localhost:8340" &
elif command -v google-chrome-stable &>/dev/null; then
    google-chrome-stable --new-window "http://localhost:8340" &
elif command -v firefox &>/dev/null; then
    firefox "http://localhost:8340" &
fi

# Optional: open apps defined in config
# Add custom app launches here, e.g.:
# obsidian &

# Start Jarvis server
cd "$JARVIS_DIR"
python server.py
