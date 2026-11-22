# Textara Upgrade Plan

**Goal:** Take Textara from a capable offline MVP to a world-class, premium-feeling EPUB/PDF reader that stays **completely free** — no accounts, no ads, no paywalls, no subscription scaffolding.

**Product north star:** Private ownership of books and knowledge. Compete on reading comfort, trust, accessibility, and Idea Threads — not on monetization or cloud lock-in.

**Related prior art:** An earlier engineering plan lives at `docs/plans/2026-07-21-001-feat-premium-reader-platform-plan.md`. This document supersedes it as the living root roadmap: it is grounded in the current tree, expands quality/release topics, and explicitly excludes monetization and paid sync tiers mentioned in `README.md`.

---

## 0. Current State Inventory

### Stack (`pubspec.yaml`)

| Area | Package / choice | Notes |
|---|---|---|
| SDK | Dart `^3.11.0`, Flutter | Stable baseline |
| State | `flutter_riverpod` ^2.6.1 | All providers live in one file |
| DB | `sqflite` + `sqlite3_flutter_libs` | Schema version **2** in `DatabaseHelper` |
| EPUB | `epub_pro` ^5.6.0 + `html` | Flutter-native rendering (not WebView) |
| PDF | `pdfrx` ^1.0.92 | Hardware-accelerated viewer |
| Theme fonts | `google_fonts` ^6.2.1 | `LeafTheme` defaults to Inter |
| Prefs | `shared_preferences` | Theme, a11y flags, first-run, library view |
| TTS | `flutter_tts` ^4.2.0 | **Declared but unused in `lib/`** |
| UI extras | `shimmer`, `permission_handler` | **Declared but unused in `lib/`** |
| Export | `pdf` package | Markdown + PDF highlight/thread export |
| Test | `flutter_test`, `flutter_lints` ^6.0.0, `mocktail` | No integration_test package yet |

### Layout that actually exists

```
lib/
  main.dart                          # ProviderScope + first-run gate → Onboarding | Library
  core/constants/                    # AppConstants, enums (incl. unused TtsState)
  core/theme/leaf_theme.dart         # Material 3 from AppTheme
  domain/entities/                   # Book, Highlight, Bookmark, Collection, IdeaThread,
                                     # ReaderSettings, AppTheme, BackupData, SearchResult, EpubContent
  data/database/                     # DatabaseHelper, BookDao, AnnotationDao,
                                     # CollectionDao, IdeaThreadDao
  data/services/                     # ImportService, ExportService, EpubParserService,
                                     # FileStorageService, ImportSecurityPolicy
  presentation/providers/            # app_providers.dart (monolith)
  presentation/screens/              # library, reader, settings, onboarding, threads
  presentation/widgets/              # library/* and reader/*
test/unit/                           # entity + backup + import security tests
test/widget/                         # library_screen_test, theme_test
```

**Claimed but missing:** `README.md` lists `domain/repositories/`. That folder does not exist. Screens call DAOs/services through Riverpod providers directly.

### Screens and navigation

| Screen | File | How reached |
|---|---|---|
| Onboarding | `lib/presentation/screens/onboarding/onboarding_screen.dart` | `main.dart` when `prefKeyFirstRun` |
| Library | `lib/presentation/screens/library/library_screen.dart` | App home; hub for everything else |
| Reader | `lib/presentation/screens/reader/reader_screen.dart` (+ `epub_reader_view.dart`, `pdf_reader_view.dart`) | `Navigator.push` from library |
| Idea Threads | `lib/presentation/screens/threads/idea_threads_screen.dart` (+ detail in same file) | App bar icon from library |
| Settings | `lib/presentation/screens/settings/settings_screen.dart` | App bar icon from library |

Navigation is imperative `MaterialPageRoute` only — **no** `go_router` / named routes / deep links. Tablet detection exists (`shortestSide >= 600`) but there is no two-pane layout.

### Features that work today

