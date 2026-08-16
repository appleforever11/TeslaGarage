# Sparkle updates

Tesla Garage embeds Sparkle 2.9.5 and has an Ed25519 public update key in the app bundle. The private signing key was generated locally and remains in the macOS Keychain; do not export it into this repository. The public appcast is hosted at `https://raw.githubusercontent.com/appleforever11/TeslaGarage/main/updates/appcast.xml`.

## Before the first public update

1. Upload the signed release archive to GitHub Releases.
2. Build with an alternate feed URL only when necessary:

   ```sh
   SPARKLE_FEED_URL=https://your-update-host.example/appcast.xml ./script/build_and_run.sh
   ```

3. Sign your distributable archive with Sparkle's `sign_update`, then run `generate_appcast` from `.build/artifacts/sparkle/Sparkle/bin/`.
4. Publish the archive and generated `appcast.xml` over HTTPS.

Automatic checks are disabled until the first signed release is published. **Tesla Garage > Check for Updates…** already reads the public feed; until the first release, it correctly reports that no update is available.

For production distribution, use Developer ID signing and notarization in addition to Sparkle's Ed25519 archive signatures.
