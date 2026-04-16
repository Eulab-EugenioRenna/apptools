import Foundation

struct ToolAISummary: Codable, Equatable {
    let apiAvailable: Bool
    let category: String
    let concepts: [String]
    let derivedLink: String
    let name: String
    let normalizedName: String
    let summary: String
    let tags: [String]
    let useCases: [String]
}

struct ToolAIRecord: Codable, Equatable, Identifiable {
    let brand: String
    let category: String
    let collectionId: String
    let collectionName: String
    let created: String
    let deleted: Bool
    let id: String
    let link: String
    let name: String
    let source: String
    let summary: ToolAISummary
    let updated: String
}

struct AnalyzeAndSaveResponse: Codable {
    let success: Bool
    let record: ToolAIRecord?
    let error: String?
}
