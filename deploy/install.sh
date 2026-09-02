#!/bin/bash
# install.sh — sets up Muninn on a fresh Ubuntu 22.04 server (system
# dependencies, the Pipe interpreter, Muninn itself, the systemd service)
# and, on first install, walks through an interactive setup wizard that
# writes a fully filled-in .env at the end. Idempotent: every step checks
# first whether it's needed before installing anything — running it
# multiple times is safe (e.g. after an update), and an existing .env is
# never touched or overwritten.
#
# Usage: run as root, in an interactive shell, e.g. `bash deploy/install.sh`.
#
# The wizard covers Telegram/DeepSeek credentials and the MCP tools that
# work out of the box with no extra setup. What it deliberately does NOT
# cover — Google Workspace (needs its own OAuth app in the Google Cloud
# Console + a one-time browser consent) — is listed as a follow-up
# checklist at the end instead; see README.md → "Google Workspace".
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

# Prompts "$1 [Y/n]" (default="y") or "$1 [y/N]" (default="n") and prints
# "y" or "n" to stdout — call as `answer=$(ask_yn "..." y)`. Reads from the
# controlling terminal explicitly (not stdin) so it still works correctly
# inside the `run_env_wizard` call even though this script's own stdin may
# already be consumed/redirected by the time it runs.
ask_yn() {
    local prompt="$1" default="$2" ans suffix
    if [ "$default" = "n" ]; then suffix="[y/N]"; else suffix="[Y/n]"; fi
    read -r -p "$prompt $suffix: " ans </dev/tty
    ans="${ans:-$default}"
    case "$ans" in
        y|Y|yes|Yes|j|J|ja|Ja) echo "y" ;;
        *) echo "n" ;;
    esac
}

