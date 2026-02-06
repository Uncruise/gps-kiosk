#!/bin/bash
# GPS Kiosk Quick Setup Wrapper
# Simple wrapper that calls the PowerShell-like setup script

echo "================================="
echo "   GPS Kiosk Quick Setup"
echo "================================="
echo ""
echo "This will:"
echo "- Clone the GPS Kiosk repository"
echo "- Pull Docker images"
echo "- Start the application"
echo "- Configure startup on boot"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Run the actual setup script
bash "$SCRIPT_DIR/quick-setup.sh"

exitCode=$?

echo ""
if [ $exitCode -ne 0 ]; then
    echo "Setup encountered an error."
    echo "If you're having Docker issues, try running: ./docker-diagnostic.sh"
    echo ""
fi
echo "Setup complete! Press Enter to exit..."
read
