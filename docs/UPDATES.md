# Sparkle updates

Tesla Garage embeds Sparkle 2.9.5 and has an Ed25519 public update key in the app bundle. The private signing key was generated locally and remains in the macOS Keychain; do not export it into this repository.

## Before the first public update

1. Choose a public HTTPS location for `appcast.xml` and release archives. A public GitHub Releases workflow is one option.
2. Build with the feed URL:

   ```sh
   SPARKLE_FEED_URL=https://your-update-host.example/appcast.xml ./script/build_and_run.sh
   ```

3. Sign your distributable archive with Sparkle's `sign_update`, then run `generate_appcast` from `.build/artifacts/sparkle/Sparkle/bin/`.
4. Publish the archive and generated `appcast.xml` over HTTPS.

Automatic checks are disabled until that feed exists. **Check for Updates…** is already wired into the Garage menu for a configured release build.

For production distribution, use Developer ID signing and notarization in addition to Sparkle's Ed25519 archive signatures.
