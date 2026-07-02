import Foundation

enum NutritionCarbCalculatorError: Error, Equatable {
    case missingCarbsPer100g
    case missingPortionGrams
    case missingCarbsPerServing
    case missingServingCount
    case invalidValue
}

struct NutritionCarbCalculator {
    func calculate(_ input: NutritionPackageInput) throws -> Double {
        switch input.basis {
        case .per100g:
            guard let carbsPer100g = input.carbsPer100g else { throw NutritionCarbCalculatorError.missingCarbsPer100g }
            guard let portionGrams = input.portionGrams else { throw NutritionCarbCalculatorError.missingPortionGrams }
            guard carbsPer100g >= 0, portionGrams > 0 else { throw NutritionCarbCalculatorError.invalidValue }
            return carbsPer100g * portionGrams / 100

        case .perServing:
            guard let carbsPerServing = input.carbsPerServing else { throw NutritionCarbCalculatorError.missingCarbsPerServing }
            guard let servingCount = input.servingCount else { throw NutritionCarbCalculatorError.missingServingCount }
            guard carbsPerServing >= 0, servingCount > 0 else { throw NutritionCarbCalculatorError.invalidValue }
            return carbsPerServing * servingCount
        }
    }
}
