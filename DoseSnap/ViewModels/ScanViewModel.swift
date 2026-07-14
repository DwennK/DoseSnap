import Foundation
import UIKit
import Combine

@MainActor
final class ScanViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedImageData: Data?
    @Published var analysis: FoodAnalysis?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    @Published var confirmedCarbsText = ""
    @Published var currentGlucoseText = ""
    @Published var activeInsulinText = ""
    @Published var isCorrectionEnabled = false
    @Published var inputGlucoseUnit: GlucoseUnit
    @Published var notes = ""
    @Published var calculation: BolusCalculationResult?
    @Published var safetyWarnings: [SafetyWarning] = []
    @Published var hasVerifiedCarbs = false
    @Published var photoQualityWarnings: [SafetyWarning] = []
    @Published var requiresPhotoQualityConfirmation = false
    @Published var includesBeverage = false
    @Published var beverageType: BeverageType = .regularSoda
    @Published var beverageVolumeText = ""
    @Published var beverageCustomCarbsPer100mlText = ""

    private let injectedFoodAnalysisService: (any FoodAnalysisService)?
    private let calculator = BolusCalculator()

    init(foodAnalysisService: (any FoodAnalysisService)? = nil, inputGlucoseUnit: GlucoseUnit = .milligramsPerDeciliter) {
        injectedFoodAnalysisService = foodAnalysisService
        self.inputGlucoseUnit = inputGlucoseUnit
    }

    var hasImage: Bool {
        selectedImageData != nil
    }

    var mealCarbs: Double {
        Self.parseNumber(confirmedCarbsText) ?? analysis?.totalCarbsMid ?? 0
    }

    var beverageInput: BeverageInput? {
        guard includesBeverage else { return nil }

        let volume = Self.parseNumber(beverageVolumeText) ?? beverageType.defaultVolumeMl
        let customCarbs = Self.parseNumber(beverageCustomCarbsPer100mlText)

        return BeverageInput(
            type: beverageType,
            volumeMl: volume,
            customCarbsPer100ml: customCarbs
        )
    }

    var beverageCarbs: Double {
        beverageInput?.estimatedCarbs ?? 0
    }

    var confirmedCarbs: Double {
        mealCarbs + beverageCarbs
    }

    var currentGlucose: Double? {
        guard isCorrectionEnabled, let value = Self.parseNumber(currentGlucoseText) else { return nil }
        return value
    }

    func currentGlucose(in profileUnit: GlucoseUnit) -> Double? {
        guard isCorrectionEnabled, let value = Self.parseNumber(currentGlucoseText) else { return nil }
        return inputGlucoseUnit.convertedValue(value, to: profileUnit)
    }

    var activeInsulin: Double {
        Self.parseNumber(activeInsulinText) ?? 0
    }

    func setImageData(_ data: Data?) {
        let compressedData = data.flatMap { ImageCompressor.compressedJPEGData(from: $0) } ?? data
        selectedImageData = compressedData

        if let compressedData {
            selectedImage = UIImage(data: compressedData)
        } else {
            selectedImage = nil
        }

        updatePhotoQualityReport()
        analysis = nil
        calculation = nil
        safetyWarnings = []
        hasVerifiedCarbs = false
        errorMessage = nil
    }

    func setCameraImage(_ image: UIImage) {
        let compressedData = ImageCompressor.compressedJPEGData(from: image)
        selectedImageData = compressedData
        selectedImage = compressedData.flatMap(UIImage.init(data:)) ?? image
        updatePhotoQualityReport()
        analysis = nil
        calculation = nil
        safetyWarnings = []
        hasVerifiedCarbs = false
        errorMessage = nil
    }

    func setIncludesBeverage(_ isIncluded: Bool) {
        includesBeverage = isIncluded
        hasVerifiedCarbs = false

        if isIncluded && beverageVolumeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            beverageVolumeText = beverageType.defaultVolumeMl.formatted(.number.precision(.fractionLength(0)))
        }
    }

    func setBeverageType(_ type: BeverageType) {
        beverageType = type
        hasVerifiedCarbs = false
        beverageVolumeText = type.defaultVolumeMl.formatted(.number.precision(.fractionLength(0)))

        if type != .custom {
            beverageCustomCarbsPer100mlText = ""
        }
    }

    func analyze(profile: UserProfile) async {
        guard selectedImageData != nil else {
            errorMessage = "Ajoutez une photo avant l'analyse."
            return
        }

        if requiresPhotoQualityConfirmation {
            errorMessage = "Qualité photo à vérifier. Reprenez la photo ou appuyez à nouveau pour analyser quand même."
            requiresPhotoQualityConfirmation = false
            return
        }

        isAnalyzing = true
        errorMessage = nil

        do {
            let service = injectedFoodAnalysisService ?? FoodAnalysisServiceFactory.makeService(for: profile)
            let rawAnalysis = try await service.analyze(imageData: selectedImageData)
            let adjusted = rawAnalysis.adjustedForCalibration(profile.calibrationStatus)
            analysis = adjusted
            confirmedCarbsText = adjusted.totalCarbsMid.formatted(.number.precision(.fractionLength(0)))
            hasVerifiedCarbs = false
            recalculate(profile: profile)
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }

    func configureManualEntry(carbs: Double = 45) {
        analysis = FoodAnalysis(
            detectedItems: [DetectedFoodItem(name: "Saisie manuelle", estimatedCarbs: carbs, confidence: 1)],
            totalCarbsLow: carbs,
            totalCarbsMid: carbs,
            totalCarbsHigh: carbs,
            confidence: 1,
            warnings: ["Glucides saisis manuellement. Vérifiez avec vos repères habituels."],
            explanation: "Aucune photo n'a été analysée pour cette entrée.",
            isLikelyFood: true
        )
        confirmedCarbsText = carbs.formatted(.number.precision(.fractionLength(0)))
        hasVerifiedCarbs = false
    }

    func configureNutritionEntry(name: String, carbs: Double, barcode: String?, details: String) {
        let barcodeSuffix = barcode.map { " Code-barres: \($0)." } ?? ""

        analysis = FoodAnalysis(
            detectedItems: [DetectedFoodItem(name: name, estimatedCarbs: carbs, confidence: 1)],
            totalCarbsLow: carbs,
            totalCarbsMid: carbs,
            totalCarbsHigh: carbs,
            confidence: 1,
            warnings: ["Valeurs issues de l'emballage. Vérifiez la portion et les glucides avant de sauvegarder."],
            explanation: "\(details)\(barcodeSuffix)",
            isLikelyFood: true
        )
        selectedImage = nil
        selectedImageData = nil
        confirmedCarbsText = carbs.formatted(.number.precision(.fractionLength(0...1)))
        hasVerifiedCarbs = false
        notes = details
    }

    func confirmPhotoQualityForAnalysis() {
        requiresPhotoQualityConfirmation = false
        errorMessage = nil
    }

    #if DEBUG
    func simulateSnickers(profile: UserProfile) {
        guard let snickers = MockFoodAnalysisService.mockResponses.first else { return }

        let adjusted = snickers.adjustedForCalibration(profile.calibrationStatus)
        analysis = adjusted
        selectedImage = nil
        selectedImageData = nil
        confirmedCarbsText = adjusted.totalCarbsMid.formatted(.number.precision(.fractionLength(0)))
        currentGlucoseText = ""
        isCorrectionEnabled = false
        inputGlucoseUnit = profile.glucoseUnit
        activeInsulinText = ""
        notes = ""
        hasVerifiedCarbs = false
        recalculate(profile: profile)
    }
    #endif

    func recalculate(profile: UserProfile) {
        if SafetyRules.shouldBlockSuggestion(
            profile: profile,
            analysis: analysis,
            carbs: confirmedCarbs,
            glucose: currentGlucose(in: profile.glucoseUnit),
            activeInsulin: activeInsulin,
            beverageInput: beverageInput
        ) {
            calculation = nil
            safetyWarnings = SafetyRules.warnings(
                analysis: analysis,
                carbs: confirmedCarbs,
                glucose: currentGlucose(in: profile.glucoseUnit),
                profile: profile,
                calculation: nil,
                activeInsulin: activeInsulin,
                beverageInput: beverageInput
            )
            return
        }

        let input = BolusInput(
            estimatedCarbs: confirmedCarbs,
            currentGlucose: currentGlucose(in: profile.glucoseUnit),
            glucoseUnit: profile.glucoseUnit,
            insulinToCarbRatio: profile.insulinToCarbRatio,
            correctionFactor: profile.correctionFactor,
            targetGlucose: profile.targetGlucose,
            activeInsulin: activeInsulin,
            maximumDose: profile.maxSuggestedDose,
            roundingIncrement: profile.roundingIncrement
        )

        do {
            calculation = try calculator.calculate(input)
            errorMessage = nil
        } catch {
            calculation = nil
            errorMessage = "Impossible de calculer la suggestion avec ces valeurs."
        }

        safetyWarnings = SafetyRules.warnings(
            analysis: analysis,
            carbs: confirmedCarbs,
            glucose: currentGlucose(in: profile.glucoseUnit),
            profile: profile,
            calculation: calculation,
            activeInsulin: activeInsulin,
            beverageInput: beverageInput
        )
    }

    func makeMealEntry(profile: UserProfile) -> MealEntry? {
        guard let calculation else { return nil }

        let rangeLow = analysis?.totalCarbsLow ?? confirmedCarbs
        let rangeHigh = analysis?.totalCarbsHigh ?? confirmedCarbs
        let name = analysis?.displayName.isEmpty == false ? analysis?.displayName ?? "Repas" : "Repas"

        return MealEntry(
            thumbnailData: selectedImage?.jpegData(compressionQuality: 0.35) ?? selectedImageData,
            estimatedMealName: name,
            confirmedCarbs: confirmedCarbs,
            carbsRangeLow: rangeLow,
            carbsRangeHigh: rangeHigh,
            suggestedDose: calculation.suggestedDose,
            glucoseValue: currentGlucose(in: profile.glucoseUnit),
            activeInsulin: activeInsulin > 0 ? activeInsulin : nil,
            notes: mealNotesWithBeverage()
        )
    }

    private func mealNotesWithBeverage() -> String {
        guard let beverageInput else { return notes }

        let beverageNote = "Boisson incluse: \(beverageInput.displayName), \(DoseFormatter.carbs(beverageInput.estimatedCarbs))."
        guard !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return beverageNote
        }

        return notes + "\n" + beverageNote
    }

    private func updatePhotoQualityReport() {
        guard let selectedImage else {
            photoQualityWarnings = []
            requiresPhotoQualityConfirmation = false
            return
        }

        let report = PhotoQualityAnalyzer.analyze(selectedImage)
        photoQualityWarnings = report.warnings
        requiresPhotoQualityConfirmation = report.requiresConfirmation
    }

    private static func parseNumber(_ text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !normalized.isEmpty else { return nil }
        return Double(normalized)
    }
}
