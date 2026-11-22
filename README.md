# Textara

A premium, DRM-free EPUB and PDF reader built with Flutter. Beautiful, accessible, and fully offline — **completely free**, with no accounts, ads, or paywalls.

## Store listing

**Textara: Your Books, Beautifully Read**

Textara is a thoughtfully crafted reading app for your DRM-free EPUB and PDF library. No accounts, no ads, no internet required.

Import your books and enjoy a premium reading experience with deep customisation: choose from 8 handcrafted themes, adjust typography to your preference, and read comfortably with accessibility modes designed for every reader.

Highlight passages, write notes, and weave Idea Threads across books. Export annotations to Markdown or PDF. Keep your library organised with collections, tags, favourites, and powerful search.

Your books stay on your device. Your data belongs to you.

**Key features:**
- Read DRM-free EPUB and PDF files
- 8 reading themes including OLED black and sepia
- Full typography controls: font, size, spacing, alignment
- Highlights with colour choices and attached notes
- Idea Threads with local insights (no cloud AI)
- Text-to-speech for EPUB
- Export annotations to Markdown and PDF
- Accessibility first: dyslexia-friendly, reduced motion, high contrast, low stimulation
- Fully offline, no account required
- Backup and restore (optional passphrase encryption)

Built with care in Great Britain.

Store submission checklist: [docs/release/store-readiness.md](docs/release/store-readiness.md). Privacy claims: [docs/release/privacy-and-data.md](docs/release/privacy-and-data.md).

## Setup

### Prerequisites

- Flutter SDK (stable channel, 3.11+)
- Dart SDK 3.11+
- Xcode (for iOS) or Android Studio (for Android)

### Steps

```bash
cd textara
flutter pub get
flutter run
flutter test
./tool/check.sh   # format + analyze + unit/widget/a11y + knowledge-loop smoke
```

Release builds:

```bash
# Android (set TEXTARA_UPLOAD_* for Play signing — see docs/release/release-signing.md)
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

# iOS
flutter build ipa --release
```

Regenerate launcher / splash masters:

```bash
python3 tool/generate_brand_assets.py
# optional:
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Architecture

```
lib/
  core/                     # Constants, theme tokens, local error log
  domain/                   # Entities, repository interfaces, local services
  data/                     # SQLite DAOs, repositories, import/export/security
  presentation/             # Riverpod providers, screens, widgets
```

See [PLAN.md](PLAN.md) for the free premium-quality roadmap (Milestones 1–8). Schema notes: [docs/architecture/schema.md](docs/architecture/schema.md).

| Decision | Choice | Rationale |
|---|---|---|
| **State management** | Riverpod | Type-safe, testable |
| **Database** | sqflite (SQLite) | Mature, offline, FTS-friendly |
| **EPUB parsing** | epub_pro | Metadata + content + covers |
| **PDF rendering** | pdfrx | Hardware-accelerated |
| **EPUB rendering** | PageView + SelectableText | Typography / a11y control without WebView |
| **Theming** | AppTheme + Material 3 | 8 themes + a11y overlays |
| **Export** | pdf + Markdown | Offline annotation portability |

## Features

### Library
- Grid / list, sort, favourites, tags, collections, reading status
- Search across metadata and EPUB full text
- Import via picker, share intents, or document open

### Reader
- EPUB pagination with typography controls and chapter cache
- PDF viewer with selection
- Bookmarks, TOC, throttled progress, TTS

### Annotations & Idea Threads
- Highlights (8 colours) with notes
- Cross-book Idea Threads, reorder, local insight chips
- Export to Markdown and PDF

### Themes and accessibility
- Porcelain, Parchment, Dusk, Midnight, Sage, Rosewood, Ocean, Ember
- Reduced motion, high contrast, OpenDyslexic, low stimulation
- Semantics / large-text coverage gated in CI

### Data & trust
- JSON backup / restore (optional encryption)
- No accounts, no required network, no default trackers
- Local diagnostics export only

## Testing

```bash
flutter test
flutter test test/unit/
flutter test test/widget/
flutter test test/a11y/
flutter test integration_test/knowledge_loop_smoke_test.dart -d flutter-tester
```

CI runs format, analyze, tests, and the knowledge-loop smoke on every PR (`.github/workflows/flutter-ci.yml`).

## Roadmap

Milestones 1–8 in [PLAN.md](PLAN.md) define the free product: architecture spine, reader quality, design system, Idea Threads, productivity (TTS / share / stats), offline security, a11y quality gates, and store readiness.

**Non-goals forever for this plan:** subscriptions, freemium gates, mandatory cloud sync, ads, or Pro upsell UI.
