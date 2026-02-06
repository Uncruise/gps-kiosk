#!/bin/bash
# Test GPS Kiosk restart functionality without rebooting

echo "=== Testing GPS Kiosk Restart Sequence ==="

# Simulate restart by stopping everything
echo "1. Stopping GPS Kiosk containers..."
docker compose down

echo "2. Running startup script to simulate boot..."
INSTALL_PATH="/opt/gps-kiosk"
if [ ! -d "$INSTALL_PATH" ]; then
    INSTALL_PATH="$PWD"
fi

if [ -f "$INSTALL_PATH/start-gps-kiosk.sh" ]; then
    bash "$INSTALL_PATH/start-gps-kiosk.sh"
    echo "✓ Startup script completed"
else
    echo "✗ Startup script not found - run quick-setup.sh first"
    exit 1
fi

echo ""
echo "Test complete. Check that:"
echo "- Docker containers are running: docker ps"
echo "- Web interface works: curl -I http://localhost:3000"
echo "- Browser launched (if DISPLAY is set)"
