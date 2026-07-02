import Foundation
import Combine

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case disclaimer
    case glucoseUnit
    case insulinProfile
    case safetyLimit
    case calibration
    case review

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .disclaimer:
            "DoseSnap est une aide d'estimation"
        case .glucoseUnit:
            "Unite de glycemie"
        case .insulinProfile:
            "Profil insulinique"
        case .safetyLimit:
            "Garde-fous"
        case .calibration:
            "Calibration alimentaire"
        case .review:
            "Verification finale"
        }
    }

    var iconName: String {
        switch self {
        case .disclaimer:
            "exclamationmark.shield"
        case .glucoseUnit:
            "drop"
        case .insulinProfile:
            "slider.horizontal.3"
        case .safetyLimit:
            "lock.shield"
        case .calibration:
            "fork.knife"
        case .review:
            "checkmark.seal"
        }
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var currentStep: OnboardingStep = .disclaimer

    init(profile: UserProfile = .default) {
        self.profile = profile
    }

    var progress: Double {
        let total = Double(OnboardingStep.allCases.count)
        return Double(currentStep.rawValue + 1) / total
    }

    var canGoBack: Bool {
        currentStep.rawValue > 0
    }

    var isLastStep: Bool {
        currentStep == .review
    }

    var canContinue: Bool {
        switch currentStep {
        case .disclaimer, .glucoseUnit, .safetyLimit, .calibration, .review:
            true
        case .insulinProfile:
            profile.insulinToCarbRatio > 0 &&
            profile.correctionFactor > 0 &&
            profile.targetGlucose > 0
        }
    }

    func goBack() {
        guard let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = previousStep
    }

    func goForward() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextStep
    }

    func setGlucoseUnit(_ unit: GlucoseUnit) {
        profile.updateGlucoseUnit(unit)
    }
}
