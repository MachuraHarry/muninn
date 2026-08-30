# Muninn — Ausbau-Roadmap

> Odins Rabe des Gedächtnisses. Ein selbstgehosteter, omnichannel-fähiger,
> tool-nutzender, proaktiver Langzeit-Assistent in reinem Pipe.

## Vision

Muninn wächst vom Chat-Bot zum **persönlichen Langzeit-Assistenten**, der:

- selbstständig im Web recherchiert und **mit Quellen lernt** („der Rabe fliegt aus und bringt zurück"),
- sein Gedächtnis **pflegt und verdichtet** (Vergessen, Verallgemeinern),
- **beliebige Werkzeuge** sicher nutzt (MCP),
- **proaktiv** erinnert, brieft und langlaufende Ziele verfolgt,
- über **mehrere Kanäle** erreichbar ist (Telegram, Discord, Web, CLI) —
- und dabei radikal schlank bleibt: reines Pipe, ~8 MB Runtime, SQLite, keine Framework-Last.

## Leitprinzipien (Differenzierung zu OpenClaw/Hermes)

1. **Lernen mit Quellen** — Web-Erkenntnisse werden dauerhaft mit `source`-URL gespeichert und später zitiert.
2. **Traum/Konsolidierung** — periodische Verdichtung des Gedächtnisses (nicht nur addieren, auch vergessen/verallgemeinern).
3. **Inneres Gremium als epistemische Qualitätskontrolle** — Faktenwächter + Kritiker prüfen gegen Gedächtnis *und* Web.
4. **Deterministischer, auditierbarer Kern** — jede Zustandsänderung über validierende, registrierte Tools; **nie rohe `exec`/Datei-Builtins an die KI** (Lehre aus der Sandbox-Audit-Reihe, Runde 11).

---

## Phasen

### P1 — Tool-Ökosystem via MCP  *(Priorität: zuerst)*

Muninn bekommt **beliebige Werkzeuge** über MCP — die größte Hebelwirkung für einen „Assistenten".

- **MCP-Client** via `mcp_use_stdio` / `mcp_use_sse`:
  - Filesystem (Dateien lesen/schreiben in einem klar begrenzten Verzeichnis)
  - GitHub (Issues/PRs/Repos)
  - Browser (Web-Automation)
  - Datenbank, Kalender, E-Mail
- **Tool-Sandboxing**: jedes MCP-/Werkzeug unter einem eigenen Sandbox-Profil;
  MCP-Subprozesse laufen nur unter bewusst eng gefasster `exec`-Freigabe.
- **Tool-Registry/Plugin-System** in Pipe: Tools deklarativ registrieren,
  versionieren und dem Gremium/Executor verfügbar machen.
- Executor bekommt Aktionen, die MCP-Tools aufrufen (validierend, nicht roh).

### P2 — Tiefes Gedächtnis & Wissen  *(Priorität: zuerst)*

- **Episodisches Gedächtnis**: mehrzügige Konversationen/Threads mit Verlauf,
  Folgefragen beziehen sich auf den laufenden Kontext.
- **Konsolidierung („Träume")**: periodischer Job verdichtet alte, unwichtige
  Erinnerungen, bildet Verallgemeinerungen, senkt Importance, löscht Veraltetes.
- **Auto-Entitäten + Graph**: automatische Entitäts-Extraktion und Verknüpfung
  im Wissensgraph (`entities`/`relations`).
- **Dokument-Ingestion**: URLs, Dateien, PDFs → eigene Wissensbasis (RAG).
- **Echte semantische Embeddings**: Option OpenAI/Ollama (DeepSeek liefert nur
  einen 128-dim lexikalischen Hash; hybride Suche bleibt Fallback).

### P3 — Omnichannel + Dashboard

- **Web-Dashboard** via `pipe-web`: Chat, Erinnerungen durchsuchen/verwalten,
  Status, Einstellungen.
- **Discord-Kanal** (REST-Polling, Basis `scripts/discord.pipe`).
- **Webhook-Modus** für Telegram (effizienter als Long-Polling).
- **CLI/REPL-Modus** (`pipe muninn.pipe ask "…"`).

### P4 — Proaktivität & Autonomie

- **Scheduler**: geplante Aufgaben/Erinnerungen (Cron-artig, in SQLite + Loop).
- **Tägliches Briefing/Digest** („Guten Morgen, hier dein Tag …").
- **Langlaufende autonome Ziele** mit Checkpoints + Resume.
- **Lernen aus Feedback**: 👍/👎-Buttons passen Importance/Quellen an.

### P5 — Intelligenz-Upgrade

- **Streaming-Antworten** (`ai_stream`) — Antwort erscheint tokenweise.
- **Vision** (`ai_vision`) — Bilder verstehen (URL/Datei/Bytes).
- **Mehr Gremium-Rollen**: Rechercheur, Coder, Zusammenfasser.
- **Mehrzügiger Kontext** über Nachrichten hinweg.

### P6 — Robustheit, Sicherheit, Ops

- Sandbox-Profile überall, Retry/Backoff, Health-Checks.
- **Backup/Export/Import der Seele** (SQLite-Dump).
- **Multi-User-Berechtigungen** (pro Chat-ID Rolle/Whitelist).
- **Deployment**: systemd/Docker, Metriken (`ai_cost`, Logs).

---

## Technische Bausteine (in Pipe verifiziert)

| Baustein | Zweck |
|----------|-------|
| `mcp_use_stdio` / `mcp_use_sse` | MCP-Server als Tools einbinden |
| `pipe-web` (`app`, `route_get`, `serve`, `json` …) | Web-Dashboard |
| `http_server` | roher HTTP-Server / Webhooks |
| `ai_vision` | Bilder verstehen |
| `ai_stream` | tokenweises Streaming |
| `embed` (OpenAI/Ollama) | semantische Suche |
| `ai_chat_json`, `ai_swarm`, `ai_with_tools` | Gremium + strukturierte Ausgabe |
| `web_search`, `wiki_search` | Web-Recherche |
| `discord.pipe`, `x.pipe`, `mqtt` | weitere Kanäle |
| Sandbox-Profile | Tool-/Ausführungs-Sicherheit |

## Bestehende Module (Ist-Zustand)

```
muninn.pipe            Einstiegspunkt: dotenv, Whitelist, Long-Polling-Loop, Router
modules/telegram.pipe  Telegram Bot API (Polling, Inline-Keyboard, Callbacks)
modules/memory.pipe    Seele: memories, embeddings, entities, relations, goals, events + RAG
modules/swarm.pipe     Gremium: planer/faktenwaechter/kritiker/registrator (+ Web-Tools)
modules/executor.pipe  Autonomer Executor: Plan-Bibliothek, Checkpoints, Feedback-Loop
modules/web.pipe       Recherche: web_lookup, web_search_full, web_fetch, research
muninn_test.pipe       28 deterministische Tests
```

## Risiken / offene Fragen

- **Such-/Embedding-Qualität**: bessere Provider (Tavily/Brave/OpenAI/Ollama) bräuchten Keys.
- **Discord**: nur REST-Polling ohne WebSocket-Go-Erweiterung (kein Echtzeit-Gateway).
- **MCP**: Subprozesse erfordern bewusst eng gefasste `exec`-Freigabe im Profil.
- **Voice**: Pipe hat aktuell kein Speech-to-Text; ggf. extern lösen.

## Nicht-Ziele (bewusst)

- Kein Umstieg auf Node.js/TypeScript, kein Cloud-Zwang.
- Kein roher `exec`/Datei-Builtin an die KI.
- Keine Echtzeit-Discord-Gateway-Eigenentwicklung, solange nicht nötig.
- Kein Verkauf von Daten; alles bleibt lokal.
