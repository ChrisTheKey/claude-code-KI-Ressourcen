# Video Editing Workflow

## Edit-Workflow (mit Rohvideo)
1. Roh-MP4 in `raw/<projektname>/` legen
2. `"Edit @raw/<projektname>/<datei>.mp4 in eine Folge"` sagen
3. Claude transkribiert mit ElevenLabs Scribe
4. Claude erkennt Füllwörter, Pausen, Fehlstarts, Versprecher, Retakes
5. Cut-Plan auf Deutsch → Nutzer-OK
6. `projects/<name>/clips/edited.mp4` + `master.srt` + Wort-Zeitstempel-JSON
7. Storyboard für Motion Graphics → Nutzer-OK
8. Compositions mit Hyperframes (parallel via Sub-Agents wo sinnvoll)
9. `npx hyperframes preview` → Studio auf `localhost:3002`
10. Iteration auf Feedback
11. Final-Render: `projects/<name>/renders/final.mp4`

## Pure-Animation-Workflow (ohne Rohvideo)
Identisch ab Schritt 7 — Nutzer beschreibt das Video, Claude erzeugt Storyboard.
