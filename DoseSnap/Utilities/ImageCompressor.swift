import UIKit

enum ImageCompressor {
    static let defaultMaxDimension: CGFloat = 1_280
    static let defaultJPEGQuality: CGFloat = 0.82

    static func compressedJPEGData(
        from data: Data,
        maxDimension: CGFloat = defaultMaxDimension,
        quality: CGFloat = defaultJPEGQuality
    ) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return compressedJPEGData(from: image, maxDimension: maxDimension, quality: quality)
    }

    static func compressedJPEGData(
        from image: UIImage,
        maxDimension: CGFloat = defaultMaxDimension,
        quality: CGFloat = defaultJPEGQuality
    ) -> Data? {
        let targetSize = scaledSize(for: image.size, maxDimension: maxDimension)
        guard targetSize.width > 0, targetSize.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let renderedImage = renderer.image { context in
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return renderedImage.jpegData(compressionQuality: quality)
    }

    private static func scaledSize(for originalSize: CGSize, maxDimension: CGFloat) -> CGSize {
        let width = originalSize.width
        let height = originalSize.height
        guard width > 0, height > 0, maxDimension > 0 else { return .zero }

        let longestSide = max(width, height)
        guard longestSide > maxDimension else {
            return CGSize(width: width.rounded(), height: height.rounded())
        }

        let scale = maxDimension / longestSide
        return CGSize(
            width: max(1, (width * scale).rounded()),
            height: max(1, (height * scale).rounded())
        )
    }
}
