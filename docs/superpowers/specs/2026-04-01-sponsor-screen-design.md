# Sponsor Screen Design

## Summary

Add a `Nhà tài trợ` entry inside both the user and family `Cá nhân` tabs. Tapping the entry
should open a shared sponsor screen that presents project sponsors, starting with `DAVO`, its
website `https://davoice.io/`, a short description based on DAVO's published product focus, and
the sponsor logo loaded directly from the sponsor website.

## Problem

The app currently has no place to acknowledge project sponsors. The user and family areas already
use card-based secondary destinations inside `Cá nhân`, so sponsors should fit that structure
instead of expanding bottom navigation or creating role-specific information architecture.

## Goals

- Add a discoverable `Nhà tài trợ` item in the user `Cá nhân` tab.
- Add the same `Nhà tài trợ` item in the family `Cá nhân` tab.
- Open one shared sponsor screen from both entry points.
- Show the first sponsor as `DAVO` with logo, website, and a grounded description.
- Keep the UI consistent with the app's existing card and accessibility patterns.

## Non-Goals

- Adding a fourth bottom navigation tab.
- Building sponsor management, CMS, or backend integration.
- Adding role-specific sponsor data for user and family.
- Downloading and storing sponsor brand assets inside the repo for this change.

## Recommended Approach

Reuse one shared `SponsorScreen` for both user and family. Add a sponsor menu card in each
`Cá nhân` tab, keep sponsor data static in the screen layer, and render DAVO's logo from its
published site asset URL instead of bundling a local asset.

Why this approach:

- It keeps user and family behavior consistent.
- It avoids duplicating nearly identical screen code.
- It lets the app acknowledge the sponsor with a real logo immediately.
- It remains small and easy to expand when more sponsors are added later.

## Screen Behavior

### User Personal Tab

1. Add a new menu card labeled `Nhà tài trợ`.
2. Subtitle explains that the screen contains supporting organizations.
3. Tapping the card pushes the shared sponsor screen.

### Family Personal Tab

1. Add a new menu card labeled `Nhà tài trợ`.
2. Keep it visually aligned with the existing `Email`, `Vai trò`, `Ngày tham gia`, and volunteer
   content.
3. Tapping the card pushes the same shared sponsor screen.

### Sponsor Screen

1. Show an app bar title `Nhà tài trợ`.
2. Show a short intro explaining that these organizations are supporting AiSee.
3. Render a sponsor card for `DAVO`.
4. The card includes:
   - sponsor logo loaded from website URL
   - sponsor name `DAVO`
   - website text `davoice.io`
   - description grounded in DAVO's website content
   - a primary action to open the sponsor website
5. The layout remains a simple scrollable page so additional sponsors can be appended later.

## Sponsor Content

Start with one static sponsor entry:

- Name: `DAVO`
- Website: `https://davoice.io/`
- Logo URL: use DAVO's published logo asset URL from the website metadata
- Description: `DAVO phát triển công nghệ voice AI chạy trực tiếp trên thiết bị, gồm wake word,
  speaker recognition, VAD, STT và TTS, ưu tiên tốc độ và quyền riêng tư.`

This description is based on DAVO's public site messaging about on-device voice AI, wake word /
hotword detection, speaker recognition, VAD, STT, TTS, speed, and privacy.

## Data Model

Keep sponsor content local and static for now.

- A small in-file list or constant model is enough.
- Start with a single sponsor object for `DAVO`.
- Include logo URL in the static object.
- No API calls, persistence, or caching.

## Remote Logo Handling

- Load the sponsor logo from the remote DAVO asset URL.
- Provide a small visual fallback if the network image fails.
- Do not block the rest of the card if the logo cannot load.
- Keep the sponsor name visible even when the image is unavailable.

## External Link Handling

- The sponsor action should open `https://davoice.io/`.
- Reuse the project's existing `url_launcher` pattern.
- If opening fails, surface a clear user-facing error message instead of failing silently.

## Accessibility

- Both new menu cards should have descriptive semantics labels.
- The sponsor card should expose readable sponsor information even if the logo does not load.
- The website action should expose clear button semantics.
- Preserve the large tap-target style already used in the app.

## Testing

- `UserPersonalTab` renders a `Nhà tài trợ` entry and navigates to the sponsor screen.
- `FamilyPersonalTab` renders a `Nhà tài trợ` entry and navigates to the same sponsor screen.
- The sponsor screen shows `DAVO`, `davoice.io`, and the updated description.
- The sponsor screen attempts to load the remote logo without crashing widget tests.
- The website action uses the existing URL launch flow or its injected equivalent in tests.

## Notes

- This design document was written locally only. I did not create a git commit because commit
  creation requires an explicit user request in this workspace.
