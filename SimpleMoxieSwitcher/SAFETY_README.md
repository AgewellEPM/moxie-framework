# Moxie Safety Architecture - Documentation Index

**Version:** 1.0
**Date:** January 7, 2026

---

## Overview

This folder contains the complete production-ready safety and trust architecture for Moxie, a children's AI companion app. The architecture satisfies the needs of parents, schools, and regulators while maintaining a child-friendly, empowering experience.

---

## Documentation Files

### 1. SAFETY_EXECUTIVE_SUMMARY.md
**Audience:** Product leadership, investors, non-technical stakeholders
**Length:** 15 pages
**Purpose:** High-level overview of safety features, benefits, and business case

**Read this if you want:**
- Quick understanding of what we built
- Talking points for stakeholders
- Competitive differentiation
- Budget and timeline estimates

---

### 2. SAFETY_ARCHITECTURE.md
**Audience:** Product managers, designers, engineers, legal team
**Length:** 50+ pages
**Purpose:** Comprehensive specification of all safety features

**Contents:**
- Feature specifications (5 core safety features)
- Data models (ParentAccount, ModeContext, SafetyModels)
- User flows (setup wizard, PIN entry, content flagging)
- UX guidelines (voice/tone, visual design, age-appropriate messaging)
- Privacy policy (COPPA, FERPA, GDPR compliant)
- Edge cases (10+ scenarios with solutions)
- Implementation roadmap (20-week plan)

**Read this if you want:**
- Detailed feature specifications
- User experience guidelines
- Privacy policy draft
- Edge case handling

---

### 3. IMPLEMENTATION_GUIDE.md
**Audience:** Engineering team
**Length:** 20 pages
**Purpose:** Step-by-step guide to implementing the safety architecture

**Contents:**
- Integration steps with existing codebase
- Repository protocols and implementations
- ViewModel patterns
- SwiftUI view examples
- Testing checklist
- Common issues and solutions

**Read this if you're:**
- Implementing the safety features
- Writing unit tests
- Debugging integration issues

---

### 4. Implementation Files (Created)

The following Swift files have been created in your project:

#### Models
- `Sources/SimpleMoxieSwitcher/Models/ParentAccount.swift`
  - Parent account, email, security question
  - Notification preferences
  - Logging preferences (4 privacy levels)

- `Sources/SimpleMoxieSwitcher/Models/ModeContext.swift`
  - Operational mode (child/adult)
  - PIN attempt tracking
  - Auto-lock schedule
  - Emergency override
  - Time window calculations

- `Sources/SimpleMoxieSwitcher/Models/SafetyModels.swift`
  - ConversationLog with safety features
  - ContentFlag (9 categories, 4 severity levels)
  - Sentiment analysis
  - ActivityEvent (14 event types)
  - ActivityLog with filtering

#### Services
- `Sources/SimpleMoxieSwitcher/Services/PINService.swift`
  - PIN creation with strength validation
  - PIN validation with lockout
  - macOS Keychain integration
  - Security utilities

---

## Quick Start

### For Product Managers
1. Read `SAFETY_EXECUTIVE_SUMMARY.md` (30 minutes)
2. Review feature specifications in `SAFETY_ARCHITECTURE.md` (2 hours)
3. Decide on MVP vs. V2 features
4. Schedule stakeholder reviews

### For Engineers
1. Skim `SAFETY_ARCHITECTURE.md` to understand the vision
2. Read `IMPLEMENTATION_GUIDE.md` thoroughly
3. Review the created Swift files
4. Follow integration steps in implementation guide
5. Run tests

### For Designers
1. Read UX Guidelines section in `SAFETY_ARCHITECTURE.md`
2. Review user flows (setup wizard, PIN entry, mode switching)
3. Study visual indicators (color schemes, badges, transitions)
4. Create high-fidelity mockups based on specifications

### For Legal/Compliance
1. Read Privacy Policy section in `SAFETY_ARCHITECTURE.md`
2. Review data models to understand what's collected
3. Verify COPPA, FERPA, GDPR compliance
4. Prepare data processing agreements for schools

---

## Key Concepts

### 1. Dual Mode Architecture
- **Child Mode:** Playful, age-appropriate, limited access
- **Adult Mode:** Professional, full controls, analytics
- Separate conversation databases
- Different AI personalities

### 2. Safety Layers
- **Access Control:** PIN-protected features
- **Time Restrictions:** Bedtime and school locks
- **Content Monitoring:** AI-powered flagging
- **Activity Logging:** Transparent audit trail
- **Emergency Override:** Safety valve for urgent needs

