import Foundation

enum DoseRoundingIncrement: Double, Codable, CaseIterable, Identifiable {
    case halfUnit = 0.5
    case oneUnit = 1.0

    var id: Double { rawValue }

    var title: String {
        switch self {
        case .halfUnit:
            "0,5 unité"
        case .oneUnit:
            "1 unité"
        }
    }
}

struct FoodCalibration: Codable, Equatable {
    var snickersUnits: Double
    var bigMacMenuUnits: Double
    var mediumPizzaUnits: Double
    var pastaBowlUnits: Double

    static let empty = FoodCalibration(
        snickersUnits: 0,
        bigMacMenuUnits: 0,
        mediumPizzaUnits: 0,
        pastaBowlUnits: 0
    )
}

enum FoodAnalysisProvider: String, Codable, CaseIterable, Identifiable {
    case backend
    case mock

    var id: String { rawValue }

    var title: String {
        switch self {
        case .backend:
            "Backend IA"
        case .mock:
            "Mock local"
        }
    }
}

enum CalibrationStatus: Equatable {
    case unavailable
    case coherent(factor: Double)
    case needsReview(factor: Double, spread: Double)

    var factor: Double {
        switch self {
        case .unavailable:
            1
        case .coherent(let factor), .needsReview(let factor, _):
            factor
        }
    }

    var shouldApplyAdjustment: Bool {
        switch self {
        case .unavailable, .needsReview:
            false
        case .coherent(let factor):
            factor != 1
        }
    }
}

struct UserProfile: Codable, Equatable {
    static let defaultBackendEndpoint = ""

    var hasCompletedOnboarding: Bool
    var glucoseUnit: GlucoseUnit
    var insulinToCarbRatio: Double
    var correctionFactor: Double
    var targetGlucose: Double
    var maxSuggestedDose: Double
    var roundingIncrement: DoseRoundingIncrement
    var calibration: FoodCalibration
    var foodAnalysisProvider: FoodAnalysisProvider
    var backendEndpoint: String

    enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding
        case glucoseUnit
        case insulinToCarbRatio
        case correctionFactor
        case targetGlucose
        case maxSuggestedDose
        case roundingIncrement
        case calibration
        case foodAnalysisProvider
        case backendEndpoint
    }

    static let `default` = UserProfile(
        hasCompletedOnboarding: false,
        glucoseUnit: .milligramsPerDeciliter,
        insulinToCarbRatio: 10,
        correctionFactor: GlucoseUnit.milligramsPerDeciliter.defaultCorrectionFactor,
        targetGlucose: GlucoseUnit.milligramsPerDeciliter.defaultTarget,
        maxSuggestedDose: 12,
        roundingIncrement: .halfUnit,
        calibration: .empty,
        foodAnalysisProvider: .mock,
        backendEndpoint: defaultBackendEndpoint
    )

    init(
        hasCompletedOnboarding: Bool,
        glucoseUnit: GlucoseUnit,
        insulinToCarbRatio: Double,
        correctionFactor: Double,
        targetGlucose: Double,
        maxSuggestedDose: Double,
        roundingIncrement: DoseRoundingIncrement,
        calibration: FoodCalibration,
        foodAnalysisProvider: FoodAnalysisProvider,
        backendEndpoint: String
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.glucoseUnit = glucoseUnit
        self.insulinToCarbRatio = insulinToCarbRatio
        self.correctionFactor = correctionFactor
        self.targetGlucose = targetGlucose
        self.maxSuggestedDose = maxSuggestedDose
        self.roundingIncrement = roundingIncrement
        self.calibration = calibration
        self.foodAnalysisProvider = foodAnalysisProvider
        self.backendEndpoint = backendEndpoint
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        glucoseUnit = try container.decode(GlucoseUnit.self, forKey: .glucoseUnit)
        insulinToCarbRatio = try container.decode(Double.self, forKey: .insulinToCarbRatio)
        correctionFactor = try container.decode(Double.self, forKey: .correctionFactor)
        targetGlucose = try container.decode(Double.self, forKey: .targetGlucose)
        maxSuggestedDose = try container.decode(Double.self, forKey: .maxSuggestedDose)
        roundingIncrement = try container.decode(DoseRoundingIncrement.self, forKey: .roundingIncrement)
        calibration = try container.decode(FoodCalibration.self, forKey: .calibration)
        foodAnalysisProvider = try container.decodeIfPresent(FoodAnalysisProvider.self, forKey: .foodAnalysisProvider) ?? .backend
        let decodedEndpoint = try container.decodeIfPresent(String.self, forKey: .backendEndpoint) ?? ""
        backendEndpoint = decodedEndpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Self.defaultBackendEndpoint : decodedEndpoint
    }

    var isComplete: Bool {
        insulinToCarbRatio > 0 &&
        correctionFactor > 0 &&
        targetGlucose > 0 &&
        maxSuggestedDose > 0
    }

    var calibrationAdjustmentFactor: Double {
        calibrationStatus.factor
    }

    var calibrationStatus: CalibrationStatus {
        let baselines: [(units: Double, carbs: Double)] = [
            (calibration.snickersUnits, 33),
            (calibration.bigMacMenuUnits, 115),
            (calibration.mediumPizzaUnits, 125),
            (calibration.pastaBowlUnits, 95)
        ]

        let ratios = baselines.compactMap { item -> Double? in
            guard item.units > 0, insulinToCarbRatio > 0 else { return nil }
            return (item.units * insulinToCarbRatio) / item.carbs
        }

        guard ratios.count >= 2 else { return .unavailable }

        let average = ratios.reduce(0, +) / Double(ratios.count)
        let minimum = ratios.min() ?? average
        let maximum = ratios.max() ?? average
        let spread = maximum - minimum
        let boundedFactor = min(1.1, max(0.9, average))

        if spread > 0.35 || average < 0.75 || average > 1.25 {
            return .needsReview(factor: boundedFactor, spread: spread)
        }

        return .coherent(factor: boundedFactor)
    }

    mutating func updateGlucoseUnit(_ newUnit: GlucoseUnit) {
        guard glucoseUnit != newUnit else { return }

        targetGlucose = glucoseUnit.convertedValue(targetGlucose, to: newUnit)
        correctionFactor = glucoseUnit.convertedValue(correctionFactor, to: newUnit)
        glucoseUnit = newUnit
    }
}
