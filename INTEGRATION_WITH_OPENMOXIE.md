# Integration with OpenMoxie

This Moxie Companion App Framework is designed to work alongside the [OpenMoxie MQTT Server](https://github.com/jbeghtol/openmoxie).

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│              OpenMoxie Ecosystem                 │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────────────┐   ┌──────────────────┐   │
│  │  OpenMoxie MQTT  │◄──►│ Companion Apps  │   │
│  │     Server       │   │   Framework     │   │
│  │  (jbeghtol/      │   │  (This Repo)    │   │
│  │   openmoxie)     │   │                 │   │
│  └──────────────────┘   └──────────────────┘   │
│           ▲                      ▲              │
│           │                      │              │
│           ▼                      ▼              │
│  ┌──────────────────────────────────────────┐  │
│  │          Moxie Robot Hardware            │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
```

## How They Work Together

### 1. OpenMoxie MQTT Server (jbeghtol/openmoxie)
- Provides the communication backbone
- Handles message routing between robot and apps
- Manages device connections and sessions
- Runs in Docker for easy deployment

### 2. Companion App Framework (This Repository)
- Provides client applications for users
- Multi-platform support (iOS, macOS, Windows, Linux)
- Connects to MQTT server for robot communication
- Handles UI/UX and user interactions

## Integration Options

### Option 1: Separate Repositories (Recommended)
Keep as separate repositories that reference each other:

```bash
# Clone both repositories
git clone https://github.com/jbeghtol/openmoxie.git
git clone https://github.com/AgewellEPM/moxie-framework.git

# Set up MQTT server
cd openmoxie
docker-compose up -d

# Configure companion app to connect to MQTT
cd ../moxie-framework
# Edit configuration to point to MQTT server
```

### Option 2: Submodule Integration
Add companion framework as a git submodule:

```bash
cd openmoxie
git submodule add https://github.com/AgewellEPM/moxie-framework.git companion-apps
git commit -m "Add companion app framework as submodule"
```

### Option 3: Monorepo Structure
Create a parent repository containing both:

```
openmoxie-complete/
├── mqtt-server/      (from jbeghtol/openmoxie)
├── companion-apps/   (from this repository)
└── docker-compose.yml (orchestrates both)
```

## Configuration

### MQTT Connection Settings
In the companion app, configure the MQTT connection:

```swift
// SimpleMoxieSwitcher/Config/MQTTConfig.swift
struct MQTTConfig {
    static let broker = "localhost"  // or your MQTT server address
    static let port = 1883
    static let topic = "moxie/+"
    static let clientId = "moxie-companion-\(UUID().uuidString)"
}
```

### Docker Integration
Add companion app services to docker-compose.yml:

```yaml
version: '3'
services:
  mqtt:
    build:
      context: .
      dockerfile: mqtt.Dockerfile
    ports:
      - "1883:1883"
      - "9001:9001"

  companion-api:
    build:
      context: ./companion-apps
      dockerfile: Dockerfile
    environment:
      - MQTT_BROKER=mqtt
      - MQTT_PORT=1883
    depends_on:
      - mqtt
```

## Communication Protocol

### Topics Structure
```
moxie/robot/status      - Robot status updates
moxie/robot/commands    - Commands to robot
moxie/app/events        - App-generated events
moxie/app/telemetry     - App usage data
moxie/content/+         - Content delivery
```

### Message Format
```json
{
  "timestamp": "2024-01-19T10:30:00Z",
  "source": "companion-app",
  "type": "command",
  "payload": {
    "action": "speak",
    "data": {
      "text": "Hello, friend!",
      "emotion": "happy"
    }
  }
}
```

## Development Workflow

1. **Start MQTT Server**
   ```bash
   cd openmoxie
   docker-compose up
   ```

2. **Run Companion App**
   ```bash
   cd moxie-framework/SimpleMoxieSwitcher
   swift run
   ```

3. **Test Communication**
   - Use MQTT client to monitor messages
   - Verify app can connect and communicate
   - Test robot responses

## Contributing

Both projects welcome contributions:
- MQTT Server: https://github.com/jbeghtol/openmoxie
- Companion Apps: https://github.com/AgewellEPM/moxie-framework

## References

- [OpenMoxie MQTT Documentation](https://github.com/jbeghtol/openmoxie)
- [MQTT Protocol Specification](https://mqtt.org/)
- [Companion App Framework Docs](./README.md)