### 3. Privacy Levels
- **High Privacy:** Timestamps only
- **Balanced:** Topics + flags (DEFAULT)
- **Full Transparency:** Complete transcripts
- **Institutional:** Full logs + AI scoring

### 4. Content Flags
- **Low:** Inappropriate language → Log only
- **Medium:** Bullying, sadness → Weekly summary
- **High:** Privacy risk → Immediate alert
- **Critical:** Self-harm → Instant alert + resources

---

## Architecture Highlights

### Security
- PIN stored in macOS Keychain (AES-256)
- File permissions: Owner-only (600)
- No cloud storage by default
- Session timeout: 30 minutes

### Privacy
- Local-first architecture
- Parent-controlled logging level
- COPPA compliant by design
- Data deletion on demand

### Reliability
- Offline mode with cached content
- Crash recovery defaults to Child Mode
- Timezone-aware scheduling
- Graceful degradation

---

## Implementation Phases

### Phase 1: Foundation (Weeks 1-2)
- Data models
- PIN service
- Email verification

### Phase 2: Mode Switching (Weeks 3-4)
- Adult/Child mode UI
- PIN entry screens
- Visual transitions

### Phase 3: Conversation Isolation (Weeks 5-6)
- Separate databases
- Context switching
- Personality adaptation

### Phase 4: Activity Logging (Weeks 7-8)
- Event logging
- Log viewer UI
- Privacy controls

### Phase 5: Time Restrictions (Weeks 9-10)
- Auto-lock scheduler
- Warning notifications
- Extension requests

### Phase 6: Safety Features (Weeks 11-12)
- Content flagging
- Email alerts
- Flag review UI

### Phase 7: Parent Console (Weeks 13-14)
- Dashboard
- Conversation viewer
- Data export

### Phase 8: Setup Wizard (Weeks 15-16)
- Onboarding flow
- Email verification
- Quick configuration

### Phase 9: Edge Cases (Weeks 17-18)
- PIN reset
- Multi-profile
- Offline mode

### Phase 10: Documentation (Weeks 19-20)
- Privacy policy
- User guides
- Compliance docs

---

## Testing Strategy

### Unit Tests
- PIN creation and validation
- Time window calculations
- Content flag detection
- Sentiment analysis
- Activity logging

### Integration Tests
- Mode switching
- Conversation isolation
- Time restrictions
- Emergency override

### UI Tests
- Setup wizard flow
- PIN entry
- Parent console navigation
- Child mode restrictions

### Manual Testing
- Age-appropriateness review
- Parent usability study
- Child safety testing
- Edge case verification

---

## Success Criteria

### Technical
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] UI tests pass
- [ ] Performance benchmarks met (<500ms mode switch)
- [ ] Security audit passed

### User Experience
- [ ] 85%+ setup completion without support
- [ ] 90%+ parent satisfaction
- [ ] 80%+ children feel trusted
- [ ] Zero critical bugs in production

### Compliance
- [ ] COPPA compliant
- [ ] FERPA compliant
- [ ] GDPR compliant
- [ ] Third-party audit passed

---

## Support and Resources

### Internal Contacts
- **Product Questions:** product@moxie.app
- **Technical Questions:** engineering@moxie.app
- **Design Questions:** design@moxie.app
- **Legal Questions:** legal@moxie.app

### External Resources
- COPPA Compliance: https://www.ftc.gov/coppa
- FERPA Guidelines: https://www2.ed.gov/ferpa
- GDPR Resources: https://gdpr.eu

---

## Contributing

### Making Changes
1. Review existing specifications
2. Discuss changes with Product team
3. Update relevant documentation
4. Get legal review if privacy-impacting
5. Update implementation guide

### Documentation Standards
- Use clear, concise language
- Include code examples
- Add acceptance criteria
- Document edge cases
- Update version numbers

---

## Version History

### v1.0 (January 7, 2026)
- Initial production-ready specification
- 5 core safety features
- Complete data models
- Implementation guide
- Privacy policy
- Edge case handling

---

## License and Legal

This documentation is proprietary and confidential.

**Copyright:** Moxie, Inc.
**Effective Date:** January 7, 2026
**Review Date:** February 7, 2026

---

## What's Next?

1. **Week 1:** Stakeholder review and approval
2. **Week 2:** Engineering team kickoff
3. **Week 3:** Begin Phase 1 implementation
4. **Month 3:** Beta testing with 10-20 families
5. **Month 6:** Public launch

**Questions?** Contact the Product team at product@moxie.app
