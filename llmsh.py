#!/usr/bin/env python3
# llmsh.py — Local LLM Shell Executor for Parrot OS
# Enhanced: Date-based organization, fuzzy search, CyberChef recipe selection,
# dry-run mode, dependency checks, validation of video/metadata pairs.

import subprocess
import sys
import os
import json
from pathlib import Path
import requests
import re
from datetime import datetime
from difflib import get_close_matches

# ===================== CONFIG =====================
OLLAMA_API = "http://127.0.0.1:11434/v1/complete"
MODEL = "qwen3-coder:8b"
VIDEOS_DIR = Path("/mnt/llm/videos")
REPORTS_DIR = Path.home() / "investigation/reports"
CYBERCHEF_CLI = "/usr/local/bin/cyberchef-cli"
LOG_FILE = REPORTS_DIR / "llmsh_log.txt"
PROCESSED_LOG = REPORTS_DIR / "processed_videos.json"

# Ensure reports dir exists
REPORTS_DIR.mkdir(parents=True, exist_ok=True)

# ===================== LOGGING =====================
def log(msg):
    with open(LOG_FILE, "a") as f:
        f.write(msg + "\n")
    print(msg)

def run_command(cmd, check=True, dry_run=False):
    log(f"[EXEC] {cmd}")
    if dry_run:
        log("[DRY-RUN] Skipped execution")
        return None
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.stdout.strip():
            log(f"[STDOUT]\n{result.stdout}")
        if result.stderr.strip():
            log(f"[STDERR]\n{result.stderr}")
        if check and result.returncode != 0:
            log(f"[ERROR] Command failed with exit {result.returncode}")
        return result
    except Exception as e:
        log(f"[EXCEPTION] {e}")
        return None

