# SimpleMoxieSwitcher - Linux Port Plan

**Date:** January 10, 2026
**Status:** 🚀 PLANNING PHASE
**Target:** Create Linux version with 100% feature parity with Windows/macOS

---

## 🎯 Project Goals

### Primary Objectives:
1. ✅ 100% feature parity with Windows and macOS versions
2. ✅ Native Linux desktop integration
3. ✅ Support for major Linux distros (Ubuntu, Fedora, Debian, Arch)
4. ✅ Maintain consistent UX across all platforms
5. ✅ Use modern, maintainable technology stack

### Target Distributions:
- Ubuntu 22.04+ (LTS priority)
- Fedora 38+
- Debian 12+
- Arch Linux (rolling)
- Pop!_OS
- Linux Mint

---

## 🔍 GUI Framework Analysis

### Option 1: Qt/QML ⭐ RECOMMENDED
**Pros:**
- ✅ Native C++ performance
- ✅ Most similar to Windows WPF architecture
- ✅ Excellent desktop integration
- ✅ QML markup similar to XAML/SwiftUI
- ✅ Mature, stable, widely used
- ✅ Cross-platform (can compile for Windows/macOS too!)
- ✅ Built-in theming system
- ✅ Excellent documentation

**Cons:**
- ❌ Larger binary size (~50-80MB)
- ❌ LGPL licensing (must link dynamically)
- ❌ Steeper learning curve for QML

**Architecture Pattern:**
```
SimpleMoxieSwitcher-Linux/
├── src/
│   ├── main.cpp              # Qt application entry
│   ├── models/               # C++ data models
│   ├── viewmodels/           # C++ view models (Qt properties)
│   ├── services/             # C++ services (MQTT, Docker, AI)
│   └── qml/                  # QML views
│       ├── Main.qml
│       ├── Games/
│       │   ├── GamesMenuView.qml
│       │   ├── GamePlayerView.qml
│       │   └── KnowledgeQuestView.qml
│       ├── Analytics/
│       │   ├── UsageView.qml
│       │   └── MemoryView.qml
│       └── Controls/
│           ├── ControlsView.qml
│           └── MovementControlView.qml
├── resources/                # Icons, images, fonts
└── CMakeLists.txt
```

**Code Example (QML):**
```qml
// GamesMenuView.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#FF6B35" }
        GradientStop { position: 1.0; color: "#F7931E" }
    }

    GridView {
        id: gamesGrid
        model: gamesMenuViewModel.gameTypes

        delegate: GameModeCard {
            gameType: modelData
            onClicked: gamesMenuViewModel.selectGame(modelData)

            // Hover animation
            scale: hovered ? 1.05 : 1.0
            Behavior on scale {
                SpringAnimation {
                    spring: 2
                    damping: 0.2
                }
            }
        }
    }
}
```

**Estimated Development Time:** 6-8 weeks for full port

---

### Option 2: Flutter
**Pros:**
- ✅ Modern, fast development
- ✅ Hot reload for rapid iteration
- ✅ Beautiful Material Design out-of-box
- ✅ Dart language (easier than C++)
- ✅ Can share code with mobile versions
- ✅ Excellent animation framework

**Cons:**
- ❌ Still maturing for Linux desktop
- ❌ Larger binary size (~40-60MB)
- ❌ Less native desktop integration
- ❌ Limited plugin ecosystem for Linux

**Estimated Development Time:** 4-6 weeks for full port

---

### Option 3: GTK4 (GtkBuilder + Python)
**Pros:**
- ✅ Native GNOME look and feel
- ✅ Python development (fast prototyping)
- ✅ Good desktop integration
- ✅ Smaller binaries

**Cons:**
- ❌ Python packaging complexity
- ❌ Less similar to WPF/SwiftUI
- ❌ Performance concerns for complex UI

**Estimated Development Time:** 5-7 weeks for full port

---

### Option 4: Electron + React
**Pros:**
- ✅ Web technologies (familiar to many devs)
- ✅ Rapid development
- ✅ Can reuse web components

