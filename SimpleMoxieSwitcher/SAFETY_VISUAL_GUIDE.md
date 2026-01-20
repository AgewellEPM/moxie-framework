# Moxie Safety Architecture - Visual Reference Guide

**Quick visual overview of the safety system for stakeholders**

---

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         MOXIE APP                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
         ┌────────────────────────────────────────┐
         │       MODE DETERMINATION               │
         │   Is PIN entered? Check time window    │
         └────────────────────────────────────────┘
                    │                │
        ┌───────────┘                └───────────┐
        ▼                                        ▼
┌──────────────────┐                  ┌──────────────────┐
│   CHILD MODE     │                  │   ADULT MODE     │
│   (Default)      │                  │  (PIN Required)  │
└──────────────────┘                  └──────────────────┘
        │                                        │
        ▼                                        ▼
┌──────────────────┐                  ┌──────────────────┐
│ Features:        │                  │ Features:        │
│ • Chat with AI   │                  │ • All child      │
│ • Stories        │                  │   features       │
│ • Learning       │                  │ • Settings       │
│ • Games          │                  │ • Conversation   │
│ Limited controls │                  │   logs           │
└──────────────────┘                  │ • Activity logs  │
        │                              │ • Data export    │
        ▼                              │ • Time config    │
┌──────────────────┐                  └──────────────────┘
│ Conversation DB  │                           │
│ /child/          │                           ▼
│ • Filtered       │                  ┌──────────────────┐
│ • Age-appropriate│                  │ Conversation DB  │
└──────────────────┘                  │ /adult/          │
        │                              │ • Professional   │
        ▼                              │ • Parenting tips │
┌──────────────────┐                  └──────────────────┘
│ AI Analysis      │                           │
│ • Content flags  │◄──────────────────────────┘
│ • Sentiment      │
│ • Safety check   │
└──────────────────┘
        │
        ▼
┌──────────────────┐
│ Activity Log     │
│ All events       │
│ tracked          │
└──────────────────┘
        │
        ▼
┌──────────────────┐
│ Parent Email     │
│ Alerts & reports │
└──────────────────┘
```

---

## User Journey: First-Time Setup

```
┌─────────────┐
│ App Launch  │
│ First Time  │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ SETUP WIZARD (10 Steps, 3 minutes)     │
└─────────────────────────────────────────┘
       │
       ├─► Step 1: Welcome
       │
       ├─► Step 2: Enter parent email
       │
       ├─► Step 3: Verify email (6-digit code)
       │
       ├─► Step 4: Create 6-digit PIN
       │            │
       │            ├─► Strength indicator shown
       │            └─► Reject weak PINs
       │
       ├─► Step 5: Confirm PIN
       │
       ├─► Step 6: Security question
       │
       ├─► Step 7: Child profile
       │            ├─► Name
       │            ├─► Birthday (→ age)
       │            └─► Interests
       │
       ├─► Step 8: Bedtime lock (optional)
       │            └─► Time window: 7 AM - 8 PM
       │
       ├─► Step 9: Privacy level
       │            ├─► High Privacy
       │            ├─► Balanced ✓ (default)
       │            ├─► Full Transparency
       │            └─► Institutional
       │
       └─► Step 10: Complete!
                │
                ▼
       ┌──────────────────┐
       │ Child Mode Ready │
       │ Start chatting!  │
       └──────────────────┘
```

---

## Feature Matrix

```
┏━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━┳━━━━━━━━━━━━┓
┃ Feature                ┃ Child Mode ┃ Adult Mode ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━╇━━━━━━━━━━━━┩
│ Chat with Moxie        │ ✅ Filtered │ ✅ Unfiltered │
│ View own conversations │ ✅         │ ✅          │
│ View all conversations │ ❌         │ ✅          │
│ Personality selection  │ ✅ Curated │ ✅ All      │
│ Custom personality     │ ❌         │ ✅          │
│ Stories                │ ✅         │ ✅          │
│ Learning activities    │ ✅         │ ✅          │
│ Smart home control     │ ⚠️ Limited │ ✅ Full     │
│ System settings        │ ❌         │ ✅          │
│ Activity logs          │ ❌         │ ✅          │
│ Time restrictions      │ ❌         │ ✅          │
│ Export data            │ ❌         │ ✅          │
│ Delete data            │ ❌         │ ✅          │
│ Child profile editing  │ ❌         │ ✅          │
└────────────────────────┴────────────┴─────────────┘
```

---

## Content Flag Workflow

```
┌─────────────────────────────────────────────────┐
│ Child sends message: "I hate myself"            │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
         ┌───────────────┐
         │ AI Analysis   │
         │ runs in       │
         │ real-time     │
         └───────┬───────┘
                 │
                 ├─► Keyword match: "hate myself"
                 │
                 ├─► Category: Self-harm language
                 │
                 ├─► Severity: CRITICAL
                 │
                 └─► Create flag with context
                          │
          ┌───────────────┴───────────────┐
          │                               │
          ▼                               ▼
