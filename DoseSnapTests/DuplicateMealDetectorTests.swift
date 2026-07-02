import XCTest
@testable import DoseSnap

final class DuplicateMealDetectorTests: XCTestCase {
    func testDetectsSameMealWithinTwoMinutes() {
        let now = Date()
        let existing = meal(name: "Snickers standard", carbs: 33, date: now.addingTimeInterval(-60))
        let candidate = meal(name: "snickers standard", carbs: 36, date: now)

        let duplicate = DuplicateMealDetector.likelyDuplicate(of: candidate, in: [existing])

        XCTAssertEqual(duplicate?.id, existing.id)
    }

    func testIgnoresMealOutsideWindow() {
        let now = Date()
        let existing = meal(name: "Snickers standard", carbs: 33, date: now.addingTimeInterval(-180))
        let candidate = meal(name: "Snickers standard", carbs: 33, date: now)

        XCTAssertNil(DuplicateMealDetector.likelyDuplicate(of: candidate, in: [existing]))
    }

    func testIgnoresDifferentCarbs() {
        let now = Date()
        let existing = meal(name: "Pizza moyenne", carbs: 120, date: now.addingTimeInterval(-30))
        let candidate = meal(name: "Pizza moyenne", carbs: 40, date: now)

        XCTAssertNil(DuplicateMealDetector.likelyDuplicate(of: candidate, in: [existing]))
    }

    private func meal(name: String, carbs: Double, date: Date) -> MealEntry {
        MealEntry(
            id: UUID(),
            date: date,
            thumbnailData: nil,
            estimatedMealName: name,
            confirmedCarbs: carbs,
            carbsRangeLow: carbs,
            carbsRangeHigh: carbs,
            suggestedDose: carbs / 10,
            glucoseValue: nil,
            activeInsulin: nil,
            notes: ""
        )
    }
}
