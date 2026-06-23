# Android Release Signing

Textara supports Play-ready release signing without committing secrets.

## Files

- `android/key.properties` is ignored by git and must exist only on trusted release machines.
- `android/key.properties.example` documents the required keys.
- The actual `.jks`/`.keystore` file must not be committed.

## Setup

1. Create or obtain the Textara upload keystore.
2. Store it outside source control, for example `release/textara-upload-keystore.jks`.
3. Copy `android/key.properties.example` to `android/key.properties`.
4. Fill in `storePassword`, `keyPassword`, `keyAlias`, and `storeFile`.
5. Run:

```sh
flutter build appbundle --release
```

When `android/key.properties` is present, Gradle signs release bundles with that keystore. When it is absent, Gradle falls back to debug signing so local release builds still work, but those bundles must not be uploaded to Play.

## Play Console

- Enable Play App Signing.
- Upload the signed `app-release.aab`.
- Keep the upload keystore backed up in a secure password manager or secret store.
- Rotate the upload key through Play Console only if the key is compromised.
