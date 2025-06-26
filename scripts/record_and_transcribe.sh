#!/usr/bin/env bash
set -euo pipefail

NAME=${1:-"recording-$(date +%Y%m%d-%H%M%S)"}
RECORDINGS_DIR="$HOME/recordings"
OUTPUT_DIR="$HOME/.local/share/whisperx/output"
VENV_PATH="$HOME/.local/share/whisperx/.venv"
WAV_FILE="$RECORDINGS_DIR/${NAME}.wav"
JSON_FILE="$OUTPUT_DIR/${NAME}.json"
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

# -------- 🧠 Transcribe with WhisperX (with diarization) --------
echo "🧠 Transcribing with WhisperX and speaker diarization..."
"$PYTHON_BIN" -m whisperx "$WAV_FILE" \
  --output_dir "$OUTPUT_DIR" \
  --output_format json \
  --diarize \
  --hf_token "${HF_TOKEN:-}" \
  --device cpu

# -------- 📝 Generate enhanced Markdown with speaker flow --------
echo "📝 Generating enhanced Markdown with speaker flow..."
"$PYTHON_BIN" -c "
import json
import os
from datetime import datetime, timedelta

json_file = '$JSON_FILE'
markdown_file = '$MARKDOWN_FILE'

if not os.path.exists(json_file):
    print(f'❌ JSON file not found: {json_file}')
    exit(1)

with open(json_file, 'r') as f:
    data = json.load(f)

# Create enhanced Markdown
with open(markdown_file, 'w') as f:
    f.write(f'# Transcription: ${NAME}\n\n')
    f.write(f'**Date:** {datetime.now().strftime(\"%Y-%m-%d %H:%M:%S\")}\n')
    f.write(f'**Duration:** {data.get(\"duration\", \"Unknown\")} seconds\n\n')
    f.write('---\n\n')
    
    segments = data.get('segments', [])
    if not segments:
        f.write('No transcription segments found.\n')
    else:
        current_speaker = None
        for segment in segments:
            speaker = segment.get('speaker', 'Unknown')
            start_time = segment.get('start', 0)
            end_time = segment.get('end', 0)
            text = segment.get('text', '').strip()
            
            # Format timestamp
            start_min = int(start_time // 60)
            start_sec = int(start_time % 60)
            timestamp = f'{start_min:02d}:{start_sec:02d}'
            
            # Add speaker header if speaker changed
            if speaker != current_speaker:
                if current_speaker is not None:
                    f.write('\n')
                f.write(f'## {speaker}\n\n')
                current_speaker = speaker
            
            # Write timestamped text
            f.write(f'**[{timestamp}]** {text}\n\n')
        
        # Add summary section
        f.write('---\n\n## Summary\n\n')
        f.write('*Add your summary here*\n\n')
        f.write('## Action Items\n\n')
        f.write('- [ ] *Add action items here*\n')

print(f'✅ Enhanced Markdown generated: {markdown_file}')
"

# -------- 📁 Export to Obsidian --------
if [ -f "$MARKDOWN_FILE" ]; then
  cp "$MARKDOWN_FILE" "$OBS_PATH/"
  echo "✅ Transcription exported to Obsidian: $OBS_PATH/$(basename "$MARKDOWN_FILE")"
  echo "📄 Files created:"
  echo "  - Audio: $WAV_FILE"
  echo "  - JSON: $JSON_FILE"
  echo "  - Markdown: $MARKDOWN_FILE"
  echo "  - Obsidian: $OBS_PATH/$(basename "$MARKDOWN_FILE")"
else
  echo "❌ Transcription failed or output not found."
fi
