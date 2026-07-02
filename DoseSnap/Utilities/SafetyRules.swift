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
                    message: "Completez vos reglages personnels avant d'afficher une suggestion indicative.",
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
                    title: "Glucides eleves",
                    message: "L'estimation depasse 150 g. Pesez le repas ou validez manuellement les portions.",
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
                        title: "Aliment non confirme",
                        message: "La photo ne semble pas montrer clairement un aliment. Entrez les glucides manuellement.",
                        severity: .critical
                    )
                )
            }

            if containsBeverageKeyword(analysis), beverageInput == nil {
                warnings.append(
                    SafetyWarning(
                        title: "Boisson a verifier",
                        message: "Une boisson sucree, un jus, un cafe sucre ou un alcool peut etre mal estime sur photo. Ajoutez-la manuellement si elle fait partie du repas.",
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
                        title: "Calibration appliquee",
                        message: "Vos reponses de calibration ajustent legerement l'estimation. Verifiez quand meme les glucides.",
                        severity: .info
                    )
                )
            }
        case .needsReview:
            warnings.append(
                SafetyWarning(
                    title: "Calibration incoherente",
                    message: "Vos reponses semblent incoherentes avec votre ratio. Verifiez vos reglages avant de vous fier a cette estimation.",
                    severity: .caution
                )
            )
        }

        if let glucose {
            if glucose <= profile.glucoseUnit.veryLowThreshold {
                warnings.append(
                    SafetyWarning(
                        title: "Glycemie tres basse",
                        message: "La glycemie saisie est basse. Verifiez vos consignes medicales avant toute correction.",
                        severity: .critical
                    )
                )
            }

            if glucose >= profile.glucoseUnit.veryHighThreshold {
                warnings.append(
                    SafetyWarning(
                        title: "Glycemie tres haute",
                        message: "La glycemie saisie est tres haute. Confirmez avec vos reglages medicaux et votre plan de soins.",
                        severity: .critical
                    )
                )
            }
        }

        if calculation?.wasLimitedByMaximum == true {
            warnings.append(
                SafetyWarning(
                    title: "Limite appliquee",
                    message: "La suggestion calculee depassait votre dose maximale par suggestion. La limite de securite a ete appliquee.",
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
                message: "Completez vos reglages personnels avant d'afficher une suggestion indicative.",
                severity: .critical
            )
        }

        if analysis?.isLikelyFood == false {
            return SafetyWarning(
                title: "Aliment non confirme",
                message: "Entrez les glucides manuellement ou reprenez une photo claire avant d'afficher une suggestion.",
                severity: .critical
            )
        }

        if let glucose, glucose <= profile.glucoseUnit.veryLowThreshold {
            return SafetyWarning(
                title: "Suggestion masquee",
                message: "Glycemie basse detectee. L'app masque toute suggestion chiffree. Suivez vos consignes medicales avant toute decision.",
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
