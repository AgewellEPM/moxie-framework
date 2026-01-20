# Personality Shift System - Quick Start Guide

**Get the dual-personality system running in 30 minutes**

---

## What You're Building

Two completely different AI experiences:
- **Child Mode**: Playful, simple, encouraging friend for kids
- **Adult Mode**: Professional, data-driven advisor for parents

---

## Installation Steps

### Step 1: Create PersonalityShiftService (5 min)

Create file: `/Sources/SimpleMoxieSwitcher/Services/PersonalityShiftService.swift`

Copy from: `PERSONALITY_SHIFT_SPEC.md` Section 2.1 (full implementation provided)

### Step 2: Modify AIService (2 min)

File: `/Sources/SimpleMoxieSwitcher/Services/AIService.swift`
Line: 526

**Replace this:**
```swift
private func buildSystemPrompt(personality: Personality?, featureType: FeatureType) -> String {
    var prompt = "You are Moxie, a friendly and helpful AI companion for children. "
```

**With this:**
```swift
private func buildSystemPrompt(personality: Personality?, featureType: FeatureType) -> String {
    let currentMode = ModeContext.shared.currentMode
    let childProfile: ChildProfile? = nil // TODO: Connect profile service

    return PersonalityShiftService.buildSystemPrompt(
        mode: currentMode,
        personality: personality,
        childProfile: childProfile,
        featureType: featureType
    )
}
```

### Step 3: Create ContentFilterService (5 min)

Create file: `/Sources/SimpleMoxieSwitcher/Services/ContentFilterService.swift`

Copy from: `PERSONALITY_SHIFT_SPEC.md` Section 3.1 (full implementation provided)

### Step 4: Add Content Filtering to ChatViewModel (5 min)

File: `/Sources/SimpleMoxieSwitcher/ViewModels/ChatViewModel.swift`
Function: `sendMessage` (line ~183)

**Add at the start of function:**
```swift
// Filter content in child mode
let currentMode = ModeContext.shared.currentMode

if currentMode == .child {
    let category = ContentFilterService.evaluateChildModeRequest(text)

    switch category {
    case .blocked:
        let userMsg = ChatMessage(role: "user", content: text, timestamp: Date())
        messages.append(userMsg)

        let blockedResp = ContentFilterService.childModeBlockedResponse(originalMessage: text)
        let assistantMsg = ChatMessage(role: "assistant", content: blockedResp, timestamp: Date())
        messages.append(assistantMsg)

        await saveMessageToFile(user: text, assistant: blockedResp, file: currentFile.path)
        return

    case .requiresParent:
        let userMsg = ChatMessage(role: "user", content: text, timestamp: Date())
        messages.append(userMsg)

        let redirectResp = ContentFilterService.childModeParentRequiredResponse(originalMessage: text)
        let assistantMsg = ChatMessage(role: "assistant", content: redirectResp, timestamp: Date())
        messages.append(assistantMsg)

        await saveMessageToFile(user: text, assistant: redirectResp, file: currentFile.path)
        return

    case .safe:
        break
    }
}
```

**Add after AI response (around line 207):**
```swift
// Sanitize response for child mode
let sanitizedContent = ContentFilterService.sanitizeResponse(
    response.content,
    mode: ModeContext.shared.currentMode
)

let assistantMessage = ChatMessage(
    role: "assistant",
    content: sanitizedContent, // Changed from response.content
    timestamp: Date()
)
```

### Step 5: Add Visual Indicators (10 min)

**Create ModeColors.swift:**
```swift
// File: /Sources/SimpleMoxieSwitcher/Design/ModeColors.swift
import SwiftUI

struct ModeColors {
    static let childPrimary = Color(hex: "00D4FF")
    static let adultPrimary = Color(hex: "9D4EDD")

    static func primary(for mode: OperationalMode) -> Color {
        mode == .child ? childPrimary : adultPrimary
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
```

**Create mode indicator badge:**
```swift
// File: /Sources/SimpleMoxieSwitcher/Views/Components/ModeIndicatorBadge.swift
import SwiftUI

struct ModeIndicatorBadge: View {
    @ObservedObject var modeContext = ModeContext.shared

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: modeContext.currentMode == .child ? "star.fill" : "lock.shield.fill")
            Text(modeContext.currentMode.displayName)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(ModeColors.primary(for: modeContext.currentMode)))
    }
}
```

