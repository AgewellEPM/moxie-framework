# SimpleMoxieSwitcher - Linux Edition

**OpenMoxie Robot Controller for Linux**

Full-featured Qt/QML application with 100% feature parity with Windows and macOS versions.

---

## ✨ Features

### Core Features
- 💬 **AI Chat** - Interact with Moxie using OpenAI, Anthropic, DeepSeek, or Gemini
- 🎮 **Games System** - 5 game types: Trivia, Spelling Bee, Movie Lines, Video Games, Knowledge Quest
- 📚 **Language Learning** - Multi-step wizard with lessons and sessions
- 📖 **Story Time** - AI-generated stories with library and wizard
- 🎛️ **Robot Controls** - Movement, camera, volume, face emotions
- 📊 **Usage Analytics** - Track AI costs, usage trends, model comparison
- 🧠 **Memory Visualization** - 3-panel view of Moxie's memories
- 👤 **Personality Management** - 10+ personalities with custom creator
- ⚙️ **Settings** - Complete configuration and preferences

### Backend Services
- MQTT communication with Moxie robot
- Docker integration for OpenMoxie backend
- Multi-provider AI support (OpenAI, Anthropic, DeepSeek, Gemini)
- Memory extraction and storage
- Safety logging
- Usage tracking
- QR code generation

---

## 📦 Installation

### Ubuntu/Debian
```bash
# Download .deb package
wget https://github.com/openmoxie/SimpleMoxieSwitcher-Linux/releases/latest/download/simplemoxieswitcher_1.0.0_amd64.deb

# Install
sudo dpkg -i simplemoxieswitcher_1.0.0_amd64.deb
sudo apt-get install -f  # Install dependencies
```

### Fedora/RHEL
```bash
# Download .rpm package
wget https://github.com/openmoxie/SimpleMoxieSwitcher-Linux/releases/latest/download/simplemoxieswitcher-1.0.0-1.x86_64.rpm

# Install
sudo dnf install simplemoxieswitcher-1.0.0-1.x86_64.rpm
```

### Universal (AppImage)
```bash
# Download AppImage
wget https://github.com/openmoxie/SimpleMoxieSwitcher-Linux/releases/latest/download/SimpleMoxieSwitcher-1.0.0-x86_64.AppImage

# Make executable
chmod +x SimpleMoxieSwitcher-1.0.0-x86_64.AppImage

# Run
./SimpleMoxieSwitcher-1.0.0-x86_64.AppImage
```

### Flatpak
```bash
# Install from Flathub
flatpak install flathub org.openmoxie.SimpleMoxieSwitcher

# Run
flatpak run org.openmoxie.SimpleMoxieSwitcher
```

---

## 🔨 Building from Source

See [BUILD.md](BUILD.md) for detailed build instructions.

Quick start:
```bash
# Install dependencies (Ubuntu/Debian)
sudo apt install qt6-base-dev qt6-declarative-dev qt6-charts-dev \
  cmake ninja-build libmosquitto-dev docker-ce libcurl4-openssl-dev \
  libssl-dev qrencode

# Clone repository
git clone https://github.com/openmoxie/SimpleMoxieSwitcher-Linux.git
cd SimpleMoxieSwitcher-Linux

# Build
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)

# Run
./build/SimpleMoxieSwitcher
```

---

## 🚀 Quick Start

1. **First Launch** - Run the Setup Wizard to configure:
   - Parent PIN
   - WiFi credentials
   - OpenMoxie endpoint
   - AI API keys

2. **Create Child Profile** - Set up interests, goals, learning preferences

3. **Start Chatting** - Talk to Moxie via the Chat interface

4. **Play Games** - Try Trivia, Spelling Bee, or Knowledge Quest

5. **View Analytics** - Check usage and costs in the Analytics tab

---

## 📊 System Requirements

### Minimum
- **OS:** Ubuntu 22.04, Fedora 38, Debian 12, or equivalent
- **CPU:** Dual-core 2.0 GHz
- **RAM:** 4 GB
- **Disk:** 500 MB free space
- **Graphics:** OpenGL 3.3 compatible

### Recommended
- **OS:** Ubuntu 24.04 LTS or Fedora 40+
- **CPU:** Quad-core 2.5 GHz+
- **RAM:** 8 GB+
- **Disk:** 2 GB free space
- **Graphics:** Dedicated GPU with OpenGL 4.5

### Dependencies
- Qt 6.5+
- Docker CE 24.0+
- mosquitto (MQTT broker)
- OpenMoxie backend (bundled)

---

## 🌐 Network Configuration

SimpleMoxieSwitcher requires:
- **Docker**: For running OpenMoxie backend
- **MQTT**: Port 1883 (mosquitto)
- **OpenMoxie API**: Port 8003 (localhost)
- **Internet**: For AI provider APIs

---

## 🎨 Screenshots

### Games Arcade
![Games Menu](docs/screenshots/games-menu.png)

### Usage Analytics
![Usage Analytics](docs/screenshots/usage-analytics.png)

### Memory Visualization
![Memory View](docs/screenshots/memory-view.png)

### Chat Interface
![Chat](docs/screenshots/chat-interface.png)

---

## 🐛 Troubleshooting

### Docker Permission Denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in for changes to take effect
```

### MQTT Connection Failed
```bash
# Start mosquitto service
sudo systemctl start mosquitto
sudo systemctl enable mosquitto

# Check status
sudo systemctl status mosquitto
```

### Qt Platform Plugin Error
```bash
# Install Qt platform plugins
sudo apt install qt6-qpa-plugins  # Ubuntu/Debian
sudo dnf install qt6-qtbase-gui   # Fedora
```

### Missing API Keys
1. Go to Settings → AI Providers
2. Add your API keys for OpenAI, Anthropic, etc.
3. Keys are stored securely in your home directory

---

## 📝 Configuration Files

### Location
```
~/.config/OpenMoxie/SimpleMoxieSwitcher/
├── config.json          # Main configuration
├── profiles/            # Child profiles
├── memories/            # Extracted memories
├── usage/               # Usage tracking
└── logs/                # Application logs
```

### OpenMoxie Backend
```
~/OpenMoxie/
├── docker-compose.yml
├── hive/                # Django backend
└── data/                # Database
```

---

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development
```bash
# Clone with submodules
git clone --recursive https://github.com/openmoxie/SimpleMoxieSwitcher-Linux.git

# Build in debug mode
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build

# Run tests
ctest --test-dir build
```

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 🔗 Links

- **Website**: https://openmoxie.org
- **Documentation**: https://docs.openmoxie.org
- **Issues**: https://github.com/openmoxie/SimpleMoxieSwitcher-Linux/issues
- **Discussions**: https://github.com/openmoxie/SimpleMoxieSwitcher-Linux/discussions

---

## 💬 Support

- **Discord**: https://discord.gg/openmoxie
- **Email**: support@openmoxie.org
- **Forum**: https://community.openmoxie.org

---

## 🙏 Acknowledgments

- **Embodied Inc.** - Original Moxie robot creators
- **Qt Company** - Qt framework
- **Eclipse Mosquitto** - MQTT broker
- **OpenAI, Anthropic, Google, DeepSeek** - AI providers

---

**Version:** 1.0.0
**Platform:** Linux (Qt 6 / QML)
**Status:** ✅ Production Ready
**Parity:** 100% with Windows/macOS versions
