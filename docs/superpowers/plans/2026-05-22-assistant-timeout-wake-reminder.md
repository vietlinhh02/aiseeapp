# Assistant Timeout Wake Reminder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When the assistant times out after silence, notify the user with sound plus a persistent wake reminder, and show an always-visible "call AiSee" hint card on the assistant screen.

**Architecture:** Keep the timeout source inside `AssistantAudioCoordinator`, surface a reasoned callback to `UserHomeScreen`, and render reminder cards through `UserAssistantTab`. Reuse existing system alert and haptic feedback instead of adding new audio assets or TTS.

**Tech Stack:** Flutter, existing wake coordinator, existing assistant tab, existing localization, existing system sound/haptic feedback helpers

---

### Task 1: Lock timeout callback behavior with tests

**Files:**
- Modify: `test/user_home_wake_handoff_test.dart`

- [ ] **Step 1: Add failing test for grace-expired idle callback**
- [ ] **Step 2: Verify only timeout path emits the reminder reason**

### Task 2: Lock assistant-screen reminder UI with tests

**Files:**
- Create: `test/user_assistant_tab_test.dart`

- [ ] **Step 1: Add failing widget test for persistent wake hint card**
- [ ] **Step 2: Add failing widget test for timeout reminder card**

### Task 3: Implement reminder plumbing

**Files:**
- Modify: `lib/services/assistant_audio_coordinator.dart`
- Modify: `lib/screens/user_home_screen.dart`
- Modify: `lib/screens/user_assistant_tab.dart`
- Modify: `lib/l10n/app_vi.arb`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Add idle-wake callback with timeout reason**
- [ ] **Step 2: Store and clear reminder state in `UserHomeScreen`**
- [ ] **Step 3: Play alert sound, haptic, and announcement on timeout**
- [ ] **Step 4: Render timeout reminder card and wake hint card in assistant tab**
- [ ] **Step 5: Regenerate localizations**

### Task 4: Verify

**Files:**
- Verify: `test/user_home_wake_handoff_test.dart`
- Verify: `test/user_assistant_tab_test.dart`

- [ ] **Step 1: Run targeted Flutter tests**
- [ ] **Step 2: Run formatter if needed**
