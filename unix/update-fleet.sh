#!/bin/bash
# GPS Kiosk Fleet Update Script
# Run this from your management machine to update multiple GPS Kiosk deployments

# Default computer names - modify as needed
COMPUTER_NAMES=("gps-kiosk-01" "gps-kiosk-02")
SSH_USER=""
SSH_KEY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --computers)
            IFS=',' read -ra COMPUTER_NAMES <<< "$2"
            shift 2
            ;;
        --user)
            SSH_USER="$2"
            shift 2
            ;;
        --key)
            SSH_KEY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 --computers host1,host2 --user username [--key /path/to/key]"
            exit 1
            ;;
    esac
done

if [ -z "$SSH_USER" ]; then
    echo "ERROR: SSH user required"
    echo "Usage: $0 --computers host1,host2 --user username [--key /path/to/key]"
    exit 1
fi

echo "=== GPS Kiosk Fleet Update ==="
echo "Updating ${#COMPUTER_NAMES[@]} machines with auto-update functionality..."

SSH_OPTS=""
if [ -n "$SSH_KEY" ]; then
    SSH_OPTS="-i $SSH_KEY"
fi

for computer in "${COMPUTER_NAMES[@]}"; do
    echo ""
    echo "Updating $computer..."
    
    ssh $SSH_OPTS "$SSH_USER@$computer" bash << 'ENDSSH'
        # Navigate to GPS Kiosk directory
        cd /opt/gps-kiosk || cd ~/gps-kiosk || exit 1
        
        # Pull latest repository updates
        if [ -d .git ]; then
            git pull origin main
        fi
        
        # Stop containers
        docker compose down
        
        # Pull latest Docker image
        docker compose pull
        
        # Start with new image
        docker compose up -d --force-recreate
        
        # Wait and check status
        sleep 10
        status=$(docker ps --filter "name=gps-kiosk" --format "{{.Status}}" 2>/dev/null)
        
        if echo "$status" | grep -q "Up"; then
            echo "SUCCESS: $HOSTNAME - $status"
        else
            echo "FAILED: $HOSTNAME - $status"
            exit 1
        fi
ENDSSH
    
    if [ $? -eq 0 ]; then
        echo "  ✓ $computer updated successfully"
    else
        echo "  ✗ $computer update failed"
    fi
done

echo ""
echo "Fleet update complete!"
echo "All machines will now auto-update on restart."
