#!/bin/bash
# tts_synth_dialog.sh <manifest_file> <ogg_file>
# Two-voice dialogue pipeline (Huginn & Muninn audio overview): piper TTS
# per speaker turn -> normalized WAV (voices have DIFFERENT native sample
# rates, 22050 vs 16000 -- must be resampled to a common rate before they
# can be concatenated) -> short silence between turns -> concat -> ffmpeg
# -> Opus/OGG. Same security pattern as tts_synth.sh: no AI-controllable
# flags, only file paths are passed in; voice models, encoding and the
# silence gap are hardcoded, and the speaker tag is validated against a
# fixed 2-value enum below.
#
# manifest_file format: one line per turn, "speaker|text_file_path", e.g.:
#   muninn|/root/muninn/tts_tmp/abc_0.txt
#   huginn|/root/muninn/tts_tmp/abc_1.txt
set -euo pipefail
MANIFEST="$1"
OGG_FILE="$2"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

RATE=22050
SILENCE="$TMPDIR/silence.wav"
ffmpeg -nostdin -y -loglevel error -f lavfi -i "anullsrc=r=$RATE:cl=mono" -t 0.5 -ar "$RATE" -ac 1 "$SILENCE" < /dev/null

CONCAT_LIST="$TMPDIR/concat.txt"
: > "$CONCAT_LIST"

i=0
first=1
while IFS='|' read -r voice textfile; do
    [ -z "$voice" ] && continue
    case "$voice" in
        muninn) MODEL="/opt/piper/voices/de_DE-thorsten-high.onnx" ;;
        huginn) MODEL="/opt/piper/voices/de_DE-kerstin-low.onnx" ;;
        *) echo "tts_synth_dialog: unknown voice '$voice'" >&2; exit 1 ;;
    esac
    RAW="$TMPDIR/raw_$i.wav"
    NORM="$TMPDIR/seg_$i.wav"
    /opt/piper/piper/piper -m "$MODEL" -f "$RAW" < "$textfile"
    ffmpeg -nostdin -y -loglevel error -i "$RAW" -ar "$RATE" -ac 1 "$NORM" < /dev/null
    if [ "$first" -eq 0 ]; then
        echo "file '$SILENCE'" >> "$CONCAT_LIST"
    fi
    echo "file '$NORM'" >> "$CONCAT_LIST"
    first=0
    i=$((i+1))
done < "$MANIFEST"

ffmpeg -nostdin -y -loglevel error -f concat -safe 0 -i "$CONCAT_LIST" -c:a libopus -b:a 32k "$OGG_FILE" < /dev/null
