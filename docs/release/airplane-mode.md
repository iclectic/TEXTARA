# Airplane-mode certification

Core flows that must work with radios off (manual checklist before store builds):

- [ ] Open an already-imported EPUB and PDF
- [ ] Library search (metadata + full-text index)
- [ ] Create highlight / bookmark
- [ ] Idea Threads add/export Markdown
- [ ] JSON backup export/import (local file)
- [ ] Encrypted backup export (local passphrase)
- [ ] Diagnostics export
- [ ] TTS using an already-downloaded system voice

Expected residual OS behaviour (not Textara servers):

- System may still prompt to download a TTS voice
- Google Fonts runtime fetch is **disabled** in `main.dart`