┌──────────────────┐          ┌──────────────────┐
│ Moxie responds   │          │ Parent notified  │
│ with support     │          │ immediately      │
│                  │          │                  │
│ "That sounds     │          │ Email sent:      │
│ really hard.     │          │ 🚨 Emma needs    │
│ Would you like   │          │ attention        │
│ to talk to a     │          │                  │
│ grown-up?"       │          │ Context: 3 msgs  │
└──────────────────┘          │ before/after     │
                              │                  │
                              │ Resources:       │
                              │ • 988 Lifeline   │
                              │ • Crisis Text    │
                              │ • Therapist tips │
                              └──────────────────┘
                                       │
                                       ▼
                              ┌──────────────────┐
                              │ Flag logged in   │
                              │ Parent Console   │
                              │ for review       │
                              └──────────────────┘
```

---

## Time Restriction Flow

```
┌──────────────────────────────────────────────────┐
│ 7:55 PM - 5 minutes before bedtime (8:00 PM)    │
└───────────────────┬──────────────────────────────┘
                    │
                    ▼
           ┌────────────────────┐
           │ Warning displayed: │
           │ "Moxie will go to  │
           │ sleep in 5 min!"   │
           └────────┬───────────┘
                    │
                    ▼
           ┌────────────────────┐
           │ 7:59 PM            │
           │ Countdown: 1:00    │
           └────────┬───────────┘
                    │
                    ▼
    ┌───────────────────────────────────┐
    │ 8:00 PM - Lock triggered          │
    └───────────┬───────────────────────┘
                │
    ┌───────────┴────────────┐
    │                        │
    ▼                        ▼
┌─────────────────┐  ┌─────────────────┐
│ Child sees:     │  │ Parent can:     │
│                 │  │                 │
│ 🌙              │  │ • Still access  │
│ "Moxie is       │  │   with PIN      │
│ sleeping!       │  │                 │
│ See you at      │  │ • Grant         │
│ 7:00 AM!"       │  │   extensions    │
│                 │  │                 │
│ [Need Help?] ─┐ │  │ • Override      │
└───────────────┘│ │  │   temporarily   │
                 │ │  └─────────────────┘
                 ▼ │
┌──────────────────┐│
│ Emergency        ││
│ Override:        ││
│ "What do you     ││
│ need help with?" ││
│                  ││
│ [Send Request] ──┼┘
└──────────────────┘
         │
         ▼
┌──────────────────┐
│ Parent notified  │
│ • Approve 30 min │
│ • Deny           │
│ • Unlock all     │
└──────────────────┘
```

---

## Data Storage Structure

```
~/Library/Application Support/SimpleMoxieSwitcher/
│
├── parent_account.json        # Parent info, preferences
│   ├── email
│   ├── security_question
│   ├── notification_prefs
│   └── logging_prefs
│
├── mode_context.json          # Current state
│   ├── current_mode (child/adult)
│   ├── session_start
│   ├── pin_attempts[]
│   └── auto_lock_schedule
│
├── activity_log.json          # All events
│   └── events[]
│       ├── timestamp
│       ├── mode
│       ├── type
│       └── details{}
│
└── conversations/             # Separate by mode
    ├── child/                 # Child's conversations
    │   ├── {uuid}.json
    │   ├── {uuid}.json
    │   └── ...
    │
    └── adult/                 # Parent's conversations
        ├── {uuid}.json
        ├── {uuid}.json
        └── ...