- Import EPUB/PDF via `file_picker` with `ImportSecurityPolicy` (size, extension, magic-byte checks)
- Library grid/list, favourites, sort, in-memory title/author/tag filter
- EPUB chapter `PageView` + `SelectableText` highlights; PDF via `pdfrx`
- Reader typography sheet; 8 themes in `BuiltInThemes` (Porcelain → Ember)
- Accessibility toggles: reduced motion, high contrast, dyslexia, low stimulation (persistence yes; **visual application incomplete** outside dyslexia font + reduced page transitions)
- Annotations list + Markdown/PDF export; Idea Threads with evidence + thread Markdown export
- JSON backup/restore via `ExportService` / `BackupData`
- SQLite indexes + `full_text_search` table populated at EPUB import; `BookDao.searchLibrary` / `fullTextSearch` exist

### Gaps vs README / code claims

1. Library UI search (`filteredBooksProvider`) does **not** call `BookDao.searchLibrary` — full-text excerpts are unused in the UI.
2. `ReaderSettingsNotifier` never persists to `AppConstants.prefKeyReaderDefaults`.
3. `CollectionDao` + `collectionsProvider` exist; **no Collections screen or library filter UI**.
4. Onboarding “import sample” is a **simulated** `Future.delayed` — `assets/sample/` is empty (`.gitkeep` only).
5. Progress writes fire on every page change from `ReaderScreen._onPageChanged` with no throttle.
6. Highlight colour picker / note editor at creation time are missing (defaults to yellow, no note prompt).
7. No CI (`.github/` absent), no `integration_test/`, limited widget coverage.
8. Android release still uses **debug signing** (`android/app/build.gradle.kts`).
9. No crash reporting, analytics, notifications, share-intent import, or TTS wiring despite deps/enums.
10. README v2.0 still mentions “Optional cloud sync (Pro tier)” — **out of scope forever for this free product plan**.

---

## Guiding Principles

1. **Evolve, don’t rewrite.** Keep Riverpod, sqflite, `epub_pro`, `pdfrx`, Flutter-native EPUB UI, and local-first identity.
2. **Presentation renders state and issues commands.** Stop growing `LibraryScreen` / `ReaderScreen` / `IdeaThreadsScreen` as service orchestrators.
3. **Offline is a feature.** Any network dependency (fonts at runtime, analytics, crash reporting) must be opt-in, documented, and fail closed offline.
4. **Free forever.** No IAP, paywalls, freemium gates, “Pro” naming, or account systems. Cloud sync stays out unless a future *optional, free, user-hosted* sync is separately designed.
5. **Measure premium.** Reader jank, import latency, search latency, backup integrity, and a11y guidelines are release gates — not vibes.

---

## Milestone 1 — Architecture Spine & Reliability Foundation

**Outcome:** Clear boundaries, safe schema evolution, typed errors, and a CI spine so later polish does not rot the core.

### 1.1 Split the provider monolith

**Today:** Everything is in `lib/presentation/providers/app_providers.dart` (~390 lines): DAOs, services, theme, a11y, library filters, books notifier, reader settings, import progress, threads.

**Tasks:**

- Split into feature files under `lib/presentation/providers/` (or `view_models/`):
  - `database_providers.dart`, `library_providers.dart`, `reader_providers.dart`, `settings_providers.dart`, `threads_providers.dart`, `import_providers.dart`
- Introduce thin **feature notifiers / view models** for Library, Reader, Import, and Threads that expose UI state (`loading | data | error`) and commands (`import`, `toggleFavourite`, `saveProgress`, `createHighlight`).
- Add repository interfaces only where workflows cross DAO + files + index (start with `LibraryRepository` and `BackupRepository`). Place contracts in `lib/domain/repositories/` and implementations in `lib/data/repositories/` so README matches reality.
- Keep single-DAO CRUD callable via existing `*DaoProvider`s where wrapping adds no value.
- Add characterization tests around `BooksNotifier` / `filteredBooksProvider` before moving logic.

### 1.2 Persistence, migrations, and data model hygiene

**Today:** `DatabaseHelper` is at version 2; upgrade only adds Idea Thread tables. Tags and `collection_ids` are comma-joined strings on `books` while a proper `book_collections` join table also exists — dual models invite drift.

**Tasks:**

