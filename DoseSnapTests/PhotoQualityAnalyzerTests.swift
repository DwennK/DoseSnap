import XCTest
import UIKit
@testable import DoseSnap

final class PhotoQualityAnalyzerTests: XCTestCase {
    func testWarnsForDarkPhoto() {
        let image = makeImage(size: CGSize(width: 320, height: 240), color: .black)

        let report = PhotoQualityAnalyzer.analyze(image)

        XCTAssertTrue(report.warnings.contains { $0.title == "Photo trop sombre" })
        XCTAssertTrue(report.requiresConfirmation)
    }

    private func makeImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
