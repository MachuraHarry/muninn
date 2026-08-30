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
- ✅ **Konsolidierung („Träume")**: `memory.pipe` — `consolidate_threads` verdichtet
  fällige Threads (geschlossen, oder aktiv seit `inactive_days` ohne neue
  Nachricht) zu je einer Zusammenfassungs-Erinnerung (kind `summary`, KI-Kürzung
  mit deterministischem Fallback auf die ersten 800 Zeichen) und löscht danach
  die Rohnachrichten — löst das oben genannte unbegrenzte Wachstum von
  `messages`. `consolidate_memories` senkt die Importance alter, nicht-
  `permanent`er Erinnerungen pro Lauf um 1 und vergisst (löscht) sie, sobald sie
  bei Importance 0 UND alt genug sind; `permanent`-Erinnerungen (explizites
  „merke dir …") bleiben unangetastet. Aufgerufen über `mem.consolidate h`
  (Orchestrator, Default 3/14/30 Tage). Aktivierbar per neuem CLI-Modus
  `pipe muninn.pipe consolidate` (für externen Cron — Pipe hat vor P4 keinen
  eigenen Scheduler) oder direkt per Telegram-Befehl `/consolidate`. 9 neue Tests.
  **Nebenbei gefundener und gefixter Bug**: das reine-Pipe-`sqlite`-Modul wertet
  `datetime('now')` nicht aus — es speicherte wörtlich den String `"now"` in
  jeder `ts`-Spalte (memories/events/messages/plans), was jede Alters-basierte
  Logik unmöglich gemacht hätte. Neues `mem.now_ts` baut den Zeitstempel jetzt
  selbst aus Pipes `now`/`format_time`. Zeilen mit dem alten `"now"`-Sentinel
  gelten als unbekannt alt und werden von der Konsolidierung übersprungen bzw.
  nur über explizite Zustände (z.B. `closed`) fällig, nie über Inaktivitätsdauer.
  (Der Bug betrifft nur `muninn`s eigene Nutzung des `sqlite`-Moduls — eine
  Korrektur im `pipe-modules`-Repo selbst stand nicht an, siehe unten.)
- ⏳ **Verallgemeinerung über reine Kürzung hinaus**: `consolidate_threads`
  kürzt/summiert bislang nur je einen einzelnen Thread; ein echtes Verdichten
  *mehrerer* ähnlicher, kleiner Erinnerungen zu einer generalisierten Aussage
  (z.B. mehrere Einzel-Fakten über eine Vorliebe → eine zusammenfassende
  Erinnerung) ist noch offen.
- ✅ **Auto-Entitäten + Graph**: `memory.pipe` — `auto_link` läuft automatisch bei
  jedem `add_memory` (also bei jeder gespeicherten Erinnerung, egal ob per
  `/permanent`-Nachricht, Gremium-Registrator oder Executor) und extrahiert per
  KI benannte Entitäten + Beziehungen, die dann über `apply_extraction` (rein,
  ohne KI — deterministisch getestet) im bestehenden `entities`/`relations`-
  Graphen landen. Best-effort: ohne KI-Provider passiert einfach nichts.
  `add_relation` dedupliziert jetzt außerdem gleiche (from, to, rel)-Tripel, da
  Auto-Extraktion dieselbe Beziehung über mehrere Erinnerungen hinweg erneut
  finden kann. Neuer Telegram-Befehl `/graph <Name>` fragt Nachbarn einer
  Entität ab; `/status` zeigt Entitäten-/Relationen-Anzahl. Live mit echter KI
  verifiziert (Beispiel: "Harry entwickelt Pipe und lebt in Hamburg" → 3
  Entitäten, 2 Relationen, $0,000157). 8 neue Tests.
- ✅ **Dokument-Ingestion** (URLs + Textdateien; PDFs bewusst außen vor, siehe
  unten): `memory.pipe` — `chunk_text` zerlegt einen langen Text rein und
  deterministisch in ≤1200-Zeichen-Stücke (bevorzugt an Absatzgrenzen);
  `ingest_document` speichert jeden Chunk als eigene Erinnerung (kind
  `document`, inkl. Embedding + Auto-Verknüpfung über `add_memory`) und
  begrenzt die Anzahl über `max_chunks` (Kosten-/Zeit-Deckel bei großen
  Dokumenten). `web.pipe` bekam `web_fetch_raw` (wie `web_fetch`, aber ohne die
  4000-Zeichen-Kürzung — für Ingestion wird der volle Text gebraucht).
  Telegram: neuer Befehl **`/learn <URL>`** sowie automatische Erkennung
  hochgeladener **`.txt`/`.md`-Dateien** (`telegram.pipe`: `tel_get_file`/
  `tel_download_file` gegen Telegrams File-API). **PDFs/Binärformate sind
  bewusst nicht unterstützt** — Pipe ist ein dependency-freies Binary ohne
  PDF-Bibliothek; eine Erweiterung um PDF-Text-Extraktion wäre am saubersten
  über einen angebundenen MCP-Server lösbar (P1) statt eine Abhängigkeit ins
  Kernbinary zu ziehen. Live mit echter KI verifiziert: Wikipedia-Artikel
  "Huginn and Muninn" (31 KB Rohtext) → 26 Chunks erkannt, 5 gespeichert (Limit),
  passende Entitäten (Huginn, Muninn, Odin, Sleipnir, ...) automatisch verlinkt,
  $0,0024 für 5 Chunks. 8 neue Tests.
  **Bekannte Grenze**: `strip_html`/`web_fetch_raw` entfernen nur Tags/Scripts,
  keine Wikipedia-Navigations-/Sprachlink-Boilerplate — Inhalts-Erkennung
  (Readability-artige Hauptinhalt-Extraktion) ist nicht implementiert.
- ⏳ **Echte semantische Embeddings**: Option OpenAI/Ollama (DeepSeek liefert nur
  einen 128-dim lexikalischen Hash; hybride Suche bleibt Fallback).

### P3 — Omnichannel + Dashboard

- ✅ **Web-Dashboard** via `pipe-web`: `modules/dashboard.pipe`, aktivierbar per
  `pipe muninn.pipe web` (neuer CLI-Modus, analog zu `once`/`consolidate`).
  Sidebar-Navigation (Chat/Erinnerungen/Ziele/Wissensgraph/Aktivität/Werkzeuge),
  eine einzige selbstenthaltene HTML-Seite mit Vanilla-JS (kein Build-Schritt,
  keine Frontend-Abhaengigkeit). **Design**: NUR die Farbpalette 1:1 von
  [pipe-lang.com](https://pipe-lang.com) übernommen (dunkles Theme, lila
  Akzente) — explizit gewünscht; Layout/Komponenten/Typografie bewusst
  eigenstaendig (Sidebar statt Scroll-Seite, System-Schrift statt der
  Google-Font-Kombination der Seite, keine Gradient-Text-Ueberschriften, kein
  "Terminal-Fenster"-Chat mit Ampel-Punkten — das erste Design hatte zu viele
  dieser Seiten-spezifischen Stilmittel uebernommen, nicht nur die Farben).
  Chat (eigene, bewusst duenne Kommando-Weiche `dashboard_reply` — siehe
  Modul-Kommentar zur Abgrenzung von Telegrams `handle_message`); Erinnerungen
  durchsuchen/filtern (Stichwort + Art), Importance anpassen, loeschen; Ziele
  auflisten und Status umschalten (`mem.list_goals`/`set_goal_status`, neu);
  Wissensgraph abfragen; Aktivitaet (Ereignisse + Executor-Plaene, neu:
  `exe.recent_plans`); Werkzeuge (alle registrierten lokalen + MCP-Tools);
  Status live. Standardmaessig nur an `127.0.0.1` gebunden (kein `0.0.0.0`);
  optional per `DASHBOARD_TOKEN` zusaetzlich abgesichert (Query-Param/Header —
  kein vollwertiger Auth-Mechanismus, siehe `.env.example`).
  **Deployment**: hinter einem bestehenden Apache-Reverse-Proxy unter einem
  Unterpfad live geschaltet (`https://<domain>/muninn/`) — Frontend nutzt
  ausschliesslich relative Pfade (`api/...`, kein `/api/...`), damit es unter
  jedem Unterpfad funktioniert, siehe README → Hinter einem Reverse-Proxy.
  **Responsive**: Desktop-Sidebar wird ab 760px zu einer unteren Tab-Leiste
  (nicht nur verschmälert — ein eigenes mobiles Layout), ab 420px Icon-only;
  16px-Formularfelder auf Mobil gegen iOS-Safari-Autozoom. Visuell mit
  Puppeteer/Headless-Chrome bei 1400/800/740/390/360px verifiziert (kein
  Browser-Tool in der Session verfuegbar — `libasound2`/`libgbm1` mussten
  fuer den headless Chrome nachinstalliert werden).
  **"Einstellungen"** (aus der urspruenglichen Bullet-Liste) ist bewusst noch
  nicht gebaut — es gibt aktuell keine Laufzeit-Einstellung, die sich lohnen
  wuerde, ohne die bestehende `.env`-Konfiguration zu duplizieren.
  - ⚠️ **Kritischer Nebenlaeufigkeits-Bug gefunden UND behoben**: Telegram-Bot
    und Dashboard liefen anfangs als zwei unabhaengige Prozesse gegen dieselbe
    `muninn.db` — das reine-Pipe-`sqlite`-Modul laedt beim Oeffnen einen
    Snapshot in den Speicher und schreibt beim Schliessen die GESAMTE Datei
    atomar zurueck, ganz ohne prozessuebergreifende Sperre. Live reproduziert:
    eine über den Dashboard-Chat gespeicherte Erinnerung ging spurlos verloren,
    weil der parallel laufende Telegram-Prozess sie beim naechsten
    `db_close` unbemerkt überschrieben hat. **Behoben an der Wurzel**: neuer
    Pipe-Builtin `file_lock`/`file_unlock` (echtes OS-Advisory-Lock — `flock`
    unter Unix, `LockFileEx` unter Windows, No-Op unter WASM) im
    `pipe`-Repo, dazu `mem.open_locked`/`close_locked` in `memory.pipe`, die
    jeden Datei-DB-Zugriff (Telegram-Loop, Dashboard-Handler, Konsolidierung)
    exklusiv sperren. Die Sperre wird bewusst NICHT um Telegrams 25s-
    Long-Polling-Wartezeit gelegt (sonst waere das Dashboard fast permanent
    blockiert), sondern nur um die tatsaechlichen DB-Zugriffe. Live erneut
    verifiziert: 5 schnell aufeinanderfolgende Dashboard-Schreibvorgaenge
    ueberlebten den parallelen Telegram-Betrieb vollstaendig (vorher ging
    schon ein einzelner verloren). `file_lock`/`file_unlock` sind committed
    und nach `origin/master` im `pipe`-Repo gepusht (noch nicht in einem
    offiziellen Release-Tag).
- ⏳ **Discord-Kanal** (REST-Polling, Basis `scripts/discord.pipe`).
- ⏳ **Webhook-Modus** für Telegram (effizienter als Long-Polling).
- ⏳ **CLI/REPL-Modus** (`pipe muninn.pipe ask "…"`).

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
- **Externer `sqlite`-Modul-Bug** (`datetime('now')` wird nicht ausgewertet, siehe
  P2/Konsolidierung oben): in `muninn` selbst umgangen (`mem.now_ts`); ein Fix im
  `pipe-modules`-Repo stromaufwärts steht noch aus, falls gewünscht. Ebenso
  `docs/de/10-builtin-referenz.md`s Beispiel `ts: now 0` ist veraltet — `now`
  nimmt inzwischen keine Argumente mehr (`now` bar aufrufen, nicht `now 0`).

## Nicht-Ziele (bewusst)

- Kein Umstieg auf Node.js/TypeScript, kein Cloud-Zwang.
- Kein roher `exec`/Datei-Builtin an die KI.
- Keine Echtzeit-Discord-Gateway-Eigenentwicklung, solange nicht nötig.
- Kein Verkauf von Daten; alles bleibt lokal.
