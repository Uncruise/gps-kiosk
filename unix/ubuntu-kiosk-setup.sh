#!/bin/bash
# GPS Kiosk - Ubuntu All-in-One Setup Script
# Run once on a fresh Ubuntu machine; the system will reboot into a full-screen kiosk.
# Usage: sudo bash unix/ubuntu-kiosk-setup.sh [--admin-username <u>] [--username <u>] [--password <p>]
#                                              [--gps-host <h>] [--gps-port <p>]
#                                              [--map-lat <lat>] [--map-lon <lon>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PATH="/opt/gps-kiosk"
KIOSK_URL="http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
ADMIN_USERNAME="gpsadmin"   # sudo/management user; default: gpsadmin
USERNAME="gpskiosk"         # auto-login kiosk user; default: gpskiosk
PASSWORD=""
GPS_HOST=""
GPS_PORT=""
MAP_LAT=""
MAP_LON=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --admin-username) ADMIN_USERNAME="$2"; shift 2 ;;
        --username)       USERNAME="$2";        shift 2 ;;
        --password)       PASSWORD="$2";        shift 2 ;;
        --gps-host)       GPS_HOST="$2";        shift 2 ;;
        --gps-port)       GPS_PORT="$2";        shift 2 ;;
        --map-lat)        MAP_LAT="$2";         shift 2 ;;
        --map-lon)        MAP_LON="$2";         shift 2 ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--admin-username <u>] [--username <u>] [--password <p>] [--gps-host <h>] [--gps-port <p>] [--map-lat <lat>] [--map-lon <lon>]"
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Step 1: Preflight checks
# ---------------------------------------------------------------------------
echo "=== GPS Kiosk Ubuntu Setup ==="
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)."
    echo "Usage: sudo bash $0"
    exit 1
fi

if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    if [ "${ID:-}" != "ubuntu" ]; then
        echo "WARNING: This script is designed for Ubuntu but detected OS: ${ID:-unknown}"
        echo "Continuing anyway — some steps may not work correctly."
    else
        echo "Detected Ubuntu ${VERSION_ID:-}"
    fi
else
    echo "WARNING: Cannot detect OS (no /etc/os-release). Continuing..."
fi

# Prompt for missing required values (defaults already set above)
if [ -z "$PASSWORD" ]; then
    read -rsp "Password for '$USERNAME' (and '$ADMIN_USERNAME'): " PASSWORD
    echo ""
fi
if [ -z "$PASSWORD" ]; then
    echo "ERROR: Password is required."
    exit 1
fi

echo ""
echo "Admin user : $ADMIN_USERNAME"
echo "Kiosk user : $USERNAME"
echo "Install    : $INSTALL_PATH"
echo ""

# ---------------------------------------------------------------------------
# Step 2: System package installation
# ---------------------------------------------------------------------------
echo "--- Step 2: Installing system packages ---"

apt-get update -y

# Resolve chromium package name (differs across Ubuntu versions)
CHROMIUM_PKG=""
if apt-cache show chromium-browser &>/dev/null 2>&1; then
    CHROMIUM_PKG="chromium-browser"
elif apt-cache show chromium &>/dev/null 2>&1; then
    CHROMIUM_PKG="chromium"
else
    # Snap-based Ubuntu 22.04+ — chromium is installed via snap; use the snap name
    CHROMIUM_PKG=""
    echo "NOTE: chromium not in apt — will install via snap."
fi

PACKAGES=(
    docker.io
    docker-compose-plugin
    git
    curl
    unzip
    x11-xserver-utils
    xdotool
)
if [ -n "$CHROMIUM_PKG" ]; then
    PACKAGES+=("$CHROMIUM_PKG")
fi

apt-get install -y "${PACKAGES[@]}"

# Install chromium via snap if apt couldn't find it
if [ -z "$CHROMIUM_PKG" ]; then
    if command -v snap &>/dev/null; then
        snap install chromium
        CHROMIUM_PKG="chromium"
    else
        echo "WARNING: snap not available and chromium not in apt. Browser launch may fail."
    fi
fi

systemctl enable docker
systemctl start docker

echo "✓ Packages installed, Docker enabled."

# ---------------------------------------------------------------------------
# Step 3: Create admin user and kiosk user
# ---------------------------------------------------------------------------
echo ""
echo "--- Step 3: Creating users ---"

# Admin user (gpsadmin) — sudo + docker access for management
if id "$ADMIN_USERNAME" &>/dev/null; then
    echo "User '$ADMIN_USERNAME' already exists — skipping creation."