- Document the current schema (tables: `books`, `highlights`, `bookmarks`, `collections`, `book_collections`, `full_text_search`, `idea_threads`, `thread_highlights`) in `docs/architecture/schema.md`.
- Add migration tests: fresh `_onCreate` at latest version ≡ upgraded path from v1/v2 fixtures (`test/unit/database/`).
- Prefer transactional migrations; never leave partial Idea Thread / FTS state.
- Normalize tags into a join table (or keep denormalized but single-source) and stop writing unused `collection_ids` CSV if `book_collections` is canonical.
- Evaluate upgrading `full_text_search` from `LIKE` on a plain table to SQLite **FTS4/FTS5** with a rebuild path; keep `BookDao.searchLibrary` ranking API stable (`SearchResult` already models metadata vs full-text).
- Make backup restore all-or-nothing (today `ExportService.importBackup` inserts in a loop without a wrapping transaction).

### 1.3 Error model and resilience

**Tasks:**

- Define a small sealed/`Equatable` failure type (e.g. `AppFailure`) for import, open-book, backup, export, and DB errors — map exceptions at repository/service boundaries.
- Replace silent catches (e.g. EPUB parse failure swallowed in `ImportService.importFile`, FTS indexing `catch (_) {}`) with structured results that the UI can show and that still clean temp files via `FileStorageService`.
- Add global Flutter error hooks in `main.dart` (zone + `FlutterError.onError`) that log locally; wire remote crash reporting later in Milestone 6 as **opt-in**.
- Ensure missing book files in reader show the existing recoverable UI (`EpubReaderView` / `PdfReaderView` error states) and never write bogus progress.

### 1.4 CI / analysis baseline

**Today:** No `.github/workflows`. `analysis_options.yaml` is stock `flutter_lints` with no extra rules.

**Tasks:**

- Add `.github/workflows/flutter-ci.yml`: `flutter pub get`, `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test`.
- Tighten `analysis_options.yaml` (prefer single quotes, avoid print, unawaited futures, require trailing commas as team prefers).
- Fix `test/widget_test.dart` so it is stable against async SharedPreferences / first-run (mock prefs or pump until settle with timeouts).
- Add a `Makefile` or `tool/check.sh` mirroring CI for local use; update `README.md` Testing section.

**Exit criteria:** CI green on PR; providers split; migration + backup transaction tests; no silent partial imports leaving orphan files under `books/` / `covers/`.

---

## Milestone 2 — Reader Core, Search, and Import Quality

**Outcome:** The daily reading loop feels trustworthy and fast.

### 2.1 Reader location and progress

**Today:** Progress is chapter index / page int; `_onPageChanged` persists immediately via `BookDao.updateReadingProgress`.

**Tasks:**

- Introduce `ReaderLocation` (chapter id + offset or PDF page) in `domain/entities/`.
- Throttle/debounce progress writes (coalesce rapid swipes); flush on dispose / app lifecycle pause (`WidgetsBindingObserver` in `ReaderScreen` or a reader view model).
- Preserve nearest location when font size / margin changes in `EpubReaderView`.
- Cache parsed chapter text so reopening settings sheets does not re-parse the whole EPUB every rebuild path that triggers `_loadEpub`.
- Align “page” semantics: EPUB currently treats chapter index as page — surface honest UI copy (“Chapter X of Y”) in `ReaderBottomBar` / `ReaderAppBar`.

### 2.2 Annotations UX

**Today:** Context menu “Highlight” in `EpubReaderView` saves yellow with offsets; no colour/note sheet at create time. PDF selection path needs parity audit in `pdf_reader_view.dart`.

**Tasks:**

- Add `annotation_editor_sheet.dart`: colour (`HighlightColour` enum already has 8 values), optional note, “Add to Idea Thread”.
- Render highlight marks in-chapter (background spans) using stored offsets; handle offset drift gracefully.
- Bookmark create/jump from TOC + bottom bar with clear labels.
- Undo snackbar after highlight delete.

### 2.3 Wire real library search

**Tasks:**

