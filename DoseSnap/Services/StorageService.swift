import Foundation

protocol StorageService {
    func loadProfile() -> UserProfile
    func saveProfile(_ profile: UserProfile) throws
    func loadMealHistory() -> [MealEntry]
    func saveMealHistory(_ meals: [MealEntry]) throws
    func clearMealHistory() throws
}

struct LocalStorageService: StorageService {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DoseSnap", isDirectory: true)

        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        fileURL = directory.appendingPathComponent("storage.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadProfile() -> UserProfile {
        loadEnvelope().profile
    }

    func saveProfile(_ profile: UserProfile) throws {
        var envelope = loadEnvelope()
        envelope.profile = profile
        try saveEnvelope(envelope)
    }

    func loadMealHistory() -> [MealEntry] {
        loadEnvelope().meals
    }

    func saveMealHistory(_ meals: [MealEntry]) throws {
        var envelope = loadEnvelope()
        envelope.meals = meals
        try saveEnvelope(envelope)
    }

    func clearMealHistory() throws {
        var envelope = loadEnvelope()
        envelope.meals = []
        try saveEnvelope(envelope)
    }

    private func loadEnvelope() -> StorageEnvelope {
        guard let data = try? Data(contentsOf: fileURL) else {
            return StorageEnvelope(profile: .default, meals: [])
        }

        return (try? decoder.decode(StorageEnvelope.self, from: data)) ?? StorageEnvelope(profile: .default, meals: [])
    }

    private func saveEnvelope(_ envelope: StorageEnvelope) throws {
        let data = try encoder.encode(envelope)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}

private struct StorageEnvelope: Codable {
    var profile: UserProfile
    var meals: [MealEntry]
}