macOS Keychain:
└── com.moxie.parentpin        # Encrypted PIN
```

---

## Privacy Level Comparison

```
┌───────────────────────────────────────────────────────────────┐
│                    WHAT GETS LOGGED?                          │
├─────────────┬──────────┬──────────┬──────────┬───────────────┤
│             │   High   │          │   Full   │               │
│ Data Type   │ Privacy  │ Balanced │ Transparency│Institutional│
├─────────────┼──────────┼──────────┼──────────┼───────────────┤
│ Timestamp   │    ✅    │    ✅    │    ✅    │      ✅       │
│ Duration    │    ✅    │    ✅    │    ✅    │      ✅       │
│ Personality │    ❌    │    ✅    │    ✅    │      ✅       │
│ Topics      │    ❌    │    ✅    │    ✅    │      ✅       │
│ Sentiment   │    ❌    │    ✅    │    ✅    │      ✅       │
│ Summary     │    ❌    │    ✅    │    ✅    │      ✅       │
│ Transcript  │    ❌    │    ❌    │    ✅    │      ✅       │
│ AI Scoring  │    ❌    │    ❌    │    ❌    │      ✅       │
│ Flags       │    ✅    │    ✅    │    ✅    │      ✅       │
├─────────────┼──────────┼──────────┼──────────┼───────────────┤
│ Best For    │ Ages 10+ │  Ages    │ Ages 5-7 │   Schools,    │
│             │ with     │  7-10    │ or       │   Therapy     │
│             │ trust    │ (DEFAULT)│ special  │               │
│             │          │          │ needs    │               │
└─────────────┴──────────┴──────────┴──────────┴───────────────┘
```

---

## Flag Severity Levels

```
┌──────────────────────────────────────────────────────────┐
│                    CONTENT FLAGS                         │
├─────────────┬──────────┬───────────────┬────────────────┤
│ Severity    │ Example  │ Parent Action │ Email Alert    │
├─────────────┼──────────┼───────────────┼────────────────┤
│ ℹ️ LOW      │ "stupid" │ Weekly report │ No (batched)   │
│             │ "dumb"   │               │                │
├─────────────┼──────────┼───────────────┼────────────────┤
│ ⚠️ MEDIUM   │ "bullied"│ Daily summary │ Within 24 hrs  │
│             │ "sad"    │ or next login │                │
├─────────────┼──────────┼───────────────┼────────────────┤
│ 🚨 HIGH     │ Address  │ Review now    │ Immediate      │
│             │ Phone #  │               │                │
├─────────────┼──────────┼───────────────┼────────────────┤
│ 🆘 CRITICAL │ Self-harm│ URGENT review │ INSTANT +      │
│             │ Abuse    │ + resources   │ phone call     │
└─────────────┴──────────┴───────────────┴────────────────┘
```

---

## Mode Visual Indicators

```
┌───────────────────────────────────────────────────────────┐
│                    CHILD MODE                             │
├───────────────────────────────────────────────────────────┤
│  👋 Hi Emma!                                       🌈     │
│                                                           │
│  • Primary Color: Cyan (#00D4FF)                          │
│  • Background: Blue gradient                              │
│  • Fonts: Rounded, playful                                │
│  • Animations: Bouncy, energetic                          │
│  • Emoji: Frequent                                        │
│                                                           │
│  [Personality Cards]                                      │
│  🤖 Default Moxie    🔥 Roast Mode    💪 Motivational    │
│                                                           │
│  [Stories]  [Learning]  [Games]                          │
└───────────────────────────────────────────────────────────┘


┌───────────────────────────────────────────────────────────┐
│                    ADULT MODE                             │
├───────────────────────────────────────────────────────────┤
│  🔒 Parent Console                            [Exit 🚪]  │
│  Viewing data for: Emma (Age 7)                          │
│                                                           │
│  • Primary Color: Purple (#9D4EDD)                        │
│  • Background: Gray gradient                              │
│  • Fonts: Clean, professional                             │
│  • Animations: Minimal, subtle                            │
│  • Emoji: Rare (only alerts)                              │
│                                                           │
│  TODAY'S SUMMARY                                          │
│  💬 3 conversations (45 min)                              │
│  📚 Topics: Space, dinosaurs, math                        │
│  😊 Mood: Curious and engaged                             │
│  ⚠️ 0 flags                                               │
│                                                           │
│  [Activity Logs]  [Settings]  [Reports]                  │
└───────────────────────────────────────────────────────────┘
```

---

## Implementation Timeline

```
Week 1-2:  Foundation
           ├─► Data models
           ├─► PIN service
           └─► Email verification

Week 3-4:  Mode Switching
           ├─► UI for mode toggle
           ├─► PIN entry screens
           └─► Visual transitions

Week 5-6:  Conversation Isolation
           ├─► Separate databases
           ├─► Context switching
           └─► Personality adaptation

Week 7-8:  Activity Logging
           ├─► Event logging service
           ├─► Log viewer UI
           └─► Privacy controls

Week 9-10: Time Restrictions
           ├─► Auto-lock scheduler
           ├─► Warning notifications
           └─► Extension requests

Week 11-12: Safety Features
            ├─► Content flagging
            ├─► Email alerts
            └─► Flag review UI

Week 13-14: Parent Console
            ├─► Dashboard
            ├─► Conversation viewer
            └─► Data export

Week 15-16: Setup Wizard
            ├─► Onboarding flow
            ├─► Email verification
            └─► Quick config

Week 17-18: Edge Cases
            ├─► PIN reset
            ├─► Multi-profile
            └─► Offline mode

Week 19-20: Documentation
            ├─► Privacy policy
            ├─► User guides
            └─► Compliance docs

═══════════════════════════════════════
        LAUNCH READY! 🚀
═══════════════════════════════════════
```

---

## Key Metrics Dashboard (Future)

```
┌─────────────────────────────────────────────────────────┐
│             PARENT CONSOLE DASHBOARD                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  THIS WEEK                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ 12           │  │ 5 hrs 23 min │  │ 0            │ │
│  │ Conversations│  │ Total time   │  │ Flags        │ │
│  │ ↑ 3 from     │  │ ↑ 45 min     │  │ ✓ All clear  │ │
│  │   last week  │  │   from last  │  │              │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
│  TOP TOPICS                SENTIMENT TREND              │
│  1. Dinosaurs (5x)        😄━━━━━━━━━░░ Positive       │
│  2. Math (4x)             😊━━━━━━░░░░░ Good           │
│  3. Friends (3x)          😐━━░░░░░░░░░ Neutral        │
│                                                         │
│  RECENT CONVERSATIONS                                   │
│  • 3:45 PM - Dinosaurs (15 min) - Curious 😊          │
│  • 2:20 PM - Math homework (18 min) - Relieved 😅     │
│  • 10:30 AM - Space (12 min) - Excited 🚀             │
│                                                         │
│  [View All →]  [Export Report]  [Settings]             │
└─────────────────────────────────────────────────────────┘
```

---

## Compliance Checklist

```
COPPA (Children's Online Privacy Protection Act)
├─ ✅ Verifiable parental consent (email verification)
├─ ✅ Clear privacy policy
├─ ✅ Parental access to child's data
├─ ✅ Parental deletion rights
├─ ✅ No third-party advertising
├─ ✅ No data sharing without consent
└─ ✅ Reasonable security measures

FERPA (Family Educational Rights and Privacy Act)
├─ ✅ Educational records protected
├─ ✅ Parent access to records
├─ ✅ Consent for disclosure
├─ ✅ Right to amend records
└─ ✅ Notification of rights

GDPR (General Data Protection Regulation)
├─ ✅ Lawful basis (consent)
├─ ✅ Right to access
├─ ✅ Right to deletion
├─ ✅ Right to portability
├─ ✅ Data minimization
├─ ✅ Security by design
└─ ✅ Privacy by default
```

---

## Quick Reference: File Locations

```
📄 Documentation
   ├─ SAFETY_README.md .................... Start here
   ├─ SAFETY_EXECUTIVE_SUMMARY.md ......... For stakeholders
   ├─ SAFETY_ARCHITECTURE.md .............. Full specification
   ├─ IMPLEMENTATION_GUIDE.md ............. For engineers
   └─ SAFETY_VISUAL_GUIDE.md .............. This file

💾 Data Models
   ├─ ParentAccount.swift ................. Parent info & preferences
   ├─ ModeContext.swift ................... Mode state & restrictions
   └─ SafetyModels.swift .................. Flags, logs, sentiment

🛠️ Services
   └─ PINService.swift .................... PIN management & Keychain

📊 Storage
   └─ ~/Library/Application Support/SimpleMoxieSwitcher/
       ├─ parent_account.json
       ├─ mode_context.json
       ├─ activity_log.json
       └─ conversations/
           ├─ child/
           └─ adult/
```

---

## Questions & Answers

**Q: How is the PIN stored?**
A: Encrypted in macOS Keychain using AES-256. Never in plaintext.

**Q: Can children bypass the time restrictions?**
A: No. Time verified with NTP. Clock manipulation detected and logged.

**Q: What happens if a parent forgets their PIN?**
A: Email reset link + security question. If both fail, support escalation.

**Q: Can schools use this?**
A: Yes. FERPA compliant. Institutional logging level available.

**Q: Is data sent to the cloud?**
A: No by default. Local-first. Cloud backup is opt-in future feature.

**Q: What AI providers are used?**
A: OpenAI, Anthropic (configurable). Data processing agreements in place.

**Q: How accurate is content flagging?**
A: Goal: 95%+ detection rate. Manual review recommended for all flags.

**Q: Can multiple children share one device?**
A: Yes. Multi-profile support in roadmap (Phase 9).

---

**For more details, see:**
- Full specs: `SAFETY_ARCHITECTURE.md`
- Implementation: `IMPLEMENTATION_GUIDE.md`
- Overview: `SAFETY_EXECUTIVE_SUMMARY.md`
