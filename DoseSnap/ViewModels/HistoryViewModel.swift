import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var entries: [MealEntry] = []

    func refresh(meals: [MealEntry]) {
        entries = meals.sorted { $0.date > $1.date }
    }
}
