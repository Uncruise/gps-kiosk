# GPS Kiosk — Unix/Linux Scripts

Shell scripts for setting up and managing the GPS Kiosk on Ubuntu/Debian and other Linux systems.

## Setup Scripts

| Script | Purpose |
|--------|---------|
| `quick-setup.sh` | Full setup: installs Docker, clones repo, starts container, configures autologin and systemd services. Run once, then reboot. |
| `kiosk-quick-setup.sh` | Ubuntu 24.04 GNOME tuning: SSH, Wayland disable, sleep/lock off, keyring fix, update suppression, daily restart. Run after `quick-setup.sh`. |
| `download-setup.sh` | Same as `quick-setup.sh` but downloads the repo as a zip — use on machines without Git. |

### First-time setup

```bash
sudo bash /opt/gps-kiosk/unix/quick-setup.sh
sudo bash /opt/gps-kiosk/unix/kiosk-quick-setup.sh gpskiosk
sudo reboot
```

### Re-bootstrap an existing machine

If a machine was deployed before the `gps-kiosk-setup.service` auto-updater existed:

```bash
sudo bash /opt/gps-kiosk/unix/quick-setup.sh
```

After that, future changes to `kiosk-quick-setup.sh` are applied automatically on reboot.

---

## Configuration Scripts

| Script | Purpose |
|--------|---------|
| `configure-auto-login.sh` | Standalone autologin config (GDM3/LightDM) |
| `configure-gps-kiosk.sh` | Configure GPS data source and map settings |

```bash
# Change NMEA data source
./configure-gps-kiosk.sh --gps-host 192.168.1.100 --gps-port 10110

# Change default map center
./configure-gps-kiosk.sh --map-lat 27.7634 --map-lon -6.8447 --map-zoom 15
```

---

## Diagnostic Scripts

| Script | Purpose |
|--------|---------|
| `docker-diagnostic.sh` | Diagnose Docker issues; `--fix` to auto-repair |
| `diagnose-deployment.sh` | Check deployment status and startup problems |
| `verify-update.sh` | Confirm auto-update is working |

```bash
bash unix/docker-diagnostic.sh --fix
bash unix/diagnose-deployment.sh
bash unix/verify-update.sh
```

---

## Service Control

```bash
sudo systemctl status gps-kiosk.service
sudo systemctl status gps-kiosk-setup.service
sudo journalctl -u gps-kiosk.service -f
sudo journalctl -t gps-kiosk-setup -f    # setup checker logs
```

---

## Docker Commands

```bash
docker compose pull && docker compose up -d
docker logs -f gps-kiosk
docker compose restart
```

---

## Fleet Management

Update multiple kiosks remotely over SSH:

```bash
bash unix/update-fleet.sh --computers host1,host2,host3 --user gpskiosk --key ~/.ssh/id_rsa
bash unix/verify-update.sh
```

---

## Serial Port Bridging

For instruments connected via a serial (RS-232) adapter instead of direct TCP:

```bash
bash unix/add-com2tcp-support.sh
```

Serial ports on Linux: `/dev/ttyS0`, `/dev/ttyS1`, `/dev/ttyUSB0`, etc.

---

## How Auto-Updates Work

On every reboot:

1. `gps-kiosk-setup.service` runs as root
2. It does `git pull` on `/opt/gps-kiosk`
3. It compares the sha256 of `unix/kiosk-quick-setup.sh` to `/var/lib/gps-kiosk/setup.hash`
4. If the hash changed, it re-runs `kiosk-quick-setup.sh` automatically and updates the stored hash
5. `gps-kiosk.service` then pulls the latest Docker image and starts the container

To watch it run: `sudo journalctl -t gps-kiosk-setup -f`

---

## Supported Distributions

- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12
- Raspberry Pi OS (Bullseye, Bookworm)
- CentOS Stream 8, 9 / Fedora 38, 39 (Docker setup only; GNOME tuning is Ubuntu-specific)
