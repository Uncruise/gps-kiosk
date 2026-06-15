#!/bin/bash
# =============================================================================
# UnCruise Kiosk Quick Setup
# Ubuntu 24.04 (Noble) GNOME
# Run as: sudo bash kiosk-quick-setup.sh <admin_user>
# Example: sudo bash kiosk-quick-setup.sh gpskiosk
# =============================================================================

set -e

ADMIN_USER=${1:-gpskiosk}
ADMIN_UID=$(id -u $ADMIN_USER 2>/dev/null || echo "1000")

echo "============================================="
echo " Kiosk Quick Setup: user=$ADMIN_USER"
echo "============================================="

# -----------------------------------------------------------------------------
# 1. Install SSH
# -----------------------------------------------------------------------------
echo "[1/8] Installing SSH..."
DEBIAN_FRONTEND=noninteractive apt update -q
DEBIAN_FRONTEND=noninteractive apt install -y openssh-server net-tools pulseaudio-utils
systemctl enable --now ssh
echo "      SSH installed and running on port 22."

# -----------------------------------------------------------------------------
# 2. Firewall
# -----------------------------------------------------------------------------
echo "[2/8] Configuring firewall..."
ufw --force enable
ufw allow 22/tcp
ufw reload
echo "      Firewall rules applied."

# -----------------------------------------------------------------------------
# 3. Kill and block gnome-remote-desktop
# -----------------------------------------------------------------------------
echo "[3/8] Blocking gnome-remote-desktop..."
pkill -9 -f gnome-remote-desktop 2>/dev/null || true
systemctl disable gnome-remote-desktop 2>/dev/null || true
systemctl mask gnome-remote-desktop 2>/dev/null || true

# Block for admin user
sudo -u $ADMIN_USER mkdir -p /home/$ADMIN_USER/.config/systemd/user/
cat > /home/$ADMIN_USER/.config/systemd/user/gnome-remote-desktop.service << EOF
[Unit]
Description=Masked gnome-remote-desktop
[Service]
ExecStart=/bin/true
EOF

sudo -u $ADMIN_USER mkdir -p /home/$ADMIN_USER/.config/autostart/
cat > /home/$ADMIN_USER/.config/autostart/gnome-remote-desktop.desktop << EOF
[Desktop Entry]
Hidden=true
EOF

chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.config
echo "      gnome-remote-desktop blocked."

# -----------------------------------------------------------------------------
# 4. Disable Wayland + set autologin (fixes ScreenConnect black/static screen)
# -----------------------------------------------------------------------------
echo "[4/8] Configuring GDM..."
if grep -q "WaylandEnable" /etc/gdm3/custom.conf; then
    sed -i 's/.*WaylandEnable.*/WaylandEnable=false/' /etc/gdm3/custom.conf
else
    sed -i '/\[daemon\]/a WaylandEnable=false' /etc/gdm3/custom.conf
fi

if grep -q "AutomaticLogin=" /etc/gdm3/custom.conf; then
    sed -i "s/AutomaticLogin=.*/AutomaticLogin=$ADMIN_USER/" /etc/gdm3/custom.conf
    sed -i "s/AutomaticLoginEnable=.*/AutomaticLoginEnable=true/" /etc/gdm3/custom.conf
else
    sed -i '/\[daemon\]/a AutomaticLoginEnable=true' /etc/gdm3/custom.conf
    sed -i "/\[daemon\]/a AutomaticLogin=$ADMIN_USER" /etc/gdm3/custom.conf
fi
echo "      Wayland disabled, autologin set to $ADMIN_USER."

# -----------------------------------------------------------------------------
# 5. Disable sleep and screen lock
# -----------------------------------------------------------------------------
echo "[5/8] Disabling sleep and screen lock..."
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

mkdir -p /etc/polkit-1/localauthority/50-local.d
cat > /etc/polkit-1/localauthority/50-local.d/disable-lock.pkla << EOF
[Disable lock screen password]
Identity=unix-user:$ADMIN_USER
Action=org.freedesktop.login1.suspend;org.gnome.desktop.screensaver.lock
ResultAny=yes
ResultInactive=yes
ResultActive=yes
EOF

