#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$HOME/.local/share/whisperx"
VENV_DIR="$PROJECT_DIR/.venv"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$PROJECT_DIR" "$BIN_DIR"

# Create the virtual environment using uv if not exists
if [ ! -d "$VENV_DIR" ]; then
    echo "🔧 Creating virtual environment..."
    uv venv "$VENV_DIR"
fi

# Install into the venv using system uv and --python path
echo "📦 Installing whisperx and dependencies..."
uv pip install whisperx ffmpeg torchaudio pyaudio --python "$VENV_DIR/bin/python"

# Create the wrapper script
cat <<EOF > "$BIN_DIR/record-and-whisper"
#!/usr/bin/env bash
set -euo pipefail

VENV="$VENV_DIR"
RECORDING="\$(mktemp -u).wav"

echo "🎙 Recording started. Press Ctrl+C to stop..."
trap 'echo "🛑 Recording stopped"; echo "🔍 Transcribing..."; \
    "\$VENV/bin/python" -m whisperx "\$RECORDING" --output_dir . --diarize && rm "\$RECORDING"' INT

ffmpeg -f avfoundation -i ":0" -ar 16000 -ac 1 -c:a pcm_s16le "\$RECORDING"
EOF

chmod +x "$BIN_DIR/record-and-whisper"
echo "✅ Installed. Use: record-and-whisper"