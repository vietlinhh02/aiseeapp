# AiSeeApp Package-Led Infrastructure Migration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce hand-written infrastructure in `aiseeapp` by replacing repeated HTTP/JSON/socket/chart glue with maintained Flutter packages, while keeping AiSee-specific voice, wake-word, LiveKit, moderation, and device-command logic custom.

**Architecture:** Migrate in slices. First replace low-risk repeated plumbing (`http` + manual JSON parsing) with generated clients. Then replace generic chat websocket reconnect logic. Then remove JS-backed chart rendering. Keep `AiseeAiSession`, LiveKit session orchestration, wake-word, NSFW moderation, and call/push bridge custom until later.

**Tech Stack:** Flutter, `dio`, `retrofit`, `json_serializable`, optional `freezed`, `web_socket_client`, `fl_chart`, existing test suite

**Non-goals:**
- Do not rewrite `AiseeAiSession` or `AiseeLiveKitVoiceSession` in this migration.
- Do not replace `flutter_wake_word`, `livekit_client`, `record`, `camera`, `tflite_flutter`, or RevenueCat wrappers in this phase.
- Do not introduce `Riverpod` until HTTP and websocket migration are stable.

---

### Task 1: Add package foundation for generated API clients

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/api/`
- Create: `lib/api/models/`
- Create: `lib/api/generated/` or package-equivalent generated outputs

- [ ] **Step 1: Add new dependencies**

Add:
- `dio`
- `retrofit`
- `json_annotation`

Add dev dependencies:
- `retrofit_generator`
- `json_serializable`
- `build_runner`

Optional, only if model ergonomics become painful during Task 2:
- `freezed`
- `freezed_annotation`

- [ ] **Step 2: Create shared Dio bootstrap**

Create single HTTP bootstrap with:
- base URL from `AppEnv.apiBaseUrl`
- auth header injection
- timeout defaults
- response logging only in debug
- 401 refresh hook kept explicit, not magical

- [ ] **Step 3: Define migration rules before first client**

Rules:
- new API code goes under `lib/api/`
- old hand-written services stay until exact replacement lands
- no mixed manual/generated parsing in same migrated endpoint
- generated models own JSON shape, screen/service code owns domain decisions

- [ ] **Step 4: Add codegen command to team workflow**

Document and verify:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Acceptance:**
- `flutter pub get` succeeds
- codegen runs cleanly
- no existing app behavior changes yet

---

### Task 2: Pilot generated clients on smallest high-value slice

**Files:**
- Create: `lib/api/auth_api.dart`
- Create: `lib/api/family_api.dart`
- Create: `lib/api/billing_api.dart`
- Create: `lib/api/models/*.dart`
- Modify: `lib/services/aisee_auth_service.dart`
- Modify: `lib/services/aisee_family_service.dart`
- Modify: `lib/services/aisee_billing_service.dart`
- Modify: related tests

- [ ] **Step 1: Migrate `AiseeAuthService` first**

Target current endpoints from:
- `lib/services/aisee_auth_service.dart`

Endpoints:
- `/api/v1/auth/google`
- `/api/v1/auth/refresh`
- `/api/v1/users/me`

Reason:
- small endpoint count
- used everywhere
- good proving ground for token/error patterns

- [ ] **Step 2: Migrate `AiseeFamilyService` second**

Reason:
- medium complexity
- touches core app flows
- validates query/body handling and shared auth headers

- [ ] **Step 3: Migrate `AiseeBillingService` third**

Reason:
- currently has retry/fallback logic
- good test that generated client can still coexist with custom domain fallback

Keep custom logic in wrapper if needed:
- `no_billing_care_group` retry behavior
- current-group resolution
- UI-facing error wording

- [ ] **Step 4: Keep wrapper services thin**

After migration, service wrappers should mainly:
- call generated API
- apply fallback rules
- translate errors
- expose stable interface to screens

They should stop owning:
- raw URL construction
- repeated headers
- repeated `jsonDecode`
- repeated body map assembly where DTO can own it

- [ ] **Step 5: Lock migration with targeted tests**

Run or add tests for:
- auth refresh/resume session
- family current-group and join flow
- billing overview and fallback retry

**Acceptance:**
- migrated services contain no manual `http.Response` handling
- migrated models own JSON parsing
- targeted tests pass
- old screens compile without constructor churn

---

### Task 3: Expand generated API clients to remaining REST services

**Files:**
- Modify: `lib/services/aisee_call_service.dart`
- Modify: `lib/services/aisee_care_service.dart`
- Modify: `lib/services/aisee_chat_service.dart`
- Modify: `lib/services/aisee_dashboard_service.dart`
- Modify: `lib/services/aisee_health_service.dart`
- Modify: `lib/services/aisee_supporter_service.dart`
- Modify: `lib/services/aisee_upload_service.dart`
- Modify: `lib/services/aisee_volunteer_service.dart`

- [ ] **Step 1: Migrate simple CRUD services next**

Suggested order:
1. `aisee_call_service.dart`
2. `aisee_dashboard_service.dart`
3. `aisee_health_service.dart`
4. `aisee_volunteer_service.dart`

- [ ] **Step 2: Migrate multipart upload carefully**

`aisee_upload_service.dart` is special because it owns:
- file-size checks
- MIME validation
- multipart upload

Keep validation custom if needed, but move request transport to `dio`.

- [ ] **Step 3: Migrate chat and care APIs**

These likely have more DTO surface area. Split model files by endpoint family, not giant shared DTO files.

- [ ] **Step 4: Remove dead manual parsing helpers**

After migration, delete unused manual helpers and duplicated error parsing paths where safe.

**Acceptance:**
- majority of REST calls use shared `Dio`
- manual `jsonDecode/jsonEncode` count drops sharply
- no duplicate auth header builders remain in migrated services

---

### Task 4: Replace generic chat websocket plumbing with package client

**Files:**
- Modify: `lib/services/aisee_chat_socket.dart`
- Modify: `lib/widgets/auth_shell.dart`
- Modify: `lib/screens/family_messages_tab.dart`
- Modify: `lib/screens/chat_detail_screen.dart`
- Modify: websocket-related tests

- [ ] **Step 1: Introduce `web_socket_client` for chat only**

Use package for:
- connection lifecycle
- reconnect/backoff
- stream subscription

Do not apply to:
- `AiseeAiSession`

- [ ] **Step 2: Preserve current event contract**

`AiseeChatSocket` should still expose:
- parsed `AiseeMessage` stream
- incoming call event handling
- call ended handling
- unread/in-app message behavior

- [ ] **Step 3: Keep `AuthShell` ownership model**

Do not change architecture here:
- singleton socket still owned by `AuthShell`
- screens still consume same abstraction

Only transport internals should change.

- [ ] **Step 4: Add regression coverage**

Cases:
- reconnect after close
- no duplicate connection on resume
- incoming call payload still reaches push/call bridge
- message parsing still updates `AiseeInAppMessageController`

**Acceptance:**
- `aisee_chat_socket.dart` stops directly using `dart:io WebSocket`
- reconnect logic shrinks materially
- lifecycle behavior remains same from screen perspective

---

### Task 5: Replace JS-backed charts with native Flutter chart package

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/screens/family_dashboard_health_tab.dart`
- Modify: `lib/screens/family_care_widgets.dart`
- Delete: `assets/chart.umd.min.js`
- Delete: `assets/chart_template.html`
- Modify: asset list in `pubspec.yaml`

- [ ] **Step 1: Introduce `fl_chart`**

Use it for current dashboard visuals if chart needs are limited to:
- line
- bar
- pie/donut if any

- [ ] **Step 2: Rebuild current health overview chart**

Start with `FamilyDashboardHealthTab`.
Keep data mapping and visual semantics close to current output.

- [ ] **Step 3: Rebuild care report charts**

Migrate remaining `chartjs_flutter` usage after first chart is visually correct.

- [ ] **Step 4: Remove JS asset dependency**

Delete:
- `assets/chart.umd.min.js`
- `assets/chart_template.html`

Remove `chartjs_flutter` if no longer used.

**Acceptance:**
- no runtime JS/HTML chart assets remain
- chart screens render natively on Flutter
- visual regressions checked on target screens

---

### Task 6: Decide whether `Riverpod` phase is worth doing

**Files:**
- No code changes until decision is explicit
- Optional future targets:
  - `lib/widgets/auth_shell.dart`
  - `lib/main.dart`
  - `lib/services/in_app_message_controller.dart`
  - `lib/services/incoming_call_controller.dart`
  - `lib/services/aisee_reminder_service.dart`
  - `lib/services/aisee_push_service.dart`

- [ ] **Step 1: Re-evaluate after Tasks 1-5**

Only start `Riverpod` if these still hurt:
- singleton sprawl
- widget lifecycle coupling
- cross-screen session/call/reminder state bugs

- [ ] **Step 2: If approved, migrate one vertical slice first**

Best first candidate:
- auth/session/bootstrap state

Do not start by moving whole app at once.

- [ ] **Step 3: Keep service interfaces stable**

Providers should orchestrate services, not rewrite domain behavior.

**Acceptance:**
- explicit yes/no decision recorded
- no broad state-management rewrite without proven need

---

### Task 7: Verification and cleanup

**Files:**
- Verify: targeted `test/*.dart`
- Verify: `flutter analyze`
- Verify: `flutter test`

- [ ] **Step 1: Run targeted verification after each slice**

Minimum per slice:
```bash
flutter analyze
flutter test
```

If full suite is too slow, run slice-specific tests first, then full suite after each completed task.

- [ ] **Step 2: Remove obsolete dependencies only after migration lands**

Candidates:
- `http`
- `http_parser` if upload path no longer needs it
- `chartjs_flutter`

- [ ] **Step 3: Record metrics after migration**

Track:
- number of hand-written HTTP services left
- number of manual JSON parse sites left
- number of JS chart assets left
- size change in `aisee_chat_socket.dart`

---

### Recommended execution order

1. Task 1
2. Task 2
3. Task 3
4. Task 4
5. Task 5
6. Task 7
7. Task 6 only if still justified

---

### Expected outcome

After this migration:
- REST transport becomes consistent and generated
- JSON DTO churn drops hard
- generic websocket reconnect code shrinks
- chart rendering becomes native Flutter
- AiSee-specific real-time voice stack stays custom and protected from risky rewrites
