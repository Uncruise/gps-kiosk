#!/bin/bash
# Add COM2TCP functionality to existing GPS Kiosk startup script
# Run this script to update an existing installation with SVO-GPS specific functionality

echo "Adding COM2TCP support to GPS Kiosk startup..."

startupScript="/opt/gps-kiosk/start-gps-kiosk.sh"

if [ ! -f "$startupScript" ]; then
    echo "ERROR: GPS Kiosk startup script not found at $startupScript"
    echo "Please run quick-setup.sh first to create the startup script."
    exit 1
fi

# Create a backup of the existing script
cp "$startupScript" "$startupScript.backup"
echo "Created backup: $startupScript.backup"

# Check if COM2TCP logic already exists
if grep -q "COM2TCP" "$startupScript"; then
    echo "COM2TCP functionality already exists in startup script."
    exit 0
fi

# Create temporary file with updated script
tempScript=$(mktemp)

# Copy everything up to the browser launch
grep -v "GPS Kiosk is ready" "$startupScript" > "$tempScript"

# Add COM2TCP logic
cat >> "$tempScript" << 'EOF'

# Check computer name and start COM2TCP if needed
echo "Checking computer name for specialized configuration..."
if [ "$HOSTNAME" = "SVO-GPS" ]; then
    echo "Computer is SVO-GPS, starting COM2TCP for serial data bridge..."
    if [ -f "tools/com2tcp" ]; then
        nohup tools/com2tcp --baud 4800 /dev/ttyS4 127.0.0.1 10110 > /dev/null 2>&1 &
        echo "COM2TCP started: /dev/ttyS4 at 4800 baud -> 127.0.0.1:10110"
    else
        echo "WARNING: COM2TCP executable not found in tools directory"
    fi
else
    echo "Computer name is $HOSTNAME, skipping COM2TCP startup"
fi

EOF

# Add remaining script content
grep "GPS Kiosk is ready" "$startupScript" >> "$tempScript"
tail -n +$(grep -n "GPS Kiosk is ready" "$startupScript" | cut -d: -f1) "$startupScript" >> "$tempScript"

# Replace original script
mv "$tempScript" "$startupScript"
chmod +x "$startupScript"

echo "COM2TCP functionality added to GPS Kiosk startup script!"
echo ""
echo "Computer-specific behavior:"
echo "  • SVO-GPS: Will start COM2TCP bridge (/dev/ttyS4 4800 baud -> 127.0.0.1:10110)"
echo "  • Other computers: Will skip COM2TCP and run normally"
echo ""
echo "To test the updated startup:"
echo "  1. Restart the computer, OR"
echo "  2. Run: $startupScript"
echo ""
echo "Current computer name: $HOSTNAME"
if [ "$HOSTNAME" = "SVO-GPS" ]; then
    echo "✓ This computer will start COM2TCP on next restart"
else
    echo "ℹ This computer will skip COM2TCP (not SVO-GPS)"
fi
