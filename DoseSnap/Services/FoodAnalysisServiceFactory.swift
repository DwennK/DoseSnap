import Foundation

enum FoodAnalysisServiceFactory {
    static func makeService(for profile: UserProfile) -> any FoodAnalysisService {
        switch profile.foodAnalysisProvider {
        case .mock:
            return MockFoodAnalysisService()
        case .backend:
            return OpenAIFoodAnalysisService(endpoint: backendURL(from: profile.backendEndpoint))
        }
    }

    static func backendURL(from endpoint: String) -> URL? {
        guard let url = URL(string: endpoint),
              let scheme = url.scheme?.lowercased(),
              url.host != nil else {
            return nil
        }

        #if DEBUG
        guard ["http", "https"].contains(scheme) else { return nil }
        #else
        guard scheme == "https" else { return nil }
        #endif

        return url
    }
}
