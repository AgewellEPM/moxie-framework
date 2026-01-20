# Building SimpleMoxieSwitcher for Linux

Complete guide to building SimpleMoxieSwitcher from source on Linux.

---

## 📋 Prerequisites

### Required Tools
- **CMake 3.20+**
- **C++ Compiler** (GCC 11+ or Clang 14+)
- **Qt 6.5+**
- **Git**

### Optional Tools
- **Ninja** (faster builds than Make)
- **ccache** (faster rebuilds)
- **clang-tidy** (code analysis)
- **clang-format** (code formatting)

---

## 🔧 Installing Dependencies

### Ubuntu 22.04 / Debian 12
```bash
# Core build tools
sudo apt update
sudo apt install build-essential cmake ninja-build git

# Qt 6
sudo apt install qt6-base-dev qt6-declarative-dev qt6-charts-dev \
  qt6-tools-dev qt6-l10n-tools qml6-module-qtquick \
  qml6-module-qtquick-controls qml6-module-qtquick-layouts

# Additional libraries
sudo apt install libmosquitto-dev libcurl4-openssl-dev \
  libssl-dev qrencode libsqlite3-dev

# Docker
sudo apt install docker-ce docker-ce-cli containerd.io

# Optional
sudo apt install ccache clang-tidy clang-format
```

### Ubuntu 24.04 LTS
```bash
# Same as 22.04 but Qt 6.6 is available
sudo apt update
sudo apt install build-essential cmake ninja-build git \
  qt6-base-dev qt6-declarative-dev qt6-charts-dev \
  libmosquitto-dev docker-ce libcurl4-openssl-dev \
  libssl-dev qrencode
```

### Fedora 40+
```bash
# Core build tools
sudo dnf groupinstall "Development Tools"
sudo dnf install cmake ninja-build git

# Qt 6
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel \
  qt6-qtcharts-devel qt6-qttools-devel

# Additional libraries
sudo dnf install mosquitto-devel libcurl-devel openssl-devel \
  qrencode-devel sqlite-devel

# Docker
sudo dnf install docker-ce docker-ce-cli containerd.io

# Optional
sudo dnf install ccache clang-tools-extra
```

### Arch Linux
```bash
# Core build tools
sudo pacman -S base-devel cmake ninja git

# Qt 6
sudo pacman -S qt6-base qt6-declarative qt6-charts qt6-tools

# Additional libraries
sudo pacman -S mosquitto libcurl openssl qrencode sqlite

# Docker
sudo pacman -S docker

# Optional
sudo pacman -S ccache clang
```

---

## 📥 Clone Repository

```bash
# Clone main repository
git clone https://github.com/openmoxie/SimpleMoxieSwitcher-Linux.git
cd SimpleMoxieSwitcher-Linux

# If there are submodules (future)
git submodule update --init --recursive
```

---

## 🏗️ Build Instructions

### Standard Build (Release)
```bash
# Configure
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build -j$(nproc)

# Output: build/SimpleMoxieSwitcher
```

### Debug Build
```bash
# Configure with debug symbols
cmake -B build-debug -DCMAKE_BUILD_TYPE=Debug

# Build
cmake --build build-debug -j$(nproc)

# Run with debugging
gdb ./build-debug/SimpleMoxieSwitcher
```

### Build with Ninja (Faster)
```bash
# Configure with Ninja generator
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release

# Build
ninja -C build

# Much faster parallel builds
```

### Build with ccache (Faster Rebuilds)
```bash
# Configure with ccache
cmake -B build -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_COMPILER_LAUNCHER=ccache

# Subsequent builds will be much faster
cmake --build build -j$(nproc)
```

---

## 🧪 Running Tests

```bash
# Build tests
cmake --build build --target tests

# Run all tests
ctest --test-dir build --output-on-failure

# Run specific test
./build/tests/ViewModelTests

# Run with verbose output
ctest --test-dir build --verbose
```

---

## 📦 Creating Packages

### AppImage (Universal)
```bash
# Install linuxdeploy
wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
chmod +x linuxdeploy-x86_64.AppImage

# Build AppImage
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build
DESTDIR=AppDir cmake --install build
./linuxdeploy-x86_64.AppImage --appdir AppDir --output appimage

# Output: SimpleMoxieSwitcher-x86_64.AppImage
```

### .deb Package (Debian/Ubuntu)
```bash
# Configure with CPack
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build

# Create .deb package
cd build
cpack -G DEB

# Output: simplemoxieswitcher_1.0.0_amd64.deb
```

