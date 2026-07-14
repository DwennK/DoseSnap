import XCTest
@testable import DoseSnap

@MainActor
final class NutritionPackageViewModelTests: XCTestCase {
    func testScannedBarcodePrefillsProductNutrition() async {
        let viewModel = NutritionPackageViewModel(
            productLookupService: StubProductNutritionLookupService(
                result: .success(
                    ProductNutrition(
                        barcode: "3017624010701",
                        productName: "Pate a tartiner",
                        carbsPer100g: 57.5,
                        servingQuantityGrams: 15,
                        carbsPerServing: nil
                    )
                )
            )
        )

        await viewModel.setBarcode("3017624010701")

        XCTAssertEqual(viewModel.barcode, "3017624010701")
        XCTAssertEqual(viewModel.productName, "Pate a tartiner")
        XCTAssertEqual(viewModel.basis, .per100g)
        XCTAssertEqual(viewModel.input.carbsPer100g ?? 0, 57.5, accuracy: 0.001)
        XCTAssertEqual(viewModel.portionGramsText, "15")
        XCTAssertEqual(viewModel.calculatedCarbs ?? 0, 8.625, accuracy: 0.001)
        XCTAssertEqual(viewModel.isLookingUpBarcode, false)
    }

    func testScannedBarcodeKeepsManualFallbackWhenProductIsMissing() async {
        let viewModel = NutritionPackageViewModel(
            productLookupService: StubProductNutritionLookupService(
                result: .failure(ProductNutritionLookupError.productNotFound)
            )
        )

        await viewModel.setBarcode("0000000000000")

        XCTAssertEqual(viewModel.barcode, "0000000000000")
        XCTAssertEqual(viewModel.productName, "")
        XCTAssertNil(viewModel.calculatedCarbs)
        XCTAssertEqual(viewModel.isLookingUpBarcode, false)
        XCTAssertEqual(viewModel.statusMessage, "Produit introuvable. Scannez l'étiquette ou saisissez les glucides manuellement.")
    }

    func testScannedBarcodeUsesServingCarbsWhenServingQuantityIsMissing() async {
        let viewModel = NutritionPackageViewModel(
            productLookupService: StubProductNutritionLookupService(
                result: .success(
                    ProductNutrition(
                        barcode: "1234567890123",
                        productName: "Barre cereales",
                        carbsPer100g: 62,
                        servingQuantityGrams: nil,
                        carbsPerServing: 18
                    )
                )
            )
        )

        await viewModel.setBarcode("1234567890123")

        XCTAssertEqual(viewModel.basis, .perServing)
        XCTAssertEqual(viewModel.input.carbsPerServing ?? 0, 18, accuracy: 0.001)
        XCTAssertEqual(viewModel.input.servingCount ?? 0, 1, accuracy: 0.001)
        XCTAssertEqual(viewModel.calculatedCarbs ?? 0, 18, accuracy: 0.001)
    }
}

private struct StubProductNutritionLookupService: ProductNutritionLookupService {
    var result: Result<ProductNutrition, Error>

    func product(for barcode: String) async throws -> ProductNutrition {
        try result.get()
    }
}
