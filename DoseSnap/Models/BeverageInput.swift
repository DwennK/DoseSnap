import Foundation

enum BeverageType: String, Codable, CaseIterable, Identifiable {
    case regularSoda
    case fruitJuice
    case sweetCoffee
    case milkDrink
    case beer
    case wine
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .regularSoda:
            "Soda sucre"
        case .fruitJuice:
            "Jus"
        case .sweetCoffee:
            "Cafe sucre"
        case .milkDrink:
            "Boisson lactee"
        case .beer:
            "Biere"
        case .wine:
            "Vin / alcool"
        case .custom:
            "Personnalise"
        }
    }

    var defaultCarbsPer100ml: Double {
        switch self {
        case .regularSoda:
            10.6
        case .fruitJuice:
            11
        case .sweetCoffee:
            8
        case .milkDrink:
            5
        case .beer:
            3.5
        case .wine:
            2
        case .custom:
            0
        }
    }

    var defaultVolumeMl: Double {
        switch self {
        case .wine:
            150
        case .sweetCoffee, .milkDrink:
            250
        default:
            330
        }
    }

    var isAlcoholic: Bool {
        switch self {
        case .beer, .wine:
            true
        default:
            false
        }
    }
}

struct BeverageInput: Equatable {
    var type: BeverageType
    var volumeMl: Double
    var customCarbsPer100ml: Double?

    var carbsPer100ml: Double {
        type == .custom ? customCarbsPer100ml ?? 0 : type.defaultCarbsPer100ml
    }

    var estimatedCarbs: Double {
        guard volumeMl > 0, carbsPer100ml >= 0 else { return 0 }
        return volumeMl * carbsPer100ml / 100
    }

    var displayName: String {
        "\(type.title) \(volumeMl.formatted(.number.precision(.fractionLength(0)))) ml"
    }
}
