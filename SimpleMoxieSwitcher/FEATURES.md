# SimpleMoxieSwitcher - Complete Feature Documentation

## Overview
SimpleMoxieSwitcher is now a comprehensive Moxie robot control system with full customization capabilities, featuring:
- Personality switching
- Complete appearance/face customization
- Audio/volume controls
- Movement and gesture controls
- Camera management

---

## New Features Added

### 1. APPEARANCE CUSTOMIZATION (💇 Button)
Complete control over Moxie's visual appearance through the OpenMoxie face customization system.

#### Eyes & Face Colors (Most Stable)
- **Eyes**: Brown, Gold, Grey, Hazel, Light Blue, Purple, Turquoise
- **Face Colors**: Green, Pink, Purple, Teal, Yellow

#### Hair & Facial Features
- **Head Hair**: Black Bob, Black Center, Pink Shag, Red Shag
- **Facial Hair**: Black Angled, Black Dali, Brown Handlebar, Orange Bat Wing, Yellow Upturn
- **Eyebrows**: Brown Cut, Grey Short, Purple, White Bushy, Yellow Thin

#### Accessories
- **Glasses**: Blue Heart, Gold Half Round, Red Cat, Round White Dot, Small Round
- **Nose**: Cat, Clown, Dog, Human, Pig

#### Face Details
- **Mouth**: Black Small, Dark Red Medium, Pink Pointy, Purple Full, Red Medium
- **Eye Designs**: Blue Circuits, Blue Clouds, Circuits, Clouds, Gears, Gold Stars, Purple Gears, Red Hearts, Stars
- **Eyelid Designs**: Green Eye Shadow, Purple Eye Shadow, Rainbow Stars, Red Eye Shadow, Smokey Lashes
- **Face Designs**: Candies, Flowers, Hearts, Leaves, Stars

