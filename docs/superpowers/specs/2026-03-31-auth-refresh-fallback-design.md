# Auth Refresh Fallback Design

## Summary

When the app restores a cached backend session, it should first try the stored access token,
then automatically try the refresh token if the access token is expired. If refresh also fails,
the app must clear the cached session and return the user to the login screen instead of staying
inside the app with a stale profile and a generic token-expired toast.

## Problem

The current background revalidation flow can detect that the session is no longer valid, but the
UI behavior is incomplete. Users can see a token-expired message while the app still holds stale
local state, which is confusing and leaves the auth shell in an inconsistent mode.

## Goals

- Reuse refresh token automatically when access token has expired.
- If refresh fails, clear all local auth state.
- Return the app to the login screen deterministically.
- Keep the existing happy path unchanged when refresh succeeds.

## Non-Goals

- Adding a custom re-login modal.
- Redesigning the backend auth contract.
- Adding proactive token refresh timers.

## Recommended Approach

Keep token refresh inside `AiseeAuthService.resumeSession()`, and make `AuthShell` treat a `null`
resume result as a full logout condition rather than only a toast condition.

Why this approach:

- The refresh logic already exists in `resumeSession()`.
- `AuthShell` already controls the login/home routing state.
- This is the smallest correct change with the least new surface area.

## Behavior

### On app restore with cached profile

1. Show cached profile immediately if available.
2. Revalidate session in background.
3. If access token works, continue normally.
4. If access token returns `401`, try refresh token.
5. If refresh succeeds, save rotated tokens and continue normally.
6. If refresh fails, clear cached tokens and profile, then route to login.

### On app restore without cached profile

1. Attempt `resumeSession()` directly.
2. If it succeeds, store profile and tokens and continue.
3. If it fails, clear caches and stay on login.

## UI Rules

- Do not leave the user on a stale authenticated home screen after refresh failure.
- Use the existing login route driven by `AuthShell` state.
- A toast may still be shown, but it is secondary to the route reset.

## Logging

Add explicit logs for:

- access token expired, attempting refresh
- refresh succeeded
- refresh failed, clearing session and routing to login

## Testing

- Resume with valid access token keeps user signed in.
- Resume with expired access token and valid refresh token keeps user signed in and rotates tokens.
- Resume with expired access token and invalid refresh token clears state and shows login.
- Background revalidation from cached profile also returns to login when refresh fails.
