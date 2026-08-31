#!/bin/bash
# tts_synth.sh <text_file> <ogg_file>
# Fixed pipeline (piper TTS -> WAV -> ffmpeg -> Opus/OGG for Telegram voice
# messages). No parameter here is AI-controllable beyond the two file paths
# Pipe passes in — voice model and encoding are hardcoded, matching the
# docker_tools.pipe pattern (fixed command template, no free-form flags).
set -euo pipefail
TEXT_FILE="$1"
OGG_FILE="$2"
WAV_FILE="$(mktemp --suffix=.wav)"
trap 'rm -f "$WAV_FILE"' EXIT

/opt/piper/piper/piper -m /opt/piper/voices/de_DE-thorsten-high.onnx -f "$WAV_FILE" < "$TEXT_FILE"
ffmpeg -y -loglevel error -i "$WAV_FILE" -c:a libopus -b:a 32k "$OGG_FILE"