# Interactive .env setup: asks for the required credentials plus a handful
# of yes/no toggles for the MCP tools that need no extra external setup
# (Google Workspace is deliberately excluded — it needs its own OAuth app,
# see the checklist printed at the end instead), then writes a ready-to-run
# .env. Falls back to the old "copy .env.example, fill in by hand" behavior
# when stdin isn't a real terminal (e.g. this script piped in via curl, or
# run non-interactively in CI) — a wizard has nothing to read from there.
run_env_wizard() {
    local env_file="$1" example_file="$2"

    # `[ -e /dev/tty ]` alone isn't enough: the device NODE exists even with
    # no controlling terminal at all (e.g. `curl ... | bash`, a cron job, or
    # this script run detached) — reads from it then fail at runtime
    # ("No such device or address"), reproduced live, right in the middle of
    # the wizard. Actually attempting to open it for reading (and discarding
    # any error) is the only reliable way to tell whether it's really usable.
    if ! { true < /dev/tty; } 2>/dev/null; then
        cp "$example_file" "$env_file"
        echo "→ Not running interactively (no terminal available) — .env created from"
        echo "  .env.example instead. Fill it in by hand (see checklist below), or re-run"
        echo "  this script in an interactive shell for the guided setup."
        ENV_WIZARD_RAN=0
        return
    fi

    echo
    echo "════════════════════════════════════════════════════════════════"
    echo " Muninn setup — a few questions, then .env gets written for you."
    echo " Press Enter to accept a [default] where one is shown."
    echo "════════════════════════════════════════════════════════════════"

    echo
    echo "--- Required ---"
    local telegram_token="" telegram_chat_id="" deepseek_key=""
    while [ -z "$telegram_token" ]; do
        read -r -p "Telegram bot token (from @BotFather, /newbot): " telegram_token </dev/tty
    done
    while [ -z "$telegram_chat_id" ]; do
        read -r -p "Your Telegram chat ID (from @userinfobot): " telegram_chat_id </dev/tty
    done
    while [ -z "$deepseek_key" ]; do
        read -r -p "DeepSeek API key (platform.deepseek.com): " deepseek_key </dev/tty
    done

    echo
    echo "--- Optional capabilities (MCP tools, no extra setup needed) ---"
    local want_filesystem want_memory want_thinking want_browser want_docker want_whisper want_ppt want_word
    want_filesystem=$(ask_yn "  Filesystem access (read/write files in mcp_data/)" y)
    want_memory=$(ask_yn "  Persistent memory / knowledge graph tools" y)
    want_thinking=$(ask_yn "  Sequential thinking (better structured reasoning on complex requests)" y)
    want_browser=$(ask_yn "  Browser automation (Playwright — navigate sites, screenshots)" y)
    want_docker=$(ask_yn "  Docker container management" y)
    want_whisper=$(ask_yn "  Voice message transcription (local Whisper, no API key)" y)
    want_ppt=$(ask_yn "  PowerPoint presentation creation" y)
    want_word=$(ask_yn "  Word document creation (incl. PDF export)" y)

    echo
    echo "--- Web dashboard ---"
    local want_dashboard dashboard_bind="127.0.0.1:8787" dashboard_token=""
    want_dashboard=$(ask_yn "  Enable the web dashboard (chat/memories/goals in a browser)" n)
    if [ "$want_dashboard" = "y" ]; then
        local bind_in=""
        read -r -p "    Bind address [127.0.0.1:8787]: " bind_in </dev/tty
        dashboard_bind="${bind_in:-127.0.0.1:8787}"
        local want_token
        want_token=$(ask_yn "    Protect it with a random access token (?token=...)" y)
        if [ "$want_token" = "y" ]; then
            dashboard_token="$(head -c 24 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 24)"
        fi
    fi

    echo
    echo "--- Schedule ---"
    local tz_offset_in="" briefing_time_in=""
    read -r -p "  Timezone offset from UTC in seconds, e.g. 7200 for UTC+2 [0]: " tz_offset_in </dev/tty
    read -r -p "  Daily briefing time, HH:MM [08:00]: " briefing_time_in </dev/tty
    local tz_offset="${tz_offset_in:-0}" briefing_time="${briefing_time_in:-08:00}"

    # Build the MCP_AUTO_SERVERS JSON array from the selected toggles — each
    # snippet matches the one documented in .env.example / already proven
    # working in production, minus one deliberate simplification: the
    # browser entry drops --executable-path (which pointed at a specific
    # pre-cached Chrome build on the original dev machine, not something a
    # fresh install has) so Playwright manages its own browser download
    # instead — slower on first connect, but portable to any machine.
    local servers=()
    [ "$want_filesystem" = "y" ] && servers+=("{\"alias\":\"filesystem\",\"type\":\"stdio\",\"command\":\"npx\",\"args\":[\"-y\",\"@modelcontextprotocol/server-filesystem\",\"$MUNINN_DIR/mcp_data\"],\"keywords\":[\"datei\",\"dateien\",\"filesystem\",\"ordner\"]}")
    [ "$want_memory" = "y" ] && servers+=('{"alias":"memory","type":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-memory"],"keywords":["wissen","wissensgraph","entitaet","beziehung"]}')
    [ "$want_thinking" = "y" ] && servers+=('{"alias":"denkwerkzeug","type":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-sequential-thinking"],"keywords":["komplex","plane","durchdenke","analysiere","strategie","abwaegen"]}')
    [ "$want_browser" = "y" ] && servers+=('{"alias":"browser","type":"stdio","command":"npx","args":["-y","@playwright/mcp@latest","--headless","--no-sandbox"],"keywords":["browser","webseite","website","navigiere","screenshot","klick","formular","internetseite","oeffne die seite"]}')
    [ "$want_docker" = "y" ] && servers+=('{"alias":"docker","type":"stdio","command":"npx","args":["-y","mcp-docker-server"],"keywords":["docker","container","image","dienst","service","deployment"]}')
    [ "$want_whisper" = "y" ] && servers+=("{\"alias\":\"whisper\",\"type\":\"stdio\",\"command\":\"$HOME/.local/bin/uv\",\"args\":[\"run\",\"--with\",\"fastmcp\",\"--with\",\"faster-whisper\",\"python\",\"$MUNINN_DIR/modules/whisper_server.py\"],\"env\":{\"WHISPER_MODEL\":\"base\"},\"keywords\":[\"transkribiere\",\"transkription\",\"audio\",\"sprachnachricht verstehen\",\"sprache zu text\",\"speech to text\"]}")
    [ "$want_ppt" = "y" ] && servers+=("{\"alias\":\"praesentation\",\"type\":\"stdio\",\"command\":\"$HOME/.local/bin/uvx\",\"args\":[\"--from\",\"office-powerpoint-mcp-server\",\"--with\",\"mcp<2\",\"ppt_mcp_server\"],\"keywords\":[\"praesentation\",\"powerpoint\",\"pptx\",\"folie\",\"folien\",\"slides\"]}")
    [ "$want_word" = "y" ] && servers+=("{\"alias\":\"dokument\",\"type\":\"stdio\",\"command\":\"$HOME/.local/bin/uvx\",\"args\":[\"--from\",\"git+https://github.com/GongRzhe/Office-Word-MCP-Server\",\"--with\",\"mcp<2\",\"word_mcp_server\"],\"keywords\":[\"word\",\"docx\",\"dokument schreiben\",\"bericht\",\"pdf erstellen\"]}")

    local mcp_auto_servers=""
    if [ ${#servers[@]} -gt 0 ]; then
        local joined
        joined="$(IFS=,; echo "${servers[*]}")"
        mcp_auto_servers="[$joined]"
    fi

    cat > "$env_file" <<ENVEOF
# Muninn — written by deploy/install.sh's interactive setup on $(date -u +%Y-%m-%dT%H:%M:%SZ)
# Edit freely — this file is gitignored. See .env.example for the full
# reference (every available option, commented) — e.g. to add Google
# Workspace (Gmail/Drive/Calendar) later, which needs its own OAuth setup
# and isn't covered by the wizard, see README.md → "Google Workspace".
TELEGRAM_BOT_TOKEN=$telegram_token
TELEGRAM_ALLOWED_CHAT_ID=$telegram_chat_id
MUNINN_PROVIDER=deepseek
DEEPSEEK_API_KEY=$deepseek_key

MCP_SERVERS=
MCP_AUTO_SERVERS=$mcp_auto_servers

CALENDAR_REMINDER_MINUTES=30

DASHBOARD_BIND=$dashboard_bind
DASHBOARD_TOKEN=$dashboard_token

BRIEFING_TIME=$briefing_time
MUNINN_TZ_OFFSET=$tz_offset
ENVEOF

    echo
    echo "→ .env written to $env_file."
    if [ "$want_dashboard" = "y" ]; then
        if [ -n "$dashboard_token" ]; then
            echo "  Dashboard (once running): http://$dashboard_bind/?token=$dashboard_token"
        else
            echo "  Dashboard (once running): http://$dashboard_bind/"
        fi
    fi
    ENV_WIZARD_RAN=1
}

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
# The package installing successfully doesn't mean the daemon is actually
# running (e.g. restricted/nested virtualization on some budget VPS
# providers can leave the systemd unit failed to start) — check explicitly
# instead of silently completing while Muninn's Docker features would be
# broken.
if docker info >/dev/null 2>&1; then
    echo "Docker daemon is up and responding."
else
    echo "WARNING: Docker is installed but the daemon isn't responding (checked 'docker info')." >&2
    echo "         Muninn's Docker features (docker_tools.pipe, mcp-docker-server) won't work" >&2
    echo "         until this is fixed. Check: systemctl status docker" >&2
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

ENV_WIZARD_RAN=0
if [ ! -f "$MUNINN_DIR/.env" ]; then
    run_env_wizard "$MUNINN_DIR/.env" "$MUNINN_DIR/.env.example"
else
    echo ".env already exists, not overwriting."
fi

log "Set up the systemd service"
cp "$MUNINN_DIR/deploy/muninn.service" /etc/systemd/system/muninn.service
systemctl daemon-reload
echo "Service installed (not started yet — see checklist below)."

if [ "$ENV_WIZARD_RAN" = "1" ]; then
cat <<EOF

════════════════════════════════════════════════════════════════
 Installation complete. .env is fully filled in — ready to start:
════════════════════════════════════════════════════════════════

  systemctl enable --now muninn
  journalctl -u muninn -f      # follow logs live

Optional, not covered by the setup wizard:
  - Google Workspace (Gmail/Drive/Calendar) needs its own OAuth app in
    the Google Cloud Console + a one-time browser consent — see
    README.md → "Google Workspace", then add the entry to
    MCP_AUTO_SERVERS in $MUNINN_DIR/.env by hand.
  - Anything else in .env.example not asked about above (e.g. GitHub
    repo access) can be added to MCP_AUTO_SERVERS the same way.

To test manually without systemd:
     cd $MUNINN_DIR && pipe muninn.pipe
════════════════════════════════════════════════════════════════
EOF
else
cat <<EOF

════════════════════════════════════════════════════════════════
 Installation complete. Before the first start, by hand:
════════════════════════════════════════════════════════════════

1. Fill in $MUNINN_DIR/.env (required):
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
     cd $MUNINN_DIR && pipe muninn.pipe
════════════════════════════════════════════════════════════════
EOF
fi
