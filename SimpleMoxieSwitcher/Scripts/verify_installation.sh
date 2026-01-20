#!/bin/bash
# Post-installation verification for SimpleMoxieSwitcher
# Run this after completing setup to verify everything is working

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
FAILED=0

pass() {
    echo -e "${GREEN}  [OK]${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}  [FAIL]${NC} $1"
    ((FAILED++))
}

info() {
    echo -e "${CYAN}  [INFO]${NC} $1"
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        SimpleMoxieSwitcher Installation Verification       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================
# Docker Checks
# ============================================================
echo -e "${BLUE}Docker Status${NC}"
echo "────────────────────────────────────────"

# Docker running
if docker info &>/dev/null; then
    pass "Docker daemon is running"
else
    fail "Docker daemon is not running"
fi

# Container: openmoxie-server
SERVER_STATUS=$(docker inspect --format='{{.State.Status}}' openmoxie-server 2>/dev/null || echo "not found")
if [ "$SERVER_STATUS" == "running" ]; then
    pass "openmoxie-server container is running"

    # Get uptime
    STARTED=$(docker inspect --format='{{.State.StartedAt}}' openmoxie-server 2>/dev/null)
    info "Started at: $STARTED"
else
    fail "openmoxie-server container: $SERVER_STATUS"
fi

# Container: openmoxie-mqtt
MQTT_STATUS=$(docker inspect --format='{{.State.Status}}' openmoxie-mqtt 2>/dev/null || echo "not found")
if [ "$MQTT_STATUS" == "running" ]; then
    pass "openmoxie-mqtt container is running"
else
    fail "openmoxie-mqtt container: $MQTT_STATUS"
fi

# ============================================================
# Network Endpoints
# ============================================================
echo ""
echo -e "${BLUE}Network Endpoints${NC}"
echo "────────────────────────────────────────"

# Local server endpoint
if curl -s --max-time 5 http://localhost:8001/ &>/dev/null; then
    pass "Server responding on localhost:8001"
else
    fail "Server not responding on localhost:8001"
fi

# Hive setup page
SETUP_PAGE=$(curl -s --max-time 5 http://localhost:8001/hive/setup 2>/dev/null || echo "")
if [ -n "$SETUP_PAGE" ]; then
    pass "Hive setup page accessible"
else
    fail "Hive setup page not accessible"
fi

# MQTT port
if nc -z localhost 8883 2>/dev/null; then
    pass "MQTT port 8883 is open"
else
    fail "MQTT port 8883 is not accessible"
fi

# ============================================================
# App Configuration
# ============================================================
echo ""
echo -e "${BLUE}App Configuration${NC}"
echo "────────────────────────────────────────"

# Check if setup completed
SETUP_COMPLETED=$(defaults read com.simplemoxieswitcher hasCompletedSetup 2>/dev/null || defaults read SimpleMoxieSwitcher hasCompletedSetup 2>/dev/null || echo "0")
if [ "$SETUP_COMPLETED" == "1" ]; then
    pass "Setup wizard completed"
else
    info "Setup wizard not yet completed (will show on first launch)"
fi

# Check saved endpoint
SAVED_ENDPOINT=$(defaults read com.simplemoxieswitcher moxieEndpoint 2>/dev/null || defaults read SimpleMoxieSwitcher moxieEndpoint 2>/dev/null || echo "")
if [ -n "$SAVED_ENDPOINT" ]; then
    pass "Endpoint saved: $SAVED_ENDPOINT"
else
    info "Endpoint not yet configured"
fi

# Check IP address
SAVED_IP=$(defaults read com.simplemoxieswitcher detectedIPAddress 2>/dev/null || defaults read SimpleMoxieSwitcher detectedIPAddress 2>/dev/null || echo "")
if [ -n "$SAVED_IP" ]; then
    pass "IP address saved: $SAVED_IP"
else
    info "IP address not yet saved"
fi

# ============================================================
# Network Detection
# ============================================================
echo ""
echo -e "${BLUE}Current Network${NC}"
echo "────────────────────────────────────────"

# Detect current IP
CURRENT_IP=""
for iface in en0 en1; do
    IP=$(ipconfig getifaddr $iface 2>/dev/null || echo "")
    if [ -n "$IP" ]; then
        CURRENT_IP="$IP"
        break
    fi
done
if [ -n "$CURRENT_IP" ]; then
    pass "Current IP: $CURRENT_IP"
else
    fail "Could not detect current IP"
fi

# Detect WiFi
WIFI=$(/usr/sbin/networksetup -getairportnetwork en0 2>/dev/null | sed 's/Current Wi-Fi Network: //' || echo "")
if [ -n "$WIFI" ] && [ "$WIFI" != "You are not associated with an AirPort network." ]; then
    pass "Connected to WiFi: $WIFI"
else
    info "Not connected to WiFi (may be using ethernet)"
fi

# ============================================================
# Container Logs Check
# ============================================================
echo ""
echo -e "${BLUE}Recent Container Logs${NC}"
echo "────────────────────────────────────────"

# Check for errors in server logs
SERVER_ERRORS=$(docker logs openmoxie-server 2>&1 | tail -20 | grep -i "error\|exception\|failed" || echo "")
if [ -z "$SERVER_ERRORS" ]; then
    pass "No recent errors in server logs"
else
    fail "Found errors in server logs:"
    echo "$SERVER_ERRORS" | head -5
fi

# Check for errors in MQTT logs
MQTT_ERRORS=$(docker logs openmoxie-mqtt 2>&1 | tail -20 | grep -i "error\|exception\|failed" || echo "")
if [ -z "$MQTT_ERRORS" ]; then
    pass "No recent errors in MQTT logs"
else
    fail "Found errors in MQTT logs:"
    echo "$MQTT_ERRORS" | head -5
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   Verification Summary                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}SUCCESS: Installation verified!${NC}"
    echo ""
    echo "Quick Links:"
    echo "  Admin Panel:  http://localhost:8001/hive/setup"
    if [ -n "$CURRENT_IP" ]; then
        echo "  Endpoint URL: http://${CURRENT_IP}:8003/hive/endpoint/"
    fi
    echo ""
    echo "Your Moxie robot should be able to connect now."
    exit 0
else
    echo -e "${RED}WARNING: Some checks failed${NC}"
    echo "Please review the issues above."
    echo ""
    echo "Troubleshooting:"
    echo "  1. Restart Docker: docker-compose -f ~/OpenMoxie/docker-compose.yml restart"
    echo "  2. Check logs: docker logs openmoxie-server"
    echo "  3. Re-run setup: Run the SimpleMoxieSwitcher app"
    exit 1
fi
