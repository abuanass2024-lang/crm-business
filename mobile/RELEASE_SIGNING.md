# Android Release Signing — v1.4

The repository never contains the production keystore or passwords.

CI can sign a release when these environment variables are supplied securely:

- `ANDROID_KEYSTORE_PATH`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

For GitHub Actions, store the keystore as an encrypted repository secret and materialize it only during the build job. Prefer an organization/environment secret with restricted access.

For Google Play, build an Android App Bundle (`flutter build appbundle --release`) and keep the upload key separate from the app signing key when Play App Signing is enabled.
