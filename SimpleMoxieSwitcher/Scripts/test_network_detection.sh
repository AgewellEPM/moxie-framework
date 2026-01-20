#!/bin/bash
# Test network detection capabilities for SimpleMoxieSwitcher
# Validates IP detection, WiFi detection, and endpoint generation

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

pass() {
    echo -e "${GREEN}  PASS${NC}: $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}  FAIL${NC}: $1"
    ((FAILED++))
}

info() {
    echo -e "${YELLOW}  INFO${NC}: $1"
}

echo -e "${BLUE}=== Network Detection Tests ===${NC}"
echo ""

# Test 1: Local IP Detection (en0)
echo -e "${YELLOW}[Test 1] Local IP Detection (en0)${NC}"
IP_EN0=$(ipconfig getifaddr en0 2>/dev/null || echo "")
if [ -n "$IP_EN0" ]; then
    pass "Detected IP on en0: $IP_EN0"
else
    info "No IP on en0 (may be using different interface)"
fi

# Test 2: Local IP Detection (en1)
echo -e "${YELLOW}[Test 2] Local IP Detection (en1)${NC}"
IP_EN1=$(ipconfig getifaddr en1 2>/dev/null || echo "")
if [ -n "$IP_EN1" ]; then
    pass "Detected IP on en1: $IP_EN1"
else
    info "No IP on en1"
fi

# Test 3: Any LAN IP Available
echo -e "${YELLOW}[Test 3] Any LAN IP Available${NC}"
DETECTED_IP=""
for iface in en0 en1 en2 en3 en4; do
    IP=$(ipconfig getifaddr $iface 2>/dev/null || echo "")
    if [ -n "$IP" ]; then
        # Check if it's a private IP
        if [[ "$IP" =~ ^192\.168\. ]] || [[ "$IP" =~ ^10\. ]] || [[ "$IP" =~ ^172\.(1[6-9]|2[0-9]|3[01])\. ]]; then
            DETECTED_IP="$IP"
            break
        fi
    fi
done

if [ -n "$DETECTED_IP" ]; then
    pass "Detected LAN IP: $DETECTED_IP"
else
    fail "No LAN IP detected on any interface"
fi

# Test 4: WiFi SSID Detection (networksetup method)
echo -e "${YELLOW}[Test 4] WiFi SSID Detection (networksetup)${NC}"
SSID_NETWORKSETUP=$(/usr/sbin/networksetup -getairportnetwork en0 2>/dev/null | sed 's/Current Wi-Fi Network: //' || echo "")
if [ -n "$SSID_NETWORKSETUP" ] && [ "$SSID_NETWORKSETUP" != "You are not associated with an AirPort network." ]; then
    pass "Detected WiFi SSID via networksetup: $SSID_NETWORKSETUP"
else
    info "networksetup method did not return SSID"
fi

# Test 5: WiFi SSID Detection (airport method)
echo -e "${YELLOW}[Test 5] WiFi SSID Detection (airport)${NC}"
AIRPORT_PATH="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
if [ -f "$AIRPORT_PATH" ]; then
    SSID_AIRPORT=$($AIRPORT_PATH -I 2>/dev/null | grep ' SSID' | cut -d ':' -f 2 | tr -d ' ' || echo "")
    if [ -n "$SSID_AIRPORT" ]; then
        pass "Detected WiFi SSID via airport: $SSID_AIRPORT"
    else
        info "airport method did not return SSID"
    fi
else
    info "airport utility not found at expected path"
fi

# Test 6: WiFi Interface Active
echo -e "${YELLOW}[Test 6] WiFi Interface Active${NC}"
WIFI_POWER=$(/usr/sbin/networksetup -getairportpower en0 2>/dev/null | grep -i "on" || echo "")
if [ -n "$WIFI_POWER" ]; then
    pass "WiFi is enabled"
else
    fail "WiFi appears to be disabled"
fi

# Test 7: Endpoint URL Generation
echo -e "${YELLOW}[Test 7] Endpoint URL Generation${NC}"
if [ -n "$DETECTED_IP" ]; then
    ENDPOINT="http://${DETECTED_IP}:8003/hive/endpoint/"
    pass "Generated endpoint URL: $ENDPOINT"
else
    fail "Cannot generate endpoint URL without IP"
fi

# Test 8: DNS Resolution
echo -e "${YELLOW}[Test 8] DNS Resolution${NC}"
if host google.com &>/dev/null; then
    pass "DNS resolution working"
else
    fail "DNS resolution failed"
fi

# Test 9: Internet Connectivity
echo -e "${YELLOW}[Test 9] Internet Connectivity${NC}"
if curl -s --max-time 5 https://hub.docker.com &>/dev/null; then
    pass "Internet connectivity confirmed (can reach Docker Hub)"
else
    fail "Cannot reach Docker Hub (internet may be down)"
fi

# Test 10: Local Endpoint Test (if containers running)
echo -e "${YELLOW}[Test 10] Local OpenMoxie Endpoint${NC}"
if curl -s --max-time 3 http://localhost:8001/hive/setup &>/dev/null; then
    pass "OpenMoxie server responding on localhost:8001"
elif curl -s --max-time 3 http://localhost:8003/hive/endpoint/ &>/dev/null; then
    pass "OpenMoxie endpoint responding on localhost:8003"
else
    info "OpenMoxie not currently running (will start with app)"
fi

# Summary
echo ""
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

# Show detected configuration
echo -e "${BLUE}=== Detected Configuration ===${NC}"
echo "  LAN IP:   ${DETECTED_IP:-Not detected}"
echo "  WiFi:     ${SSID_NETWORKSETUP:-${SSID_AIRPORT:-Not detected}}"
echo "  Endpoint: ${ENDPOINT:-Not generated}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All network tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}Some tests had issues. Review above for details.${NC}"
    exit 1
fi
