import XCTest
import UIKit
@testable import DoseSnap

final class ImageCompressorTests: XCTestCase {
    func testCompressesLargeImageToConfiguredMaximumDimension() {
        let image = makeImage(size: CGSize(width: 2_400, height: 1_200))

        let data = ImageCompressor.compressedJPEGData(from: image, maxDimension: 1_280, quality: 0.82)

        XCTAssertNotNil(data)
        let decoded = data.flatMap(UIImage.init(data:))
        XCTAssertEqual(decoded?.size.width ?? 0, 1_280, accuracy: 1)
        XCTAssertEqual(decoded?.size.height ?? 0, 640, accuracy: 1)
    }

    func testKeepsSmallImageDimensions() {
        let image = makeImage(size: CGSize(width: 640, height: 480))

        let data = ImageCompressor.compressedJPEGData(from: image, maxDimension: 1_280, quality: 0.82)

        let decoded = data.flatMap(UIImage.init(data:))
        XCTAssertEqual(decoded?.size.width ?? 0, 640, accuracy: 1)
        XCTAssertEqual(decoded?.size.height ?? 0, 480, accuracy: 1)
    }

    private func makeImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.systemGreen.setFill()
            context.fill(CGRect(x: size.width * 0.25, y: size.height * 0.25, width: size.width * 0.5, height: size.height * 0.5))
        }
    }
}