- Replace / extend `filteredBooksProvider` so queries use `BookDao.searchLibrary` (already returns ranked `SearchResult` with excerpts).
- Build a search results UI: metadata hits vs passage hits with excerpt; tap opens reader at chapter when `chapterId` present.
- Debounce input; show empty and error states; respect `AppConstants.searchResultLimit`.
- Add DAO tests for ranking helpers already in `book_dao.dart`.

### 2.4 Import pipeline as a job

**Today:** `ImportService.pickAndImportFiles` loops files; `ImportProgressNotifier` exists but library screen does not drive it during pick/import. Onboarding sample is fake.

**Tasks:**

- Model `ImportJob` / per-file states; connect `importProgressProvider` to a visible progress banner on `LibraryScreen`.
- Cancel-friendly batching using `AppConstants.importBatchSize`.
- Ship a real sample EPUB under `assets/sample/` and make onboarding call `ImportService` (or a dedicated sample installer).
- Duplicate detection (hash or title+author+size) with user choice: skip / replace / keep both.
- Continue hardening `ImportSecurityPolicy` (zip-slip for EPUB, PDF header depth) with fixtures in `test/unit/import_security_policy_test.dart`.

### 2.5 Performance budgets

**Tasks:**

- Profile large EPUB open and 500+ book library scroll; use `RepaintBoundary` / cover image caching (`AppConstants.coverCacheSize` is unused).
- Lazy-load covers in `BookGridTile` / `BookListTile`; consider local disk cache + memory LRU.
- Optionally adopt `shimmer` (already in pubspec) for cover placeholders — or remove the unused dependency.
- Document budgets in `docs/release/performance.md` (e.g. library first paint, chapter turn, import of 10MB EPUB).

**Exit criteria:** Reopen restores location; search shows passages; import shows progress and real sample; progress writes coalesced; performance notes with measured numbers on a mid-tier device.

---

## Milestone 3 — Design System, UI/UX Polish, and Motion

**Outcome:** The app feels intentional and premium without becoming a dashboard of chrome.

### 3.1 Design tokens

**Today:** `LeafTheme.fromAppTheme` builds Material 3 from `AppTheme`; library/reader widgets hard-code spacings and radii.

**Tasks:**

- Extract tokens: spacing, radius, elevation, duration (`AppConstants.animationFast/Normal/Slow` already exist — use them consistently), typography roles beyond Inter-everywhere.
- Reader chrome (`ReaderAppBar`, `ReaderBottomBar`) should feel editorial: calm, low contrast chrome that disappears (`_showControls` already toggles — polish animation with `reducedMotionProvider`).
- Ensure brand “Textara” is visible in onboarding and empty states (`LibraryEmptyState`, onboarding) without cluttering the reader.

### 3.2 Navigation IA

**Tasks:**

- Introduce a root shell with clear destinations: **Library**, **Threads**, **Settings** (NavigationBar / Rail on tablet) instead of only AppBar icon stacking on `LibraryScreen`.
- Prefer `go_router` (or equivalent) for typed routes, deep links (`textara://book/<id>`), and share-target landing — keep offline-first.
- Tablet: two-pane library + reader / threads list + detail when `shortestSide >= 600`.

### 3.3 Motion (respectful)

**Tasks:**

- 2–3 intentional motions: library item appear, reader chrome fade, thread evidence add — all gated by `reducedMotionProvider` and system reduce-motion.
- Remove or replace default Material noise; keep haptic usage (`HapticFeedback`) consistent and optional under low stimulation.

### 3.4 Finish accessibility modes

**Today:** Toggles persist; only dyslexia font swap and reduced page transitions clearly apply. High contrast / low stimulation barely affect `LeafTheme`.

**Tasks:**

- Map `highContrastProvider` → forced contrast palette / theme overlay.
- Map `lowStimulationProvider` → muted accents, no haptics, no decorative motion, simplified library tiles.
- Dyslexia: ensure OpenDyslexic (or bundled font asset) is available **offline** — do not rely on runtime Google Fonts download for critical a11y paths; vendor fonts under `assets/fonts/`.
- Prefer bundling primary reader fonts (Literata etc.) for offline reliability; keep `google_fonts` only where acceptable with fallbacks (already partially handled in `EpubReaderView._getReaderTextStyle`).