else
    useradd -m -s /bin/bash "$ADMIN_USERNAME"
    echo "✓ Admin user '$ADMIN_USERNAME' created."
fi
echo "$ADMIN_USERNAME:$PASSWORD" | chpasswd
usermod -aG sudo "$ADMIN_USERNAME" 2>/dev/null || usermod -aG wheel "$ADMIN_USERNAME" 2>/dev/null || true
for GRP in docker; do
    if getent group "$GRP" &>/dev/null; then
        usermod -aG "$GRP" "$ADMIN_USERNAME"
    fi
done
echo "✓ '$ADMIN_USERNAME' added to sudo + docker."

# Kiosk user (gpskiosk) — auto-login, runs the browser
if id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' already exists — skipping creation."
else
    useradd -m -s /bin/bash "$USERNAME"
    echo "✓ Kiosk user '$USERNAME' created."
fi
echo "$USERNAME:$PASSWORD" | chpasswd
for GRP in docker video audio; do
    if getent group "$GRP" &>/dev/null; then
        usermod -aG "$GRP" "$USERNAME"
    fi
done
echo "✓ Groups assigned to '$USERNAME': docker video audio."

# ---------------------------------------------------------------------------
# Step 4: Install GPS Kiosk (clone repo + start containers)
# ---------------------------------------------------------------------------
echo ""
echo "--- Step 4: Installing GPS Kiosk ---"

# Wait for Docker daemon
echo "Waiting for Docker daemon..."
ELAPSED=0
until docker info &>/dev/null; do
    sleep 2; ELAPSED=$((ELAPSED + 2))
    if [ "$ELAPSED" -ge 60 ]; then echo "ERROR: Docker daemon did not start."; exit 1; fi
done

mkdir -p "$INSTALL_PATH"
cd "$INSTALL_PATH"

if [ -d ".git" ]; then
    echo "Repository found — pulling latest..."
    git reset --hard HEAD
    git pull
else
    echo "Cloning GPS Kiosk repository..."
    git clone https://github.com/Uncruise/gps-kiosk.git .
fi

echo "Pulling Docker images..."
docker compose pull

echo "Starting GPS Kiosk containers..."
docker compose up -d

echo "Waiting for Signal K to be ready (up to 120 s)..."
ELAPSED=0
until curl -sf http://localhost:3000/signalk/ &>/dev/null; do
    sleep 2; ELAPSED=$((ELAPSED + 2))
    if [ "$ELAPSED" -ge 120 ]; then
        echo "WARNING: GPS Kiosk did not respond within 120 s — continuing anyway."
        break
    fi
done
echo "✓ GPS Kiosk containers running."

# Apply optional GPS / map configuration
if [ -n "$GPS_HOST" ] || [ -n "$MAP_LAT" ]; then
    CONFIGURE_SCRIPT="$SCRIPT_DIR/configure-gps-kiosk.sh"
    if [ -f "$CONFIGURE_SCRIPT" ]; then
        CONF_ARGS=()
        [ -n "$GPS_HOST" ]  && CONF_ARGS+=(--gps-host  "$GPS_HOST")
        [ -n "$GPS_PORT" ]  && CONF_ARGS+=(--gps-port  "$GPS_PORT")
        [ -n "$MAP_LAT"  ]  && CONF_ARGS+=(--map-lat   "$MAP_LAT")
        [ -n "$MAP_LON"  ]  && CONF_ARGS+=(--map-lon   "$MAP_LON")
        bash "$CONFIGURE_SCRIPT" "${CONF_ARGS[@]}" || echo "WARNING: configure-gps-kiosk.sh exited non-zero."
    else
        echo "NOTE: configure-gps-kiosk.sh not found — skipping GPS/map config."
    fi
fi

# ---------------------------------------------------------------------------
# Step 5: Write start-gps-kiosk.sh with headless-safe browser launch
# ---------------------------------------------------------------------------
echo ""
echo "--- Step 5: Writing start-gps-kiosk.sh ---"

cat > "$INSTALL_PATH/start-gps-kiosk.sh" << EOFSTART
#!/bin/bash
# GPS Kiosk Auto-Startup Script — generated by ubuntu-kiosk-setup.sh
echo "Starting GPS Kiosk Auto-Startup..."
cd "\$(dirname "\$0")"

# Ensure Docker is running
if ! docker info &>/dev/null; then
    echo "Starting Docker service..."
    sudo systemctl start docker
    ELAPSED=0
    until docker info &>/dev/null; do
        sleep 2; ELAPSED=\$((ELAPSED + 2))
        if [ "\$ELAPSED" -ge 60 ]; then echo "Docker failed to start"; exit 1; fi
    done
