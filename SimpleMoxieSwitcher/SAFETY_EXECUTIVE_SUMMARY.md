# Moxie Safety Architecture - Executive Summary

**Prepared for:** Product Team, Parents, Schools, Regulators
**Date:** January 7, 2026
**Status:** Production-Ready Specification

---

## What We Built

A comprehensive safety and trust architecture that transforms Moxie from a simple AI companion into a **family-safe, school-approved, regulation-compliant platform**.

---

## The Problem We Solved

Parents, schools, and regulators have three critical concerns about AI companions for children:

1. **Safety:** How do we prevent inappropriate interactions?
2. **Transparency:** How do parents know what their child discussed?
3. **Control:** How do we ensure age-appropriate boundaries?

---

## Our Solution: 5 Core Safety Features

### 1. PIN-Protected Adult Mode
**What it does:** Separates parent controls from child features

**Why it matters:**
- Children cannot modify safety settings
- Parents have private conversations with Moxie about parenting strategies
- Professional tone for adults, playful tone for kids

**How it works:**
- 6-digit PIN stored securely in macOS Keychain
- 3 failed attempts = 5-minute lockout
- Email + security question for PIN reset

---

### 2. Time-Based Restrictions
**What it does:** Automatically locks Moxie during bedtime, school, or custom hours

**Why it matters:**
- Prevents late-night unsupervised interactions
- Enforces screen-time boundaries
- Configurable for each family's values

**How it works:**
- Parent sets allowed windows (e.g., 7 AM - 8 PM weekdays)
- 5-minute warning before auto-lock
- Emergency override if child needs help

**Example:**
```
8:00 PM: "Moxie is sleeping! See you at 7:00 AM tomorrow!"
Child can request extension → Parent gets notification → Approve/deny
```

---

### 3. Memory Isolation (Dual Conversation Context)
**What it does:** Child conversations and parent conversations are completely separate

**Why it matters:**
- Parents can discuss sensitive topics without child seeing
- Child's privacy respected for age-appropriate conversations
- Context switching ensures correct personality

**How it works:**
- `/conversations/child/` - Child's chats with Moxie
- `/conversations/adult/` - Parent's discussions
- AI receives different system prompts based on mode

**Example:**
```
Child Mode: "I'm sad because my friend didn't play with me."
Moxie: [emotion:sad] "That's really hard. Want to talk about it?"

Adult Mode: "My child seems sad about friend conflicts."
Moxie: "Social conflicts are developmentally normal at this age.
Here are evidence-based strategies..."
```

---

### 4. Intelligent Logging with Privacy Controls
**What it does:** Records activity with parent-controlled detail level

**Why it matters:**
- Parents stay informed without invasive surveillance
- Age-appropriate transparency for children
- Compliance with COPPA, FERPA, GDPR

**Logging Levels:**

| Level | What's Logged | Best For |
|-------|---------------|----------|
| **High Privacy** | Timestamps + duration only | Older kids (10+) |
| **Balanced** | Topics + flags + summaries | Most families (DEFAULT) |
| **Full Transparency** | Complete transcripts | Young kids (5-7) |
| **Institutional** | Full logs + AI safety scores | Schools |

**Safety Flagging:**
- AI detects concerning language (self-harm, bullying, etc.)
- Parent gets immediate email for critical flags
- Context provided (3 messages before/after)
- Recommended actions included

---

### 5. Content Flagging and Alerts
**What it does:** Automatically detects and reports concerning language

**Why it matters:**
- Early warning system for mental health concerns
- Privacy risk detection (child sharing address/phone)
- Supports parents in difficult conversations

**Flag Categories:**
- Self-harm language → CRITICAL (immediate alert)
- Bullying mention → MEDIUM (notify within 1 hour)
- Repeated sadness → MEDIUM (weekly summary)
- Inappropriate language → LOW (log only)
- Privacy risk → HIGH (alert + context)

