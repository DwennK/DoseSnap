import Foundation

struct OpenAIFoodAnalysisService: FoodAnalysisService {
    private let endpoint: URL?
    private let urlSession: URLSession

    init(endpoint: URL?, urlSession: URLSession = .shared) {
        self.endpoint = endpoint
        self.urlSession = urlSession
    }

    func analyze(imageData: Data?) async throws -> FoodAnalysis {
        guard let imageData else { throw FoodAnalysisError.missingImage }
        guard let endpoint else { throw FoodAnalysisError.backendNotConfigured }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45

        let payload = AnalyzeFoodRequest(imageBase64: imageData.base64EncodedString())
        request.httpBody = try JSONEncoder().encode(payload)
        let integrityHeaders = await DeviceIntegrityService.shared.headers(for: request.httpBody)
        request.setValue(integrityHeaders.installationId, forHTTPHeaderField: "X-DoseSnap-Device-ID")

        if let appAttestKeyId = integrityHeaders.appAttestKeyId {
            request.setValue(appAttestKeyId, forHTTPHeaderField: "X-DoseSnap-App-Attest-Key-ID")
        }

        if let appAttestAssertion = integrityHeaders.appAttestAssertion {
            request.setValue(appAttestAssertion, forHTTPHeaderField: "X-DoseSnap-App-Attest-Assertion")
        }

        if let deviceCheckToken = integrityHeaders.deviceCheckToken {
            request.setValue(deviceCheckToken, forHTTPHeaderField: "X-DoseSnap-DeviceCheck-Token")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                throw FoodAnalysisError.invalidResponse
            }

            let dto = try JSONDecoder().decode(AnalyzeFoodResponse.self, from: data)
            return dto.foodAnalysis
        } catch let error as FoodAnalysisError {
            throw error
        } catch {
            throw FoodAnalysisError.requestFailed(error.localizedDescription)
        }
    }
}

private struct AnalyzeFoodRequest: Encodable {
    var imageBase64: String

    enum CodingKeys: String, CodingKey {
        case imageBase64 = "image_base64"
    }
}

private struct AnalyzeFoodResponse: Decodable {
    var detectedItems: [DetectedItemResponse]
    var totalCarbsLow: Double
    var totalCarbsMid: Double
    var totalCarbsHigh: Double
    var confidence: Double
    var warnings: [String]
    var explanation: String

    enum CodingKeys: String, CodingKey {
        case detectedItems = "detected_items"
        case totalCarbsLow = "total_carbs_low_g"
        case totalCarbsMid = "total_carbs_mid_g"
        case totalCarbsHigh = "total_carbs_high_g"
        case confidence
        case warnings
        case explanation
    }

    var foodAnalysis: FoodAnalysis {
        FoodAnalysis(
            detectedItems: detectedItems.map(\.foodItem),
            totalCarbsLow: totalCarbsLow,
            totalCarbsMid: totalCarbsMid,
            totalCarbsHigh: totalCarbsHigh,
            confidence: confidence,
            warnings: warnings,
            explanation: explanation,
            isLikelyFood: !detectedItems.isEmpty && totalCarbsHigh > 0
        )
    }
}

private struct DetectedItemResponse: Decodable {
    var name: String
    var estimatedCarbs: Double
    var confidence: Double

    enum CodingKeys: String, CodingKey {
        case name
        case estimatedCarbs = "estimated_carbs_g"
        case confidence
    }

    var foodItem: DetectedFoodItem {
        DetectedFoodItem(name: name, estimatedCarbs: estimatedCarbs, confidence: confidence)
    }
}
