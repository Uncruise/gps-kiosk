# GPS Kiosk - Windows Scripts

This directory contains Windows PowerShell and batch scripts for the GPS Kiosk project.

## Quick Start

### Automated Setup (Recommended)

For a fresh installation with Git:

```powershell
.\setup.bat
```

For a fresh installation without Git:

```powershell
.\download.bat
```

### PowerShell Setup (Advanced)

For more control, run PowerShell scripts directly:

```powershell
# Full setup with Docker auto-install
.\quick-setup.ps1

# Download and setup without Git
.\download-setup.ps1

# Configure auto-login
.\configure-kiosk.bat
```

## Script Descriptions

### Setup Scripts

- **setup.bat** - Simple batch wrapper for interactive setup
- **download.bat** - Wrapper for download-based setup
- **quick-setup.ps1** - Fully automated installation with Docker auto-install, repository cloning, and startup configuration
- **download-setup.ps1** - Downloads GPS Kiosk from GitHub without requiring Git installation

### Configuration Scripts

- **configure-kiosk.bat** - Interactive wrapper for auto-login configuration
- **configure-auto-login.ps1** - Configures Windows for automatic login and kiosk mode operation (requires Administrator)
- **configure-gps-kiosk.ps1** - Configure GPS data source and map settings
- **docker-engine-setup.ps1** - Alternative Docker setup for remote machines (uses Docker Engine instead of Desktop)

### Diagnostic Scripts

- **docker-diagnostic.ps1** - Diagnose Docker Desktop issues
- **diagnose-deployment.ps1** - Check deployment status and troubleshoot startup problems
- **enable-docker-features.ps1** - Enable Windows features required for Docker (Hyper-V, WSL, Containers)

### Utility Scripts

- **add-com2tcp-support.bat** & **add-com2tcp-support.ps1** - Add COM2TCP serial bridge support
- **test-restart.ps1** - Test restart sequence without rebooting
- **update-fleet.ps1** - Remotely update multiple GPS Kiosk deployments via PowerShell remoting
- **verify-update.ps1** - Verify auto-update functionality is working correctly

## Requirements

### Minimum Requirements

- Windows 10 (version 2004 or later) or Windows 11
- PowerShell 5.0 or later (usually pre-installed)
- Administrator access for Docker and auto-login configuration
- Internet connection (for initial setup)
- 4GB RAM, 20GB disk space

### Optional Requirements

- Git (recommended, but download-setup.ps1 works without it)
- Docker Desktop (installed automatically if not present)

## Installation Paths

By default, scripts install to:

- **System-wide**: `C:\gps-kiosk\`
- **Custom**: Specify `-InstallPath` parameter in PowerShell scripts

## Running Scripts

### As Administrator

Most scripts require Administrator privileges:

1. **Right-click PowerShell** and select "Run as administrator"
2. **Set execution policy** if needed:

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Run the script**:

   ```powershell
   .\quick-setup.ps1
   ```

Or run batch files directly - they will request elevation if needed.

### Execution Policy

If you get an execution policy error:

```powershell
# Temporarily bypass for one script
powershell.exe -ExecutionPolicy Bypass -File ".\quick-setup.ps1"

# Or permanently set for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

## Docker Requirements

### Docker Desktop Setup

Scripts will automatically:

1. Check for Docker Desktop installation
2. Install Docker Desktop if missing (via winget or direct download)
3. Enable WSL 2 backend
4. Configure Docker settings
5. Start Docker service

### Windows Features

Required Windows features (enabled automatically):

- **Windows Subsystem for Linux (WSL)** - For Docker WSL 2 backend
- **Virtual Machine Platform** - For Hyper-V and WSL 2
- **Containers** - For Windows container support (optional)

To manually enable:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
Enable-WindowsOptionalFeature -Online -FeatureName Containers -All
```

## Configuration

### GPS Data Source

Configure the GPS data source (TCP/IP, serial port, etc.):

```powershell
.\configure-gps-kiosk.ps1 -GpsHost 192.168.1.100 -GpsPort 10110
```

### Map Settings

Configure default map center and zoom level:

```powershell
.\configure-gps-kiosk.ps1 -MapCenterLat 27.7634 -MapCenterLon -6.8447 -MapZoom 15
```

### View Current Configuration

```powershell
.\configure-gps-kiosk.ps1 -ShowCurrent
```

### Auto-Login Setup

Configure the system to automatically login and launch GPS Kiosk:

```powershell
# Run as Administrator
.\configure-auto-login.ps1 -Username "kiosk-user" -Password "your-password"
```

Options:

- `-DisableUpdates` - Disable Windows automatic updates
- `-ShowCurrent` - Show current auto-login configuration

## Troubleshooting

### Docker Issues

Run the diagnostic script:

```powershell
.\docker-diagnostic.ps1
```

To automatically fix common issues:

```powershell
.\docker-diagnostic.ps1 -Fix
```

### Deployment Issues

Check deployment status:

```powershell
.\diagnose-deployment.ps1
```

### Windows Features Not Enabled

Enable Docker-required features:

```powershell
# Run as Administrator
.\enable-docker-features.ps1

# With automatic restart
.\enable-docker-features.ps1 -Force
```

### Execution Policy Issues

```powershell
# Temporarily allow script execution
powershell.exe -ExecutionPolicy Bypass -File ".\quick-setup.ps1"

# Or permanently (current user only)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Manual Docker Commands

```powershell
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

## Fleet Management

To update multiple GPS Kiosk systems remotely:

```powershell
# Define computers and credentials
$computers = @("GPS-KIOSK-01", "GPS-KIOSK-02", "GPS-KIOSK-03")
$cred = Get-Credential -Message "Enter credentials for remote machines"

# Update all
.\update-fleet.ps1 -ComputerNames $computers -Credential $cred
```

After updating, verify each system:

```powershell
.\verify-update.ps1
```

## Tested Platforms

- Windows 10 (Build 2004 or later)
- Windows 11 (all versions)
- Windows Server 2019
- Windows Server 2022

## Getting Help

1. Check the main README.md in the project root
2. Run diagnostic scripts to identify issues
3. Check Docker logs: `docker logs gps-kiosk`
4. Check Windows Event Viewer: Applications and Services Logs → Application
5. Visit the project repository: <https://github.com/Uncruise/gps-kiosk>

## See Also

- [Unix/Linux Scripts](../unix/README.md) - For Linux/macOS
- [Windows-Unix Mapping](../WINDOWS-UNIX-MAPPING.md) - Compare Windows and Unix scripts

## License

Same as the main GPS Kiosk project.
