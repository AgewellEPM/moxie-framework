#!/bin/bash
# Test Docker setup for SimpleMoxieSwitcher
# Validates Docker installation, daemon, and container setup

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

echo -e "${BLUE}=== Docker Setup Tests ===${NC}"
echo ""

# Test 1: Docker Desktop Installation
echo -e "${YELLOW}[Test 1] Docker Desktop Installation${NC}"
if [ -d "/Applications/Docker.app" ]; then
    pass "Docker Desktop is installed at /Applications/Docker.app"
else
    fail "Docker Desktop not found at /Applications/Docker.app"
fi

# Test 2: Docker CLI Available
echo -e "${YELLOW}[Test 2] Docker CLI Available${NC}"
DOCKER_PATH=""
for path in /usr/local/bin/docker /opt/homebrew/bin/docker /usr/bin/docker; do
    if [ -f "$path" ]; then
        DOCKER_PATH="$path"
        break
    fi
done

if [ -n "$DOCKER_PATH" ]; then
    pass "Docker CLI found at $DOCKER_PATH"
else
    fail "Docker CLI not found in standard paths"
fi

# Test 3: Docker Daemon Running
echo -e "${YELLOW}[Test 3] Docker Daemon Running${NC}"
if docker info &>/dev/null; then
    pass "Docker daemon is running"
else
    fail "Docker daemon is not running (try starting Docker Desktop)"
fi

# Test 4: Docker Compose Available
echo -e "${YELLOW}[Test 4] Docker Compose Available${NC}"
if docker-compose version &>/dev/null || docker compose version &>/dev/null; then
    pass "Docker Compose is available"
else
    fail "Docker Compose not found"
fi

# Test 5: OpenMoxie Server Image
echo -e "${YELLOW}[Test 5] OpenMoxie Server Image${NC}"
if docker images | grep -q "openmoxie/openmoxie-server"; then
    pass "openmoxie/openmoxie-server image exists locally"
else
    echo -e "${YELLOW}  INFO${NC}: Image not cached locally, attempting pull..."
    if docker pull openmoxie/openmoxie-server:latest &>/dev/null; then
        pass "openmoxie/openmoxie-server image pulled successfully"
    else
        fail "Failed to pull openmoxie/openmoxie-server image"
    fi
fi

# Test 6: OpenMoxie MQTT Image
echo -e "${YELLOW}[Test 6] OpenMoxie MQTT Image${NC}"
if docker images | grep -q "openmoxie/openmoxie-mqtt"; then
    pass "openmoxie/openmoxie-mqtt image exists locally"
else
    echo -e "${YELLOW}  INFO${NC}: Image not cached locally, attempting pull..."
    if docker pull openmoxie/openmoxie-mqtt:latest &>/dev/null; then
        pass "openmoxie/openmoxie-mqtt image pulled successfully"
    else
        fail "Failed to pull openmoxie/openmoxie-mqtt image"
    fi
fi

# Test 7: Port 8001 Available
echo -e "${YELLOW}[Test 7] Port 8001 Available${NC}"
if ! lsof -i :8001 &>/dev/null; then
    pass "Port 8001 is available"
else
    PROCESS=$(lsof -i :8001 | tail -1 | awk '{print $1}')
    if [[ "$PROCESS" == "com.docke"* ]] || [[ "$PROCESS" == "docker"* ]]; then
        pass "Port 8001 is in use by Docker (expected)"
    else
        fail "Port 8001 is in use by: $PROCESS"
    fi
fi

# Test 8: Port 8003 Available
echo -e "${YELLOW}[Test 8] Port 8003 Available${NC}"
if ! lsof -i :8003 &>/dev/null; then
    pass "Port 8003 is available"
else
    PROCESS=$(lsof -i :8003 | tail -1 | awk '{print $1}')
    if [[ "$PROCESS" == "com.docke"* ]] || [[ "$PROCESS" == "docker"* ]]; then
        pass "Port 8003 is in use by Docker (expected)"
    else
        fail "Port 8003 is in use by: $PROCESS"
    fi
fi

# Test 9: Port 8883 Available (MQTT)
echo -e "${YELLOW}[Test 9] Port 8883 Available (MQTT)${NC}"
if ! lsof -i :8883 &>/dev/null; then
    pass "Port 8883 is available"
else
    PROCESS=$(lsof -i :8883 | tail -1 | awk '{print $1}')
    if [[ "$PROCESS" == "com.docke"* ]] || [[ "$PROCESS" == "docker"* ]]; then
        pass "Port 8883 is in use by Docker (expected)"
    else
        fail "Port 8883 is in use by: $PROCESS"
    fi
fi

# Test 10: OpenMoxie Directory
echo -e "${YELLOW}[Test 10] OpenMoxie Directory${NC}"
if [ -d "$HOME/OpenMoxie" ]; then
    pass "OpenMoxie directory exists at ~/OpenMoxie"
    if [ -f "$HOME/OpenMoxie/docker-compose.yml" ]; then
        pass "docker-compose.yml exists"
    else
        fail "docker-compose.yml missing from ~/OpenMoxie"
    fi
else
    echo -e "${YELLOW}  INFO${NC}: ~/OpenMoxie directory will be created on first run"
    pass "Directory check noted (will be created automatically)"
fi

# Summary
echo ""
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All Docker tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please address the issues above.${NC}"
    exit 1
fi
