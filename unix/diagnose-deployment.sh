#!/bin/bash
# GPS Kiosk Diagnostic Script for Deployment Issues
# This script checks why kiosk browser and startup components aren't working

echo "=== GPS Kiosk Deployment Diagnostics ==="
echo ""

INSTALL_PATH="/opt/gps-kiosk"
if [ ! -d "$INSTALL_PATH" ]; then
    INSTALL_PATH="$HOME/gps-kiosk"
fi

# Check if quick-setup.sh ran to completion
echo "1. Checking setup completion status..."
startupScript="$INSTALL_PATH/start-gps-kiosk.sh"

if [ -f "$startupScript" ]; then
    echo "   ✓ Startup script exists: $startupScript"
else
    echo "   ✗ Startup script missing: $startupScript"
    echo "      This indicates quick-setup.sh didn't complete successfully"
fi

# Check systemd service
echo ""
echo "2. Checking systemd service..."
if systemctl is-enabled gps-kiosk.service &>/dev/null; then
    echo "   ✓ GPS Kiosk service is enabled"
    status=$(systemctl is-active gps-kiosk.service)
    echo "      Status: $status"
elif [ -f /etc/systemd/system/gps-kiosk.service ]; then
    echo "   ⚠ GPS Kiosk service exists but not enabled"
    echo "      Run: sudo systemctl enable gps-kiosk.service"
else
    echo "   ✗ GPS Kiosk service not configured"
fi

# Check Docker containers
echo ""
echo "3. Checking Docker containers..."
if docker ps --filter "name=gps-kiosk" --format "{{.Status}}" &>/dev/null; then
    containerStatus=$(docker ps --filter "name=gps-kiosk" --format "{{.Status}}")
    if [ -n "$containerStatus" ]; then
        echo "   ✓ GPS Kiosk container: $containerStatus"
    else
        echo "   ✗ GPS Kiosk container not running"
        allContainers=$(docker ps -a --filter "name=gps-kiosk" --format "{{.Status}}")
        if [ -n "$allContainers" ]; then
            echo "      Container exists but stopped: $allContainers"
        else
            echo "      Container doesn't exist - setup may have failed"
        fi
    fi
else
    echo "   ✗ Docker not available or not running"
fi

# Check web interface accessibility
echo ""
echo "4. Checking GPS Kiosk web interface..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/signalk/ 2>/dev/null | grep -q "200"; then
    echo "   ✓ Web interface accessible (HTTP 200)"
else
    echo "   ✗ Web interface not accessible"
    echo "      Try: curl -I http://localhost:3000/signalk/"
fi

# Check browser availability
echo ""
echo "5. Checking browsers..."
browsers=("chromium-browser" "chromium" "google-chrome" "firefox")
browserFound=false
for browser in "${browsers[@]}"; do
    if command -v "$browser" &>/dev/null; then
        echo "   ✓ Found: $browser ($(command -v $browser))"
        browserFound=true
    fi
done

if [ "$browserFound" = false ]; then
    echo "   ✗ No supported browsers found"
    echo "      Install chromium or firefox for kiosk mode"
fi

# Check auto-login configuration
echo ""
echo "6. Checking auto-login configuration..."
if [ -f /etc/gdm3/custom.conf ] && grep -q "AutomaticLoginEnable.*true" /etc/gdm3/custom.conf; then
    autologinUser=$(grep "AutomaticLogin=" /etc/gdm3/custom.conf | cut -d= -f2)
    echo "   ✓ Auto-login enabled (GDM3) for: $autologinUser"
elif [ -f /etc/lightdm/lightdm.conf ] && grep -q "autologin-user=" /etc/lightdm/lightdm.conf; then
    autologinUser=$(grep "autologin-user=" /etc/lightdm/lightdm.conf | cut -d= -f2)
    echo "   ✓ Auto-login enabled (LightDM) for: $autologinUser"
else
    echo "   ⚠ Auto-login not configured (manual login required)"
fi

# Check display server
echo ""
echo "7. Checking display server..."
if [ -n "$DISPLAY" ]; then
    echo "   ✓ DISPLAY is set: $DISPLAY"
elif [ -n "$WAYLAND_DISPLAY" ]; then
    echo "   ✓ WAYLAND_DISPLAY is set: $WAYLAND_DISPLAY"
else
    echo "   ⚠ No display server detected (headless?)"
fi

echo ""
echo "=== Summary ==="

if [ -f "$startupScript" ]; then
    echo "✓ Setup appears to have completed - startup components created"
    
    if docker ps --filter "name=gps-kiosk" --format "{{.Status}}" 2>/dev/null | grep -q "Up"; then
        echo "✓ System is ready - try manual browser launch:"
        echo '   chromium-browser --kiosk "http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1" &'
    else
        echo "⚠ Containers not running - try:"
        echo "   cd $INSTALL_PATH"
        echo "   docker compose up -d"
    fi
else
    echo "✗ Setup incomplete - startup components missing"
    echo "   Try running setup again:"
    echo "   cd $INSTALL_PATH/unix"
    echo "   sudo ./quick-setup.sh"
fi

echo ""
echo "For detailed logs, check:"
echo "   docker logs gps-kiosk"
echo "   sudo journalctl -u gps-kiosk.service -n 50"