### 3.5 Collections and library organization UI

**Tasks:**

- Build `CollectionsScreen` on top of `CollectionDao` / `collectionsProvider`.
- Book long-press / details sheet: edit metadata (title, author, tags, status), assign collections, replace cover.
- Filters: favourites, reading status (`ReadingStatus`), collection, format (`BookFormat`).
- Reading status updates automatically from progress thresholds.

**Exit criteria:** Distinctive calm visual system; shell navigation; a11y modes visibly change UI; collections usable end-to-end.

---

## Milestone 4 — Idea Threads as the Signature Free Feature

**Outcome:** Textara’s differentiator is private knowledge work — fully free.

### 4.1 Capture from reading

**Tasks:**

- From highlight editor: add to existing thread / create thread / optional reflection (mirror states described in the older plan’s interaction contracts).
- Duplicate evidence detection via `IdeaThreadDao` primary key `(thread_id, highlight_id)`.
- Saved-with-undo; failure with retry.

### 4.2 Thread workspace

**Today:** List + detail + synthesis note + Markdown export exist in `idea_threads_screen.dart`.

**Tasks:**

- Evidence reorder (`sort_order`), reflection edit, filter by book/tag.
- Export preview (scope confirmation) before `ExportService.exportThreadToMarkdown`.
- Cross-links: open source book at highlight location.
- Empty states that teach the workflow without gimmicks.

### 4.3 Local, opt-in “intelligence” (no cloud, no paywall)

**Tasks:**

- Purely local suggestions inside a thread: recurring terms across evidence, books with orphan notes, “thread needs evidence” prompts.
- Every suggestion explains *why*; dismissible; globally disable in Settings.
- **No** network models, **No** account, **No** premium gate.

**Exit criteria:** Read → highlight → thread → export loop is delightful and tested; local suggestions optional.

---

## Milestone 5 — Productivity Features (Still Free)

**Outcome:** Daily usefulness beyond “open a book.”

### 5.1 Text-to-speech

**Tasks:**

- Wire `flutter_tts` (already in pubspec) + `TtsState` enum into a `TtsController` / provider.
- EPUB: play/pause, speed, voice picker; highlight spoken sentence if feasible.
- Respect reduced motion / low stimulation (no flashy visualizers).
- Handle `permission_handler` only if a platform requires it; otherwise remove unused dependency.

### 5.2 Dictionary / lookup

**Tasks:**

- Long-press → define via onboard word list or OS dictionary intents where available; never require an account.
- Offline-first stub with clear “definition unavailable offline” state.

### 5.3 Import convenience

**Tasks:**

- Share / Open-with intents (`ImportSource` enum already lists `shareIntent`, `openWith`, `dragDrop`).
- Android intent-filters in `AndroidManifest.xml`; iOS document types / `CFBundleDocumentTypes` in `Info.plist`.
- Drag-and-drop on iPad / macOS scaffold where practical.

### 5.4 Reading insights (local stats)

**Tasks:**

- Local statistics: minutes estimated from progress deltas, books finished, highlights count — stored in SQLite, shown in Settings or a simple Insights sheet.
- Home-screen widget (“Continue reading”) as a later stretch — Android/iOS glance surfaces, still free.

### 5.5 Export / share productivity

**Tasks:**

- Share sheet for highlight Markdown snippets; export all notes; OPML/CSV optional later.
- Keep `ExportFormat` enum (`markdown`, `pdf`, `json`) as the contract.

### 5.6 Notifications (careful, local-only)

**Tasks:**

- Optional local reading reminders (`flutter_local_notifications` or equivalent) — user-scheduled, no server push.
- Defaults **off**; clear copy in Settings; no engagement dark patterns.
- Do not add marketing notifications.

**Exit criteria:** TTS usable on EPUB; share-to-import works on Android+iOS; local reminders optional; stats accurate offline.

---

## Milestone 6 — Offline Hardening, Persistence, Security, Privacy Telemetry

**Outcome:** Trustworthy offline product with honest privacy.

### 6.1 Offline & fonts

