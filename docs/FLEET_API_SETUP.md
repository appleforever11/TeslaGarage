# Tesla Fleet API connection

Tesla Garage uses Tesla's official Fleet API for live, owner-authorized data. It is intentionally cache-first: it only makes a live request after you choose **Refresh Live Tesla Data**. No command endpoints are enabled in this build.

## What you need

1. A Tesla Developer application registered for this app and approved for your owner account.
2. OAuth scopes: `openid`, `offline_access`, and `vehicle_device_data`. Add `vehicle_location` only if you later choose to show precise location.
3. A Tesla-issued OAuth access token. Tesla Garage stores this token only in your macOS Keychain; it never writes it to the repository or a config file.

## Connect the app

1. Open **Tesla Garage > Settings**.
2. Leave the North America Fleet API URL in place unless Tesla's region endpoint returns a different HTTPS base URL.
3. Paste the access token, choose **Save Token**, then **Test Connection**.
4. Choose **Refresh Live Tesla Data** from the Garage menu to fetch the first vehicle and its current `vehicle_data` snapshot.

## Deliberate safety limits

- No password collection or Tesla login form.
- No automatic polling and no `wake_up` call.
- No vehicle command endpoints in this initial connection layer.
- The DoorDock Pro local cache remains the offline fallback.

Tesla documents that `vehicle_data` is a live call and that routine polling is expensive; use Fleet Telemetry later if you decide to operate a public server-side data pipeline.
