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
                    title: "Ratio à vérifier",
                    message: "Le ratio insuline/glucides semble hors plage habituelle. Vérifiez la valeur avant tout calcul.",
                    severity: .critical
                )
            )
        }

        if !profile.glucoseUnit.isPlausibleCorrectionFactor(profile.correctionFactor) {
            warnings.append(
                SafetyWarning(
                    title: "Facteur de correction à vérifier",
                    message: "Le facteur de correction semble incohérent pour l'unité choisie.",
                    severity: .critical
                )
            )
        }

        if !profile.glucoseUnit.isPlausibleTarget(profile.targetGlucose) {
            warnings.append(
                SafetyWarning(
                    title: "Cible glycémie à vérifier",
                    message: "La cible glycémie semble hors plage plausible pour l'unité choisie.",
                    severity: .critical
                )
            )
        }

        if !profile.maxSuggestedDose.isFinite ||
            profile.maxSuggestedDose <= 0 ||
            profile.maxSuggestedDose > maximumPlausibleDoseLimit {
            warnings.append(
                SafetyWarning(
                    title: "Limite de dose à vérifier",
                    message: "La dose maximale par suggestion est très élevée. Réduisez-la ou confirmez vos réglages médicaux.",
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
                    title: "Glucides à vérifier",
                    message: "La valeur saisie dépasse \(DoseFormatter.carbs(maximumPlausibleCarbs)). L'app bloque la suggestion jusqu'à correction.",
                    severity: .critical
                )
            )
        }

        if let glucose, !glucoseUnit.isPlausibleGlucose(glucose) {
            warnings.append(
                SafetyWarning(
                    title: "Glycémie à vérifier",
                    message: "La glycémie saisie semble hors plage plausible. Vérifiez l'unité et la valeur.",
                    severity: .critical
                )
            )
        }

        if activeInsulin > maximumPlausibleActiveInsulin {
            warnings.append(
                SafetyWarning(
                    title: "Insuline active à vérifier",
                    message: "L'insuline active saisie semble très élevée. Vérifiez la valeur avant le calcul.",
                    severity: .critical
                )
            )
        }

        if let beverageInput {
            if beverageInput.volumeMl > maximumPlausibleBeverageVolumeMl {
                warnings.append(
                    SafetyWarning(
                        title: "Volume boisson à vérifier",
                        message: "Le volume de boisson saisi semble trop élevé. Vérifiez les millilitres.",
                        severity: .critical
                    )
                )
            }

            if beverageInput.estimatedCarbs > maximumPlausibleBeverageCarbs {
                warnings.append(
                    SafetyWarning(
                        title: "Boisson très sucrée",
                        message: "Les glucides de la boisson sont très élevés. Vérifiez l'étiquette, le volume et l'unité.",
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
