#!/bin/bash
# GPS Kiosk Download Setup Wrapper
# Simple wrapper for the download setup script

echo "================================="
echo "   GPS Kiosk Download Setup"
echo "================================="
echo ""
echo "This will:"
echo "- Download GPS Kiosk from GitHub (no login required)"
echo "- Extract and install the application"
echo "- Pull Docker images"
echo "- Start the application"
echo "- Configure startup on boot"
echo ""
echo "No Git installation or GitHub login required!"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Run the actual download setup script
bash "$SCRIPT_DIR/download-setup.sh"

echo ""
echo "Setup complete! Press Enter to exit..."
read
