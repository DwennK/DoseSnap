import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var profile: UserProfile

    init(profile: UserProfile) {
        self.profile = profile
    }

    func setGlucoseUnit(_ unit: GlucoseUnit) {
        profile.updateGlucoseUnit(unit)
    }

    func resetCalibration() {
        profile.calibration = .empty
    }
}
