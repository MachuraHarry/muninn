# Muninn

**Muninn** — Odins Rabe des Gedächtnisses. Ein selbstgehosteter, omnichannel-fähiger
Langzeit-KI-Agent in der Programmiersprache [Pipe](https://github.com/MachuraHarry/pipe).

Kein kurzer Chat-Bot, sondern ein Agent mit einer **persistenten „Seele"** (SQLite),
der sich Dinge **mit Quellen merkt**, Antworten über ein **inneres Gremium** verfeinert,
Aufgaben **autonom ausführt** und **im Web recherchiert und lernt** — der Rabe, der
ausfliegt und Wissen zurückbringt. Alle Daten bleiben auf deiner Maschine.

---

## Features

- **Persistente Seele** — SQLite mit Erinnerungen, Wissensgraph (Entitäten/Relationen), Zielen und Verlauf.
- **Hybride Suche (RAG)** — TF-IDF-Keyword-Scoring + semantische Embeddings.
- **Inneres Gremium** — 4 Swarm-Agenten (`planer → faktenwaechter → kritiker → registrator`),
  die Fakten gegen Gedächtnis **und** Web prüfen.
- **Lernen aus dem Web** — neue Erkenntnisse werden dauerhaft **mit Quellen-URL** gespeichert und später zitiert.
- **Autonomer Executor** — Aufgaben werden als Pläne mit Checkpoints und Feedback-Loop ausgeführt.
- **Web-Recherche** — DuckDuckGo + Wikipedia, Seiten-Fetch und Zusammenfassung (kein API-Key nötig).
- **MCP-Tool-Ökosystem** — beliebige externe Werkzeuge (Dateisystem, GitHub, ...) per
  Model Context Protocol anbinden; laufen unter einem Sandbox-Profil mit eng gefasster
  exec-Whitelist, ein eigener „werkzeugmeister"-Agent im Gremium nutzt sie.
- **Telegram-Bot** — Long-Polling, Inline-Buttons, Befehle.
- **Deterministische Tests** — Kernlogik ohne KI/Netz testbar.

## Stand der Entwicklung

| Meilenstein | Status |
|---|---|
| M1 — Telegram-Bot + Kern-Seele | ✅ |
| M2 — Wissensgraph + RAG | ✅ |
| M3 — Inneres Gremium (ai_swarm) | ✅ |
| M4 — Autonomer Executor | ✅ |
| Web-Recherche + Lernen + Inline-Buttons | ✅ |
| P1 — MCP-Tool-Ökosystem + Sandboxing | ✅ |
| M5 — Discord | ⏳ geplant |

Weitere Schritte: [Plan.md](Plan.md)

---

## Schnellstart

### Voraussetzungen

- Ein Pipe-Binary mit den Builtins `tool_call` (P1) und `file_lock`/`file_unlock`
  (P3) — Stand: noch nicht in einem offiziellen Release-Tag, aber committed und
  nach `origin/master` gepusht im [`pipe`](https://github.com/MachuraHarry/pipe)-Repo.
- Die Pipe-Module `sqlite`, `pipe-test` und `pipe-web`:

```bash
pipe -get sqlite
pipe -get pipe-test
pipe -get pipe-web
```

### Konfiguration

`.env` anlegen (ist gitignored — **nie committen**):

```bash
cp .env.example .env
```

```bash
TELEGRAM_BOT_TOKEN=123456:ABC...        # Token von @BotFather (/newbot)
TELEGRAM_ALLOWED_CHAT_ID=               # deine Chat-ID von @userinfobot (leer = jeder darf)
DEEPSEEK_API_KEY=sk-...                 # für Klassifikation, Gremium, Zusammenfassung
MCP_SERVERS=                            # optional: JSON-Liste externer MCP-Server (siehe .env.example)
```

> Muninn nutzt **DeepSeek** als Provider (kostenlos anmeldbar unter platform.deepseek.com).
> Für *echte* semantische Embeddings (statt des lexikalischen DeepSeek-Fallbacks)
> kann alternativ OpenAI/Ollama konfiguriert werden.

> **MCP-Server (optional):** `MCP_SERVERS` bindet externe Werkzeuge per Model Context
> Protocol ein (siehe `.env.example` für das Format). Leer = deaktiviert, kein `exec`
> nötig. Ist mindestens ein `stdio`-Server konfiguriert, aktiviert Muninn `exec`
> ausschließlich für dessen Kommando (Sandbox-Profil `muninn`, `exec_whitelist`).

### Starten

```bash
pipe muninn.pipe             # Telegram-Bot (Long-Polling, läuft dauerhaft)
pipe muninn.pipe once        # ein Polling-Zyklus, dann exit (Test)
pipe muninn.pipe web         # Web-Dashboard (siehe DASHBOARD_BIND/-TOKEN)
pipe muninn.pipe consolidate # Konsolidierung ("Traum"), z.B. per Cron
```

Telegram-Bot und Dashboard dürfen **gleichzeitig** laufen (z.B. Bot dauerhaft im
Hintergrund, Dashboard bei Bedarf) — beide teilen sich `muninn.db` und sichern
jeden Zugriff per `file_lock`/`file_unlock` gegeneinander ab (siehe
[Architektur](#nebenläufigkeit-telegram--dashboard)).

### Tests

Deterministisch, ohne KI und ohne Netz:

```bash
pipe -test
```

---

## Bedienung (Telegram)

### Befehle

| Befehl | Beschreibung |
|--------|--------------|
| `/start` | Begrüßung |
| `/help` | alle Befehle |
| `/status` | Zustand (Erinnerungen, Provider, Gremium, Executor) |
| `/list` | deine wichtigsten Erinnerungen |
| `/search <begriff>` | Web-Recherche mit Quellen |
| `/reset` | Gesprächsverlauf zurücksetzen (frischer Kontext für Folgefragen) |
| `/consolidate` | Traum: alte Gespräche verdichten, Erinnerungen altern/vergessen lassen |
| `/graph <Name>` | Wissensgraph abfragen (Nachbarn einer Entität) |
| `/learn <URL>` | Dokument lernen (oder direkt eine `.txt`/`.md`-Datei schicken) |

### Natürliche Sprache

| Eingabe | Wirkung |
|---------|---------|
| „Merke dir, dass …" | wird dauerhaft gespeichert |
| „Erledige …" / „Mache …" | autonomer Executor führt einen Plan aus |
| „Mein Ziel ist …" | legt ein Ziel an |
| „Suche …" / „Recherchiere …" / „Finde …" | Web-Recherche |
| Frage („…?") | Gremium beantwortet fundiert über Gedächtnis + Web |

Antworten tragen **Inline-Buttons**: `💾 Merken` (in die Seele speichern) und
`🔍 Vertiefen` (weiter recherchieren).

---

## Bedienung (Web-Dashboard, P3)

```bash
pipe muninn.pipe web
# -> Muninn-Dashboard: http://127.0.0.1:8787/
```

Eine einzige, selbstenthaltene Seite (kein Build-Schritt), **vollständig
responsive**. Farbpalette 1:1 von [pipe-lang.com](https://pipe-lang.com)
übernommen (dunkles Theme, lila Akzente); Layout, Komponenten und Typografie
sind bewusst **eigenständig** (Sidebar-Navigation statt Scroll-Seite,
System-Schrift statt Google-Fonts, keine Gradient-Text-Überschriften, kein
„Terminal-Fenster"-Chat):

- **Desktop** (> 760px): feste Sidebar links.
- **Mobil** (≤ 760px): die Sidebar wird zu einer unteren Tab-Leiste (etabliertes
  App-Muster) statt sich nur zu verschmälern; Formularfelder auf 16px Schrift
  (verhindert das automatische Hineinzoomen von iOS Safari bei Fokus).
- **Sehr schmale Geräte** (≤ 420px): Tab-Labels weichen reinen Icons, sonst zu
  eng bei 6 Tabs.
- Visuell mit Puppeteer/Headless-Chrome bei mehreren Breite geprüft (1400/800/
  740/390/360px) — kein Browser-Tool in dieser Session verfügbar, daher dieser
  Weg zur echten Verifikation statt bloßer CSS-Vermutung.

- **Chat** — dieselben Befehle wie bei Telegram (`/status`, `/graph <Name>`,
  `/learn <URL>`, `/reset`, `/consolidate`) plus natürliche Sprache. Eigene,
  bewusst schlanke Kommando-Weiche (`dashboard_reply`) statt Wiederverwendung
  von Telegrams `handle_message` — siehe Architektur unten.
- **Erinnerungen** — durchsuchen (Stichwort + Art-Filter), Importance direkt
  anpassen (▲/▼), löschen.
- **Ziele** — Übersicht offener/erledigter Ziele, per Klick umschalten.
- **Wissensgraph** — Nachbarn einer Entität abfragen.
- **Aktivität** — jüngste Ereignisse (klassifizierte Nachrichten) und Executor-Pläne
  mit Status (offen/erledigt/fehlgeschlagen).
- **Werkzeuge** — alle registrierten (lokalen + per MCP gebrückten) Tools.
- **Status-Leiste** — Erinnerungen, Entitäten/Relationen, Werkzeuge live.

Mit `DEEPSEEK_API_KEY` konfiguriert nutzt der Dashboard-Chat dieselbe KI wie
Telegram (Gremium, Klassifikation, Executor) — beide Kanäle teilen sich
Gedächtnis, Threads und Wissensgraph vollständig.

### Hinter einem Reverse-Proxy (z.B. unter einem Unterpfad)

`DASHBOARD_BIND` bleibt dabei auf `127.0.0.1:<port>` (kein `0.0.0.0`); TLS und
öffentlicher Zugriff laufen über den Proxy. Das Frontend nutzt ausschließlich
relative Pfade (`api/...`, `href="./"`), funktioniert also unter jedem
Unterpfad, solange die Backend-Requests des Proxys den Pfad entsprechend
strippen. Beispiel Apache, Dashboard unter `https://host/muninn/`, neben einer
bestehenden Seite auf der Domain-Root:

```apache
RewriteEngine On
RewriteRule ^/muninn$ /muninn/ [R=302,L]
# ^ WICHTIG: RewriteEngine muss INNERHALB des <VirtualHost>-Blocks stehen —
#   ausserhalb (Server-Kontext) wird es nicht auf den vHost angewendet.

ProxyPass /muninn/ http://127.0.0.1:8787/
ProxyPassReverse /muninn/ http://127.0.0.1:8787/
# ^ Muss VOR einer generischen "ProxyPass / ..."-Regel stehen (spezifischster
#   Pfad zuerst) — sonst faengt die generische Regel /muninn faelschlich ab.
```

---

## Architektur

```
muninn.pipe             Einstiegspunkt: dotenv, Whitelist, Long-Polling-Loop, Router
modules/telegram.pipe   Telegram Bot API (Polling, Inline-Keyboard, Callbacks)
modules/memory.pipe     Seele: memories, embeddings, entities, relations, goals, events + RAG
modules/swarm.pipe      Gremium: planer/faktenwaechter/kritiker/registrator (+ Web-Tools)
modules/executor.pipe   Autonomer Executor: Plan-Bibliothek, Checkpoints, Feedback-Loop
modules/web.pipe        Recherche: web_lookup, web_search_full, web_fetch, research
modules/mcp.pipe        MCP-Tool-Ökosystem: Server-Konfig, exec-Whitelist, Verbindungsaufbau
modules/dashboard.pipe  Web-Dashboard (P3): pipe-web-Routen, HTML/CSS/JS, eigene Chat-Weiche
muninn_test.pipe        deterministische Tests
```

### Nebenläufigkeit: Telegram + Dashboard

Beide Kanäle laufen als **separate Prozesse** (ein gemeinsamer Prozess ist bewusst
vermieden, da Pipes Interpreter keinen globalen Lock hat — parallele Zugriffe auf
gemeinsamen Modul-Zustand könnten den Prozess zum Absturz bringen), teilen sich aber
`muninn.db`. Das reine-Pipe-`sqlite`-Modul lädt beim Öffnen einen Snapshot in den
Speicher und schreibt beim Schließen die komplette Datei atomar zurück — **ohne
eigene prozessübergreifende Sperre**. Ohne Gegenmaßnahme kann ein Prozess beim
Schließen den committeten Schreibvorgang eines anderen, gleichzeitig laufenden
Prozesses stillschweigend überschreiben (live reproduziert: eine über das Dashboard
gespeicherte Erinnerung ging beim parallel laufenden Telegram-Bot verloren).

**Fix**: `mem.open_locked`/`close_locked` umschließen jeden Datei-DB-Zugriff mit
einer echten OS-Sperre (`file_lock`/`file_unlock`, ein neuer Pipe-Builtin —
`flock` unter Unix, `LockFileEx` unter Windows). Die Sperre wird bewusst **nicht**
um Telegrams 25-Sekunden-Long-Polling-Wartezeit gelegt, sondern nur um die
tatsächlichen Lese-/Schreibzugriffe — sonst wäre das Dashboard während des Wartens
praktisch blockiert. Nachteil: solange ein Kanal eine Nachricht aktiv verarbeitet
(z.B. ein Gremium-Aufruf, der einige Sekunden dauert), wartet der jeweils andere
Kanal kurz auf die Sperre — für ein persönliches Ein-Nutzer-Tool ein akzeptabler
Kompromiss gegenüber stillem Datenverlust.

### Seele (`memory.pipe`)

Alles Gedächtnis liegt in `muninn.db`. Die Datenbank wird pro Zugriff (Polling-
Zyklus, Dashboard-Request, Konsolidierungslauf) über `open_locked`/`close_locked`
geöffnet, verarbeitet und persistiert. Eingehende Nachrichten werden klassifiziert
(KI mit deterministischem Regel-Fallback) und verdichtet, bevor sie gespeichert werden.

### Wissen & RAG (`memory.pipe`)

- **Wissensgraph:** `entities`/`relations`; `add_entity`, `add_relation` (dedupliziert
  gleiche from/to/rel-Tripel), `neighbors_of`.
- **Auto-Entitäten (P2):** `auto_link` läuft automatisch bei jeder gespeicherten
  Erinnerung (`add_memory`) und extrahiert per KI benannte Entitäten + Beziehungen
  in den Graphen (`apply_extraction` — rein, ohne KI, deterministisch testbar).
  Best-effort: ohne KI-Provider passiert nichts. Telegram: `/graph <Name>` fragt
  Nachbarn ab, `/status` zeigt die Graph-Größe.

### Dokument-Ingestion (P2)

`/learn <URL>` oder eine hochgeladene `.txt`/`.md`-Datei nehmen ein Dokument in
die Wissensbasis auf:

- **`chunk_text`** zerlegt den Text rein/deterministisch in ≤1200-Zeichen-Stücke
  (bevorzugt an Absatzgrenzen).
- **`ingest_document`** speichert jeden Chunk als eigene Erinnerung (kind
  `document`, mit Embedding + Auto-Verknüpfung) und begrenzt die Anzahl über
  `max_chunks` (Kosten-/Zeit-Deckel).
- **PDFs/Binärformate werden bewusst nicht unterstützt** — Pipe ist ein
  dependency-freies Binary ohne PDF-Bibliothek. Der saubere Weg dafür wäre ein
  angebundener MCP-Server mit PDF-Extraktion (siehe P1) statt einer Abhängigkeit
  im Kernbinary.
- **Hybride Retrieval:** `retrieve_context` kombiniert lexikalisches TF-IDF-Scoring (0.75)
  mit semantischen Embeddings (0.25). DeepSeek liefert nur einen 128-dim lexikalischen
  Hash — bei einem echten Embedding-Provider (>300 dim) schaltet die Gewichtung
  automatisch auf semantisch um (0.7/0.3).

### Episodisches Gedächtnis (`memory.pipe`, P2)

Ein **Thread pro Chat** (`threads`-Tabelle) sammelt den Gesprächsverlauf
(`messages`-Tabelle), damit sich Folgefragen auf den laufenden Kontext beziehen können:

- **`active_thread`** liefert den aktiven Thread eines Chats (legt bei Bedarf einen an).
- **`add_message`/`thread_history`** protokollieren bzw. lesen die letzten Nachrichten
  chronologisch; `format_history` rendert sie als Prompt-Text.
- Bei Fragen (Gremium), `/search`-Recherchen und „Vertiefen" wird der Verlauf der
  letzten 6 Nachrichten dem Gremium als Kontext mitgegeben — die eigentliche
  Konversationslogik bleibt dabei stateless (`swarm.pipe` braucht keine Änderung).
- **`/reset`** schließt den aktiven Thread; die nächste Nachricht startet einen
  frischen, leeren Kontext.

### Konsolidierung („Traum", `memory.pipe`, P2)

Ein periodischer Aufräum-/Verdichtungsjob, ausführbar per `pipe muninn.pipe consolidate`
(z.B. via Cron — Pipe hat vor P4 keinen eigenen Scheduler) oder per Telegram-Befehl
`/consolidate`:

- **`consolidate_threads`** verdichtet fällige Threads (geschlossen, oder aktiv seit
  3 Tagen ohne neue Nachricht) zu je einer Zusammenfassungs-Erinnerung und löscht
  danach die Rohnachrichten — begrenzt das sonst unbegrenzte Wachstum von `messages`.
- **`consolidate_memories`** senkt die Importance alter, nicht-`permanent`er
  Erinnerungen pro Lauf um 1 und vergisst sie endgültig, sobald sie bei Importance 0
  angekommen und alt genug sind. Explizit gemerkte (`permanent`) Erinnerungen bleiben
  unangetastet.
- **Bug gefixt**: das externe, reine-Pipe-`sqlite`-Modul wertet `datetime('now')`
  nicht aus (speichert wörtlich `"now"`) — `mem.now_ts` baut Zeitstempel seither
  selbst aus Pipes `now`/`format_time`.

### Inneres Gremium (`swarm.pipe`)

Vier Swarm-Agenten (`ai_swarm`) verfeinern eine Antwort per Handoff:

`planer` → `faktenwaechter` → `kritiker` → `registrator`

- **planer** analysiert und delegiert.
- **faktenwaechter** belegt Aussagen über `erinnerungen_suchen` (RAG), `web_search` und `web_fetch`.
- **kritiker** prüft auf Lücken/Widersprüche.
- **registrator** schreibt Erkenntnisse über `merken` bzw. `merken_quelle` (mit Quellen-URL) zurück.

Die Tools erhalten den DB-Handle über einen geteilten, mutablen Modul-State.

### Autonomer Executor (`executor.pipe`)

Aufgaben (`task`/`goal`) werden als **Pläne** ausgeführt:

- **Plan-Bibliothek** mit deterministischen Templates.
- **Schritt-Dispatcher** `exec_step` mit validierenden Aktionen
  (`store`/`graph`/`goal`/`retrieve`/`search`/`fetch`/`research`) — keine rohen Shell-/Datei-Builtins.
- **Checkpoints** in SQLite (`plans`-Tabelle), resumefähig.
- **Feedback-Loop**: bei Fehler wird der Plan revidiert (KI) bzw. der fehlgeschlagene
  Schritt gestrichen (deterministischer Fallback) und erneut versucht.
- **`mcp_call`-Aktion** (P1): ruft ein per MCP angebundenes (oder lokales) Werkzeug direkt
  per Name auf — deterministisch, über den Pipe-Builtin `tool_call`, ohne dass dafür eine
  KI-Tool-Call-Schleife nötig wäre. Damit können auch autonome Pläne (nicht nur das
  Gremium) MCP-Werkzeuge nutzen.

### Web-Recherche (`web.pipe`)

- `web_lookup` — DuckDuckGo Instant Answer + Wikipedia.
- `web_search_full` — DDG-HTML-Volltextsuche (ohne API-Key).
- `web_fetch` — Seite abrufen und zu Fließtext reduzieren.
- `research` — suchen → Top-N fetchen → verdichten → `{context, sources}`.

### MCP-Tool-Ökosystem (`mcp.pipe`)

Externe Werkzeuge (Dateisystem, GitHub, Datenbanken, ...) werden per
[Model Context Protocol](https://modelcontextprotocol.io) eingebunden, konfiguriert über
`MCP_SERVERS` (JSON-Liste in `.env`):

- **`parse_mcp_config`** parst die Konfiguration robust (ungültiges JSON → `[]`, kein Absturz).
- **`exec_whitelist_for`** extrahiert die Kommando-Basenamen aller `stdio`-Server für die
  Sandbox — nur genau diese Programme dürfen als Subprozess laufen.
- **`connect_servers`** verbindet alle konfigurierten Server (`mcp_use_stdio`/`mcp_use_sse`)
  best-effort: ein fehlschlagender Server blockiert die anderen nicht.
- **`discovered_tool_names`** liefert alle entdeckten Remote-Tool-Namen (ohne die lokal
  registrierten), die an einen eigenen **`werkzeugmeister`**-Agenten im Gremium gehen.

Ist kein Server konfiguriert, bleibt `exec` im Sandbox-Profil deaktiviert — Muninn läuft
unverändert wie zuvor.

### Telegram (`telegram.pipe`)

Reiner HTTP-Client über `http_request`/`to_json`/`parse_json` — kein WebSocket nötig.
Der Token wird **nie** im Code oder Repo abgelegt, sondern aus der Umgebung oder der
gitignorierten `.env` gelesen.

---

## Sicherheit

- **Secrets** nur in `.env` (gitignored); bei Leak: `@BotFather → /revoke`. MCP-Server-Env
  (z.B. `GITHUB_TOKEN`) wird per `"env:NAME"` zur Laufzeit aus der echten Umgebung gelesen,
  statt doppelt in `MCP_SERVERS` zu stehen.
- **Chat-Whitelist** über `TELEGRAM_ALLOWED_CHAT_ID`.
- **Keine rohen Shell-/Datei-Builtins für die KI** — nur registrierte, validierende
  Werkzeuge (Lehre aus der Sandbox-Audit-Reihe von Pipe, Runde 11).
- **Sandbox-Profil `muninn`** (aktiviert in `muninn.pipe`): `exec` ist standardmäßig aus
  und wird nur eingeschaltet, wenn `MCP_SERVERS` mindestens einen `stdio`-Server nennt —
  dann ausschließlich für dessen Kommandos (`exec_whitelist`). `audit_log` protokolliert
  alle sicherheitsrelevanten Ereignisse (HTTP, KI-Aufrufe, Tool-Calls); `max_tool_calls`
  begrenzt Tool-Ausführungen pro Gremium-Lauf gegen Endlosschleifen.
- **Web-Dashboard**: standardmäßig nur an `127.0.0.1` gebunden (`DASHBOARD_BIND`),
  nicht an `0.0.0.0` — es hat keinen echten Auth-Mechanismus, nur ein optionales
  `DASHBOARD_TOKEN` (Query-Param/Header). Für eine Bereitstellung über localhost
  hinaus gehört zwingend ein Reverse-Proxy mit TLS + echter Authentifizierung davor.
- **Datei-Sperre statt stillem Datenverlust**: `file_lock`/`file_unlock` (neuer
  Pipe-Builtin) sichern jeden `muninn.db`-Zugriff prozessübergreifend ab, damit
  Telegram-Bot und Dashboard gleichzeitig laufen können, ohne sich gegenseitig
  Schreibvorgänge zu überschreiben (siehe Architektur → Nebenläufigkeit).

---

## Roadmap

Der vollständige Ausbauplan (MCP-Tools, tiefes Gedächtnis, Omnichannel, Proaktivität,
Intelligenz-Upgrade, Ops) liegt in [Plan.md](Plan.md).

## Lizenz

Keine festgelegt (noch).
