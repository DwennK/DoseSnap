import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: OnboardingViewModel

    init(profile: UserProfile) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(profile: profile))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: viewModel.progress)
                    .tint(AppTheme.accent)
                    .padding(.horizontal)
                    .padding(.top, 14)

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        CardView {
                            stepContent
                        }

                        Text("Toutes les valeurs peuvent etre modifiees plus tard dans Reglages.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }

                footer
                    .padding(20)
                    .background(AppTheme.warmSurface)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(AppTheme.subtleStroke)
                            .frame(height: 1)
                    }
            }
            .background(AppBackground())
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: viewModel.currentStep.iconName)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    AppTheme.primaryGradient,
                    in: RoundedRectangle(cornerRadius: 19, style: .continuous)
                )
                .shadow(color: AppTheme.accent.opacity(0.08), radius: 8, x: 0, y: 4)

            Text(viewModel.currentStep.title)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.navy)
                .lineLimit(3)
                .minimumScaleFactor(0.74)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .disclaimer:
            DisclaimerView()
        case .glucoseUnit:
            unitStep
        case .insulinProfile:
            insulinProfileStep
        case .safetyLimit:
            safetyLimitStep
        case .calibration:
            calibrationStep
        case .review:
            reviewStep
        }
    }

    private var unitStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choisissez l'unite utilisee par votre lecteur ou capteur.")
                .foregroundStyle(.secondary)

            Picker("Unite", selection: Binding(
                get: { viewModel.profile.glucoseUnit },
                set: { viewModel.setGlucoseUnit($0) }
            )) {
                ForEach(GlucoseUnit.allCases) { unit in
                    Text(unit.title).tag(unit)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var insulinProfileStep: some View {
        VStack(spacing: 16) {
            NumericProfileField(
                title: "Ratio insuline/glucides",
                unit: "g pour 1 U",
                value: $viewModel.profile.insulinToCarbRatio
            )

            NumericProfileField(
                title: "Facteur de correction",
                unit: viewModel.profile.glucoseUnit.title + " par 1 U",
                value: $viewModel.profile.correctionFactor
            )

            NumericProfileField(
                title: "Glycemie cible",
                unit: viewModel.profile.glucoseUnit.title,
                value: $viewModel.profile.targetGlucose
            )
        }
    }

    private var safetyLimitStep: some View {
        VStack(spacing: 16) {
            NumericProfileField(
                title: "Dose maximale par suggestion",
                unit: "U",
                value: $viewModel.profile.maxSuggestedDose
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Arrondi")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Arrondi", selection: $viewModel.profile.roundingIncrement) {
                    ForEach(DoseRoundingIncrement.allCases) { increment in
                        Text(increment.title).tag(increment)
                    }
                }
                .pickerStyle(.segmented)
            }

            Text("Cette limite ne rend pas une suggestion certaine. Elle sert a eviter une valeur affichee trop haute.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var calibrationStep: some View {
        VStack(spacing: 16) {
            Text("Ces questions ne remplacent pas vos reglages medicaux. Elles servent seulement a detecter une incoherence et a ajuster legerement les estimations.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            NumericProfileField(title: "Snickers standard", unit: "U", value: $viewModel.profile.calibration.snickersUnits)
            NumericProfileField(title: "Menu Big Mac", unit: "U", value: $viewModel.profile.calibration.bigMacMenuUnits)
            NumericProfileField(title: "Pizza moyenne", unit: "U", value: $viewModel.profile.calibration.mediumPizzaUnits)
            NumericProfileField(title: "Bol de pates", unit: "U", value: $viewModel.profile.calibration.pastaBowlUnits)
        }
    }

    private var reviewStep: some View {
        VStack(spacing: 14) {
            MetricRow(title: "Ratio", value: "1 U / \(DoseFormatter.carbs(viewModel.profile.insulinToCarbRatio))", systemImage: "scalemass")
            MetricRow(title: "Correction", value: "\(DoseFormatter.glucose(viewModel.profile.correctionFactor, unit: viewModel.profile.glucoseUnit)) / U", systemImage: "arrow.down.heart")
            MetricRow(title: "Cible", value: DoseFormatter.glucose(viewModel.profile.targetGlucose, unit: viewModel.profile.glucoseUnit), systemImage: "scope")
            MetricRow(title: "Limite", value: DoseFormatter.dose(viewModel.profile.maxSuggestedDose), systemImage: "lock.shield")

            SafetyWarningView(
                warning: SafetyWarning(
                    title: "Rappel important",
                    message: "DoseSnap affiche une suggestion indicative a verifier, jamais une consigne certaine.",
                    severity: .caution
                )
            )
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if viewModel.canGoBack {
                Button("Retour") {
                    viewModel.goBack()
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.accent)
                .controlSize(.large)
            }

            PrimaryActionButton(
                title: viewModel.isLastStep ? "Commencer" : "Continuer",
                systemImage: viewModel.isLastStep ? "checkmark" : "arrow.right",
                isDisabled: !viewModel.canContinue
            ) {
                if viewModel.isLastStep {
                    appState.completeOnboarding(with: viewModel.profile)
                } else {
                    viewModel.goForward()
                }
            }
        }
    }
}
