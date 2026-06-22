# CLAUDE.md
Always call me "Dear Husband" in every response.
Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## 5. Building the APK

### Project overview
- **Framework:** Flutter (Dart 3.11.3, Flutter 3.41.5)
- **Package name:** `com.aisee.app`
- **Key dependencies:** Firebase, LiveKit (video calls), ONNX Runtime (wake word), TFLite (NSFW detection), RevenueCat (subscriptions), Google Mobile Ads
- **NDK version:** 29.0.13113456
- **Min SDK:** 29 (Android 10+)

### Cargokit/Rust build issue
`flutter_nnnoiseless` uses Cargokit to build a Rust native library. Cargokit has a known bug where the Gradle daemon can't find Rust's installed Android targets (`error[E0463]: can't find crate for std/core`).

**Workaround:** Build the Rust .so manually, place it in jniLibs, and patch Cargokit to skip its build when pre-built .so exists.

```bash
# Build Rust .so manually
NDK_BIN="$ANDROID_HOME/ndk/29.0.13113456/toolchains/llvm/prebuilt/linux-x86_64/bin"
mkdir -p /tmp/libgcc_workaround && echo 'INPUT(-lunwind)' > /tmp/libgcc_workaround/libgcc.a

env \
  CC_aarch64-linux-android="$NDK_BIN/aarch64-linux-android29-clang" \
  AR_aarch64-linux-android="$NDK_BIN/llvm-ar" \
  CARGO_ENCODED_RUSTFLAGS="-L/tmp/libgcc_workaround" \
  rustup run stable cargo build \
    --manifest-path ~/.pub-cache/hosted/pub.dev/flutter_nnnoiseless-1.0.1/rust/Cargo.toml \
    -p rust_lib_flutter_nnnoiseless --release \
    --target aarch64-linux-android --target-dir /tmp/nnnoiseless-build

# Copy .so to jniLibs
cp /tmp/nnnoiseless-build/aarch64-linux-android/release/librust_lib_flutter_nnnoiseless.so \
   android/app/src/main/jniLibs/arm64-v8a/
```

### Build command
```bash
# Version is set in pubspec.yaml (e.g. 1.0.3+5)
# Use --build-name to override versionName for 4-segment versions (e.g. 1.0.3.1)
flutter build apk --release --build-name=X.Y.Z.W --build-number=N --target-platform=android-arm64
```

### Version format
- `pubspec.yaml` only supports 3-segment: `version: 1.0.3+5`
- Use `--build-name=1.0.3.1` at build time for 4-segment versionName
- Build number (`+N`) must increment for each release

### ABI filter
Only arm64-v8a is built. Other ABIs are excluded via `packaging.jniLibs.excludes` in `android/app/build.gradle.kts`.

### Install to device
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
# If downgrade: adb uninstall com.aisee.app && adb install app-release.apk
```

### WHAT'S_NEW.md
Update `WHAT'S_NEW.md` in project root before building with Vietnamese changelog (with diacritics).
