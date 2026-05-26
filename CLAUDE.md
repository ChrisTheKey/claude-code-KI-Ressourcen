# KI Video Editing Studio — Arbeitsregeln

- Video-Use first für Schnitt/Transkription, dann Hyperframes für Motion Graphics
- **Plan-Bestätigung auf Deutsch** vor jedem Cut und vor jeder Composition
- Outputs landen unter `projects/<name>/renders/`, niemals in Repo-Root oder `raw/`
- `.env` nie committen
- Brand-Guidelines-Konvention: wenn keine Brand genannt wird, fällt Claude auf `brand-guidelines/default/` zurück
- Bei Multi-Scene-Compositions: parallele Sub-Agents (eine Szene pro Agent), wenn unabhängig
- Nach jedem Render Self-Eval per `timeline_view`-Pattern, bevor Preview gezeigt wird
- **`.env`-Sync:** Wenn Claude bemerkt, dass `./.env` und `./video-use/.env` divergieren, syncen (Projekt-Root ist Wahrheit)
- Skill-Imports (Windows-Hinweis): falls Junction nicht angelegt werden konnte, per absolutem Pfad importieren
