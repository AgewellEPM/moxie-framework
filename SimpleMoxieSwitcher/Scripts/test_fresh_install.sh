#!/bin/bash
# Full integration test for SimpleMoxieSwitcher fresh install
# Simulates a complete fresh install experience

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

pass() {
    echo -e "${GREEN}  PASS${NC}: $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}  FAIL${NC}: $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}  WARN${NC}: $1"
    ((WARNINGS++))
}

info() {
    echo -e "${CYAN}  INFO${NC}: $1"
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     SimpleMoxieSwitcher Fresh Install Integration Test     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if we should do a full reset
SKIP_RESET=false
if [[ "$1" == "--skip-reset" ]]; then
    SKIP_RESET=true
    info "Skipping reset (--skip-reset flag set)"
fi

# ============================================================
# Phase 1: Reset to Fresh State
# ============================================================
echo -e "${BLUE}[Phase 1] Reset to Fresh State${NC}"
echo "────────────────────────────────────────"

if [[ "$SKIP_RESET" == false ]]; then
    # Clear UserDefaults
    echo -e "${YELLOW}Clearing app preferences...${NC}"
    defaults delete com.simplemoxieswitcher 2>/dev/null || true
    defaults delete SimpleMoxieSwitcher 2>/dev/null || true
    pass "App preferences cleared"

    # Clear Keychain
    echo -e "${YELLOW}Clearing Keychain items...${NC}"
    security delete-generic-password -s "SimpleMoxieSwitcher" 2>/dev/null || true
    security delete-generic-password -s "MoxieParentPIN" 2>/dev/null || true
    pass "Keychain items cleared"
else
    info "Reset skipped"
fi

# ============================================================
# Phase 2: Pre-requisites Check
# ============================================================
echo ""
echo -e "${BLUE}[Phase 2] Pre-requisites Check${NC}"
echo "────────────────────────────────────────"

# Check Docker installed
echo -e "${YELLOW}Checking Docker installation...${NC}"
if [ -d "/Applications/Docker.app" ]; then
    pass "Docker Desktop installed"
else
    fail "Docker Desktop not installed"
    echo -e "${RED}Please install Docker Desktop from https://docker.com${NC}"
    exit 1
fi

# Check Docker running
echo -e "${YELLOW}Checking Docker daemon...${NC}"
if docker info &>/dev/null; then
    pass "Docker daemon running"
else
    warn "Docker daemon not running, attempting to start..."
    open -a Docker
    echo "Waiting for Docker to start (up to 60 seconds)..."
    for i in {1..30}; do
        sleep 2
        if docker info &>/dev/null; then
            pass "Docker daemon started"
            break
        fi
        echo -n "."
    done
    if ! docker info &>/dev/null; then
        fail "Docker daemon failed to start"
        exit 1
    fi
fi

# Check network
echo -e "${YELLOW}Checking network connectivity...${NC}"
if curl -s --max-time 5 https://hub.docker.com &>/dev/null; then
    pass "Internet connectivity OK"
else
    fail "No internet connectivity"
    exit 1
fi

# ============================================================
# Phase 3: Container Setup Test
# ============================================================
echo ""
echo -e "${BLUE}[Phase 3] Container Setup Test${NC}"
echo "────────────────────────────────────────"

# Stop existing containers
echo -e "${YELLOW}Stopping any existing containers...${NC}"
docker stop openmoxie-server openmoxie-mqtt 2>/dev/null || true
docker rm openmoxie-server openmoxie-mqtt 2>/dev/null || true
pass "Cleaned up existing containers"

# Create OpenMoxie directory if needed
OPENMOXIE_DIR="$HOME/OpenMoxie"
echo -e "${YELLOW}Setting up OpenMoxie directory...${NC}"
mkdir -p "$OPENMOXIE_DIR/local/work"

# Create docker-compose.yml
cat > "$OPENMOXIE_DIR/docker-compose.yml" << 'EOF'
version: '3.8'
services:
  openmoxie-server:
    image: openmoxie/openmoxie-server:latest
    container_name: openmoxie-server
    ports:
      - "8001:8000"
    volumes:
      - ./local:/app/local
    restart: unless-stopped
    depends_on:
      - openmoxie-mqtt

  openmoxie-mqtt:
    image: openmoxie/openmoxie-mqtt:latest
    container_name: openmoxie-mqtt
    ports:
      - "8883:8883"
    restart: unless-stopped
EOF
pass "Created docker-compose.yml"

# Pull images
echo -e "${YELLOW}Pulling Docker images (this may take a few minutes)...${NC}"
cd "$OPENMOXIE_DIR"
if docker-compose pull 2>&1; then
    pass "Docker images pulled successfully"
else
    fail "Failed to pull Docker images"
fi

# Start containers
echo -e "${YELLOW}Starting containers...${NC}"
if docker-compose up -d 2>&1; then
    pass "Containers started"
else
    fail "Failed to start containers"
fi

# Wait for server to be ready
echo -e "${YELLOW}Waiting for OpenMoxie server to be ready...${NC}"
MAX_WAIT=60
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s --max-time 3 http://localhost:8001/ &>/dev/null; then
        pass "OpenMoxie server is responding (waited ${WAITED}s)"
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -n "."
done
echo ""

if [ $WAITED -ge $MAX_WAIT ]; then
    warn "Server did not respond within ${MAX_WAIT}s (may still be starting)"
fi

# ============================================================
# Phase 4: Network Detection Test
# ============================================================
echo ""
echo -e "${BLUE}[Phase 4] Network Detection Test${NC}"
echo "────────────────────────────────────────"

# Detect IP
echo -e "${YELLOW}Detecting local IP address...${NC}"
DETECTED_IP=""
for iface in en0 en1 en2; do
    IP=$(ipconfig getifaddr $iface 2>/dev/null || echo "")
    if [ -n "$IP" ] && [[ "$IP" =~ ^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.) ]]; then
        DETECTED_IP="$IP"
        break
    fi
