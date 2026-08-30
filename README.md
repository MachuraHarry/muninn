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

- Ein Pipe-Binary mit dem `tool_call`-Builtin (Stand: noch nicht in einem offiziellen
  Release — lokal in `~/pipe` ab Commit `f7ae197` ergänzt, siehe
  [Plan.md](Plan.md#p1--tool-ökosystem-via-mcp--priorität-zuerst--erledigt)) —
  [pipe](https://github.com/MachuraHarry/pipe)
- Die Pipe-Module `sqlite` und `pipe-test`:

```bash
pipe -get sqlite
pipe -get pipe-test
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
pipe muninn.pipe          # Produktions-Loop (Long-Polling, läuft dauerhaft)
pipe muninn.pipe once     # ein Polling-Zyklus, dann exit (Test)
```

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

## Architektur

```
muninn.pipe             Einstiegspunkt: dotenv, Whitelist, Long-Polling-Loop, Router
modules/telegram.pipe   Telegram Bot API (Polling, Inline-Keyboard, Callbacks)
modules/memory.pipe     Seele: memories, embeddings, entities, relations, goals, events + RAG
modules/swarm.pipe      Gremium: planer/faktenwaechter/kritiker/registrator (+ Web-Tools)
modules/executor.pipe   Autonomer Executor: Plan-Bibliothek, Checkpoints, Feedback-Loop
modules/web.pipe        Recherche: web_lookup, web_search_full, web_fetch, research
modules/mcp.pipe        MCP-Tool-Ökosystem: Server-Konfig, exec-Whitelist, Verbindungsaufbau
muninn_test.pipe        deterministische Tests
```

### Seele (`memory.pipe`)

Alles Gedächtnis liegt in `muninn.db`. Die Datenbank wird pro Polling-Zyklus geöffnet,
verarbeitet und mit `db_close` persistiert. Eingehende Nachrichten werden klassifiziert
(KI mit deterministischem Regel-Fallback) und verdichtet, bevor sie gespeichert werden.

### Wissen & RAG (`memory.pipe`)

- **Wissensgraph:** `entities`/`relations`; `add_entity`, `add_relation`, `neighbors_of`.
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

---

## Roadmap

Der vollständige Ausbauplan (MCP-Tools, tiefes Gedächtnis, Omnichannel, Proaktivität,
Intelligenz-Upgrade, Ops) liegt in [Plan.md](Plan.md).

## Lizenz

Keine festgelegt (noch).
