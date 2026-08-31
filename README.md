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
- **Hybride Suche (RAG)** — TF-IDF-Keyword-Scoring + semantische Embeddings; faellt bei leerem
  Ergebnis auf die wichtigsten dauerhaften Fakten zurueck (Fragen wie „Wer bin ich?" bestehen
  sonst nur aus Stoppwoertern und liefern garantiert 0 Treffer).
- **Inneres Gremium, EIN Pfad statt Klassifikations-Toepfe** — jede freie Nachricht laeuft durch
  `planer → faktenwaechter → kritiker → registrator`, mit vollem Gespraechsverlauf und allen
  Werkzeugen. Nur echte, eindeutige Befehle (`/remind`, `/search`, Slash-Commands) bleiben
  deterministische Fast-Paths.
- **P5 — automatische Werkzeug-Spezialisierung** — jeder verbundene MCP-Server bekommt seinen
  eigenen, fokussierten `werkzeug_<alias>`-Agenten statt eines Alleskönners mit allen
  Werkzeugen — skaliert von selbst mit jedem neuen Server.
- **Ehrlichkeits-Regeln** — das Gremium unterscheidet KI-Recherche-Ergebnisse von echten
  Nutzeraussagen (keine erfundenen „Interessen" aus Recherche-Nebenprodukten), erfindet keine
  Aktionen bei vagen Anfragen, und beantwortet Fragen zu eigenen Werkzeugen aus der echten,
  aktuellen Werkzeugliste statt per Websuche.
- **Lernen aus dem Web** — neue Erkenntnisse werden dauerhaft **mit Quellen-URL** gespeichert und später zitiert.
- **Proaktivität (P4)** — Scheduler im Bot-Loop: Erinnerungen („Erinnere mich …", deterministischer
  Pfad — keine KI-Bestätigung ohne tatsächliche Terminierung), tägliches Morgen-Briefing,
  automatisches Fortsetzen unterbrochener Pläne, 👍/👎-Feedback-Lernen.
- **Web-Recherche** — DuckDuckGo + Wikipedia, Seiten-Fetch und Zusammenfassung (kein API-Key nötig).
- **MCP-Tool-Ökosystem** — beliebige externe Werkzeuge (Dateisystem, Browser, Docker, Wetter,
  Dokumentations-Lookup, Google Workspace, ...) per Model Context Protocol anbinden; laufen unter
  einem Sandbox-Profil mit eng gefasster exec-Whitelist.
- **Live-Status-Stream** — während das Gremium arbeitet, editiert Muninn EINE Telegram-Nachricht
  laufend weiter (welcher Agent aktiv ist, welches Werkzeug er aufruft), statt neuer
  Nachrichtenblöcke oder Schweigens bis zur Endantwort.
- **Google Workspace** — Gmail (inkl. Versand), Drive und Kalender per OAuth 2.0 angebunden
  (`taylorwilsdon/google_workspace_mcp`), Tokens bewusst außerhalb des Filesystem-MCP-Bereichs.
- **Sprachnachrichten** — der Registrator entscheidet pro Antwort selbst, ob eine echte
  Telegram-Sprachnachricht (statt Text) passender ist; lokale Synthese per Piper + ffmpeg,
  kein Cloud-Dienst/API-Key.
- **Eingeschränkte Docker-Erweiterung** — Image ziehen + Container anlegen, aber strukturell
  ohne Volume-Mounts/`--privileged`, Ports standardmäßig nur auf `127.0.0.1` (siehe
  [Sicherheit](#sicherheit)).
- **Kosten-Tracking** — KI-Betriebskosten werden pro Session in der Seele protokolliert;
  `/costs` liefert eine KI-zusammengefasste (aber zahlenmäßig deterministisch berechnete)
  Übersicht, das Dashboard hat einen eigenen Kosten-Tab.
- **Telegram-Bot** — Long-Polling, Inline-Buttons, natives Befehlsmenü (`/`-Aufklapp-Menü über
  `setMyCommands`), Foto-Verständnis (`ai_vision`).
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
| P4 — Proaktivität (Scheduler, Erinnerungen, Briefing) | ✅ |
| P5 — Automatische Werkzeug-Spezialisierung + Ehrlichkeits-Regeln | ✅ |
| Kosten-Tracking (`/costs`, Dashboard-Tab) | ✅ |
| Eingeschränkte Docker-Erweiterung (Image ziehen, Container anlegen) | ✅ |
| Google Workspace (Gmail, Drive, Kalender) via MCP | ✅ |
| Sprachnachrichten (Piper-TTS, KI entscheidet selbst) | ✅ |
| Live-Status-Stream im Telegram-Chat (`ai_swarm_stream`) | ✅ |
| M5 — Discord | ⏳ geplant |

Weitere Schritte: [Plan.md](Plan.md)

---

## Schnellstart

### Voraussetzungen

- Ein Pipe-Binary mit den Builtins `tool_call` (P1) und `file_lock`/`file_unlock`
  (P3), dem Fix für den `arguments`-`omitempty`-Bug im MCP-Client (behebt
  Tool-Aufrufe an zod-basierte MCP-Server, die ein leeres `arguments`-Feld statt
  eines fehlenden erwarten — betraf z.B. `mcp-docker-server`/`time-mcp`), sowie
  einem sauberen Shutdown fuer stdio-MCP-Subprozesse (`Pdeathsig`+`Setpgid`+ein
  SIGTERM-Handler — ohne das blieben verbundene MCP-Server samt ihren eigenen
  Kindprozessen bei jedem Neustart als Prozessleiche haengen, siehe
  `pkg/mcp/procattr_unix.go`) — Stand: noch nicht in einem offiziellen
  Release-Tag, aber committed und nach `origin/master` gepusht im
  [`pipe`](https://github.com/MachuraHarry/pipe)-Repo.
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
DEEPSEEK_API_KEY=sk-...                 # erforderlich: DeepSeek-Key für Klassifikation, Gremium, Zusammenfassung
MCP_SERVERS=                            # optional: JSON-Liste externer MCP-Server (siehe .env.example)
MCP_AUTO_SERVERS=                       # optional: vertrauenswürdige Server mit Keywords für Bedarfsladen
BRIEFING_TIME=08:00                     # optional (P4): Uhrzeit des täglichen Briefings
MUNINN_TZ_OFFSET=0                      # optional (P4): Sekunden-Offset der lokalen Zeitzone
```

> Muninn nutzt **DeepSeek** als Provider (kostenlos anmeldbar unter platform.deepseek.com).
> Die Implementierung setzt derzeit bewusst auf DeepSeek fest; `MUNINN_PROVIDER`
> wird nur als Hinweis gelesen, aber nicht als alternativer Provider aktiviert.

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

Alle Befehle sind zusätzlich über Telegrams natives `/`-Aufklapp-Menü sichtbar
(`setMyCommands`, einmalig beim Start registriert) — auch über den Menü-Button
neben dem Eingabefeld.

### Befehle

| Befehl | Beschreibung |
|--------|--------------|
| `/start` | Begrüßung |
| `/help` | alle Befehle |
| `/status` | Zustand (Erinnerungen, Provider, Gremium, Executor) |
| `/costs` | KI-Betriebskosten zusammengefasst (Sessions, Tokens, $) — KI fasst zusammen, Zahlen kommen deterministisch aus der Seele |
| `/list` | deine wichtigsten Erinnerungen |
| `/search <begriff>` | Web-Recherche mit Quellen |
| `/reset` | Gesprächsverlauf zurücksetzen (frischer Kontext für Folgefragen) |
| `/consolidate` | Traum: alte Gespräche verdichten, Erinnerungen altern/vergessen lassen |
| `/graph <Name>` | Wissensgraph abfragen (Nachbarn einer Entität) |
| `/remind <Anweisung>` | Erinnerung planen (z.B. `/remind in 10 Minuten an die Pause`) |
| `/reminders` | offene Erinnerungen/Briefings anzeigen |
| `/briefing` | tägliches Morgen-Briefing aktivieren (`/briefing stop` zum Abbestellen) |
| `/learn <URL>` | Dokument lernen (oder direkt eine `.txt`/`.md`-Datei schicken) |

### Natürliche Sprache

Nur wenige, eindeutige Muster laufen als deterministischer Fast-Path direkt in
`muninn.pipe` (ohne KI-Entscheidung dazwischen):

| Eingabe | Wirkung |
|---------|---------|
| „Erinnere mich …" | plant eine Erinnerung (deterministisch, wie `/remind` — bewusst nicht dem Gremium überlassen, siehe Architektur → Gremium) |
| „Suche …" / „Recherchiere …" / „Finde …" | Web-Recherche (wie `/search`) |

**Alles andere** — „Merke dir …", „Erledige …", Fragen, beiläufiger Small Talk,
Anfragen an angebundene Werkzeuge (Dateisystem, Browser, Docker, …) — läuft
durch **einen** gemeinsamen Pfad: das Gremium, mit vollem Gesprächsverlauf und
allen Werkzeugen. Es entscheidet selbst pro Nachricht, ob es merkt, eine
Erinnerung plant (`erinnerung_planen`-Werkzeug für implizite Fälle wie „Ich
habe morgen einen Termin …"), recherchiert, ein Werkzeug nutzt oder einfach
antwortet — statt einer vorab-Klassifikation in feste Töpfe (siehe
[Architektur → Inneres Gremium](#inneres-gremium-swarmpipe) für die
Begründung).

**Live-Status statt Stille.** Während das Gremium arbeitet, sendet Muninn eine
Platzhalternachricht und bearbeitet sie laufend per `editMessageText`
(„🧭 Plane die Antwort...", „🔧 Nutze wetter... → ruft get_forecast auf", …),
gedrosselt auf ca. 1 Edit/Sekunde — statt neuer Nachrichtenblöcke oder
kompletten Schweigens bis zur Endantwort. Details:
[Architektur → Inneres Gremium](#inneres-gremium-swarmpipe).

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
  `/learn <URL>`, `/reset`, `/consolidate`) plus natürliche Sprache über
  denselben Gremium-Pfad wie Telegram. Eigene, bewusst schlanke Kommando-Weiche
  (`dashboard_reply`) statt Wiederverwendung von Telegrams `handle_message`
  (Telegram-spezifisches Verhalten wie Inline-Buttons/„typing"-Status würde
  sonst mit rein) — siehe Architektur unten.
- **Erinnerungen** — durchsuchen (Stichwort + Art-Filter), Importance direkt
  anpassen (▲/▼), löschen.
- **Ziele** — Übersicht offener/erledigter Ziele, per Klick umschalten.
- **Wissensgraph** — Nachbarn einer Entität abfragen.
- **Aktivität** — jüngste Ereignisse (klassifizierte Nachrichten) und Executor-Pläne
  mit Status (offen/erledigt/fehlgeschlagen).
- **Werkzeuge** — alle registrierten (lokalen + per MCP gebrückten) Tools.
- **Kosten** — dieselbe Zusammenfassung wie `/costs`, als eigener Tab (Gesamt + pro Session).
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
modules/scheduler.pipe  Proaktivität (P4): geplante Erinnerungen, Briefing, Plan-Resume-Tick
modules/docker_tools.pipe  Eingeschränkte Docker-Erweiterung: Image ziehen, Container anlegen
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
geöffnet, verarbeitet und persistiert. Was das Gremium als dauerhaft merkenswert
einstuft, wird über `merken`/`merken_quelle` verdichtet gespeichert (siehe
Architektur → Inneres Gremium) — es gibt keine separate Vorab-Klassifikation
mehr, die das für jede Nachricht pauschal entscheidet.

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

**Warum ein KI-Schwarm statt eines einzelnen KI-Aufrufs?** Das Gremium ist
technisch ein KI-Schwarm (Pipe-Builtin `ai_swarm`/`ai_swarm_trace`/
`ai_swarm_stream`) — mehrere spezialisierte Agenten mit je eigenem
System-Prompt und eigenem Werkzeugsatz, die die Konversation per Handoff
untereinander weiterreichen, statt ein einzelnes KI-Modell alles auf einmal
entscheiden zu lassen. Vorteile gegenüber einem einzelnen Alleskönner-Aufruf:

- **Spezialisierung statt Überforderung** — ein Agent mit drei klar
  umrissenen Werkzeugen (z.B. `faktenwaechter`: Gedächtnis + Web) trifft
  zuverlässiger die richtige Werkzeugwahl als ein Agent, der aus Dutzenden
  Werkzeugen aller Domänen gleichzeitig wählen müsste (siehe P5 unten).
- **Eingebaute Selbstkorrektur** — der `kritiker`-Schritt prüft jede Antwort
  auf Lücken/Widersprüche, bevor sie den Nutzer erreicht, und kann bei Bedarf
  zurück an `faktenwaechter`/den zuständigen Spezialisten schicken, statt
  einen einzigen unüberprüften Versuch auszuliefern.
- **Trennung von Recherche und Formulierung** — `registrator` schließt bewusst
  als einziger Agent ab (Speichern, Erinnerungen planen, Antwortformat), damit
  nicht jeder Zwischenschritt eigene, ggf. widersprüchliche Nutzeraussagen
  formuliert.
- **Skaliert ohne Umbau** — neue Fähigkeiten (ein neuer MCP-Server, siehe P5)
  bekommen automatisch einen eigenen Agenten, statt den Prompt eines
  monolithischen Alleskönners immer weiter aufzublähen.

Kehrseite: mehr Agenten-Runden bedeuten mehr Latenz und Kosten pro Antwort
als ein einzelner KI-Aufruf — abgefedert durch den Live-Status-Stream weiter
unten in diesem Abschnitt, der während der Wartezeit zeigt, welcher Agent
gerade was tut.

**Ein Pfad statt Klassifikations-Töpfe.** Ursprünglich klassifizierte Muninn jede
Nachricht vorab (regelbasiert + ein kontextfreier KI-Aufruf) in
`permanent`/`reminder`/`task`/`goal`/`fleeting`/`question` und verzweigte in sechs
isolierte, größtenteils werkzeuglose Handler. Das führte zu widersprüchlichem
Verhalten bei identischem Text (je nachdem, welchen Topf die Klassifikation traf)
und einem blind JSON-Schritte erfindenden Task-Executor ohne jeden Kontext. Seit
dem P5-Umbau läuft **jede freie Nachricht durch das Gremium**, mit vollem
Gesprächsverlauf und Zugriff auf alle Werkzeuge:

`planer` → `faktenwaechter` → `kritiker` → `registrator`

- **planer** analysiert und delegiert — an `faktenwaechter` (Fakten-/Gedächtnis-/
  Meta-Fragen), an den passenden `werkzeug_<alias>`-Spezialisten (siehe P5 unten)
  oder direkt an `kritiker`.
- **faktenwaechter** belegt Aussagen über `erinnerungen_suchen` (RAG), `web_search`
  und `web_fetch`.
- **kritiker** prüft auf Lücken/Widersprüche.
- **registrator** schreibt Erkenntnisse über `merken`/`merken_quelle` zurück, plant
  bei Bedarf eine Erinnerung (`erinnerung_planen`) und verfasst die Endantwort.

Ein deterministischer Backstop in `run_gremium` fängt den Fall ab, dass ein Agent
sein Handoff-Werkzeug nicht aufruft und der Pfad nicht beim `registrator` endet
(sonst würden rohe interne Kommentare durchrutschen) — Prompt-Regeln allein
garantieren das bei einem LLM nicht zuverlässig genug.

**Live-Status-Stream.** `ai_swarm_trace` (der Pipe-Builtin hinter dem Gremium)
lief bisher komplett synchron durch und lieferte erst am Ende ein Ergebnis —
kein Zwischenstand für den Nutzer. Der Pipe-Interpreter selbst (`~/pipe`,
`pkg/ai/swarm.go`) bekam dafür einen optionalen Fortschritts-Callback
(`SwarmProgressFunc`), der nach jedem Runden-Start, Werkzeugaufruf, Handoff und
der Endantwort feuert; als neuer Builtin `ai_swarm_stream` (task, entry_agent,
max_rounds, on_progress) nimmt er dafür eine Pipe-Closure entgegen. `swarm.pipe`
exportiert **`run_gremium_stream`** als UI-neutrales Gegenstück zu
`run_gremium` — dieselbe Logik (inkl. Backstop), nur mit `on_update`-Callback.
Das Telegram-spezifische Formatieren/Editieren (`swarm_status_text`,
`tel_finalize`, `make_swarm_updater`) lebt bewusst in `muninn.pipe`, nicht hier.

**P5 — automatische Werkzeug-Spezialisierung.** `mcp.discovered_tools_by_source`
gruppiert alle per MCP verbundenen Werkzeuge nach Herkunfts-Server; `init_gremium`
erzeugt daraus automatisch **einen eigenen Agenten pro Server**
(`werkzeug_filesystem`, `werkzeug_docker`, `werkzeug_browser`, …) statt eines
Alleskönners mit einer riesigen, flachen Werkzeugliste — das hält die
Tool-Auswahl der KI treffsicher und skaliert ohne Code-Änderung mit jedem neuen
MCP-Server.

**Ehrlichkeits-Regeln** (System-Prompt-Bausteine, in `swarm.pipe` als eigene
Konstanten):

- `HONESTY_RULE` — bei zu vagen Anfragen ("mach mal irgendwas") nachfragen statt
  eine Aktion zu erfinden oder zu behaupten, etwas getan zu haben.
- `MEMORY_HONESTY_RULE` — `erinnerungen_suchen`-Treffer, die keine echten
  Nutzeraussagen sind (alte Recherchen, Task-Protokolle), werden von
  `retrieve_context` markiert; das Gremium darf daraus keine Interessen/Meinungen
  des Nutzers konstruieren.
- `TOOL_DISCIPLINE_RULE`/`tools_desc` — Fragen zu Muninns eigenen Fähigkeiten
  werden aus der echten, aktuell verbundenen Werkzeugliste beantwortet, nie per
  Websuche (das Internet weiß nichts über diese konkrete Instanz).

Die Tools erhalten DB-Handle, Chat-ID und Zeitzone über einen geteilten, mutablen
Modul-State (`STATE`).

### Autonomer Executor (`executor.pipe`)

Plan-Infrastruktur mit Checkpoints — heute primär für **P4s langlaufende,
unterbrechbare Ziele** genutzt (`resume_plan`/`resume_running_plans`, vom
`goal_tick`-Scheduler periodisch angestoßen), **nicht mehr** als blinder
Auto-Handler für casual formulierte "Erledige …"-Nachrichten (das war genau der
kontextfreie Task-Planer, der im P5-Umbau durch das Gremium ersetzt wurde, siehe
oben):

- **Plan-Bibliothek** mit deterministischen Templates.
- **Schritt-Dispatcher** `exec_step` mit validierenden Aktionen
  (`store`/`graph`/`goal`/`retrieve`/`search`/`fetch`/`research`/`mcp_call`) —
  keine rohen Shell-/Datei-Builtins.
- **Checkpoints** in SQLite (`plans`-Tabelle), resumefähig.
- **Feedback-Loop**: bei Fehler wird der Plan revidiert (KI) bzw. der fehlgeschlagene
  Schritt gestrichen (deterministischer Fallback) und erneut versucht.
- **`mcp_call`-Aktion** (P1): ruft ein per MCP angebundenes (oder lokales) Werkzeug direkt
  per Name auf — deterministisch, über den Pipe-Builtin `tool_call`, ohne dass dafür eine
  KI-Tool-Call-Schleife nötig wäre.

### Proaktivität (`scheduler.pipe`, P4)

Erinnerungen, tägliches Briefing und automatisches Plan-Fortsetzen laufen über
den Scheduler. **Kein eigener Scheduler-Prozess** (Pipe hat vor P4 keinen, und
Nebenläufigkeit hält Muninn bewusst pro Prozess): der Tick steckt im
Telegram-Long-Polling-Loop, der seinen Timeout dynamisch auf „Zeit bis zur
nächsten fälligen Aufgabe" kappt (`next_due_ms`) — Single-threaded, keine
DB-Konkurrenz, trotzdem Sekunden-Präzision.

- **`scheduled`-Tabelle** (`kind, chat_id, note, due_ts, repeat, state`),
  `due_ts` als Unix-Sekunden (sortier-/arithmetisierbar).
- **Erinnerungen**: „Erinnere mich …" oder `/remind` → `parse_reminder`
  (KI mit deterministischem Regel-Fallback) → `schedule`. Einmalig, `daily`
  oder `weekly`.
- **Briefing**: `/briefing` legt einen `daily`-Eintrag zur `BRIEFING_TIME`
  an; beim Feuern baut `compose_briefing` den Text deterministisch aus der
  Seele (wichtigste Erinnerungen + offene Ziele + jüngste Ereignisse).
- **Plan-Resume**: `exe.resume_plan`/`resume_running_plans` setzen unterbrochene
  Pläne ab ihrem Checkpoint (`step_idx`) fort — der `goal_tick`-Scheduler-Kind
  ruft das periodisch auf.
- **Feedback-Lernen**: 👍/👎-Buttons auf Antworten rufen `adjust_by_content`
  auf und heben/senken die Importance der (ggf. zuvor gespeicherten) Antwort.

Zeitzonen: Pipe hat keinen Timezone-Builtin (`format_time` arbeitet in UTC);
`MUNINN_TZ_OFFSET` (Sekunden, z.B. `7200` für UTC+2) verschiebt die lokale
Briefing-/Erinnerungszeit, siehe `.env.example`.

### Web-Recherche (`web.pipe`)

- `web_lookup` — DuckDuckGo Instant Answer + Wikipedia.
- `web_search_full` — DDG-HTML-Volltextsuche (ohne API-Key).
- `web_fetch` — Seite abrufen und zu Fließtext reduzieren.
- `research` — suchen → Top-N fetchen → verdichten → `{context, sources}`.

### MCP-Tool-Ökosystem (`mcp.pipe`)

Externe Werkzeuge (Dateisystem, Browser, Docker, ...) werden per
[Model Context Protocol](https://modelcontextprotocol.io) eingebunden, konfiguriert über
`MCP_SERVERS` und/oder `MCP_AUTO_SERVERS` (beide JSON-Listen in `.env`, werden
zusammengeführt und beim Start gemeinsam verbunden — `MCP_AUTO_SERVERS` trägt
zusätzlich `keywords` für spätere On-Demand-Zuordnung im Executor):

- **`parse_mcp_config`** parst die Konfiguration robust (ungültiges JSON → `[]`, kein Absturz).
- **`exec_whitelist_for`** extrahiert die Kommando-Basenamen aller `stdio`-Server für die
  Sandbox — nur genau diese Programme dürfen als Subprozess laufen.
- **`connect_servers`** verbindet alle konfigurierten Server (`mcp_use_stdio`/`mcp_use_sse`)
  best-effort: ein fehlschlagender Server blockiert die anderen nicht.
- **`discovered_tools_by_source`** gruppiert alle entdeckten Remote-Tool-Namen nach
  Herkunfts-Server (P5): jeder verbundene MCP-Server bekommt automatisch einen eigenen,
  fokussierten **`werkzeug_<alias>`**-Agenten im Gremium statt eines Alleskönners — skaliert
  von selbst mit jedem neu angebundenen Server, ohne Code-Änderung.

Ist kein Server konfiguriert, bleibt `exec` im Sandbox-Profil deaktiviert — Muninn läuft
unverändert wie zuvor.

**Aktuell konfiguriert** (`.env.example`, alle ohne API-Key nutzbar):

| Alias | Server | Bringt |
|---|---|---|
| `filesystem` | `@modelcontextprotocol/server-filesystem` | Dateien im `mcp_data`-Ordner |
| `memory` | `@modelcontextprotocol/server-memory` | Wissensgraph |
| `denkwerkzeug` | `@modelcontextprotocol/server-sequential-thinking` | strukturiertes Durchdenken komplexer Anfragen |
| `browser` | `@playwright/mcp` (Microsoft, offiziell) | echte Web-Interaktion — navigieren, klicken, Formulare |
| `doku` | `@upstash/context7-mcp` | aktuelle Bibliotheks-/Framework-Dokumentation |
| `wetter` | `@dangahagan/weather-mcp` | Live-Wetterdaten (NOAA/Open-Meteo) |
| `docker` | `mcp-docker-server` | bestehende Container/Images verwalten (kein Erstellen — siehe unten) |
| `zeit` | `time-mcp` | Uhrzeit/Zeitzonen-Umrechnung |
| `google` | `taylorwilsdon/google_workspace_mcp` | Gmail/Drive/Kalender — braucht eigenes OAuth-Setup, siehe unten |

### Eingeschränkte Docker-Erweiterung (`docker_tools.pipe`)

Der MCP-Server `docker` verwaltet bewusst nur **bestehende** Container/Images
(kein `docker pull`/`docker run`). Volle Docker-MCP-Server mit Image-Pull und
Container-Erstellung existieren, kommen aber mit expliziter Warnung ihrer Autoren:
„inherently unsafe" — Host-Volume-Mounts in einem Container sind faktisch
Root-Zugriff auf den Host. `docker_tools.pipe` deckt den konkreten Bedarf
(„Webserver-Container aufsetzen") ab, ohne diese Fähigkeit:

- **Kein Parameter für Volume-Mounts im Tool-Schema überhaupt** — strukturell
  nicht anfragbar, nicht nur unerwünscht per Prompt-Bitte.
- Fester Kommando-Template ohne `--privileged`/`--network=host`, keine frei
  wählbaren zusätzlichen Docker-Flags.
- Port-Bindung standardmäßig nur auf `127.0.0.1`, öffentlich nur mit explizitem
  `public='true'`.
- Image-/Container-Name und Ports werden gegen strikt verankerte Regex (`^...$`)
  geprüft, bevor sie in `exec()` eingesetzt werden — verhindert Argument-Injection
  (z.B. ein „Image-Name" wie `nginx --privileged`, der sonst als zusätzliches
  Docker-Flag durchgereicht würde). `exec()` selbst tokenisiert über
  `splitShellWords` und ruft direkt auf (kein `sh -c`), die Regex-Prüfung ist
  trotzdem nötig für die Argument-Ebene.

Nur der `werkzeug_docker`-Spezial-Agent bekommt diese beiden zusätzlichen
lokalen Werkzeuge neben den MCP-Werkzeugen aus `docker`.

### Google Workspace (`google_creds/`)

Anders als die übrigen MCP-Server braucht Gmail/Drive/Kalender echtes OAuth 2.0
statt eines einfachen API-Keys — Einrichtung in der Google Cloud Console
(API-Aktivierung, OAuth-Consent-Screen, Client-ID/Secret), einmalige
Browser-Freigabe pro Google-Konto. Details:

- **Consent-Screen bleibt auf „Testing"**, mit dem eigenen Account als
  Test-User — „In production" stellen würde für die genutzten sensiblen
  Scopes (`gmail.send`, volles Drive/Calendar) eine echte App-Überprüfung
  durch Google verlangen. Einziger Nachteil: das OAuth-Token läuft alle 7 Tage
  ab und muss neu bestätigt werden (dauert ca. 2 Minuten).
- **`--single-user`-Modus**: keine Multi-User-Session-Zuordnung, Zugangsdaten
  werden aus dem konfigurierten `WORKSPACE_MCP_CREDENTIALS_DIR` gelesen.
- **Tokens liegen in `google_creds/`** (gitignored, `chmod 700`) —
  **bewusst außerhalb von `mcp_data`**, das der Filesystem-MCP-Server offenlegt.
- **`BROWSER=/bin/true`** im Server-Environment ist Absicht: Der Server ruft bei
  jeder Auth-Anfrage `webbrowser.open()` auf. Auf einem Server ohne GUI fällt
  Python dabei auf `xdg-open` → `www-browser` zurück, einen Terminal-Textbrowser,
  der volle ANSI-Steuercodes auf **stdout** schreibt — genau den Kanal, den
  MCP-stdio für JSON braucht. Das zerstört den Protokoll-Stream und lässt den
  Aufruf hängen. `/bin/true` macht `webbrowser.open()` zu einem sauberen No-op
  (die Login-URL steht trotzdem in der Werkzeug-Antwort).
- **`WORKSPACE_MCP_PERMISSIONS=gmail:send drive:full calendar:full`** — bewusste
  Entscheidung für vollen Gmail-Versand statt nur Entwürfe (Nutzerentscheidung,
  siehe Git-Historie); Drive/Kalender sind ohnehin jederzeit rückgängig zu
  machen.
- Der `werkzeug_google`-Spezial-Agent bekommt eine eigene Anleitung: bei
  fehlender Autorisierung selbstständig `start_google_auth` aufrufen und die
  zurückgegebene Freigabe-URL an den Nutzer weiterreichen, statt zu behaupten,
  das Verbinden ginge nicht.

Einmalige Einrichtung (aus der Ferne): SSH-Port-Forward auf den OAuth-Callback
(`ssh -L 8000:localhost:8000 user@server`), dann in Telegram „Verbinde mein
Google-Konto" schreiben und den zurückgegebenen Link im eigenen Browser öffnen.

### Sprachnachrichten (`tts_synth.sh`)

Der Registrator entscheidet pro Antwort selbst, ob eine echte Telegram-
Sprachnachricht (`sendVoice`) passender ist als Text — kurze/lockere
Antworten oder eine explizite Bitte des Nutzers eher als Sprache, lange/
inhaltsreiche Antworten, Listen, Links oder Code bleiben Text (klingt als
Sprache nicht sinnvoll). Wie jede Prompt-Regel nicht hundertprozentig
zuverlässig, aber bei expliziter Bitte ("sag mir das als Sprachnachricht")
verlässlich getestet.

- **Rein lokal, kein API-Key**: [Piper](https://github.com/rhasspy/piper)
  (neuronale TTS, hier die deutsche `thorsten-high`-Stimme) synthetisiert
  Text zu WAV, `ffmpeg` konvertiert nach Opus/OGG — Telegrams einziges
  Format für eine "echte" Sprachnachrichten-Blase (`sendAudio`/Datei-Anhang
  würde stattdessen als normaler Audio-Player angezeigt).
- **Fester Zwei-Schritt-Kommandotemplate** in `tts_synth.sh`, aufgerufen per
  `exec()` (kein MCP-Server dafür) — Stimme/Modell/Encoding sind im Skript
  hart codiert, nicht AI-wählbar, gleiches Sicherheitsmuster wie bei der
  [Docker-Erweiterung](#eingeschränkte-docker-erweiterung-docker_toolspipe).
- Zwischendateien (`tts_tmp/`, gitignored) werden nach jedem Versand sofort
  wieder gelöscht.

### Kosten-Tracking (`memory.pipe`, `muninn.pipe`)

`ai_cost`/`ai_tokens` sind reine In-Prozess-Zähler über die Laufzeit — nichts
davon übersteht einen Neustart oder ist historisch auswertbar. Die `cost_log`-
Tabelle persistiert periodische Schnappschüsse (nur wenn sich seit dem letzten
Zyklus etwas geändert hat, kein Log pro leerem Poll-Zyklus) unter einer
fortlaufenden `session_id` — **ein Prozesslauf = eine Session**, da die Zähler
selbst bei jedem Neustart wieder bei 0 anfangen. `mem.cost_summary` aggregiert
in Pipe selbst (bewusst keine SQL-`GROUP BY`/Aggregatfunktionen, siehe
Sicherheits-/Zuverlässigkeits-Hinweis zum reinen-Pipe-`sqlite`-Modul weiter
unten): pro Session wird das Maximum genommen (die Werte sind pro Session
monoton steigende Zähler), über Sessions hinweg summiert.

`/costs` (Telegram) und der „Kosten"-Tab (Dashboard) zeigen dieselbe Übersicht.
Die Zahlen selbst kommen **deterministisch** aus `cost_summary` — die KI
bekommt für `/costs` nur die Aufgabe, diese fertigen Zahlen lesbar
zusammenzufassen, mit expliziter Anweisung, nichts selbst nachzurechnen oder zu
erfinden (Halluzinationsrisiko bei den Zahlen selbst ausgeschlossen).

### Telegram (`telegram.pipe`)

Reiner HTTP-Client über `http_request`/`to_json`/`parse_json` — kein WebSocket nötig.
Der Token wird **nie** im Code oder Repo abgelegt, sondern aus der Umgebung oder der
gitignorierten `.env` gelesen.

- **Natives Befehlsmenü**: `tel_set_my_commands` (`setMyCommands`) registriert alle
  Befehle samt Beschreibung einmalig beim Start — Telegram speichert das
  serverseitig, sichtbar im `/`-Aufklapp-Menü und über den Menü-Button.
- **Markdown-Normalisierung**: LLM-Ausgaben sind durchgehend CommonMark-Stil
  (`**fett**`), Telegrams `Markdown`-Parse-Mode kennt aber nur einfache
  Sternchen. `tg_markdown` normalisiert vor dem Senden; scheitert der Versand
  trotzdem (z.B. unausgewogene Entities), wird automatisch als Klartext
  nachgesendet, damit nie eine Antwort wegen eines Formatierungsfehlers
  verlorengeht.
- **Fotos**: `ai_vision` beantwortet Bildunterschriften/Standardfragen zu
  geschickten Fotos; DeepSeeks Standardmodell kann keine Bilder, `handle_photo`
  schaltet dafür kurz auf ein Vision-Modell um und danach zuverlässig zurück.

---

## Sicherheit

- **Secrets** nur in `.env` (gitignored); bei Leak: `@BotFather → /revoke`. MCP-Server-Env
  (z.B. `GITHUB_TOKEN`) wird per `"env:NAME"` zur Laufzeit aus der echten Umgebung gelesen,
  statt doppelt in `MCP_SERVERS` zu stehen.
- **Chat-Whitelist** über `TELEGRAM_ALLOWED_CHAT_ID`.
- **Keine rohen Shell-/Datei-Builtins für die KI** — nur registrierte, validierende
  Werkzeuge (Lehre aus der Sandbox-Audit-Reihe von Pipe, Runde 11).
- **Sandbox-Profil `muninn`** (aktiviert in `muninn.pipe`): `exec` ist standardmäßig aus
  und wird nur eingeschaltet, wenn `MCP_SERVERS`/`MCP_AUTO_SERVERS` mindestens einen
  `stdio`-Server nennt — dann ausschließlich für dessen Kommandos (`exec_whitelist`).
  `docker` steht zusätzlich fest auf der Whitelist (für `docker_tools.pipe`, siehe MCP-
  Abschnitt → Eingeschränkte Docker-Erweiterung — dort auch die Argument-Injection-
  Absicherung per verankerter Regex vor jedem `exec()`-Aufruf). `audit_log` protokolliert
  alle sicherheitsrelevanten Ereignisse (HTTP, KI-Aufrufe, Tool-Calls); `max_tool_calls`
  begrenzt Tool-Ausführungen pro Gremium-Lauf gegen Endlosschleifen.
- **Das reine-Pipe-`sqlite`-Modul ist kein echtes SQLite** — sein Ausdrucks-Auswerter
  kennt nur `count`/`sum`/`avg`/`min`/`max` als SQL-Funktionen; andere (`lower()`,
  `trim()`, `datetime('now')`, ...) werden in `WHERE`-Klauseln und Ausdrücken
  **stillschweigend ignoriert** (geben ihr Argument unverändert zurück, statt einen
  Fehler zu werfen). Betraf u.a. die Dedup-Prüfung in `add_memory` (musste auf
  Pipe-seitige Normalisierung statt SQL umgestellt werden) und ist der Grund, warum
  `mem.cost_summary` bewusst in Pipe selbst aggregiert statt SQL `GROUP BY`/`MAX` zu
  vertrauen. Bei neuen `db_query`/`db_exec`-Aufrufen mit SQL-Funktionen: erst gegen eine
  Testdatenbank verifizieren, nicht blind vertrauen.
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
