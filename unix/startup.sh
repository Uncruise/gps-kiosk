#!/bin/sh

# GPS Kiosk Startup Script - Auto-pull Volume config from GitHub

CONFIG_DIR="/home/node/.signalk"
GITHUB_REPO="https://github.com/Uncruise/gps-kiosk.git"
BRANCH="main"

echo "🚀 Starting GPS Kiosk..."
echo "📁 Config directory: $CONFIG_DIR"

# Always pull latest configuration from GitHub
if command -v git >/dev/null 2>&1; then
  echo "🔄 Pulling latest configuration from GitHub..."
  git clone -b $BRANCH $GITHUB_REPO /tmp/config
  
  # Backup existing config if exists
  if [ -d "$CONFIG_DIR" ] && [ "$(ls -A $CONFIG_DIR 2>/dev/null)" ]; then
    echo "📋 Backing up existing configuration..."
    cp -a "$CONFIG_DIR" /tmp/config-backup
  fi
  
  rm -rf "$CONFIG_DIR"/*
  
  # Copy Volume contents to config directory
  if [ -d "/tmp/config/Volume" ]; then
    cp -a /tmp/config/Volume/* "$CONFIG_DIR/"
    echo "✅ Latest configuration applied from GitHub"
  else
    echo "⚠️  No Volume directory found"
    if [ -d "/tmp/config-backup" ]; then
      echo "🔙 Restoring previous configuration"
      cp -a /tmp/config-backup/* "$CONFIG_DIR/"
    fi
  fi
  
  rm -rf /tmp/config /tmp/config-backup
else
  echo "⚠️  Git not available"
  echo "📋 Using existing configuration"
fi

# Ensure proper permissions
chown -R node:node "$CONFIG_DIR"
chmod -R 755 "$CONFIG_DIR"

echo "🌟 Starting Signal K Server..."
exec /usr/local/bin/signalk-server