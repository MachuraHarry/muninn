#!/bin/bash
# html_to_pdf.sh <html_file> <pdf_file>
# Fixed pipeline (wkhtmltopdf) for converting Muninn-generated HTML (from
# plain text or already-authored HTML, see build_pdf_html in swarm.pipe)
# into a PDF. No parameter here is AI-controllable beyond the two file
# paths Pipe passes in -- page size/margins/fonts are baked into the HTML
# itself, not passed as flags. Same fixed-command-template pattern as
# tts_synth.sh/docker_tools.pipe: never AI-controllable flags.
set -euo pipefail
HTML_FILE="$1"
PDF_FILE="$2"
wkhtmltopdf --quiet --encoding utf-8 "$HTML_FILE" "$PDF_FILE"
