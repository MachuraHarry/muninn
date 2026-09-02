#!/bin/bash
# install.sh — sets up Muninn on a fresh Ubuntu 22.04 server (system
# dependencies, the Pipe interpreter, Muninn itself, the systemd service)
# and creates an empty .env from the template. Idempotent: every step
# checks first whether it's needed before installing anything — running it
# multiple times is safe (e.g. after an update).
#
# Usage: run as root, e.g. `bash deploy/install.sh`.
#
# Covers ONLY the installation. What still needs to be done by hand
# afterward (Telegram bot token, DeepSeek key, Google OAuth setup + one-time
# consent grant) is listed as a checklist at the end — that can't be
# automated by a script, see README.md.
set -euo pipefail

MUNINN_DIR="/root/muninn"
PIPE_DIR="/root/pipe"
GO_VERSION="1.25.0"
PIPER_RELEASE="2023.11.14-2"

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root (e.g. with sudo)." >&2
    exit 1
fi

log() { echo -e "\n\033[1;34m==> $1\033[0m"; }

log "System packages (git, curl, ffmpeg, ca-certificates, make, poppler-utils)"
apt-get update -qq
apt-get install -y -qq git curl ffmpeg ca-certificates make poppler-utils >/dev/null

log "Go ${GO_VERSION}+ (Ubuntu's apt package is too old for pipe's go.mod)"
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
    echo "Go ${GO_VERSION} already installed, skipping."
fi
export PATH="/usr/local/go/bin:$PATH"

log "Node.js 20.x (for the npx-based MCP servers)"
if ! command -v node >/dev/null 2>&1 || [ "$(node --version | cut -d. -f1)" != "v20" ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null
    apt-get install -y -qq nodejs >/dev/null
else
    echo "Node.js $(node --version) already installed, skipping."
fi

log "Docker Engine (for the restricted Docker extension + mcp-docker-server)"
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sh >/dev/null
else
    echo "Docker $(docker --version) already installed, skipping."
fi

log "uv/uvx (for the Python-based MCP servers: Google Workspace, PowerPoint, Word)"
if [ ! -x "$HOME/.local/bin/uvx" ]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null
else
    echo "uv/uvx already installed, skipping."
fi
export PATH="$HOME/.local/bin:$PATH"

log "Piper TTS + German voice (for voice messages, see tts_synth.sh)"
mkdir -p /opt/piper/voices
if [ ! -x /opt/piper/piper/piper ]; then
    tmp_tar="$(mktemp --suffix=.tar.gz)"
    curl -LsSf -o "$tmp_tar" "https://github.com/rhasspy/piper/releases/download/${PIPER_RELEASE}/piper_linux_x86_64.tar.gz"
    tar -C /opt/piper -xzf "$tmp_tar"
    rm "$tmp_tar"
else
    echo "Piper binary already present, skipping."
fi
if [ ! -f /opt/piper/voices/de_DE-thorsten-high.onnx ]; then
    curl -LsSf -o /opt/piper/voices/de_DE-thorsten-high.onnx \
        "https://huggingface.co/rhasspy/piper-voices/resolve/main/de/de_DE/thorsten/high/de_DE-thorsten-high.onnx"
    curl -LsSf -o /opt/piper/voices/de_DE-thorsten-high.onnx.json \
        "https://huggingface.co/rhasspy/piper-voices/resolve/main/de/de_DE/thorsten/high/de_DE-thorsten-high.onnx.json"
else
    echo "Voice model already present, skipping."
fi

log "Build the Pipe interpreter (${PIPE_DIR})"
if [ ! -d "$PIPE_DIR" ]; then
    git clone https://github.com/MachuraHarry/pipe "$PIPE_DIR"
fi
(cd "$PIPE_DIR" && PATH="/usr/local/go/bin:$PATH" make build)
cp "$PIPE_DIR/bin/pipe" /usr/local/bin/pipe.new
mv /usr/local/bin/pipe.new /usr/local/bin/pipe

log "Muninn itself (${MUNINN_DIR})"
if [ ! -d "$MUNINN_DIR" ]; then
    git clone https://github.com/MachuraHarry/muninn "$MUNINN_DIR"
fi
mkdir -p "$MUNINN_DIR/mcp_data" "$MUNINN_DIR/google_creds" "$MUNINN_DIR/tts_tmp"
chmod 700 "$MUNINN_DIR/google_creds"
chmod +x "$MUNINN_DIR/tts_synth.sh"
if [ ! -f "$MUNINN_DIR/.env" ]; then
    cp "$MUNINN_DIR/.env.example" "$MUNINN_DIR/.env"
    echo "→ .env created from .env.example — still needs to be filled in (see checklist below)."
else
    echo ".env already exists, not overwriting."
fi

log "Set up the systemd service"
cp "$MUNINN_DIR/deploy/muninn.service" /etc/systemd/system/muninn.service
systemctl daemon-reload
echo "Service installed (not started yet — see checklist below)."

cat <<'EOF'

════════════════════════════════════════════════════════════════
 Installation complete. Before the first start, by hand:
════════════════════════════════════════════════════════════════

1. Fill in /root/muninn/.env (required):
   - TELEGRAM_BOT_TOKEN       from @BotFather (/newbot)
   - TELEGRAM_ALLOWED_CHAT_ID from @userinfobot (empty = anyone
                              allowed, not recommended — also
                              required for proactive calendar
                              reminders)
   - DEEPSEEK_API_KEY         platform.deepseek.com

2. Optional, depending on the capabilities you want (see the
   comments in .env.example for the exact JSON format):
   - Extend MCP_AUTO_SERVERS (filesystem/browser/weather/Docker/
     Google Workspace/presentations/documents, ...)
   - For Google Workspace (Gmail/Drive/Calendar): your own OAuth
     setup in the Google Cloud Console + a one-time browser
     consent is needed — see README.md → "Google Workspace"
     (cannot be automated).
   - DASHBOARD_BIND/DASHBOARD_TOKEN for the web dashboard.

3. Once .env is complete:
     systemctl enable --now muninn
     journalctl -u muninn -f      # follow logs live

To test manually without systemd:
     cd /root/muninn && pipe muninn.pipe
════════════════════════════════════════════════════════════════
EOF
