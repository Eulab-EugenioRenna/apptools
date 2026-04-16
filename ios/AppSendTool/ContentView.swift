import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var savedRecordStore: SavedRecordStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var healthMessage = ""
    @State private var isCheckingHealth = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Backend") {
                    TextField("Backend URL", text: $settingsStore.backendURL)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
#endif
                        .autocorrectionDisabled(true)

                    Button(isCheckingHealth ? "Test in corso..." : "Test connessione") {
                        Task {
                            await runHealthCheck()
                        }
                    }
                    .disabled(isCheckingHealth)

                    if !healthMessage.isEmpty {
                        Text(healthMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Ultimo record salvato") {
                    if let record = savedRecordStore.record {
                        compactField("Nome", record.name)
                        compactField("Categoria", record.category)
                        compactField("Link", record.link.isEmpty ? "-" : record.link)
                        compactField("Source", record.source)
                        compactField("PocketBase ID", record.id)

                        if !record.summary.tags.isEmpty {
                            Text(record.summary.tags.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Text(record.summary.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(4)
                    } else {
                        Text("Nessun record ancora salvato dalla Share Extension.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Cronologia") {
                    if savedRecordStore.history.isEmpty {
                        Text("Nessun record salvato.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(savedRecordStore.history) { record in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(record.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !record.link.isEmpty {
                                    Text(record.link)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }
                }
            }
            .navigationTitle("AppSendTool")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                savedRecordStore.load()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                if scenePhase == .active {
                    savedRecordStore.refreshIfNeeded()
                }
            }
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }

                while !Task.isCancelled {
                    savedRecordStore.refreshIfNeeded()

                    do {
                        try await Task.sleep(for: .seconds(2))
                    } catch {
                        return
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func compactField(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.caption)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }

    @MainActor
    private func runHealthCheck() async {
        isCheckingHealth = true
        defer { isCheckingHealth = false }

        do {
            try await BackendClient(baseURL: settingsStore.backendURL).healthCheck()
            healthMessage = "Backend raggiungibile."
        } catch {
            healthMessage = error.localizedDescription
        }
    }
}
