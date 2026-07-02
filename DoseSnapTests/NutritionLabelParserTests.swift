import XCTest
@testable import DoseSnap

final class NutritionLabelParserTests: XCTestCase {
    func testExtractsFrenchCarbsLine() {
        let text = """
        Energie 450 kcal
        Glucides 62,5 g
        dont sucres 48 g
        Proteines 7 g
        """

        XCTAssertEqual(NutritionLabelParser.extractCarbsPer100g(from: text) ?? 0, 62.5, accuracy: 0.001)
    }

    func testExtractsEnglishCarbohydrateLine() {
        let text = """
        Calories 210
        Total Carbohydrate 31g
        Sugars 26g
        """

        XCTAssertEqual(NutritionLabelParser.extractCarbsPer100g(from: text) ?? 0, 31, accuracy: 0.001)
    }

    func testIgnoresSugarLineWithoutCarbsLine() {
        let text = """
        dont sucres 15 g
        fibre 4 g
        """

        XCTAssertNil(NutritionLabelParser.extractCarbsPer100g(from: text))
    }
}
