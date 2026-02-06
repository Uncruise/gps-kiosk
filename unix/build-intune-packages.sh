#!/bin/bash
# Build Intune Packages Script (Linux version)
# Note: Intune is primarily for Windows, but this creates archives for deployment

echo "================================"
echo "  Building Deployment Packages"
echo "================================"
echo ""

echo "Note: Microsoft Intune is primarily for Windows devices."
echo "This script creates deployment archives for Linux systems."
echo ""

# Create output directory if it doesn't exist
mkdir -p intune_out

echo "Building GPS Kiosk package..."
if [ -d "../intune" ]; then
    tar -czf intune_out/gps-kiosk-linux.tar.gz \
        -C .. \
        unix/ \
        docker-compose.yml \
        Volume/ \
        Dockerfile
    
    if [ $? -eq 0 ]; then
        echo "✓ GPS Kiosk package created: intune_out/gps-kiosk-linux.tar.gz"
    else
        echo "✗ Failed to build GPS Kiosk package"
        exit 1
    fi
else
    echo "✗ intune directory not found"
    exit 1
fi

echo ""
echo "Building installation package..."
cat > intune_out/install.sh << 'EOFINSTALL'
#!/bin/bash
# GPS Kiosk Linux Installation Script

echo "=== Installing GPS Kiosk ==="

# Check for root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Extract package
tar -xzf gps-kiosk-linux.tar.gz -C /opt/
cd /opt/unix

# Run setup
bash quick-setup.sh

echo "Installation complete!"
EOFINSTALL

chmod +x intune_out/install.sh

echo "✓ Installation script created: intune_out/install.sh"

echo ""
echo "================================"
echo "  Build Complete!"
echo "================================"
echo ""
echo "Created files:"
echo "  - intune_out/gps-kiosk-linux.tar.gz"
echo "  - intune_out/install.sh"
echo ""
echo "To deploy:"
echo "  1. Copy both files to target machine"
echo "  2. Run: sudo bash install.sh"
echo ""
