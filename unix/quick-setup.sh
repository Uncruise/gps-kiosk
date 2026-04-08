#!/bin/bash
# GPS Kiosk - Complete Linux Setup
# Configures the account that ran sudo for passwordless auto-login.
# All files kept under /opt/ and /etc/ — no user home folders touched.

set -euo pipefail

INSTALL_PATH="/opt/gps-kiosk"
KIOSK_URL="http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1"

# ── Root check ────────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Run as root:  sudo bash $0"
    exit 1
fi

# Use the user who invoked sudo — that is the single kiosk account.
KIOSK_USER="${SUDO_USER:-}"
if [ -z "$KIOSK_USER" ] || [ "$KIOSK_USER" = "root" ]; then
    echo "ERROR: Run with sudo, not as root directly."
    echo "       Example:  sudo bash $0"
    exit 1
fi

echo "=== GPS Kiosk Setup ==="
echo "Kiosk user: $KIOSK_USER"
echo ""

# ── Install Docker ────────────────────────────────────────────────────────────
command_exists() { command -v "$1" &>/dev/null; }

if ! command_exists docker; then
    echo "Installing Docker..."
    if [ -f /etc/debian_version ]; then
        apt-get update -qq
        apt-get install -y ca-certificates curl gnupg
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
            | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
            | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update -qq
        apt-get install -y docker-ce docker-ce-cli containerd.io \
            docker-buildx-plugin docker-compose-plugin
    elif [ -f /etc/redhat-release ]; then
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io \
            docker-buildx-plugin docker-compose-plugin
    else
        echo "ERROR: Unsupported distro. Install Docker manually."
        echo "       https://docs.docker.com/engine/install/"
        exit 1
    fi
    systemctl enable --now docker
    echo "✓ Docker installed"
fi

usermod -aG docker "$KIOSK_USER"
echo "✓ $KIOSK_USER added to docker group"

# ── Install Git ───────────────────────────────────────────────────────────────
if ! command_exists git; then
    echo "Installing Git..."
    if [ -f /etc/debian_version ]; then
        apt-get install -y git
    elif [ -f /etc/redhat-release ]; then
        yum install -y git
    fi
fi

# ── Wait for Docker daemon ────────────────────────────────────────────────────
systemctl start docker
echo "Waiting for Docker daemon..."
until docker info &>/dev/null; do sleep 1; done

# ── Clone / update repo into /opt/ ───────────────────────────────────────────
mkdir -p "$INSTALL_PATH"
chown -R "$KIOSK_USER:$KIOSK_USER" "$INSTALL_PATH"

if [ -d "$INSTALL_PATH/.git" ]; then
    echo "Updating GPS Kiosk repo..."
    sudo -u "$KIOSK_USER" git -C "$INSTALL_PATH" pull
else
    echo "Cloning GPS Kiosk repo..."
    sudo -u "$KIOSK_USER" git clone https://github.com/Uncruise/gps-kiosk.git "$INSTALL_PATH"
fi

# ── Start GPS Kiosk container ─────────────────────────────────────────────────
echo "Pulling Docker images..."
sudo -u "$KIOSK_USER" docker compose -f "$INSTALL_PATH/docker-compose.yml" pull
echo "Starting GPS Kiosk container..."
sudo -u "$KIOSK_USER" docker compose -f "$INSTALL_PATH/docker-compose.yml" up -d
echo "✓ GPS Kiosk container started"

# ── systemd service ───────────────────────────────────────────────────────────
cat > /etc/systemd/system/gps-kiosk.service << EOF
[Unit]
Description=GPS Kiosk Navigation System
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=simple
User=$KIOSK_USER
WorkingDirectory=$INSTALL_PATH
ExecStartPre=/usr/bin/git -C $INSTALL_PATH pull
ExecStartPre=/usr/bin/docker compose -f $INSTALL_PATH/docker-compose.yml pull
ExecStart=/usr/bin/docker compose -f $INSTALL_PATH/docker-compose.yml up --force-recreate
ExecStop=/usr/bin/docker compose -f $INSTALL_PATH/docker-compose.yml down
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable gps-kiosk.service
echo "✓ GPS Kiosk systemd service enabled"