cat > /home/$ADMIN_USER/.config/autostart/disable-lock.desktop << EOF
[Desktop Entry]
Type=Application
Name=Disable Lock and Sleep
Exec=bash -c 'gsettings set org.gnome.desktop.screensaver lock-enabled false; gsettings set org.gnome.desktop.session idle-delay 0; gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0; gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0; gsettings set org.gnome.settings-daemon.plugins.power idle-dim false; gsettings set org.gnome.desktop.screensaver ubuntu-lock-on-suspend false'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
chown $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.config/autostart/disable-lock.desktop
echo "      Sleep and screen lock disabled."

# -----------------------------------------------------------------------------
# 6. Mute audio
# -----------------------------------------------------------------------------
echo "[6/8] Muting audio..."
sudo -u $ADMIN_USER XDG_RUNTIME_DIR=/run/user/$ADMIN_UID wpctl set-mute @DEFAULT_AUDIO_SINK@ 1 2>/dev/null || \
sudo -u $ADMIN_USER XDG_RUNTIME_DIR=/run/user/$ADMIN_UID pactl set-sink-mute @DEFAULT_SINK@ 1 2>/dev/null || \
echo "      [WARN] Could not mute audio — run manually after login."
echo "      Audio muted."

# -----------------------------------------------------------------------------
# 7. Suppress kernel update notifications
# -----------------------------------------------------------------------------
echo "[7/8] Suppressing kernel/update notifications..."

# needrestart: switch from interactive (i) to automatic (a) — no restart prompts
if [ -f /etc/needrestart/needrestart.conf ]; then
    sed -i "s/#\?\\\$nrconf{restart}.*$/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
    sed -i "s/#\?\\\$nrconf{kernelhints}.*$/\$nrconf{kernelhints} = 0;/" /etc/needrestart/needrestart.conf
else
    mkdir -p /etc/needrestart
    cat > /etc/needrestart/needrestart.conf << 'EOF'
$nrconf{restart} = 'a';
$nrconf{kernelhints} = 0;
EOF
fi

# Stop apt background update timers so they don't trigger needrestart mid-session
systemctl disable --now apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true

# Hide GNOME update-notifier for this user
cat > /home/$ADMIN_USER/.config/autostart/update-notifier.desktop << 'EOF'
[Desktop Entry]
Hidden=true
EOF
chown $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.config/autostart/update-notifier.desktop
echo "      Kernel/update notifications suppressed."

# -----------------------------------------------------------------------------
# 8. Daily restart at 3:00 AM
# -----------------------------------------------------------------------------
echo "[8/8] Scheduling daily 3 AM restart..."

cat > /etc/systemd/system/kiosk-daily-restart.service << 'EOF'
[Unit]
Description=GPS Kiosk Daily Restart

[Service]
Type=oneshot
ExecStart=/sbin/reboot
EOF

cat > /etc/systemd/system/kiosk-daily-restart.timer << 'EOF'
[Unit]
Description=GPS Kiosk Daily Restart at 3 AM

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now kiosk-daily-restart.timer
echo "      Daily restart scheduled at 3:00 AM."

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo ""
echo "============================================="
echo " Setup Complete — Reboot Required"
echo "============================================="
echo " SSH:             port 22"
echo " Wayland:         disabled (X11 enforced)"
echo " Sleep:           disabled"
echo " Lock:            disabled"
echo " Autologin:       $ADMIN_USER"
echo " Audio:           muted"
echo " Update popups:   suppressed"
echo " Daily restart:   3:00 AM"
echo "============================================="
echo ""

read -p "Reboot now? (y/n): " REBOOT
if [[ "$REBOOT" == "y" ]]; then
    sudo systemctl restart gdm3
    sleep 3
    reboot
else
    echo "Run 'sudo systemctl restart gdm3 && sudo reboot' when ready."
fi