fi

# Update repository
if [ -d .git ]; then
    echo "Updating GPS Kiosk..."
    git reset --hard HEAD
    git pull
fi

# Pull latest image and restart containers
docker compose pull
docker compose up -d --force-recreate

# Wait for Signal K
echo "Waiting for GPS Kiosk to be ready..."
ELAPSED=0
until curl -sf http://localhost:3000/signalk/ &>/dev/null; do
    sleep 2; ELAPSED=\$((ELAPSED + 2))
    if [ "\$ELAPSED" -ge 120 ]; then echo "GPS Kiosk failed to start"; exit 1; fi
done
echo "GPS Kiosk is ready!"

# Set up display environment for systemd context
export DISPLAY=:0
export XAUTHORITY=/home/${USERNAME}/.Xauthority

# Wait for X server to be ready (up to 30 s)
for i in \$(seq 1 30); do
    xdpyinfo -display :0 &>/dev/null && break
    sleep 1
done

# Disable screen blanking / DPMS at runtime
xset -dpms s off s noblank 2>/dev/null || true

# Determine browser binary
BROWSER=""
for B in chromium-browser chromium google-chrome firefox; do
    if command -v "\$B" &>/dev/null; then
        BROWSER="\$B"
        break
    fi
done
# Also check snap chromium path
if [ -z "\$BROWSER" ] && [ -x /snap/bin/chromium ]; then
    BROWSER=/snap/bin/chromium
fi

if [ -z "\$BROWSER" ]; then
    echo "ERROR: No supported browser found. Please install chromium-browser."
    exit 1
fi

KIOSK_URL="${KIOSK_URL}"

if [ "\$BROWSER" = "firefox" ]; then
    "\$BROWSER" --kiosk "\$KIOSK_URL" &
else
    "\$BROWSER" --kiosk \
        --no-first-run \
        --disable-session-crashed-bubble \
        --disable-infobars \
        --noerrdialogs \
        "\$KIOSK_URL" &
fi
EOFSTART

chmod +x "$INSTALL_PATH/start-gps-kiosk.sh"
echo "✓ start-gps-kiosk.sh written."

# ---------------------------------------------------------------------------
# Step 6: Passwordless sudoers for kiosk user
# ---------------------------------------------------------------------------
echo ""
echo "--- Step 6: Configuring sudoers ---"

cat > /etc/sudoers.d/gps-kiosk << EOFSUDOERS
# GPS Kiosk — allow kiosk user to manage Docker and the kiosk service
${USERNAME} ALL=(ALL) NOPASSWD: /usr/bin/systemctl start docker, /usr/bin/systemctl stop docker, /usr/bin/docker
EOFSUDOERS

chmod 440 /etc/sudoers.d/gps-kiosk
echo "✓ /etc/sudoers.d/gps-kiosk written."

# ---------------------------------------------------------------------------
# Step 7: Configure auto-login + systemd service (delegate to existing script)
# ---------------------------------------------------------------------------
echo ""
echo "--- Step 7: Configuring auto-login and systemd service ---"

AUTO_LOGIN_SCRIPT="$SCRIPT_DIR/configure-auto-login.sh"
if [ -f "$AUTO_LOGIN_SCRIPT" ]; then
    bash "$AUTO_LOGIN_SCRIPT" --username "$USERNAME" --password "$PASSWORD"
else
    echo "WARNING: configure-auto-login.sh not found at $AUTO_LOGIN_SCRIPT"
    echo "Creating minimal systemd service manually..."

    cat > /etc/systemd/system/gps-kiosk.service << EOF
[Unit]
Description=GPS Kiosk Navigation System
After=network.target docker.service graphical.target
Requires=docker.service

[Service]
Type=simple
User=${USERNAME}
ExecStart=${INSTALL_PATH}/start-gps-kiosk.sh
Restart=always
RestartSec=10

[Install]
WantedBy=graphical.target
EOF
    systemctl daemon-reload
    systemctl enable gps-kiosk.service
fi

