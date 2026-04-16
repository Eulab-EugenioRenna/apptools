import Foundation

enum AppConfiguration {
    static let appGroupIdentifier = "group.com.eulab.AppSendTool"
    static let backendURLKey = "backend_url"
    static let lastSavedRecordKey = "last_saved_record"
    static let defaultBackendURL = "http://127.0.0.1:8787"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published var backendURL: String {
        didSet {
            AppConfiguration.sharedDefaults.set(backendURL, forKey: AppConfiguration.backendURLKey)
        }
    }

    init() {
        let savedURL = AppConfiguration.sharedDefaults.string(forKey: AppConfiguration.backendURLKey)
        backendURL = savedURL?.isEmpty == false ? savedURL! : AppConfiguration.defaultBackendURL
    }
}

@MainActor
final class SavedRecordStore: ObservableObject {
    @Published private(set) var record: ToolAIRecord?

    func load() {
        guard let data = AppConfiguration.sharedDefaults.data(forKey: AppConfiguration.lastSavedRecordKey) else {
            record = nil
            return
        }

        record = try? JSONDecoder().decode(ToolAIRecord.self, from: data)
    }

    func save(_ record: ToolAIRecord) {
        self.record = record
        if let data = try? JSONEncoder().encode(record) {
            AppConfiguration.sharedDefaults.set(data, forKey: AppConfiguration.lastSavedRecordKey)
        }
    }
}
