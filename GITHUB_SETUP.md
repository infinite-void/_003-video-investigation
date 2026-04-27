# Video Investigation Scripts - GitHub Setup Guide

## Current Status

Your video investigation scripts are ready and committed to a local Git repository at:
```
/home/_003/investigation/scripts/
```

## What's Been Done

1. ✅ Code review completed - all scripts are technically sound
2. ✅ Comprehensive README.md created
3. ✅ Git repository initialized
4. ✅ All scripts committed
5. ✅ GitHub setup script created

## Files in Repository

- `llmsh.py` - Main LLM orchestrator
- `script1_extract.sh` - Metadata extraction
- `script2_visual.sh` - Visual analysis
- `README.md` - Complete documentation
- `setup_github.sh` - GitHub setup helper

## Next Steps to Push to GitHub

### Option 1: Use the Setup Script (Recommended)

1. Run the setup script:
```bash
cd /home/_003/investigation/scripts
./setup_github.sh
```

2. Follow the prompts to:
   - Enter your GitHub username
   - Enter repository name (default: video-investigation-scripts)
   - Enter your GitHub personal access token

### Option 2: Manual Setup

1. Create a new repository on GitHub:
   - Go to https://github.com/new
   - Repository name: `video-investigation-scripts`
   - Description: "Video investigation scripts for Parrot OS"
   - Public or Private: Your choice
   - Click "Create repository"

2. Add remote and push:
```bash
cd /home/_003/investigation/scripts
git remote add origin https://github.com/yourusername/video-investigation-scripts.git
git push -u origin master
```

### Option 3: If You Don't Have a GitHub Token

1. Create a personal access token:
   - Go to GitHub Settings > Developer settings > Personal access tokens
   - Click "Generate new token"
   - Give it a name like "Video Investigation Scripts"
   - Select scopes: `repo` (full control of private repositories)
   - Click "Generate token"
   - Copy the token immediately (it won't be shown again)

2. Then use either Option 1 or 2 above

## Verifying Your Setup

After pushing, verify everything is working:

```bash
# Check remote
git remote -v

# Check status
git status

# View on GitHub
# Open https://github.com/yourusername/video-investigation-scripts in your browser
```

## Using the Scripts

Once on GitHub, others can clone and use your scripts:

```bash
git clone https://github.com/yourusername/video-investigation-scripts.git
cd video-investigation-scripts
chmod +x *.sh *.py
# Follow README.md instructions
```

## Need Help?

If you encounter any issues:

1. **Permission denied errors**: Make sure your GitHub token has the right permissions
2. **Authentication failed**: Double-check your token and username
3. **Repository already exists**: Choose a different name or delete the existing one
4. **Network issues**: Check your internet connection and GitHub status

The scripts are ready to use locally even without pushing to GitHub. The GitHub step is optional but recommended for version control and sharing.
