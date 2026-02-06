#!/bin/bash
# GPS Kiosk Auto-Setup Script for Linux/Unix
# Fully automated installation with Docker auto-install, latest pulls, and startup configuration

INSTALL_PATH="/opt/gps-kiosk"

echo "=== GPS Kiosk Auto-Setup ==="

# Check if running as root for system-level installation
if [ "$EUID" -ne 0 ]; then
    echo "WARNING: Not running as root. Installation will be in current directory."
    INSTALL_PATH="$PWD/gps-kiosk"
fi

# Function to check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Function to install Docker on various Linux distributions
install_docker() {
    echo "Docker not found. Installing Docker..."
    
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        echo "Detected Debian/Ubuntu system"
        apt-get update
        apt-get install -y ca-certificates curl gnupg
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        
        echo \
          "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
    elif [ -f /etc/redhat-release ]; then
        # RHEL/CentOS/Fedora
        echo "Detected RHEL/CentOS/Fedora system"
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
    elif [ -f /etc/arch-release ]; then
        # Arch Linux
        echo "Detected Arch Linux"
        pacman -Sy --noconfirm docker docker-compose
        
    else
        echo "Unsupported distribution. Please install Docker manually."
        echo "Visit: https://docs.docker.com/engine/install/"
        exit 1
    fi
    
    # Start and enable Docker service
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group (if not root)
    if [ "$EUID" -ne 0 ]; then
        usermod -aG docker "$SUDO_USER"
        echo "User added to docker group. You may need to log out and back in."
    fi
    
    echo "Docker installed successfully."
}

# Check and install Docker if needed
echo "Checking Docker..."
if ! command_exists docker; then
    if [ "$EUID" -eq 0 ]; then
        install_docker
    else
        echo "Docker not found and not running as root."
        echo "Please install Docker manually or run this script with sudo."
        exit 1
    fi
fi

# Ensure Docker service is running
if ! systemctl is-active --quiet docker; then
    echo "Starting Docker service..."
    systemctl start docker
fi

# Wait for Docker to be ready
echo "Waiting for Docker daemon..."
timeout=60
elapsed=0
until docker info &>/dev/null; do
    sleep 2
    elapsed=$((elapsed + 2))
    if [ $elapsed -ge $timeout ]; then
        echo "Docker daemon failed to start within timeout."
        exit 1
    fi
done
echo "Docker daemon is ready."

# Auto-install Git if needed
echo "Checking Git..."
if ! command_exists git; then
    echo "Git not found. Installing Git..."
    if [ -f /etc/debian_version ]; then
        apt-get update && apt-get install -y git
    elif [ -f /etc/redhat-release ]; then
        yum install -y git
    elif [ -f /etc/arch-release ]; then
        pacman -Sy --noconfirm git
    fi
fi

# Create installation directory
mkdir -p "$INSTALL_PATH"
cd "$INSTALL_PATH" || exit 1

# Clone or update repository
if [ -d ".git" ]; then
    echo "Repository exists. Pulling latest updates..."
    git pull
else
    echo "Cloning GPS Kiosk repository..."
    git clone https://github.com/Uncruise/gps-kiosk.git .
fi

# Pull latest Docker images
echo "Pulling latest Docker images..."
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

# Create startup script
cat > "$INSTALL_PATH/start-gps-kiosk.sh" << 'EOFSTART'
#!/bin/bash
# GPS Kiosk Auto-Startup Script - Runs on every boot
echo "Starting GPS Kiosk Auto-Startup..."
cd "$(dirname "$0")"

# Ensure Docker is running
if ! docker info &>/dev/null; then
    echo "Starting Docker service..."
    sudo systemctl start docker
    
    # Wait for Docker to be ready
    timeout=60
    elapsed=0
    until docker info &>/dev/null; do
        sleep 2
        elapsed=$((elapsed + 2))
        if [ $elapsed -ge $timeout ]; then
            echo "Docker failed to start"
            exit 1
        fi
    done
fi

# Update repository if Git is available
if [ -d .git ]; then
    echo "Updating GPS Kiosk to latest version..."
    git reset --hard HEAD
    git pull
fi

# Pull latest Docker images and start containers
echo "Pulling latest Docker images..."
docker compose pull
echo "Starting GPS Kiosk containers..."
docker compose up -d --force-recreate

# Wait for service
echo "Waiting for GPS Kiosk to be ready..."
timeout=120
elapsed=0
until curl -s http://localhost:3000/signalk/ &>/dev/null; do
    sleep 2
    elapsed=$((elapsed + 2))
    if [ $elapsed -ge $timeout ]; then
        echo "GPS Kiosk failed to start"
        exit 1
    fi
done

echo "GPS Kiosk is ready!"

# Launch browser in kiosk mode if DISPLAY is set
if [ -n "$DISPLAY" ]; then
    kioskUrl="http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1"
    
    if command -v chromium-browser &>/dev/null; then
        chromium-browser --kiosk --no-first-run --disable-session-crashed-bubble "$kioskUrl" &
    elif command -v chromium &>/dev/null; then
        chromium --kiosk --no-first-run --disable-session-crashed-bubble "$kioskUrl" &
    elif command -v google-chrome &>/dev/null; then
        google-chrome --kiosk --no-first-run --disable-session-crashed-bubble "$kioskUrl" &
    elif command -v firefox &>/dev/null; then
        firefox --kiosk "$kioskUrl" &
    else
        echo "No supported browser found for kiosk mode"
        echo "Please open: $kioskUrl"
    fi
fi
EOFSTART

chmod +x "$INSTALL_PATH/start-gps-kiosk.sh"

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "GPS Kiosk is accessible at:"
echo "  http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1"
echo ""
echo "To configure auto-start on boot:"
echo "  sudo ./configure-auto-login.sh --username <your-username> --password <your-password>"
echo ""
echo "Manual controls:"
echo "  Start: docker compose up -d"
echo "  Stop: docker compose down"
echo "  View logs: docker logs -f gps-kiosk"
echo ""
