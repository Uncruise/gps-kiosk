#!/bin/bash
# GPS Kiosk Auto-Login and Kiosk Configuration Wrapper Script
# This script wraps the auto-login configuration for easier use

echo ""
echo "==============================================="
echo "   GPS Kiosk Auto-Login Configuration"
echo "==============================================="
echo ""
echo "This script will configure your Linux system for:"
echo "  ✓ Automatic login (no password prompt)"
echo "  ✓ Kiosk mode startup integration"
echo "  ✓ GPS navigation auto-launch"
echo "  ✓ Display power management"
echo ""
echo "WARNING: This will modify system settings"
echo "for unattended operation. Only use on dedicated kiosk systems."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    echo ""
    echo "Run with: sudo $0"
    echo ""
    exit 1
fi

echo "Running as root ✓"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check if configure-auto-login.sh exists
if [ ! -f "$SCRIPT_DIR/configure-auto-login.sh" ]; then
    echo "ERROR: configure-auto-login.sh not found in current directory"
    echo "Please ensure you're running this from the GPS Kiosk unix folder"
    echo ""
    exit 1
fi

# Get username and password
echo "=== User Configuration ==="
read -p "Enter username for auto-login: " username
read -sp "Enter password: " password
echo ""
echo ""

# Confirm
echo "Configuration:"
echo "  Username: $username"
echo "  Auto-login: Enabled"
echo "  Kiosk mode: Enabled"
echo ""
read -p "Continue with these settings? (y/N): " confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Configuration cancelled."
    exit 0
fi

# Run the actual configuration script
bash "$SCRIPT_DIR/configure-auto-login.sh" --username "$username" --password "$password"

exitCode=$?

if [ $exitCode -eq 0 ]; then
    echo ""
    echo "=== Configuration Complete! ==="
    echo ""
    echo "Your system is now configured for kiosk mode."
    echo "On next boot, it will:"
    echo "  1. Automatically login as $username"
    echo "  2. Start GPS Kiosk service"
    echo "  3. Launch browser in kiosk mode"
    echo ""
    echo "To test without rebooting:"
    echo "  sudo systemctl start gps-kiosk.service"
    echo ""
else
    echo ""
    echo "Configuration encountered errors. Please check the output above."
fi
