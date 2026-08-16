import SwiftUI

struct GarageSettings: View {
    @Bindable var store: GarageStore
    @State private var accessToken = ""
    @State private var baseURL = ""
    @State private var tokenMessage: String?

    var body: some View {
        Form {
            Section("Vehicle") {
                LabeledContent("Profile", value: "2021 Model 3 Standard Range Plus")
                LabeledContent("Paint", value: "Pearl White Multi-Coat")
            }
            Section("Offline fallback") {
                Text("Tesla Garage always retains the last local DoorDock Pro snapshot. This remains available when the car is asleep or the Tesla connection is unavailable.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Import Local Tesla Cache") { store.refresh() }
            }
            Section("Tesla Fleet API") {
                Text("Live refresh is manual only. Tesla Garage never sends vehicle commands or wakes the car in the background.")
                    .font(.caption).foregroundStyle(.secondary)
                TextField("Fleet API base URL", text: $baseURL)
                    .textFieldStyle(.roundedBorder)
                SecureField("OAuth access token", text: $accessToken)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Save Token") {
                        do {
                            store.saveFleetBaseURL(baseURL)
                            try store.saveFleetToken(accessToken)
                            accessToken = ""
                            tokenMessage = "Saved in your Mac Keychain."
                        } catch {
                            tokenMessage = error.localizedDescription
                        }
                    }
                    .disabled(accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Test Connection") { store.testFleetConnection() }
                        .disabled(!store.hasFleetToken || store.isRefreshing)
                    Button("Disconnect", role: .destructive) { store.disconnectFleet() }
                        .disabled(!store.hasFleetToken)
                }
                LabeledContent("Stored token", value: store.hasFleetToken ? "Present in Keychain" : "Not configured")
                if let tokenMessage { Text(tokenMessage).font(.caption).foregroundStyle(.secondary) }
                Text("Use a Tesla-issued third-party OAuth token with vehicle_device_data and offline_access. Do not paste your Tesla password here.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Connection status") {
                LabeledContent("Status", value: store.refreshMessage)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 560)
        .onAppear { baseURL = store.fleetBaseURL }
    }
}