**Cons:**
- ❌ MASSIVE memory usage (200-500MB)
- ❌ Slow startup time
- ❌ Not truly native
- ❌ Battery drain on laptops

**Estimated Development Time:** 3-5 weeks for full port

---

## 🏆 RECOMMENDATION: Qt/QML

### Why Qt/QML?

1. **Architecture Similarity to WPF/SwiftUI**
   - QML markup language similar to XAML
   - MVVM pattern built-in
   - Property binding system
   - Easy to port existing Windows views

2. **Performance**
   - C++ backend for services
   - Hardware-accelerated QML rendering
   - Low memory footprint (~100-150MB)

3. **Desktop Integration**
   - Native system tray
   - D-Bus integration
   - Notifications
   - Theme support (light/dark)

4. **Maintainability**
   - Large community
   - Excellent documentation
   - Long-term Qt Company support
   - Used by KDE, VLC, Telegram, OBS Studio

5. **Cross-Platform Bonus**
   - Can compile same codebase for Windows/macOS
   - Potential to replace all 3 platforms with Qt (optional)

---

## 📋 Feature Porting Checklist

### Core Features (from Windows/macOS):
- [ ] Setup Wizard (7 steps)
- [ ] Child Profile Management
- [ ] Chat Interface with AI
- [ ] Story Time
- [ ] Games System
  - [ ] GamesMenuView
  - [ ] GamePlayerView (Trivia, Spelling, Movies, Video Games)
  - [ ] KnowledgeQuestView
  - [ ] QuestPlayerView
- [ ] Language Learning
  - [ ] LanguageLearningWizardView
  - [ ] LanguageSessionsView
  - [ ] LessonPlayerView
- [ ] Controls
  - [ ] ControlsView (movement, camera, volume)
  - [ ] MovementControlView
- [ ] Analytics
  - [ ] UsageView (cost tracking, charts)
  - [ ] MemoryView (3-panel visualization)
- [ ] Personality Management
  - [ ] CustomPersonalityView
  - [ ] Personality Switching (10+ personalities)
- [ ] Settings
- [ ] All Conversations View
- [ ] Documentation View
- [ ] Smart Home Integration (Alexa/Google)
- [ ] Music Player
- [ ] Camera Viewer
- [ ] Parent Authentication/PIN

### Backend Services:
- [ ] MQTT Communication (mosquitto-dev)
- [ ] Docker Integration (docker-ce)
- [ ] OpenMoxie Container Management
- [ ] AI Provider Integration (OpenAI, Anthropic, DeepSeek, Gemini)
- [ ] Memory Extraction & Storage (SQLite)
- [ ] Games Content Generation
- [ ] Language Learning Content Generation
- [ ] Story Generation
- [ ] Safety Logging
- [ ] Usage Tracking
- [ ] QR Code Generation (qrencode library)

### Linux-Specific Features:
- [ ] .desktop file for app launcher
- [ ] AppImage packaging
- [ ] .deb package (Debian/Ubuntu)
- [ ] .rpm package (Fedora/RHEL)
- [ ] Flatpak support
- [ ] System tray integration
- [ ] D-Bus service
- [ ] Auto-start on login
- [ ] System theme detection (light/dark)

---

## 🏗️ Project Structure

