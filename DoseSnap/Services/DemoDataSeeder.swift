import Foundation

enum DemoDataSeeder {
    static func demoMeals() -> [MealEntry] {
        [
            MealEntry(
                date: Date().addingTimeInterval(-3_600),
                thumbnailData: nil,
                estimatedMealName: "Snickers standard",
                confirmedCarbs: 33,
                carbsRangeLow: 28,
                carbsRangeHigh: 38,
                suggestedDose: 3.5,
                glucoseValue: nil,
                activeInsulin: nil,
                notes: "Exemple local pour vérifier l'historique.",
                usefulness: .useful
            ),
            MealEntry(
                date: Date().addingTimeInterval(-86_400),
                thumbnailData: nil,
                estimatedMealName: "Bol de pâtes",
                confirmedCarbs: 92,
                carbsRangeLow: 70,
                carbsRangeHigh: 120,
                suggestedDose: 9,
                glucoseValue: 115,
                activeInsulin: nil,
                notes: "Portion démo à remplacer par une vraie entrée.",
                usefulness: .notRated
            )
        ]
    }
}
