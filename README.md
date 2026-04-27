# Video Investigation Scripts

A suite of scripts for comprehensive video analysis and investigation on Parrot OS.

## Overview

This repository contains three scripts that form a complete pipeline for video investigation:

1. **llmsh.py** - Main orchestrator using LLM for command generation
2. **script1_extract.sh** - Metadata and URL extraction
3. **script2_visual.sh** - Visual frame analysis

## Features

- **Date-based organization**: Automatically organizes videos into YYYYMM folders
- **Metadata extraction**: Comprehensive analysis of video metadata and descriptions
- **URL and pattern scanning**: Identifies URLs, iframes, hidden unicode, handles
- **Visual analysis**: Extracts and analyzes key frames using VL models
- **Memory management**: Efficient handling of large language models
- **Reporting**: Generates detailed analysis reports

## Requirements

### Dependencies

- Python 3.x
- Ollama API (running locally)
- FFmpeg
- jq
- curl
- CyberChef CLI (optional for llmsh.py)

### Recommended Models

- `qwen3-coder:8b` - For command generation
- `huihui_ai/qwen3-vl-abliterated:latest` - For visual analysis

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/video-investigation-scripts.git
cd video-investigation-scripts

# Make scripts executable
chmod +x llmsh.py script1_extract.sh script2_visual.sh

# Install dependencies
sudo apt install python3 ffmpeg jq curl

# Install Ollama and required models
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen3-coder:8b
ollama pull huihui_ai/qwen3-vl-abliterated:latest
```

## Configuration

Edit the configuration section in each script to match your environment:

### llmsh.py
```python
OLLAMA_API = "http://127.0.0.1:11434/v1/complete"
MODEL = "qwen3-coder:8b"
VIDEOS_DIR = Path("/mnt/llm/videos")
REPORTS_DIR = Path.home() / "investigation/reports"
CYBERCHEF_CLI = "/usr/local/bin/cyberchef-cli"
```

### script1_extract.sh
```bash
VIDEO_DIR="/mnt/llm/videos"
REPORT_DIR="$HOME/investigation/reports"
```

### script2_visual.sh
```bash
VIDEO_DIR="/mnt/llm/videos"
REPORT_DIR="$HOME/investigation/reports"
FRAME_DIR="$HOME/investigation/frames"
VL_MODEL="huihui_ai/qwen3-vl-abliterated:latest"
OLLAMA_API="http://127.0.0.1:11434"
```

## Usage

### Basic Workflow

1. **Run metadata extraction**:
```bash
./script1_extract.sh
```

2. **Run visual analysis**:
```bash
./script2_visual.sh
```

3. **Use LLM orchestrator**:
```bash
python llmsh.py "analyze recent videos" [--dry-run]
```

### llmsh.py Usage

```bash
# Basic usage
python llmsh.py "analyze videos from January 2024"

# Force re-analysis
python llmsh.py "re-analyze all videos force"

# Dry run (show commands without executing)
python llmsh.py "analyze recent batch" --dry-run

# Specific video selection
python llmsh.py "analyze videos with keyword tutorial"
```

## Output Structure

```
investigation/
├── reports/              # Analysis reports
│   ├── *video_name*_report.txt      # Metadata reports
│   ├── *video_name*_visual.txt     # Visual analysis reports
│   ├── cyberchef_summary.json      # CyberChef analysis
│   ├── metadata_summary.json       # Metadata summary
│   └── llmsh_log.txt               # Execution logs
├── frames/               # Extracted frames
│   └── *video_name*/     # Per-video frame organization
│       ├── scene/        # Scene change frames
│       └── pause/        # Motion pause frames
└── scripts/               # The scripts themselves
```

## Examples

### Example 1: Analyze recent videos
```bash
python llmsh.py "analyze most recent batch"
```

### Example 2: Analyze specific month
```bash
python llmsh.py "analyze videos from March 2024"
```

### Example 3: Force re-analysis
```bash
python llmsh.py "re-analyze videos with tutorial keyword force"
```

## Advanced Features

### Date-based Organization
Videos are automatically organized into YYYYMM folders based on their upload date extracted from filenames.

### Fuzzy Search
The system uses fuzzy matching to find videos based on keywords in filenames.

### Memory Management
The visual analysis script includes memory management to unload VL models between videos, preventing memory exhaustion.

### Dry Run Mode
Use `--dry-run` flag to see what commands would be executed without actually running them.

## Troubleshooting

### Ollama not responding
- Ensure Ollama service is running: `sudo systemctl start ollama.service`
- Check that the required models are pulled
- Verify the API endpoint matches your configuration

### Missing dependencies
- Run the dependency check: `./script1_extract.sh` (it will show missing dependencies)
- Install missing packages with: `sudo apt install package-name`

### Frame extraction issues
- Ensure FFmpeg is properly installed
- Check video file permissions
- Verify disk space for frame storage

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit your changes: `git commit -am 'Add new feature'`
4. Push to the branch: `git push origin feature-name`
5. Submit a pull request

## License

[MIT License](LICENSE)

## Support

For issues or questions, please open an issue on the GitHub repository.
