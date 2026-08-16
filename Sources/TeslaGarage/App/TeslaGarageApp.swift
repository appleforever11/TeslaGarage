import SwiftUI

@main
struct TeslaGarageApp: App {
    @State private var store = GarageStore()
    @State private var updater = SparkleUpdater()
    var body: some Scene {
        WindowGroup("Tesla Garage") { ContentView(store: store).frame(minWidth: 1180, minHeight: 720) }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("Garage") {
                Button("Refresh Cached Data") { store.refresh() }.keyboardShortcut("r")
                Button("Refresh Live Tesla Data") { store.refreshLiveData() }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                    .disabled(!store.hasFleetToken || store.isRefreshing)
                Divider()
                Button("Check for Updates…") { updater.checkForUpdates() }
            }
        }
        Settings { GarageSettings(store: store) }
    }
}
