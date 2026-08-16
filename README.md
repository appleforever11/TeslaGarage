# Tesla Garage

Tesla Garage is a native macOS control-room dashboard for one 2021 Model 3 Standard Range Plus in Pearl White.

## What is working

- Tesla-inspired dashboard with a dedicated Model 3 hero view.
- Separate Controls, Dynamics, Charging, Locks, Climate, Schedule, Service, and Software views.
- Drive statistics, tire pressure, battery, range, cabin temperature, charging state, and odometer presentation.
- Safe local cache import from the existing DoorDock Pro Tesla widget.
- Manual, Keychain-backed Tesla Fleet API live-data connection.
- Sparkle 2 updater framework, embedded and ready for a signed public appcast.
- A native Settings window for vehicle identity and connection status.
- A macOS app bundle and a Run action for repeatable builds and launches.

## Live-data safety

The existing Tesla Fleet API account was previously throttled by Tesla. Tesla Garage intentionally does **not** poll, wake the vehicle, or send commands while that remains unresolved. Its refresh action imports only the last saved DoorDock Pro snapshot from this Mac.

When the Fleet API account is available again, use the owner-authorized connection flow in Settings. Tesla Garage stores the access token in the Mac Keychain and preserves cache-first behavior.

See [Fleet API setup](docs/FLEET_API_SETUP.md) and [Sparkle updates](docs/UPDATES.md).

## Run

Use the Run action in Codex, or run `./script/build_and_run.sh` from this folder.
