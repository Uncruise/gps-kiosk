#!/bin/bash
# GPS Kiosk Update Verification Script
# Run this on each machine after updating to verify auto-update functionality

echo "=== GPS Kiosk Update Verification ==="

INSTALL_PATH="/opt/gps-kiosk"
if [ ! -d "$INSTALL_PATH" ]; then
    INSTALL_PATH="$HOME/gps-kiosk"
    if [ ! -d "$INSTALL_PATH" ]; then
        INSTALL_PATH="$PWD"
    fi
fi

# Check if Docker container is running
containerStatus=$(docker ps --filter "name=gps-kiosk" --format "{{.Status}}" 2>/dev/null)
if echo "$containerStatus" | grep -q "Up"; then
    echo "✓ Container Status: $containerStatus"
else
    echo "✗ Container not running: $containerStatus"
fi

# Check if auto-update startup script exists
startupScript="$INSTALL_PATH/start-gps-kiosk.sh"
if [ -f "$startupScript" ]; then
    echo "✓ Startup script exists: $startupScript"
else
    echo "✗ Startup script missing: $startupScript"
fi

# Check if startup script has auto-update functionality
if [ -f "$startupScript" ]; then
    if grep -q "docker compose pull" "$startupScript"; then
        echo "✓ Startup script includes auto-update (docker compose pull)"
    else
        echo "✗ Startup script missing auto-update functionality"
    fi
fi

# Check web interface
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/signalk/ 2>/dev/null | grep -q "200"; then
    echo "✓ Web interface accessible (HTTP 200)"
else
    echo "✗ Web interface not accessible"
fi

# Test auto-update by checking if Git is available in container
gitTest=$(docker exec gps-kiosk git --version 2>/dev/null)
if [ -n "$gitTest" ]; then
    echo "✓ Git available in container for auto-updates: $gitTest"
else
    echo "✗ Git not available in container - auto-update won't work"
fi

# Check systemd service
if systemctl is-enabled gps-kiosk.service &>/dev/null; then
    echo "✓ GPS Kiosk service is enabled (will start on boot)"
else
    echo "⚠ GPS Kiosk service not enabled - won't auto-start on boot"
fi

echo ""
echo "=== Update Verification Complete ==="
echo "If all items show ✓, the machine is ready for auto-updates!"
