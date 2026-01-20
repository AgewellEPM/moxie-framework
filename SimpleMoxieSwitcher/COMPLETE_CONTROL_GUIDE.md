# SimpleMoxieSwitcher - Complete Control Guide

## Main Interface

```
┌─────────────────────────────────────────────┐
│        🤖 Moxie Brain Switcher              │
│                                             │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐   │
│  │  ✨  │  │  😊  │  │  🎮  │  │  💇  │   │
│  │Create│  │Faces │  │Contro│  │Appear│   │
│  │Custom│  │      │  │  ls  │  │ance  │   │
│  └──────┘  └──────┘  └──────┘  └──────┘   │
│                                             │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐   │
│  │  🤖  │  │  🔥  │  │  😤  │  │  👊  │   │
│  │Default│ │ Roast│  │ Hood │  │2Pac │   │
│  │Moxie │  │ Mode │  │ Mode │  │Moxie│   │
│  └──────┘  └──────┘  └──────┘  └──────┘   │
│                                             │
│         ... (more personalities)           │
└─────────────────────────────────────────────┘
```

---

## 1. Appearance Customization (💇 NEW!)

### Full Face Customization Interface

```
┌─────────────────────────────────────────────────────┐
│  💇 Customize Moxie's Look              [Done]      │
├─────────────────────────────────────────────────────┤
│                                                     │
│  👁️ EYES                                           │
│  ┌───────────────────────────────────────┐         │
│  │ Eyes Color:  [Purple ▼]               │         │
│  │  Options: Brown, Gold, Grey, Hazel,   │         │
│  │          Light Blue, Purple, Turquoise│         │
│  └───────────────────────────────────────┘         │
│                                                     │
│  🎨 FACE COLORS                                     │
│  ┌───────────────────────────────────────┐         │
│  │ Face Colors: [Pink ▼]                 │         │
│  │  Options: Green, Pink, Purple,        │         │
│  │          Teal, Yellow                 │         │
│  └───────────────────────────────────────┘         │
│                                                     │
│  ───────────────────────────────────────           │
│                                                     │
│  💈 HAIR & FACIAL FEATURES                         │
│                                                     │
│  💇 HEAD HAIR                                       │
│  [Black Bob ▼] Black Center, Pink Shag, Red Shag  │
│                                                     │
│  🧔 FACIAL HAIR                                     │
│  [Brown Handlebar ▼] Angled, Dali, Bat Wing, etc │
│                                                     │
│  🤨 EYEBROWS                                        │
│  [White Bushy ▼] Brown Cut, Grey Short, Purple    │
│                                                     │
│  ───────────────────────────────────────           │
│                                                     │
│  👓 ACCESSORIES                                     │
│                                                     │
│  👓 GLASSES                                         │
│  [Gold Half Round ▼] Blue Heart, Red Cat, etc     │
│                                                     │
│  👃 NOSE                                            │
│  [Cat ▼] Clown, Dog, Human, Pig                   │
│                                                     │
│  ───────────────────────────────────────           │
│                                                     │
│  ✨ FACE DETAILS                                    │
│                                                     │
│  👄 MOUTH                                           │
│  [Purple Full ▼] Black Small, Pink Pointy, etc    │
│                                                     │
│  👁️‍🗨️ EYE DESIGNS                                   │
│  [Default ▼] Circuits, Clouds, Gears, Stars       │
│                                                     │
│  💄 EYELID DESIGNS                                  │
│  [Purple Eye Shadow ▼] Rainbow Stars, etc         │
│                                                     │
│  🌸 FACE DESIGNS                                    │
│  [Default ▼] Candies, Flowers, Hearts, Leaves     │
│                                                     │
│  ⚠️ CAUTION: Experimental features may cause       │
│     instability. Eyes & Face Colors most stable.   │
│                                                     │
│  ┌──────────────────────────────────────┐          │
│  │    Apply Customization               │          │
│  └──────────────────────────────────────┘          │
└─────────────────────────────────────────────────────┘
```

**Features**:
- 11 customization categories
- 50+ appearance options total
- HTTP POST to OpenMoxie server
- CSRF token handling
- Real-time application

---

## 2. Audio & Sound Controls (🎮 NEW!)

### Enhanced Controls Interface

