# OpenMoxie 2.0 Companion App Framework

A cross-platform framework for building companion applications for interactive robots and AI assistants. This is the open-source base framework - developers need to add their own AI model integrations and content.

## Overview

This framework provides the foundation for building educational and interactive companion apps with:
- Cross-platform support (macOS, iOS, Windows, Linux)
- Modular architecture for easy extension
- Safety-first design for child-friendly applications
- Real-time communication capabilities
- Multi-provider AI integration support

## Project Structure

```
moxie/
├── SimpleMoxieSwitcher/          # macOS/iOS SwiftUI app
├── SimpleMoxieSwitcher-Windows/  # Windows WPF app
├── SimpleMoxieSwitcher-Linux/    # Linux Qt app
├── SimpleMoxieSwitcherApp/       # iOS-specific components
└── SimpleMoxieSwitcherApp.xcodeproj/
```

## Requirements

### macOS/iOS
- Xcode 15.0+
- Swift 5.9+
- macOS 14.0+ / iOS 17.0+

### Windows
- Visual Studio 2022+
- .NET 8.0+
- Windows 10/11

### Linux
- Qt 6.0+
- CMake 3.20+
- GCC 11+ or Clang 14+

## Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/moxie.git
cd moxie
```

### 2. Configure AI Providers

You'll need to add your own AI provider configurations:

1. Edit `SimpleMoxieSwitcher/Sources/SimpleMoxieSwitcher/Services/AIProviderManager.swift`
2. Replace placeholder endpoints with actual AI service URLs
3. Add your model configurations
4. Implement API key management

### 3. Build for Your Platform

#### macOS
```bash
cd SimpleMoxieSwitcher
swift build --configuration release
```

#### iOS
Open `SimpleMoxieSwitcherApp.xcodeproj` in Xcode and build

#### Windows
Open `SimpleMoxieSwitcher-Windows/SimpleMoxieSwitcher.sln` in Visual Studio

#### Linux
```bash
cd SimpleMoxieSwitcher-Linux
mkdir build && cd build
cmake ..
make
```

## Core Features to Implement

### AI Integration
- [ ] Add your AI model API endpoints
- [ ] Implement model selection logic
- [ ] Add API key management
- [ ] Configure rate limiting and safety filters

### Content System
- [ ] Design age-appropriate content
- [ ] Implement content filtering
- [ ] Add educational modules
- [ ] Create interactive experiences

### Safety Features
- [ ] Implement parental controls
- [ ] Add content moderation
- [ ] Create usage monitoring
- [ ] Set up data privacy protections

## Architecture

The app follows MVVM architecture with:
- **Models**: Data structures and business logic
- **Views**: SwiftUI/WPF/Qt UI components
- **ViewModels**: Presentation logic and state management
- **Services**: AI integration, networking, and platform services
- **Repositories**: Data persistence and caching

## Contributing

We welcome contributions! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### Guidelines
- Follow platform-specific coding conventions
- Add tests for new functionality
- Update documentation
- Ensure child safety in all features

## Safety Notice

This framework is designed for building child-friendly applications. When implementing:
- Always prioritize child safety
- Implement appropriate content filtering
- Follow COPPA and regional privacy regulations
- Add parental controls and monitoring
- Never store personal information without proper consent

## License

[Add your license here]

## Support

For questions and support:
- Open an issue on GitHub
- Check the documentation wiki
- Join our developer community

## Disclaimer

This is a framework/template. Developers are responsible for:
- Adding their own AI integrations
- Implementing safety features
- Ensuring regulatory compliance
- Creating appropriate content
- Managing API keys and credentials securely

---
## Thank You
jbeghtol Justin Beghtol
Who Founded The Open Moxie Project, Without his orginal concept this would not exist.
Orginal OpenMoxie: https://github.com/jbeghtol/openmoxie

**Note**: This is the base framework only. AI models, API keys, and proprietary content systems have been removed for public distribution.
