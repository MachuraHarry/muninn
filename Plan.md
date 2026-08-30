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

### P1 — Tool-Ökosystem via MCP  *(Priorität: zuerst)*  ✅ Erledigt

Muninn bekommt **beliebige Werkzeuge** über MCP — die größte Hebelwirkung für einen „Assistenten".

- ✅ **MCP-Client** via `mcp_use_stdio` / `mcp_use_sse`, konfiguriert über `MCP_SERVERS`
  (JSON-Liste in `.env`) — `modules/mcp.pipe`: `parse_mcp_config`, `connect_servers`.
  Beliebige Server anbindbar (Filesystem, GitHub, Datenbank, ...), sofern per stdio/SSE
  erreichbar. End-to-End mit `@modelcontextprotocol/server-filesystem` verifiziert.
- ✅ **Tool-Sandboxing**: Sandbox-Profil `muninn` in `muninn.pipe`; MCP-Subprozesse laufen
  nur unter `exec_whitelist` (ausschließlich die konfigurierten Kommandos), `ai`/`network`
  offen, `audit_log` + `max_tool_calls` aktiv. Ohne konfigurierte Server bleibt `exec` aus.
- ✅ **Gremium-Anbindung**: entdeckte MCP-Tools gehen an einen eigenen `werkzeugmeister`-
  Agenten (`swarm.pipe`), an den `planer`/`kritiker` bei Bedarf weiterleiten.
- ✅ **Executor-Aktion `mcp_call`**: `executor.pipe` kann MCP-/lokale Tools jetzt
  deterministisch aus einem Plan heraus aufrufen, ganz ohne KI-Tool-Call-Schleife —
  ermöglicht durch einen **neuen Pipe-Builtin `tool_call(name, args?)`**
  (`~/pipe/pkg/object/builtins_ai.go`, registriert in `object.go`, dokumentiert in
  `pkg/analysis/builtins.go`), der `executeTool` — denselben Dispatch, den
  `ai_with_tools` intern nutzt — direkt aufruft. Da lokale `ai_tool`s und per MCP
  gebrückte Tools in derselben `toolRegistry` liegen, funktioniert `tool_call`
  transparent für beide. Sandbox-Gating (`max_tool_calls`, `audit_log`) bleibt
  identisch zu `ai_with_tools`. Go-Tests: `TestToolCallDirectInvocation` in
  `pkg/object/ai_builtins_test.go`; Pipe-Tests: `exec_step mcp_call ...` in
  `muninn_test.pipe`. **Achtung:** `tool_call` ist noch nicht in einem offiziellen
  Pipe-Release (Tag) enthalten — `/usr/local/bin/pipe` läuft auf einem lokalen Build
  von Commit `5c1fbe5` (im `pipe`-Repo committed und nach `origin/master` gepusht;
  Backup der vorherigen v1.2.0 unter `/usr/local/bin/pipe.v1.2.0.bak`).
- ⏳ **Tool-Registry/Plugin-System**: aktuell reicht die MCP-Registry von Pipe selbst
  (`mcp_tools`/`tool_call`) plus `ai_tool`; ein eigenes Versionierungs-/Plugin-Layer
  ist bewusst nicht gebaut, mangels konkretem Bedarf (YAGNI) — eine `.env`-Zeile mit
  Server-Liste deckt Muninns gesamte "Plugin"-Oberfläche ab.
- ⏳ **Browser-Automation** als konkretes Beispiel noch nicht getestet — hängt von einem
  MCP-Browser-Server ab (z.B. Playwright-MCP); mit der jetzigen Config nur eine
  `MCP_SERVERS`-Zeile entfernt.

### P2 — Tiefes Gedächtnis & Wissen  *(Priorität: zuerst)*

- ✅ **Episodisches Gedächtnis**: ein Thread pro Chat (`threads`-Tabelle, bislang
  angelegt aber ungenutzt — jetzt aktiv) sammelt den Verlauf in einer neuen
  `messages`-Tabelle. `memory.pipe`: `active_thread`, `add_message`,
  `thread_history`, `format_history`, `close_thread`. Fragen (Gremium),
  `/search`-Recherchen und „Vertiefen" bekommen die letzten 6 Nachrichten als
  Kontext vorangestellt (`muninn.pipe`), sodass Folgefragen sich auf den
  laufenden Kontext beziehen — `swarm.pipe`/`ai_swarm_trace` selbst bleibt
  stateless, der Verlauf wird als Text Teil der `task`-Eingabe. Neuer Befehl
  `/reset` schließt den aktiven Thread (frischer Kontext danach). 6 neue Tests.
  Bewusst noch **kein** Kontextfenster-Management über die letzten 6 Nachrichten
  hinaus — das übernimmt als Nächstes die Konsolidierung.
- ⏳ **Konsolidierung („Träume")**: periodischer Job verdichtet alte, unwichtige
  Erinnerungen, bildet Verallgemeinerungen, senkt Importance, löscht Veraltetes.
  Mit dem Episodischen Gedächtnis jetzt auch Kandidat für alte `messages`/
  `threads` (aktuell wächst die `messages`-Tabelle unbegrenzt).
- ⏳ **Auto-Entitäten + Graph**: automatische Entitäts-Extraktion und Verknüpfung
  im Wissensgraph (`entities`/`relations`).
- ⏳ **Dokument-Ingestion**: URLs, Dateien, PDFs → eigene Wissensbasis (RAG).
- ⏳ **Echte semantische Embeddings**: Option OpenAI/Ollama (DeepSeek liefert nur
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
modules/mcp.pipe       MCP-Tool-Ökosystem: Server-Konfig, exec-Whitelist, Verbindungsaufbau
muninn_test.pipe       deterministische Tests
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
