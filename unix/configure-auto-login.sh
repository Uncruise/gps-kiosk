#!/bin/bash
# GPS Kiosk Auto-Login and Kiosk Mode Configuration for Linux
# This script configures Linux for unattended GPS Kiosk operation

# Default parameters
USERNAME=""
PASSWORD=""
DISABLE_UPDATES=false
SHOW_CURRENT=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --username)
            USERNAME="$2"
            shift 2
            ;;
        --password)
            PASSWORD="$2"
            shift 2
            ;;
        --disable-updates)
            DISABLE_UPDATES=true
            shift
            ;;
        --show-current)
            SHOW_CURRENT=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 --username <user> --password <pass> [--disable-updates] [--show-current]"
            exit 1
            ;;
    esac
done

echo "=== GPS Kiosk Auto-Login Configuration ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

if [ "$SHOW_CURRENT" = true ]; then
    echo "=== Current Auto-Login Configuration ==="
    
    # Check for common display managers
    if [ -f "/etc/gdm3/custom.conf" ]; then
        echo "Display Manager: GDM3"
        if grep -q "AutomaticLoginEnable.*true" /etc/gdm3/custom.conf; then
            autologin_user=$(grep "AutomaticLogin=" /etc/gdm3/custom.conf | cut -d= -f2)
            echo "✓ Auto-Login: ENABLED for user '$autologin_user'"
        else
            echo "✗ Auto-Login: DISABLED"
        fi
    elif [ -f "/etc/lightdm/lightdm.conf" ]; then
        echo "Display Manager: LightDM"
        if grep -q "autologin-user=" /etc/lightdm/lightdm.conf; then
            autologin_user=$(grep "autologin-user=" /etc/lightdm/lightdm.conf | cut -d= -f2)
            echo "✓ Auto-Login: ENABLED for user '$autologin_user'"
        else
            echo "✗ Auto-Login: DISABLED"
        fi
    fi
    
    # Check startup configuration
    startup_script="/opt/gps-kiosk/start-gps-kiosk.sh"
    if [ -f "$startup_script" ]; then
        echo "✓ Startup script exists: $startup_script"
    else
        echo "✗ Startup script missing: $startup_script"
    fi
    
    # Check systemd service
    if systemctl is-enabled gps-kiosk.service &>/dev/null; then
        echo "✓ GPS Kiosk service: ENABLED"
    else
        echo "✗ GPS Kiosk service: NOT ENABLED"
    fi
    
    exit 0
fi

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "ERROR: Username and password are required"
    echo "Usage: $0 --username <user> --password <pass>"
    exit 1
fi

echo "Configuring auto-login for user: $USERNAME"

# Detect display manager and configure auto-login
if command -v gdm3 &>/dev/null || [ -f "/etc/gdm3/custom.conf" ]; then
    echo "Configuring GDM3 for auto-login..."
    
    if [ ! -f "/etc/gdm3/custom.conf" ]; then
        mkdir -p /etc/gdm3
        cat > /etc/gdm3/custom.conf << EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=$USERNAME

[security]

[xdmcp]

[chooser]

[debug]
EOF
    else
        sed -i "s/^AutomaticLoginEnable=.*/AutomaticLoginEnable=true/" /etc/gdm3/custom.conf
        sed -i "s/^AutomaticLogin=.*/AutomaticLogin=$USERNAME/" /etc/gdm3/custom.conf
        
        if ! grep -q "AutomaticLoginEnable" /etc/gdm3/custom.conf; then
            sed -i "/\[daemon\]/a AutomaticLoginEnable=true\nAutomaticLogin=$USERNAME" /etc/gdm3/custom.conf
        fi
    fi
    
    echo "✓ GDM3 auto-login configured for: $USERNAME"
    
elif command -v lightdm &>/dev/null || [ -f "/etc/lightdm/lightdm.conf" ]; then
    echo "Configuring LightDM for auto-login..."
    
    if [ ! -f "/etc/lightdm/lightdm.conf" ]; then
        mkdir -p /etc/lightdm
        cat > /etc/lightdm/lightdm.conf << EOF
[Seat:*]
autologin-user=$USERNAME
autologin-user-timeout=0
EOF
    else
        sed -i "s/^autologin-user=.*/autologin-user=$USERNAME/" /etc/lightdm/lightdm.conf
        sed -i "s/^autologin-user-timeout=.*/autologin-user-timeout=0/" /etc/lightdm/lightdm.conf
        
        if ! grep -q "autologin-user=" /etc/lightdm/lightdm.conf; then
            sed -i "/\[Seat:\*\]/a autologin-user=$USERNAME\nautologin-user-timeout=0" /etc/lightdm/lightdm.conf
        fi
    fi
    
    echo "✓ LightDM auto-login configured for: $USERNAME"
else
    echo "WARNING: No supported display manager found (GDM3 or LightDM)"
    echo "Auto-login may need to be configured manually"
fi

# Configure display power settings
echo "Configuring display settings for kiosk mode..."

# Disable screen blanking and power management
if [ -d "/etc/X11/xorg.conf.d" ]; then
    cat > /etc/X11/xorg.conf.d/10-monitor.conf << 'EOF'
Section "ServerFlags"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection
EOF
    echo "✓ X11 power management disabled"
fi

# Create systemd service for GPS Kiosk
echo "Creating GPS Kiosk systemd service..."
cat > /etc/systemd/system/gps-kiosk.service << EOF
[Unit]
Description=GPS Kiosk Navigation System
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=$USERNAME
ExecStart=/opt/gps-kiosk/start-gps-kiosk.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable gps-kiosk.service

echo "✓ GPS Kiosk service created and enabled"
echo ""
echo "=== Configuration Complete ==="
echo "System will auto-login as $USERNAME and start GPS Kiosk on boot"
echo ""
echo "To test without rebooting:"
echo "  sudo systemctl start gps-kiosk.service"
