# Textara

Textara is a private reading app for DRM-free EPUB and PDF books. It is built with Flutter, it runs entirely on the device, and it is free: there is no account, no ad, no subscription, and no copy of your library on a Textara server.

The point of the app is not only to turn pages. You import a book you already own, read it with the typography and accessibility settings that suit you, keep the passages that matter, and gather those passages into Idea Threads you can export. The book, the notes, and the threads stay in the app’s documents folder.

## What you can do

**Bring books in.** Pick EPUB or PDF files from the library, open them from the Files app or another app’s share sheet, or drop them onto the macOS window (and onto the iPad window while Textara is open). Onboarding can also install a short sample EPUB so the first launch is not an empty shelf. Imports are checked for size, extension, and file signature before they are copied into the library. If a book looks like one you already have, Textara asks whether to skip it, replace it, or keep both.

**Find a book or a passage.** The library is a grid or a list. You can sort it, mark favourites, and filter by reading status, format, or collection. Search looks at titles, authors, tags, and the text indexed from EPUBs, and a passage result opens that chapter.

**Read.** EPUB chapters are drawn with Flutter text, not a web view, so type size, line height, margins, alignment, and font are under your control. PDF uses a hardware-accelerated viewer. Progress is saved as you move, without writing to the database on every swipe, and reopening a book returns to that place. The reader can show the table of contents, bookmarks, and notes. On a tablet, the shelf stays beside the open book. On a phone, the book fills the screen.

**Listen.** EPUB chapters can be read aloud with the device’s own text-to-speech voices. There is no cloud voice and no account.

**Keep what you noticed.** A highlight has one of eight colours and an optional note. You can drop it into an existing Idea Thread or start a new one. Deleting a highlight can be undone. Long-pressing a word explains that an offline definition is not available yet; Textara does not send the word anywhere to look it up.

**Think across books.** Idea Threads are the part of Textara that is not just a reader. A thread is a private question or theme. Each piece of evidence is a highlight, with the book it came from and an optional reflection on why it belongs. You can reorder evidence, filter it by book, and write a synthesis note. On a tablet the list of threads stays beside the one you are working in. Local suggestions can point at a thread that has no evidence yet, a note that is not in any thread, or a word that keeps showing up. Every suggestion says why it appeared, and you can turn the whole feature off in Settings. Nothing about this is a network model.

**Leave with your work.** Annotations and threads export to Markdown or PDF. The whole library — books’ metadata, highlights, bookmarks, collections, and threads — exports as a JSON backup, with an optional passphrase so the file is encrypted on disk. Restore is all-or-nothing. Diagnostics can be exported as a log you review yourself; that log does not include book titles or chapter text, and Textara never uploads it.

**Make reading comfortable.** Eight themes ship with the app: Porcelain, Parchment, Dusk, Midnight, Sage, Rosewood, Ocean, and Ember. Settings also has reduced motion, high contrast, a bundled OpenDyslexic face, and a low-stimulation mode that mutes accents and turns off decorative motion and haptics. The other reading fonts (Literata, Merriweather, Lora, Source Serif, Inter, Roboto, Open Sans, and Atkinson Hyperlegible) are in the app as well, so typography does not depend on a font download.

**See that you have been reading.** Settings shows local reading time, books finished, and highlight counts, from sessions stored in SQLite. A daily reading reminder exists, is off until you turn it on, and is scheduled on the device. It is not a push from a server.

## How the app is organised

The first launch is a short onboarding screen. After that, a shell with three destinations is home:

| Destination | What it is |
|---|---|
| Library | Shelf, search, filters, collections, and import. On a tablet, the open book sits in a second pane. |
| Threads | Idea Threads. On a tablet, the selected thread sits beside the list. |
| Settings | Theme, accessibility, local suggestions, reading stats, the optional reminder, backup, and diagnostics. |

A link of the form `textara://book/<id>` opens a book that is already in the library. The id is the local book id, not an account id.

## What Textara will not do

Textara does not remove DRM, and it will not import a book that fails the file checks. It does not offer accounts, sync to a vendor cloud, social features, ads, or a paid tier. Optional cloud sync is not part of this product. The roadmap in [PLAN.md](PLAN.md) says the same thing.

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

The interface renders state and sends commands. Repositories exist where a workflow crosses the database and the filesystem (the library, and backup). Simple record updates still go through the DAO that owns that table.

```
lib/
  core/                     # Constants, layout breakpoint, theme tokens, local error log
  domain/                   # Entities, repository interfaces, local services
  data/                     # SQLite DAOs, repositories, import/export/security
  presentation/             # Riverpod providers, screens, widgets
```

| Decision | Choice | Rationale |
|---|---|---|
| **State management** | Riverpod | Type-safe, testable |
| **Database** | sqflite (SQLite) | Mature, offline, local to the device |
| **EPUB parsing** | epub_pro | Metadata, content, and covers |
| **PDF rendering** | pdfrx | Hardware-accelerated |
| **EPUB rendering** | PageView + SelectableText | Typography and accessibility without a web view |
| **Theming** | AppTheme + Material 3 | 8 themes plus accessibility overlays |
| **Fonts** | Bundled under `assets/fonts/` | Reading works with no network. Licences are in `assets/fonts/licenses/` |
| **Export** | pdf + Markdown | Offline annotation portability |
| **Navigation** | App shell + imperative reader routes | Library, Threads, and Settings are the destinations. `textara://book/<id>` and shared files arrive on a platform channel |

Schema notes: [docs/architecture/schema.md](docs/architecture/schema.md). The free-product roadmap, including what was deliberately not built: [PLAN.md](PLAN.md).

## Testing

```bash
flutter test
flutter test test/unit/
flutter test test/widget/
flutter test test/a11y/
flutter test integration_test/knowledge_loop_smoke_test.dart -d flutter-tester
```

CI runs format, analyze, tests, and the knowledge-loop smoke on every pull request (`.github/workflows/flutter-ci.yml`).

## Roadmap

[PLAN.md](PLAN.md) is the source of truth. Milestones 1–8 — architecture, the reader, the design system, Idea Threads, text-to-speech and sharing, offline security, accessibility gates, and store-readiness docs — are in the tree.

What is still a human step before a store upload: screenshots, the Play and App Store listings, and a signed release build. See [docs/release/store-readiness.md](docs/release/store-readiness.md) and [docs/release/release-signing.md](docs/release/release-signing.md).

**Not part of this product:** subscriptions, freemium gates, a mandatory cloud, ads, or a Pro upsell.
