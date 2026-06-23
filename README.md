# Textara

Textara is a DRM-free EPUB and PDF reader built with Flutter. The product goal is a calm, private, offline-first reading app for people who own their own books.

Current status: **pre-release foundation build**. The app can import and open EPUB/PDF files, stores library data locally, and builds an Android app bundle, but it is not Play Store-ready until the release checklist in `docs/play-store-readiness.md` is complete.

## Setup

### Prerequisites

- Flutter stable with Dart 3.11+
- Android Studio or command-line Android SDK for Android builds
- Xcode for iOS/macOS builds

### Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

## Architecture

```text
lib/
  core/                     Shared constants, enums, and theme mapping
  domain/entities/          Pure Dart models for books, annotations, backup data, themes
  data/database/            SQLite helper and DAOs
  data/services/            File storage, EPUB parsing, import, export, backup restore
  presentation/             Riverpod providers, screens, and reusable widgets
```

The app currently uses Riverpod providers directly over DAOs and services. A repository layer is planned but not implemented yet.

## Implemented Features

### Library

- Import DRM-free EPUB and PDF files through the file picker.
- Grid and list views.
- Sort by title, author, recently opened, date added, and progress.
- Search by title, author, and tags.
- Favourite books.
- Basic duplicate detection during import.
- Clearer import failure messages for unsupported, missing, duplicate, or unreadable files.

### Reader

- EPUB reading through Flutter-native text widgets with estimated reflow pages.
- PDF reading through `pdfrx`.
- Reader controls for progress, bookmarks, table of contents, annotations sheet, and typography settings.
- Font size, line height, margin, alignment, and hyphenation settings.
- Basic reading progress persistence.
- Table-of-contents navigation for EPUB chapters.

Important EPUB limitation: the current EPUB reader measures Flutter text against the active viewport and reader settings for pagination. It is stronger than estimated character paging, but still does not provide full EPUB CSS/layout fidelity.

### Annotations and Export

- Bookmark creation from the reader.
- Highlight creation from selected EPUB text.
- Notes attached to highlights from the annotations sheet.
- Per-book annotations sheet.
- Export stored highlights to Markdown, PDF, or JSON.

### Data and Backup

- SQLite-backed local library metadata.
- Book files and covers are copied into app documents storage.
- Backup export to JSON.
- Backup import validates duplicate IDs and orphaned highlights/bookmarks before restoring.
- Restore reports when backed-up book metadata points to files that are not present on the current device.

### Accessibility and Themes

- Material 3 theme foundation with eight built-in visual themes.
- Reduced motion removes route animations.
- High contrast and low stimulation modes alter app colours.
- Dyslexia-friendly mode swaps reader typography to the configured dyslexia font family.
- Some semantic labels and tooltips on key library/settings controls.

Important accessibility limitation: TalkBack flow, large text behavior, focus order, and full contrast QA still need a dedicated release pass.

## Current Verification Baseline

As of this phase:

- `flutter analyze` passes.
- `flutter test` passes.
- `flutter build appbundle --release` succeeds locally.

The generated Android release build still uses debug signing and is **not** suitable for Play Store upload.

## Release Readiness

Use `docs/play-store-readiness.md` before any Play Store internal test or production release.

## Product Direction

Textara should become:

> Your books, beautifully read. Offline, private, accessible, and fully yours.

Near-term priorities:

1. Release foundations: signing, icons, truthful docs, error handling, backup safety.
2. Design system: spacing, typography, polished empty/loading/error states.
3. Reader excellence: full EPUB CSS/layout fidelity, richer notes, better resume, search.
4. Accessibility: TalkBack, large text, reduced motion, high contrast, low stimulation.
5. Library organization: collections, tags UI, metadata editing, duplicate handling.

Release preparation docs:

- `docs/release-signing.md`
- `docs/privacy-policy.md`
- `docs/manual-qa-checklist.md`
- `docs/play-store-readiness.md`