# Patch the service unit: add DISPLAY + XAUTHORITY and target graphical.target
SERVICE_FILE="/etc/systemd/system/gps-kiosk.service"
if [ -f "$SERVICE_FILE" ]; then
    # Add environment variables if not already present
    if ! grep -q "DISPLAY=:0" "$SERVICE_FILE"; then
        sed -i "/^\[Service\]/a Environment=DISPLAY=:0\nEnvironment=XAUTHORITY=/home/${USERNAME}/.Xauthority" "$SERVICE_FILE"
    fi
    # Ensure service waits for graphical session
    if grep -q "WantedBy=multi-user.target" "$SERVICE_FILE"; then
        sed -i "s/WantedBy=multi-user.target/WantedBy=graphical.target/" "$SERVICE_FILE"
    fi
    systemctl daemon-reload
    echo "✓ systemd service patched with DISPLAY and XAUTHORITY."
fi

# ---------------------------------------------------------------------------
# Step 8: Disable GNOME screen blanking / lock
# ---------------------------------------------------------------------------
echo ""
echo "--- Step 8: Disabling GNOME screen blanking ---"

if command -v gsettings &>/dev/null; then
    sudo -u "$USERNAME" gsettings set org.gnome.desktop.screensaver lock-enabled false  2>/dev/null || true
    sudo -u "$USERNAME" gsettings set org.gnome.desktop.session idle-delay 0            2>/dev/null || true
    echo "✓ GNOME screensaver/lock disabled."
else
    echo "NOTE: gsettings not found — skipping GNOME-specific settings."
fi

# ---------------------------------------------------------------------------
# Step 9: Disable system sleep / suspend
# ---------------------------------------------------------------------------
echo ""
echo "--- Step 9: Disabling system sleep and suspend ---"

LOGIND_CONF="/etc/systemd/logind.conf"
for KEY in IdleAction HandleLidSwitch HandleLidSwitchDocked; do
    if grep -q "^${KEY}=" "$LOGIND_CONF" 2>/dev/null; then
        sed -i "s/^${KEY}=.*/${KEY}=ignore/" "$LOGIND_CONF"
    elif grep -q "^#${KEY}=" "$LOGIND_CONF" 2>/dev/null; then
        sed -i "s/^#${KEY}=.*/${KEY}=ignore/" "$LOGIND_CONF"
    else
        echo "${KEY}=ignore" >> "$LOGIND_CONF"
    fi
done

systemctl restart systemd-logind 2>/dev/null || true
echo "✓ logind.conf updated (IdleAction, HandleLidSwitch → ignore)."

# Also mask sleep/hibernate targets for good measure
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null || true
echo "✓ Sleep/hibernate targets masked."

# ---------------------------------------------------------------------------
# Step 10: Final verification and summary
# ---------------------------------------------------------------------------
echo ""
echo "=== Final Verification ==="
echo ""

CHECK_PASS=0
CHECK_FAIL=0

check() {
    local LABEL="$1"
    local CMD="$2"
    if eval "$CMD" &>/dev/null; then
        printf "  ✓  %s\n" "$LABEL"
        CHECK_PASS=$((CHECK_PASS + 1))
    else
        printf "  ✗  %s\n" "$LABEL"
        CHECK_FAIL=$((CHECK_FAIL + 1))
    fi
}

check "Docker daemon running"           "docker info"
check "GPS Kiosk container running"     "docker ps --filter name=gps-kiosk --filter status=running | grep -q gps-kiosk"
check "Signal K responding"             "curl -sf http://localhost:3000/signalk/"
check "gps-kiosk.service enabled"       "systemctl is-enabled gps-kiosk.service"
check "start-gps-kiosk.sh executable"   "[ -x '$INSTALL_PATH/start-gps-kiosk.sh' ]"
check "Kiosk user exists"               "id '$USERNAME'"
check "sudoers file present"            "[ -f /etc/sudoers.d/gps-kiosk ]"

# Browser check
BROWSER_FOUND=false
for B in chromium-browser chromium google-chrome /snap/bin/chromium; do
    if command -v "$B" &>/dev/null || [ -x "$B" ]; then
        BROWSER_FOUND=true
        break
    fi
done
if $BROWSER_FOUND; then
    printf "  ✓  Browser binary found\n"; CHECK_PASS=$((CHECK_PASS + 1))
else
    printf "  ✗  Browser binary found\n"; CHECK_FAIL=$((CHECK_FAIL + 1))
fi

echo ""
echo "Results: $CHECK_PASS passed, $CHECK_FAIL failed."
echo ""
echo "Access URL: $KIOSK_URL"
echo ""

if [ "$CHECK_FAIL" -eq 0 ]; then
    echo "All checks passed."
else
    echo "Some checks failed — review the output above before rebooting."
fi

echo ""
echo "To test the full kiosk boot sequence, run:"
echo "  reboot"