**Tasks:**

- Audit runtime network: `google_fonts` fetching — bundle critical fonts; document any residual network in `docs/release/privacy-and-data.md`.
- Ensure open/import/search/backup/export work in airplane mode (integration smoke).

### 6.2 Persistence completeness

**Tasks:**

- Persist `ReaderSettings` to `prefKeyReaderDefaults` (load in notifier constructor).
- Persist library sort field/order (today only view mode is persisted).
- Encrypted backup option (user passphrase, local AES) as optional free enhancement — never cloud-uploaded by us.

### 6.3 Security

**Tasks:**

- Continue treating EPUB/PDF/backup as untrusted (`ImportSecurityPolicy`); add zip-slip and entity-expansion tests.
- Path confinement: all writes under app documents (`FileStorageService` books/covers/exports).
- Android: decide `android:allowBackup` / backup rules; iOS: file protection attributes where applicable.
- Release builds: obfuscation (`--obfuscate`) + split debug info; remove debug signing from release (`android/app/build.gradle.kts`).
- Sanitize Markdown/PDF export fields (already partially needed for thread export).

### 6.4 Analytics & crash reporting (privacy-first)

**Tasks:**

- Default **off**. If added, use privacy-respecting options (e.g. self-hosted or offline log export) with explicit Settings opt-in.
- Never attach book titles/contents to crash reports without opt-in redaction policy.
- Document Data Safety / App Privacy answers: no account, no tracking by default, local files only.
- Prefer local diagnostics export (“Send feedback” attaches a user-reviewed log) over always-on SaaS analytics.

**Exit criteria:** Airplane-mode certification; reader settings persist; release signing story documented; privacy doc matches code.

---

## Milestone 7 — Accessibility, Testing Strategy, and Quality Gates

### 7.1 Accessibility

**Tasks:**

- Semantics audit on icon-only controls (library AppBar already has tooltips — ensure `Semantics` / screen-reader labels everywhere, following patterns in `book_grid_tile.dart` / `book_list_tile.dart`).
- Tap target ≥ 48dp; large text scale tests for reader settings sheet and library.
- Contrast checks for all 8 `BuiltInThemes` (golden or automated guidelines).
- Add `test/a11y/accessibility_guidelines_test.dart` using Flutter’s accessibility guidelines matcher.

### 7.2 Testing pyramid

| Layer | Location | Expand to cover |
|---|---|---|
| Unit | `test/unit/` | DAOs (sqflite `ffi`), repositories, import/export, migrations, view models |
| Widget | `test/widget/` | Reader chrome, settings, threads, search, import progress |
| Golden | `test/golden/` | Themes + reader typography |
| Integration | `integration_test/` | Import → read → highlight → thread → export → backup restore |
| A11y | `test/a11y/` | Library, reader, settings, threads |

**Tasks:**

- Add `sqflite_common_ffi` (or equivalent) for DB tests in CI.
- Keep `mocktail` for repository fakes.
- CI job matrix: analyze + unit/widget; scheduled/manual integration on API level emulator where feasible.

### 7.3 Error / empty / loading polish

**Tasks:**

- Consistent empty/error/retry widgets; `filteredBooksProvider` should not swallow errors as `[]` without surfacing `booksProvider` error UI.
- Import partial-success summary with per-file reasons.

**Exit criteria:** A11y tests gate PRs; integration smoke for the knowledge loop; error states visible.

**Done (landed):** `test/a11y/accessibility_guidelines_test.dart` (semantics, text scale, contrast across themes); shared `AppErrorView` / `AppEmptyView`; import summary dialog with per-file failure reasons; `integration_test/knowledge_loop_smoke_test.dart` on `flutter-tester` in CI; reader chrome widget tests; `tool/check.sh` + CI gate the smoke.

---

## Milestone 8 — App Store Readiness & Ship

### 8.1 Branding assets

**Tasks:**

- Replace default Flutter launcher icons (Android `mipmap-*`, iOS `AppIcon.appiconset`) with Textara brand marks.
- Proper splash / launch theme (`LaunchTheme` / `LaunchImage`) — calm branded background, not blank white.
- Consider `flutter_native_splash` + `flutter_launcher_icons` as dev tooling.