```
┌─────────────────────────────────────────────────────┐
│  🎮 Moxie Controls                      [Done]      │
├─────────────────────────────────────────────────────┤
│                                                     │
│  🔊 AUDIO & SOUND                                   │
│  ┌──────────────────────────────────────┐          │
│  │  🔊 Volume              50%          │          │
│  │                                      │          │
│  │  ├────────●─────────────┤  (slider) │          │
│  │  0%                    100%          │          │
│  │                                      │          │
│  │  [🔇 Mute]  [Reset Volume]          │          │
│  └──────────────────────────────────────┘          │
│                                                     │
│  ───────────────────────────────────────           │
│                                                     │
│  📷 CAMERA                                          │
│  Camera OFF [Toggle Switch]                        │
│                                                     │
│  ───────────────────────────────────────           │
│                                                     │
│  🚗 MOVEMENT                                        │
│         [⬆️ Forward]                                │
│  [⬅️ Left] [➡️ Right]                              │
│         [⬇️ Backward]                               │
│                                                     │
│  ───────────────────────────────────────           │
│                                                     │
│  👀 HEAD                                            │
│         [⬆️ Look Up]                                │
│  [⬅️ Left] [🎯 Center] [➡️ Right]                 │
│         [⬇️ Look Down]                              │
│                                                     │
│  ───────────────────────────────────────           │
│                                                     │
│  💪 ARMS                                            │
│  Left Arm:  [⬆️ Up] [⬇️ Down]                      │
│  Right Arm: [⬆️ Up] [⬇️ Down]                      │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Audio Features**:
- Volume slider (0-100%)
- Visual percentage display
- Mute/Unmute toggle with color change
- Reset to 50% button
- Slider disabled when muted
- MQTT command integration

---

## 3. Quick Feature Reference

### Appearance Customization
| Category | Options Count | Most Stable? |
|----------|--------------|--------------|
| Eyes | 7 colors | ✅ YES |
| Face Colors | 5 colors | ✅ YES |
| Eye Designs | 9 designs | ⚠️ Experimental |
| Face Designs | 5 designs | ⚠️ Experimental |
| Eyelid Designs | 5 designs | ⚠️ Experimental |
| Mouth | 5 styles | ⚠️ Experimental |
| Head Hair | 4 styles | ⚠️ Experimental |
| Facial Hair | 5 styles | ⚠️ Experimental |
| Brows | 5 styles | ⚠️ Experimental |
| Glasses | 5 styles | ⚠️ Experimental |
| Nose | 5 styles | ⚠️ Experimental |

### Audio Controls
| Control | Range | Default |
|---------|-------|---------|
| Volume | 0-100% | 50% |
| Mute | On/Off | Off |

### Movement Controls
| Direction | Command |
|-----------|---------|
| Forward | `[move:forward]` |
| Backward | `[move:backward]` |
| Left | `[move:left]` |
| Right | `[move:right]` |

### Head Controls
| Direction | Command |
|-----------|---------|
| Up | `[look:up]` |
| Down | `[look:down]` |
| Left | `[look:left]` |
| Right | `[look:right]` |
| Center | `[look:center]` |

### Arm Controls
| Arm | Position | Command |
|-----|----------|---------|
| Left | Up | `[arm:left:up]` |
| Left | Down | `[arm:left:down]` |
| Right | Up | `[arm:right:up]` |
| Right | Down | `[arm:right:down]` |

---

## 4. Common Use Cases

### Fixing "No Sound" Issues
```
1. Click 🎮 Controls button
2. Scroll to 🔊 AUDIO & SOUND section
3. Check if muted (red button = muted)
4. If muted, click "🔇 Unmute"
5. Adjust volume slider to 50% or higher
6. Test by having Moxie speak
```

### Customizing Moxie's Look
```
1. Click 💇 Appearance button
2. Start with safe options:
   - Choose eye color (e.g., Purple)
   - Choose face color (e.g., Pink)
3. Add accessories if desired:
   - Select glasses style
   - Select nose style
4. Experiment with hair (more risky):
   - Head hair style
   - Facial hair style
5. Click "Apply Customization"
6. Wait for success message
7. Check Moxie's screen
```

### Creating a Custom Look
```
EXAMPLE: "Sophisticated Professor Moxie"
- Eyes: Gold
- Face Colors: Teal
- Glasses: Gold Half Round
- Nose: Human
- Brows: White Bushy
- Mouth: Dark Red Medium

EXAMPLE: "Party Moxie"
- Eyes: Purple
- Face Colors: Pink
- Glasses: Blue Heart
- Face Designs: Stars
- Eyelid Designs: Rainbow Stars
- Mouth: Purple Full
```

### Testing New Features Safely
```
1. Start with ONLY Eyes and Face Colors
2. Click Apply
3. Verify Moxie is stable
4. Add ONE accessory at a time
5. Test between each change
6. If issues occur:
   - Revert to Default values
   - Use OpenMoxie web interface to reset
   - Check "Reset Child ID" if severe
```

---

## 5. Button Layout

```
Main Screen Layout:

Row 1 (Action Buttons):
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│   ✨    │ │   😊    │ │   🎮    │ │   💇    │
│ Create  │ │  Faces  │ │Controls │ │Appearance│
│ Custom  │ │         │ │         │ │         │
└─────────┘ └─────────┘ └─────────┘ └─────────┘
  Purple       Orange      Green       Cyan

Row 2+ (Personalities):
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│   🤖    │ │   🔥    │ │   😤    │ │   👊    │
│ Default │ │  Roast  │ │  Hood   │ │  2Pac   │
│  Moxie  │ │  Mode   │ │  Mode   │ │ Moxie   │
└─────────┘ └─────────┘ └─────────┘ └─────────┘
     Blue        Blue        Blue        Blue

