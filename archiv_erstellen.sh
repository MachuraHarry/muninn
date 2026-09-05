#!/bin/bash
# archiv_erstellen.sh <format: zip|targz> <output_path> <relative_input_path...>
# Fixed pipeline for packing files/folders into a .zip or .tar.gz archive.
# Always operates relative to the mcp_data/ workspace root (cd below) so
# archive members get clean relative paths instead of a leaked absolute
# /root/muninn/mcp_data/... prefix. No AI-controllable flags -- 'format'
# is a strict 2-value enum validated here, everything else is just paths
# Pipe already validated against mcp_data/ (see resolve_mcp_data_path in
# swarm.pipe). Same security pattern as tts_synth.sh/html_to_pdf.sh.
set -euo pipefail
ROOT="/root/muninn/mcp_data"
FORMAT="$1"
OUTPUT="$2"
shift 2
cd "$ROOT"
case "$FORMAT" in
    zip)
        zip -r -q "$OUTPUT" "$@"
        ;;
    targz)
        tar -czf "$OUTPUT" "$@"
        ;;
    *)
        echo "archiv_erstellen: unknown format '$FORMAT' (use zip or targz)" >&2
        exit 1
        ;;
esac
