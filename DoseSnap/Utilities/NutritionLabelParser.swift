import Foundation

enum NutritionLabelParser {
    static func extractCarbsPer100g(from recognizedText: String) -> Double? {
        let lines = recognizedText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for line in lines {
            let normalized = line.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).lowercased()

            guard normalized.contains("glucide") ||
                  normalized.contains("carbohydrate") ||
                  normalized.contains("carbs") else {
                continue
            }

            guard !normalized.contains("dont sucres"),
                  !normalized.contains("sugars"),
                  !normalized.contains("fiber"),
                  !normalized.contains("fibre") else {
                continue
            }

            if let value = firstNumber(in: normalized) {
                return value
            }
        }

        return nil
    }

    private static func firstNumber(in text: String) -> Double? {
        let pattern = #"(\d+(?:[\.,]\d+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return Double(text[range].replacingOccurrences(of: ",", with: "."))
    }
}
