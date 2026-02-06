#!/bin/bash
# Docker Diagnostic Script for GPS Kiosk
# Run this script to diagnose Docker issues

FIX=false
if [ "$1" = "--fix" ]; then
    FIX=true
fi

echo "=== GPS Kiosk Docker Diagnostic ==="
echo ""

issues=()

# Check 1: Docker Installation
echo "1. Checking Docker installation..."
if command -v docker &>/dev/null; then
    echo "   [OK] Docker is installed"
else
    echo "   [ERROR] Docker not found"
    issues+=("Docker is not installed")
fi

# Check 2: Docker Service
echo "2. Checking Docker service..."
if systemctl is-active --quiet docker 2>/dev/null; then
    echo "   [OK] Docker service is running"
elif service docker status &>/dev/null; then
    echo "   [OK] Docker service is running"
else
    echo "   [ERROR] Docker service not running"
    issues+=("Docker service is not running")
    
    if [ "$FIX" = true ]; then
        echo "   [FIX] Starting Docker service..."
        if [ "$EUID" -eq 0 ]; then
            systemctl start docker || service docker start
        else
            sudo systemctl start docker || sudo service docker start
        fi
        sleep 5
    fi
fi

# Check 3: Docker Daemon
echo "3. Checking Docker daemon..."
if docker info &>/dev/null; then
    version=$(docker version --format '{{.Server.Version}}' 2>/dev/null)
    echo "   [OK] Docker daemon is responding (version: $version)"
else
    echo "   [ERROR] Docker daemon is not responding"
    echo "   Error: $(docker info 2>&1 | head -n 1)"
    issues+=("Docker daemon is not accessible")
fi

# Check 4: Docker Compose
echo "4. Checking Docker Compose..."
if docker compose version &>/dev/null; then
    composeVersion=$(docker compose version --short 2>/dev/null)
    echo "   [OK] Docker Compose is available (version: $composeVersion)"
elif command -v docker-compose &>/dev/null; then
    composeVersion=$(docker-compose version --short 2>/dev/null)
    echo "   [OK] Docker Compose is available (version: $composeVersion)"
else
    echo "   [ERROR] Docker Compose is not available"
    issues+=("Docker Compose is not working")
fi

# Check 5: User Permissions
echo "5. Checking user permissions..."
if [ "$EUID" -eq 0 ]; then
    echo "   [OK] Running as root"
elif groups | grep -q docker; then
    echo "   [OK] User is in docker group"
else
    echo "   [WARNING] User is not in docker group"
    issues+=("User needs to be added to docker group (run: sudo usermod -aG docker \$USER)")
fi

# Check 6: Docker Storage
echo "6. Checking Docker storage..."
if docker info &>/dev/null; then
    storage_driver=$(docker info --format '{{.Driver}}' 2>/dev/null)
    echo "   [OK] Storage driver: $storage_driver"
else
    echo "   [WARNING] Cannot check Docker storage"
fi

# Summary
echo ""
echo "=== DIAGNOSTIC SUMMARY ==="
if [ ${#issues[@]} -eq 0 ]; then
    echo "[SUCCESS] All checks passed! Docker should be working properly."
    echo ""
    echo "If you're still having issues, try:"
    echo "* Restart Docker: sudo systemctl restart docker"
    echo "* Restart your computer"
    echo "* Check Docker logs: sudo journalctl -u docker"
else
    echo "[ISSUES] Found ${#issues[@]} issue(s):"
    for issue in "${issues[@]}"; do
        echo "   * $issue"
    done
    
    echo ""
    echo "=== RECOMMENDED FIXES ==="
    
    if [[ " ${issues[@]} " =~ "Docker is not installed" ]]; then
        echo "[INSTALL] Install Docker:"
        echo "   Visit: https://docs.docker.com/engine/install/"
    fi
    
    if [[ " ${issues[@]} " =~ "Docker service is not running" ]]; then
        echo "[START] Start Docker service:"
        echo "   sudo systemctl start docker"
        echo "   Or run this script with --fix parameter"
    fi
    
    if [[ " ${issues[@]} " =~ "Docker daemon is not accessible" ]]; then
        echo "[FIX] Fix Docker Daemon:"
        echo "   * Wait for Docker to fully start"
        echo "   * Try restarting: sudo systemctl restart docker"
        echo "   * Check logs: sudo journalctl -u docker -n 50"
        echo "   * Try running as root"
    fi
    
    if [[ " ${issues[@]} " =~ "User needs to be added to docker group" ]]; then
        echo "[FIX] Add user to docker group:"
        echo "   sudo usermod -aG docker \$USER"
        echo "   Then log out and back in"
    fi
fi

echo ""
exit ${#issues[@]}