```
SimpleMoxieSwitcher-Linux/
├── CMakeLists.txt                    # Build configuration
├── README.md
├── LICENSE
├── .gitignore
├── packaging/                        # Packaging scripts
│   ├── appimage/
│   ├── deb/
│   ├── rpm/
│   └── flatpak/
├── resources/                        # Application resources
│   ├── icons/
│   │   ├── hicolor/
│   │   │   ├── 16x16/
│   │   │   ├── 32x32/
│   │   │   ├── 48x48/
│   │   │   ├── 128x128/
│   │   │   └── 256x256/
│   │   └── SimpleMoxieSwitcher.svg
│   ├── fonts/
│   ├── images/
│   └── qml.qrc                       # Qt resource file
├── src/                              # C++ source code
│   ├── main.cpp
│   ├── models/                       # Data models
│   │   ├── Personality.h
│   │   ├── ChildProfile.h
│   │   ├── Games.h
│   │   ├── LanguageLearning.h
│   │   ├── Memory.h
│   │   └── UsageRecord.h
│   ├── viewmodels/                   # View models (Qt properties)
│   │   ├── GamesMenuViewModel.h
│   │   ├── GamePlayerViewModel.h
│   │   ├── ChatViewModel.h
│   │   ├── StoryTimeViewModel.h
│   │   ├── ControlsViewModel.h
│   │   ├── UsageViewModel.h
│   │   └── MemoryViewModel.h
│   ├── services/                     # Business logic
│   │   ├── MQTTService.h             # MQTT pub/sub
│   │   ├── DockerService.h           # Docker integration
│   │   ├── AIProviderService.h       # Multi-provider AI
│   │   ├── MemoryExtractionService.h
│   │   ├── GameContentService.h
│   │   ├── LanguageLearningService.h
│   │   ├── StoryGenerationService.h
│   │   ├── SafetyService.h
│   │   └── UsageTrackingService.h
│   ├── repositories/                 # Data access
│   │   ├── UsageRepository.h
│   │   ├── MemoryRepository.h
│   │   ├── GamesRepository.h
│   │   └── ConversationsRepository.h
│   └── utils/                        # Utilities
│       ├── DIContainer.h
│       ├── LocalizationService.h
│       ├── PINService.h
│       └── QRCodeService.h
├── qml/                              # QML UI files
│   ├── Main.qml
│   ├── Components/                   # Reusable components
│   │   ├── MoxieSpeechBubble.qml
│   │   ├── GameModeCard.qml
│   │   ├── StatBadge.qml
│   │   └── GradientButton.qml
│   ├── Games/
│   │   ├── GamesMenuView.qml
│   │   ├── GamePlayerView.qml
│   │   ├── KnowledgeQuestView.qml
│   │   └── QuestPlayerView.qml
│   ├── LanguageLearning/
│   │   ├── LanguageLearningWizardView.qml
│   │   ├── LanguageSessionsView.qml
│   │   └── LessonPlayerView.qml
│   ├── Controls/
│   │   ├── ControlsView.qml
│   │   └── MovementControlView.qml
│   ├── Analytics/
│   │   ├── UsageView.qml
│   │   └── MemoryView.qml
│   ├── Chat/
│   │   ├── ChatInterfaceView.qml
│   │   └── ConversationsView.qml
│   ├── Story/
│   │   ├── StoryTimeView.qml
│   │   ├── StoryLibraryView.qml
│   │   └── StoryWizardView.qml
│   ├── Setup/
│   │   └── SetupWizardView.qml
│   ├── Settings/
│   │   ├── SettingsView.qml
│   │   ├── PersonalityEditorView.qml
│   │   └── ChildProfileView.qml
│   └── Personality/
│       └── CustomPersonalityView.qml
├── tests/                            # Unit tests
│   ├── ViewModelTests/
│   └── ServiceTests/
└── docs/                             # Documentation
    ├── BUILD.md
    ├── ARCHITECTURE.md
    └── CONTRIBUTING.md
```

---

## 🔧 Technology Stack

### Core Technologies:
- **Qt 6.5+** - GUI framework
- **QML** - Declarative UI language
- **C++20** - Backend language
- **CMake 3.20+** - Build system
- **SQLite** - Local database

### Linux Dependencies:
- **mosquitto-dev** - MQTT library
- **libqt6-dev** - Qt development files
- **docker-ce** - Docker engine
- **libcurl-dev** - HTTP requests
- **libssl-dev** - SSL/TLS
- **qrencode** - QR code generation

### Build Tools:
- **gcc 11+** or **clang 14+**
- **cmake 3.20+**
- **ninja** (optional, faster builds)
- **ccache** (optional, faster rebuilds)

---

## 📦 Packaging Strategy

### 1. AppImage (Universal Binary) ⭐ PRIMARY
**Pros:**
- Works on all distros
- No installation required
- Includes all dependencies
- Easy distribution

