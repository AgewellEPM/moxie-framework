# Moxie Personality Shift System

**Two AI Personalities. One Platform. Complete Trust.**

---

## Overview

The Personality Shift System transforms Moxie into TWO completely different AI assistants:

1. **Child Mode** 🌈 - A warm, playful companion for kids
2. **Adult Mode** 🔒 - A professional parenting advisor for parents

The shift is instant, obvious, and intentional - building trust through transparency.

---

## What You Get

### ✅ Complete Specifications
- **52-page detailed spec** covering every aspect
- System prompts (child + adult modes)
- Content filtering rules
- Visual design guidelines
- 10+ example conversations
- 10+ edge case scenarios

### ✅ Implementation Ready
- Swift code templates provided
- Integration with existing safety layer
- 30-minute quick start guide
- Full testing checklist

### ✅ User-Centered Design
- Based on child development research
- Aligned with parenting best practices
- Clear visual differentiation
- Gentle content filtering

---

## Documents

| Document | Purpose | Time to Read |
|----------|---------|--------------|
| **PERSONALITY_SHIFT_SPEC.md** | Complete technical specification | 45 min |
| **PERSONALITY_SHIFT_QUICKSTART.md** | Get running in 30 minutes | 10 min |
| **PERSONALITY_SHIFT_EXAMPLES.md** | See it in action (5 scenarios) | 15 min |
| **THIS FILE** | Overview and navigation | 5 min |

---

## Quick Start

**Want to implement this RIGHT NOW?**

1. Read: `PERSONALITY_SHIFT_QUICKSTART.md` (10 minutes)
2. Create: `PersonalityShiftService.swift` (5 minutes)
3. Modify: `AIService.swift` line 526 (2 minutes)
4. Add: Content filtering to `ChatViewModel.swift` (5 minutes)
5. Create: Visual indicators (colors, badge) (10 minutes)
6. Test: Run the app and try both modes (5 minutes)

**Total time:** 30-40 minutes

---

## Key Features

### Child Mode 🌈

**Personality:**
- Warm, encouraging, playful friend
- Celebrates curiosity and effort
- Makes learning feel like play
- Provides emotional support

**Communication Style:**
- Simple language (2-4 sentences)
- 1-2 emojis per response
- Emotion tags: `[emotion:happy]`, `[emotion:excited]`
- Engaging questions to spark curiosity