**How It Works**:
- Fetches CSRF token from OpenMoxie server (http://localhost:8003)
- Submits HTTP POST request to `/hive/face_edit/1`
- Maps user-friendly names to OpenMoxie asset identifiers (e.g., "Purple" → "MX_010_Eyes_Purple")
- Includes safety warning about experimental features

---

### 2. AUDIO/SOUND CONTROLS (Enhanced 🎮 Controls)
Complete audio management to fix "Moxie talking but no sound" issues.

#### Volume Control
- Slider from 0-100%
- Real-time volume adjustment
- Visual feedback showing current volume percentage
- Reset button to return to 50% volume

#### Mute/Unmute
- Toggle mute button
- Changes color when muted (red) vs unmuted (orange)
- Disables volume slider when muted
- Sends MQTT commands: `[mute:true]` or `[mute:false]`

**MQTT Commands**:
```
[volume:50]    // Set volume to 50%
[mute:true]    // Mute audio
[mute:false]   // Unmute audio
```

---

### 3. ENHANCED CONTROLS VIEW
The Controls view now includes:
1. **Audio & Sound** (NEW)
   - Volume slider (0-100%)
   - Mute/Unmute toggle
   - Reset volume button

2. **Camera**
   - Toggle camera on/off
   - Status indicator

3. **Movement**
   - Forward, Backward, Left, Right

4. **Head Controls**
   - Look Up, Down, Left, Right, Center

5. **Arm Controls**
   - Individual left/right arm control
   - Up/Down positions

---

## Technical Implementation

### Face Customization Backend
```swift
func applyAppearance(
    eyes: String,
    faceColors: String,
    eyeDesigns: String,
    // ... all 11 face features
) async
```

**Process**:
1. Fetch CSRF token from OpenMoxie web interface
2. Map display names to asset identifiers
3. Build form-encoded POST body
4. Submit to `/hive/face_edit/1` endpoint
5. Handle success/error responses

### Audio Controls Backend
```swift
func setVolume(_ volume: Int) async
func toggleMute(_ muted: Bool) async
```

**Process**:
1. Send MQTT command to `moxie/wake` topic
2. Format: `[volume:50]` or `[mute:true]`
3. Use `mosquitto_pub` for message delivery
4. Update status message with feedback

### OpenMoxie Integration
- **Server URL**: `http://localhost:8003`
- **Face Edit Endpoint**: `/hive/face_edit/1`
- **Asset Naming Convention**: `MX_[category]_[feature]_[name]`
  - Example: `MX_010_Eyes_Purple`
  - Category numbers: 010 (Eyes), 020 (Face Colors), 030 (Eye Designs), etc.

---

## UI Features

### Plastic Toy Button Styling
All buttons use a cohesive "plastic toy" aesthetic:
- Gradient backgrounds (bright, saturated colors)
- Glossy shine effect (white gradient at top)
- Inner border glow
- Double shadow (colored glow + dark shadow)
- 18px corner radius

**New Appearance Button**:
- Color: Bright Cyan
- Icon: 💇
- Matches existing Controls, Faces, and Custom buttons

### Appearance View Layout
- Organized into sections:
  - Eyes & Face Colors
  - Hair & Facial Features
  - Accessories
  - Face Details
- Color-coded backgrounds for each feature category
- Large, easy-to-read pickers
- Bottom apply button (cyan, full width)
- Safety warning included

### Audio Controls Layout
- Blue-themed section (matches audio theme)
- Volume slider with percentage display
- Mute/Unmute button with visual state
- Reset volume button
- Disabled state when muted

---

## Usage Instructions

### To Customize Appearance:
1. Click the **💇 Appearance** button
2. Select desired features from dropdowns
3. Use "Default" to keep original/remove feature
4. Click **Apply Customization**
5. Wait for success message
6. Close the dialog

### To Control Audio:
1. Click the **🎮 Controls** button
2. Scroll to **AUDIO & SOUND** section
3. Adjust volume slider (0-100%)
4. Toggle mute if needed
5. Use "Reset Volume" to return to 50%

### To Control Movement/Camera:
1. Click the **🎮 Controls** button
2. Use the respective sections:
   - Camera toggle
   - Movement buttons
   - Head direction buttons
   - Arm position buttons

---

## MQTT Topics & Commands

### Audio Commands
```
Topic: moxie/wake
Messages:
  [volume:0-100]  // Set volume percentage
  [mute:true]     // Mute audio
  [mute:false]    // Unmute audio
```

### Movement Commands
```
Topic: moxie/wake
Messages:
  [move:forward]
  [move:backward]
  [move:left]
  [move:right]
```

### Head Control Commands
```
Topic: moxie/wake
Messages:
  [look:up]
  [look:down]
  [look:left]
  [look:right]
  [look:center]
```

### Arm Control Commands
```
Topic: moxie/wake
Messages:
  [arm:left:up]
  [arm:left:down]
  [arm:right:up]
  [arm:right:down]
```

### Camera Control
```
Topic: moxie/wake
Messages:
  [camera:true]   // Enable camera
  [camera:false]  // Disable camera
```

### Emotion Control
```
Topic: moxie/wake
Messages:
  [emotion:happy]
  [emotion:sad]
  [emotion:angry]
  [emotion:surprised]
  [emotion:neutral]
  [emotion:excited]
  [emotion:sleepy]
  [emotion:confused]
```

---

## Architecture

### PersonalityController Extensions
The controller now handles:
1. **Personality switching** (original feature)
2. **Face/Emotion control** (original feature)
3. **Movement control** (original feature)
4. **Camera control** (original feature)
5. **Audio control** (NEW)
6. **Appearance customization** (NEW)

### HTTP Communication
- Uses `URLSession` for OpenMoxie HTTP API
- Handles CSRF tokens automatically
- Form URL encoding for POST data
- Error handling with user feedback

### MQTT Communication
- Uses `mosquitto_pub` command-line tool
- Publishes to `moxie/wake` topic
- Command format: `[command:parameter]`
- Timeout handling (1 second)

---

## Safety & Warnings

### Appearance Customization
⚠️ **CAUTION**: Aside from Eyes and Face Colors, other custom assets have had little testing and may cause instability:
- May affect background services
- Could cause audio processing issues
- Not all combinations tested
- Use "Reset Child ID" checkbox in OpenMoxie web interface if issues occur

### Best Practices
1. Start with Eyes and Face Colors only (most stable)
2. Test one feature at a time
3. Monitor Moxie's behavior after changes
4. Keep the OpenMoxie web interface open for emergency reset
5. Document your working configurations

---

## Requirements

### System Requirements
- macOS (Darwin 25.0.0 or later)
- Swift 5.0+
- OpenMoxie server running on `localhost:8003`
- MQTT broker running on `localhost:1883`
- `mosquitto_pub` command available
- Docker with `openmoxie-server` container

### Network Requirements
- OpenMoxie server: `http://localhost:8003`
- MQTT broker: `localhost:1883`
- Docker daemon running

---

## Troubleshooting

### Audio Issues
**Problem**: Moxie talking but no sound
**Solutions**:
1. Open Controls → Audio & Sound
2. Unmute if muted
3. Increase volume to 50% or higher
4. Check MQTT broker is running
5. Verify Moxie is connected to network

### Appearance Not Applying
**Problem**: Customization doesn't change Moxie's look
**Solutions**:
1. Verify OpenMoxie server is running (check `http://localhost:8003`)
2. Check CSRF token is being fetched correctly
3. Look at console for error messages
4. Try resetting to default values first
5. Use OpenMoxie web interface directly to verify

### MQTT Commands Not Working
**Problem**: Controls don't affect Moxie
**Solutions**:
1. Verify `mosquitto_pub` is installed
2. Check MQTT broker is running on port 1883
3. Test with command line: `mosquitto_pub -h localhost -t moxie/wake -m "[volume:50]"`
4. Verify Moxie is subscribed to `moxie/wake` topic

---

## Future Enhancements

Potential additions:
1. Save/load appearance presets
2. Real-time preview of appearance changes
3. Volume level indicator from Moxie feedback
4. Audio equalizer controls
5. Custom movement patterns/sequences
6. Appearance randomizer
7. Backup/restore configurations
8. Network diagnostics panel

---

## Credits

Built on top of:
- OpenMoxie server (http://localhost:8003)
- MQTT (Mosquitto)
- SwiftUI
- Foundation URLSession

Face customization options extracted from OpenMoxie web interface.
Audio controls designed to fix common "no sound" issues.
Plastic toy aesthetic maintained throughout.
