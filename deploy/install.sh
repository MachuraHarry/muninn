#!/bin/bash
# install.sh — richtet Muninn auf einem frischen Ubuntu-22.04-Server ein
# (System-Abhaengigkeiten, den Pipe-Interpreter, Muninn selbst, den
# systemd-Dienst) und legt eine leere .env aus der Vorlage an. Idempotent:
# jeder Schritt prueft erst, ob er noetig ist, bevor er etwas installiert —
# mehrfaches Ausfuehren ist sicher (z.B. nach einem Update).
#
# Nutzung: als root ausfuehren, z.B. `bash deploy/install.sh`.
#
# Deckt NUR die Installation ab. Was danach noch von Hand passieren muss
# (Telegram-Bot-Token, DeepSeek-Key, Google-OAuth-Einrichtung + einmalige
# Consent-Freigabe) steht am Ende als Checkliste — das kann kein Skript
# automatisieren, siehe README.md.
set -euo pipefail

MUNINN_DIR="/root/muninn"
PIPE_DIR="/root/pipe"
GO_VERSION="1.25.0"
PIPER_RELEASE="2023.11.14-2"

if [ "$(id -u)" -ne 0 ]; then
    echo "Bitte als root ausfuehren (z.B. mit sudo)." >&2
    exit 1
fi

log() { echo -e "\n\033[1;34m==> $1\033[0m"; }

log "System-Pakete (git, curl, ffmpeg, ca-certificates)"
apt-get update -qq
apt-get install -y -qq git curl ffmpeg ca-certificates >/dev/null

log "Go ${GO_VERSION}+ (Ubuntus apt-Paket ist zu alt fuer pipes go.mod)"
current_go=""
if [ -x /usr/local/go/bin/go ]; then
    current_go="$(/usr/local/go/bin/go version | awk '{print $3}' | sed 's/go//')"
fi
if [ "$current_go" != "$GO_VERSION" ]; then
    tmp_tar="$(mktemp --suffix=.tar.gz)"
    curl -LsSf -o "$tmp_tar" "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "$tmp_tar"
    rm "$tmp_tar"
else
    echo "Go ${GO_VERSION} bereits installiert, ueberspringe."
fi
export PATH="/usr/local/go/bin:$PATH"

log "Node.js 20.x (fuer die npx-basierten MCP-Server)"
if ! command -v node >/dev/null 2>&1 || [ "$(node --version | cut -d. -f1)" != "v20" ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null
    apt-get install -y -qq nodejs >/dev/null
else
    echo "Node.js $(node --version) bereits installiert, ueberspringe."
fi

log "Docker Engine (fuer die eingeschraenkte Docker-Erweiterung + mcp-docker-server)"
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sh >/dev/null
else
    echo "Docker $(docker --version) bereits installiert, ueberspringe."
fi

log "uv/uvx (fuer die Python-basierten MCP-Server: Google Workspace, PowerPoint, Word)"
if [ ! -x "$HOME/.local/bin/uvx" ]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null
else
    echo "uv/uvx bereits installiert, ueberspringe."
fi
export PATH="$HOME/.local/bin:$PATH"

log "Piper TTS + deutsche Stimme (fuer Sprachnachrichten, siehe tts_synth.sh)"
mkdir -p /opt/piper/voices
if [ ! -x /opt/piper/piper/piper ]; then
    tmp_tar="$(mktemp --suffix=.tar.gz)"
    curl -LsSf -o "$tmp_tar" "https://github.com/rhasspy/piper/releases/download/${PIPER_RELEASE}/piper_linux_x86_64.tar.gz"
    tar -C /opt/piper -xzf "$tmp_tar"
    rm "$tmp_tar"
else
    echo "Piper-Binary bereits vorhanden, ueberspringe."
fi
if [ ! -f /opt/piper/voices/de_DE-thorsten-high.onnx ]; then
    curl -LsSf -o /opt/piper/voices/de_DE-thorsten-high.onnx \
        "https://huggingface.co/rhasspy/piper-voices/resolve/main/de/de_DE/thorsten/high/de_DE-thorsten-high.onnx"
    curl -LsSf -o /opt/piper/voices/de_DE-thorsten-high.onnx.json \
        "https://huggingface.co/rhasspy/piper-voices/resolve/main/de/de_DE/thorsten/high/de_DE-thorsten-high.onnx.json"
else
    echo "Stimmmodell bereits vorhanden, ueberspringe."
fi

log "Pipe-Interpreter bauen (${PIPE_DIR})"
if [ ! -d "$PIPE_DIR" ]; then
    git clone https://github.com/MachuraHarry/pipe "$PIPE_DIR"
fi
(cd "$PIPE_DIR" && PATH="/usr/local/go/bin:$PATH" make build)
cp "$PIPE_DIR/bin/pipe" /usr/local/bin/pipe.new
mv /usr/local/bin/pipe.new /usr/local/bin/pipe

log "Muninn selbst (${MUNINN_DIR})"
if [ ! -d "$MUNINN_DIR" ]; then
    git clone https://github.com/MachuraHarry/muninn "$MUNINN_DIR"
fi
mkdir -p "$MUNINN_DIR/mcp_data" "$MUNINN_DIR/google_creds" "$MUNINN_DIR/tts_tmp"
chmod 700 "$MUNINN_DIR/google_creds"
chmod +x "$MUNINN_DIR/tts_synth.sh"
if [ ! -f "$MUNINN_DIR/.env" ]; then
    cp "$MUNINN_DIR/.env.example" "$MUNINN_DIR/.env"
    echo "→ .env aus .env.example angelegt — muss noch ausgefuellt werden (siehe Checkliste unten)."
else
    echo ".env existiert bereits, wird nicht ueberschrieben."
fi

log "systemd-Dienst einrichten"
cp "$MUNINN_DIR/deploy/muninn.service" /etc/systemd/system/muninn.service
systemctl daemon-reload
echo "Dienst installiert (noch nicht gestartet — siehe Checkliste unten)."

cat <<'EOF'

════════════════════════════════════════════════════════════════
 Installation fertig. Vor dem ersten Start noch von Hand:
════════════════════════════════════════════════════════════════

1. /root/muninn/.env ausfuellen (Pflicht):
   - TELEGRAM_BOT_TOKEN       von @BotFather (/newbot)
   - TELEGRAM_ALLOWED_CHAT_ID von @userinfobot (leer = jeder darf,
                              nicht empfohlen — auch Voraussetzung
                              fuer proaktive Kalender-Erinnerungen)
   - DEEPSEEK_API_KEY         platform.deepseek.com

2. Optional, je nach gewuenschten Faehigkeiten (siehe Kommentare
   in .env.example fuer das genaue JSON-Format):
   - MCP_AUTO_SERVERS erweitern (Dateisystem/Browser/Wetter/Docker/
     Google Workspace/Praesentationen/Dokumente, ...)
   - Fuer Google Workspace (Gmail/Drive/Kalender): eigenes
     OAuth-Setup in der Google Cloud Console + einmalige
     Browser-Freigabe noetig — siehe README.md → "Google Workspace"
     (kann NICHT automatisiert werden).
   - DASHBOARD_BIND/DASHBOARD_TOKEN fuer das Web-Dashboard.

3. Wenn .env vollstaendig ist:
     systemctl enable --now muninn
     journalctl -u muninn -f      # Logs live verfolgen

Ohne systemd manuell testen:
     cd /root/muninn && pipe muninn.pipe
════════════════════════════════════════════════════════════════
EOF
