# Textara Manual QA Checklist

Run this checklist on at least one low-end Android phone, one modern Android phone, and one tablet before Play Store release.

## Device Matrix

| Device | Android Version | Screen | Result | Notes |
| --- | --- | --- | --- | --- |
| Low-end phone | TBD | Small | Not run | Required |
| Modern phone | TBD | Medium | Not run | Required |
| Tablet | TBD | Large | Not run | Required |

## Install And Launch

- Install the release app bundle through Play internal testing or bundletool.
- Launch cold after force stop.
- Relaunch after device rotation.
- Relaunch after process death.
- Confirm first-run onboarding appears once.
- Confirm no unexpected permission prompts appear.

## EPUB Reading

- Import a valid DRM-free EPUB.
- Open the EPUB and page forward/backward.
- Change font size, line height, margins, alignment, and theme.
- Confirm pagination updates without losing the current chapter.
- Jump through table of contents.
- Select text and create a highlight.
- Add, edit, and clear a note on that highlight.
- Close and reopen the book; confirm progress persists.
- Try a very large EPUB and record load time/memory behavior.

## PDF Reading

- Import a valid PDF.
- Open the PDF and page forward/backward.
- Rotate the device.
- Reopen and confirm progress persists.
- Try a large scanned PDF and record performance.

## Import And Restore

- Import one EPUB and one PDF.
- Attempt to import a corrupt EPUB.
- Attempt to import a corrupt PDF.
- Attempt to import duplicate files.
- Export a backup.
- Restore the backup on the same device.
- Restore the backup after deleting/moving book files and verify metadata-only warning.
- Export highlights to Markdown, PDF, and JSON.

## Accessibility

- Enable TalkBack.
- Navigate onboarding from start to finish.
- Import a book using TalkBack.
- Open reader controls using TalkBack.
- Confirm reader progress is announced.
- Confirm Contents and Notes controls are reachable.
- Confirm settings switches announce state changes.
- Set Android display size and font size to largest.
- Confirm library, settings, reader controls, bottom sheets, and error states remain usable.
- Enable high contrast, low stimulation, dyslexia-friendly mode, and reduced motion.

## Play Store Smoke

- Build a signed release bundle with `android/key.properties`.
- Upload to Play internal testing.
- Install from Play internal testing.
- Confirm app label, icon, splash, version, and package name.
- Confirm Data Safety answers match `docs/privacy-policy.md`.
- Confirm privacy policy URL is live before production rollout.