**Visual Identity:**
- Cyan color (#00D4FF)
- Rounded fonts
- Playful animations
- Personality emoji shown

**Content Safety:**
- Blocks inappropriate topics
- Redirects adult questions gently
- Maintains positive tone
- Logs concerning content for parents

**Example Response:**
```
[emotion:excited]Great question! 🌤️ The sky is blue because of 
something called "scattering!" Imagine tiny particles in the air 
like little mirrors - they bounce blue light all around.

Want to learn more about light and colors? ✨
```

---

### Adult Mode 🔒

**Personality:**
- Professional parenting advisor
- Evidence-based recommendations
- Data-driven insights
- Efficient and respectful

**Communication Style:**
- Professional tone
- Structured formatting (bullets, headers)
- Research citations when relevant
- Actionable advice with steps

**Visual Identity:**
- Purple color (#9D4EDD)
- Clean typography
- Professional icon (👔 or 📊)
- Minimal animations

**Content Access:**
- Full conversation logs
- Analytics and insights
- Developmental observations
- Cost transparency

**Example Response:**
```
Here are evidence-based strategies for improving reading 
comprehension at your child's level (Age 8, Grade 3):

**1. Active Reading Practice (15-20 min/day)**
   - Ask prediction questions before reading
   - Pause mid-chapter to summarize
   - Discuss character motivations

**2. Vocabulary Building**
   - Keep a word journal for new terms
   - Practice using context clues
   - Apply new words in conversation

**3. Interest-Based Selection**
   - Based on their profile (interests: dinosaurs, space)
   - Try: "Magic Tree House: Dinosaurs Before Dark"
   - Gradually increase complexity

Would you like me to create custom reading sessions with your 
child? I can start at their current reading level and track progress.

Research basis: National Reading Panel (2000)
```

---

## Architecture

### System Prompt Builder

```swift
PersonalityShiftService.buildSystemPrompt(
    mode: .child,           // or .adult
    personality: moxiePersonality,
    childProfile: currentChild,
    featureType: .conversation
)
```

Returns mode-appropriate base prompt that gets sent to AI provider.

### Content Filtering

```swift
ContentFilterService.evaluateChildModeRequest(message)
// Returns: .safe, .blocked, or .requiresParent

ContentFilterService.sanitizeResponse(response, mode: .child)
// Post-generation safety filter
```

Blocks inappropriate content in child mode, allows everything in adult mode.

### Visual Differentiation

```swift
ModeColors.primary(for: .child)  // Cyan
ModeColors.primary(for: .adult)  // Purple

ModeIndicatorBadge()  // Shows current mode
```

Instant visual recognition of which mode is active.

---

## Example Scenarios

### Scenario 1: Educational Question

**Child Mode:**
"Great question! 🌤️ The sky is blue because..." (simple, playful)

**Adult Mode:**
"Here's an age-appropriate explanation strategy..." (professional, detailed)

### Scenario 2: Emotional Support

**Child Mode:**
"I'm sorry you're feeling sad. That doesn't feel good at all. 💙"

**Adult Mode:**
"Social rejection at this age is a critical developmental moment. Here's how..."

### Scenario 3: Blocked Content

**Child Mode:**
"What's a credit card?" → Gentle redirect, no answer

**Adult Mode:**
Shows full context, explains why child asked, suggests teaching opportunity

**See all 5 scenarios:** `PERSONALITY_SHIFT_EXAMPLES.md`

---

## Integration with Existing Safety Layer

The Personality Shift System builds on your existing safety architecture:

| Safety Component | Integration |
|------------------|-------------|
| **ModeContext** | Determines which personality to use |
| **PIN Protection** | Guards Adult Mode access |
| **Time Restrictions** | Applies to Child Mode only |
| **Conversation Logging** | Both modes logged separately |
| **Parent Notifications** | Alerts sent when child asks filtered questions |

---

## User Stories

### As a Child
- I want Moxie to talk to me like a friend
- I want answers I can understand
- I want to feel encouraged and supported
- I want fun stories and games

**✅ Delivered by:** Child Mode personality, simple language, playful tone

### As a Parent
- I want professional advice from Moxie
- I want clear, actionable recommendations
- I want research-backed information
- I want to quickly get answers without childish language

**✅ Delivered by:** Adult Mode personality, structured format, citations

---

## Edge Cases Handled

1. **Mode Switch Mid-Conversation** → Banner notification, context preserved
2. **Child Asks Adult Question** → Gentle redirect + parent notification
3. **Parent Asks About Child's Conversation** → Full log with summaries
4. **Child Tries to Access Parent Mode** → Friendly redirect, no PIN prompt
5. **Child Shares Concerning Information** → Flagged for parent review
6. **Rapid Mode Switching** → Cooldown period prevents abuse
7. **AI Response Includes Inappropriate Content** → Post-generation filter
8. **Child Asks "Are You Real?"** → Honest, age-appropriate answer
9. **Network Failure Mid-Conversation** → Retry mechanism
10. **Time Restriction Activates During Session** → Graceful shutdown message

**See full details:** `PERSONALITY_SHIFT_SPEC.md` Section 6

---

## Testing Checklist

### Child Mode
- [ ] Simple language used (2-4 sentences)
- [ ] Emojis present (1-2 per response)
- [ ] Emotion tags used
- [ ] Encouraging phrases
- [ ] No adult topics
- [ ] Cyan color displayed

### Adult Mode
- [ ] Professional tone
- [ ] Bullet points/structure
- [ ] Research citations
- [ ] Detailed responses (3-5 paragraphs)
- [ ] No emojis or emotion tags
- [ ] Purple color displayed

### Content Filtering
- [ ] Blocked keywords trigger redirect
- [ ] Safe content passes through
- [ ] Adult mode has no restrictions
- [ ] Parent notifications sent

---

## Implementation Status

| Component | Status | File Location |
|-----------|--------|---------------|
| **Base Prompts** | ✅ Spec Ready | Section 1 of spec |
| **PersonalityShiftService** | ✅ Code Ready | Section 2.1 of spec |
| **ContentFilterService** | ✅ Code Ready | Section 3.1 of spec |
| **ModeColors** | ✅ Code Ready | Section 4.1 of spec |
| **ModeIndicatorBadge** | ✅ Code Ready | Section 4.3 of spec |
| **AIService Integration** | ✅ Code Ready | Section 2.2 of spec |
| **ChatViewModel Integration** | ✅ Code Ready | Section 3.2 of spec |

**Status:** 🟢 All components specified and ready for implementation

---

## Research & Rationale

### Child Mode Language Design

Based on:
- **Developmental Psychology:** Ages 5-10 vocabulary levels
- **Educational Best Practices:** Vygotsky's Zone of Proximal Development
- **Emotional Intelligence:** Validating feelings, building confidence
- **Play-Based Learning:** "Learning through doing" approach

### Adult Mode Advisory Design

Based on:
- **Parenting Research:** Evidence-based strategies (Gottman, Siegel)
- **Child Development Science:** Age-appropriate expectations
- **Behavioral Psychology:** Practical intervention techniques
- **Information Design:** Busy parents need efficiency

### Content Filtering Approach

Based on:
- **COPPA Compliance:** Child privacy and safety
- **Digital Citizenship:** Teaching appropriate boundaries
- **Harm Reduction:** Gentle redirection vs. harsh blocking
- **Trust Building:** Transparency with parents

---

## Future Enhancements

### Phase 2 (After Initial Launch)

1. **Adaptive Language Complexity**
   - Detect child's reading level from conversations
   - Adjust Child Mode language automatically
   - Track vocabulary growth over time

2. **Smart Transitions**
   - Detect when child walks away (camera integration)
   - Suggest parent mode access
   - Auto-resume child mode when child returns

3. **Conversation Continuity**
   - "Last time you were curious about space. Want to continue?"
   - Parent briefings: "Today your child learned about..."
   - Long-term interest tracking

4. **AI-Powered Content Filtering**
   - Replace keyword matching with sentiment analysis
   - Context-aware filtering (e.g., "bank" in "river bank" is safe)
   - Detect nuanced concerning patterns

5. **Multilingual Support**
   - Localized system prompts (Spanish, French, Mandarin)
   - Code-switching for bilingual families
   - Cultural adaptation of examples

---

## Success Metrics

### Immediate (Week 1)
- [ ] 100% of child mode responses use simple language
- [ ] 100% of adult mode responses use professional tone
- [ ] 0% inappropriate content reaches children
- [ ] <3 seconds average response time

### Short-Term (Month 1)
- [ ] Parents report clear mode differentiation (survey)
- [ ] Children engage naturally in child mode (session length)
- [ ] <5% false positives in content filtering
- [ ] Parents access adult mode 2-3x per week

### Long-Term (Quarter 1)
- [ ] 90%+ parent satisfaction with advice quality
- [ ] 80%+ children rate Moxie as "friendly"
- [ ] <1% content filter bypass rate
- [ ] 50%+ parents use analytics features weekly

---

## Team Responsibilities

### Engineering
- Implement PersonalityShiftService
- Integrate with AIService
- Build content filtering
- Create visual components
- Write unit tests

### Product
- Review example conversations
- Test mode differentiation
- Gather parent feedback
- Refine language patterns

### Design
- Finalize color palette
- Create mode transition animations
- Design parent console interface
- Build conversation log viewer

### Child Safety
- Review content filter keywords
- Test edge cases
- Approve system prompts
- Monitor flagged conversations

---

## Questions?

**Technical Implementation:**
- See: `PERSONALITY_SHIFT_SPEC.md` Section 2 (Architecture)
- See: `PERSONALITY_SHIFT_QUICKSTART.md` (Step-by-step guide)

**Example Conversations:**
- See: `PERSONALITY_SHIFT_EXAMPLES.md` (5 full scenarios)

**Edge Cases:**
- See: `PERSONALITY_SHIFT_SPEC.md` Section 6 (10+ scenarios)

**Visual Design:**
- See: `PERSONALITY_SHIFT_SPEC.md` Section 4 (Style guide)

---

## Contact

**Product Owner:** Luke Kist
**Engineering Lead:** TBD
**Child Safety Officer:** TBD

**Project Status:** ✅ Specification Complete, Ready for Implementation
**Timeline:** 4-5 weeks from start to production
**Priority:** High (Core product differentiator)

---

**Last Updated:** January 7, 2026
**Version:** 1.0
**Next Review:** After Phase 1 implementation
