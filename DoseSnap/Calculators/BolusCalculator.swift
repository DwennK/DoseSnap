import Foundation

enum BolusCalculationError: Error, Equatable {
    case invalidCarbs
    case invalidRatio
    case invalidCorrectionFactor
    case invalidTargetGlucose
    case invalidCurrentGlucose
    case invalidActiveInsulin
    case invalidMaximumDose
    case invalidRoundingIncrement
}

struct BolusInput: Equatable {
    var estimatedCarbs: Double
    var currentGlucose: Double?
    var glucoseUnit: GlucoseUnit
    var insulinToCarbRatio: Double
    var correctionFactor: Double
    var targetGlucose: Double
    var activeInsulin: Double
    var maximumDose: Double
    var roundingIncrement: DoseRoundingIncrement
}

struct BolusCalculationResult: Equatable {
    var mealDose: Double
    var correctionDose: Double
    var activeInsulinSubtracted: Double
    var rawTotalDose: Double
    var roundedDose: Double
    var suggestedDose: Double
    var wasLimitedByMaximum: Bool
    var correctionWasUsed: Bool
}

struct BolusCalculator {
    func calculate(_ input: BolusInput) throws -> BolusCalculationResult {
        try validate(input)

        let mealDose = input.estimatedCarbs / input.insulinToCarbRatio
        let correctionDose: Double

        if let currentGlucose = input.currentGlucose {
            correctionDose = (currentGlucose - input.targetGlucose) / input.correctionFactor
        } else {
            correctionDose = 0
        }

        let rawTotal = max(0, mealDose + correctionDose - input.activeInsulin)
        let rounded = roundedDose(rawTotal, increment: input.roundingIncrement.rawValue)
        let wasLimited = rounded > input.maximumDose
        let suggested = wasLimited ? input.maximumDose : rounded

        return BolusCalculationResult(
            mealDose: mealDose,
            correctionDose: correctionDose,
            activeInsulinSubtracted: input.activeInsulin,
            rawTotalDose: rawTotal,
            roundedDose: rounded,
            suggestedDose: suggested,
            wasLimitedByMaximum: wasLimited,
            correctionWasUsed: input.currentGlucose != nil
        )
    }

    private func validate(_ input: BolusInput) throws {
        guard input.estimatedCarbs >= 0,
              input.estimatedCarbs <= 500,
              input.estimatedCarbs.isFinite else {
            throw BolusCalculationError.invalidCarbs
        }
        guard input.insulinToCarbRatio >= 1,
              input.insulinToCarbRatio <= 120,
              input.insulinToCarbRatio.isFinite else {
            throw BolusCalculationError.invalidRatio
        }
        guard input.correctionFactor > 0,
              input.glucoseUnit.isPlausibleCorrectionFactor(input.correctionFactor),
              input.correctionFactor.isFinite else {
            throw BolusCalculationError.invalidCorrectionFactor
        }
        guard input.targetGlucose > 0,
              input.glucoseUnit.isPlausibleTarget(input.targetGlucose),
              input.targetGlucose.isFinite else {
            throw BolusCalculationError.invalidTargetGlucose
        }
        if let currentGlucose = input.currentGlucose {
            guard input.glucoseUnit.isPlausibleGlucose(currentGlucose), currentGlucose.isFinite else {
                throw BolusCalculationError.invalidCurrentGlucose
            }
        }
        guard input.activeInsulin >= 0,
              input.activeInsulin <= InputValidationRules.maximumPlausibleActiveInsulin,
              input.activeInsulin.isFinite else {
            throw BolusCalculationError.invalidActiveInsulin
        }
        guard input.maximumDose > 0,
              input.maximumDose <= InputValidationRules.maximumPlausibleDoseLimit,
              input.maximumDose.isFinite else {
            throw BolusCalculationError.invalidMaximumDose
        }
        guard input.roundingIncrement.rawValue > 0 else {
            throw BolusCalculationError.invalidRoundingIncrement
        }
    }

    private func roundedDose(_ dose: Double, increment: Double) -> Double {
        (dose / increment).rounded() * increment
    }
}
