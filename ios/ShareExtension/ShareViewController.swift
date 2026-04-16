import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let viewModel = ShareViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let rootView = ShareRootView(viewModel: viewModel) { [weak self] in
            self?.finishRequest()
        } onCancel: { [weak self] in
            self?.cancelRequest()
        }

        let hostingController = UIHostingController(rootView: rootView)
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)

        Task {
            await viewModel.loadImage(from: extensionContext)
        }
    }

    private func finishRequest() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func cancelRequest() {
        extensionContext?.cancelRequest(withError: NSError(domain: "AppSendTool", code: 1))
    }
}

@MainActor
final class ShareViewModel: ObservableObject {
    @Published var previewImage: UIImage?
    @Published var statusText = "Carica un'immagine dalla condivisione."
    @Published var isSaving = false

    private var sharedFileURL: URL?

    var canDeleteSharedFile: Bool {
        sharedFileURL?.isFileURL == true
    }

    func loadImage(from context: NSExtensionContext?) async {
        guard let item = context?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) else {
            statusText = "Nessuna immagine disponibile."
            return
        }

        do {
            let item = try await provider.loadItem(forTypeIdentifier: UTType.image.identifier)
            previewImage = try image(from: item)
            statusText = "Immagine pronta."
        } catch {
            statusText = error.localizedDescription
        }
    }

    func saveCurrentImage() async {
        guard !isSaving else { return }
        guard let previewImage else {
            statusText = "Immagine non disponibile."
            return
        }

        let backendURL = AppConfiguration.sharedDefaults.string(forKey: AppConfiguration.backendURLKey) ?? AppConfiguration.defaultBackendURL
        isSaving = true
        statusText = "Analizzo e salvo..."

        do {
            let record = try await BackendClient(baseURL: backendURL).analyzeAndSave(image: previewImage, source: "ios-share-extension")
            if let data = try? JSONEncoder().encode(record) {
                AppConfiguration.sharedDefaults.set(data, forKey: AppConfiguration.lastSavedRecordKey)
            }
            statusText = "Salvato: \(record.name)"
        } catch {
            statusText = error.localizedDescription
        }

        isSaving = false
    }

    func deleteSharedFileIfPossible() throws {
        guard let sharedFileURL, sharedFileURL.isFileURL else {
            return
        }

        let startedAccess = sharedFileURL.startAccessingSecurityScopedResource()
        defer {
            if startedAccess {
                sharedFileURL.stopAccessingSecurityScopedResource()
            }
        }

        if FileManager.default.fileExists(atPath: sharedFileURL.path) {
            try FileManager.default.removeItem(at: sharedFileURL)
        }
    }

    private func image(from item: NSSecureCoding?) throws -> UIImage {
        if let url = item as? URL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            sharedFileURL = url
            return image
        }

        sharedFileURL = nil

        if let image = item as? UIImage {
            return image
        }

        if let data = item as? Data, let image = UIImage(data: data) {
            return image
        }

        throw BackendClientError.backend("Formato immagine non supportato dalla share extension.")
    }
}

private extension NSItemProvider {
    func loadItem(forTypeIdentifier typeIdentifier: String) async throws -> NSSecureCoding? {
        try await withCheckedThrowingContinuation { continuation in
            loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: item as? NSSecureCoding)
            }
        }
    }
}

struct ShareRootView: View {
    @ObservedObject var viewModel: ShareViewModel
    let onDone: () -> Void
    let onCancel: () -> Void

    @State private var isShowingCloseConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Group {
                    if let image = viewModel.previewImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 220)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 42))
                                    .foregroundStyle(.secondary)
                            }
                    }
                }

                Text(viewModel.statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(viewModel.isSaving ? "Salvataggio..." : "Salva in PocketBase") {
                    Task {
                        await viewModel.saveCurrentImage()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.previewImage == nil || viewModel.isSaving)

                Button("Chiudi") {
                    isShowingCloseConfirmation = true
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isSaving)
            }
            .padding()
            .navigationTitle("Save Tool")
            .confirmationDialog("Chiudi la condivisione?", isPresented: $isShowingCloseConfirmation, titleVisibility: .visible) {
                if viewModel.canDeleteSharedFile {
                    Button("Elimina file e chiudi", role: .destructive) {
                        do {
                            try viewModel.deleteSharedFileIfPossible()
                            onDone()
                        } catch {
                            viewModel.statusText = error.localizedDescription
                        }
                    }
                }

                Button("Chiudi senza eliminare") {
                    onDone()
                }

                Button("Annulla", role: .cancel) {}
            } message: {
                if viewModel.canDeleteSharedFile {
                    Text("Puoi chiudere la share extension oppure eliminare il file locale condiviso prima di chiudere.")
                } else {
                    Text("Conferma la chiusura della share extension.")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla", action: onCancel)
                }
            }
        }
    }
}
