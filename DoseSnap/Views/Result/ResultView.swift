import SwiftUI

struct ResultView: View {
    @ObservedObject var viewModel: ScanViewModel
    var profile: UserProfile
    var onSave: () -> Void
    var onCancel: () -> Void
    @State private var isShowingLimitations = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            workflowHeader
            limitationsButton
            suggestionPanel
            criticalWarningList
            verificationPanel
            calculationCard
            auditJournal

            if let analysis = viewModel.analysis {
                analysisSummary(analysis)
            }

            analysisWarnings
            warningList
            actionButtons
        }
        .onChange(of: viewModel.confirmedCarbsText) { _, _ in
            viewModel.hasVerifiedCarbs = false
            viewModel.recalculate(profile: profile)
        }
        .onChange(of: viewModel.currentGlucoseText) { _, _ in
            viewModel.recalculate(profile: profile)
        }
        .onChange(of: viewModel.activeInsulinText) { _, _ in
            viewModel.recalculate(profile: profile)
        }
        .sheet(isPresented: $isShowingLimitations) {
            AppLimitationsView()
        }
    }

    private var workflowHeader: some View {
        HStack(spacing: 8) {
            WorkflowStep(title: "Scan", systemImage: "camera.fill", isActive: false, isComplete: true)
            DividerLine()
            WorkflowStep(title: "Verifier", systemImage: "checkmark.circle.fill", isActive: !viewModel.hasVerifiedCarbs, isComplete: viewModel.hasVerifiedCarbs)
            DividerLine()
            WorkflowStep(title: "Sauver", systemImage: "tray.and.arrow.down.fill", isActive: canSave, isComplete: false)
        }
        .padding(12)
        .background(AppTheme.warmSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.subtleStroke, lineWidth: 1)
        )
    }

    private func analysisSummary(_ analysis: FoodAnalysis) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analyse image")
                            .font(.headline)
                        Text("Confiance IA : \(DoseFormatter.percent(analysis.confidence))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: analysis.confidence < 0.55 ? "exclamationmark.triangle.fill" : "sparkles")
                        .foregroundStyle(analysis.confidence < 0.55 ? AppTheme.warning : AppTheme.accent)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(analysis.detectedItems) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(DoseFormatter.carbs(item.estimatedCarbs))
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                }

                Text(analysis.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var verificationPanel: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    title: "Verifier avant sauvegarde",
                    subtitle: "Corrigez les glucides, ajoutez la glycemie si utile, puis confirmez."
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Glucides confirmes")
                        .font(.subheadline.weight(.semibold))

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        TextField("Glucides", text: $viewModel.confirmedCarbsText)
                            .keyboardType(.decimalPad)
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)

                        Text("g")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(viewModel.hasVerifiedCarbs ? AppTheme.positive.opacity(0.45) : AppTheme.accent.opacity(0.35), lineWidth: 1)
                    )
                }

                Button {
                    viewModel.hasVerifiedCarbs.toggle()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: viewModel.hasVerifiedCarbs ? "checkmark.circle.fill" : "circle")
                        Text("J'ai verifie les glucides")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(14)
                    .foregroundStyle(viewModel.hasVerifiedCarbs ? AppTheme.positive : AppTheme.accent)
                    .background((viewModel.hasVerifiedCarbs ? AppTheme.positive : AppTheme.accent).opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke((viewModel.hasVerifiedCarbs ? AppTheme.positive : AppTheme.accent).opacity(0.18), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                beverageInputCard

                glucoseInputCard

                DecimalField(
                    title: "Insuline active",
                    unit: "U",
                    placeholder: "Optionnel",
                    text: $viewModel.activeInsulinText
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("Optionnel", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(14)
                        .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.subtleStroke, lineWidth: 1)
                        )
                }
            }
        }
    }

    private var suggestionPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    suggestionTitleBlock

                    Spacer(minLength: 8)

                    verificationCapsule
                }

                VStack(alignment: .leading, spacing: 12) {
                    suggestionTitleBlock
                    verificationCapsule
                }
            }

            if let blockingWarning {
                SafetyWarningView(warning: blockingWarning)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    glucoseInfoPill
                    rangeInfoPill
                }

                VStack(spacing: 10) {
                    glucoseInfoPill
                    rangeInfoPill
                }
            }

            Text(viewModel.calculation?.correctionWasUsed == true ? "Inclut une correction basee sur la glycemie saisie." : "Correction glycemie non incluse.")
                .font(.footnote)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Verifiez toujours avec votre propre jugement et vos consignes medicales.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.navyGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: AppTheme.navy.opacity(0.12), radius: 14, x: 0, y: 7)
    }

    private var suggestionTitleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Suggestion indicative")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.secondaryAccent)
                .tracking(0.8)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            if blockingWarning != nil {
                Text("Masquee")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            } else if let calculation = viewModel.calculation {
                Text(DoseFormatter.dose(calculation.suggestedDose))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
                    .contentTransition(.numericText())
            } else {
                Text("--")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }

    private var verificationCapsule: some View {
        StatusCapsule(
            title: viewModel.hasVerifiedCarbs ? "Verifie" : "A verifier",
            systemImage: viewModel.hasVerifiedCarbs ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
            color: viewModel.hasVerifiedCarbs ? AppTheme.positive : AppTheme.warning
        )
        .background(AppTheme.warmSurface, in: Capsule())
    }

    private var glucoseInfoPill: some View {
        InfoPill(title: "Glucides", value: DoseFormatter.carbs(viewModel.confirmedCarbs), systemImage: "scalemass")
    }

    private var rangeInfoPill: some View {
        Group {
            if let analysis = viewModel.analysis {
                InfoPill(
                    title: "Fourchette",
                    value: "\(DoseFormatter.carbs(analysis.totalCarbsLow))-\(DoseFormatter.carbs(analysis.totalCarbsHigh))",
                    systemImage: "arrow.left.and.right"
                )
            } else {
                InfoPill(title: "Fourchette", value: "Manuelle", systemImage: "square.and.pencil")
            }
        }
    }
    @ViewBuilder
    private var calculationCard: some View {
        if let calculation = viewModel.calculation {
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Detail du calcul")
                        .font(.headline)

                    MetricRow(title: "Part repas", value: DoseFormatter.dose(calculation.mealDose), systemImage: "fork.knife")
                    MetricRow(title: "Correction", value: DoseFormatter.dose(calculation.correctionDose), systemImage: "arrow.up.arrow.down")

                    if calculation.activeInsulinSubtracted > 0 {
                        MetricRow(title: "Insuline active soustraite", value: DoseFormatter.dose(calculation.activeInsulinSubtracted), systemImage: "minus.circle")
                    }

                    if calculation.wasLimitedByMaximum {
                        MetricRow(title: "Limite appliquee", value: DoseFormatter.dose(profile.maxSuggestedDose), systemImage: "lock.shield")
                    }
                }
            }
        } else {
            SafetyWarningView(
                warning: SafetyWarning(
                    title: "Suggestion indisponible",
                    message: "Completez le profil et verifiez les valeurs saisies pour afficher une suggestion indicative.",
                    severity: .critical
                )
            )
        }
    }

    private var auditJournal: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Journal d'audit local")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "list.bullet.clipboard")
                        .foregroundStyle(AppTheme.accent)
                }

                AuditRow(title: "Glucides utilises", value: DoseFormatter.carbs(viewModel.confirmedCarbs))
                AuditRow(title: "Glucides repas", value: DoseFormatter.carbs(viewModel.mealCarbs))

                if let beverageInput = viewModel.beverageInput {
                    AuditRow(title: "Boisson", value: "\(beverageInput.displayName), \(DoseFormatter.carbs(beverageInput.estimatedCarbs))")
                } else {
                    AuditRow(title: "Boisson", value: "Non incluse")
                }

                AuditRow(title: "Source glucides", value: viewModel.analysis?.displayName.isEmpty == false ? viewModel.analysis?.displayName ?? "Saisie" : "Saisie")

                if let analysis = viewModel.analysis {
                    AuditRow(title: "Confiance analyse", value: DoseFormatter.percent(analysis.confidence))
                    AuditRow(title: "Fourchette", value: "\(DoseFormatter.carbs(analysis.totalCarbsLow))-\(DoseFormatter.carbs(analysis.totalCarbsHigh))")
                }

                if viewModel.isCorrectionEnabled, let glucose = viewModel.currentGlucose(in: profile.glucoseUnit) {
                    AuditRow(title: "Glycemie utilisee", value: DoseFormatter.glucose(glucose, unit: profile.glucoseUnit))
                } else {
                    AuditRow(title: "Correction glycemie", value: "Non incluse")
                }

                AuditRow(title: "Ratio", value: "1 U / \(DoseFormatter.carbs(profile.insulinToCarbRatio))")
                AuditRow(title: "Facteur correction", value: DoseFormatter.glucose(profile.correctionFactor, unit: profile.glucoseUnit) + " / U")
                AuditRow(title: "Cible", value: DoseFormatter.glucose(profile.targetGlucose, unit: profile.glucoseUnit))
                AuditRow(title: "Insuline active", value: DoseFormatter.dose(viewModel.activeInsulin))
                AuditRow(title: "Arrondi", value: profile.roundingIncrement.title)
                AuditRow(title: "Limite suggestion", value: DoseFormatter.dose(profile.maxSuggestedDose))
            }
        }
    }

    private var limitationsButton: some View {
        Button {
            isShowingLimitations = true
        } label: {
            Label("Voir les limites de l'app avant decision", systemImage: "exclamationmark.shield")
                .font(.footnote.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .foregroundStyle(AppTheme.danger)
                .background(AppTheme.warmSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.danger.opacity(0.16), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var analysisWarnings: some View {
        if let analysis = viewModel.analysis, !analysis.warnings.isEmpty {
            VStack(spacing: 10) {
                ForEach(analysis.warnings, id: \.self) { warning in
                    SafetyWarningView(
                        warning: SafetyWarning(
                            title: "Analyse a verifier",
                            message: warning,
                            severity: analysis.confidence < 0.55 ? .critical : .caution
                        )
                    )
                }
            }
        }
    }

    private var canSave: Bool {
        viewModel.calculation != nil &&
        !SafetyRules.shouldBlockSave(
            profile: profile,
            analysis: viewModel.analysis,
            carbs: viewModel.confirmedCarbs,
            glucose: viewModel.currentGlucose(in: profile.glucoseUnit),
            activeInsulin: viewModel.activeInsulin,
            beverageInput: viewModel.beverageInput,
            hasVerifiedCarbs: viewModel.hasVerifiedCarbs
        )
    }

    private var blockingWarning: SafetyWarning? {
        if let warning = SafetyRules.blockingSuggestionWarning(
            profile: profile,
            analysis: viewModel.analysis,
            glucose: viewModel.currentGlucose(in: profile.glucoseUnit)
        ) {
            return warning
        }

        let blockingTitles: Set<String> = [
            "Glucides a verifier",
            "Glycemie a verifier",
            "Insuline active a verifier",
            "Volume boisson a verifier",
            "Boisson tres sucree",
            "Ratio a verifier",
            "Facteur de correction a verifier",
            "Cible glycemie a verifier",
            "Limite de dose a verifier"
        ]

        return viewModel.safetyWarnings.first {
            $0.severity == .critical && blockingTitles.contains($0.title)
        }
    }

    @ViewBuilder
    private var criticalWarningList: some View {
        let criticalWarnings = viewModel.safetyWarnings.filter { $0.severity == .critical }
        if !criticalWarnings.isEmpty {
            VStack(spacing: 10) {
                ForEach(criticalWarnings) { warning in
                    SafetyWarningView(warning: warning)
                }
            }
        }
    }

    @ViewBuilder
    private var warningList: some View {
        let nonCriticalWarnings = viewModel.safetyWarnings.filter { $0.severity != .critical }
        if !nonCriticalWarnings.isEmpty {
            VStack(spacing: 10) {
                ForEach(nonCriticalWarnings) { warning in
                    SafetyWarningView(warning: warning)
                }
            }
        }
    }

    private var glucoseInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Inclure une correction glycemie", isOn: $viewModel.isCorrectionEnabled)
                .font(.subheadline.weight(.semibold))

            if viewModel.isCorrectionEnabled {
                Picker("Unite saisie", selection: $viewModel.inputGlucoseUnit) {
                    ForEach(GlucoseUnit.allCases) { unit in
                        Text(unit.title).tag(unit)
                    }
                }
                .pickerStyle(.segmented)

                DecimalField(
                    title: "Glycemie actuelle",
                    unit: viewModel.inputGlucoseUnit.title,
                    placeholder: "Optionnel",
                    text: $viewModel.currentGlucoseText
                )

                if viewModel.inputGlucoseUnit != profile.glucoseUnit,
                   let converted = viewModel.currentGlucose(in: profile.glucoseUnit) {
                    Text("Converti pour le calcul : \(DoseFormatter.glucose(converted, unit: profile.glucoseUnit))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Aucune correction ne sera calculee. La suggestion indicative utilisera seulement les glucides.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: viewModel.isCorrectionEnabled) { _, _ in
            viewModel.recalculate(profile: profile)
        }
        .onChange(of: viewModel.inputGlucoseUnit) { _, _ in
            viewModel.recalculate(profile: profile)
        }
    }

    private var beverageInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Ajouter une boisson", isOn: Binding(
                get: { viewModel.includesBeverage },
                set: { newValue in
                    viewModel.setIncludesBeverage(newValue)
                    viewModel.recalculate(profile: profile)
                }
            ))
            .font(.subheadline.weight(.semibold))

            if viewModel.includesBeverage {
                Picker("Type de boisson", selection: Binding(
                    get: { viewModel.beverageType },
                    set: { newType in
                        viewModel.setBeverageType(newType)
                        viewModel.recalculate(profile: profile)
                    }
                )) {
                    ForEach(BeverageType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(.menu)

                DecimalField(
                    title: "Volume boisson",
                    unit: "ml",
                    placeholder: "Ex. 330",
                    text: $viewModel.beverageVolumeText
                )

                if viewModel.beverageType == .custom {
                    DecimalField(
                        title: "Glucides boisson pour 100 ml",
                        unit: "g",
                        placeholder: "Ex. 10,6",
                        text: $viewModel.beverageCustomCarbsPer100mlText
                    )
                }

                HStack {
                    Label("Boisson estimee", systemImage: "cup.and.saucer")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(DoseFormatter.carbs(viewModel.beverageCarbs))
                        .fontWeight(.semibold)
                }
                .font(.footnote)

                if viewModel.beverageType.isAlcoholic {
                    SafetyWarningView(
                        warning: SafetyWarning(
                            title: "Alcool a verifier",
                            message: "L'alcool peut rendre l'estimation moins fiable. Confirmez avec vos consignes medicales et votre propre jugement.",
                            severity: .caution
                        )
                    )
                } else {
                    Text("Les boissons sucrees, jus et cafes sucres peuvent etre invisibles sur la photo. Ajoutez-les ici si elles font partie du repas.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Aucune boisson n'est incluse dans les glucides. Ajoutez soda, jus, cafe sucre ou alcool si necessaire.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(15)
        .background(AppTheme.warmSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.subtleStroke, lineWidth: 1)
        )
        .onChange(of: viewModel.beverageVolumeText) { _, _ in
            viewModel.hasVerifiedCarbs = false
            viewModel.recalculate(profile: profile)
        }
        .onChange(of: viewModel.beverageCustomCarbsPer100mlText) { _, _ in
            viewModel.hasVerifiedCarbs = false
            viewModel.recalculate(profile: profile)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            PrimaryActionButton(
                title: "Sauvegarder dans l'historique",
                systemImage: "tray.and.arrow.down",
                isDisabled: !canSave
            ) {
                onSave()
            }

            if !canSave {
                Text("La sauvegarde devient disponible apres verification des glucides et resolution des alertes bloquantes.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            SecondaryActionButton(title: "Annuler", systemImage: "xmark", role: .cancel) {
                onCancel()
            }
        }
    }
}

private struct WorkflowStep: View {
    var title: String
    var systemImage: String
    var isActive: Bool
    var isComplete: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(isActive || isComplete ? 0.14 : 0.08), in: Circle())

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isActive || isComplete ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var color: Color {
        if isComplete { return AppTheme.positive }
        if isActive { return AppTheme.accent }
        return Color.secondary
    }
}

private struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.18))
            .frame(width: 28, height: 1)
            .padding(.bottom, 18)
    }
}

private struct InfoPill: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.secondaryAccent)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.white)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.76)
        }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(AppTheme.deepNavy.opacity(0.42), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct AuditRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(.footnote.weight(.semibold))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(3)
                .minimumScaleFactor(0.78)
        }
        .padding(.vertical, 2)
    }
}
