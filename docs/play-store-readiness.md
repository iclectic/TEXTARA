# Textara Play Store Readiness Checklist

Status key:

- Completed: verified in this repository.
- Needs work: required before Play Store upload.
- Risk: could block release or create review/support issues.

## Build and Release

| Item | Status | Risk | Recommendation |
|---|---|---|---|
| Android app bundle builds | Completed | Low | Keep `flutter build appbundle --release` as a release gate. |
| Static analysis | Completed | Low | Keep `flutter analyze` clean before every release. |
| Unit/widget tests | Completed | Medium | Current tests are useful but shallow; expand before public release. |
| Release signing | Needs work | High | Gradle supports `android/key.properties`; create a real upload keystore before Play upload. |
| Versioning | Needs work | Medium | Confirm `pubspec.yaml` `version` and Android `versionCode` before every upload. |
| App size | Risk | Medium | Current bundle is about 59 MB; monitor after assets/features are added. |
| R8/ProGuard | Risk | Low | Validate release behavior after signing and dependency upgrades. |

## Android Store Assets

| Item | Status | Risk | Recommendation |
|---|---|---|---|
| App name | Completed | Low | Android label is `Textara`. |
| Package name | Completed | Medium | Current package is `com.textara.textara`; confirm ownership before publishing. |
| Launcher icon | Needs work | High | Replace default Flutter launcher icon with branded icons. |
| Adaptive icon | Needs work | High | Add Android adaptive foreground/background assets. |
| Splash screen | Needs work | Medium | Add a branded, calm launch screen. |
| Screenshots | Needs work | High | Capture phone and tablet screenshots after UI polish. |
| Feature graphic | Needs work | Medium | Create a Play feature graphic matching the app identity. |

## Privacy and Permissions

| Item | Status | Risk | Recommendation |
|---|---|---|---|
| No account required | Completed | Low | Preserve this unless explicitly approved otherwise. |
| Offline-first behavior | Completed | Medium | Reader/library work locally; keep network-free core flows. |
| Ads/tracking | Completed | Low | No ad or analytics SDKs are present. |
| Broad storage permissions | Completed | Low | File picker avoids broad storage permissions. |
| Privacy policy | Needs work | High | Draft exists in `docs/privacy-policy.md`; host it at a public HTTPS URL before submission. |
| Data Safety form | Needs work | High | Fill based on local-only data handling and no collection/sharing. |

## Product Quality Gates

| Item | Status | Risk | Recommendation |
|---|---|---|---|
| EPUB import failure handling | Completed | Medium | Unreadable EPUB imports now fail instead of creating broken rows. |
| Duplicate import handling | Completed | Medium | Likely duplicates are rejected by title, format, and file size. |
| Backup validation | Completed | Medium | Restore rejects duplicate IDs and orphaned annotations. |
| Metadata-only restore warning | Completed | Medium | Restore reports missing book files after metadata import. |
| EPUB reader quality | Needs work | High | Highlight creation, TOC jumps, and viewport-measured Flutter text pagination exist; full EPUB CSS/layout fidelity still needs deeper engine work. |
| PDF reader quality | Risk | Medium | Validate large PDFs, memory use, text selection, and resume behavior. |
| Accessibility | Needs work | High | Reader controls have stronger semantics; run full TalkBack, large text, contrast, focus order, and reduced motion pass on device. |
| Crash resilience | Needs work | High | Add tests for corrupt files, missing files, restore failures, and large libraries. |

## Internal Testing Checklist

- Fresh install launches onboarding.
- Skip onboarding opens an empty library.
- Import one valid EPUB.
- Import one valid PDF.
- Try importing a corrupt EPUB and verify clear failure.
- Try importing the same book twice and verify duplicate handling.
- Open EPUB, change reader settings, close, reopen.
- Open PDF, navigate pages, close, reopen.
- Add bookmark and verify it appears in annotations.
- Select EPUB text, create a highlight, add a note, and export highlights.
- Export backup.
- Import backup on the same device.
- Import backup after deleting/moving book files and verify metadata-only warning.
- Enable TalkBack and navigate onboarding, library, settings, reader controls.
- Test system font scaling at large sizes.
- Test dark mode and high contrast settings.
- Build signed release candidate and install it on a physical Android device.
- Fill out `docs/manual-qa-checklist.md` for each release candidate device.
