import Foundation

enum FoodAnalysisError: LocalizedError, Equatable {
    case missingImage
    case backendNotConfigured
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingImage:
            "Aucune image n'a ete fournie."
        case .backendNotConfigured:
            "Aucun endpoint backend n'est configure."
        case .invalidResponse:
            "La reponse d'analyse est invalide."
        case .requestFailed(let message):
            message
        }
    }
}

protocol FoodAnalysisService {
    func analyze(imageData: Data?) async throws -> FoodAnalysis
}
