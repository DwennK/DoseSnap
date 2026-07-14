import XCTest
@testable import DoseSnap

final class SafetyRulesTests: XCTestCase {
    func testWarnsForHighCarbs() {
        let warnings = SafetyRules.warnings(
            analysis: nil,
            carbs: 180,
            glucose: nil,
            profile: completeProfile(),
            calculation: nil
        )

        XCTAssertTrue(warnings.contains { $0.title == "Glucides élevés" })
    }

    func testWarnsForLowGlucose() {
        let warnings = SafetyRules.warnings(
            analysis: nil,
            carbs: 30,
            glucose: 65,
            profile: completeProfile(),
            calculation: nil
        )

        XCTAssertTrue(warnings.contains { $0.title == "Glycémie très basse" })
    }

    func testWarnsForIncoherentCalibration() {
        var profile = completeProfile()
        profile.calibration = FoodCalibration(
            snickersUnits: 1,
            bigMacMenuUnits: 20,
            mediumPizzaUnits: 2,
            pastaBowlUnits: 18
        )

        let warnings = SafetyRules.warnings(
            analysis: nil,
            carbs: 40,
            glucose: nil,
            profile: profile,
            calculation: nil
        )

        XCTAssertTrue(warnings.contains { $0.title == "Calibration incohérente" })
    }

    func testBlocksSaveUntilCarbsVerified() {
        XCTAssertTrue(
            SafetyRules.shouldBlockSave(
                profile: completeProfile(),
                analysis: nil,
                hasVerifiedCarbs: false
            )
        )

        XCTAssertFalse(
            SafetyRules.shouldBlockSave(
                profile: completeProfile(),
                analysis: nil,
                hasVerifiedCarbs: true
            )
        )
    }

    func testBlocksSuggestionForVeryLowGlucose() {
        let profile = completeProfile()

        XCTAssertTrue(
            SafetyRules.shouldBlockSuggestion(
                profile: profile,
                analysis: nil,
                glucose: profile.glucoseUnit.veryLowThreshold
            )
        )

        XCTAssertEqual(
            SafetyRules.blockingSuggestionWarning(
                profile: profile,
                analysis: nil,
                glucose: profile.glucoseUnit.veryLowThreshold
            )?.title,
            "Suggestion masquée"
        )
    }

    func testBlocksSuggestionForAbsurdCarbs() {
        let profile = completeProfile()

        XCTAssertTrue(
            SafetyRules.shouldBlockSuggestion(
                profile: profile,
                analysis: nil,
                carbs: 900,
                glucose: nil
            )
        )

        let warnings = SafetyRules.warnings(
            analysis: nil,
            carbs: 900,
            glucose: nil,
            profile: profile,
            calculation: nil
        )

        XCTAssertTrue(warnings.contains { $0.title == "Glucides à vérifier" })
    }

    func testWarnsWhenBeverageIsDetectedButNotConfirmed() {
        let analysis = FoodAnalysis(
            detectedItems: [DetectedFoodItem(name: "Burger et soda", estimatedCarbs: 95, confidence: 0.82)],
            totalCarbsLow: 80,
            totalCarbsMid: 95,
            totalCarbsHigh: 120,
            confidence: 0.82,
            explanation: "Repas avec boisson possible."
        )

        let warnings = SafetyRules.warnings(
            analysis: analysis,
            carbs: 95,
            glucose: nil,
            profile: completeProfile(),
            calculation: nil
        )

        XCTAssertTrue(warnings.contains { $0.title == "Boisson à vérifier" })
    }

    func testWarnsForAbsurdProfileValues() {
        var profile = completeProfile()
        profile.insulinToCarbRatio = 0.1

        let warnings = SafetyRules.warnings(
            analysis: nil,
            carbs: 30,
            glucose: nil,
            profile: profile,
            calculation: nil
        )

        XCTAssertTrue(warnings.contains { $0.title == "Ratio à vérifier" })
    }

    private func completeProfile() -> UserProfile {
        var profile = UserProfile.default
        profile.hasCompletedOnboarding = true
        return profile
    }
}
