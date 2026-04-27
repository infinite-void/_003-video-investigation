# _003 Video Investigation Suite

**Advanced video forensics tools for Parrot OS** 🔍

![Video Investigation](https://img.shields.io/badge/Status-Production-ready-success)
![License](https://img.shields.io/badge/License-MIT-blue)
![Python](https://img.shields.io/badge/Python-3.x-blue)
![Ollama](https://img.shields.io/badge/Ollama-Powered-important)

## 🎯 Overview

A **flexible, configurable** suite for comprehensive video analysis and investigation. Designed for forensic analysts, researchers, and security professionals.

## 🔧 Features

### **Core Capabilities**
- ✅ **Multi-storage support**: Thumb drives, USB, network storage, local directories
- ✅ **LLM automation**: Ollama-powered intelligent command generation
- ✅ **Visual forensics**: Frame extraction and VL model analysis
- ✅ **Metadata extraction**: Comprehensive video metadata scanning
- ✅ **Flexible configuration**: Environment variables, config files, or defaults
- ✅ **Memory management**: Efficient handling of large language models

### **Storage Flexibility**
Adapts to YOUR setup:
- 📁 Thumb drives (`/mnt/llm/videos`)
- 💾 USB drives (`/media/username/DRIVE/`)
- 🌐 Network storage (`/mnt/nas/videos`)
- 🏠 Local directories (`~/videos/`)

### **Analysis Tools**
1. **llmsh.py** - LLM-powered orchestrator
2. **script1_extract.sh** - Metadata & URL extraction
3. **script2_visual.sh** - Visual frame analysis

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/infinite-void/_003-video-investigation.git
cd _003-video-investigation

# Set up for your storage (or use defaults)
export VIDEO_DIR="/mnt/llm/videos"  # Your thumb drive

# Install dependencies
sudo apt install python3 ffmpeg jq curl

# Install Ollama and models
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen3-coder:8b
ollama pull huihui_ai/qwen3-vl-abliterated:latest

# Run analysis
./script1_extract.sh   # Extract metadata
./script2_visual.sh   # Analyze frames
python llmsh.py "analyze recent videos"  # LLM orchestration
```

## 📁 Configuration

### **Quick Setup (Environment Variables)**
```bash
# Thumb drive (your setup)
export VIDEO_DIR="/mnt/llm/videos"
export REPORT_DIR="~/investigation/reports"
export FRAME_DIR="~/investigation/frames"
```

### **Persistent Setup (Config File)**
```bash
# Copy example config
mkdir -p ~/.config/video-investigation/
cp config.ini.example ~/.config/video-investigation/config.ini

# Edit for your setup
nano ~/.config/video-investigation/config.ini
```

### **Multiple Configurations**
```bash
# Switch between setups easily
export VIDEO_DIR="/media/usb/videos"  # USB drive
./script1_extract.sh

export VIDEO_DIR="/mnt/nas/videos"    # Network storage
./script1_extract.sh
```

See [CONFIGURATION_GUIDE.md](CONFIGURATION_GUIDE.md) for complete setup instructions.

## 🎯 Use Cases

Perfect for:
- **Video forensics** - Extract hidden data from videos
- **Content analysis** - Scan descriptions, URLs, metadata
- **Investigation** - Find clues in visual content
- **Automation** - LLM-powered workflows
- **Research** - Comprehensive video analysis

## 📊 Example Workflow

```bash
# 1. Extract metadata from videos
./script1_extract.sh
# → Generates detailed reports in ~/investigation/reports/

# 2. Analyze visual content
./script2_visual.sh
# → Extracts key frames and analyzes with VL model

# 3. Use LLM for intelligent analysis
python llmsh.py "find suspicious videos from March 2024"
# → Generates and executes analysis commands
```

## 🔒 Security & Privacy

- **No hardcoded paths** - All paths are configurable
- **Local processing** - All analysis happens on your machine
- **Private by default** - No data sent to external servers
- **Configurable** - Adapt to your security requirements

## 📚 Documentation

- **[Configuration Guide](CONFIGURATION_GUIDE.md)** - Complete setup instructions
- **[GitHub Setup](GITHUB_SETUP.md)** - Repository setup guide
- **[Project Summary](PROJECT_SUMMARY.md)** - Technical overview

## 🎨 Customization

### **Ollama Models**
```bash
# Use different models
export OLLAMA_MODEL="llama3:70b"
export OLLAMA_VL_MODEL="bakllava:latest"
```

### **Analysis Parameters**
```bash
# Adjust sensitivity
export SCENE_THRESHOLD="0.4"    # More sensitive scene detection
export PAUSE_THRESHOLD="0.03"   # More sensitive pause detection
```

## 🌟 Why _003?

The `_003` prefix indicates:
- **Project 003** - Third in a series of investigation tools
- **Flexible** - Adapts to different storage setups (003 = multiple options)
- **Professional** - Designed for serious investigation work

## 📈 Roadmap

Future enhancements:
- ✅ Flexible configuration system (DONE)
- 🔜 Command-line argument parsing
- 🔜 Docker container support
- 🔜 Web interface
- 🔜 Automated report generation

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 📝 License

MIT License - Free to use, modify, and distribute

## 📬 Contact

For questions or support:
- Open an issue on GitHub
- Check the documentation
- Explore the configuration options

---

**Built for investigators, by investigators** 🔍

![Video Investigation](https://socialify.git.ci/infinite-void/_003-video-investigation/image?description=1&font=Inter&language=1&name=1&owner=1&pattern=Plus&stargazers=1&theme=Dark)
