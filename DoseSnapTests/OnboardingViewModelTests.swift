import XCTest
@testable import DoseSnap

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    func testInsulinProfileBlocksImplausibleRatio() {
        let viewModel = OnboardingViewModel()
        viewModel.currentStep = .insulinProfile
        viewModel.profile.insulinToCarbRatio = 0.1

        XCTAssertFalse(viewModel.canContinue)
        XCTAssertFalse(viewModel.blockingProfileWarnings.isEmpty)
    }

    func testSafetyLimitBlocksNonPositiveDose() {
        let viewModel = OnboardingViewModel()
        viewModel.currentStep = .safetyLimit
        viewModel.profile.maxSuggestedDose = 0

        XCTAssertFalse(viewModel.canContinue)
        XCTAssertFalse(viewModel.blockingProfileWarnings.isEmpty)
    }

    func testCalibrationCannotAdvanceToReviewWithInvalidProfile() {
        let viewModel = OnboardingViewModel()
        viewModel.currentStep = .calibration
        viewModel.profile.targetGlucose = 999

        viewModel.goForward()

        XCTAssertEqual(viewModel.currentStep, .calibration)
        XCTAssertFalse(viewModel.canContinue)
    }

    func testValidProfileCanReachAndCompleteReview() {
        let viewModel = OnboardingViewModel()
        viewModel.currentStep = .calibration

        viewModel.goForward()

        XCTAssertEqual(viewModel.currentStep, .review)
        XCTAssertTrue(viewModel.canContinue)
        XCTAssertTrue(viewModel.blockingProfileWarnings.isEmpty)
    }
}
