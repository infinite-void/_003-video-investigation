#!/bin/bash

# ============================================================
# SCRIPT 1 — METADATA & URL EXTRACTION
# Run this first on your downloaded videos
# Output: ~/investigation/reports/
# ============================================================

VIDEO_DIR="/mnt/llm/videos"
REPORT_DIR="$HOME/investigation/reports"
mkdir -p "$REPORT_DIR"

# Check dependencies
for cmd in jq curl python3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: $cmd not found. Run: sudo apt install $cmd"
        exit 1
    fi
done

echo "=============================="
echo "METADATA EXTRACTION STARTED"
echo "$(date)"
echo "=============================="

for json in "$VIDEO_DIR"/*.info.json; do
    [ -f "$json" ] || continue

    raw_base=$(basename "$json" .info.json)
    safe_base=$(echo "$raw_base" | tr -d '#|' | tr ' ' '_' | tr -s '_')
    REPORT="$REPORT_DIR/${safe_base}_report.txt"

    echo "" 
    echo "Processing: $raw_base"

    {
        echo "============================================================"
        echo "INVESTIGATION REPORT"
        echo "============================================================"
        echo "Source file: $raw_base"
        echo "Generated: $(date)"
        echo ""

        echo "------------------------------------------------------------"
        echo "METADATA"
        echo "------------------------------------------------------------"
        echo "Title: $(jq -r '.title // "N/A"' "$json")"
        echo "Channel: $(jq -r '.uploader // "N/A"' "$json")"
        echo "Channel ID: $(jq -r '.channel_id // "N/A"' "$json")"
        echo "Channel URL: $(jq -r '.channel_url // "N/A"' "$json")"
        echo "Uploader ID: $(jq -r '.uploader_id // "N/A"' "$json")"
        echo "Uploader URL: $(jq -r '.uploader_url // "N/A"' "$json")"
        echo "Upload Date: $(jq -r '.upload_date // "N/A"' "$json")"
        echo "Duration: $(jq -r '.duration // "N/A"' "$json") seconds"
        echo "View Count: $(jq -r '.view_count // "N/A"' "$json")"
        echo "Like Count: $(jq -r '.like_count // "N/A"' "$json")"
        echo "Comment Count:$(jq -r '.comment_count // "N/A"' "$json")"
        echo "Subscriber Count: $(jq -r '.channel_follower_count // "N/A"' "$json")"
        echo "Tags: $(jq -r '.tags // [] | join(", ")' "$json")"
        echo "Categories: $(jq -r '.categories // [] | join(", ")' "$json")"
        echo "Age Limit: $(jq -r '.age_limit // "N/A"' "$json")"
        echo "Availability: $(jq -r '.availability // "N/A"' "$json")"
        echo "Live Status: $(jq -r '.live_status // "N/A"' "$json")"
        echo "Location: $(jq -r '.location // "N/A"' "$json")"
        echo "Language: $(jq -r '.language // "N/A"' "$json")"
        echo ""

        echo "------------------------------------------------------------"
        echo "DESCRIPTION (FULL)"
        echo "------------------------------------------------------------"
        jq -r '.description // "No description"' "$json"
        echo ""

        echo "------------------------------------------------------------"
        echo "URLS FOUND IN DESCRIPTION"
        echo "------------------------------------------------------------"
        desc=$(jq -r '.description // ""' "$json")
        urls=$(echo "$desc" | grep -oE 'https?://[^[:space:]"<>]+')
        if [ -n "$urls" ]; then
            echo "$urls"
        else
            echo "None found"
        fi
        echo ""

        echo "------------------------------------------------------------"
        echo "IFRAMES IN DESCRIPTION"
        echo "------------------------------------------------------------"
        echo "$desc" | grep -oi '<iframe[^>]*>' || echo "None found"
        echo ""

        echo "------------------------------------------------------------"
        echo "HIDDEN UNICODE IN DESCRIPTION"
        echo "------------------------------------------------------------"
        hidden=$(echo "$desc" | grep -P "[\x{200B}-\x{200D}\x{FEFF}\x{00AD}]")
        if [ -n "$hidden" ]; then
            echo "WARNING: Hidden unicode detected:"
            echo "$hidden"
        else
            echo "None detected"
        fi
        echo ""

        echo "------------------------------------------------------------"
        echo "CHANNEL HANDLES AND USERNAMES FOUND"
        echo "------------------------------------------------------------"
        echo "$desc" | grep -oE '@[A-Za-z0-9_.-]+' || echo "None found"
        echo ""

        echo "------------------------------------------------------------"
        echo "HASHTAGS"
        echo "------------------------------------------------------------"
        echo "$desc" | grep -oE '#[A-Za-z0-9_]+' || echo "None found"
        echo ""

        echo "------------------------------------------------------------"
        echo "RELATED VIDEOS/PLAYLISTS IN METADATA"
        echo "------------------------------------------------------------"
        jq -r '.chapters // [] | .[] | "Chapter: \(.title) at \(.start_time)s"' "$json" 2>/dev/null || echo "No chapters"
        echo ""
        jq -r '.related_videos // [] | .[] | "Related: \(.title) | \(.id)"' "$json" 2>/dev/null || echo "No related videos in metadata"
        echo ""

        echo "------------------------------------------------------------"
        echo "SUBTITLES AVAILABLE"
        echo "------------------------------------------------------------"
        jq -r '.subtitles // {} | keys | join(", ")' "$json" 2>/dev/null || echo "None"
        echo ""

        echo "------------------------------------------------------------"
        echo "FILE BUNDLE CHECK"
        echo "------------------------------------------------------------"
        for ext in mp4 en.vtt description webp info.json; do
            if [ -f "$VIDEO_DIR/${raw_base}.$ext" ]; then
                echo "$ext: PRESENT"
            else
                echo "$ext: MISSING"
            fi
        done
        echo ""

        # Description file scan if present
        DESC_FILE="$VIDEO_DIR/${raw_base}.description"
        if [ -f "$DESC_FILE" ]; then
            echo "------------------------------------------------------------"
            echo "DESCRIPTION FILE — ADDITIONAL SCAN"
            echo "------------------------------------------------------------"
            echo "Iframes:"
            grep -oi '<iframe[^>]*>' "$DESC_FILE" || echo "None"
            echo ""
            echo "External URLs:"
            grep -oE 'https?://[^[:space:]"<>]+' "$DESC_FILE" || echo "None"
            echo ""
            echo "Handles:"
            grep -oE '@[A-Za-z0-9_.-]+' "$DESC_FILE" || echo "None"
            echo ""
        fi

        echo "------------------------------------------------------------"
        echo "LINKED PAGE CONTENT SCAN"
        echo "------------------------------------------------------------"
        desc=$(jq -r '.description // ""' "$json")
        urls=$(echo "$desc" | grep -oE 'https?://[^[:space:]"<>]+' | head -10)

        if [ -z "$urls" ]; then
            echo "No URLs to scan"
        else
            while IFS= read -r url; do
                echo ""
                echo "Fetching: $url"
                page=$(curl -s --max-time 15 --user-agent "Mozilla/5.0" "$url" 2>/dev/null)

                if [ -z "$page" ]; then
                    echo "Could not fetch page"
                    continue
                fi

                echo "--- Hidden HTML elements ---"
                echo "$page" | grep -oi 'display:\s*none[^"]*\|visibility:\s*hidden[^"]*\|opacity:\s*0[^"]*' | head -20 || echo "None found"

                echo "--- Zero-size elements ---"
                echo "$page" | grep -oi 'width:\s*0\|height:\s*0\|font-size:\s*0' | head -10 || echo "None found"

                echo "--- Iframes on page ---"
                echo "$page" | grep -oi '<iframe[^>]*>' | head -10 || echo "None found"

                echo "--- Obfuscated JS patterns ---"
                echo "$page" | grep -oE 'eval\([^)]+\)\|atob\([^)]+\)\|unescape\([^)]+\)' | head -10 || echo "None found"

                echo "--- Additional URLs on page ---"
                echo "$page" | grep -oE 'https?://[^"<> ]+' | grep -v 'youtube\|google\|gstatic\|ytimg' | head -20 || echo "None found"

                echo "--- Channel handles on page ---"
                echo "$page" | grep -oE '@[A-Za-z0-9_.-]+' | head -20 || echo "None found"

            done <<< "$urls"
        fi

        echo ""
        echo "============================================================"
        echo "END OF REPORT: $raw_base"
        echo "$(date)"
        echo "============================================================"

    } > "$REPORT"

    echo "Report saved: $REPORT"

done

echo ""
echo "=============================="
echo "ALL METADATA EXTRACTED"
echo "$(date)"
echo "Reports in: $REPORT_DIR"
echo "=============================="

