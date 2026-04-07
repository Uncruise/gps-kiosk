# GPS Kiosk - Marine Navigation System

A containerized marine navigation kiosk built on Signal K technology, designed for easy deployment and automatic updates.

## 🚀 Quick Start

### For Windows Users

1. **Download and run**: `Windows/setup.bat`
2. **Done!** The system will auto-install Docker, pull latest images, and launch in kiosk mode

### For Linux/Unix Users

1. **Run setup**: `sudo bash unix/quick-setup.sh`
   - Creates a `kiosk` account (no password), configures auto-login, starts the container, and launches the browser in kiosk mode on every boot.
2. **No Git installed?**: `sudo bash unix/download-setup.sh`

### For IT Deployment

1. **Intune Packages**: Use files in `intune_out/` folder (Windows only)
2. **Direct Download**: Use `Windows/download.bat` (Windows) or `unix/download.sh` (Linux) for non-Git environments

## 🎯 What It Does

- **Marine Navigation Display**: Real-time GPS, wind, and marine instrument data
- **Signal K Server**: Open-source marine data platform
- **Freeboard Interface**: Touch-friendly navigation charts
- **Auto-Updates**: Pulls latest Docker images and configurations
- **Kiosk Mode**: Full-screen Edge browser for dedicated displays

## 📋 Features

- ✅ **Auto-installs Docker Desktop** if missing
- ✅ **Auto-pulls latest images** from Docker Hub (`morrisuca/gps-kiosk:latest`)
- ✅ **Auto-starts on boot** with Windows startup integration
- ✅ **Self-updating configuration** from GitHub
- ✅ **Enterprise deployment** via Microsoft Intune
- ✅ **Marine chart integration** (OpenStreetMap + OpenSeaMap)
- ✅ **NMEA data support** via TCP connections
- ✅ **Touch-friendly interface** optimized for marine environments

## 🏗️ Architecture

```
GPS Kiosk System
├── Docker Container (morrisuca/gps-kiosk:latest)
│   ├── Signal K Server (Node.js)
│   ├── Freeboard-SK Interface
│   └── Marine Data Processing
├── Volume Mount (./Volume)
│   ├── Configuration Files
│   ├── User Settings
│   └── Chart Data
└── Auto-Startup Scripts
    ├── Docker Management
    ├── Health Monitoring
    └── Browser Launch
```

## 📁 Project Structure

```
gps-kiosk/
├── Windows/                   # Windows scripts and tools
│   ├── setup.bat              # Simple setup for end users
│   ├── quick-setup.ps1        # Advanced PowerShell setup
│   ├── download.bat           # Git-free download setup
│   ├── download-setup.ps1     # PowerShell download script
│   ├── configure-*.ps1        # Configuration scripts
│   ├── docker-diagnostic.ps1  # Diagnostic tools
│   └── README.md              # Windows-specific documentation
├── unix/                      # Linux/Unix scripts
│   ├── setup.sh              # Interactive setup wrapper
│   ├── quick-setup.sh        # Advanced shell setup
│   ├── download.sh           # Git-free download setup
│   ├── download-setup.sh     # Shell download script
│   ├── configure-*.sh        # Configuration scripts
│   ├── docker-diagnostic.sh  # Diagnostic tools
│   └── README.md             # Unix-specific documentation
├── docker-compose.yml         # Container configuration
├── Dockerfile                 # Custom image build
├── startup.sh                 # Container startup script
├── Volume/                    # Signal K configuration
│   ├── settings.json         # Server settings
│   ├── security.json         # Security configuration
│   └── applicationData/      # User data and plugins
├── intune/                   # Microsoft Intune deployment
│   ├── install.ps1          # Intune installation script
│   ├── detection.ps1        # Intune detection script
│   └── gps-kiosk-launcher.bat # Intune entry point
├── docker-intune/           # Docker-only Intune package
└── intune_out/              # Built Intune packages
    ├── gps-kiosk-launcher.intunewin
    └── docker-installer.intunewin
```

## 🔧 Configuration

### NMEA Data Source

Edit `Volume/settings.json` to configure your marine data source:

```json
{
  "pipedProviders": [
    {
      "pipeElements": [
        {
          "type": "providers/simple",
          "options": {
            "type": "NMEA0183",
            "subOptions": {
              "type": "tcp",
              "host": "YOUR_DEVICE_IP",
              "port": "23"
            }
          }
        }
      ]
    }
  ]
}
```

### Chart Configuration

Charts are configured in the Freeboard interface:

- **OpenStreetMap**: Base mapping
- **OpenSeaMap**: Marine-specific overlay
- **Custom Charts**: S-57 ENC support available

## 🚀 Deployment Options

### 1. Manual Installation (Windows)

```powershell
# Clone repository
git clone https://github.com/Uncruise/gps-kiosk.git
cd gps-kiosk\Windows

# Run setup
.\setup.bat
```

### 2. Manual Installation (Linux/Unix)

```bash
# Clone repository
sudo git clone https://github.com/Uncruise/gps-kiosk.git /opt/gps-kiosk

# Run setup — creates 'kiosk' user (no password), auto-login, container, and browser kiosk
sudo bash /opt/gps-kiosk/unix/quick-setup.sh

# Reboot into kiosk mode
sudo reboot
```

### 3. Direct Download (No Git Required)

**Windows:**

```powershell
.\windows\download.bat
```

**Linux/Unix:**

```bash
sudo bash unix/download.sh
```

**Windows:**

```powershell
# Or manually
docker compose pull
docker compose up -d
```

**Linux/Unix:**
```bash2. Configure detection rule with `detection.ps1`
3. Deploy to device groups

## 🔄 Updates

The system automatically updates on every restart:

- **Docker Images**: Pulls latest from Docker Hub
- **Configuration**: Syncs from GitHub repository
- **Dependencies**: Auto-managed by container

### Manual Update

```bash
# Run the update script
./update-gps-kiosk.bat

# Or manually
docker compose pull
docker compose up -d
```

## 🛠️ Development

### Building Custom Images

```bash
# Build locally
docker build -t gps-kiosk .

# Run with custom image
docker compose up -d
```

### Modifying Configuration

1. Edit files in `Volume/` directory
2. Restart containers: `docker compose restart`
3. Changes persist across updates

## 🌐 Access

- **Primary Interface**: <http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1>
- **Signal K API**: <http://localhost:3000/signalk/>
- **Admin Panel**: <http://localhost:3000/admin/>
- **Freeboard-SK Kiosk Mode**: <http://localhost:3000/@signalk/freeboard-sk/?zoom=12&northup=1&movemap=1&kiosk=1>

## 📞 Support

- **Repository**: <https://github.com/Uncruise/gps-kiosk>
- **Signal K Documentation**: <https://signalk.org/>
- **Freeboard Documentation**: <https://github.com/SignalK/freeboard-sk>

## 📄 License

Apache-2.0 License - See Signal K project for details.

---

**Built for maritime professionals who need reliable, updateable navigation displays.**
