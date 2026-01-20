# SimpleMoxieSwitcher

**Take control of your Moxie robot. No subscriptions. Your data stays local.**

[![Download](https://img.shields.io/badge/Download-openmoxie.org-blue)](https://openmoxie.org/download)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

## What is SimpleMoxieSwitcher?

SimpleMoxieSwitcher is a control system for Moxie robots that gives you complete control without cloud subscriptions or monthly fees. Everything runs locally on your computer.

### Features

- **AI Conversations** - Multiple personalities powered by OpenAI, Anthropic, or local models
- **Educational Games** - Trivia, spelling, movie quotes, and more
- **Language Learning** - Support for 8+ languages
- **Interactive Stories** - Choose-your-own-adventure storytelling
- **Smart Home** - Control Alexa and Google Home devices
- **Parental Controls** - PIN protection, usage limits, content filtering
- **Analytics** - Track usage, costs, and learning progress
- **Customization** - Change Moxie's appearance and behavior
- **Privacy** - All data stays on your computer, never sent to cloud

## Download

**[Download SimpleMoxieSwitcher](https://openmoxie.org/download)**

### Platforms

- **macOS** - macOS 13.0 or later ([Download .dmg](https://openmoxie.org/downloads/SimpleMoxieSwitcher-Mac.dmg))
- **Windows** - Windows 10 (19041+) or Windows 11 ([Download .exe](https://openmoxie.org/downloads/SimpleMoxieSwitcher-Setup.exe))
- **iOS** - Remote control app ([Get on TestFlight](https://openmoxie.org/download))

## Quick Start

### Desktop (Mac/Windows)

1. Download installer from [openmoxie.org/download](https://openmoxie.org/download)
2. Run the installer - it will automatically set up:
   - Docker Desktop
   - Mosquitto MQTT broker
   - OpenMoxie backend
3. Follow the setup wizard
4. Connect your Moxie robot
5. Start interacting!

### iOS Remote

1. Install TestFlight app from App Store
2. Open [TestFlight invitation link](https://openmoxie.org/download)
3. Install MoxieRemote
4. Enter your computer's IP address in settings
5. Control Moxie from anywhere in your house

## Requirements

### Desktop App
- **Mac:** macOS 13.0 or later
- **Windows:** Windows 10 (build 19041+) or Windows 11
- Docker Desktop (free)
- 8GB RAM (16GB recommended)
- 10GB storage
- OpenAI API key (or other AI provider)

### Moxie Robot
- Moxie robot connected to same WiFi network
- Latest firmware

## Documentation

- [Installation Guide](https://openmoxie.org/docs/installation)
- [User Guide](https://openmoxie.org/docs/user-guide)
- [Parental Controls](https://openmoxie.org/docs/parental-controls)
- [Safety Features](https://openmoxie.org/docs/safety)
- [FAQ](https://openmoxie.org/docs/faq)

## Support

- [Documentation](https://openmoxie.org/docs)
- [Community Forum](https://openmoxie.org/community)
- [Report Issues](https://openmoxie.org/support)
- [Email Support](mailto:support@openmoxie.org)

## System Architecture

SimpleMoxieSwitcher uses a local-first architecture:

```
Desktop App (Mac/Windows)
    |
Docker Container (OpenMoxie Backend)
    |
MQTT Broker (Mosquitto)
    |
Moxie Robot
```

**iOS Remote** connects to your desktop app over local WiFi.

## Privacy & Security

- All data stored locally on your computer
- No telemetry or tracking
- Parental controls with PIN protection
- Content filtering for child safety
- Usage monitoring and limits
- OpenAI API calls are direct (no proxy)

## License

This software is proprietary and closed-source.

Copyright 2026 RollSEO LLC. All rights reserved.

**NOT PERMITTED:**
- Reverse engineering
- Decompilation
- Redistribution
- Commercial use without license

See [LICENSE](LICENSE) for full terms.

## Disclaimer

This is an independent project not affiliated with Embodied Inc. Moxie is a trademark of Embodied Inc.

---

**Made with care by RollSEO LLC**

[openmoxie.org](https://openmoxie.org) | [support@openmoxie.org](mailto:support@openmoxie.org)
