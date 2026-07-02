import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var latestMeal: MealEntry?
    @Published private(set) var recentMeals: [MealEntry] = []
    @Published private(set) var profileSummary: String = ""

    func refresh(profile: UserProfile, meals: [MealEntry]) {
        latestMeal = meals.first
        recentMeals = Array(meals.prefix(4))
        profileSummary = "1 U / \(DoseFormatter.carbs(profile.insulinToCarbRatio)), cible \(DoseFormatter.glucose(profile.targetGlucose, unit: profile.glucoseUnit))"
    }
}
