#!/bin/bash
# GPS Kiosk Anonymous Download and Setup Script
# Downloads from GitHub without requiring git

INSTALL_PATH="/opt/gps-kiosk"
TEMP_PATH="/tmp/gps-kiosk-download"

echo "=== GPS Kiosk Anonymous Download Setup ==="

# Check if running as root for system-level installation
if [ "$EUID" -ne 0 ]; then
    echo "WARNING: Not running as root. Installation will be in current directory."
    INSTALL_PATH="$PWD/gps-kiosk"
fi

# Function to check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Check if Docker is installed
echo "Checking Docker..."
if ! command_exists docker; then
    echo "Docker not found. Please install Docker first."
    echo "Visit: https://docs.docker.com/engine/install/"
    exit 1
fi

# Ensure Docker service is running
if ! systemctl is-active --quiet docker 2>/dev/null; then
    echo "Starting Docker service..."
    if [ "$EUID" -eq 0 ]; then
        systemctl start docker
    else
        sudo systemctl start docker
    fi
fi

# Wait for Docker to be ready
echo "Waiting for Docker daemon..."
timeout=60
elapsed=0
until docker info &>/dev/null; do
    sleep 2
    elapsed=$((elapsed + 2))
    if [ $elapsed -ge $timeout ]; then
        echo "Docker daemon failed to start. Please check Docker status."
        exit 1
    fi
done
echo "Docker is ready."

# Clean up temp directory if it exists
rm -rf "$TEMP_PATH"
mkdir -p "$TEMP_PATH"

# Download repository ZIP from GitHub
echo "Downloading GPS Kiosk from GitHub..."
zipUrl="https://github.com/Uncruise/gps-kiosk/archive/refs/heads/main.zip"
zipPath="$TEMP_PATH/gps-kiosk.zip"

if command_exists curl; then
    curl -L "$zipUrl" -o "$zipPath"
elif command_exists wget; then
    wget "$zipUrl" -O "$zipPath"
else
    echo "ERROR: Neither curl nor wget found. Please install one of them."
    exit 1
fi

if [ ! -f "$zipPath" ]; then
    echo "Failed to download from GitHub"
    exit 1
fi

echo "Downloaded successfully!"

# Extract the ZIP file
echo "Extracting files..."
if command_exists unzip; then
    unzip -q "$zipPath" -d "$TEMP_PATH"
else
    echo "ERROR: unzip not found. Please install unzip."
    exit 1
fi

# Find the extracted folder (GitHub adds branch name to folder)
extractedFolder=$(find "$TEMP_PATH" -maxdepth 1 -type d -name "gps-kiosk-*" | head -n 1)

if [ -z "$extractedFolder" ]; then
    echo "Could not find extracted folder"
    exit 1
fi

# Copy to installation path
echo "Installing to $INSTALL_PATH..."
mkdir -p "$INSTALL_PATH"
cp -r "$extractedFolder"/* "$INSTALL_PATH/"

# Clean up
rm -rf "$TEMP_PATH"

# Change to installation directory
cd "$INSTALL_PATH" || exit 1

# Make scripts executable
chmod +x unix/*.sh 2>/dev/null

# Pull Docker images
echo "Pulling Docker images..."
docker compose pull

# Start GPS Kiosk
echo "Starting GPS Kiosk containers..."
docker compose up -d

# Wait for service to be ready
echo "Waiting for GPS Kiosk to be ready..."
timeout=120
elapsed=0
until curl -s http://localhost:3000/signalk/ &>/dev/null; do
    sleep 2
    elapsed=$((elapsed + 2))
    if [ $elapsed -ge $timeout ]; then
        echo "GPS Kiosk failed to start within timeout."
        echo "Check logs with: docker logs gps-kiosk"
        exit 1
    fi
done

echo "✓ GPS Kiosk is running!"
echo ""
echo "=== Setup Complete! ==="
echo ""
echo "GPS Kiosk is accessible at:"
echo "  http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1"
echo ""
echo "Installation directory: $INSTALL_PATH"
echo ""
echo "To configure auto-start on boot:"
echo "  cd $INSTALL_PATH/unix"
echo "  sudo ./configure-auto-login.sh --username <your-username> --password <your-password>"
echo ""
