import Foundation

enum InputValidationRules {
    static let maximumPlausibleCarbs = 350.0
    static let maximumPlausibleBeverageCarbs = 120.0
    static let maximumPlausibleBeverageVolumeMl = 2_000.0
    static let minimumPlausibleInsulinToCarbRatio = 2.0
    static let maximumPlausibleInsulinToCarbRatio = 80.0
    static let maximumPlausibleActiveInsulin = 30.0
    static let maximumPlausibleDoseLimit = 80.0

    static func profileWarnings(_ profile: UserProfile) -> [SafetyWarning] {
        var warnings: [SafetyWarning] = []

        if !profile.insulinToCarbRatio.isFinite ||
            profile.insulinToCarbRatio < minimumPlausibleInsulinToCarbRatio ||
            profile.insulinToCarbRatio > maximumPlausibleInsulinToCarbRatio {
            warnings.append(
                SafetyWarning(
                    title: "Ratio a verifier",
                    message: "Le ratio insuline/glucides semble hors plage habituelle. Verifiez la valeur avant tout calcul.",
                    severity: .critical
                )
            )
        }

        if !profile.glucoseUnit.isPlausibleCorrectionFactor(profile.correctionFactor) {
            warnings.append(
                SafetyWarning(
                    title: "Facteur de correction a verifier",
                    message: "Le facteur de correction semble incoherent pour l'unite choisie.",
                    severity: .critical
                )
            )
        }

        if !profile.glucoseUnit.isPlausibleTarget(profile.targetGlucose) {
            warnings.append(
                SafetyWarning(
                    title: "Cible glycemie a verifier",
                    message: "La cible glycemie semble hors plage plausible pour l'unite choisie.",
                    severity: .critical
                )
            )
        }

        if !profile.maxSuggestedDose.isFinite ||
            profile.maxSuggestedDose <= 0 ||
            profile.maxSuggestedDose > maximumPlausibleDoseLimit {
            warnings.append(
                SafetyWarning(
                    title: "Limite de dose a verifier",
                    message: "La dose maximale par suggestion est tres elevee. Reduisez-la ou confirmez vos reglages medicaux.",
                    severity: .critical
                )
            )
        }

        return warnings
    }

    static func entryWarnings(
        carbs: Double,
        glucose: Double?,
        glucoseUnit: GlucoseUnit,
        activeInsulin: Double,
        beverageInput: BeverageInput?
    ) -> [SafetyWarning] {
        var warnings: [SafetyWarning] = []

        if carbs > maximumPlausibleCarbs {
            warnings.append(
                SafetyWarning(
                    title: "Glucides a verifier",
                    message: "La valeur saisie depasse \(DoseFormatter.carbs(maximumPlausibleCarbs)). L'app bloque la suggestion jusqu'a correction.",
                    severity: .critical
                )
            )
        }

        if let glucose, !glucoseUnit.isPlausibleGlucose(glucose) {
            warnings.append(
                SafetyWarning(
                    title: "Glycemie a verifier",
                    message: "La glycemie saisie semble hors plage plausible. Verifiez l'unite et la valeur.",
                    severity: .critical
                )
            )
        }

        if activeInsulin > maximumPlausibleActiveInsulin {
            warnings.append(
                SafetyWarning(
                    title: "Insuline active a verifier",
                    message: "L'insuline active saisie semble tres elevee. Verifiez la valeur avant le calcul.",
                    severity: .critical
                )
            )
        }

        if let beverageInput {
            if beverageInput.volumeMl > maximumPlausibleBeverageVolumeMl {
                warnings.append(
                    SafetyWarning(
                        title: "Volume boisson a verifier",
                        message: "Le volume de boisson saisi semble trop eleve. Verifiez les millilitres.",
                        severity: .critical
                    )
                )
            }

            if beverageInput.estimatedCarbs > maximumPlausibleBeverageCarbs {
                warnings.append(
                    SafetyWarning(
                        title: "Boisson tres sucree",
                        message: "Les glucides de la boisson sont tres eleves. Verifiez l'etiquette, le volume et l'unite.",
                        severity: .critical
                    )
                )
            }
        }

        return warnings
    }

    static func hasBlockingWarnings(
        profile: UserProfile,
        carbs: Double,
        glucose: Double?,
        glucoseUnit: GlucoseUnit,
        activeInsulin: Double,
        beverageInput: BeverageInput?
    ) -> Bool {
        let warnings = profileWarnings(profile) + entryWarnings(
            carbs: carbs,
            glucose: glucose,
            glucoseUnit: glucoseUnit,
            activeInsulin: activeInsulin,
            beverageInput: beverageInput
        )

        return warnings.contains { $0.severity == .critical }
    }
}
