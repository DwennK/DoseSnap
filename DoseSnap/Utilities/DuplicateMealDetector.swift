import Foundation

enum DuplicateMealDetector {
    static let defaultWindow: TimeInterval = 120

    static func likelyDuplicate(
        of meal: MealEntry,
        in history: [MealEntry],
        window: TimeInterval = defaultWindow
    ) -> MealEntry? {
        history
            .filter { abs($0.date.timeIntervalSince(meal.date)) <= window }
            .first { existing in
                hasSimilarName(existing.estimatedMealName, meal.estimatedMealName) &&
                hasSimilarCarbs(existing.confirmedCarbs, meal.confirmedCarbs)
            }
    }

    private static func hasSimilarName(_ left: String, _ right: String) -> Bool {
        let normalizedLeft = normalize(left)
        let normalizedRight = normalize(right)

        guard !normalizedLeft.isEmpty, !normalizedRight.isEmpty else { return false }
        return normalizedLeft == normalizedRight
    }

    private static func hasSimilarCarbs(_ left: Double, _ right: Double) -> Bool {
        let tolerance = max(5, max(left, right) * 0.15)
        return abs(left - right) <= tolerance
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
