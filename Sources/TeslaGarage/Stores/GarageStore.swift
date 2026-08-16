import SwiftUI

@Observable final class GarageStore {
    var selectedSection: GarageSection = .controls
    var showTripDetails = true
    var showVehicleMenu = false
    var snapshot = VehicleSnapshot()
    var refreshMessage = "Live connection paused"
    var isUsingLocalCache = false
    var isRefreshing = false
    var fleetBaseURL = UserDefaults.standard.string(forKey: "fleetBaseURL") ?? TeslaFleetConfiguration.defaultBaseURL
    var selectedVIN = UserDefaults.standard.string(forKey: "fleetVIN") ?? ""

    var hasFleetToken: Bool {
        (try? KeychainStore.read(account: TeslaFleetConfiguration.tokenAccount)) != nil
    }

    func refresh() {
        do {
            snapshot = try TeslaCacheImporter.load()
            isUsingLocalCache = true
            refreshMessage = "Showing last saved Tesla data"
        } catch {
            refreshMessage = "No saved Tesla snapshot found"
        }
    }

    func refreshLiveData() {
        Task { @MainActor in
            isRefreshing = true
            defer { isRefreshing = false }
            do {
                let client = try fleetClient()
                let vehicles = try await client.vehicles()
                guard let vehicle = vehicles.first(where: { $0.vin == selectedVIN }) ?? vehicles.first else {
                    throw TeslaFleetError.malformedResponse
                }
                selectedVIN = vehicle.vin
                UserDefaults.standard.set(vehicle.vin, forKey: "fleetVIN")
                snapshot = try await client.vehicleData(vin: vehicle.vin)
                isUsingLocalCache = false
                refreshMessage = "Live data refreshed · \(vehicle.name)"
            } catch {
                refreshMessage = error.localizedDescription
            }
        }
    }

    func testFleetConnection() {
        Task { @MainActor in
            isRefreshing = true
            defer { isRefreshing = false }
            do {
                let vehicles = try await fleetClient().vehicles()
                let suffix = vehicles.count == 1 ? "" : "s"
                refreshMessage = "Tesla Fleet API connected · \(vehicles.count) vehicle\(suffix) found"
            } catch {
                refreshMessage = error.localizedDescription
            }
        }
    }

    func saveFleetBaseURL(_ url: String) {
        fleetBaseURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(fleetBaseURL, forKey: "fleetBaseURL")
    }

    func saveFleetToken(_ token: String) throws {
        let cleaned = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw TeslaFleetError.missingToken }
        try KeychainStore.save(cleaned, account: TeslaFleetConfiguration.tokenAccount)
        refreshMessage = "Tesla API token saved securely in Keychain"
    }

    func disconnectFleet() {
        KeychainStore.delete(account: TeslaFleetConfiguration.tokenAccount)
        selectedVIN = ""
        UserDefaults.standard.removeObject(forKey: "fleetVIN")
        refreshMessage = "Tesla Fleet API disconnected"
    }

    private func fleetClient() throws -> TeslaFleetClient {
        guard let token = try KeychainStore.read(account: TeslaFleetConfiguration.tokenAccount), !token.isEmpty else {
            throw TeslaFleetError.missingToken
        }
        return TeslaFleetClient(configuration: try TeslaFleetConfiguration(baseURL: fleetBaseURL, accessToken: token))
    }
}

enum GarageSection: String, CaseIterable, Identifiable {
    case controls = "Controls", dynamics = "Dynamics", charging = "Charging", autopilot = "Autopilot", locks = "Locks"
    case lights = "Lights", seats = "Seats", display = "Display", schedule = "Schedule", safety = "Safety"
    case service = "Service", software = "Software", navigation = "Navigation", trips = "Trips", wifi = "Wi-Fi", bluetooth = "Bluetooth", audio = "Audio", upgrades = "Upgrades"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .controls: "switch.2"; case .dynamics: "gauge.with.dots.needle.67percent"
        case .charging: "bolt.fill"; case .autopilot: "steeringwheel"; case .locks: "lock.fill"
        case .lights: "sun.max"; case .seats: "carseat.left"; case .display: "rectangle.inset.filled"
        case .schedule: "calendar"; case .safety: "exclamationmark.circle"; case .service: "wrench.and.screwdriver.fill"
        case .software: "arrow.down.circle"; case .navigation: "location.north.fill"; case .trips: "point.topleft.down.to.point.bottomright.curvepath"
        case .wifi: "wifi"; case .bluetooth: "bluetooth"; case .audio: "speaker.wave.2.fill"; case .upgrades: "cart.fill"
        }
    }
}
