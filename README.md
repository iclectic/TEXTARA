# Textara

A premium, DRM-free EPUB and PDF reader built with Flutter. Beautiful, accessible, and fully offline.

## Setup Instructions

### Prerequisites

- Flutter SDK (stable channel, 3.11+)
- Dart SDK 3.11+
- Xcode (for iOS) or Android Studio (for Android)

### Step-by-step Setup

1. **Clone and enter the project**
   ```bash
   cd textara
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run on a device or simulator**
   ```bash
   flutter run
   ```

4. **Run tests**
   ```bash
   flutter test
   ```

5. **Build for release**
   ```bash
   # Android
   flutter build apk --release

   # iOS
   flutter build ios --release
   ```

## Project Architecture

Textara follows a clean layered architecture:

```
lib/
  core/                     # Shared constants, theme, utilities
    constants/              # App-wide constants and enums
    theme/                  # Theme system (8 built-in themes)
  domain/                   # Business logic layer
    entities/               # Pure Dart models (Book, Highlight, Bookmark, etc.)
    repositories/           # Repository interfaces (contracts)
  data/                     # Data layer implementation
    database/               # SQLite via sqflite (DAOs for books, annotations, collections)
    services/               # File storage, EPUB parsing, import/export
  presentation/             # UI layer
    providers/              # Riverpod state management
    screens/                # Full-page screens (library, reader, settings, onboarding)
    widgets/                # Reusable UI components
```

### Key Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| **State management** | Riverpod | Type-safe, testable, no BuildContext dependency for providers |
| **Database** | sqflite (SQLite) | No code generation needed, mature, excellent mobile support, handles 5000+ books |
| **EPUB parsing** | epubx | Pure Dart, no platform channels, parses metadata + content + covers |
| **PDF rendering** | pdfrx | Hardware-accelerated, supports text selection, smooth scrolling |
| **EPUB rendering** | Custom PageView + SelectableText | Full control over typography, themes, and accessibility; avoids WebView overhead |
| **Theming** | Custom AppTheme entity + Material 3 | 8 handcrafted themes including OLED black, sepia, high contrast |
| **Search** | SQLite LIKE queries + FTS table | Full-text EPUB content indexed at import time, metadata search for library |
| **Export** | pdf package + raw Markdown | Highlights export to both .md and .pdf with no network dependency |

### EPUB Rendering Tradeoffs

We render EPUB content using Flutter-native widgets (PageView + SelectableText) rather than a WebView approach:

- **Advantages**: Full theme control, native text selection, accessibility support, no WebView overhead, consistent behaviour across platforms, deep integration with reader settings
- **Tradeoffs**: Complex CSS in EPUBs (tables, SVG, complex layouts) may not render perfectly. For the vast majority of prose-heavy books, this approach is superior in performance and UX.

## Features

### Library
- Grid and list view toggle
- Sort by title, author, date added, recently opened, progress
- Search across title, author, tags, and EPUB full text
- Favourites, tags, collections, reading status tracking
- Import via file picker (EPUB and PDF)

### Reader
- EPUB: paginated chapter view with full typography controls
- PDF: hardware-accelerated viewer with text selection
- Font family selection (8 fonts including Atkinson Hyperlegible)
- Font size, line height, margin, alignment, and hyphenation controls
- Bookmarks, table of contents, reading progress with time estimates

### Annotations
- Highlights with 8 colour choices
- Notes attached to highlights
- View all highlights and notes per book
- Export to Markdown and PDF

### Themes and Accessibility
- 8 built-in themes: Porcelain, Parchment, Dusk, Midnight, Sage, Rosewood, Ocean, Ember
- Reduced motion mode
- High contrast mode
- Dyslexia-friendly mode (font + spacing)
- Low stimulation mode (muted colours, no animations)
- Full accessibility labels on all controls
- Respects system text scaling

### Data
- Export/import full backup as JSON (books, highlights, bookmarks, collections)
- Validates imported data carefully
- No account required, no network dependency

## Testing

```bash
# Run all tests
flutter test

# Run unit tests only
flutter test test/unit/

# Run widget tests only
flutter test test/widget/
```

### Test Coverage

- **Unit tests**: Book entity serialisation, reading progress persistence, highlight/note creation and export formatting, backup validation and failure cases, reader settings serialisation
- **Widget tests**: Library empty state, book grid/list tiles, theme switching updates reader, favourite toggling

## Phased Roadmap

### MVP v1.0 (Current)
- EPUB and PDF import and reading
- Library with grid/list, search, sort, favourites
- Reader with typography controls and 8 themes
- Bookmarks, highlights, notes
- Export highlights to Markdown and PDF
- Backup/restore library data
- Onboarding flow
- Accessibility modes (reduced motion, high contrast, dyslexia, low stimulation)

### v1.5
- Text-to-speech for EPUB (play, pause, speed, voice selection)
- Dictionary lookup (long-press to define, offline where possible)
- Drag-and-drop import on tablets
- Share-to-Textara import flow
- Collections management UI
- Metadata editing (title, author, cover)
- Theme pack customisation (accent colour, background texture, highlight palette)

### v2.0
- Optional cloud sync (Pro tier architecture already prepared)
- Cross-device reading progress sync
- Advanced export formats (Notion, Readwise)
- Reading statistics and insights
- Widget for home screen (currently reading)
- Tablet-optimised two-pane layout

## Store Listing Draft

**Textara: Your Books, Beautifully Read**

Textara is a thoughtfully crafted reading app for your DRM-free EPUB and PDF library. No accounts, no ads, no internet required.

Import your books and enjoy a premium reading experience with deep customisation: choose from 8 handcrafted themes, adjust typography to your preference, and read comfortably with accessibility modes designed for every reader.

Highlight passages, write notes, and export your annotations to Markdown or PDF. Keep your entire library organised with collections, tags, favourites, and powerful search.

Your books stay on your device. Your data belongs to you.

**Key features:**
- Read DRM-free EPUB and PDF files
- 8 beautiful reading themes including OLED black and sepia
- Full typography controls: font, size, spacing, alignment
- Highlights with colour choices and attached notes
- Export annotations to Markdown and PDF
- Accessibility first: dyslexia-friendly, reduced motion, high contrast, low stimulation modes
- Fully offline, no account required
- Backup and restore your entire library

Built with care in Great Britain.
