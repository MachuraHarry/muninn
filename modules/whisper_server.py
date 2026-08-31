#!/usr/bin/env python3
"""Lokaler Whisper-MCP-Server fuer Muninn.

Ersatz fuer das (mit faster-whisper>=1.2 inkompatible) PyPI-Paket
"whisper-transcribe-mcp": dessen server.py liest _local_model.model_size_or_path,
das in faster-whisper 1.2 entfernt wurde -> beim ERSTEN tool_call klappt es
(Kurzschluss in "x is None or x.model_size_or_path ..."), jeder WEITERE Aufruf
schlaegt mit "AttributeError: 'WhisperModel' object has no attribute
'model_size_or_path'" fehl. Dieses Skript speichert die Modellgroesse selbst
und funktioniert dadurch ueber beliebig viele Aufrufe hinweg stabil.

Start (MCP_AUTO_SERVERS-Eintrag):
  uv run --with fastmcp --with faster-whisper python /root/muninn/modules/whisper_server.py

Kein API-Key noetig; komplett lokal. Modell wird beim ersten Gebrauch einmalig
von HuggingFace geholt und danach gecacht.
"""

import base64
import os
import tempfile
from pathlib import Path

from fastmcp import FastMCP

mcp = FastMCP("muninn-whisper")

DEFAULT_MODEL = os.environ.get("WHISPER_MODEL", "base")

_local_model = None
_local_model_size = None


def _get_local_model(model_size: str):
    """Laedt das faster-whisper-Modell genau einmal je Groesse und merkt sich
    die Groesse selbst (kein _local_model.model_size_or_path - das existiert in
    faster-whisper>=1.2 nicht mehr)."""
    from faster_whisper import WhisperModel

    global _local_model, _local_model_size
    if _local_model is None or _local_model_size != model_size:
        _local_model = WhisperModel(model_size, device="cpu", compute_type="int8")
        _local_model_size = model_size
    return _local_model


def _transcribe(path: str, language, model_size: str) -> dict:
    model = _get_local_model(model_size)
    try:
        segments, info = model.transcribe(str(path), language=language, beam_size=5)
        segment_list = [
            {"start": round(s.start, 2), "end": round(s.end, 2), "text": s.text.strip()}
            for s in segments
        ]
    except Exception as e:  # noqa: BLE001 - MCP-Fehlermeldung an den Aufrufer
        return {"error": f"Transcription failed: {e}"}

    return {
        "text": " ".join(s["text"] for s in segment_list),
        "language": info.language,
        "language_probability": round(info.language_probability, 3),
        "segments": segment_list,
        "backend": "local",
        "model": model_size,
    }


@mcp.tool()
def transcribe_file(
    file_path: str,
    language: str | None = None,
    model_size: str | None = None,
) -> dict:
    """Transcribe an audio file to text.

    Args:
        file_path: Absolute path to the audio file (ogg, mp3, wav, m4a, flac, ...).
        language: Language code (e.g. 'de', 'en'). Auto-detected if not provided.
        model_size: Local model size: tiny, base, small, medium, large-v3.
                    Defaults to the WHISPER_MODEL environment variable.
    """
    path = Path(file_path).expanduser().resolve()
    if not path.exists():
        return {"error": f"File not found: {file_path}"}
    if path.stat().st_size == 0:
        return {"error": f"File is empty: {file_path}"}
    return _transcribe(str(path), language, model_size or DEFAULT_MODEL)


@mcp.tool()
def transcribe_base64(
    audio_base64: str,
    extension: str = "ogg",
    language: str | None = None,
    model_size: str | None = None,
) -> dict:
    """Transcribe audio provided as a base64-encoded string.

    Args:
        audio_base64: Base64-encoded audio data.
        extension: File extension for the temp file (ogg, mp3, wav, m4a, ...).
        language: Language code. Auto-detected if not provided.
        model_size: Local model size. Defaults to the WHISPER_MODEL environment variable.
    """
    try:
        audio_bytes = base64.b64decode(audio_base64, validate=True)
    except Exception as e:  # noqa: BLE001
        return {"error": f"Invalid base64 data: {e}"}

    with tempfile.NamedTemporaryFile(suffix=f".{extension}", delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    try:
        return transcribe_file(str(tmp_path), language=language, model_size=model_size)
    finally:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass


@mcp.tool()
def list_models() -> dict:
    """List available Whisper model sizes and current configuration."""
    return {
        "active_backend": "local",
        "default_local_model": DEFAULT_MODEL,
        "local_models": [
            {"name": "tiny", "params": "39M", "speed": "~32x", "note": "Fastest, least accurate"},
            {"name": "base", "params": "74M", "speed": "~16x", "note": "Good balance"},
            {"name": "small", "params": "244M", "speed": "~6x", "note": "Better accuracy"},
            {"name": "medium", "params": "769M", "speed": "~2x", "note": "High accuracy"},
            {"name": "large-v3", "params": "1.5G", "speed": "~1x", "note": "Best accuracy, slowest"},
        ],
    }


def main():
    mcp.run()


if __name__ == "__main__":
    main()