**Build:**
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target appimage
```

### 2. .deb Package (Debian/Ubuntu)
**Pros:**
- Native package manager integration
- Smaller download size
- System updates

**Build:**
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target deb
```

### 3. Flatpak (Sandboxed)
**Pros:**
- Sandboxed security
- Flathub distribution
- Easy permissions management

**Build:**
```bash
flatpak-builder --repo=repo build-dir org.openmoxie.SimpleMoxieSwitcher.yml
```

### 4. Snap (Ubuntu Store)
**Pros:**
- Ubuntu Software Center
- Auto-updates
- Confined execution

---

## 🎨 UI Porting Strategy

### Phase 1: Core Views (2 weeks)
1. Main Window + Navigation
2. SetupWizardView
3. ChatInterfaceView
4. ChildProfileView
5. SettingsView

### Phase 2: Games System (2 weeks)
1. GamesMenuView
2. GamePlayerView
3. KnowledgeQuestView
4. QuestPlayerView

### Phase 3: Language & Controls (1.5 weeks)
1. LanguageLearningWizardView
2. LanguageSessionsView
3. LessonPlayerView
4. ControlsView
5. MovementControlView

### Phase 4: Analytics (1 week)
1. UsageView
2. MemoryView

### Phase 5: Story & Misc (1 week)
1. StoryTimeView
2. StoryLibraryView
3. PersonalityEditorView
4. AllConversationsView

### Phase 6: Polish & Testing (1.5 weeks)
1. Theme integration
2. Animations
3. Accessibility
4. Performance optimization
5. Bug fixing

**Total Estimated Time:** 8 weeks

---

## 🚀 Next Steps

### Immediate Actions:
1. ✅ Create GitHub repository: `SimpleMoxieSwitcher-Linux`
2. ✅ Set up Qt 6 development environment
3. ✅ Create CMake project structure
4. ✅ Port core models from Windows (C# → C++)
5. ✅ Implement MQTT service (C++)
6. ✅ Create first QML view (Main.qml)
7. ✅ Port GamesMenuView as proof-of-concept

### Development Environment Setup:
```bash
# Ubuntu/Debian
sudo apt install qt6-base-dev qt6-declarative-dev \
  qt6-charts-dev cmake ninja-build \
  libmosquitto-dev docker-ce libcurl4-openssl-dev \
  libssl-dev qrencode

# Fedora
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel \
  qt6-qtcharts-devel cmake ninja-build \
  mosquitto-devel docker-ce libcurl-devel \
  openssl-devel qrencode-devel

# Arch
sudo pacman -S qt6-base qt6-declarative qt6-charts \
  cmake ninja mosquitto docker libcurl openssl qrencode
```

---

## 📊 Success Metrics

### Feature Parity:
- ✅ 40/40 views ported (100%)
- ✅ All services implemented
- ✅ All backend features working

### Performance:
- ✅ Startup time < 2 seconds
- ✅ Memory usage < 200MB
- ✅ Smooth 60fps animations

### Quality:
- ✅ Zero crashes in 1-hour test
- ✅ 80%+ unit test coverage
- ✅ All features tested on Ubuntu, Fedora, Arch

### Distribution:
- ✅ AppImage available for download
- ✅ .deb package for Debian/Ubuntu
- ✅ Flatpak on Flathub
- ✅ Documentation complete

---

## 💡 Key Challenges & Solutions

### Challenge 1: Docker Integration on Linux
**Problem:** Docker socket permissions
**Solution:** Add user to `docker` group, or use rootless Docker

### Challenge 2: MQTT Broker
**Problem:** mosquitto not running by default
**Solution:** Auto-detect and start mosquitto service via systemd

### Challenge 3: System Tray
**Problem:** Different tray implementations (GNOME vs KDE)
**Solution:** Use Qt's QSystemTrayIcon (handles both)

### Challenge 4: Theme Detection
**Problem:** No standard Linux theme API
**Solution:** Query GTK/Qt theme settings, fallback to system D-Bus

---

**Status:** 🚀 READY TO START
**Framework Decision:** Qt/QML ⭐
**Next Action:** Create GitHub repo and project structure

