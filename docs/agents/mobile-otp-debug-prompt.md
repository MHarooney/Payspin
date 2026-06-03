# Mobile OTP debug — agent prompt

**Purpose:** Debug Firebase Phone Auth on a **physical iPhone** (or simulator): OTP not received, app jumping to step 3/5, stale session restore, iOS SMS autofill, and agent-driven device testing via **mobile-mcp**.

**When to use:** Paste the prompt below into a **new Cursor Agent chat** (or Claude Code) when onboarding OTP is broken on device — not for general mobile UI work (see [mobile-implementation-prompt.md](mobile-implementation-prompt.md)).

---

## How to use this prompt (read first)

### 1. Use the **project** MCP config, not only global

| File | Scope |
|------|--------|
| **`Payspin/.mcp.json`** | Project — **correct for this repo** (already has `dart` + `mobile-mcp`) |
| **`~/.cursor/mcp.json`** | Global — optional; add `mobile-mcp` here only if project MCP does not load |

After editing MCP config: **restart Cursor** or reload MCP servers (`Cursor Settings → MCP → refresh`).

See also: [claude-mcp-setup.md](claude-mcp-setup.md).

### 2. Start a **fresh agent chat** with context attached

Best results when the agent can read files and run tools:

```
@docs/agents/mobile-otp-debug-prompt.md
@mobile/lib/presentation/onboarding/pages/step_otp_page.dart
@mobile/lib/core/onboarding/onboarding_progress.dart
@.mcp.json

[Paste the AGENT PROMPT section below]
```

Attach a **screenshot** of the OTP screen if the bug is visual (e.g. stuck on 3/5 with empty boxes).

### 3. One task per message (don’t overload)

| Good | Bad |
|------|-----|
| “Fix stale OTP restore and verify with `flutter test`” | “Fix OTP, redesign onboarding, deploy to Hetzner, add Circles” |
| “Configure mobile-mcp and list my connected iPhone” | “Make the whole app work” |
| “Add Firebase test number flow for +20 …” | “Integrate every MCP in mcp.json” |

Work in order: **MCP device visible → code fix → run on phone → confirm SMS or test code**.

### 4. Prepare the device before asking the agent

```bash
# Install debug build on iPhone (from repo root)
./scripts/dev/ios-run-iphone.sh

# Or manually
cd mobile
flutter run --dart-define-from-file=dart_defines.local.json
```

On the iPhone:

- Trust the computer, enable **Developer Mode**
- Payspin debug app installed
- If stuck on OTP from an old session: tap **Back** on OTP (clears progress) or delete/reinstall the app

### 5. Enable mobile-mcp prerequisites (Mac)

```bash
# Node 22+ recommended for mobile-mcp
node -v

# Xcode CLI
xcode-select -p

# iPhone visible to Xcode
xcrun xctrace list devices
# or: Xcode → Window → Devices and Simulators
```

In Cursor, confirm **`mobile-mcp`** shows as connected (green) under MCP servers.

### 6. Real SMS (production path)

Use your **real phone number** in onboarding. Firebase sends a normal SMS OTP.

**If no SMS arrives:**

1. Firebase Console → **Authentication → Sign-in method → Phone** — confirm Phone is **Enabled**
2. Remove your number from **Phone numbers for testing** (test numbers skip SMS and use a fixed code)
3. **Blaze billing** may be required for some regions (e.g. +20 Egypt)
4. Tap **Resend code** on the OTP screen after fixing Console settings

**Optional dev shortcut:** Add a *different* throwaway number under “Phone numbers for testing” for CI/simulator only — never list your real number there.

### 7. What to expect from the agent

| Tool | Use for OTP work |
|------|------------------|
| **`dart` MCP** | Analyze Flutter code, run tests, read packages |
| **`mobile-mcp`** | List devices, launch app, tap/type on real iPhone, screenshots |
| **`browsermcp` / `playwright`** | Payer web only — **not** for native OTP |
| **`payspin-design`** | UI polish only — not for Firebase debugging |

### 8. Verify fixes locally

```bash
cd mobile
flutter test test/onboarding_progress_store_test.dart test/otp_restore_test.dart
flutter analyze lib/presentation/onboarding lib/core/onboarding lib/core/firebase
```

### 9. Short prompts for follow-up chats

After the main prompt, use small follow-ups:

- *“List iOS devices via mobile-mcp and screenshot the OTP screen.”*
- *“Clear stale onboarding progress logic — user still lands on OTP without SMS.”*
- *“Wire iOS SMS autofill so 6 digits auto-submit.”*
- *“Add kDebugMode hint when Firebase returns too-many-requests.”*

---

## Known issue (already partially fixed in repo)

**Symptom:** App opens directly to **step 3/5 “Enter the code”** with no SMS.

**Cause:** `OnboardingProgressStore` persisted a previous verification; splash restored `/onboarding/otp` even when Firebase never confirmed SMS or the session expired.

**Current behavior (verify in code):**

