# SimpleMoxieSwitcher Installation Guide

## Platform Requirements

This is a **macOS-only** application. It will NOT run on Windows or Linux.

## Prerequisites

### Required Software

1. **macOS** (tested on macOS 13+)
   - This is a native macOS application
   - Will NOT work on Windows or Linux

2. **Docker Desktop for Mac** (REQUIRED)
   - Download: https://www.docker.com/products/docker-desktop
   - OpenMoxie backend runs in Docker
   - **The app will check for Docker on startup and show an error if it's not installed or running**

3. **Mosquitto MQTT Broker**
   ```bash
   brew install mosquitto
   brew services start mosquitto
   ```

4. **Xcode Command Line Tools** (for building from source)
   ```bash
   xcode-select --install
   ```

5. **Swift 5.9+** (comes with Xcode Command Line Tools)

### Required Services

1. **OpenMoxie Docker Container**
   - You need the OpenMoxie Django backend running in Docker
   - This connects to your physical Moxie robot
   - Configuration required for your specific Moxie device

2. **OpenAI API Key**
   - Sign up at https://platform.openai.com
   - Export in your environment:
     ```bash
     export OPENAI_API_KEY="sk-..."
     ```

3. **Physical Moxie Robot**
   - Connected to the same network
   - Configured in OpenMoxie backend
   - MQTT connection established

## Installation Steps

### Option A: Download Pre-built App (Recommended)

1. **Download the latest release**
   - Download `SimpleMoxieSwitcher-v1.0.0.zip` from the releases page
   - Unzip the file
   - Drag `SimpleMoxieSwitcher.app` to your Applications folder

2. **First Launch**
   - Right-click the app and select "Open" (required for first launch)
   - If you see a security warning, go to System Preferences → Security & Privacy → Click "Open Anyway"
   - **The app will check if Docker is installed and running**
   - If Docker is not found, you'll see a dialog with:
     - Link to download Docker Desktop
     - "Retry" button to check again after installing
     - "Quit" button to exit

3. **Install Docker Desktop** (if not already installed)
   - Click "Download Docker" in the error dialog, or visit https://www.docker.com/products/docker-desktop
   - Install Docker Desktop
   - Start Docker Desktop and wait for it to finish starting
   - Click "Retry" in the SimpleMoxieSwitcher dialog

4. **Continue Setup**
   - Once Docker is detected, the app will start normally
   - Configure your OpenAI API key in settings
   - Set up parental controls (optional)
   - Connect your Moxie robot

### Option B: Build from Source

1. **Clone the Repository**
   ```bash
   cd ~/Desktop
   git clone <repository-url> SimpleMoxieSwitcher
   cd SimpleMoxieSwitcher
   ```

2. **Install Mosquitto**
   ```bash
   # Install via Homebrew
   brew install mosquitto

   # Start the service
   brew services start mosquitto

   # Verify it's running
   brew services list | grep mosquitto
   ```

3. **Set Up OpenMoxie Docker**
   ```bash
   # Make sure Docker Desktop is running

   # Pull/run the OpenMoxie container
   # (You'll need the specific OpenMoxie setup instructions)
   docker ps  # Should show OpenMoxie container running
   ```

4. **Configure Environment**
   ```bash
   # Set your OpenAI API key
   export OPENAI_API_KEY="sk-your-key-here"

   # Add to ~/.zshrc or ~/.bash_profile to persist:
   echo 'export OPENAI_API_KEY="sk-your-key-here"' >> ~/.zshrc
   ```

5. **Build the Application**
   ```bash
   # Build using Swift Package Manager
   swift build

   # Or build and run
   swift run
   ```

6. **Create App Bundle** (Optional)
   ```bash
   # Make the script executable
   chmod +x create_app_bundle.sh

   # Run the script to create .app bundle
   ./create_app_bundle.sh

   # The app will be at SimpleMoxieSwitcher.app
   open SimpleMoxieSwitcher.app
   ```

## Verifying Installation

### Check Docker Container
```bash
docker ps
# Should show OpenMoxie container running on port 8000
```

### Check MQTT Broker
```bash
brew services list | grep mosquitto
# Should show "started"

# Test MQTT connection
mosquitto_sub -h localhost -t test/topic -v
```

### Check OpenMoxie Backend
```bash
curl http://localhost:8000/api/health
# Should return health check response
```

### Test Moxie Connection
```bash
# Subscribe to Moxie's MQTT topics
timeout 3 mosquitto_sub -h localhost -t "moxie/#" -v
# Should show Moxie status messages if connected
```

