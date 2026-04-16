import Foundation

enum AppConfiguration {
    static let appGroupIdentifier = "group.com.eulab.AppSendTool"
    static let backendURLKey = "backend_url"
    static let lastSavedRecordKey = "last_saved_record"
    static let savedHistoryKey = "saved_record_history"
    static let defaultBackendURL = "https://appsend.eulab.cloud"

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
    @Published private(set) var history: [ToolAIRecord] = []

    func load() {
        if let data = AppConfiguration.sharedDefaults.data(forKey: AppConfiguration.lastSavedRecordKey) {
            record = try? JSONDecoder().decode(ToolAIRecord.self, from: data)
        } else {
            record = nil
        }

        if let data = AppConfiguration.sharedDefaults.data(forKey: AppConfiguration.savedHistoryKey),
           let decoded = try? JSONDecoder().decode([ToolAIRecord].self, from: data) {
            history = decoded
        } else {
            history = record.map { [$0] } ?? []
        }
    }

    func save(_ record: ToolAIRecord) {
        self.record = record

        if let data = try? JSONEncoder().encode(record) {
            AppConfiguration.sharedDefaults.set(data, forKey: AppConfiguration.lastSavedRecordKey)
        }

        var nextHistory = history.filter { $0.id != record.id }
        nextHistory.insert(record, at: 0)
        history = nextHistory

        if let data = try? JSONEncoder().encode(nextHistory) {
            AppConfiguration.sharedDefaults.set(data, forKey: AppConfiguration.savedHistoryKey)
        }
    }
}