### .rpm Package (Fedora/RHEL)
```bash
# Configure with CPack
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build

# Create .rpm package
cd build
cpack -G RPM

# Output: simplemoxieswitcher-1.0.0-1.x86_64.rpm
```

### Flatpak
```bash
# Install flatpak-builder
sudo apt install flatpak-builder  # Ubuntu/Debian
sudo dnf install flatpak-builder  # Fedora

# Build Flatpak
flatpak-builder --repo=repo build-dir \
  packaging/flatpak/org.openmoxie.SimpleMoxieSwitcher.yml

# Install locally
flatpak-builder --user --install build-dir \
  packaging/flatpak/org.openmoxie.SimpleMoxieSwitcher.yml
```

---

## 🛠️ Advanced Build Options

### Custom Qt Installation
```bash
# If Qt is not in standard location
cmake -B build -DCMAKE_PREFIX_PATH="/opt/Qt/6.6.0/gcc_64"
```

### Static Linking
```bash
# Build with static Qt (requires static Qt build)
cmake -B build -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF
```

### Cross-Compilation
```bash
# Example: Build for ARM64 from x86_64
cmake -B build-arm64 \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/linux-aarch64.cmake
```

### Profile-Guided Optimization (PGO)
```bash
# Step 1: Build with profiling
cmake -B build-pgo -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="-fprofile-generate"
cmake --build build-pgo

# Step 2: Run to generate profile data
./build-pgo/SimpleMoxieSwitcher
# (Use the application for typical workloads)

# Step 3: Rebuild with profile data
cmake -B build -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_FLAGS="-fprofile-use"
cmake --build build
```

---

## 🐛 Troubleshooting

### Qt Not Found
```bash
# Add Qt to CMAKE_PREFIX_PATH
export CMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/cmake

# Or install qt6-base-dev
sudo apt install qt6-base-dev
```

### Missing QML Modules
```bash
# Install QML modules
sudo apt install qml6-module-qtquick \
  qml6-module-qtquick-controls \
  qml6-module-qtquick-layouts
```

### Mosquitto Library Not Found
```bash
# Install mosquitto development files
sudo apt install libmosquitto-dev  # Ubuntu/Debian
sudo dnf install mosquitto-devel   # Fedora
```

### Docker Permission Denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in
```

---

## 📊 Build Performance

### Typical Build Times (Release)
- **Full build** (8-core CPU): ~3-5 minutes
- **Incremental build**: ~30-60 seconds
- **With ccache** (second build): ~10-20 seconds

### Reducing Build Time
```bash
# Use Ninja
cmake -B build -G Ninja

# Use ccache
cmake -B build -DCMAKE_CXX_COMPILER_LAUNCHER=ccache

# Limit parallel jobs (if running out of memory)
cmake --build build -j4
```

---

## 🔍 Code Quality Tools

### Clang-Tidy (Static Analysis)
```bash
# Configure with clang-tidy
cmake -B build -DCMAKE_CXX_CLANG_TIDY="clang-tidy;-checks=*"

# Build (will run clang-tidy on each file)
cmake --build build
```

### Clang-Format (Code Formatting)
```bash
# Format all source files
find src -name "*.cpp" -o -name "*.h" | xargs clang-format -i

# Check formatting without modifying
find src -name "*.cpp" -o -name "*.h" | xargs clang-format --dry-run
```

### Valgrind (Memory Leak Detection)
```bash
# Build with debug symbols
cmake -B build -DCMAKE_BUILD_TYPE=Debug

# Run with valgrind
valgrind --leak-check=full ./build/SimpleMoxieSwitcher
```

---

## 📝 Environment Variables

```bash
# Qt platform plugin
export QT_QPA_PLATFORM=wayland  # or xcb for X11

# Enable Qt logging
export QT_LOGGING_RULES="*.debug=true"

# Qt scale factor (for HiDPI)
export QT_SCALE_FACTOR=1.5

# Enable QML debugging
export QML_IMPORT_TRACE=1
```

---

## 🚀 Installing

### System-Wide Installation
```bash
# Build
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Install (requires sudo)
sudo cmake --install build

# Uninstall
sudo xargs rm < build/install_manifest.txt
```

### User Installation
```bash
# Install to ~/.local
cmake -B build -DCMAKE_INSTALL_PREFIX=~/.local
cmake --build build
cmake --install build

# Run
~/.local/bin/SimpleMoxieSwitcher
```

---

**Last Updated:** January 10, 2026
**Qt Version:** 6.5+
**CMake Version:** 3.20+
**Status:** ✅ Production Ready
