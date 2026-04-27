# Configuration Guide for Video Investigation Scripts

## 🎯 **Overview**

The scripts now support **multiple configuration methods**, making them flexible for different setups including thumb drives, external storage, and various system configurations.

## 📁 **Configuration Methods (Priority Order)**

1. **Environment Variables** (highest priority)
2. **Configuration File** (`config.ini`)
3. **Default Values** (fallback)

## 🔧 **Method 1: Environment Variables (Quick Setup)**

Set variables before running scripts:

```bash
# For thumb drive setup (your current configuration)
export VIDEO_DIR="/mnt/llm/videos"
export REPORT_DIR="~/investigation/reports"
export FRAME_DIR="~/investigation/frames"

# For different Ollama setup
export OLLAMA_API="http://localhost:11434"
export OLLAMA_MODEL="llama3:70b"

# Run scripts
./script1_extract.sh
./script2_visual.sh
```

### **Available Environment Variables**

```bash
# Path Configuration
VIDEO_DIR="/path/to/videos"        # Video files location
REPORT_DIR="/path/to/reports"      # Report output location
FRAME_DIR="/path/to/frames"        # Extracted frames location

# Ollama Configuration
OLLAMA_API="http://host:port"        # Ollama API endpoint
OLLAMA_MODEL="model:name"          # Default LLM model
OLLAMA_VL_MODEL="vl-model:name"     # Visual LLM model

# CyberChef Configuration
CYBERCHEF_CLI="/path/to/cyberchef"  # CyberChef CLI path

# Analysis Parameters
SCENE_THRESHOLD="0.3"               # Scene change sensitivity (0.0-1.0)
PAUSE_THRESHOLD="0.05"              # Motion pause sensitivity (0.0-1.0)
MAX_PAUSE_FRAMES="15"               # Max pause frames per video
```

## 📄 **Method 2: Configuration File (Persistent Setup)**

Create a `config.ini` file in one of these locations:

1. `~/.config/video-investigation/config.ini` (recommended)
2. `/home/_003/investigation/scripts/config.ini` (script directory)
3. `./config.ini` (current working directory)

### **Example Configuration File**

```ini
[paths]
# For thumb drive setup (your current configuration)
video_dir = /mnt/llm/videos
report_dir = ~/investigation/reports
frame_dir = ~/investigation/frames

# For SSD/HDD setup
# video_dir = /media/username/drive_name/videos
# report_dir = /home/username/projects/reports

[ollama]
# Default Ollama configuration
api_endpoint = http://127.0.0.1:11434
model = qwen3-coder:8b
vl_model = huihui_ai/qwen3-vl-abliterated:latest

# For remote Ollama server
# api_endpoint = http://192.168.1.100:11434

[cyberchef]
cli_path = /usr/local/bin/cyberchef-cli

[behavior]
scene_threshold = 0.3
pause_threshold = 0.05
max_pause_frames = 15
```

### **Copy the Example Config**

```bash
# Copy the example to your home config directory
mkdir -p ~/.config/video-investigation/
cp config.ini.example ~/.config/video-investigation/config.ini

# Then edit it
nano ~/.config/video-investigation/config.ini
```

## 🏗️ **Method 3: Command-Line Arguments (Coming Soon)**

Future enhancement will add direct command-line options:

```bash
# Not yet implemented, but planned
./script1_extract.sh --video-dir /mnt/my/videos --report-dir ~/my/reports
```

## 📋 **Common Configuration Scenarios**

### **Scenario 1: Thumb Drive (Your Current Setup)**

```bash
# Environment variables
export VIDEO_DIR="/mnt/llm/videos"
export REPORT_DIR="~/investigation/reports"
export FRAME_DIR="~/investigation/frames"
```

Or in `config.ini`:
```ini
[paths]
video_dir = /mnt/llm/videos
report_dir = ~/investigation/reports
frame_dir = ~/investigation/frames
```

### **Scenario 2: External USB Drive**

```bash
# If your drive mounts at /media/username/DRIVE_NAME
export VIDEO_DIR="/media/username/DRIVE_NAME/videos"
export REPORT_DIR="/media/username/DRIVE_NAME/reports"
```

### **Scenario 3: Network Storage**

```bash
# For NFS/Samba mounts
export VIDEO_DIR="/mnt/nas/videos"
export REPORT_DIR="/mnt/nas/analysis"
```