- Restore OTP only when **`verificationId` + `codeSent`**
- Auto **resend** when restored session is older than `OnboardingProgress.resendAfter` (~4 min)
- Incomplete sessions → restore **phone** step, not OTP

Key files:

- `mobile/lib/core/onboarding/onboarding_progress.dart`
- `mobile/lib/presentation/splash/splash_page.dart`
- `mobile/lib/presentation/onboarding/pages/step_otp_page.dart`
- `mobile/lib/core/firebase/phone_auth_service.dart`

---

## AGENT PROMPT (copy from here)

```
You are a senior Flutter + Firebase + MCP automation expert working on the Payspin monorepo.

## Goal
Fix and fully debug the mobile onboarding phone OTP flow on a physical iPhone. The app may open directly to onboarding step 3/5 ("Enter the code") without the user receiving an SMS. Deliver reliable OTP delivery, iOS SMS autofill, stale-session recovery, and agent-driven device testing via mobile-mcp.

## Context
- Flutter app: mobile/
- Firebase Phone Auth: payspin-mobile project; iOS AppDelegate handles reCAPTCHA deep links
- Onboarding restore:
  - mobile/lib/core/onboarding/onboarding_progress.dart
  - mobile/lib/presentation/splash/splash_page.dart
  - mobile/lib/presentation/onboarding/pages/step_otp_page.dart
  - mobile/lib/core/firebase/phone_auth_service.dart
- OTP UI: mobile/lib/core/design_system/widgets/payspin_otp_boxes.dart (AutofillHints.oneTimeCode)
- Project MCP: Payspin/.mcp.json (dart + mobile-mcp)
- Agent doc: docs/agents/mobile-otp-debug-prompt.md

## Root causes to verify
1. Stale SharedPreferences key payspin_onboarding_phone_progress restores OTP without re-sending SMS
2. Firebase may not SMS real +20 numbers without billing or test numbers
3. iOS reCAPTCHA completes but app restart leaves a stale verificationId

## Tasks

### A. MCP — physical iPhone
1. Confirm mobile-mcp in Payspin/.mcp.json is enabled in Cursor
2. Prerequisites: Xcode, iPhone USB + trusted + Developer Mode, debug build installed
3. Use mobile-mcp to: list devices, launch Payspin, capture OTP screen, tap/type OTP digits
4. Use dart MCP for analysis/tests; do NOT use browser MCP for native OTP

### B. OTP restore / send logic
1. Restore OTP only when verificationId AND codeSent == true
2. Auto-resend when restored session is older than ~4 minutes
3. Phone-only snapshot → /onboarding/phone, not OTP
4. On fresh OTP entry (not restore): call sendCode()
5. Surface Firebase errors (reCAPTCHA, too-many-requests, app verification)
6. Resend code must update persisted progress

### C. Auto-detect and auto-fill OTP
1. iOS: AutofillGroup + AutofillHints.oneTimeCode on hidden TextField
2. Android: Firebase verificationCompleted instant-verify
3. Auto-submit when 6 digits entered (onCompleted)
4. kDebugMode: document Firebase test phone numbers (fixed code in Console)
5. Do not commit secrets

### D. Firebase dev setup
1. Console → Auth → Phone → enable + test numbers
2. iOS: APNs key for silent push (helps instant verify)
3. Verify GoogleService-Info.plist, Info.plist reCAPTCHA scheme, AppDelegate.swift

### E. Unblock user manually
- OTP Back button → clearPhoneProgress()
- Or delete/reinstall app

### F. Tests
cd mobile && flutter test test/onboarding_progress_store_test.dart test/otp_restore_test.dart

## Success criteria
1. Fresh install: Welcome → Name → Phone → OTP → SMS or test code works
2. Kill during reCAPTCHA: correct restore + working resend
3. iOS SMS autofill fills 6 boxes and submits
4. mobile-mcp can interact with the device on OTP screen
5. No silent jump to step 3 without active SMS session

## Constraints
- Minimal diffs; match Payspin patterns
- No Payspin-portal changes
- No .env / dart_defines.local.json commits

Start by: list iOS devices via mobile-mcp, read onboarding restore code, then run phone → OTP on the physical iPhone.
```

---

## Quick troubleshooting

| Symptom | Try |
|---------|-----|
| Jump to OTP, no SMS | Back on OTP or reinstall app; check Firebase test numbers |
| “Too many attempts” | Wait 15 min or use Firebase test number |
| reCAPTCHA / app verification error | Physical device, latest debug build; Firebase iOS app verification |
| Agent can’t see phone | Reload MCP; check Xcode devices; USB + trust |
| Autofill doesn’t appear | Real SMS format must include code; tap OTP field; iOS 12+ |
| Tests pass, device fails | Firebase/billing/device attestation — separate from unit tests |

---

## Related docs

- [claude-mcp-setup.md](claude-mcp-setup.md) — MCP servers in this repo
- [mobile-implementation-prompt.md](mobile-implementation-prompt.md) — general mobile agent prompt
- [../../mobile/README.md](../../mobile/README.md) — Flutter run commands
