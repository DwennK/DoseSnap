import Foundation

enum ProductNutritionLookupError: Error, Equatable {
    case invalidBarcode
    case productNotFound
    case nutritionUnavailable
    case invalidResponse
}

protocol ProductNutritionLookupService {
    func product(for barcode: String) async throws -> ProductNutrition
}

struct OpenFoodFactsProductNutritionLookupService: ProductNutritionLookupService {
    private let baseURL: URL
    private let urlSession: URLSession

    init(
        baseURL: URL = URL(string: "https://world.openfoodfacts.org")!,
        urlSession: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
    }

    func product(for barcode: String) async throws -> ProductNutrition {
        let normalizedBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedBarcode.isEmpty else { throw ProductNutritionLookupError.invalidBarcode }

        var components = URLComponents(
            url: baseURL
                .appendingPathComponent("api")
                .appendingPathComponent("v2")
                .appendingPathComponent("product")
                .appendingPathComponent(normalizedBarcode),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(
                name: "fields",
                value: [
                    "product_name",
                    "product_name_fr",
                    "generic_name",
                    "generic_name_fr",
                    "nutriments",
                    "serving_quantity",
                    "serving_size"
                ].joined(separator: ",")
            )
        ]

        guard let url = components?.url else { throw ProductNutritionLookupError.invalidBarcode }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.setValue("DoseSnap/1.0 (iOS; product nutrition lookup)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw ProductNutritionLookupError.invalidResponse
        }

        let dto = try JSONDecoder().decode(OpenFoodFactsProductResponse.self, from: data)
        guard dto.status == 1, let product = dto.product else {
            throw ProductNutritionLookupError.productNotFound
        }

        let nutrition = product.nutrition(barcode: normalizedBarcode)
        guard nutrition.carbsPer100g != nil || nutrition.carbsPerServing != nil else {
            throw ProductNutritionLookupError.nutritionUnavailable
        }

        return nutrition
    }
}

private struct OpenFoodFactsProductResponse: Decodable {
    var status: Int
    var product: OpenFoodFactsProduct?
}

private struct OpenFoodFactsProduct: Decodable {
    var productName: String?
    var productNameFr: String?
    var genericName: String?
    var genericNameFr: String?
    var servingQuantity: FlexibleDouble?
    var servingSize: String?
    var nutriments: OpenFoodFactsNutriments?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case productNameFr = "product_name_fr"
        case genericName = "generic_name"
        case genericNameFr = "generic_name_fr"
        case servingQuantity = "serving_quantity"
        case servingSize = "serving_size"
        case nutriments
    }

    func nutrition(barcode: String) -> ProductNutrition {
        ProductNutrition(
            barcode: barcode,
            productName: preferredName,
            carbsPer100g: nutriments?.carbohydrates100g?.value,
            servingQuantityGrams: servingQuantity?.value ?? Self.firstNumber(in: servingSize),
            carbsPerServing: nutriments?.carbohydratesServing?.value
        )
    }

    private var preferredName: String? {
        [productNameFr, productName, genericNameFr, genericName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    private static func firstNumber(in text: String?) -> Double? {
        guard let text,
              let range = text.range(
                of: #"[-+]?\d+([,.]\d+)?"#,
                options: .regularExpression
              ) else {
            return nil
        }

        return Double(text[range].replacingOccurrences(of: ",", with: "."))
    }
}

private struct OpenFoodFactsNutriments: Decodable {
    var carbohydrates100g: FlexibleDouble?
    var carbohydratesServing: FlexibleDouble?

    enum CodingKeys: String, CodingKey {
        case carbohydrates100g = "carbohydrates_100g"
        case carbohydratesServing = "carbohydrates_serving"
    }
}

private struct FlexibleDouble: Decodable, Equatable {
    var value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(Double.self) {
            self.value = value
            return
        }

        if let string = try? container.decode(String.self) {
            let normalized = string
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")

            if let value = Double(normalized) {
                self.value = value
                return
            }
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Expected a numeric value."
        )
    }
}
