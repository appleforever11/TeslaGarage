import Foundation
import Sparkle

@MainActor
final class SparkleUpdater: NSObject {
    private let controller: SPUStandardUpdaterController

    override init() {
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        super.init()
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
