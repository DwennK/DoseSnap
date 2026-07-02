import UIKit
import Vision

struct PhotoQualityReport: Equatable {
    var warnings: [SafetyWarning]

    var requiresConfirmation: Bool {
        !warnings.isEmpty
    }
}

enum PhotoQualityAnalyzer {
    static func analyze(_ image: UIImage) -> PhotoQualityReport {
        var warnings: [SafetyWarning] = []

        if let metrics = ImageMetrics(image: image) {
            if metrics.averageLuminance < 0.16 {
                warnings.append(
                    SafetyWarning(
                        title: "Photo trop sombre",
                        message: "La photo semble sombre. Reprenez-la avec plus de lumiere ou confirmez avant d'envoyer l'image.",
                        severity: .caution
                    )
                )
            }

            if metrics.sharpnessScore < 0.018 {
                warnings.append(
                    SafetyWarning(
                        title: "Photo possiblement floue",
                        message: "Les contours semblent peu nets. Une photo floue peut produire une estimation de glucides peu fiable.",
                        severity: .caution
                    )
                )
            }
        }

        if let subjectAreaRatio = salientSubjectAreaRatio(in: image), subjectAreaRatio < 0.08 {
            warnings.append(
                SafetyWarning(
                    title: "Repas trop petit dans l'image",
                    message: "Le sujet principal occupe peu de place. Rapprochez-vous du repas pour limiter les erreurs d'estimation.",
                    severity: .caution
                )
            )
        }

        return PhotoQualityReport(warnings: warnings)
    }

    private static func salientSubjectAreaRatio(in image: UIImage) -> CGFloat? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNGenerateAttentionBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImagePropertyOrientation)

        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let observation = request.results?.first,
              let object = observation.salientObjects?.max(by: { $0.boundingBox.area < $1.boundingBox.area }) else {
            return nil
        }

        return object.boundingBox.area
    }
}

private struct ImageMetrics {
    var averageLuminance: CGFloat
    var sharpnessScore: CGFloat

    init?(image: UIImage, sampleSize: Int = 64) {
        guard let cgImage = image.cgImage, sampleSize > 2 else { return nil }

        let width = sampleSize
        let height = sampleSize
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .low
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var luminance = [CGFloat](repeating: 0, count: width * height)
        var total: CGFloat = 0

        for index in 0..<(width * height) {
            let offset = index * bytesPerPixel
            let red = CGFloat(pixels[offset]) / 255
            let green = CGFloat(pixels[offset + 1]) / 255
            let blue = CGFloat(pixels[offset + 2]) / 255
            let value = 0.2126 * red + 0.7152 * green + 0.0722 * blue
            luminance[index] = value
            total += value
        }

        var gradientTotal: CGFloat = 0
        var gradientCount: CGFloat = 0

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let center = y * width + x
                let dx = luminance[center + 1] - luminance[center - 1]
                let dy = luminance[center + width] - luminance[center - width]
                gradientTotal += abs(dx) + abs(dy)
                gradientCount += 1
            }
        }

        averageLuminance = total / CGFloat(width * height)
        sharpnessScore = gradientCount > 0 ? gradientTotal / gradientCount : 0
    }
}

private extension CGRect {
    var area: CGFloat {
        width * height
    }
}

private extension UIImage {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up:
            .up
        case .upMirrored:
            .upMirrored
        case .down:
            .down
        case .downMirrored:
            .downMirrored
        case .left:
            .left
        case .leftMirrored:
            .leftMirrored
        case .right:
            .right
        case .rightMirrored:
            .rightMirrored
        @unknown default:
            .up
        }
    }
}