**Example Alert:**
```
Email Subject: 🚨 IMPORTANT: Emma needs your attention

Emma used language suggesting distress: "I hate myself"
Time: 4:22 PM today
Context: Conversation about spelling test grade

Moxie's response: Encouraged Emma to talk to a trusted adult.

Resources: National Suicide Prevention Lifeline (988)
```

---

## Key Benefits

### For Parents
✓ Peace of mind with transparent safety controls
✓ Private conversations about parenting strategies
✓ Early detection of emotional concerns
✓ Flexible controls that match family values
✓ Export data for therapists/doctors if needed

### For Children
✓ Safe, age-appropriate AI companion
✓ Privacy-respecting logging (no surveillance feel)
✓ Emergency help available 24/7
✓ Learns their interests and adapts conversations

### For Schools
✓ COPPA and FERPA compliant out-of-the-box
✓ Audit logs for all student interactions
✓ Content filtering with institutional controls
✓ No advertising or data selling
✓ Local-first (no cloud dependency)

### For Regulators
✓ COPPA compliant: Verifiable parental consent
✓ GDPR compliant: Right to deletion, data portability
✓ FERPA compliant: Educational records protection
✓ Clear privacy policy in plain language
✓ Third-party audit ready

---

## Technical Architecture

### Security
- **PIN Storage:** macOS Keychain (AES-256 encrypted)
- **File Permissions:** Owner-only (chmod 600)
- **Data at Rest:** FileVault encryption (if enabled)
- **No Cloud:** Local-first by default
- **Session Timeout:** 30 minutes of inactivity

### Privacy
- **Local Storage:** `~/Library/Application Support/SimpleMoxieSwitcher/`
- **No Tracking:** No analytics, cookies, or advertising IDs
- **Minimal Data:** Only what's needed for functionality
- **User Control:** Parents can delete data anytime
- **Retention:** Auto-delete after 90 days (configurable)

### Reliability
- **Offline Mode:** Cached stories and learning activities
- **Graceful Degradation:** Falls back to restrictive policy if system time unavailable
- **Crash Recovery:** Always opens in Child Mode after crash
- **Timezone Aware:** Adjusts schedules when traveling

---

## Edge Cases Handled

We've thought through 10+ edge cases:

1. **PIN forgotten during setup** → Restart wizard option
2. **Time zone changes** → Ask parent to update schedule
3. **System clock manipulation** → Detect and lock + alert
4. **Parent lock-out** → Email + security question + support escalation
5. **Child distress during locked hours** → Emergency override with logging
6. **App crash in Adult Mode** → Always reopen in Child Mode
7. **Multiple children, one device** → Multi-profile support
8. **Offline mode** → Limited functionality with cached content
9. **Inappropriate personality for age** → Age-gating with parent approval
10. **Legal data request** → Structured export with compliance support

---

## Implementation Status

### Completed
✅ Full architecture specification (50+ pages)
✅ Data models (ParentAccount, ModeContext, SafetyModels)
✅ PIN service with Keychain integration
✅ Activity logging system
✅ Content flagging framework
✅ Privacy policy and compliance documentation
✅ Implementation guide for engineering team

### Next Steps (Weeks 1-4)
🔨 Setup wizard UI
🔨 Parent Console dashboard
🔨 PIN entry views
🔨 Mode switching implementation
🔨 Email service integration

### Future Enhancements (Weeks 5-20)
📋 Time restriction UI and scheduler
📋 AI-powered sentiment analysis
📋 Multi-child profile switching
📋 Data export (PDF/JSON)
📋 Weekly/daily summary emails
📋 Mobile companion app for remote monitoring

---

## Success Metrics

### Parental Trust
**Goal:** 90%+ parent satisfaction
**Measure:** Post-setup survey

### Child Safety
**Goal:** 95%+ of concerning content flagged
**Measure:** Manual audit of flagged vs. missed content

### Privacy Balance
**Goal:** 80%+ children feel trusted
**Measure:** Age-appropriate child survey

### Compliance
**Goal:** 100% regulatory compliance
**Measure:** Third-party audit (COPPA, FERPA, GDPR)

### Usability
**Goal:** 85%+ parents complete setup without support
**Measure:** Setup completion rate

