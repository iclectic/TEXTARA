# Release signing

## Android

1. Create an upload keystore (once):

```bash
keytool -genkey -v -keystore textara-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias textara
```

2. For Play / CI builds, set environment variables (never commit the keystore or passwords):

| Variable | Purpose |
|---|---|
| `TEXTARA_UPLOAD_STORE_FILE` | Absolute path to `.jks` |
| `TEXTARA_UPLOAD_STORE_PASSWORD` | Keystore password |
| `TEXTARA_UPLOAD_KEY_ALIAS` | Key alias |
| `TEXTARA_UPLOAD_KEY_PASSWORD` | Key password |

3. Build with obfuscation and split debug info:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

If `TEXTARA_UPLOAD_STORE_FILE` is unset, `android/app/build.gradle.kts` falls back to **debug signing** so local release runs still work. Do **not** upload a debug-signed AAB to Play.

## iOS

Use Xcode / `flutter build ipa` with the team’s distribution certificate and App Store provisioning profile. Export compliance: Textara uses only standard HTTPS OS stacks and local AES for optional user-chosen backup encryption — document `ITSAppUsesNonExemptEncryption` as appropriate for App Store Connect.
