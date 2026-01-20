#!/bin/bash
# Reset SimpleMoxieSwitcher to fresh install state for testing
# Usage: ./reset_for_testing.sh [--keep-docker]

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== SimpleMoxieSwitcher Fresh Install Reset ===${NC}"
echo ""

KEEP_DOCKER=false
if [[ "$1" == "--keep-docker" ]]; then
    KEEP_DOCKER=true
    echo -e "${YELLOW}Keeping Docker containers (--keep-docker flag set)${NC}"
fi

# 1. Clear UserDefaults
echo -e "${YELLOW}[1/4] Clearing app preferences...${NC}"
defaults delete com.simplemoxieswitcher 2>/dev/null || true
defaults delete SimpleMoxieSwitcher 2>/dev/null || true
echo -e "${GREEN}  - App preferences cleared${NC}"

# 2. Clear Keychain items (PIN storage)
echo -e "${YELLOW}[2/4] Clearing Keychain items...${NC}"
security delete-generic-password -s "SimpleMoxieSwitcher" 2>/dev/null || true
security delete-generic-password -s "MoxieParentPIN" 2>/dev/null || true
echo -e "${GREEN}  - Keychain items cleared${NC}"

# 3. Stop and remove Docker containers (optional)
if [[ "$KEEP_DOCKER" == false ]]; then
    echo -e "${YELLOW}[3/4] Stopping and removing Docker containers...${NC}"
    docker stop openmoxie-server openmoxie-mqtt 2>/dev/null || true
    docker rm openmoxie-server openmoxie-mqtt 2>/dev/null || true
    echo -e "${GREEN}  - Docker containers removed${NC}"
else
    echo -e "${YELLOW}[3/4] Skipping Docker container removal${NC}"
fi

# 4. Clear OpenMoxie local data (but keep docker-compose.yml)
echo -e "${YELLOW}[4/4] Clearing OpenMoxie local data...${NC}"
rm -rf ~/OpenMoxie/local/work/* 2>/dev/null || true
echo -e "${GREEN}  - Local data cleared${NC}"

echo ""
echo -e "${GREEN}=== Reset Complete ===${NC}"
echo ""
echo "The app is now in a fresh install state."
echo "Launch SimpleMoxieSwitcher to test the setup wizard."
echo ""
if [[ "$KEEP_DOCKER" == true ]]; then
    echo "Note: Docker containers were kept. Use without --keep-docker to remove them."
fi
