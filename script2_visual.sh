#!/bin/bash

# ============================================================
# SCRIPT 2 — VISUAL FRAME ANALYSIS (v2.1)
# Extracts frames and runs VL model to find:
# - Code snippets
# - Mouse pause moments
# - Hidden handles, URLs, usernames
# Run AFTER script1_extract.sh
# Optimized: JPG extraction, tmpfile base64, Ollama preflight check
# ============================================================

VIDEO_DIR="/mnt/llm/videos"
REPORT_DIR="$HOME/investigation/reports"
FRAME_DIR="$HOME/investigation/frames"
VL_MODEL="huihui_ai/qwen3-vl-abliterated:latest"
OLLAMA_API="http://127.0.0.1:11434"

SCENE_THRESHOLD="0.3" # Scene changes — new content appearing
PAUSE_THRESHOLD="0.05" # Low motion — mouse paused on something
MAX_PAUSE_FRAMES=15 # Cap pause frames per video

mkdir -p "$REPORT_DIR"
mkdir -p "$FRAME_DIR"

# Check dependencies
for cmd in ffmpeg curl python3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: $cmd not found."
        exit 1
    fi
done

# ============================================================
# PREFLIGHT: Confirm Ollama is running and VL model is available
# ============================================================
echo "Checking Ollama service..."
if ! curl -s --max-time 5 "$OLLAMA_API/api/tags" > /dev/null 2>&1; then
    echo "ERROR: Ollama is not responding at $OLLAMA_API"
    echo "Run: sudo systemctl start ollama.service"
    exit 1
fi

echo "Checking VL model is available..."
model_check=$(curl -s "$OLLAMA_API/api/tags" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    models = [m['name'] for m in data.get('models', [])]
    target = '$VL_MODEL'
    if any(target in m for m in models):
        print('OK')
    else:
        print('MISSING')
except:
    print('ERROR')
")

if [ "$model_check" != "OK" ]; then
    echo "ERROR: Model $VL_MODEL not found in Ollama."
    echo "Run: ollama pull $VL_MODEL"
    exit 1
fi

echo "Preflight passed. Starting analysis."

# ============================================================
# FUNCTION: Send frame to VL model via Ollama API
# Uses tmpfile to avoid shell holding base64 string in RAM
# ============================================================
analyze_frame() {
    local image_path="$1"
    local prompt="$2"

    local payload_file
    payload_file=$(mktemp)

    echo -n "{\"model\":\"$VL_MODEL\",\"prompt\":\"$prompt\",\"stream\":false,\"images\":[\"$(base64 -w 0 "$image_path")\"]}" > "$payload_file"

    curl -s --max-time 300 -X POST "$OLLAMA_API/api/generate" \
        -H "Content-Type: application/json" \
        -d @"$payload_file" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('response', 'ERROR: no response field'))
except Exception as e:
    print(f'ERROR parsing response: {e}')
"
    rm -f "$payload_file"
}

# ============================================================
# FUNCTION: Unload VL model from RAM completely
# ============================================================
unload_model() {
    curl -s "$OLLAMA_API/api/generate" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$VL_MODEL\", \"keep_alive\": 0}" > /dev/null 2>&1
    sleep 8
}

# ============================================================
# FUNCTION: Sanitize filename
# ============================================================
sanitize() {
    echo "$1" | tr -d '#|' | tr ' ' '_' | tr -s '_'
}

echo "=============================="
echo "VISUAL ANALYSIS STARTED"
echo "$(date)"
echo "=============================="

