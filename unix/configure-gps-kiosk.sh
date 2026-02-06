#!/bin/bash
# GPS Kiosk Configuration Helper
# Use this script to easily modify common GPS Kiosk settings

GPS_HOST=""
GPS_PORT=""
MAP_CENTER_LAT=""
MAP_CENTER_LON=""
MAP_ZOOM=""
SHOW_CURRENT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --gps-host)
            GPS_HOST="$2"
            shift 2
            ;;
        --gps-port)
            GPS_PORT="$2"
            shift 2
            ;;
        --map-lat)
            MAP_CENTER_LAT="$2"
            shift 2
            ;;
        --map-lon)
            MAP_CENTER_LON="$2"
            shift 2
            ;;
        --map-zoom)
            MAP_ZOOM="$2"
            shift 2
            ;;
        --show-current)
            SHOW_CURRENT=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

volumePath="./Volume"
settingsFile="$volumePath/settings.json"
freeboardFile="$volumePath/applicationData/users/admin/freeboard/1.0.0.json"

if [ "$SHOW_CURRENT" = true ]; then
    echo "=== Current GPS Kiosk Configuration ==="
    echo ""
    
    if [ -f "$settingsFile" ]; then
        echo "GPS Data Source:"
        gps_host=$(jq -r '.pipedProviders[] | select(.id=="WND") | .pipeElements[0].options.subOptions.host' "$settingsFile")
        gps_port=$(jq -r '.pipedProviders[] | select(.id=="WND") | .pipeElements[0].options.subOptions.port' "$settingsFile")
        gps_type=$(jq -r '.pipedProviders[] | select(.id=="WND") | .pipeElements[0].options.subOptions.type' "$settingsFile")
        
        echo "  Host: $gps_host"
        echo "  Port: $gps_port"
        echo "  Type: $gps_type"
    fi
    
    if [ -f "$freeboardFile" ]; then
        echo ""
        echo "Map Configuration:"
        map_center=$(jq -r '.map.center' "$freeboardFile")
        map_zoom=$(jq -r '.map.zoomLevel' "$freeboardFile")
        dark_mode=$(jq -r '.darkMode.enabled' "$freeboardFile")
        
        echo "  Center: $map_center"
        echo "  Zoom Level: $map_zoom"
        echo "  Dark Mode: $dark_mode"
    fi
    
    echo ""
    echo "To modify settings, use parameters:"
    echo "  ./configure-gps-kiosk.sh --gps-host 192.168.1.100 --gps-port 23"
    echo "  ./configure-gps-kiosk.sh --map-lat 27.7634 --map-lon -6.8447 --map-zoom 15"
    exit 0
fi

changes=()

# Update GPS settings
if [ -n "$GPS_HOST" ] || [ -n "$GPS_PORT" ]; then
    echo "Updating GPS data source..."
    
    if [ -f "$settingsFile" ]; then
        if [ -n "$GPS_HOST" ]; then
            jq --arg host "$GPS_HOST" '(.pipedProviders[] | select(.id=="WND") | .pipeElements[0].options.subOptions.host) = $host' "$settingsFile" > "${settingsFile}.tmp"
            mv "${settingsFile}.tmp" "$settingsFile"
            changes+=("GPS Host: $GPS_HOST")
        fi
        
        if [ -n "$GPS_PORT" ]; then
            jq --arg port "$GPS_PORT" '(.pipedProviders[] | select(.id=="WND") | .pipeElements[0].options.subOptions.port) = $port' "$settingsFile" > "${settingsFile}.tmp"
            mv "${settingsFile}.tmp" "$settingsFile"
            changes+=("GPS Port: $GPS_PORT")
        fi
        
        echo "GPS settings updated."
    fi
fi

# Update map settings
if [ -n "$MAP_CENTER_LAT" ] || [ -n "$MAP_CENTER_LON" ] || [ -n "$MAP_ZOOM" ]; then
    echo "Updating map configuration..."
    
    if [ -f "$freeboardFile" ]; then
        if [ -n "$MAP_CENTER_LAT" ]; then
            jq --argjson lat "$MAP_CENTER_LAT" '.map.center[0] = $lat' "$freeboardFile" > "${freeboardFile}.tmp"
            mv "${freeboardFile}.tmp" "$freeboardFile"
        fi
        
        if [ -n "$MAP_CENTER_LON" ]; then
            jq --argjson lon "$MAP_CENTER_LON" '.map.center[1] = $lon' "$freeboardFile" > "${freeboardFile}.tmp"
            mv "${freeboardFile}.tmp" "$freeboardFile"
        fi
        
        if [ -n "$MAP_ZOOM" ]; then
            jq --argjson zoom "$MAP_ZOOM" '.map.zoomLevel = $zoom' "$freeboardFile" > "${freeboardFile}.tmp"
            mv "${freeboardFile}.tmp" "$freeboardFile"
            changes+=("Map Zoom: $MAP_ZOOM")
        fi
        
        if [ -n "$MAP_CENTER_LAT" ] || [ -n "$MAP_CENTER_LON" ]; then
            center=$(jq -r '.map.center' "$freeboardFile")
            changes+=("Map Center: $center")
        fi
        
        echo "Map settings updated."
    fi
fi

if [ ${#changes[@]} -gt 0 ]; then
    echo ""
    echo "=== Configuration Changes Applied ==="
    for change in "${changes[@]}"; do
        echo "  ✓ $change"
    done
    echo ""
    echo "Restart GPS Kiosk to apply changes:"
    echo "  docker compose restart"
    echo "  Or run: ./quick-setup.sh"
else
    echo "No changes specified. Use --show-current to see current settings."
fi
