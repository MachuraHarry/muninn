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
- **PDFs lernen** — hochgeladene PDFs (z.B. Rechnungen, Verträge, Berichte) werden per
  lokalem `pdftotext` (kein API-Key) automatisch als Text ins Gedächtnis aufgenommen,
  nicht nur roh gespeichert.
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
  Pfad — keine KI-Bestätigung ohne tatsächliche Terminierung), tägliches Morgen-Briefing (jetzt mit
  echten Kalenderterminen angereichert), automatische Kalender-Erinnerungen (meldet sich von sich
  aus vor bevorstehenden Terminen), automatisches Fortsetzen unterbrochener Pläne,
  👍/👎-Feedback-Lernen.
- **Proaktiver Eigenimpuls** — täglicher Selbst-Check (12:00): Muninn schaut von sich aus ins
  Gedächtnis (offene Aufgaben, angefangene Arbeiten, wichtige Entwicklungen), meldet sich aber
  nur, wenn es wirklich etwas gibt — sonst bewusst Schweigen. Kann dabei selbst Termine fürs
  Wiederaufgreifen planen (`erinnerung_planen`/`hintergrund_fortsetzen`).
- **Selbstreflexion & Rezepte** — nach Aufgaben speichert der Registrator wiederverwendbare
  Lern-Erfahrungen („Was hat funktioniert, was nicht") als Erkenntnis und bewährte mehrschrittige
  Arbeitsabläufe als **Rezepte** (`rezept_speichern`/`rezepte_suchen`); der Planer schlägt
  Rezepte vor der Arbeit nach und zerlegt komplexe Aufgaben in Teilschritte.
- **Längerer Gesprächskontext** — der Gremium-Lauf sieht jetzt den doppelten
  Kurzzeit-Verlauf (12 statt 6 Nachrichten), Langzeitgedächtnis deckt den Rest ab.
- **Web-Recherche** — DuckDuckGo + Wikipedia, Seiten-Fetch und Zusammenfassung (kein API-Key nötig).
- **MCP-Tool-Ökosystem** — beliebige externe Werkzeuge (Dateisystem, Browser, Docker,
  Dokumentations-Lookup, Google Workspace, Präsentationen/Dokumente, ...) per Model Context
  Protocol anbinden; laufen unter einem Sandbox-Profil mit eng gefasster exec-Whitelist.
- **Live-Status-Stream** — während das Gremium arbeitet, editiert Muninn EINE Telegram-Nachricht
  laufend weiter (welcher Agent aktiv ist, welches Werkzeug er aufruft), statt neuer
  Nachrichtenblöcke oder Schweigens bis zur Endantwort.
- **Google Workspace** — Gmail (inkl. Versand), Drive und Kalender per OAuth 2.0 angebunden
  (`taylorwilsdon/google_workspace_mcp`), Tokens bewusst außerhalb des Filesystem-MCP-Bereichs.
- **Sprachnachrichten** — der Registrator entscheidet pro Antwort selbst, ob eine echte
  Telegram-Sprachnachricht (statt Text) passender ist; lokale Synthese per Piper + ffmpeg,
  kein Cloud-Dienst/API-Key.
- **Bildgenerierung** — erstellt auf Anfrage neue Bilder aus einer Textbeschreibung und
  schickt sie direkt per Telegram; Pollinations.ai's offene HTTP-API, kein API-Key/Account.
- **Hintergrund-Aufgaben** — das Gremium erkennt selbst, wenn eine Aufgabe (jede Art,
  nicht nur Docker) mehr Zeit braucht, stellt sie zurück und arbeitet automatisch mit
  frischem Rundenbudget weiter, bis sie wirklich fertig ist — kein Pipe-Hintergrundprozess,
  laeuft ueber den bestehenden Scheduler.
- **Sprachnachrichten verstehen** — transkribiert eingehende Telegram-Sprachnachrichten
  lokal (eigener `whisper`-Server auf `faster-whisper`, kein API-Key) und verarbeitet
  den Text genauso wie eine getippte Nachricht — Befehle, Erinnerungen und Gremium
  funktionieren identisch per Sprache.
- **Proaktive Kalender-Erinnerungen** — meldet sich von sich aus vor bevorstehenden
  Terminen, reichert das tägliche Briefing um echte Kalenderdaten an.
- **Präsentationen & Dokumente** — erstellt echte PowerPoint-/Word-Dateien (inkl.
  PDF-Export) und verschickt sie direkt als Telegram-Anhang.
- **Eingeschränkte Docker-Erweiterung** — Image ziehen + Container anlegen, aber strukturell
  ohne Volume-Mounts/`--privileged`, Ports standardmäßig nur auf `127.0.0.1` (siehe
  [Sicherheit](#sicherheit)).
- **Kosten-Tracking** — KI-Betriebskosten werden pro Session in der Seele protokolliert;
  `/costs` liefert eine KI-zusammengefasste (aber zahlenmäßig deterministisch berechnete)
  Übersicht, das Dashboard hat einen eigenen Kosten-Tab.
- **Telegram-Bot** — Long-Polling, Inline-Buttons, natives Befehlsmenü (`/`-Aufklapp-Menü über
  `setMyCommands`), Foto-Verständnis (`ai_vision`).
- **Einstellungen** — `/settings` als Inline-Menü: Antwortstil (knapp/normal/ausführlich),
  Sprache (Deutsch/Englisch), proaktive Nachrichten an/aus, Gedächtnis-Aggressivität
  (wie schnell Erinnerungen bei `/consolidate` altern/verblassen) — pro Chat gespeichert.
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
| Proaktive Kalender-Erinnerungen + Briefing-Anreicherung | ✅ |
| Präsentationen & Dokumente (PowerPoint/Word/PDF) erstellen + verschicken | ✅ |
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

## Produktionsbetrieb

Für einen dauerhaften Server-Betrieb (statt manuellem `nohup pipe muninn.pipe &`)
gibt es ein Install-Skript und einen systemd-Dienst unter `deploy/`.

### Installation (`deploy/install.sh`)

Richtet einen frischen Ubuntu-22.04-Server komplett ein: Go (Ubuntus eigenes
apt-Paket ist zu alt für `pipe`s `go.mod`), Node.js 20.x (für die npx-basierten
MCP-Server), Docker Engine, `uv`/`uvx` (für die Python-basierten MCP-Server:
Google Workspace, Präsentationen, Dokumente), Piper TTS + deutsche Stimme
(Sprachnachrichten), baut den `pipe`-Interpreter aus dem Quellcode und legt
eine leere `.env` aus der Vorlage an. **Idempotent** — jeder Schritt prüft
erst, ob er nötig ist; mehrfaches Ausführen (z.B. nach einem Update) ist
sicher.

```bash
sudo bash deploy/install.sh
```

Was danach noch **von Hand** passieren muss (kann kein Skript automatisieren):

1. `.env` ausfüllen — mindestens `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOWED_CHAT_ID`,
   `DEEPSEEK_API_KEY`. Optional weitere MCP-Server in `MCP_AUTO_SERVERS`
   aktivieren (siehe Kommentare in `.env.example`).
2. Für Google Workspace: eigenes OAuth-Setup in der Google Cloud Console +
   einmalige Browser-Freigabe (siehe [Google Workspace](#google-workspace-google_creds)).
3. `systemctl enable --now muninn`

### systemd-Dienst (`deploy/muninn.service`)

- **Automatischer Neustart** bei Absturz (`Restart=on-failure`), **Start nach
  Reboot** (`enable`).
- **Sauberes Stoppen**: der Pipe-Interpreter fängt SIGTERM/SIGINT selbst ab
  und schließt alle MCP-Subprozesse geordnet (siehe
  [MCP-Tool-Ökosystem](#mcp-tool-ökosystem-mcppipe)); zusätzlich räumt
  systemds eigenes cgroup-basiertes Kill-Verhalten beim Stoppen ohnehin ALLE
  Prozesse der Unit auf, auch Enkel-Prozesse, die der interpreterseitige
  Shutdown übersehen könnte (live verifiziert: ein per `kill -9` simulierter
  Absturz hinterließ keine Waisenprozesse und löste den automatischen
  Neustart korrekt aus).
- Logs über den systemd-Journal statt einer manuell verwalteten Datei:

```bash
systemctl status muninn
journalctl -u muninn -f
systemctl stop muninn      # sauber beenden
systemctl restart muninn   # z.B. nach .env-Aenderungen
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
| `/learn <URL>` | Dokument lernen (oder direkt eine `.txt`/`.md`-Datei oder PDF schicken) |
| `/settings` | Antwortstil, Sprache, proaktive Nachrichten und Gedächtnis-Aggressivität einstellen (Inline-Menü, siehe [Architektur → Einstellungen](#einstellungen-settings-memorypipe-muninnpipe)) |

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
(„🧭 Plane die Antwort...", „🔧 Nutze praesentation... → ruft save_presentation auf", …),
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

`/learn <URL>`, eine hochgeladene `.txt`/`.md`-Datei oder eine hochgeladene
PDF nehmen ein Dokument in die Wissensbasis auf:

- **`chunk_text`** zerlegt den Text rein/deterministisch in ≤1200-Zeichen-Stücke
  (bevorzugt an Absatzgrenzen).
- **`ingest_document`** speichert jeden Chunk als eigene Erinnerung (kind
  `document`, mit Embedding + Auto-Verknüpfung) und begrenzt die Anzahl über
  `max_chunks` (Kosten-/Zeit-Deckel).
- **PDFs** (`handle_document`/`extract_pdf_text`, `muninn.pipe`): Text wird per
  `pdftotext` (Poppler, systemweit installiert, kein API-Key/Cloud-Dienst) aus
  einer hochgeladenen PDF extrahiert und genau wie eine Textdatei gelernt —
  Pipe selbst bleibt dependency-frei, `pdftotext` läuft über `exec()` mit einer
  festen exec-Whitelist-Eintragung (siehe `setup_sandbox`), das Kommando wird
  komplett aus einem festen Template gebaut (nur der bereits lokal
  gespeicherte Dateipfad wird eingesetzt, `-q` unterdrückt Poppler-Warnungen,
  die sonst mitten im extrahierten Text landen würden). Reine Bild-Scans ohne
  Text-Layer, verschlüsselte oder beschädigte PDFs liefern ehrlich "kein Text
  extrahierbar" statt stillschweigend nichts zu tun. Nur der URL-Lernpfad
  (`/learn <URL>`) unterstützt PDFs (noch) nicht — der bräuchte einen
  eigenen, nicht-HTML-strippenden Fetch-Pfad.
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
  unangetastet. Die decay/forget-Tage (Standard 14/30) sind pro Chat über
  `/settings` → „Gedächtnis" einstellbar (siehe
  [Einstellungen](#einstellungen-settings-memorypipe-muninnpipe)) — der CLI-Cron-Modus
  ohne Chat-Kontext nutzt weiterhin fest 14/30.
- **Bug gefixt**: das externe, reine-Pipe-`sqlite`-Modul wertet `datetime('now')`
  nicht aus (speichert wörtlich `"now"`) — `mem.now_ts` baut Zeitstempel seither
  selbst aus Pipes `now`/`format_time`.

### Einstellungen (`/settings`, `memory.pipe`, `muninn.pipe`)

Pro Chat einstellbar über ein Telegram-Inline-Menü (`/settings` — Antippen
eines Buttons rotiert direkt zum nächsten Wert und baut dieselbe Nachricht
per `editMessageText` neu auf, kein wachsender Nachrichtenverlauf):

| Einstellung | Werte | Standard | Wirkung |
|---|---|---|---|
| Stil | knapp / normal / ausführlich | normal | Wird dem Gremiums-Task als `[SYSTEM]`-Hinweis vorangestellt |
| Sprache | Deutsch / English | Deutsch | dito — weist das Gremium an, komplett auf Englisch zu antworten |
| Proaktive Nachrichten | an / aus | an | steuert Eigenimpuls + proaktive Kalender-Erinnerungen (siehe unten) |
| Gedächtnis | locker / normal / streng | normal | decay/forget-Tage für `/consolidate` (locker: 30/60, normal: 14/30, streng: 7/14) |

Gespeichert werden die Werte **pro `chat_id`** über die bestehende
`meta`-Tabelle (eigener Schlüssel-Namensraum `settings:<chat_id>:<key>`,
`mem.setting_get`/`setting_set`) — keine neue Tabelle nötig, `meta` ist schon
für genau sowas da. Ein Chat ohne je gesetzte Werte läuft einfach mit den
Standardwerten weiter.

**Warum ein `[SYSTEM]`-Präfix statt eines eigenen Prompt-Bausteins pro
Agent?** `init_gremium` (siehe unten) baut alle Agenten-System-Prompts nur
**einmal** beim Start — zu diesem Zeitpunkt ist noch gar nicht bekannt, für
welchen Chat/welche Nachricht sie gleich gebraucht werden. Stil/Sprache
werden stattdessen dem `task`-String jedes einzelnen `run_gremium`/
`run_gremium_stream`-Aufrufs vorangestellt (`mem.settings_prompt_prefix`) —
nach demselben Muster wie der bestehende `[SYSTEM] Only N of M rounds
remain`-Hinweis (siehe Inneres Gremium unten). Bei Standardeinstellungen ist
der Präfix leer, kein Rauschen im Prompt.

Proaktive Nachrichten (Eigenimpuls, Kalender-Erinnerungen) prüfen
`mem.setting_proaktiv_enabled` direkt in `sched_tick`, bevor sie überhaupt
das Gremium anstoßen bzw. senden — der Scheduler-Eintrag selbst feuert
trotzdem normal weiter (kein separates Deaktivieren nötig, es passiert
einfach nichts). Das tägliche Briefing ist bewusst **nicht** betroffen: das
hat der Nutzer per `/briefing` schon explizit selbst aktiviert.

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
| `docker` | `mcp-docker-server` | bestehende Container/Images verwalten (kein Erstellen — siehe unten) |
| `zeit` | `time-mcp` | Uhrzeit/Zeitzonen-Umrechnung |
| `google` | `taylorwilsdon/google_workspace_mcp` | Gmail/Drive/Kalender — braucht eigenes OAuth-Setup, siehe unten |
| `praesentation` | `office-powerpoint-mcp-server` | PowerPoint-Präsentationen erstellen (.pptx) |
| `dokument` | `office-word-mcp-server` | Word-Dokumente erstellen, inkl. PDF-Export (.docx/.pdf) |
| `whisper` | eigenes Modul (`modules/whisper_server.py`) | Audio/Sprachnachrichten lokal transkribieren, kein API-Key |

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

### Proaktive Kalender-Erinnerungen (`muninn.pipe`)

Bisher nutzte kein proaktiver Mechanismus die Google-Kalender-Anbindung —
das tägliche Briefing baute sich rein aus Muninns eigener Seele auf (Erinnerungen,
Ziele, jüngste Ereignisse), ganz ohne externe Datenquelle. Jetzt:

- **Automatisch aktiv**, sobald der `google`-MCP-Server verbunden UND
  `TELEGRAM_ALLOWED_CHAT_ID` gesetzt ist (ohne feste Chat-ID gäbe es kein
  eindeutiges Ziel für eine unaufgeforderte Nachricht — kein Rateversuch).
  Registriert sich beim Start selbst idempotent im Scheduler (`kind:
  "calendar_check"`, neuer Wiederholungstyp `"15min"` in `scheduler.pipe`).
- Prüft alle 15 Minuten den **`primary`-Kalender** (bewusst nicht den
  öffentlichen Feiertagskalender oder weitere Kalender — vermeidet
  Fehlalarme) auf Termine innerhalb der nächsten `CALENDAR_REMINDER_MINUTES`
  (Standard 30, `.env`-konfigurierbar) und meldet neue per Telegram.
- **Dedup über echte Event-IDs**: `get_events` liefert nur formatierten Text
  (kein rohes JSON), aber mit einer echten Google-Event-ID pro Zeile — die
  wird als Schlüssel in `meta` (`mem.meta_set`/`meta_get`) gespeichert, damit
  derselbe Termin nicht bei jedem 15-Minuten-Takt erneut gemeldet wird
  (Einträge älter als 24h werden beim Schreiben automatisch aussortiert).
- Rein best-effort: jeder Fehler (Google nicht verbunden, Token abgelaufen —
  siehe [Google Workspace](#google-workspace-google_creds) zum
  7-Tage-Testing-Mode-Ablauf) lässt die Prüfung einfach ausfallen, ohne den
  Scheduler-Tick oder andere Nachrichten zu stören.
- Über `/settings` → „Proaktive Nachrichten" abschaltbar (siehe
  [Einstellungen](#einstellungen-settings-memorypipe-muninnpipe)) — der
  15-Minuten-Scheduler-Eintrag läuft dabei normal weiter, nur der eigentliche
  Versand entfällt.

### Präsentationen & Dokumente (`praesentation`/`dokument`)

Zwei zusätzliche MCP-Server erzeugen echte Office-Dateien, die Muninn direkt
per `datei_senden` verschickt — geprüft nach demselben Muster wie alle
anderen Server (Sterne, Aktivität, Wartungsstatus), live end-to-end
verifiziert (echte .pptx/.docx erstellt und über Telegram zugestellt):

- **`praesentation`** ([office-powerpoint-mcp-server](https://github.com/GongRzhe/Office-PowerPoint-MCP-Server),
  1.8k★, `python-pptx`) — 37 Werkzeuge, aber der Registrator-Spezialist
  bekommt eine gezielte Anleitung auf den einfachen, zuverlässigen Pfad
  (`create_presentation` → `add_slide` pro Folie → `save_presentation`):
  live beobachtet, dass die KI sich im umfangreichen Vorlagen-System
  (`create_presentation_from_templates`, `populate_placeholder`, ...) verlor
  und nie speicherte, bevor die Rundenzahl aufgebraucht war — mit der
  Anleitung lief es zuverlässig in 7-9 Runden durch.
- **`dokument`** ([office-word-mcp-server](https://github.com/GongRzhe/Office-Word-MCP-Server),
  2.1k★, `python-docx`, inkl. PDF-Export via `word_convert_to_pdf`) — 54
  Werkzeuge, dateiname-adressiert statt ID-basiert (jeder Aufruf schreibt
  sofort in die Datei, kein separater Speicher-Schritt).
- **Beide Pakete sind auf PyPI archiviert** (keine Updates mehr) — das
  PowerPoint-Paket lief unverändert von PyPI (mit `mcp<2`-Pin, da die
  neueste MCP-Python-SDK-Version `FastMCP` umbenannt hat), das Word-Paket
  hatte auf PyPI einen kaputten Packaging-Fehler (fehlendes Modul) und wird
  daher direkt aus dem GitHub-Repository installiert (`uvx --from
  git+https://github.com/...`).
- Erzeugte Dateien landen immer unter `mcp_data/` (Prompt-Vorgabe, kein
  technischer Zwang) — vom Filesystem-MCP-Server ohnehin schon freigegeben.

### Bildgenerierung (`swarm.pipe`, `bild_erstellen`)

Der Registrator erzeugt auf Anfrage ("erstelle/generiere/zeichne mir ein
Bild von...") ein neues Bild aus einer Textbeschreibung und verschickt es
sofort — Generieren und Senden bewusst in einem Werkzeugaufruf, damit die
KI das nicht als zwei separate Schritte falsch verketten kann.

- **Kein MCP-Server, kein API-Key** — der offizielle, per npm vertriebene
  Pollinations-MCP-Server (`@pollinations/mcp`) verlangt inzwischen einen
  Account/Key (live geprüft: `generateImage` schlägt ohne Key fehl), die
  darunterliegende klassische offene HTTP-API
  (`image.pollinations.ai/prompt/...`) aber weiterhin nicht — direkt per
  `http_request` angebunden statt über den MCP-Server.
- Anonyme Nutzung laut Pollinations-Doku: ~1 Anfrage/15s, evtl. kleines
  Wasserzeichen. Für einen persönlichen Bot ohne Massennutzung
  unproblematisch.
- `planer` leitet reine Bildanfragen (ohne Recherche/sonstige Aufgabe)
  direkt an `registrator` weiter (eigenes Handoff-Ziel) — ohne das sprang
  eine simple Anfrage live beobachtet 16 Runden zwischen den anderen
  Agenten hin und her, bevor sie zufällig beim richtigen Agenten landete.
- `http_request` statt `http_get` (30s statt 10s Timeout) — ein frischer,
  noch nie generierter Prompt braucht live beobachtet bis zu ~6s.

### Hintergrund-Aufgaben (`hintergrund_fortsetzen`, `docker_hintergrund_setup`)

Manche Aufgaben brauchen erkennbar mehr Zeit/Runden, als in einem einzigen
Gremiums-Lauf möglich ist (tiefe Recherche zu einem sehr breiten Thema,
eine Docker-Einrichtung mit Paketinstallation, ...). Statt entweder die
Antwort lange zu blockieren oder eine unvollständige Antwort zu erzwingen,
kann sich das Gremium selbst dafür entscheiden, die Aufgabe
zurückzustellen — Muninn antwortet sofort kurz ("ich arbeite weiter") und
meldet sich automatisch, sobald es fertig ist, über den bestehenden
Scheduler (kein Pipe-Hintergrundprozess, siehe Architekturhinweis unten).

- **Generisch (`hintergrund_fortsetzen`, nur Registrator)**: für JEDE Art
  von Aufgabe, nicht nur Docker. Legt einen Fortschritts-Checkpoint an
  (Zusammenfassung + was bisher erledigt ist / fehlt) und plant einen
  `task_check`-Scheduler-Tick (2 Minuten später) ein. Bei diesem Tick
  bekommt das Gremium ein FRISCHES Rundenbudget und arbeitet mit dem
  gespeicherten Fortschritt weiter — ist es dann fertig, antwortet es
  normal; ist es weiterhin nicht fertig, ruft es das Werkzeug erneut auf
  (beliebig oft verkettbar). Live end-to-end getestet: eine bewusst riesige
  Aufgabe ("vollständige Geschichte des Römischen Reiches, sehr
  ausführlich") wurde über zwei Fortsetzungsrunden hinweg korrekt
  weiterbearbeitet, mit jeweils ehrlichem, kurzem Zwischenstatus statt
  einer vorgetäuscht fertigen Antwort.
- **Spezifisch (`docker_hintergrund_setup`, nur Docker-Spezialist)**: für
  Docker-Setups, die länger dauern (z.B. Paketinstallation) — nutzt aus,
  dass `docker run -d` sofort zurückkehrt, sobald der Container gestartet
  ist, während die eigentliche Einrichtung beim Docker-Daemon
  weiterläuft (übersteht sogar einen `systemctl restart muninn`). Ein
  eigener `job_check`-Scheduler-Takt (5 Minuten) prüft GÜNSTIG per
  Container-Status nach, ohne dafür jedes Mal einen vollen
  Gremiums-Durchlauf zu brauchen — nur bei tatsächlichem Abschluss meldet
  sich Muninn.
- **Architekturentscheidung — kein Pipe-Hintergrundprozess**: ein
  `spawn`/`go`-Goroutine-Ansatz wurde geprüft und bewusst verworfen. Die
  Sandbox (`ActiveProfile`) ist ein einziger globaler Zeiger für den
  GESAMTEN Prozess — ein Hintergrund-Goroutine mit eigenem aktivem
  Sandbox-Profil würde sich mit dem `setup_sandbox`-Aufruf des nächsten,
  gleichzeitig verarbeiteten Nachrichten-Durchlaufs in die Quere kommen
  (Race). Die Scheduler-Tick-Lösung braucht keine Pipe-Nebenläufigkeit und
  passt zu Muninns bewusst single-threaded Design.
- **Interpreter-Falle beim Bauen entdeckt und dokumentiert**: das
  `sqlite`-Modul exportiert selbst eine Funktion `exec(handle, sql)`, die
  den globalen `exec()`-Builtin (Prozessausführung) STILLSCHWEIGEND
  überschreibt, sobald `import "sqlite"` (egal ob bare oder mit `as`) im
  selben Dateiscope wie ein `exec()`-Aufruf steht — `docker_tools.pipe`
  ruft `exec()` intensiv auf und importiert `sqlite` daher bewusst NICHT
  mehr selbst, sondern nutzt `mem.raw_exec`/`mem.raw_query` (dünne
  Durchreichen in `memory.pipe`, das `sqlite` bereits unproblematisch bare
  importiert).

### Proaktiver Eigenimpuls, Selbstreflexion & Rezepte

Drei zusammenhängende Ausbauten für mehr Autonomie („vom reinen
Tool-Bediener zum selbstorganisierenden Agenten"):

- **Proaktiver Eigenimpuls (`proaktiv`-Scheduler-Tick)**: einmal täglich
  (12:00, idempotent beim Start registriert) bekommt das Gremium einen
  Eigenimpuls, obwohl der Nutzer NICHT geschrieben hat. Es schaut per
  `erinnerungen_suchen` ins Gedächtnis (offene Aufgaben, angefangene
  Arbeiten, bald fällige Termine, wichtige Entwicklungen) und entscheidet
  selbst: Gibt es etwas Wichtiges, schreibt es eine kurze, konkrete
  Nachricht und kann sich per `erinnerung_planen`/`hintergrund_fortsetzen`
  gleich den nächsten Wiedervorlage-Termin setzen. Gibt es nichts, antwortet
  es AUSSCHLIESSLICH mit dem Wort „NICHTS" — und `sched_tick` sendet dann
  bewusst nichts (Schweigen ist ein vollwertiges Ergebnis, kein
  Leermeldungs-Spam). Über `/settings` → „Proaktive Nachrichten" ganz
  abschaltbar (siehe
  [Einstellungen](#einstellungen-settings-memorypipe-muninnpipe)).
- **Selbstreflexion**: der Registrator speichert nach einem Lauf — nur wenn
  es wirklich etwas Nennenswertes gab — eine wiederverwendbare
  Lern-Erfahrung („Was hat funktioniert, was nicht, warum") als knappe
  Erkenntnis mit dem bestehenden `merken`-Tool. Kein zusätzlicher KI-Call,
  keine Kosten.
- **Rezepte**: bewährte mehrschrittige Arbeitsabläufe werden als
  Erinnerungen vom Kind `rezept` gespeichert (`rezept_speichern`,
  Registrator) und vor der Arbeit nachgeschlagen (`rezepte_suchen`,
  Planer) — der Planer folgt bei komplexen Aufgaben erst dem Rezept, bevor
  er frei zerlegt. `mem.recipes` listet deterministisch die wichtigsten
  Rezepte (bewusst ohne Embedding-Suche: Rezepte sind selten und kurz).
- **Längerer Kontext**: `handle_message` übergibt dem Gremium jetzt die
  letzten 12 statt 6 Nachrichten des Threads — Langzeitgedächtnis
  (`retrieve_context`) deckt alles Ältere ab.

### Sprachnachrichten verstehen (`whisper`, `handle_voice`)

Schickt der Nutzer eine Telegram-Sprachnachricht, lädt Muninn die OGG/Opus-
Datei herunter, transkribiert sie lokal und reicht den erkannten Text
GENAUSO durch `handle_message` wie eine getippte Nachricht — Befehle,
Erinnerungen und das Gremium funktionieren also identisch per Sprache wie
per Text (das Gegenstück zu den bestehenden Sprachnachrichten, die Muninn
selbst verschicken kann).

- **Eigenes Modul `modules/whisper_server.py`** (fastmcp + `faster-whisper`) als
  FastMCP-Server — komplett lokal, kein API-Key. Der frühere `whisper-transcribe-mcp`
  (PyPI) fiel mit `faster-whisper>=1.2` aus: Er las intern
  `model_size_or_path`, das in `faster-whisper` 1.2 entfernt wurde, und brach genau
  ab dem **zweiten** Aufruf mit `'WhisperModel' object has no attribute
  'model_size_or_path'` — die erste Sprachnachricht klappte, jede weitere nicht.
  Das eigene Modul speichert die Modellgröße selbst und ist über beliebig viele
  Aufrufe stabil. Live end-to-end getestet: ein per Piper synthetisierter Satz
  wurde 1:1 korrekt zurücktranskribiert (deutsche Spracherkennung,
  `language_probability: 1.0`, Modell `base`).
- Modell lädt beim ersten Gebrauch automatisch von HuggingFace (~74 MB für
  `base`) und wird danach gecacht — kein manueller Download nötig.
- Ist der `whisper`-Server nicht konfiguriert (optionaler
  `MCP_AUTO_SERVERS`-Eintrag, siehe `.env.example`), fällt `handle_voice`
  ehrlich auf die Bitte zurück, stattdessen zu tippen — kein Vortäuschen
  einer nicht verfügbaren Fähigkeit.
- Da der Server ganz normal in `MCP_AUTO_SERVERS` steht, kann auch das
  Gremium selbst (`werkzeug_whisper`) bei Bedarf eine Audiodatei
  transkribieren, nicht nur der deterministische Sprachnachrichten-Pfad.

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
- **Security-Ehrlichkeits-Regel (`SECURITY_HONESTY_RULE`)**: Sicherheits- und
  Systembefunde (Kernel-Versionen, Sandbox-/Container-Eigenschaften, Exploits,
  Seccomp/UID-Mapping/Egress-Gates …) dürfen von der KI nur als Fakt ausgegeben
  werden, wenn sie in DIESEM Lauf selbst per Werkzeug geprüft wurden (mit konkreter
  Quelle); Gedächtnis-Audits werden als „aus früheren Audits, aktuell nicht erneut
  geprüft" zitiert, reines Modell-Vorwissen wird nie als Befund über das eigene
  System verkauft — nicht verifizierte Punkte werden explizit als „ungeprüft"
  markiert. Verhindert plausibel klingende, aber erfundene Security-Reports.
- **Verifizierter Systemstatus (Stand der letzten Prüfung)**: Host-Kernel 5.2.0 —
  sehr alt, zahlreiche bekannte CVEs (u.a. älter als jeder Dirty-Pipe-Fix);
  Docker-Daemon ohne User-Namespace-Remapping (`docker info` zeigt nur
  `seccomp=builtin`), Container laufen daher als UID 0 ≡ Host-Root. Beides liegt
  auf VPS-/Daemon-Ebene und ist nicht aus Muninn heraus änderbar — als
  Härtungs-Empfehlung: Kernel aktualisieren (Host-Provider) und `userns-remap`
  in `/etc/docker/daemon.json` aktivieren (Achtung: bricht bestehende
  Container-Namespaces, vorher Migration prüfen). Muninns eigene Schicht ist
  unabhängig davon eng: `exec` nur mit Whitelist (`docker`, `tts_synth.sh` +
  stdio-MCP-Kommandos), `audit_log` aktiv, `max_tool_calls` begrenzt.

---

## Roadmap

Der vollständige Ausbauplan (MCP-Tools, tiefes Gedächtnis, Omnichannel, Proaktivität,
Intelligenz-Upgrade, Ops) liegt in [Plan.md](Plan.md).

## Lizenz

Keine festgelegt (noch).
