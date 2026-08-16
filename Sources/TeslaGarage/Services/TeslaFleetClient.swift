import Foundation

struct TeslaFleetConfiguration {
    static let defaultBaseURL = "https://fleet-api.prd.na.vn.cloud.tesla.com"
    static let tokenAccount = "tesla-fleet-access-token"

    var baseURL: URL
    var accessToken: String

    init(baseURL: String, accessToken: String) throws {
        guard let url = URL(string: baseURL), url.scheme == "https" else {
            throw TeslaFleetError.invalidBaseURL
        }
        self.baseURL = url
        self.accessToken = accessToken
    }
}

struct TeslaFleetClient {
    let configuration: TeslaFleetConfiguration

    func vehicles() async throws -> [TeslaFleetVehicle] {
        let data = try await request(path: "/api/1/vehicles")
        return try TeslaFleetDecoder.vehicles(from: data)
    }

    func vehicleData(vin: String) async throws -> VehicleSnapshot {
        let data = try await request(path: "/api/1/vehicles/\(vin)/vehicle_data")
        return try TeslaFleetDecoder.snapshot(from: data)
    }

    private func request(path: String) async throws -> Data {
        let url = configuration.baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.setValue("Bearer \(configuration.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 25
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw TeslaFleetError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw TeslaFleetError.http(status: http.statusCode, message: TeslaFleetDecoder.errorMessage(from: data))
        }
        return data
    }
}

struct TeslaFleetVehicle: Identifiable, Hashable {
    let id: String
    let vin: String
    let name: String
}

enum TeslaFleetError: LocalizedError {
    case missingToken, invalidBaseURL, invalidResponse, malformedResponse
    case http(status: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .missingToken: "Add a Tesla Fleet API access token in Settings."
        case .invalidBaseURL: "The Tesla Fleet API base URL must be HTTPS."
        case .invalidResponse: "Tesla returned an invalid response."
        case .malformedResponse: "Tesla returned data Tesla Garage could not read."
        case .http(let status, let message): message.map { "Tesla API \(status): \($0)" } ?? "Tesla API request failed (\(status))."
        }
    }
}

enum TeslaFleetDecoder {
    static func vehicles(from data: Data) throws -> [TeslaFleetVehicle] {
        let root = try object(from: data)
        let response = root["response"]
        let records: [[String: Any]]
        if let directRecords = response as? [[String: Any]] {
            records = directRecords
        } else if let response = response as? [String: Any], let pagedRecords = response["results"] as? [[String: Any]] {
            records = pagedRecords
        } else {
            throw TeslaFleetError.malformedResponse
        }
        return records.compactMap { record in
            guard let vin = record["vin"] as? String else { return nil }
            let id = String(describing: record["id_s"] ?? record["id"] ?? vin)
            return TeslaFleetVehicle(id: id, vin: vin, name: (record["display_name"] as? String) ?? vin)
        }
    }

    static func snapshot(from data: Data) throws -> VehicleSnapshot {
        let root = try object(from: data)
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
        snapshot.state = string(drive["shift_state"]) == "P" ? "Parked" : (string(drive["shift_state"]) ?? "Online")
        snapshot.name = string(vehicle["vehicle_name"]) ?? string(config["car_type"]).map { "Tesla \($0)" } ?? snapshot.name
        snapshot.lastUpdated = "Live Tesla Fleet API data"
        return snapshot
    }

    static func errorMessage(from data: Data) -> String? {
        let object = try? object(from: data)
        return object?["error"] as? String ?? object?["message"] as? String
    }

    private static func object(from data: Data) throws -> [String: Any] {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw TeslaFleetError.malformedResponse }
        return root
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