### **Scenario 4: Different Ollama Setup**

```bash
# If Ollama runs on a different port or machine
export OLLAMA_API="http://localhost:5000"
export OLLAMA_MODEL="mistral:7b"
```

## 🔄 **Configuration Precedence**

The scripts use this priority order:

1. **Environment Variables** (highest priority)
2. **Configuration File** values
3. **Default Values** (lowest priority)

Example: If you set `VIDEO_DIR` in both environment and config file, the environment variable wins.

## 🎯 **Best Practices**

### **For Your Thumb Drive Setup**

```bash
# Add to your ~/.bashrc or ~/.zshrc
# Thumb drive configuration
export VIDEO_DIR="/mnt/llm/videos"
export REPORT_DIR="~/investigation/reports"
export FRAME_DIR="~/investigation/frames"

# Custom Ollama settings
export OLLAMA_MODEL="qwen3-coder:8b"
```

### **For Portability**

```bash
# Create a portable config.ini in the script directory
cp config.ini.example config.ini
nano config.ini  # Edit for your setup

# Then the scripts will automatically use it
```

## 🐛 **Troubleshooting**

### **Scripts not finding my videos?**

```bash
# Check current configuration
echo "VIDEO_DIR: $VIDEO_DIR"
echo "REPORT_DIR: $REPORT_DIR"

# Verify directory exists
ls "$VIDEO_DIR"
```

### **Want to see what configuration is being used?**

```bash
# For Python scripts
python config_loader.py

# For bash scripts
echo "VIDEO_DIR=$VIDEO_DIR"
echo "REPORT_DIR=$REPORT_DIR"
```

### **Change configuration temporarily**

```bash
# Override just for one command
VIDEO_DIR="/custom/path" ./script1_extract.sh
```

## 📝 **Migration from Old Setup**

If you were previously using the hardcoded paths, simply:

```bash
# Option 1: Set environment variables
export VIDEO_DIR="/mnt/llm/videos"

# Option 2: Create config file
cp config.ini.example ~/.config/video-investigation/config.ini

# Option 3: Do nothing - defaults match your current setup!
```

The new system is **backward compatible** - if you don't set any configuration, it uses the same defaults as before.

## 🚀 **Advanced: Multiple Configurations**

Create different config files for different projects:

```bash
# Project A configuration
cp config.ini.example config_project_a.ini
nano config_project_a.ini

# Use it
VIDEO_DIR="/mnt/project_a/videos" ./script1_extract.sh
```

## 🔒 **Security Note**

Never commit files containing sensitive information. The `config.ini` file should not contain:
- API keys
- Passwords
- Personal information

All configuration is local to your machine and not shared with GitHub.

## 📚 **Reference: All Configuration Options**

| Variable | Config Section | Default Value | Description |
|----------|----------------|---------------|-------------|
| `VIDEO_DIR` | paths.video_dir | /mnt/llm/videos | Video files directory |
| `REPORT_DIR` | paths.report_dir | ~/investigation/reports | Report output directory |
| `FRAME_DIR` | paths.frame_dir | ~/investigation/frames | Extracted frames directory |
| `OLLAMA_API` | ollama.api_endpoint | http://127.0.0.1:11434 | Ollama API endpoint |
| `OLLAMA_MODEL` | ollama.model | qwen3-coder:8b | Default LLM model |
| `OLLAMA_VL_MODEL` | ollama.vl_model | huihui_ai/qwen3-vl-abliterated:latest | Visual LLM model |
| `CYBERCHEF_CLI` | cyberchef.cli_path | /usr/local/bin/cyberchef-cli | CyberChef CLI path |
| `SCENE_THRESHOLD` | behavior.scene_threshold | 0.3 | Scene change sensitivity |
| `PAUSE_THRESHOLD` | behavior.pause_threshold | 0.05 | Motion pause sensitivity |
| `MAX_PAUSE_FRAMES` | behavior.max_pause_frames | 15 | Max pause frames per video |

## 🎉 **You're Ready!**

The scripts now adapt to YOUR setup, whether you're using:
- Thumb drives (`/mnt/`)
- External USB drives (`/media/`)
- Network storage (`/mnt/nas/`)
- Local directories (`~/videos/`)
- Custom Ollama configurations
- Different analysis parameters

No more hardcoded paths - the scripts work with YOUR configuration! 🚀