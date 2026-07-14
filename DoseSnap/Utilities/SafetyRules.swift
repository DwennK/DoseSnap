import Foundation

enum SafetyWarningSeverity: String, Codable {
    case info
    case caution
    case critical
}

struct SafetyWarning: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var message: String
    var severity: SafetyWarningSeverity
}

enum SafetyRules {
    static func profileWarnings(_ profile: UserProfile) -> [SafetyWarning] {
        var warnings: [SafetyWarning] = []

        if !profile.isComplete {
            warnings.append(
                SafetyWarning(
                    title: "Profil incomplet",
                    message: "Complétez vos réglages personnels avant d'afficher une suggestion indicative.",
                    severity: .critical
                )
            )
        }

        return warnings + InputValidationRules.profileWarnings(profile)
    }

    static func warnings(
        analysis: FoodAnalysis?,
        carbs: Double,
        glucose: Double?,
        profile: UserProfile,
        calculation: BolusCalculationResult?,
        activeInsulin: Double = 0,
        beverageInput: BeverageInput? = nil
    ) -> [SafetyWarning] {
        var warnings = profileWarnings(profile)

        warnings.append(contentsOf: InputValidationRules.entryWarnings(
            carbs: carbs,
            glucose: glucose,
            glucoseUnit: profile.glucoseUnit,
            activeInsulin: activeInsulin,
            beverageInput: beverageInput
        ))

        if carbs > 150 {
            warnings.append(
                SafetyWarning(
                    title: "Glucides élevés",
                    message: "L'estimation dépasse 150 g. Pesez le repas ou validez manuellement les portions.",
                    severity: .caution
                )
            )
        }

        if let analysis {
            if analysis.confidence < 0.55 {
                warnings.append(
                    SafetyWarning(
                        title: "Photo incertaine",
                        message: "Photo incertaine. Pesez ou estimez manuellement le repas.",
                        severity: .critical
                    )
                )
            }

            if !analysis.isLikelyFood {
                warnings.append(
                    SafetyWarning(
                        title: "Aliment non confirmé",
                        message: "La photo ne semble pas montrer clairement un aliment. Entrez les glucides manuellement.",
                        severity: .critical
                    )
                )
            }

            if containsBeverageKeyword(analysis), beverageInput == nil {
                warnings.append(
                    SafetyWarning(
                        title: "Boisson à vérifier",
                        message: "Une boisson sucrée, un jus, un café sucré ou un alcool peut être mal estimé sur photo. Ajoutez-la manuellement si elle fait partie du repas.",
                        severity: .caution
                    )
                )
            }
        }

        switch profile.calibrationStatus {
        case .unavailable:
            break
        case .coherent(let factor):
            if factor != 1 {
                warnings.append(
                    SafetyWarning(
                        title: "Calibration appliquée",
                        message: "Vos réponses de calibration ajustent légèrement l'estimation. Vérifiez quand même les glucides.",
                        severity: .info
                    )
                )
            }
        case .needsReview:
            warnings.append(
                SafetyWarning(
                    title: "Calibration incohérente",
                    message: "Vos réponses semblent incohérentes avec votre ratio. Vérifiez vos réglages avant de vous fier à cette estimation.",
                    severity: .caution
                )
            )
        }

        if let glucose {
            if glucose <= profile.glucoseUnit.veryLowThreshold {
                warnings.append(
                    SafetyWarning(
                        title: "Glycémie très basse",
                        message: "La glycémie saisie est basse. Vérifiez vos consignes médicales avant toute correction.",
                        severity: .critical
                    )
                )
            }

            if glucose >= profile.glucoseUnit.veryHighThreshold {
                warnings.append(
                    SafetyWarning(
                        title: "Glycémie très haute",
                        message: "La glycémie saisie est très haute. Confirmez avec vos réglages médicaux et votre plan de soins.",
                        severity: .critical
                    )
                )
            }
        }

        if calculation?.wasLimitedByMaximum == true {
            warnings.append(
                SafetyWarning(
                    title: "Limite appliquée",
                    message: "La suggestion calculée dépassait votre dose maximale par suggestion. La limite de sécurité a été appliquée.",
                    severity: .critical
                )
            )
        }

        return warnings
    }

    static func shouldBlockSuggestion(profile: UserProfile, analysis: FoodAnalysis?, glucose: Double? = nil) -> Bool {
        if !profile.isComplete || analysis?.isLikelyFood == false {
            return true
        }

        if let glucose, glucose <= profile.glucoseUnit.veryLowThreshold {
            return true
        }

        return false
    }

    static func shouldBlockSuggestion(
        profile: UserProfile,
        analysis: FoodAnalysis?,
        carbs: Double,
        glucose: Double? = nil,
        activeInsulin: Double = 0,
        beverageInput: BeverageInput? = nil
    ) -> Bool {
        shouldBlockSuggestion(profile: profile, analysis: analysis, glucose: glucose) ||
        InputValidationRules.hasBlockingWarnings(
            profile: profile,
            carbs: carbs,
            glucose: glucose,
            glucoseUnit: profile.glucoseUnit,
            activeInsulin: activeInsulin,
            beverageInput: beverageInput
        )
    }

    static func shouldBlockSave(profile: UserProfile, analysis: FoodAnalysis?, glucose: Double? = nil, hasVerifiedCarbs: Bool) -> Bool {
        shouldBlockSuggestion(profile: profile, analysis: analysis, glucose: glucose) || !hasVerifiedCarbs
    }

    static func shouldBlockSave(
        profile: UserProfile,
        analysis: FoodAnalysis?,
        carbs: Double,
        glucose: Double? = nil,
        activeInsulin: Double = 0,
        beverageInput: BeverageInput? = nil,
        hasVerifiedCarbs: Bool
    ) -> Bool {
        shouldBlockSuggestion(
            profile: profile,
            analysis: analysis,
            carbs: carbs,
            glucose: glucose,
            activeInsulin: activeInsulin,
            beverageInput: beverageInput
        ) || !hasVerifiedCarbs
    }

    static func blockingSuggestionWarning(profile: UserProfile, analysis: FoodAnalysis?, glucose: Double?) -> SafetyWarning? {
        if !profile.isComplete {
            return SafetyWarning(
                title: "Profil incomplet",
                message: "Complétez vos réglages personnels avant d'afficher une suggestion indicative.",
                severity: .critical
            )
        }

        if analysis?.isLikelyFood == false {
            return SafetyWarning(
                title: "Aliment non confirmé",
                message: "Entrez les glucides manuellement ou reprenez une photo claire avant d'afficher une suggestion.",
                severity: .critical
            )
        }

        if let glucose, glucose <= profile.glucoseUnit.veryLowThreshold {
            return SafetyWarning(
                title: "Suggestion masquée",
                message: "Glycémie basse détectée. L'app masque toute suggestion chiffrée. Suivez vos consignes médicales avant toute décision.",
                severity: .critical
            )
        }

        return nil
    }

    private static func containsBeverageKeyword(_ analysis: FoodAnalysis) -> Bool {
        let text = analysis.detectedItems
            .map(\.name)
            .joined(separator: " ")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        let keywords = [
            "soda",
            "coca",
            "cola",
            "jus",
            "juice",
            "boisson",
            "drink",
            "cafe sucre",
            "latte",
            "milkshake",
            "biere",
            "beer",
            "vin",
            "wine",
            "alcool",
            "alcohol"
        ]

        return keywords.contains { text.contains($0) }
    }
}
