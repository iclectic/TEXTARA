# Textara Privacy

Textara is designed to work **fully offline** by default. Your library stays on your device.

## What stays on-device

- Book files you import (EPUB, PDF, TXT, FB2, DRM-free MOBI/AZW)
- Reading progress, bookmarks, highlights, notes, and ink strokes
- Theme, typography, brightness, and accessibility preferences
- Offline dictionary lexicon (bundled asset) and any cached lookup results stored locally

## Network use

Textara does **not** require an account and does **not** phone home for analytics or ads.

The **only** optional network call is the Free Dictionary API fallback when you explicitly enable **Online dictionary fallback** in Settings. That setting is **off by default**. When enabled, lookups that miss the offline lexicon may request:

`https://api.dictionaryapi.dev/api/v2/entries/en/{word}`

Responses may be cached on-device for later offline use. Disable the setting at any time to keep dictionary lookups local-only.

Import, reading, annotations, backup/export, and search do not require network access.

## DRM

Textara never removes or bypasses DRM. DRM-protected MOBI/AZW files are rejected with a clear explanation.

## Backups

Backups you create are JSON files you choose to save or share. Textara does not upload them.

## Permissions

Platform file-picker / storage access is used only so you can import books and export backups or annotations. Application-scoped brightness adjusts in-app display brightness where the OS allows it; Textara does not request system-wide `WRITE_SETTINGS`.

## Contact / changes

Privacy behaviour should match this document. If a release adds new network endpoints, they must be documented here and remain opt-in unless required for an explicit user action.