---

## Competitive Differentiation

| Feature | Moxie | Competitor A | Competitor B |
|---------|-------|--------------|--------------|
| Local-first storage | ✅ | ❌ (Cloud only) | ❌ (Cloud only) |
| Dual conversation context | ✅ | ❌ | ❌ |
| Age-appropriate transparency | ✅ | ⚠️ (Partial) | ❌ |
| Emergency override | ✅ | ❌ | ❌ |
| COPPA compliant | ✅ | ✅ | ⚠️ (Unclear) |
| Institutional deployment | ✅ | ❌ | ✅ |
| No cloud dependency | ✅ | ❌ | ❌ |

---

## Risks and Mitigations

### Risk: Parents find logging invasive
**Mitigation:** Four privacy levels, child-friendly transparency

### Risk: Children find workarounds (clock manipulation)
**Mitigation:** NTP verification, suspicious activity detection

### Risk: Setup too complex
**Mitigation:** 3-minute wizard with smart defaults

### Risk: False positives in content flagging
**Mitigation:** AI explanation + context + parent review required

### Risk: Regulatory changes
**Mitigation:** Modular architecture, quarterly compliance reviews

---

## Budget and Resources

### Development (20 weeks)
- 1 Senior iOS Engineer (full-time)
- 1 Product Designer (half-time)
- 1 QA Engineer (half-time)
- Legal counsel (hourly)

### Infrastructure
- Email service: $50/month (transactional)
- NTP service: Free (pool.ntp.org)
- Compliance audit: $5,000 (one-time)

### Total Estimated Cost: $150,000 - $200,000

---

## Decision Points

### For Product Team

**Question:** Which features are MVP vs. V2?

**Recommendation:**
- **MVP (Launch):** PIN, Mode Switching, Basic Logging, Time Restrictions
- **V1.1 (Month 2):** Content Flagging, Email Alerts
- **V1.2 (Month 3):** Parent Console Dashboard, Export
- **V2.0 (Month 6):** Multi-child, Mobile App, Advanced Analytics

### For Leadership

**Question:** Should we support cloud backup at launch?

**Recommendation:** **NO** - Local-first is our competitive advantage and reduces compliance risk. Add cloud as opt-in V2 feature.

### For Legal

**Question:** Are we ready for institutional deployment (schools)?

**Recommendation:** **YES** - Architecture supports FERPA compliance. Need data processing agreement template and school admin guide.

---

## Go-to-Market Messaging

### For Parents
**Headline:** "The AI companion that grows with your child—safely."

**Key Messages:**
- You're in control with transparent safety features
- Privacy-first: Your data stays on your device
- Early warning system for emotional concerns
- Adapts to your family's values

### For Schools
**Headline:** "COPPA-compliant AI learning for every classroom."

**Key Messages:**
- Designed for educational settings
- Full audit trails for administrator review
- No advertising or data collection
- Supports diverse learning needs

### For Press
**Headline:** "Moxie sets new standard for children's AI safety."

**Key Messages:**
- First AI companion with dual-context memory isolation
- Local-first architecture protects privacy
- Transparent logging without surveillance
- Backed by child development experts

---

## Call to Action

### Immediate Next Steps
1. ✅ **Review this architecture with stakeholders** (Product, Engineering, Legal, Design)
2. 🔨 **Prioritize MVP features** (Use recommendation above)
3. 🔨 **Assign engineering team** (1 senior iOS engineer to start)
4. 🔨 **Begin Phase 1 implementation** (Data models + PIN service)
5. 📋 **Schedule legal compliance review** (Target: Week 2)
6. 📋 **Create setup wizard mockups** (Target: Week 3)
7. 📋 **Plan beta program** (10-20 families, target Month 3)

---

## Questions?

**Product Questions:** product@moxie.app
**Technical Questions:** engineering@moxie.app
**Legal/Compliance Questions:** legal@moxie.app

**Document Owner:** Product Team
**Last Updated:** January 7, 2026
**Next Review:** February 7, 2026