### 8.2 Platform manifests

**Tasks:**

- Android: unique applicationId already `com.textara.textara`; add document intent-filters; storage permissions only as required by target SDK; release signing via keystore from CI secrets.
- iOS: display name, document types for EPUB/PDF, encryption export compliance key (`ITSAppUsesNonExemptEncryption`), photo/file usage strings only if needed.
- macOS: keep compile-aware (`macos/` scaffold exists) but **do not** block mobile release.

### 8.3 Store listing & docs

**Tasks:**

- Promote `README.md` store draft; remove “Pro tier” / paid sync language — replace with free-product roadmap pointing at this `PLAN.md`.
- Add `docs/release/store-readiness.md` checklist and `docs/release/privacy-and-data.md`.
- Screenshots for phone + tablet; short preview video of reading + Idea Threads.
- Version strategy: keep `pubspec.yaml` `1.0.0+1` until first store build, then semver aligned with milestones (e.g. 1.1 reader quality, 1.5 TTS/threads polish, 2.0 insights — **all free**).

### 8.4 Final release gate

- [x] `flutter analyze` clean (CI: `--no-fatal-infos --fatal-warnings`)
- [x] Unit + widget + a11y green  
- [x] Integration smoke: knowledge-loop contracts on `flutter-tester`  
- [x] Airplane mode documented (`docs/release/airplane-mode.md`)  
- [x] Accessibility modes visibly applied (Settings + a11y tests)  
- [x] Privacy questionnaire matches implementation (`docs/release/privacy-and-data.md`)  
- [ ] Signed Android AAB + iOS Archive (requires store credentials; see `docs/release/release-signing.md`)

**Done (landed):** Brand launcher/splash (Android / iOS / macOS) + adaptive icons; parchment launch theme; `docs/release/store-readiness.md` + screenshot shot list; README store listing promoted with free-product messaging; `flutter_launcher_icons` / `flutter_native_splash` tooling; version stays `1.0.0+1` until first store upload.

---

## Phased Timeline View (Dependency Order)

```text
M1 Architecture + CI
        │
        ▼
M2 Reader / Search / Import ──────────────┐
        │                                 │
        ▼                                 │
M3 Design system + Navigation             │
        │                                 │
        ▼                                 │
M4 Idea Threads depth ◄───────────────────┘
        │
        ▼
M5 Productivity (TTS, share import, local reminders)
        │
        ▼
M6 Offline / Security / Opt-in diagnostics
        │
        ▼
M7 A11y + full test pyramid (overlaps M2–M6)
        │
        ▼
M8 Store ship
```

Milestones 2–4 deliver user-visible “premium” feel. 5–6 deepen usefulness and trust. 7 runs continuously. 8 is the gate, not a feature dump.

---

## Explicit Non-Goals

- No subscriptions, trials, freemium feature gates, tip jars wired as IAP, or “Pro” upsell UI.
- No mandatory accounts or vendor cloud sync.
- No ads, trackers-by-default, or engagement spam notifications.
- No DRM circumvention (already stated in Settings / README).
- No social feed, public profiles, or collaborative editing in this plan.
- No rewrite to WebView-based EPUB unless Flutter-native rendering hits a hard fidelity ceiling — revisit only with evidence.

---

## Immediate Next Actions (start here)

Milestones 1–8 of this plan are implemented in tree. Remaining human/store steps:

1. Capture phone + tablet screenshots and preview video (`docs/release/screenshots/`).
2. Configure Play / App Store Connect listings from the README store draft.
3. Build signed Android AAB + iOS Archive with release credentials (`docs/release/release-signing.md`).
4. Optional: replace onboarding sample `.gitkeep` with a redistributable DRM-free EPUB when licensing allows.

---

## Success Definition

Textara is “world-class and free” when a reader can import DRM-free books entirely offline, customize typography and accessibility deeply, annotate with confidence, build Idea Threads into portable Markdown/PDF knowledge, restore from backup safely, and install from the stores with privacy claims that match the binary — without ever hitting a paywall.
