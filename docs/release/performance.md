# Performance budgets

Targets for a mid-tier phone (e.g. 2021 Android / recent iPhone SE class). Measure on physical hardware before release; values below are engineering budgets, not yet field-certified numbers.

| Scenario | Budget | Notes |
|---|---|---|
| Library first paint (≤100 books) | ≤ 300 ms to first meaningful frame after DB load | Prefer decode bounds on covers (`cacheWidth` / `cacheHeight`); `RepaintBoundary` on tiles |
| Library scroll (500+ books) | Steady 60 fps while flinging | Lazy cover decode; avoid rebuilding entire grid on favourites toggle |
| EPUB chapter turn | ≤ 100 ms to paint next chapter from cache | `EpubChapterCache` keeps parsed chapter text; avoid re-parse on TOC / settings |
| EPUB open (10 MB file) | ≤ 2 s to first chapter text | Progress restore should not block first paint |
| Batch import (10 files, ~10 MB each) | Progress banner updates each file; UI remains responsive via `importBatchSize` yields | Cancel must stop before the next file |
| Library search (debounced) | ≤ 250 ms after keystroke settle for local LIKE/FTS query | Debounce is 250 ms in `librarySearchResultsProvider` |

## Cover memory

`AppConstants.coverCacheSize` (500) is the intended upper bound for in-memory cover entries. Grid/list tiles request scaled bitmaps (`cacheWidth`/`cacheHeight`) and wrap painted covers in `RepaintBoundary`.

## How to measure

1. Use Flutter DevTools Performance + Timeline while scrolling the library and turning EPUB chapters.
2. Import a 10 MB sample EPUB from onboarding / assets and time open → first text.
3. Record device model, OS, and Flutter channel in the release checklist when budgets are verified.
