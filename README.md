# GPS Kiosk — Marine Navigation System

A containerized marine navigation kiosk built on Signal K technology. Runs Signal K Server + Freeboard-SK in Docker, auto-updates on every restart, and launches a browser in full-screen kiosk mode.

Docker Hub image: `morrisuca/gps-kiosk:latest`

---

## Installing on a New Machine

Assumes Ubuntu 24.04 is already installed and you are logged in as `gpskiosk`.

### Step 1 — Clone the repo

```bash
sudo apt-get install -y git
sudo git clone https://github.com/Uncruise/gps-kiosk.git /opt/gps-kiosk
```

### Step 2 — Run the full setup

```bash
sudo bash /opt/gps-kiosk/unix/quick-setup.sh
```

Installs Docker, pulls the container image, configures autologin, and registers the systemd services. Takes 5–15 minutes.

### Step 3 — Run the GNOME kiosk tuning

```bash
sudo bash /opt/gps-kiosk/unix/kiosk-quick-setup.sh gpskiosk
```

Configures Ubuntu 24.04 GNOME for unattended kiosk operation: disables Wayland, enables SSH, disables sleep/lock, fixes keyring autologin, suppresses update popups, and schedules a daily 3 AM restart.

When prompted **"Reboot now? (y/n)"** — type `n`.

### Step 4 — Reboot

```bash
sudo reboot
```

After reboot the machine logs in as `gpskiosk` automatically and the navigation display opens full-screen within 30–60 seconds.

---

## Verifying the Install

```bash
sudo systemctl status gps-kiosk.service       # should be active
sudo systemctl status gps-kiosk-setup.service # should be active
docker ps                                      # gps-kiosk container running
curl -sf http://localhost:3000/signalk/        # returns JSON
```

---

## Re-bootstrapping an Existing Machine

For machines deployed before the auto-update checker (`gps-kiosk-setup.service`) was added, run `quick-setup.sh` once to install it. After that, future changes to `kiosk-quick-setup.sh` apply automatically on reboot.

```bash
sudo bash /opt/gps-kiosk/unix/quick-setup.sh
```

To check if a machine needs re-bootstrapping:

```bash
systemctl status gps-kiosk-setup.service
# "could not be found" → run quick-setup.sh
# "active" or "inactive" → already bootstrapped
```

---

## How Auto-Updates Work

On every reboot:

1. `gps-kiosk-setup.service` (root) runs `git pull` on `/opt/gps-kiosk`
2. If `unix/kiosk-quick-setup.sh` changed, it re-runs automatically and updates the stored hash
3. `gps-kiosk.service` pulls the latest Docker image and starts the container
4. Inside the container, `startup.sh` clones the repo and overwrites `Volume/` from GitHub

**Push a change to `Volume/` or `unix/kiosk-quick-setup.sh` → deployed on next reboot with no manual steps.**

Watch it run: `sudo journalctl -t gps-kiosk-setup -f`

---

## Common Commands

```bash
# Container
docker compose pull && docker compose up -d
docker logs -f gps-kiosk
docker inspect gps-kiosk --format='{{.State.Health.Status}}'

# Services
sudo systemctl status gps-kiosk.service
sudo journalctl -u gps-kiosk.service -f
sudo journalctl -t gps-kiosk-setup -f
```

---

## Configuration

### NMEA Data Sources

Edit `Volume/settings.json` to add or change instrument TCP connections. Each `pipedProviders` entry is an NMEA 0183 TCP stream. Push to GitHub — takes effect on next container restart.

### Dashboard Layout

Edit `Volume/applicationData/users/admin/freeboard/1.0.0.json` for map center, zoom, and chart layers.

---

## Web Interfaces

| Interface | URL |
|-----------|-----|
| Navigation (kiosk) | `http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1` |
| Signal K API | `http://localhost:3000/signalk/` |
| Admin panel | `http://localhost:3000/admin/` |

---

## Fleet Management

Update multiple machines remotely over SSH:

```bash
bash unix/update-fleet.sh --computers host1,host2,host3 --user gpskiosk --key ~/.ssh/id_rsa
bash unix/verify-update.sh
```

---

## Building the Docker Image

```bash
docker build -t morrisuca/gps-kiosk:latest .
docker push morrisuca/gps-kiosk:latest
```
