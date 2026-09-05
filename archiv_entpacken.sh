#!/bin/bash
# archiv_entpacken.sh <archive_path> <dest_dir>
# Fixed pipeline for extracting a .zip/.tar.gz/.tgz/.tar archive (format
# auto-detected by extension) into dest_dir. No AI-controllable flags.
# Defense in depth against "zip-slip" (archive entries with ".."/absolute
# paths trying to write outside dest_dir), on top of the underlying
# tools' own protections: the archive listing is scanned first and
# extraction is refused outright if any entry looks unsafe.
set -euo pipefail
ARCHIVE="$1"
DEST="$2"
mkdir -p "$DEST"

UNSAFE_RE='(^/|(^|/)\.\.(/|$))'

case "$ARCHIVE" in
    *.zip)
        if unzip -Z1 "$ARCHIVE" | grep -qE "$UNSAFE_RE"; then
            echo "archiv_entpacken: refused - archive contains unsafe path entries" >&2
            exit 1
        fi
        unzip -q -o "$ARCHIVE" -d "$DEST"
        ;;
    *.tar.gz|*.tgz)
        if tar -tzf "$ARCHIVE" | grep -qE "$UNSAFE_RE"; then
            echo "archiv_entpacken: refused - archive contains unsafe path entries" >&2
            exit 1
        fi
        tar -xzf "$ARCHIVE" -C "$DEST"
        ;;
    *.tar)
        if tar -tf "$ARCHIVE" | grep -qE "$UNSAFE_RE"; then
            echo "archiv_entpacken: refused - archive contains unsafe path entries" >&2
            exit 1
        fi
        tar -xf "$ARCHIVE" -C "$DEST"
        ;;
    *)
        echo "archiv_entpacken: unsupported archive extension (use .zip, .tar.gz/.tgz, or .tar)" >&2
        exit 1
        ;;
esac