## MQTT Configuration

The app reads MQTT settings from UserDefaults:

- Host: `mqtt_host` (default `192.168.1.128`)
- Port: `mqtt_port` (default `1883`)
- TLS:  `mqtt_tls` (default `false`)
- mosquitto_sub path: `mosquitto_sub_path` (optional; otherwise auto-detected)

You can set these via Terminal:

```bash
defaults write com.moxie.SimpleMoxieSwitcher mqtt_host -string "localhost"
defaults write com.moxie.SimpleMoxieSwitcher mqtt_port -int 1883
defaults write com.moxie.SimpleMoxieSwitcher mqtt_tls -bool false
# Optional override if Homebrew path differs
defaults write com.moxie.SimpleMoxieSwitcher mosquitto_sub_path -string "/opt/homebrew/bin/mosquitto_sub"
```

## Troubleshooting

### "Docker not running" error on startup
This is the most common issue for new users.

**Solution:**
1. Install Docker Desktop from https://www.docker.com/products/docker-desktop
2. Launch Docker Desktop
3. Wait for Docker to fully start (you'll see the Docker icon in the menu bar)
4. Click "Retry" in SimpleMoxieSwitcher

**To verify Docker is running:**
```bash
docker ps
# Should show a list of running containers
```

### "Mosquitto connection refused"
```bash
# Restart mosquitto
brew services restart mosquitto

# Check if port 1883 is in use
lsof -i :1883
```

### "OpenAI API key not found"
```bash
# Verify the key is set
echo $OPENAI_API_KEY

# If empty, set it:
export OPENAI_API_KEY="sk-your-key-here"
```

### "Can't connect to Moxie"
1. Ensure Moxie is on the same network
2. Check OpenMoxie backend is running
3. Verify Moxie device_id in OpenMoxie database
4. Check MQTT broker is accessible

### "Build failed"
```bash
# Clean build directory
rm -rf .build

# Rebuild
swift build
```

### macOS Security Warning
1. Open System Preferences → Security & Privacy
2. Click "Open Anyway" button
3. Re-launch the app

## What This App Does

SimpleMoxieSwitcher provides:
- Direct control of Moxie robot via MQTT
- AI-powered conversations (multiple personalities)
- Interactive storytelling (choose-your-adventure)
- Educational games (trivia, spelling, movie quotes)
- Language learning sessions
- Knowledge Quest RPG
- Memory extraction and conversation history
- Smart home integration (in development)

## What This App Does NOT Include

This is a developer tool, not a consumer app. It does **NOT** include:
- Automatic installation of Docker (but the app will detect if it's missing and show installation instructions)
- Automatic setup of OpenMoxie backend
- Automatic Moxie robot pairing
- MQTT broker auto-configuration
- OpenAI API key management UI (you must set it via environment variable or settings)
- Windows/Linux support
- iOS/iPadOS version
- App Store distribution
- Automatic updates
- Commercial customer support

## System Requirements

- **OS**: macOS 13.0 or later
- **RAM**: 8GB minimum (16GB recommended)
- **Storage**: 10GB free space (includes Docker)
- **Network**: Same WiFi as Moxie robot
- **Docker**: Docker Desktop for Mac (REQUIRED)
- **Dependencies**: Homebrew, Swift 5.9+

## Dependencies Auto-Installed by Swift Package Manager

The following Swift packages are automatically downloaded when building:
- SwiftUI (built-in)
- Foundation (built-in)
- Combine (built-in)
- AVFoundation (built-in)

## Manual Dependencies (NOT Auto-Installed)

You must manually install:
1. **Docker Desktop** (REQUIRED - app will check on startup)
2. Mosquitto MQTT broker via Homebrew
3. OpenMoxie Docker container
4. OpenAI API key (obtain from OpenAI)

## For Developers

### Running from Xcode
1. Open Package.swift in Xcode
2. Select SimpleMoxieSwitcher scheme
3. Build and run (⌘R)

### Running from Command Line
```bash
swift run
```

### Running Tests
```bash
swift test
```

### Development Requirements
- Xcode 15.0+
- Swift 5.9+
- macOS 13.0+ SDK

## License

[Add your license information here]

## Support

This is a community/research tool. For issues:
1. Check the troubleshooting section above
2. Verify all dependencies are installed
3. Check Docker and MQTT logs
4. Review OpenMoxie backend logs

## Disclaimer

This software is provided "as is" for research and development purposes. It requires technical knowledge of Docker, MQTT, and macOS development. Not intended for general consumer use.
