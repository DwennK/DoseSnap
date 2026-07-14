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
            "Unité de glycémie"
        case .insulinProfile:
            "Profil insulinique"
        case .safetyLimit:
            "Garde-fous"
        case .calibration:
            "Calibration alimentaire"
        case .review:
            "Vérification finale"
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

    var blockingProfileWarnings: [SafetyWarning] {
        InputValidationRules.profileWarnings(profile).filter { $0.severity == .critical }
    }

    var canContinue: Bool {
        switch currentStep {
        case .disclaimer, .glucoseUnit:
            true
        case .insulinProfile, .safetyLimit, .calibration, .review:
            blockingProfileWarnings.isEmpty
        }
    }

    func goBack() {
        guard let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = previousStep
    }

    func goForward() {
        guard canContinue,
              let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextStep
    }

    func setGlucoseUnit(_ unit: GlucoseUnit) {
        profile.updateGlucoseUnit(unit)
    }
}
