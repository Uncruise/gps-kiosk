# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GPS Kiosk is a containerized marine navigation system built on Signal K technology. It runs a Signal K Server + Freeboard-SK web UI inside Docker, auto-pulls the latest image and GitHub configuration on every restart, and launches a browser in kiosk mode for dedicated navigation displays.

Docker Hub image: `morrisuca/gps-kiosk:latest`

## Common Commands

### Container management
```bash
docker compose pull          # Pull latest image
docker compose up -d         # Start in background
docker compose down          # Stop
docker compose restart       # Restart
docker logs -f gps-kiosk     # Stream logs
docker inspect gps-kiosk --format='{{.State.Health.Status}}'  # Health check
```

### Build and publish Docker image
```bash
docker build -t morrisuca/gps-kiosk:latest .
docker push morrisuca/gps-kiosk:latest
```

### Setup (from repo root)
```bash
sudo bash unix/quick-setup.sh                           # Full setup / re-bootstrap
sudo bash unix/kiosk-quick-setup.sh <user>              # Ubuntu 24.04 GNOME tuning
sudo bash unix/docker-diagnostic.sh --fix               # Diagnose and repair Docker
sudo bash unix/verify-update.sh                         # Confirm auto-updates work
sudo systemctl status gps-kiosk.service
sudo journalctl -u gps-kiosk.service -f
sudo journalctl -t gps-kiosk-setup -f                  # Watch setup checker on boot
```

## Architecture

### Auto-update mechanism
On every reboot, two systemd services run in sequence:

1. **`gps-kiosk-setup.service`** (root) — runs `/opt/gps-kiosk/check-and-apply-setup.sh`:
   - `git pull` on `/opt/gps-kiosk`
   - Compares sha256 of `unix/kiosk-quick-setup.sh` to `/var/lib/gps-kiosk/setup.hash`
   - If hash changed, re-runs `kiosk-quick-setup.sh` automatically and updates the stored hash
2. **`gps-kiosk.service`** (kiosk user) — runs after the setup service:
   - `docker compose pull` then `docker compose up --force-recreate`

Inside the container, `startup.sh` clones the repo and **clears and replaces** `/home/node/.signalk` (which is the `./Volume` mount) with `Volume/` from GitHub. **Local-only edits to `./Volume` are overwritten on container restart — always push to GitHub first.**

### Bootstrapping existing machines
Machines set up before `gps-kiosk-setup.service` was added only have the old `gps-kiosk.service`. They need a one-time manual run of `quick-setup.sh` to install the setup checker. Check with:
```bash
systemctl status gps-kiosk-setup.service
# "could not be found" → needs quick-setup.sh run
```

### Configuration persistence
`./Volume` is mounted to `/home/node/.signalk` in the container. This directory is the Signal K server's data directory and contains:
- `settings.json` — NMEA data providers (TCP connections to GPS/wind instruments)
- `security.json` — Admin credentials (bcrypt), auth tokens, ACLs
- `package.json` — Installed plugins (Freeboard-SK v2.15.1)
- `applicationData/users/admin/freeboard/1.0.0.json` — Dashboard layout, map center, chart layers, display units

### NMEA provider IDs in settings.json
Each entry in `pipedProviders` connects to a vessel or sensor via TCP on port 23:
- `WND` — Wind instrument (172.16.1.89)
- `SEN` — Sensor (172.16.1.59)
- `WAV` — Wave (172.16.5.202)
- `WIL` — Wilderness vessel (192.168.5.26)
- `SFX` — Safari Explorer vessel (192.168.20.146)
- `SVO` — TCP server listener (tcpserver, no host — accepts inbound on port 10110)

### Ports
- `3000` — Signal K server / Freeboard-SK web UI
- `30` — Signal K data stream
- `10110` — NMEA 0183 TCP input

### Web interfaces
- Kiosk: `http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1`
- Signal K API: `http://localhost:3000/signalk/`
- Admin panel: `http://localhost:3000/admin/`

### GNOME kiosk tuning (`unix/kiosk-quick-setup.sh`)
Run once after `quick-setup.sh` on Ubuntu 24.04 machines. Handles:
- SSH install and firewall
- Blocks gnome-remote-desktop (conflicts with ScreenConnect)
- Disables Wayland (`WaylandEnable=false` in GDM config — required for ScreenConnect)
- Disables sleep, screen lock, screen blanking
- Configures GNOME keyring for passwordless autologin (fixes cascade of PKCS11/secrets/SSH agent errors)
- Suppresses `needrestart` kernel update prompts and apt background timers
- Installs a systemd timer for daily 3 AM reboot

After bootstrap, changes to this script are automatically re-applied on next reboot by `gps-kiosk-setup.service`.

### NMEA data flow
Physical GPS/wind devices → TCP connection → Signal K Server (NMEA parsing) → Signal K normalized data → Freeboard-SK web UI → kiosk browser

## Key files to know

| File | Role |
|------|------|
| `docker-compose.yml` | Service definition; `pull_policy: always` drives auto-updates |
| `Dockerfile` | Extends `signalk/signalk-server:latest`, installs git, copies `startup.sh` |
| `startup.sh` | Container entrypoint — clears config, syncs from GitHub, then starts Signal K |
| `unix/quick-setup.sh` | Full host setup: Docker, systemd services, autologin, browser launcher |
| `unix/kiosk-quick-setup.sh` | Ubuntu 24.04 GNOME tuning applied on first run and on every change via boot checker |
| `Volume/settings.json` | NMEA provider config — edit to add/remove vessel TCP connections |
| `Volume/security.json` | Auth tokens and admin password hash |
