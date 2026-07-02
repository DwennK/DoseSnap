import Foundation

enum DoseFormatter {
    static func dose(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1))) + " U"
    }

    static func carbs(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0))) + " g"
    }

    static func glucose(_ value: Double, unit: GlucoseUnit) -> String {
        let precision: ClosedRange<Int> = unit == .milligramsPerDeciliter ? 0...0 : 1...1
        return value.formatted(.number.precision(.fractionLength(precision))) + " " + unit.title
    }

    static func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }
}
