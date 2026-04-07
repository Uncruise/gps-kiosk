# GPS Kiosk - Unix/Linux Scripts

This directory contains Unix/Linux shell script versions of all the Windows PowerShell and batch scripts for the GPS Kiosk project.

## Quick Start

Run **one command** on any supported Linux machine and walk away — the system reboots
into a full-screen GPS Kiosk with no login prompt and no password required:

```bash
sudo bash unix/quick-setup.sh
```

This creates a single dedicated `kiosk` account with no password, configures auto-login,
starts the GPS Kiosk Docker container, and launches the browser in kiosk mode on every boot.

For a machine without Git installed:

```bash
cd unix
sudo bash download-setup.sh
```

## Script Descriptions

### Setup Scripts

- **quick-setup.sh** - **All-in-one setup**: creates the `kiosk` user (no password), installs Docker, clones the repo, starts the container, configures passwordless auto-login (GDM3/LightDM), enables the systemd service, disables screen blanking, and sets up the browser kiosk autostart. Run once; reboot into kiosk.
- **download-setup.sh** - Downloads GPS Kiosk from GitHub without requiring Git installation
- **configure-auto-login.sh** - Standalone script to configure auto-login if needed separately
- **configure-gps-kiosk.sh** - Configure GPS data source and map settings

### Diagnostic Scripts

- **docker-diagnostic.sh** - Diagnose Docker installation and runtime issues
- **diagnose-deployment.sh** - Check deployment status and troubleshoot startup problems
- **verify-update.sh** - Verify auto-update functionality is working correctly

### Utility Scripts

- **add-com2tcp-support.sh** - Add COM2TCP serial bridge support (for SVO-GPS systems)
- **test-restart.sh** - Test restart sequence without rebooting
- **update-fleet.sh** - Remotely update multiple GPS Kiosk deployments via SSH
- **build-intune-packages.sh** - Create deployment packages for distribution

## Requirements

### Minimum Requirements

- Docker Engine or Docker Desktop
- Bash shell
- One of: Debian/Ubuntu, RHEL/CentOS/Fedora, or Arch Linux
- Internet connection (for initial setup)

### Optional Requirements

- Git (recommended, but download-setup.sh works without it)
- jq (for configure-gps-kiosk.sh to work)
- systemd (for auto-start on boot)
- X11 or Wayland display server (for kiosk mode browser)

## Installation Paths

By default, scripts install to:

- **Root installation**: `/opt/gps-kiosk` (when run with sudo)
- **User installation**: `~/gps-kiosk` or current directory (when run as regular user)

## Auto-Start Configuration

Auto-login, the systemd service, and browser kiosk launch are all configured automatically
by `quick-setup.sh`. After running it, the machine boots directly into the kiosk display
with no login prompt.

The setup creates:
- `kiosk` user account (no password)
- GDM3 or LightDM auto-login for the `kiosk` user
- `gps-kiosk.service` systemd unit (enabled at boot)
- `/opt/gps-kiosk/launch-browser.sh` — waits for Signal K, then opens browser in `--kiosk` mode
- `~/.config/autostart/gps-kiosk-browser.desktop` — triggers the browser launcher on desktop login

## Manual Service Control

```bash
# Start GPS Kiosk service
sudo systemctl start gps-kiosk.service

# Stop GPS Kiosk service
sudo systemctl stop gps-kiosk.service

# View service status
sudo systemctl status gps-kiosk.service

# View service logs
sudo journalctl -u gps-kiosk.service -f
```

## Docker Commands

```bash
# Start containers
docker compose up -d

# Stop containers
docker compose down

# View logs
docker logs -f gps-kiosk

# Restart containers
docker compose restart

# Pull latest images
docker compose pull
```

## Configuration

### GPS Data Source

Configure the GPS data source (TCP/IP, serial port, etc.):

```bash
./configure-gps-kiosk.sh --gps-host 192.168.1.100 --gps-port 10110
```

### Map Settings

Configure default map center and zoom level:

```bash
./configure-gps-kiosk.sh --map-lat 27.7634 --map-lon -6.8447 --map-zoom 15
```

### View Current Configuration

```bash
./configure-gps-kiosk.sh --show-current
```

## Troubleshooting

### Docker Issues

Run the diagnostic script:

```bash
./docker-diagnostic.sh
```

To automatically fix common issues:

```bash
./docker-diagnostic.sh --fix
```

### Deployment Issues

Check deployment status:

```bash
./diagnose-deployment.sh
```

### Permission Issues

Add your user to the docker group:

```bash
sudo usermod -aG docker $USER
```

Then log out and back in.

### Service Won't Start

Check service logs:

```bash
sudo journalctl -u gps-kiosk.service -n 50
```

Check Docker logs:

```bash
docker logs gps-kiosk
```

## Fleet Management

To update multiple GPS Kiosk systems remotely:

```bash
./update-fleet.sh --computers host1,host2,host3 --user admin --key ~/.ssh/id_rsa
```

After updating, verify each system:

```bash
./verify-update.sh
```

## Differences from Windows Scripts

1. **Docker Desktop vs Docker Engine**: Linux scripts work with Docker Engine (native) or Docker Desktop
2. **Display Managers**: Supports GDM3 and LightDM for auto-login (vs Windows auto-login)
3. **Systemd Services**: Uses systemd instead of Windows Task Scheduler
4. **Browsers**: Supports Chromium, Chrome, and Firefox in kiosk mode (vs Microsoft Edge)
5. **Serial Ports**: Uses `/dev/ttyS*` instead of `COM*` ports
6. **Package Managers**: Auto-detects apt, yum, or pacman for installing dependencies

## Supported Distributions

Tested on:

- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12
- CentOS Stream 8, 9
- Fedora 38, 39
- Arch Linux (current)
- Raspberry Pi OS (Bullseye, Bookworm)

## Getting Help

1. Check the main README.md in the project root
2. Run diagnostic scripts to identify issues
3. Check Docker logs: `docker logs gps-kiosk`
4. Check service logs: `sudo journalctl -u gps-kiosk.service`
5. Visit the project repository: <https://github.com/Uncruise/gps-kiosk>

## License

Same as the main GPS Kiosk project.
