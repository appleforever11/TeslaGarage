import Foundation

/// Reads only the last successful local DockDoor snapshot. It never wakes the car or makes a network request.
enum TeslaCacheImporter {
    static func load() throws -> VehicleSnapshot {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/DDP Tesla Charger Widget/cache/vehicle-data.json")
        let data = try Data(contentsOf: url)
        let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let response = root["response"] as? [String: Any] ?? root
        let charge = response["charge_state"] as? [String: Any] ?? [:]
        let drive = response["drive_state"] as? [String: Any] ?? [:]
        let climate = response["climate_state"] as? [String: Any] ?? [:]
        let vehicle = response["vehicle_state"] as? [String: Any] ?? [:]
        let config = response["vehicle_config"] as? [String: Any] ?? [:]
        var snapshot = VehicleSnapshot()
        snapshot.batteryLevel = int(charge["battery_level"], fallback: snapshot.batteryLevel)
        snapshot.estimatedRange = Int(double(charge["battery_range"], fallback: Double(snapshot.estimatedRange)))
        snapshot.temperature = Int(double(climate["inside_temp"], fallback: Double(snapshot.temperature)))
        snapshot.odometer = double(vehicle["odometer"], fallback: snapshot.odometer)
        snapshot.chargeState = string(charge["charging_state"]) ?? snapshot.chargeState
        snapshot.state = string(drive["shift_state"]) == "P" ? "Parked · Last saved location" : "Driving"
        if let display = string(config["car_type"]) { snapshot.name = "2021 \(display)" }
        snapshot.lastUpdated = "Imported from local Tesla cache"
        return snapshot
    }
    private static func string(_ value: Any?) -> String? { value as? String }
    private static func int(_ value: Any?, fallback: Int) -> Int { Int(double(value, fallback: Double(fallback))) }
    private static func double(_ value: Any?, fallback: Double) -> Double {
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        if let value = value as? String, let parsed = Double(value) { return parsed }
        return fallback
    }
}