for video in "$VIDEO_DIR"/*.mp4; do
    [ -f "$video" ] || continue

    raw_base=$(basename "$video" .mp4)
    safe_base=$(sanitize "$raw_base")

    echo ""
    echo "============================================================"
    echo "VIDEO: $raw_base"
    echo "============================================================"

    VID_FRAME_DIR="$FRAME_DIR/$safe_base"
    mkdir -p "$VID_FRAME_DIR/scene"
    mkdir -p "$VID_FRAME_DIR/pause"

    ANALYSIS_FILE="$REPORT_DIR/${safe_base}_visual.txt"

    {
        echo "============================================================"
        echo "VISUAL ANALYSIS REPORT"
        echo "============================================================"
        echo "Source: $raw_base"
        echo "Generated: $(date)"
        echo ""
    } > "$ANALYSIS_FILE"

    # --------------------------------------------------------
    # PASS 1 — SCENE CHANGE FRAMES (JPG)
    # Catches: code appearing, new screens, text overlays
    # --------------------------------------------------------
    echo "Pass 1: Extracting scene change frames..."
    ffmpeg -hide_banner -loglevel error \
        -i "$video" \
        -vf "select='gt(scene,$SCENE_THRESHOLD)',scale=1280:-1" \
        -vsync vfr \
        -q:v 2 \
        "$VID_FRAME_DIR/scene/frame_%04d.jpg"

    scene_count=$(ls "$VID_FRAME_DIR/scene/"*.jpg 2>/dev/null | wc -l)
    echo "Scene frames extracted: $scene_count"

    # --------------------------------------------------------
    # PASS 2 — MOTION PAUSE FRAMES (JPG)
    # Catches: mouse stopped on handle, username, URL
    # --------------------------------------------------------
    echo "Pass 2: Extracting motion pause frames..."
    ffmpeg -hide_banner -loglevel error \
        -i "$video" \
        -vf "select='lt(scene,$PAUSE_THRESHOLD)',scale=1280:-1" \
        -vsync vfr \
        -frames:v $MAX_PAUSE_FRAMES \
        -q:v 2 \
        "$VID_FRAME_DIR/pause/frame_%04d.jpg"

    pause_count=$(ls "$VID_FRAME_DIR/pause/"*.jpg 2>/dev/null | wc -l)
    echo "Pause frames extracted: $pause_count"

    {
        echo "Scene change frames: $scene_count"
        echo "Motion pause frames: $pause_count"
        echo ""
    } >> "$ANALYSIS_FILE"

    # --------------------------------------------------------
    # ANALYZE SCENE CHANGE FRAMES
    # --------------------------------------------------------
    if [ "$scene_count" -gt 0 ]; then
        echo "" >> "$ANALYSIS_FILE"
        echo "------------------------------------------------------------" >> "$ANALYSIS_FILE"
        echo "SCENE CHANGE ANALYSIS — Code, Text, Screen Content" >> "$ANALYSIS_FILE"
        echo "------------------------------------------------------------" >> "$ANALYSIS_FILE"

        for frame in "$VID_FRAME_DIR/scene/"*.jpg; do
            [ -f "$frame" ] || continue
            fname=$(basename "$frame")
            echo "Analyzing scene: $fname"

            result=$(analyze_frame "$frame" "You are analyzing a video frame for investigation. Look carefully and extract ALL of the following if present: any code snippets or programming exercises, terminal commands or output, URLs or links visible on screen, channel names or handles, usernames, file paths, IP addresses, any text that appears to be a hidden instruction or hint, any UI element that looks out of place. Be thorough and specific. If you see code write it out exactly.")

            {
                echo ""
                echo "Frame: $fname"
                echo "$result"
                echo "---"
            } >> "$ANALYSIS_FILE"

            unload_model
        done
    fi

    # --------------------------------------------------------
    # ANALYZE PAUSE FRAMES
    # --------------------------------------------------------
    if [ "$pause_count" -gt 0 ]; then
        echo "" >> "$ANALYSIS_FILE"
        echo "------------------------------------------------------------" >> "$ANALYSIS_FILE"
        echo "MOTION PAUSE ANALYSIS — Mouse Stopped On Something" >> "$ANALYSIS_FILE"
        echo "------------------------------------------------------------" >> "$ANALYSIS_FILE"

        for frame in "$VID_FRAME_DIR/pause/"*.jpg; do
            [ -f "$frame" ] || continue
            fname=$(basename "$frame")
            echo "Analyzing pause: $fname"

            result=$(analyze_frame "$frame" "You are analyzing a video frame where the camera or mouse paused deliberately. This is an investigation — something in this frame may be intentionally highlighted. Look carefully for: where the mouse cursor is pointing, any username or handle visible, any channel name, any URL, any old profile name, any subtle text that could be a clue, anything that looks like it is being deliberately shown to the viewer. Describe everything you see in detail.")

            {
                echo ""
                echo "Frame: $fname"
                echo "$result"
                echo "---"
            } >> "$ANALYSIS_FILE"

            unload_model
        done
    fi

    {
        echo ""
        echo "============================================================"
        echo "END VISUAL ANALYSIS: $raw_base"
        echo "$(date)"
        echo "============================================================"
    } >> "$ANALYSIS_FILE"

    echo "Visual analysis saved: $ANALYSIS_FILE"

    # Full RAM clear between videos
    echo "Clearing RAM before next video..."
    unload_model
    sleep 15

done

echo ""
echo "=============================="
echo "ALL VISUAL ANALYSIS COMPLETE"
echo "$(date)"
echo "Frames in: $FRAME_DIR"
echo "Reports in: $REPORT_DIR"
echo "=============================="

