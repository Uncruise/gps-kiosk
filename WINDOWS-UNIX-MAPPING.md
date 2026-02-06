# Windows to Unix Script Mapping

This document shows the mapping between Windows scripts (PowerShell/.bat) and their Unix shell script equivalents.

## Complete Script Mapping

| Windows Script | Unix Script | Description |
|----------------|-------------|-------------|
| `Windows/setup.bat` | `unix/setup.sh` | Simple interactive setup wrapper |
| `Windows/download.bat` | `unix/download.sh` | Simple download wrapper (no Git required) |
| `Windows/quick-setup.ps1` | `unix/quick-setup.sh` | Full automated setup with Docker install |
| `Windows/download-setup.ps1` | `unix/download-setup.sh` | Download and setup without Git |
| `Windows/configure-kiosk.bat` | `unix/configure-kiosk.sh` | Interactive kiosk configuration wrapper |
| `Windows/configure-auto-login.ps1` | `unix/configure-auto-login.sh` | Configure automatic login and kiosk mode |
| `Windows/configure-gps-kiosk.ps1` | `unix/configure-gps-kiosk.sh` | Configure GPS and map settings |
| `Windows/docker-diagnostic.ps1` | `unix/docker-diagnostic.sh` | Diagnose Docker issues |
| `Windows/diagnose-deployment.ps1` | `unix/diagnose-deployment.sh` | Diagnose deployment problems |
| `Windows/docker-engine-setup.ps1` | *(Not applicable)* | Linux uses native Docker Engine |
| `Windows/enable-docker-features.ps1` | *(Not applicable)* | Linux doesn't need Windows features |
| `Windows/add-com2tcp-support.bat` | `unix/add-com2tcp-support.sh` | Add COM2TCP serial bridge support |
| `Windows/add-com2tcp-support.ps1` | `unix/add-com2tcp-support.sh` | Same functionality |
| `Windows/test-restart.ps1` | `unix/test-restart.sh` | Test restart sequence |
| `Windows/update-fleet.ps1` | `unix/update-fleet.sh` | Update multiple kiosk systems remotely |
| `Windows/verify-update.ps1` | `unix/verify-update.sh` | Verify auto-update functionality |
| `Windows/build-intune-packages.bat` | `unix/build-intune-packages.sh` | Build deployment packages |

## Key Differences

### Docker

- **Windows**: Uses Docker Desktop with WSL 2 backend
- **Unix**: Uses native Docker Engine or Docker Desktop

### Auto-Login

- **Windows**: Registry-based (Winlogon)
- **Unix**: Display manager config (GDM3/LightDM)

### Auto-Start

- **Windows**: Task Scheduler / Startup folder / Registry Run key
- **Unix**: systemd service units

### Browser Kiosk Mode

- **Windows**: Microsoft Edge with `--kiosk` flag
- **Unix**: Chromium, Chrome, or Firefox with `--kiosk` flag

### Serial Ports

- **Windows**: `COM1`, `COM2`, etc.
- **Unix**: `/dev/ttyS0`, `/dev/ttyS1`, etc.

### Paths

- **Windows**: `C:\gps-kiosk\`
- **Unix**: `/opt/gps-kiosk/` (root) or `~/gps-kiosk` (user)

### Package Installation

- **Windows**: winget, direct downloads
- **Unix**: apt, yum, pacman (auto-detected)

## Usage Patterns

### Windows Example

```powershell
# Run setup
cd windows
.\setup.bat

# Or directly
.\quick-setup.ps1

# Configure kiosk
.\configure-kiosk.bat

# Diagnose issues
.\docker-diagnostic.ps1
```

### Unix Example

```bash
# Run setup
cd unix
bash setup.sh

# Or directly
bash quick-setup.sh

# Configure kiosk (requires sudo)
sudo bash configure-kiosk.sh

# Diagnose issues
bash docker-diagnostic.sh
```

## Script Locations

- **Windows scripts**: `Windows/` subdirectory
- **Unix scripts**: `unix/` subdirectory

## Compatibility Notes

### Tested Platforms

**Windows:**

- Windows 10 (version 2004 or later)
- Windows 11
- Windows Server 2019/2022

**Unix/Linux:**

- Ubuntu 20.04, 22.04, 24.04
- Debian 11, 12
- CentOS Stream 8, 9
- Fedora 38, 39
- Arch Linux
- Raspberry Pi OS

### Common Features

Both Windows and Unix versions:

- ✓ Docker auto-detection and installation
- ✓ Git auto-installation (optional)
- ✓ Automatic Docker image pulling
- ✓ Container health checking
- ✓ Auto-update on restart
- ✓ Remote fleet management
- ✓ Configuration helpers
- ✓ Diagnostic tools
- ✓ Kiosk mode browser launch

### Platform-Specific Features

**Windows Only:**

- PowerShell execution policy configuration
- WSL 2 backend setup
- Windows feature enablement (Hyper-V, Containers)
- Intune packaging (.intunewin files)

**Unix Only:**

- systemd service management
- Display manager auto-login (GDM3/LightDM)
- X11 power management
- Package manager auto-detection
- SSH-based fleet management

## Migration Guide

### From Windows to Unix

1. Copy your Volume configuration:

   ```bash
   # On Windows, export your config
   Copy-Item -Recurse C:\gps-kiosk\Volume .\volume-backup
   
   # On Unix, import the config
   cp -r /path/to/volume-backup /opt/gps-kiosk/Volume
   ```

2. Convert serial port references:
   - `COM1` → `/dev/ttyS0`
   - `COM2` → `/dev/ttyS1`
   - etc.

3. Run Unix setup:

   ```bash
   cd /opt/gps-kiosk/unix
   sudo bash quick-setup.sh
   ```

4. Configure auto-start:

   ```bash
   sudo bash configure-auto-login.sh --username gps --password yourpassword
   ```

### From Unix to Windows

1. Export configuration:

   ```bash
   tar -czf volume-backup.tar.gz /opt/gps-kiosk/Volume
   ```

2. On Windows, import:

   ```powershell
   # Extract and copy to C:\gps-kiosk\Volume
   ```

3. Convert serial port references:
   - `/dev/ttyS0` → `COM1`
   - `/dev/ttyS1` → `COM2`
   - etc.

4. Run Windows setup:

   ```powershell
   .\quick-setup.ps1
   ```

## Support

For issues specific to:

- **Windows scripts**: Check main README.md
- **Unix scripts**: Check unix/README.md
- **General GPS Kiosk**: Visit <https://github.com/Uncruise/gps-kiosk>
