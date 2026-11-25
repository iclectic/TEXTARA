# Privacy and data

Textara is a **local-first, free** reader. There is no account system and no required network for core reading.

## What stays on device

| Data | Where | Shared by default? |
|---|---|---|
| Books (EPUB/PDF) | App documents `books/` | No |
| Covers | App documents `covers/` | No |
| Highlights, bookmarks, Idea Threads | SQLite `textara.db` | No |
| Theme / a11y / reader prefs | SharedPreferences | No |
| Reading session minutes | SQLite `reading_sessions` | No |
| Local error log | `textara_errors.log` | No (user may export) |

## Network

| Feature | Network? | Notes |
|---|---|---|
| Import / open / search / backup / export | No | Fully offline |
| EPUB/PDF rendering | No | |
| TTS | Device voices only | OS may download voices separately |
| Reader fonts | **No** | Literata, Merriweather, Lora, Source Serif 4, Inter, Roboto, Open Sans, Atkinson Hyperlegible, and OpenDyslexic are bundled. The app does not fetch fonts |
| Crash / analytics SaaS | **Not included** | Local diagnostics export only |

## Diagnostics

- Unexpected errors append to a local log via `LocalErrorLog`.
- Settings → **Export diagnostics** writes a user-reviewable text file under `exports/`.
- Exports intentionally **omit book titles and chapter contents**.
- No automatic upload. No marketing notifications.

## Android / iOS platform backup

- Android: `android:allowBackup="false"` with exclude rules in `backup_rules.xml` / `data_extraction_rules.xml`.
- iOS: documents can be shared via Files when `UIFileSharingEnabled` is set; users control what they export.

## Store questionnaire answers (draft)

- **Account:** none  
- **Tracking:** none by default  
- **Data collection:** none off-device by Textara  
- **Encryption in transit:** N/A for core features (no Textara servers)  
- **User content:** books and notes remain under user control on device  