# ===================== DEPENDENCY CHECK =====================
def check_dependencies():
    missing = []
    for cmd, name in [(CYBERCHEF_CLI, "CyberChef CLI"), ("jq --version", "jq")]:
        try:
            subprocess.run(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except:
            missing.append(name)
    # Check Ollama
    try:
        r = requests.get(OLLAMA_API)
        if r.status_code != 200:
            missing.append("Ollama API not responding")
    except:
        missing.append("Ollama API not responding")
    if missing:
        log(f"[DEPENDENCY WARNING] Missing or unreachable: {', '.join(missing)}")

# ===================== OLLAMA INTERFACE =====================
def query_ollama(prompt):
    payload = {
        "model": MODEL,
        "prompt": prompt,
        "temperature": 0.0,
        "max_tokens": 1024
    }
    try:
        r = requests.post(OLLAMA_API, json=payload)
        r.raise_for_status()
        data = r.json()
        return data.get("completion", "").strip()
    except Exception as e:
        log(f"[OLLAMA ERROR] {e}")
        return ""

# ===================== PROCESSED LOG =====================
def load_processed():
    if PROCESSED_LOG.exists():
        try:
            data = json.load(open(PROCESSED_LOG))
            return set(data.get("processed", []))
        except Exception as e:
            log(f"[WARN] Failed to load processed log: {e}")
    return set()

def save_processed(files):
    processed = load_processed()
    processed.update(f.name for f in files)
    with open(PROCESSED_LOG, "w") as f:
        json.dump({"processed": sorted(list(processed))}, f, indent=2)

# ===================== VIDEO ORGANIZATION =====================
def organize_by_date(video_file):
    # Parse upload date from filename: YYYYMMDD_
    m = re.match(r"(\d{6,8})_", video_file.name)
    if m:
        date_str = m.group(1)
        folder_name = date_str[:6] # YYYYMM
        folder = VIDEOS_DIR / folder_name
        folder.mkdir(exist_ok=True)
        dest = folder / video_file.name
        if not dest.exists():
            video_file.rename(dest)
        return dest
    return video_file

# ===================== VIDEO SELECTION =====================
def resolve_videos(dates=None, pattern=None, folder=None, keywords=None):
    search_path = VIDEOS_DIR
    if folder:
        search_path = search_path / folder
    if not search_path.exists():
        log(f"[WARN] Folder {search_path} does not exist.")
        return []

    files = list(search_path.glob(pattern if pattern else "*.mp4"))

    # Filter by date
    if dates:
        matched = []
        date_regex = re.compile(r"(\d{6,8})")
        for f in files:
            m = date_regex.search(f.name)
            if m:
                file_date = m.group(1)
                if any(file_date.startswith(d) for d in dates):
                    matched.append(f)
        files = matched

    # Filter by fuzzy keywords
    if keywords:
        files = [f for f in files if any(
            kw.lower() in f.name.lower() or get_close_matches(kw.lower(), [f.name.lower()])[0:1]
            for kw in keywords
        )]

    # Validate video/JSON pair
    validated = []
    for f in files:
        json_file = f.with_suffix(".info.json")
        desc_file = f.with_suffix(".description")
        if json_file.exists() and desc_file.exists():
            validated.append(f)
        else:
            log(f"[WARN] Skipping {f.name} (missing metadata)")

    log(f"[INFO] {len(validated)} video(s) selected after validation.")
    return validated

def select_videos(user_prompt, force=False):
    # Load already processed
    processed = load_processed()
    keywords = user_prompt.lower().split()

    # Most recent batch
    if "most recent batch" in user_prompt.lower():
        subfolders = sorted([p for p in VIDEOS_DIR.iterdir() if p.is_dir()],
                            key=lambda p: p.stat().st_mtime, reverse=True)
        if subfolders:
            folder = subfolders[0].name
            files = resolve_videos(folder=folder, keywords=None)
        else:
            files = []
    else:
        # Month/year
        date_match = re.search(r"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)(\d{4})", user_prompt, re.I)
        if date_match:
            month_str, year_str = date_match.groups()
            month_num = {"Jan":"01","Feb":"02","Mar":"03","Apr":"04","May":"05","Jun":"06",
                         "Jul":"07","Aug":"08","Sep":"09","Oct":"10","Nov":"11","Dec":"12"}[month_str.capitalize()]
            prefix = f"{year_str}{month_num}"
            files = resolve_videos(dates=[prefix])
        else:
            files = resolve_videos(keywords=keywords)

    # Filter already processed unless force
    if not force:
        files = [f for f in files if f.name not in processed]

    log(f"[INFO] {len(files)} video(s) selected for processing.")
    return files

# ===================== METADATA SUMMARY =====================
def summarize_metadata(json_files):
    summary = {"earliest": None, "latest": None, "total": 0}
    dates = []
    for f in json_files:
        try:
            data = json.load(open(f))
            date = data.get("upload_date")
            if date:
                dates.append(date)
        except Exception as e:
            log(f"[WARN] Failed to read {f}: {e}")
    if dates:
        summary["earliest"] = min(dates)
        summary["latest"] = max(dates)
        summary["total"] = len(dates)
    return summary

# ===================== CYBERCHEF EXECUTION =====================
def run_cyberchef(input_files, recipe="Magic", dry_run=False):
    output_file = REPORTS_DIR / "cyberchef_summary.json"
    for f in input_files:
        cmd = f'{CYBERCHEF_CLI} -i "{f}" -r "{recipe}" -o "{output_file}"'
        run_command(cmd, dry_run=dry_run)
    log(f"[INFO] CyberChef summary saved to {output_file}")
    return output_file

# ===================== SCRIPT EXECUTION =====================
def run_extraction_script(script_name, video_files=None, dry_run=False):
    if not video_files:
        cmd = f"~/{script_name}"
    else:
        video_list = " ".join([str(f) for f in video_files])
        cmd = f"~/{script_name} --videos {video_list}"
    run_command(cmd, dry_run=dry_run)

# ===================== MAIN =====================
def main():
    if len(sys.argv) < 2:
        print("Usage: llmsh.py 'Your plain-English command here' [--dry-run]")
        sys.exit(1)

    user_prompt = sys.argv[1]
    dry_run = "--dry-run" in sys.argv
    force = "force" in user_prompt.lower() or "re-analyze" in user_prompt.lower()

    log(f"[USER] {user_prompt} (force={force}, dry_run={dry_run})")
    check_dependencies()

    video_files = select_videos(user_prompt, force=force)
    if not video_files:
        log("[WARN] No videos matched your request.")
        return

    # Organize videos into YYYYMM folders
    video_files = [organize_by_date(f) for f in video_files]

    # Generate Ollama commands
    prompt = f"""
You are a bash automation assistant for Parrot OS.
User command: {user_prompt}
Selected videos: {[f.name for f in video_files]}
Use existing scripts:
  - ~/script1_extract.sh
  - ~/script2_visual.sh
  - CyberChef CLI (cyberchef-cli)
Generate sequential bash commands to execute the task.
Format strictly as:

COMMANDS:
1) <bash command>
2) <bash command>
...
"""
    response = query_ollama(prompt)
    log(f"[OLLAMA]\n{response}")

    # Extract commands after "COMMANDS:"
    commands = []
    if "COMMANDS:" in response:
        lines = response.split("COMMANDS:")[1].strip().splitlines()
        for line in lines:
            line = line.strip()
            if line and re.match(r"^\d+\)", line):
                cmd = re.sub(r"^\d+\)\s*", "", line)
                commands.append(cmd)
    else:
        log("[WARN] No 'COMMANDS:' section found, using raw output as one command")
        commands.append(response.strip())

    if not commands:
        log("[ERROR] No commands generated by Ollama.")
        return

    # Confirm execution
    print("Generated commands:")
    for i, c in enumerate(commands, 1):
        print(f"{i}) {c}")
    choice = input("Execute all commands? (y/n): ").lower()
    if choice != "y":
        log("[INFO] Command execution skipped by user.")
        return

    # Execute sequentially
    for cmd in commands:
        run_command(cmd, dry_run=dry_run)

    # Update processed log
    if not dry_run:
        save_processed(video_files)

    # Automatic metadata summary
    json_files = list(Path(VIDEOS_DIR).rglob("*.info.json"))
    if json_files:
        summary = summarize_metadata(json_files)
        summary_file = REPORTS_DIR / "metadata_summary.json"
        with open(summary_file, "w") as f:
            json.dump(summary, f, indent=2)
        log(f"[INFO] Metadata summary saved to {summary_file}")
        log(f"[INFO] Summary: {summary}")

if __name__ == "__main__":
    main()