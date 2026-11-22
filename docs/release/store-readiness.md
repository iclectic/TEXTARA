# Store readiness checklist

Textara ships as a **fully free** reader. There is no Pro tier, subscription, or mandatory account. See [PLAN.md](../../PLAN.md) and [privacy-and-data.md](privacy-and-data.md).

## Branding

- [x] Android launcher icons (`mipmap-*` + adaptive `mipmap-anydpi-v26`)
- [x] iOS `AppIcon.appiconset`
- [x] macOS `AppIcon.appiconset` (desktop scaffold; not a release blocker)
- [x] Launch / splash: parchment `#F5F0E8` + centred brand mark
- [x] Masters under `assets/branding/`; regenerate with `python3 tool/generate_brand_assets.py`
- [x] Optional tooling: `dart run flutter_launcher_icons` / `dart run flutter_native_splash:create`

## Platform manifests

### Android (`com.textara.textara`)

- [x] Application id set
- [x] Document / share intent-filters for EPUB + PDF
- [x] `android:allowBackup="false"` + backup exclusion XML
- [x] Release signing via `TEXTARA_UPLOAD_*` env vars ([release-signing.md](release-signing.md))
- [ ] Upload AAB built with release keystore (human / CI secrets)

### iOS

- [x] Display name `Textara`
- [x] Document types for EPUB + PDF
- [x] `ITSAppUsesNonExemptEncryption` = `false`
- [x] Files sharing enabled for user exports
- [ ] Archive / IPA with distribution profile (human)

### macOS

- Compile-aware scaffold under `macos/` — **do not** block mobile store submission.

## Store listing copy

Use the draft in [README.md](../../README.md#store-listing). Short pitch:

> Textara is a thoughtfully crafted reading app for your DRM-free EPUB and PDF library. No accounts, no ads, no internet required.

## Screenshots & preview

Required captures (phone + tablet where noted): see [screenshots/README.md](screenshots/README.md).

- [ ] Phone: library grid
- [ ] Phone: reader (typography + theme)
- [ ] Phone: Idea Threads
- [ ] Tablet: two-pane / wide library
- [ ] Short preview video: import → read → highlight → thread

## Versioning

- Keep `pubspec.yaml` at `1.0.0+1` until the first store upload.
- After first ship, bump semver by capability (reader quality, TTS/threads polish, insights) — **all free**.

## Final release gate

| Gate | Status |
|---|---|
| `flutter analyze --no-fatal-infos --fatal-warnings` | CI-enforced |
| Unit + widget + a11y | CI-enforced (`flutter test`) |
| Knowledge-loop smoke | CI-enforced (`integration_test` on `flutter-tester`) |
| Airplane mode | Documented in [airplane-mode.md](airplane-mode.md) |
| Accessibility modes applied | Covered in a11y tests + Settings |
| Privacy questionnaire matches binary | [privacy-and-data.md](privacy-and-data.md) |
| Signed Android AAB + iOS Archive | Requires store credentials (human) |
