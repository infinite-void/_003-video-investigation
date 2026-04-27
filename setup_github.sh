#!/bin/bash

# GitHub Repository Setup Script
# This script helps you create a GitHub repository and push your code

echo "GitHub Repository Setup"
echo "========================"
echo ""

# Check if we're in the right directory
if [ ! -d ".git" ]; then
    echo "Error: This script must be run from the root of your Git repository"
    exit 1
fi

# Check if git is configured
if [ -z "$(git config user.email)" ] || [ -z "$(git config user.name)" ]; then
    echo "Git is not properly configured. Please run:"
    echo "  git config --global user.email "your@email.com""
    echo "  git config --global user.name "Your Name""
    exit 1
fi

echo "Current Git remote (if any):"
git remote -v
echo ""

read -p "Do you want to create a new GitHub repository? (y/n): " create_repo

if [ "$create_repo" != "y" ]; then
    echo "Skipping repository creation."
    exit 0
fi

read -p "Enter your GitHub username: " github_username
read -p "Enter repository name (video-investigation-scripts): " repo_name
repo_name=${repo_name:-video-investigation-scripts}

read -s -p "Enter your GitHub personal access token: " github_token
echo ""

# Create repository using GitHub API
response=$(curl -s -X POST \
    -H "Authorization: token $github_token" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/user/repos \
    -d "{\"name\":\"$repo_name\",\"private\":false,\"description\":\"Video investigation scripts for Parrot OS\"}")

if echo "$response" | grep -q ""message""; then
    echo "Error creating repository:"
    echo "$response" | grep ""message""
    exit 1
fi

echo "Repository created successfully!"

# Add remote and push
remote_url="https://github.com/$github_username/$repo_name.git"
git remote add origin "$remote_url"

echo "Adding remote origin: $remote_url"

echo "Pushing to GitHub..."
git push -u origin master

echo ""
echo "Repository setup complete!"
echo "Your code is now on GitHub at: https://github.com/$github_username/$repo_name"