(+ more personality buttons...)
```

---

## 6. Technical Flow Diagrams

### Appearance Customization Flow
```
User Interface
     │
     ├─ User selects features
     │  (Eyes: Purple, Face: Pink, etc.)
     │
     ├─ User clicks "Apply Customization"
     │
     ▼
PersonalityController
     │
     ├─ applyAppearance() called
     │
     ├─ Fetch CSRF token
     │  GET http://localhost:8003/hive/face/1
     │  Parse HTML for token
     │
     ├─ Map features to asset names
     │  "Purple" → "MX_010_Eyes_Purple"
     │  "Pink" → "MX_020_Face_Colors_Pink"
     │
     ├─ Build form data
     │  asset_Eyes=MX_010_Eyes_Purple&
     │  asset_Face_Colors=MX_020_Face_Colors_Pink&
     │  ...
     │
     ├─ Submit POST request
     │  POST http://localhost:8003/hive/face_edit/1
     │  Content-Type: application/x-www-form-urlencoded
     │
     ▼
OpenMoxie Server
     │
     ├─ Validate CSRF token
     │
     ├─ Apply face customization
     │
     ├─ Update Moxie's appearance
     │
     ▼
Success/Error Response
     │
     ▼
User sees status message
```

### Audio Control Flow
```
User Interface
     │
     ├─ User adjusts volume slider → 75%
     │
     ▼
PersonalityController
     │
     ├─ setVolume(75) called
     │
     ├─ Build MQTT command: "[volume:75]"
     │
     ├─ Execute: mosquitto_pub -h localhost
     │            -t moxie/wake -m "[volume:75]"
     │
     ▼
MQTT Broker (localhost:1883)
     │
     ├─ Publish to topic: moxie/wake
     │
     ▼
Moxie Robot
     │
     ├─ Subscribe to moxie/wake
     │
     ├─ Receive: [volume:75]
     │
     ├─ Parse command
     │
     ├─ Set volume to 75%
     │
     ▼
Audio system updated
```

---

## 7. Keyboard Shortcuts & Tips

### Navigation Tips
- **Scroll** through long customization lists
- **Tab** to navigate between fields
- **Space** to toggle switches
- **Enter** to click focused buttons

### Best Practices
1. **Save your settings** - Document working configurations
2. **Test incrementally** - One change at a time
3. **Monitor Moxie** - Watch for behavioral changes
4. **Keep backup** - Know how to reset to default
5. **Use stable options first** - Eyes and Face Colors

### Performance Tips
- Close other apps for smoother operation
- Ensure OpenMoxie server is responsive
- Check MQTT broker status before major changes
- Wait for confirmation before closing dialogs

---

## 8. Troubleshooting Quick Reference

| Problem | Solution |
|---------|----------|
| No sound | Controls → Audio → Check mute, increase volume |
| Appearance not applying | Verify OpenMoxie at localhost:8003 |
| MQTT commands fail | Check mosquitto_pub is installed |
| Moxie unstable after changes | Revert to Default, Reset Child ID |
| Can't connect | Verify Docker container is running |
| CSRF error | OpenMoxie server may have restarted |
| Slow response | Check network connection, restart app |

---

## 9. System Requirements Checklist

```
☑ macOS (Darwin 25.0.0+)
☑ Swift 5.0+
☑ OpenMoxie server running
   - URL: http://localhost:8003
   - Check: Open in browser
☑ MQTT broker running
   - Port: 1883
   - Test: mosquitto_pub -h localhost -t test -m "hello"
☑ Docker daemon active
   - Container: openmoxie-server
   - Check: docker ps
☑ mosquitto_pub installed
   - Check: which mosquitto_pub
☑ Network connectivity
   - Local network accessible
```

---

## 10. Feature Comparison

### Before Enhancement
```
✅ Personality switching
✅ Face emotions (8 types)
✅ Movement controls
✅ Head controls
✅ Arm controls
✅ Camera toggle
❌ Audio controls
❌ Appearance customization
❌ Volume management
❌ Mute functionality
```

### After Enhancement
```
✅ Personality switching
✅ Face emotions (8 types)
✅ Movement controls
✅ Head controls
✅ Arm controls
✅ Camera toggle
✅ Audio controls (NEW)
✅ Appearance customization (NEW)
✅ Volume management (NEW)
✅ Mute functionality (NEW)
✅ 11 face feature categories (NEW)
✅ 50+ customization options (NEW)
✅ HTTP API integration (NEW)
✅ CSRF token handling (NEW)
```

---

## Summary

**SimpleMoxieSwitcher** is now a complete Moxie robot control system offering:

- **100% control** over Moxie's appearance (11 categories, 50+ options)
- **Full audio management** (volume slider, mute/unmute, reset)
- **Comprehensive movement** (arms, head, body, camera)
- **Beautiful UI** (plastic toy aesthetic, organized sections)
- **Safe operation** (warnings, defaults, error handling)

**Total Features**: 70+ individual controls across 4 main categories
**Lines of Code**: ~1,600 (single file, well-organized)
**UI Elements**: 4 main buttons, 3 detailed modal views, 100+ interactive controls
