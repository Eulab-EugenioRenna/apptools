import Foundation
import UIKit

enum BackendClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case backend(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Backend URL non valido."
        case .invalidResponse:
            return "Risposta backend non valida."
        case let .backend(message):
            return message
        }
    }
}

struct BackendClient {
    let baseURL: String

    func healthCheck() async throws {
        guard let url = URL(string: normalizedBaseURL + "/health") else {
            throw BackendClientError.invalidURL
        }

        let (_, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw BackendClientError.invalidResponse
        }
    }

    func analyzeAndSave(image: UIImage, source: String) async throws -> ToolAIRecord {
        guard let url = URL(string: normalizedBaseURL + "/analyze-and-save") else {
            throw BackendClientError.invalidURL
        }

        guard let imageData = image.jpegData(compressionQuality: 0.92) else {
            throw BackendClientError.backend("Impossibile serializzare l'immagine.")
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartBody(imageData: imageData, boundary: boundary, source: source)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw BackendClientError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(AnalyzeAndSaveResponse.self, from: data)
        guard (200 ..< 300).contains(http.statusCode), decoded.success, let record = decoded.record else {
            throw BackendClientError.backend(decoded.error ?? "Salvataggio non riuscito.")
        }

        return record
    }

    private var normalizedBaseURL: String {
        baseURL.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "/$", with: "", options: .regularExpression)
    }

    private func multipartBody(imageData: Data, boundary: String, source: String) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"source\"\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append("\(source)\(lineBreak)".data(using: .utf8)!)

        body.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"shared.jpg\"\(lineBreak)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        body.append(imageData)
        body.append(lineBreak.data(using: .utf8)!)
        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

        return body
    }
}
