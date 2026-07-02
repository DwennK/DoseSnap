import XCTest
@testable import DoseSnap

final class ScanViewModelTests: XCTestCase {
    @MainActor
    func testAnalyzeUsesInjectedFoodAnalysisServiceAndCalculatesDose() async {
        let viewModel = ScanViewModel(foodAnalysisService: SuccessfulFoodAnalysisService())
        var profile = UserProfile.default
        profile.hasCompletedOnboarding = true
        profile.calibration = .empty

        viewModel.setImageData(Data([1, 2, 3]))
        await viewModel.analyze(profile: profile)

        XCTAssertEqual(viewModel.analysis?.displayName, "Test meal")
        XCTAssertEqual(viewModel.confirmedCarbs, 50, accuracy: 0.001)
        XCTAssertEqual(viewModel.calculation?.suggestedDose ?? -1, 5, accuracy: 0.001)
    }

    @MainActor
    func testCorrectionCanUseDifferentInputGlucoseUnit() {
        let viewModel = ScanViewModel()
        var profile = UserProfile.default
        profile.hasCompletedOnboarding = true
        profile.glucoseUnit = .milligramsPerDeciliter
        profile.targetGlucose = 100
        profile.correctionFactor = 50
        viewModel.configureManualEntry(carbs: 50)
        viewModel.isCorrectionEnabled = true
        viewModel.inputGlucoseUnit = .millimolesPerLiter
        viewModel.currentGlucoseText = "10"

        viewModel.recalculate(profile: profile)

        XCTAssertEqual(viewModel.currentGlucose(in: .milligramsPerDeciliter) ?? 0, 180.182, accuracy: 0.01)
        XCTAssertEqual(viewModel.calculation?.suggestedDose ?? -1, 6.5, accuracy: 0.001)
    }

    @MainActor
    func testVeryLowGlucoseMasksSuggestion() {
        let viewModel = ScanViewModel()
        var profile = UserProfile.default
        profile.hasCompletedOnboarding = true
        viewModel.configureManualEntry(carbs: 50)
        viewModel.isCorrectionEnabled = true
        viewModel.inputGlucoseUnit = profile.glucoseUnit
        viewModel.currentGlucoseText = "\(profile.glucoseUnit.veryLowThreshold)"

        viewModel.recalculate(profile: profile)

        XCTAssertNil(viewModel.calculation)
        XCTAssertTrue(viewModel.safetyWarnings.contains { $0.title == "Glycemie tres basse" })
    }

    @MainActor
    func testPoorPhotoRequiresConfirmationBeforeAnalyzeCallsService() async {
        let service = CountingFoodAnalysisService()
        let viewModel = ScanViewModel(foodAnalysisService: service)
        var profile = UserProfile.default
        profile.hasCompletedOnboarding = true

        viewModel.setCameraImage(makeImage(size: CGSize(width: 320, height: 240), color: .black))
        XCTAssertTrue(viewModel.requiresPhotoQualityConfirmation)

        await viewModel.analyze(profile: profile)
        XCTAssertEqual(service.callCount, 0)
        XCTAssertFalse(viewModel.requiresPhotoQualityConfirmation)

        viewModel.setCameraImage(makeImage(size: CGSize(width: 320, height: 240), color: .black))
        viewModel.confirmPhotoQualityForAnalysis()
        await viewModel.analyze(profile: profile)
        XCTAssertEqual(service.callCount, 1)
    }

    @MainActor
    func testBeverageCarbsAreAddedToConfirmedCarbs() {
        let viewModel = ScanViewModel()
        viewModel.configureManualEntry(carbs: 40)
        viewModel.setIncludesBeverage(true)
        viewModel.setBeverageType(.regularSoda)
        viewModel.beverageVolumeText = "330"

        XCTAssertEqual(viewModel.mealCarbs, 40, accuracy: 0.001)
        XCTAssertEqual(viewModel.beverageCarbs, 34.98, accuracy: 0.01)
        XCTAssertEqual(viewModel.confirmedCarbs, 74.98, accuracy: 0.01)
    }

    @MainActor
    func testAbsurdGlucoseBlocksCalculation() {
        let viewModel = ScanViewModel()
        var profile = UserProfile.default
        profile.hasCompletedOnboarding = true
        viewModel.configureManualEntry(carbs: 40)
        viewModel.isCorrectionEnabled = true
        viewModel.currentGlucoseText = "999"

        viewModel.recalculate(profile: profile)

        XCTAssertNil(viewModel.calculation)
        XCTAssertTrue(viewModel.safetyWarnings.contains { $0.title == "Glycemie a verifier" })
    }

    private func makeImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

private struct SuccessfulFoodAnalysisService: FoodAnalysisService {
    func analyze(imageData: Data?) async throws -> FoodAnalysis {
        FoodAnalysis(
            detectedItems: [DetectedFoodItem(name: "Test meal", estimatedCarbs: 50, confidence: 0.9)],
            totalCarbsLow: 45,
            totalCarbsMid: 50,
            totalCarbsHigh: 55,
            confidence: 0.9,
            explanation: "Test response."
        )
    }
}

private final class CountingFoodAnalysisService: FoodAnalysisService {
    var callCount = 0

    func analyze(imageData: Data?) async throws -> FoodAnalysis {
        callCount += 1

        return FoodAnalysis(
            detectedItems: [DetectedFoodItem(name: "Test meal", estimatedCarbs: 50, confidence: 0.9)],
            totalCarbsLow: 45,
            totalCarbsMid: 50,
            totalCarbsHigh: 55,
            confidence: 0.9,
            explanation: "Test response."
        )
    }
}
