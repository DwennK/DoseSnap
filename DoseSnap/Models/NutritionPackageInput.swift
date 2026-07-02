import Foundation

enum NutritionCarbBasis: String, CaseIterable, Identifiable {
    case per100g
    case perServing

    var id: String { rawValue }

    var title: String {
        switch self {
        case .per100g:
            "Pour 100 g"
        case .perServing:
            "Par portion"
        }
    }
}

struct NutritionPackageInput: Equatable {
    var basis: NutritionCarbBasis
    var carbsPer100g: Double?
    var portionGrams: Double?
    var carbsPerServing: Double?
    var servingCount: Double?
}
