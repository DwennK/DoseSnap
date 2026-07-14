import Foundation

struct MockFoodAnalysisService: FoodAnalysisService {
    func analyze(imageData: Data?) async throws -> FoodAnalysis {
        guard imageData != nil else { throw FoodAnalysisError.missingImage }

        try await Task.sleep(nanoseconds: 900_000_000)
        return Self.mockResponses.randomElement() ?? Self.mockResponses[0]
    }

    static let mockResponses: [FoodAnalysis] = [
        FoodAnalysis(
            detectedItems: [
                DetectedFoodItem(name: "Snickers standard", estimatedCarbs: 33, confidence: 0.86)
            ],
            totalCarbsLow: 28,
            totalCarbsMid: 33,
            totalCarbsHigh: 38,
            confidence: 0.86,
            warnings: ["Vérifiez la taille exacte de la barre."],
            explanation: "Le mock reconnaît une barre chocolat-caramel de format standard."
        ),
        FoodAnalysis(
            detectedItems: [
                DetectedFoodItem(name: "Menu Big Mac", estimatedCarbs: 115, confidence: 0.72),
                DetectedFoodItem(name: "Frites", estimatedCarbs: 55, confidence: 0.69),
                DetectedFoodItem(name: "Boisson sucrée possible", estimatedCarbs: 40, confidence: 0.48)
            ],
            totalCarbsLow: 100,
            totalCarbsMid: 120,
            totalCarbsHigh: 130,
            confidence: 0.68,
            warnings: ["La boisson et la taille des frites changent fortement les glucides."],
            explanation: "Estimation prudente pour un menu type, à confirmer selon boisson et portion."
        ),
        FoodAnalysis(
            detectedItems: [
                DetectedFoodItem(name: "Pizza moyenne", estimatedCarbs: 125, confidence: 0.7)
            ],
            totalCarbsLow: 90,
            totalCarbsMid: 125,
            totalCarbsHigh: 160,
            confidence: 0.7,
            warnings: ["L'épaisseur de pâte et le nombre de parts peuvent changer fortement l'estimation."],
            explanation: "Fourchette large pour pizza moyenne, selon diamètre et pâte."
        ),
        FoodAnalysis(
            detectedItems: [
                DetectedFoodItem(name: "Bol de pâtes", estimatedCarbs: 95, confidence: 0.74)
            ],
            totalCarbsLow: 70,
            totalCarbsMid: 95,
            totalCarbsHigh: 120,
            confidence: 0.74,
            warnings: ["La portion cuite est difficile à évaluer depuis une photo."],
            explanation: "Estimation mock pour un bol de pâtes avec portion moyenne."
        ),
        FoodAnalysis(
            detectedItems: [
                DetectedFoodItem(name: "Salade composée", estimatedCarbs: 18, confidence: 0.42)
            ],
            totalCarbsLow: 8,
            totalCarbsMid: 18,
            totalCarbsHigh: 45,
            confidence: 0.42,
            warnings: ["Dépend fortement de la sauce, du pain, des croûtons et des légumes féculents."],
            explanation: "Salade détectée avec forte incertitude sur les accompagnements."
        )
    ]
}