# ── Passwordless auto-login ───────────────────────────────────────────────────
if command_exists gdm3 || [ -f /etc/gdm3/custom.conf ]; then
    echo "Configuring GDM3 auto-login..."
    mkdir -p /etc/gdm3
    cat > /etc/gdm3/custom.conf << EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=$KIOSK_USER

[security]

[xdmcp]

[chooser]

[debug]
EOF
    echo "✓ GDM3 auto-login configured"

elif command_exists lightdm || [ -f /etc/lightdm/lightdm.conf ]; then
    echo "Configuring LightDM auto-login..."
    mkdir -p /etc/lightdm
    cat > /etc/lightdm/lightdm.conf << EOF
[Seat:*]
autologin-user=$KIOSK_USER
autologin-user-timeout=0
EOF
    groupadd -f nopasswdlogin
    usermod -aG nopasswdlogin "$KIOSK_USER"
    echo "✓ LightDM auto-login configured"

else
    echo "WARNING: No supported display manager found (GDM3 or LightDM)."
    echo "         Configure auto-login manually for your display manager."
fi

# ── Disable screen blanking ───────────────────────────────────────────────────
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/10-kiosk.conf << 'EOF'
Section "ServerFlags"
    Option "BlankTime"   "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime"     "0"
EndSection
EOF
echo "✓ Screen blanking disabled"

# ── Browser launcher (lives in /opt/) ────────────────────────────────────────
cat > "$INSTALL_PATH/launch-browser.sh" << EOF
#!/bin/bash
# Waits for GPS Kiosk service, then opens the browser in kiosk mode.
KIOSK_URL="$KIOSK_URL"

echo "Waiting for GPS Kiosk service..."
until curl -sf http://localhost:3000/signalk/ &>/dev/null; do
    sleep 2
done

xset s off     2>/dev/null || true
xset s noblank 2>/dev/null || true
xset -dpms     2>/dev/null || true

if command -v chromium-browser &>/dev/null; then
    exec chromium-browser --kiosk --no-first-run --disable-session-crashed-bubble \
        --disable-infobars --noerrdialogs --disable-translate "\$KIOSK_URL"
elif command -v chromium &>/dev/null; then
    exec chromium --kiosk --no-first-run --disable-session-crashed-bubble \
        --disable-infobars --noerrdialogs --disable-translate "\$KIOSK_URL"
elif command -v google-chrome &>/dev/null; then
    exec google-chrome --kiosk --no-first-run --disable-session-crashed-bubble \
        --disable-infobars --noerrdialogs --disable-translate "\$KIOSK_URL"
elif command -v firefox &>/dev/null; then
    exec firefox --kiosk "\$KIOSK_URL"
else
    echo "ERROR: No browser found. Install chromium or firefox."
    exit 1
fi
EOF
chmod +x "$INSTALL_PATH/launch-browser.sh"
echo "✓ Browser launcher written to $INSTALL_PATH/launch-browser.sh"

# ── System-wide autostart (in /etc/ — no user home folders) ──────────────────
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/gps-kiosk-browser.desktop << EOF
[Desktop Entry]
Type=Application
Name=GPS Kiosk Browser
Exec=$INSTALL_PATH/launch-browser.sh
X-GNOME-Autostart-enabled=true
Hidden=false
NoDisplay=false
EOF
echo "✓ Browser autostart configured (/etc/xdg/autostart/)"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "=== Setup Complete ==="
echo ""
echo "  User:       $KIOSK_USER (auto-login on boot)"
echo "  Kiosk URL:  $KIOSK_URL"
echo ""
echo "Reboot to start in kiosk mode:"
echo "  sudo reboot"
echo ""
