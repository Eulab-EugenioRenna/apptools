import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var savedRecordStore: SavedRecordStore

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
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Ultimo record salvato") {
                    if let record = savedRecordStore.record {
                        LabeledContent("Nome", value: record.name)
                        LabeledContent("Categoria", value: record.category)
                        LabeledContent("Link", value: record.link.isEmpty ? "-" : record.link)
                        LabeledContent("Source", value: record.source)
                        LabeledContent("PocketBase ID", value: record.id)

                        if !record.summary.tags.isEmpty {
                            Text(record.summary.tags.joined(separator: ", "))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Text(record.summary.summary)
                            .font(.footnote)
                    } else {
                        Text("Nessun record ancora salvato dalla Share Extension.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("AppSendTool")
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
