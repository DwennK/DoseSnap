import Foundation

struct DetectedFoodItem: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var estimatedCarbs: Double
    var confidence: Double

    init(id: UUID = UUID(), name: String, estimatedCarbs: Double, confidence: Double) {
        self.id = id
        self.name = name
        self.estimatedCarbs = estimatedCarbs
        self.confidence = confidence
    }
}

struct FoodAnalysis: Identifiable, Codable, Equatable {
    var id: UUID
    var detectedItems: [DetectedFoodItem]
    var totalCarbsLow: Double
    var totalCarbsMid: Double
    var totalCarbsHigh: Double
    var confidence: Double
    var warnings: [String]
    var explanation: String
    var isLikelyFood: Bool

    init(
        id: UUID = UUID(),
        detectedItems: [DetectedFoodItem],
        totalCarbsLow: Double,
        totalCarbsMid: Double,
        totalCarbsHigh: Double,
        confidence: Double,
        warnings: [String] = [],
        explanation: String,
        isLikelyFood: Bool = true
    ) {
        self.id = id
        self.detectedItems = detectedItems
        self.totalCarbsLow = totalCarbsLow
        self.totalCarbsMid = totalCarbsMid
        self.totalCarbsHigh = totalCarbsHigh
        self.confidence = confidence
        self.warnings = warnings
        self.explanation = explanation
        self.isLikelyFood = isLikelyFood
    }

    var displayName: String {
        detectedItems.map(\.name).joined(separator: ", ")
    }

    func adjustedForCalibration(_ status: CalibrationStatus) -> FoodAnalysis {
        guard status.shouldApplyAdjustment else { return self }

        let factor = status.factor
        guard factor != 1 else { return self }

        let adjustedItems = detectedItems.map {
            DetectedFoodItem(
                id: $0.id,
                name: $0.name,
                estimatedCarbs: ($0.estimatedCarbs * factor).rounded(),
                confidence: $0.confidence
            )
        }

        var adjustedWarnings = warnings
        adjustedWarnings.append("Calibration alimentaire appliquée avec prudence. Vérifiez les glucides avant toute décision.")

        return FoodAnalysis(
            id: id,
            detectedItems: adjustedItems,
            totalCarbsLow: max(0, (totalCarbsLow * factor).rounded()),
            totalCarbsMid: max(0, (totalCarbsMid * factor).rounded()),
            totalCarbsHigh: max(0, (totalCarbsHigh * factor).rounded()),
            confidence: confidence,
            warnings: adjustedWarnings,
            explanation: explanation,
            isLikelyFood: isLikelyFood
        )
    }
}
