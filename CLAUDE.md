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

### Windows setup (from repo root)
```powershell
.\Windows\setup.bat                          # Interactive setup
.\Windows\quick-setup.ps1                   # Fully automated
.\Windows\configure-auto-login.ps1 -Username "user" -Password "pass"
.\Windows\docker-diagnostic.ps1 -Fix        # Diagnose and repair Docker
.\Windows\verify-update.ps1                 # Confirm auto-updates work
```

### Unix/Linux setup
```bash
sudo bash unix/quick-setup.sh               # Fully automated
sudo bash unix/configure-auto-login.sh --username gps --password pass
bash unix/docker-diagnostic.sh --fix
sudo systemctl status gps-kiosk.service
sudo journalctl -u gps-kiosk.service -f
```

## Architecture

### Auto-update mechanism
`startup.sh` (container entrypoint) clones the GitHub repo on every container start, then **clears `/home/node/.signalk` and replaces it** with `Volume/` from the repo. Since `./Volume` is mounted into the container at that path, this also overwrites the local `./Volume` directory on the host. **Local-only changes to `./Volume` are lost on container restart — always push changes to GitHub first.**

The backup of the pre-restart config is stored at `/tmp/config-backup` inside the container (ephemeral).

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
- `SVO` — TCP server listener (tcpserver, no host — accepts inbound connections on port 10110)

### Ports
- `3000` — Signal K server / Freeboard-SK web UI
- `30` — Signal K data stream
- `10110` — NMEA 0183 TCP input

### Web interfaces
- Kiosk: `http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1`
- Signal K API: `http://localhost:3000/signalk/`
- Admin panel: `http://localhost:3000/admin/`

### Cross-platform scripts
`Windows/` and `unix/` contain equivalent scripts for all operations. `WINDOWS-UNIX-MAPPING.md` documents the correspondence. Windows uses PowerShell + Windows Task Scheduler + Registry (auto-login) + Microsoft Edge kiosk mode + `tools/com2tcp.exe` for COM-to-TCP bridging. Unix uses Bash + systemd + display manager config (GDM3/LightDM) + Chromium/Firefox.

Note: `unix/startup.sh` is the kiosk browser launcher (runs on the host OS to open the browser), which is separate from the container's `startup.sh` (the Signal K container entrypoint).

### Enterprise deployment
`intune/` contains install/detect/uninstall scripts for Microsoft Intune deployments that include Git and clone the repo. `docker-intune/` is a leaner variant that only installs Docker (no Git), suitable for machines that don't need Git. `tools/IntuneWinAppUtil.exe` is used to rebuild `.intunewin` packages; pre-built packages live in `intune_out/`.

### NMEA data flow
Physical GPS/wind devices → TCP connection → Signal K Server (NMEA parsing) → Signal K normalized data → Freeboard-SK web UI → kiosk browser

## Key files to know

| File | Role |
|------|------|
| `docker-compose.yml` | Service definition; `pull_policy: always` drives auto-updates |
| `Dockerfile` | Extends `signalk/signalk-server:latest`, installs git, copies `startup.sh` |
| `startup.sh` | Container entrypoint — clears config, syncs from GitHub, then starts Signal K |
| `Volume/settings.json` | NMEA provider config — edit to add/remove vessel TCP connections |
| `Volume/security.json` | Auth tokens and admin password hash |
