import UIKit
@preconcurrency import Vision

enum NutritionLabelOCRError: Error {
    case imageUnavailable
    case recognitionFailed
}

struct NutritionLabelOCRService {
    func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw NutritionLabelOCRError.imageUnavailable }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let text = request.results?
                    .compactMap { $0 as? VNRecognizedTextObservation }
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""

                guard !text.isEmpty else {
                    continuation.resume(throwing: NutritionLabelOCRError.recognitionFailed)
                    return
                }

                continuation.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["fr-FR", "en-US"]

            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage)

                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
