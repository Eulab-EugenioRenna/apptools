import SwiftUI

@main
struct AppSendToolApp: App {
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var savedRecordStore = SavedRecordStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
                .environmentObject(savedRecordStore)
        }
    }
}