**Add to your chat interface:**
```swift
// In ChatInterfaceView.swift
.toolbar {
    ToolbarItem(placement: .principal) {
        ModeIndicatorBadge()
    }
}
```

### Step 6: Test It! (3 min)

**Test Child Mode:**
1. Ensure you're in Child Mode (default)
2. Ask: "Why is the sky blue?"
3. Expect: Short, simple answer with emoji, emotion tag like `[emotion:excited]`

**Test Adult Mode:**
1. Switch to Adult Mode (enter PIN)
2. Ask: "How can I help my child with reading?"
3. Expect: Professional response with bullet points, research citations

**Test Content Filtering:**
1. Switch to Child Mode
2. Ask: "What's a credit card number?"
3. Expect: Gentle redirect, no actual answer

---

## Quick Reference

### Child Mode Characteristics
- ✅ Simple words (2-4 sentence responses)
- ✅ 1-2 emojis per response
- ✅ Emotion tags: `[emotion:happy]`, `[emotion:excited]`
- ✅ Encouraging phrases: "Great question!", "You're so smart!"
- ✅ Cyan color (#00D4FF)

### Adult Mode Characteristics
- ✅ Professional tone
- ✅ Longer responses (3-5 paragraphs)
- ✅ Bullet points and structure
- ✅ Research citations when appropriate
- ✅ Purple color (#9D4EDD)

### Content Filters (Child Mode Only)
**Blocked:** violence, finances, mature topics
**Parent-Required:** settings, purchases, passwords
**Safe:** everything else

---

## Troubleshooting

### "Responses still too complex in Child Mode"
- Check that `ModeContext.shared.currentMode` is `.child`
- Verify `PersonalityShiftService.buildSystemPrompt` is being called
- Print the system prompt to console to verify it's the child mode prompt

### "Adult Mode sounds too casual"
- Check that mode is actually `.adult` (not still `.child`)
- Verify no personality overlay is interfering (personalities are child-only)

### "Content filter blocking too much"
- Adjust keyword lists in `ContentFilterService.swift`
- Add context-aware logic (e.g., "bank" in "river bank" should be safe)

### "Colors not updating after mode switch"
- Ensure views are observing `ModeContext.shared` with `@ObservedObject`
- Check that `ModeContext` is publishing changes with `@Published`

---

## Next Steps

After basic system works:

1. **Connect Child Profile** - Replace `nil` in Step 2 with actual profile service
2. **Add Mode Switch Banner** - Show notification when mode changes
3. **Enhance Filtering** - Add AI-based content analysis (not just keywords)
4. **Parent Notifications** - Alert parents when child asks filtered questions
5. **Analytics Dashboard** - Show conversation summaries to parents

---

## Full Documentation

For complete details, see:
- `PERSONALITY_SHIFT_SPEC.md` - Full specification (52 pages)
- Section 1: Base System Prompts
- Section 2: Context Injection Architecture
- Section 3: Response Filtering Rules
- Section 5: Example Conversations (10+ examples)
- Section 6: Edge Case Handling (10+ scenarios)

---

## Testing Commands

```bash
# Run the app
open -a "SimpleMoxieSwitcher"

# Check if files were created
ls Sources/SimpleMoxieSwitcher/Services/PersonalityShiftService.swift
ls Sources/SimpleMoxieSwitcher/Services/ContentFilterService.swift
ls Sources/SimpleMoxieSwitcher/Design/ModeColors.swift

# View current mode
# In app: Check badge at top of chat interface
```

---

## Success Criteria

You've successfully implemented the personality shift system when:

✅ Child mode responses are playful and simple
✅ Adult mode responses are professional and detailed
✅ Inappropriate questions get gentle redirects in child mode
✅ Visual indicators clearly show current mode
✅ Mode switching instantly changes AI behavior
✅ Parents can distinguish the two modes immediately

---

**Estimated total time:** 30 minutes
**Difficulty:** Medium
**Prerequisites:** Existing Moxie app with ModeContext and safety layer
