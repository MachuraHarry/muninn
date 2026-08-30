# Muninn

**Muninn** — Odins Rabe des Gedächtnisses. Ein selbstgehosteter Langzeit-KI-Agent in
der Programmiersprache [Pipe](https://github.com/MachuraHarry/pipe): er vergisst nichts,
verfeinert Antworten durch ein inneres Gremium und ist über Telegram erreichbar.

Kein kurzer Chat-Bot, sondern ein Agent mit **persistenter "Seele"** (SQLite) und
**Langzeitgedächtnis**. Private Daten bleiben auf deiner Maschine.

## Stand der Entwicklung

| Meilenstein | Status |
|---|---|
| M1a — Telegram-Bot (Long-Polling) | ✅ |
| M1b — Kern-Seele (SQLite + Klassifikation) | ✅ |
| M2 — Wissensgraph + RAG | ✅ |
| M3 — Inneres Gremium (ai_swarm) | ✅ |
| M4 — Autonomer Executor | ✅ |
| M5 — Discord | ⏳ geplant |

## Schnellstart

Voraussetzung: ein Pipe-Binary (v1.1.x) plus die Module `sqlite` und `pipe-test`:

```bash
pipe -get sqlite
pipe -get pipe-test
```

Konfiguration anlegen (`.env` ist gitignored):

```bash
cp .env.example .env
# TELEGRAM_BOT_TOKEN=...        (von @BotFather)
# TELEGRAM_ALLOWED_CHAT_ID=...  (deine Chat-ID von @userinfobot; leer = jeder)
```

Bot starten:

```bash
pipe muninn.pipe          # Produktions-Loop (Long-Polling)
pipe muninn.pipe once     # ein Polling-Zyklus, dann exit (Test)
```

Tests (deterministisch, ohne KI/Netz):

```bash
pipe -test
```

## Architektur

```
muninn.pipe             Einstiegspunkt: dotenv, Whitelist, Long-Polling-Loop
modules/telegram.pipe   Telegram Bot API (Long-Polling, rein HTTP)
modules/memory.pipe     persistente "Seele" (SQLite) + Klassifikation + RAG + Wissensgraph
modules/swarm.pipe      inneres Gremium (ai_swarm-Handoffs)
modules/executor.pipe   autonomer Task-Executor (Plan-Bibliothek + Feedback-Loop)
muninn_test.pipe        deterministische Tests
```

### Seele

Alles Gedächtnis liegt in einer SQLite-Datei (`muninn.db`). Die Datenbank wird pro
Polling-Zyklus geöffnet, verarbeitet und mit `db_close` persistiert. Eingehende
Nachrichten werden klassifiziert (KI mit deterministischem Regel-Fallback) und
verdichtet, bevor sie in die Seele geschrieben werden.

### Wissen & RAG

- **Wissensgraph:** `entities`/`relations`-Tabellen; `add_entity`, `add_relation`, `neighbors_of`.
- **Hybride Retrieval:** `retrieve_context` kombiniert lexikalisches TF-IDF-Keyword-Scoring
  (Gewicht 0.75) mit semantischen Embeddings (Gewicht 0.25). DeepSeek liefert keine echten
  Embeddings, sondern nur einen 128-dim lexikalischen Hash — deshalb dominiert das
  Keyword-Scoring. Bei einem echten Embedding-Provider (>300 dim, z.B. OpenAI/Ollama)
  übernimmt automatisch die Semantik (Gewicht 0.7).

### Inneres Gremium

Vier Swarm-Agenten (`ai_swarm`) verfeinern eine Antwort in einer Handoff-Kette:

`planer` → `faktenwaechter` → `kritiker` → `registrator`

- **planer** analysiert und delegiert.
- **faktenwaechter** belegt Aussagen über das Tool `erinnerungen_suchen` (RAG).
- **kritiker** prüft auf Lücken/Widersprüche.
- **registrator** schreibt neue Erkenntnisse über `merken` zurück in die Seele.

Die Tools erhalten den DB-Handle über einen geteilten, mutablen Modul-State.

### Autonomer Executor

Aufgaben (`task`/`goal`) werden als **Pläne** ausgeführt:

- **Plan-Bibliothek** mit deterministischen Templates (permanent → store; task → store+goal; goal → goal).
- **Schritt-Dispatcher** `exec_step` mit validierenden Aktionen (`store`/`graph`/`goal`/`retrieve`) — keine rohen Shell-/Datei-Builtins.
- **Checkpoints** in SQLite (`plans`-Tabelle): jeder Schritt wird vor/nach der Ausführung persistiert (resumefähig).
- **Feedback-Loop**: schlägt ein Schritt fehl, wird der Plan revidiert (KI) bzw. der fehlgeschlagene Schritt gestrichen (deterministischer Fallback), dann erneut versucht.

### Telegram

Reiner HTTP-Client über `http_request`/`to_json`/`parse_json` — kein WebSocket nötig.
Der Bot-Token wird **nie** im Code oder im Repo abgelegt, sondern über die
Umgebungsvariable `TELEGRAM_BOT_TOKEN` oder die gitignorierte `.env` gelesen.

## Sicherheit

- Token nur in `.env` (gitignored); nie committen. Bei Leak: `@BotFather → /revoke`.
- Chat-Whitelist über `TELEGRAM_ALLOWED_CHAT_ID`.
- Keine rohen Shell-/Datei-Builtins werden der KI exponiert — nur registrierte,
  validierende Werkzeuge (Lehre aus der Sandbox-Audit-Reihe von Pipe).
