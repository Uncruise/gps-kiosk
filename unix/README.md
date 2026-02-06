# GPS Kiosk - Unix/Linux Scripts

This directory contains Unix/Linux shell script versions of all the Windows PowerShell and batch scripts for the GPS Kiosk project.

## Quick Start

### Automated Setup (Recommended)

For a fresh installation with Git:

```bash
cd unix
sudo bash quick-setup.sh
```

For a fresh installation without Git:

```bash
cd unix
sudo bash download-setup.sh
```

### Simple Wrappers

User-friendly wrappers that provide interactive prompts:

- **setup.sh** - Interactive wrapper for quick-setup.sh
- **download.sh** - Interactive wrapper for download-setup.sh
- **configure-kiosk.sh** - Interactive kiosk configuration

## Script Descriptions

### Setup Scripts

- **quick-setup.sh** - Fully automated installation with Docker auto-install, repository cloning, and startup configuration
- **download-setup.sh** - Downloads GPS Kiosk from GitHub without requiring Git installation
- **configure-auto-login.sh** - Configures Linux for automatic login and kiosk mode operation
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

To configure the system to automatically start GPS Kiosk on boot:

```bash
cd /opt/gps-kiosk/unix
sudo ./configure-auto-login.sh --username <your-username> --password <your-password>
```

This will:

1. Configure automatic login (GDM3 or LightDM)
2. Create and enable systemd service
3. Configure display power settings
4. Set up browser kiosk mode launch

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
