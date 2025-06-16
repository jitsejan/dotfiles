#!/usr/bin/env bash
set -euo pipefail

NAME=${1:-"recording-$(date +%Y%m%d-%H%M%S)"}
RECORDINGS_DIR="$HOME/recordings"
OUTPUT_DIR="$HOME/.local/share/whisperx/output"
VENV_PATH="$HOME/.local/share/whisperx/.venv"
WAV_FILE="$RECORDINGS_DIR/${NAME}.wav"
MARKDOWN_FILE="$OUTPUT_DIR/${NAME}.md"
OBS_PATH="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/ObsidiJan/Transcripts"

mkdir -p "$RECORDINGS_DIR" "$OUTPUT_DIR" "$OBS_PATH"

# -------- 🐚 Activate venv in a shell-safe way --------
echo "🔍 Detecting shell: $SHELL"

USER_SHELL=$(basename "$SHELL")
PYTHON_BIN="$VENV_PATH/bin/python3"

if [ "$USER_SHELL" = "fish" ]; then
  echo "🐟 Fish shell detected. Skipping activation script. Using python directly."
elif [ -f "$VENV_PATH/bin/activate" ]; then
  echo "💡 Activating venv..."
  source "$VENV_PATH/bin/activate"
else
  echo "⚠️ Could not find activate script. Continuing with direct call."
fi

# -------- 🎙 Record from mic --------
echo "🎙 Recording from mic to $WAV_FILE. Press Ctrl+C to stop."
ffmpeg -f avfoundation -i ":0" -ac 1 -ar 16000 "$WAV_FILE"

echo "🛑 Recording stopped. Proceeding to transcription..."

# -------- 🧠 Transcribe with WhisperX --------
echo "🧠 Transcribing with WhisperX..."
"$PYTHON_BIN" -m whisperx.transcribe "$WAV_FILE" \
  --output_dir "$OUTPUT_DIR" \
  --diarize \
  --output_format txt,json,md

# -------- 📁 Export to Obsidian --------
if [ -f "$MARKDOWN_FILE" ]; then
  cp "$MARKDOWN_FILE" "$OBS_PATH/"
  echo "✅ Transcription exported to Obsidian: $OBS_PATH/$(basename "$MARKDOWN_FILE")"
else
  echo "❌ Transcription failed or output not found."
fi
`