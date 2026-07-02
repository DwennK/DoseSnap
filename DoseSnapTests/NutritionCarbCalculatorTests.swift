import XCTest
@testable import DoseSnap

final class NutritionCarbCalculatorTests: XCTestCase {
    private let calculator = NutritionCarbCalculator()

    func testCalculatesCarbsFromPer100gLabel() throws {
        let input = NutritionPackageInput(
            basis: .per100g,
            carbsPer100g: 62,
            portionGrams: 50,
            carbsPerServing: nil,
            servingCount: nil
        )

        let carbs = try calculator.calculate(input)

        XCTAssertEqual(carbs, 31, accuracy: 0.001)
    }

    func testCalculatesCarbsFromServingLabel() throws {
        let input = NutritionPackageInput(
            basis: .perServing,
            carbsPer100g: nil,
            portionGrams: nil,
            carbsPerServing: 24,
            servingCount: 1.5
        )

        let carbs = try calculator.calculate(input)

        XCTAssertEqual(carbs, 36, accuracy: 0.001)
    }

    func testRejectsInvalidPortion() {
        let input = NutritionPackageInput(
            basis: .per100g,
            carbsPer100g: 30,
            portionGrams: 0,
            carbsPerServing: nil,
            servingCount: nil
        )

        XCTAssertThrowsError(try calculator.calculate(input))
    }
}