done

if [ -n "$DETECTED_IP" ]; then
    pass "Detected IP: $DETECTED_IP"
else
    fail "Failed to detect LAN IP"
fi

# Detect WiFi
echo -e "${YELLOW}Detecting WiFi network...${NC}"
WIFI_SSID=$(/usr/sbin/networksetup -getairportnetwork en0 2>/dev/null | sed 's/Current Wi-Fi Network: //' || echo "")
if [ -n "$WIFI_SSID" ] && [ "$WIFI_SSID" != "You are not associated with an AirPort network." ]; then
    pass "Detected WiFi: $WIFI_SSID"
else
    warn "WiFi not detected (may be using ethernet)"
fi

# ============================================================
# Phase 5: Endpoint Verification
# ============================================================
echo ""
echo -e "${BLUE}[Phase 5] Endpoint Verification${NC}"
echo "────────────────────────────────────────"

# Test hive setup endpoint
echo -e "${YELLOW}Testing /hive/setup endpoint...${NC}"
if curl -s --max-time 5 http://localhost:8001/hive/setup | grep -q "form\|setup\|hostname" 2>/dev/null; then
    pass "Hive setup page accessible"
else
    warn "Hive setup page may not be fully loaded"
fi

# Test container health
echo -e "${YELLOW}Checking container health...${NC}"
SERVER_STATUS=$(docker inspect --format='{{.State.Status}}' openmoxie-server 2>/dev/null || echo "not found")
MQTT_STATUS=$(docker inspect --format='{{.State.Status}}' openmoxie-mqtt 2>/dev/null || echo "not found")

if [ "$SERVER_STATUS" == "running" ]; then
    pass "openmoxie-server container is running"
else
    fail "openmoxie-server container status: $SERVER_STATUS"
fi

if [ "$MQTT_STATUS" == "running" ]; then
    pass "openmoxie-mqtt container is running"
else
    fail "openmoxie-mqtt container status: $MQTT_STATUS"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                      Test Summary                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}Passed:   $PASSED${NC}"
echo -e "  ${RED}Failed:   $FAILED${NC}"
echo -e "  ${YELLOW}Warnings: $WARNINGS${NC}"
echo ""

if [ -n "$DETECTED_IP" ]; then
    echo -e "${BLUE}Configuration Ready:${NC}"
    echo "  Endpoint URL: http://${DETECTED_IP}:8003/hive/endpoint/"
    echo "  Admin Panel:  http://localhost:8001/hive/setup"
    echo "  WiFi Network: ${WIFI_SSID:-Not detected}"
    echo ""
fi

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}SUCCESS: Fresh install test completed!${NC}"
    echo ""
    echo "The system is ready for SimpleMoxieSwitcher."
    echo "Launch the app and complete the setup wizard."
    exit 0
else
    echo -e "${RED}FAILED: Some tests did not pass.${NC}"
    echo "Please review the errors above and fix before proceeding."
    exit 1
fi
