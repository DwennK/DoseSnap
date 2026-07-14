import Combine
import UIKit

@MainActor
final class NutritionPackageViewModel: ObservableObject {
    @Published var barcode = ""
    @Published var productName = ""
    @Published var basis: NutritionCarbBasis = .per100g
    @Published var carbsPer100gText = ""
    @Published var portionGramsText = ""
    @Published var carbsPerServingText = ""
    @Published var servingCountText = "1"
    @Published var labelImage: UIImage?
    @Published var recognizedText = ""
    @Published var statusMessage: String?
    @Published var isReadingLabel = false
    @Published var isLookingUpBarcode = false

    private let calculator = NutritionCarbCalculator()
    private let ocrService = NutritionLabelOCRService()
    private let productLookupService: any ProductNutritionLookupService

    init(productLookupService: any ProductNutritionLookupService = OpenFoodFactsProductNutritionLookupService()) {
        self.productLookupService = productLookupService
    }

    var calculatedCarbs: Double? {
        try? calculator.calculate(input)
    }

    var displayName: String {
        let trimmed = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Emballage nutritionnel" : trimmed
    }

    var canCreateResult: Bool {
        calculatedCarbs != nil
    }

    var input: NutritionPackageInput {
        NutritionPackageInput(
            basis: basis,
            carbsPer100g: Self.parseNumber(carbsPer100gText),
            portionGrams: Self.parseNumber(portionGramsText),
            carbsPerServing: Self.parseNumber(carbsPerServingText),
            servingCount: Self.parseNumber(servingCountText)
        )
    }

    func setBarcode(_ value: String) async {
        barcode = value
        await lookupProduct(for: value)
    }

    func setLabelImageData(_ data: Data?) async {
        guard let data, let compressedData = ImageCompressor.compressedJPEGData(from: data), let image = UIImage(data: compressedData) else {
            statusMessage = "Image d'etiquette indisponible."
            return
        }

        await readLabel(from: image)
    }

    func setLabelImage(_ image: UIImage) async {
        guard let compressedData = ImageCompressor.compressedJPEGData(from: image),
              let compressedImage = UIImage(data: compressedData) else {
            statusMessage = "Image d'etiquette indisponible."
            return
        }

        await readLabel(from: compressedImage)
    }

    private func readLabel(from image: UIImage) async {
        labelImage = image
        isReadingLabel = true
        statusMessage = nil

        do {
            let text = try await ocrService.recognizeText(in: image)
            recognizedText = text

            if let carbs = NutritionLabelParser.extractCarbsPer100g(from: text) {
                basis = .per100g
                carbsPer100gText = carbs.formatted(.number.precision(.fractionLength(0...1)))
                statusMessage = "Glucides détectés sur l'étiquette. Vérifiez la valeur avant de continuer."
            } else {
                statusMessage = "Étiquette lue, mais glucides non détectés. Saisissez la valeur manuellement."
            }
        } catch {
            statusMessage = "Lecture étiquette impossible. Saisissez les glucides manuellement."
        }

        isReadingLabel = false
    }

    func apply(to scanViewModel: ScanViewModel, profile: UserProfile) {
        guard let carbs = calculatedCarbs else { return }
        let details = detailNote(carbs: carbs)
        scanViewModel.configureNutritionEntry(
            name: displayName,
            carbs: carbs,
            barcode: barcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : barcode,
            details: details
        )
        scanViewModel.recalculate(profile: profile)
    }

    private func lookupProduct(for value: String) async {
        let normalizedBarcode = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBarcode.isEmpty else {
            statusMessage = "Code-barres vide."
            return
        }

        isLookingUpBarcode = true
        statusMessage = "Recherche du produit..."

        do {
            let product = try await productLookupService.product(for: normalizedBarcode)
            apply(product)
        } catch ProductNutritionLookupError.productNotFound {
            statusMessage = "Produit introuvable. Scannez l'étiquette ou saisissez les glucides manuellement."
        } catch ProductNutritionLookupError.nutritionUnavailable {
            statusMessage = "Produit trouvé, mais glucides indisponibles. Scannez l'étiquette ou saisissez les valeurs."
        } catch {
            statusMessage = "Recherche produit impossible. Scannez l'étiquette ou saisissez les glucides manuellement."
        }

        isLookingUpBarcode = false
    }

    private func apply(_ product: ProductNutrition) {
        if let name = product.productName, productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            productName = name
        }

        if let carbsPer100g = product.carbsPer100g, let servingQuantityGrams = product.servingQuantityGrams, servingQuantityGrams > 0 {
            basis = .per100g
            carbsPer100gText = Self.formatNumber(carbsPer100g)
            portionGramsText = Self.formatNumber(servingQuantityGrams)
            statusMessage = "Produit trouvé. Glucides et portion pré-remplis depuis Open Food Facts ; vérifiez avant de continuer."
            return
        }

        if let carbsPerServing = product.carbsPerServing {
            basis = .perServing
            carbsPerServingText = Self.formatNumber(carbsPerServing)
            servingCountText = "1"
            statusMessage = "Produit trouvé. Glucides par portion pré-remplis depuis Open Food Facts ; vérifiez avant de continuer."
            return
        }

        if let carbsPer100g = product.carbsPer100g {
            basis = .per100g
            carbsPer100gText = Self.formatNumber(carbsPer100g)
            statusMessage = "Produit trouvé. Glucides / 100 g pré-remplis ; saisissez la portion consommée."
        }
    }

    private func detailNote(carbs: Double) -> String {
        switch basis {
        case .per100g:
            let carbsPer100g = carbsPer100gText.trimmingCharacters(in: .whitespacesAndNewlines)
            let portion = portionGramsText.trimmingCharacters(in: .whitespacesAndNewlines)
            return "Emballage: \(carbsPer100g) g glucides / 100 g, portion \(portion) g, total \(DoseFormatter.carbs(carbs))."
        case .perServing:
            let carbsPerServing = carbsPerServingText.trimmingCharacters(in: .whitespacesAndNewlines)
            let servingCount = servingCountText.trimmingCharacters(in: .whitespacesAndNewlines)
            return "Emballage: \(carbsPerServing) g glucides / portion, \(servingCount) portion(s), total \(DoseFormatter.carbs(carbs))."
        }
    }

    private static func parseNumber(_ text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !normalized.isEmpty else { return nil }
        return Double(normalized)
    }

    private static func formatNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
