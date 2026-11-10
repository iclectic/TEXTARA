# Store readiness checklist (lightweight)

Status for the Phase 6 polish bar. Items marked **verified locally** were checked in this agent environment; GitHub Actions green is claimed only after CI runs on the PR.

## Privacy & trust

- [x] Offline-first reader; no account required
- [x] Opt-in online dictionary only (`PRIVACY.md`)
- [x] DRM never decrypted; clear reject copy for protected MOBI/AZW
- [x] Backup/export are user-initiated local files

## Quality gates

- [x] `flutter analyze lib test` (run locally before PR)
- [x] `flutter test` unit/widget suite (run locally before PR)
- [x] `dart format` check on `lib` + `test`
- [x] GitHub Actions workflow added (`.github/workflows/ci.yml`) — **CI green only after Actions runs on the PR**

## Accessibility

- [x] Semantics on primary library/reader controls (existing)
- [x] Contrast AA checks for Light / Dark / Blue reading triad (unit tests)
- [ ] Full TalkBack/VoiceOver pass on physical devices (manual; remaining)

## Performance

- [x] Debounced reading progress writes + flush on leave
- [x] Chapter text LRU cache for EPUB/TXT/FB2/MOBI reopen
- [x] PDF viewer image cache budget tightened for large files
- [ ] Integration smoke: import → read → annotate → backup (remaining / Phase 6b follow-up)

## Listing copy

- [x] README store draft + formats expanded beyond EPUB/PDF
- [ ] Final Play/App Store screenshots and age rating (publisher task)
