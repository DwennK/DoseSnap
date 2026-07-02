import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var profile: UserProfile
    @Published var mealHistory: [MealEntry]
    @Published var storageErrorMessage: String?

    private let storageService: any StorageService

    init(storageService: any StorageService = LocalStorageService()) {
        self.storageService = storageService
        profile = storageService.loadProfile()
        mealHistory = storageService.loadMealHistory().sorted { $0.date > $1.date }
    }

    func completeOnboarding(with profile: UserProfile) {
        var completedProfile = profile
        completedProfile.hasCompletedOnboarding = true
        saveProfile(completedProfile)
    }

    func saveProfile(_ updatedProfile: UserProfile) {
        profile = updatedProfile
        persistProfile()
    }

    func addMeal(_ meal: MealEntry) {
        mealHistory.insert(meal, at: 0)
        persistMeals()
    }

    func likelyDuplicateMeal(for meal: MealEntry) -> MealEntry? {
        DuplicateMealDetector.likelyDuplicate(of: meal, in: mealHistory)
    }

    func updateMeal(_ meal: MealEntry) {
        guard let index = mealHistory.firstIndex(where: { $0.id == meal.id }) else { return }
        mealHistory[index] = meal
        persistMeals()
    }

    func clearHistory() {
        mealHistory = []

        do {
            try storageService.clearMealHistory()
        } catch {
            storageErrorMessage = error.localizedDescription
        }
    }

    func seedDemoHistory() {
        mealHistory = DemoDataSeeder.demoMeals()
        persistMeals()
    }

    private func persistProfile() {
        do {
            try storageService.saveProfile(profile)
            storageErrorMessage = nil
        } catch {
            storageErrorMessage = error.localizedDescription
        }
    }

    private func persistMeals() {
        do {
            try storageService.saveMealHistory(mealHistory)
            storageErrorMessage = nil
        } catch {
            storageErrorMessage = error.localizedDescription
        }
    }
}
