import Foundation

enum MealUsefulness: String, Codable, CaseIterable, Identifiable {
    case notRated
    case useful
    case notUseful

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notRated:
            "Non evalue"
        case .useful:
            "Utile"
        case .notUseful:
            "Pas utile"
        }
    }
}

struct MealEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var thumbnailData: Data?
    var estimatedMealName: String
    var confirmedCarbs: Double
    var carbsRangeLow: Double
    var carbsRangeHigh: Double
    var suggestedDose: Double
    var glucoseValue: Double?
    var activeInsulin: Double?
    var notes: String
    var usefulness: MealUsefulness

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        thumbnailData: Data?,
        estimatedMealName: String,
        confirmedCarbs: Double,
        carbsRangeLow: Double,
        carbsRangeHigh: Double,
        suggestedDose: Double,
        glucoseValue: Double?,
        activeInsulin: Double?,
        notes: String,
        usefulness: MealUsefulness = .notRated
    ) {
        self.id = id
        self.date = date
        self.thumbnailData = thumbnailData
        self.estimatedMealName = estimatedMealName
        self.confirmedCarbs = confirmedCarbs
        self.carbsRangeLow = carbsRangeLow
        self.carbsRangeHigh = carbsRangeHigh
        self.suggestedDose = suggestedDose
        self.glucoseValue = glucoseValue
        self.activeInsulin = activeInsulin
        self.notes = notes
        self.usefulness = usefulness
    }
}
