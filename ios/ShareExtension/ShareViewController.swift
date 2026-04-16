import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let viewModel = ShareViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        viewModel.onSaveCompleted = { [weak self] in
            self?.finishRequest()
        }

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
    @Published var statusText = "Carica immagini dalla condivisione."
    @Published var isSaving = false
    @Published private(set) var totalImages = 0
    @Published private(set) var completedImages = 0
    @Published private(set) var failedIndex: Int?

    var onSaveCompleted: (() -> Void)?

    private var images: [UIImage] = []

    func loadImage(from context: NSExtensionContext?) async {
        let providers = imageProviders(from: context)

        guard !providers.isEmpty else {
            statusText = "Nessuna immagine disponibile."
            return
        }

        do {
            var loadedImages: [UIImage] = []

            for provider in providers {
                let item = try await provider.loadItem(forTypeIdentifier: UTType.image.identifier)
                loadedImages.append(try image(from: item))
            }

            images = loadedImages
            totalImages = loadedImages.count
            completedImages = 0
            failedIndex = nil
            previewImage = loadedImages.first
            statusText = loadedImages.count == 1
                ? "1 immagine pronta."
                : "\(loadedImages.count) immagini pronte."
        } catch {
            statusText = error.localizedDescription
        }
    }

    func saveCurrentImage() async {
        await saveFromCurrentIndex()
    }

    func retryFailedImage() async {
        guard failedIndex != nil else { return }
        await saveFromCurrentIndex()
    }

    var canRetry: Bool {
        failedIndex != nil && !isSaving
    }

    var progressText: String {
        guard totalImages > 0 else { return "" }
        return "\(completedImages)/\(totalImages)"
    }

    private func saveFromCurrentIndex() async {
        guard !isSaving else { return }
        guard !images.isEmpty else {
            statusText = "Immagine non disponibile."
            return
        }

        let backendURL = AppConfiguration.sharedDefaults.string(forKey: AppConfiguration.backendURLKey) ?? AppConfiguration.defaultBackendURL
        isSaving = true
        let startIndex = failedIndex ?? completedImages
        failedIndex = nil

        for index in startIndex ..< images.count {
            previewImage = images[index]
            statusText = "Analizzo e salvo \(index + 1)/\(images.count)..."

            do {
                let record = try await BackendClient(baseURL: backendURL).analyzeAndSave(image: images[index], source: "ios-share-extension")
                persist(record)
                completedImages = index + 1
                statusText = images.count == 1
                    ? "Salvato: \(record.name)"
                    : "Salvato \(completedImages)/\(images.count): \(record.name)"
            } catch {
                failedIndex = index
                statusText = "Errore su \(index + 1)/\(images.count): \(error.localizedDescription)"
                isSaving = false
                return
            }
        }

        isSaving = false
        onSaveCompleted?()
    }

    private func image(from item: NSSecureCoding?) throws -> UIImage {
        if let url = item as? URL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            return image
        }

        if let image = item as? UIImage {
            return image
        }

        if let data = item as? Data, let image = UIImage(data: data) {
            return image
        }

        throw BackendClientError.backend("Formato immagine non supportato dalla share extension.")
    }

    private func imageProviders(from context: NSExtensionContext?) -> [NSItemProvider] {
        let items = context?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
        return items
            .flatMap { $0.attachments ?? [] }
            .filter { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }
    }

    private func persist(_ record: ToolAIRecord) {
        if let data = try? JSONEncoder().encode(record) {
            AppConfiguration.sharedDefaults.set(data, forKey: AppConfiguration.lastSavedRecordKey)
        }

        var history: [ToolAIRecord] = []
        if let data = AppConfiguration.sharedDefaults.data(forKey: AppConfiguration.savedHistoryKey),
           let decoded = try? JSONDecoder().decode([ToolAIRecord].self, from: data) {
            history = decoded
        }

        history.removeAll { $0.id == record.id }
        history.insert(record, at: 0)

        if let data = try? JSONEncoder().encode(history) {
            AppConfiguration.sharedDefaults.set(data, forKey: AppConfiguration.savedHistoryKey)
        }
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

                continuation.resume(returning: item)
            }
        }
    }
}

struct ShareRootView: View {
    @ObservedObject var viewModel: ShareViewModel
    let onDone: () -> Void
    let onCancel: () -> Void

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

                if !viewModel.progressText.isEmpty {
                    Text(viewModel.progressText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button(viewModel.isSaving ? "Salvataggio..." : "Salva in PocketBase") {
                    Task {
                        await viewModel.saveCurrentImage()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.previewImage == nil || viewModel.isSaving)

                if viewModel.canRetry {
                    Button("Riprova dalla foto in errore") {
                        Task {
                            await viewModel.retryFailedImage()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Save Tool")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla", action: onCancel)
                }
            }
        }
    }
}

