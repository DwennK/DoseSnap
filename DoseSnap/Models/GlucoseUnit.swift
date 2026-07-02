import Foundation

enum GlucoseUnit: String, Codable, CaseIterable, Identifiable {
    case milligramsPerDeciliter
    case millimolesPerLiter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .milligramsPerDeciliter:
            "mg/dL"
        case .millimolesPerLiter:
            "mmol/L"
        }
    }

    var defaultTarget: Double {
        switch self {
        case .milligramsPerDeciliter:
            110
        case .millimolesPerLiter:
            6.1
        }
    }

    var defaultCorrectionFactor: Double {
        switch self {
        case .milligramsPerDeciliter:
            50
        case .millimolesPerLiter:
            2.8
        }
    }

    var veryLowThreshold: Double {
        switch self {
        case .milligramsPerDeciliter:
            70
        case .millimolesPerLiter:
            3.9
        }
    }

    var veryHighThreshold: Double {
        switch self {
        case .milligramsPerDeciliter:
            250
        case .millimolesPerLiter:
            13.9
        }
    }

    func convertedValue(_ value: Double, to targetUnit: GlucoseUnit) -> Double {
        guard self != targetUnit else { return value }

        switch (self, targetUnit) {
        case (.milligramsPerDeciliter, .millimolesPerLiter):
            return value / 18.0182
        case (.millimolesPerLiter, .milligramsPerDeciliter):
            return value * 18.0182
        default:
            return value
        }
    }

    func isPlausibleGlucose(_ value: Double) -> Bool {
        switch self {
        case .milligramsPerDeciliter:
            return (20...600).contains(value)
        case .millimolesPerLiter:
            return (1.1...33.3).contains(value)
        }
    }

    func isPlausibleTarget(_ value: Double) -> Bool {
        switch self {
        case .milligramsPerDeciliter:
            return (70...180).contains(value)
        case .millimolesPerLiter:
            return (3.9...10).contains(value)
        }
    }

    func isPlausibleCorrectionFactor(_ value: Double) -> Bool {
        switch self {
        case .milligramsPerDeciliter:
            return (5...200).contains(value)
        case .millimolesPerLiter:
            return (0.3...11.1).contains(value)
        }
    }
}
