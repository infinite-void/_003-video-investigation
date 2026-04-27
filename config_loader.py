#!/usr/bin/env python3
# config_loader.py - Configuration management for video investigation scripts

import os
import configparser
from pathlib import Path

class ConfigLoader:
    def __init__(self):
        self.config = configparser.ConfigParser()
        self.config_file = None
        self.defaults = {
            'paths': {
                'video_dir': '/mnt/llm/videos',
                'report_dir': '~/investigation/reports',
                'frame_dir': '~/investigation/frames'
            },
            'ollama': {
                'api_endpoint': 'http://127.0.0.1:11434',
                'model': 'qwen3-coder:8b',
                'vl_model': 'huihui_ai/qwen3-vl-abliterated:latest'
            },
            'cyberchef': {
                'cli_path': '/usr/local/bin/cyberchef-cli'
            },
            'behavior': {
                'scene_threshold': '0.3',
                'pause_threshold': '0.05',
                'max_pause_frames': '15'
            }
        }
        
        # Load configuration from multiple sources
        self.load_config()
    
    def load_config(self):
        """Load configuration from file, environment variables, and defaults"""
        
        # 1. Try to find config file
        config_paths = [
            Path.home() / '.config' / 'video-investigation' / 'config.ini',
            Path(__file__).parent / 'config.ini',
            Path.cwd() / 'config.ini'
        ]
        
        for path in config_paths:
            if path.exists():
                self.config_file = path
                self.config.read(path)
                break
        
        # 2. Override with environment variables
        self.override_with_env()
    
    def override_with_env(self):
        """Override config with environment variables"""
        env_map = {
            'VIDEO_DIR': ('paths', 'video_dir'),
            'REPORT_DIR': ('paths', 'report_dir'),
            'FRAME_DIR': ('paths', 'frame_dir'),
            'OLLAMA_API': ('ollama', 'api_endpoint'),
            'OLLAMA_MODEL': ('ollama', 'model'),
            'OLLAMA_VL_MODEL': ('ollama', 'vl_model'),
            'CYBERCHEF_CLI': ('cyberchef', 'cli_path'),
            'SCENE_THRESHOLD': ('behavior', 'scene_threshold'),
            'PAUSE_THRESHOLD': ('behavior', 'pause_threshold'),
            'MAX_PAUSE_FRAMES': ('behavior', 'max_pause_frames')
        }
        
        for env_var, (section, key) in env_map.items():
            if env_var in os.environ:
                if not self.config.has_section(section):
                    self.config.add_section(section)
                self.config.set(section, key, os.environ[env_var])
    
    def get(self, section, key, default=None):
        """Get configuration value with fallback to defaults"""
        try:
            return self.config.get(section, key)
        except (configparser.NoSectionError, configparser.NoOptionError):
            return self.defaults.get(section, {}).get(key, default)
    
    def get_path(self, section, key):
        """Get path and expand user/home directory"""
        path = self.get(section, key)
        if path:
            return os.path.expanduser(path)
        return path
    
    def get_float(self, section, key):
        """Get float value"""
        value = self.get(section, key)
        return float(value) if value else None
    
    def get_int(self, section, key):
        """Get integer value"""
        value = self.get(section, key)
        return int(value) if value else None
    
    def list_config(self):
        """List current configuration"""
        print("Current Configuration:")
        print("=" * 50)
        for section in self.config.sections():
            print(f"[{section}]")
            for key, value in self.config.items(section):
                print(f"  {key} = {value}")
        print("=" * 50)

if __name__ == "__main__":
    config = ConfigLoader()
    config.list_config()