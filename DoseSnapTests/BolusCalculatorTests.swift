import XCTest
@testable import DoseSnap

final class BolusCalculatorTests: XCTestCase {
    private let calculator = BolusCalculator()

    func testCarbsOnlyCalculation() throws {
        let result = try calculator.calculate(input(carbs: 60))

        XCTAssertEqual(result.mealDose, 6, accuracy: 0.001)
        XCTAssertEqual(result.correctionDose, 0, accuracy: 0.001)
        XCTAssertEqual(result.suggestedDose, 6, accuracy: 0.001)
        XCTAssertFalse(result.correctionWasUsed)
    }

    func testCalculationWithGlucoseCorrection() throws {
        let result = try calculator.calculate(
            input(carbs: 60, currentGlucose: 180, correctionFactor: 40, targetGlucose: 100)
        )

        XCTAssertEqual(result.mealDose, 6, accuracy: 0.001)
        XCTAssertEqual(result.correctionDose, 2, accuracy: 0.001)
        XCTAssertEqual(result.suggestedDose, 8, accuracy: 0.001)
        XCTAssertTrue(result.correctionWasUsed)
    }

    func testGlucoseBelowTargetReducesSuggestion() throws {
        let result = try calculator.calculate(
            input(carbs: 60, currentGlucose: 70, correctionFactor: 30, targetGlucose: 100)
        )

        XCTAssertEqual(result.correctionDose, -1, accuracy: 0.001)
        XCTAssertEqual(result.suggestedDose, 5, accuracy: 0.001)
    }

    func testActiveInsulinIsSubtracted() throws {
        let result = try calculator.calculate(input(carbs: 60, activeInsulin: 1.5))

        XCTAssertEqual(result.activeInsulinSubtracted, 1.5, accuracy: 0.001)
        XCTAssertEqual(result.suggestedDose, 4.5, accuracy: 0.001)
    }

    func testMaximumDoseLimitIsApplied() throws {
        let result = try calculator.calculate(input(carbs: 200, maximumDose: 12))

        XCTAssertEqual(result.roundedDose, 20, accuracy: 0.001)
        XCTAssertEqual(result.suggestedDose, 12, accuracy: 0.001)
        XCTAssertTrue(result.wasLimitedByMaximum)
    }

    func testHalfUnitRounding() throws {
        let result = try calculator.calculate(input(carbs: 33, roundingIncrement: .halfUnit))

        XCTAssertEqual(result.rawTotalDose, 3.3, accuracy: 0.001)
        XCTAssertEqual(result.suggestedDose, 3.5, accuracy: 0.001)
    }

    func testOneUnitRounding() throws {
        let result = try calculator.calculate(input(carbs: 33, roundingIncrement: .oneUnit))

        XCTAssertEqual(result.rawTotalDose, 3.3, accuracy: 0.001)
        XCTAssertEqual(result.suggestedDose, 3, accuracy: 0.001)
    }

    func testInvalidValuesThrow() {
        XCTAssertThrowsError(try calculator.calculate(input(carbs: -1))) { error in
            XCTAssertEqual(error as? BolusCalculationError, .invalidCarbs)
        }

        XCTAssertThrowsError(try calculator.calculate(input(carbs: 900))) { error in
            XCTAssertEqual(error as? BolusCalculationError, .invalidCarbs)
        }

        XCTAssertThrowsError(try calculator.calculate(input(carbs: 10, ratio: 0))) { error in
            XCTAssertEqual(error as? BolusCalculationError, .invalidRatio)
        }

        XCTAssertThrowsError(try calculator.calculate(input(carbs: 10, ratio: 0.1))) { error in
            XCTAssertEqual(error as? BolusCalculationError, .invalidRatio)
        }

        XCTAssertThrowsError(try calculator.calculate(input(carbs: 10, maximumDose: 0))) { error in
            XCTAssertEqual(error as? BolusCalculationError, .invalidMaximumDose)
        }

        XCTAssertThrowsError(try calculator.calculate(input(carbs: 10, currentGlucose: 999))) { error in
            XCTAssertEqual(error as? BolusCalculationError, .invalidCurrentGlucose)
        }
    }

    private func input(
        carbs: Double,
        currentGlucose: Double? = nil,
        ratio: Double = 10,
        correctionFactor: Double = 50,
        targetGlucose: Double = 110,
        activeInsulin: Double = 0,
        maximumDose: Double = 20,
        roundingIncrement: DoseRoundingIncrement = .halfUnit
    ) -> BolusInput {
        BolusInput(
            estimatedCarbs: carbs,
            currentGlucose: currentGlucose,
            glucoseUnit: .milligramsPerDeciliter,
            insulinToCarbRatio: ratio,
            correctionFactor: correctionFactor,
            targetGlucose: targetGlucose,
            activeInsulin: activeInsulin,
            maximumDose: maximumDose,
            roundingIncrement: roundingIncrement
        )
    }
}
