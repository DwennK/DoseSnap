import Foundation
import Combine

struct AppToast: Identifiable, Equatable {
    let id = UUID()
    var message: String
    var systemImage: String
}

@MainActor
final class AppState: ObservableObject {
    @Published var profile: UserProfile
    @Published var mealHistory: [MealEntry]
    @Published var storageErrorMessage: String?
    @Published var toast: AppToast?

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
        showToast(message: "Repas sauvegardé", systemImage: "checkmark.circle.fill")
    }

    func likelyDuplicateMeal(for meal: MealEntry) -> MealEntry? {
        DuplicateMealDetector.likelyDuplicate(of: meal, in: mealHistory)
    }

    func updateMeal(_ meal: MealEntry) {
        guard let index = mealHistory.firstIndex(where: { $0.id == meal.id }) else { return }
        mealHistory[index] = meal
        persistMeals()
    }

    func deleteMeal(_ meal: MealEntry) {
        mealHistory.removeAll { $0.id == meal.id }
        persistMeals()
        showToast(message: "Repas supprimé", systemImage: "trash.fill")
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

    func showToast(message: String, systemImage: String) {
        let toast = AppToast(message: message, systemImage: systemImage)
        self.toast = toast

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if self?.toast == toast {
                    self?.toast = nil
                }
            }
        }
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
