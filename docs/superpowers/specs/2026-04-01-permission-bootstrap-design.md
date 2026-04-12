# Permission Bootstrap Design

## Summary

Add a single permission bootstrap flow that runs once after authentication and requests the core
runtime permissions needed across both user and family experiences: microphone, camera,
notifications, and location. At the same time, stop treating special Android permissions such as
`SYSTEM_ALERT_WINDOW` and `USE_FULL_SCREEN_INTENT` as part of the normal permission flow, and
investigate removing the fullscreen-call dependency if the current call UI can work through the
existing callkit-style incoming call path.

## Problem

The app currently requests permissions in several separate places:

- push notifications in `AiseePushService`
- microphone, camera, and location in `AiseeLiveKitVoiceSession`
- microphone and overlay in `AiseeWakeWordService`
- notification permission for foreground behavior in `AiseeVoiceAssistantForeground`

This creates a fragmented experience where permissions appear at different times, often only when
the user first touches a feature. It also makes it hard to reason about which permissions are
actually mandatory, and whether special Android capabilities like fullscreen intent or overlay are
still justified.

## Goals

- Request the core runtime permissions once in a single bootstrap flow.
- Cover both user and family feature needs with the same upfront permission pass.
- Remove duplicated or scattered permission prompts where possible.
- Keep feature-level code able to re-check permissions safely if the OS later revokes them.
- Investigate whether `SYSTEM_ALERT_WINDOW` and `USE_FULL_SCREEN_INTENT` can be removed from the
  normal call path.

## Non-Goals

- Building a large multi-step onboarding UI.
- Replacing the incoming call plugin.
- Solving iOS-specific permission differences in this same change unless already required by shared
  code.

## Recommended Approach

Create a dedicated permission bootstrap service that is triggered once after the app finishes auth
bootstrap and before the user starts using feature tabs. This service should request the core
runtime permissions in a deterministic order and cache a local completion flag so the app does not
prompt on every launch.

Why this approach:

- It matches the user request to ask for the needed permissions in one pass.
- It centralizes permission logic instead of letting each feature request independently.
- It still lets individual features guard themselves if a permission is later revoked.
- It gives us one place to separate normal runtime permissions from Android special cases.

## Permission Scope

### Request upfront in bootstrap

- `microphone`
- `camera`
- `notification`
- `location`

These support the combined user and family experience: voice assistant, camera assist, calls,
push/foreground notices, and location-linked features.

### Do not request upfront in bootstrap

- `SYSTEM_ALERT_WINDOW`
- `USE_FULL_SCREEN_INTENT`

Reasoning:

- `SYSTEM_ALERT_WINDOW` is a special Android capability and should not be asked as part of the
  standard permission pack unless a concrete feature truly requires overlay drawing outside the
  app.
- `USE_FULL_SCREEN_INTENT` is not a normal runtime permission. It belongs to the Android incoming
  call / urgent notification path and should be justified separately from the regular permission
  bootstrap.

## App Behavior

### First authenticated entry

1. User signs in or restores into an authenticated session.
2. App runs the permission bootstrap once.
3. Runtime permission requests appear in a fixed order.
4. App marks bootstrap as completed locally after the pass finishes, regardless of grant or deny,
   so the user is not forced through the same sequence on every launch.
5. Features may still re-check permission status later before performing protected actions.

### Later app launches

1. If bootstrap has already run, do not auto-request the same bundle again.
2. Feature code should check current status and handle denied / revoked states gracefully.
3. If product later wants a manual “Review permissions” entry, that can be added separately.

## Integration Points

### Central bootstrap

- Trigger the permission bootstrap from app startup after auth is ready and before feature use.
- The bootstrap should live outside individual feature services.

### Existing services

- `AiseePushService`: stop owning the first notification prompt if bootstrap now handles it.
- `AiseeLiveKitVoiceSession`: stop being the first place that asks for mic/camera/location on the
  happy path; keep safety checks.
- `AiseeWakeWordService`: stop requesting `SYSTEM_ALERT_WINDOW` as part of normal startup unless a
  verified technical need remains.
- `AiseeVoiceAssistantForeground`: reuse the already-granted notification state when possible.

## Special-Permission Review

### `SYSTEM_ALERT_WINDOW`

Current state:

- The app requests it inside `AiseeWakeWordService`.
- The Android manifest also declares `SYSTEM_ALERT_WINDOW`.

Design decision:

- Treat this as suspicious until proven necessary.
- Verify what user-visible behavior actually depends on overlay capability.
- If incoming calls and assistant flows work without overlay drawing outside the app, remove this
  permission request and likely the manifest entry.

### `USE_FULL_SCREEN_INTENT`

Current state:

- The manifest declares `android.permission.USE_FULL_SCREEN_INTENT`.
- Incoming calls are shown through `flutter_callkit_incoming` and push handling.

Design decision:

- Separate this from runtime permission logic.
- Verify whether the current call plugin and target Android versions still need the manifest entry
  for the desired incoming-call behavior.
- If the app can still present call UI through callkit-style notifications without it, remove the
  manifest permission.

## Error Handling

- If a permission is denied, bootstrap should continue through the remaining permissions instead of
  aborting on the first refusal.
- The app should log the resulting statuses for debugging.
- Feature code should provide clear user-facing messaging when a denied permission blocks a later
  action.

## Accessibility

- The bootstrap flow must not trap the user in an endless permission loop.
- If a custom explanatory screen is added later, it should use plain language and large tap targets.
- For now, a simple one-pass system-triggered sequence is acceptable.

## Testing

- Bootstrap requests microphone, camera, notification, and location in the chosen order.
- Bootstrap marks itself complete after the first pass.
- Existing feature services no longer own the first prompt on the happy path.
- Denied permissions do not crash bootstrap or prevent later app use.
- Special permissions are no longer requested automatically unless explicitly justified.

## Notes

- This design document was written locally only. I did not create a git commit because commit
  creation requires an explicit user request in this workspace.
