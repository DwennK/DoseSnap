import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = SettingsViewModel(profile: .default)
    @State private var isDisclaimerPresented = false
    @State private var isClearHistoryPresented = false
    @State private var saveStatusMessage: String?
    @State private var saveFeedbackTrigger = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    eyebrow: "Réglages",
                    title: "Gardez les valeurs critiques sous contrôle.",
                    subtitle: "Profil, calibration, sécurité et données locales sont modifiables ici.",
                    systemImage: "slider.horizontal.3"
                )

                saveStatusView
                profileSection
                analysisProviderSection
                calibrationSection
                safetySection
                dataSection
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppBackground())
        .navigationTitle("Réglages")
        .navigationBarTitleDisplayMode(.inline)
        .keyboardDoneButton()
        .sensoryFeedback(.success, trigger: saveFeedbackTrigger)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(hasUnsavedChanges ? "Enregistrer" : "Enregistré") {
                    saveProfile(showConfirmation: true)
                }
                .fontWeight(.semibold)
                .disabled(hasBlockingProfileWarnings)
            }
        }
        .onAppear {
            viewModel.profile = appState.profile
            saveStatusMessage = nil
        }
        .onDisappear {
            if hasUnsavedChanges && !hasBlockingProfileWarnings {
                saveProfile(showConfirmation: false)
            }
        }
        .sheet(isPresented: $isDisclaimerPresented) {
            NavigationStack {
                ScrollView {
                    CardView {
                        DisclaimerView()
                    }
                    .padding(20)
                }
                .background(AppBackground())
                .navigationTitle("Disclaimer")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Fermer") {
                            isDisclaimerPresented = false
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "Supprimer tout l'historique local ?",
            isPresented: $isClearHistoryPresented,
            titleVisibility: .visible
        ) {
            Button("Supprimer l'historique", role: .destructive) {
                appState.clearHistory()
            }
            Button("Annuler", role: .cancel) {}
        }
    }

    private var profileSection: some View {
        CardView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unité glycémie")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Unité", selection: Binding(
                        get: { viewModel.profile.glucoseUnit },
                        set: { viewModel.setGlucoseUnit($0) }
                    )) {
                        ForEach(GlucoseUnit.allCases) { unit in
                            Text(unit.title).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                NumericProfileField(title: "Ratio insuline/glucides", unit: "g pour 1 U", value: $viewModel.profile.insulinToCarbRatio)
                NumericProfileField(title: "Facteur de correction", unit: viewModel.profile.glucoseUnit.title + " par 1 U", value: $viewModel.profile.correctionFactor)
                NumericProfileField(title: "Glycémie cible", unit: viewModel.profile.glucoseUnit.title, value: $viewModel.profile.targetGlucose)

                profileValidationWarnings
            }
        }
    }

    private var calibrationSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    title: "Calibration alimentaire",
                    subtitle: "Utilisée uniquement pour détecter une incohérence et ajuster légèrement les estimations."
                )

                NumericProfileField(title: "Snickers standard", unit: "U", value: $viewModel.profile.calibration.snickersUnits)
                NumericProfileField(title: "Menu Big Mac", unit: "U", value: $viewModel.profile.calibration.bigMacMenuUnits)
                NumericProfileField(title: "Pizza moyenne", unit: "U", value: $viewModel.profile.calibration.mediumPizzaUnits)
                NumericProfileField(title: "Bol de pâtes", unit: "U", value: $viewModel.profile.calibration.pastaBowlUnits)

                calibrationStatusView

                SecondaryActionButton(title: "Refaire calibration", systemImage: "arrow.counterclockwise", role: nil) {
                    viewModel.resetCalibration()
                }
            }
        }
    }

    private var analysisProviderSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    title: "Analyse IA",
                    subtitle: "Le backend évite d'exposer une clé IA dans l'app iOS."
                )

                Picker("Service", selection: $viewModel.profile.foodAnalysisProvider) {
                    ForEach(FoodAnalysisProvider.allCases) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Endpoint backend")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField(UserProfile.defaultBackendEndpoint, text: $viewModel.profile.backendEndpoint)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.footnote.weight(.medium))
                        .lineLimit(2)
                        .minimumScaleFactor(0.70)
                        .padding(14)
                        .background(AppTheme.fieldSurface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(AppTheme.subtleStroke, lineWidth: 1)
                        )
                }

                SecondaryActionButton(title: "Utiliser endpoint DoseSnap", systemImage: "arrow.down.doc", role: nil) {
                    viewModel.profile.backendEndpoint = UserProfile.defaultBackendEndpoint
                    viewModel.profile.foodAnalysisProvider = .backend
                }

                if viewModel.profile.foodAnalysisProvider == .backend && FoodAnalysisServiceFactory.backendURL(from: viewModel.profile.backendEndpoint) == nil {
                    SafetyWarningView(
                        warning: SafetyWarning(
                            title: "Endpoint manquant",
                            message: "Renseignez une URL backend valide avant d'utiliser l'analyse IA réelle.",
                            severity: .caution
                        )
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var calibrationStatusView: some View {
        switch viewModel.profile.calibrationStatus {
        case .unavailable:
            SafetyWarningView(
                warning: SafetyWarning(
                    title: "Calibration incomplète",
                    message: "Renseignez au moins deux repères pour activer un diagnostic de cohérence.",
                    severity: .info
                )
            )
        case .coherent(let factor):
            SafetyWarningView(
                warning: SafetyWarning(
                    title: "Calibration cohérente",
                    message: factor == 1 ? "Aucun ajustement alimentaire n'est appliqué." : "Un ajustement prudent de \(factor.formatted(.number.precision(.fractionLength(2))))x peut être appliqué aux estimations.",
                    severity: .info
                )
            )
        case .needsReview:
            SafetyWarningView(
                warning: SafetyWarning(
                    title: "Calibration à vérifier",
                    message: "Vos réponses semblent incohérentes avec votre ratio. Vérifiez vos réglages médicaux avant de vous fier aux estimations.",
                    severity: .caution
                )
            )
        }
    }

    private var safetySection: some View {
        CardView {
            VStack(spacing: 16) {
                NumericProfileField(title: "Dose maximale par suggestion", unit: "U", value: $viewModel.profile.maxSuggestedDose)

                profileDoseLimitWarning

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

                SafetyWarningView(
                    warning: SafetyWarning(
                        title: "Wording produit",
                        message: "Les résultats restent des estimations et suggestions indicatives à vérifier avec vos consignes médicales.",
                        severity: .caution
                    )
                )
            }
        }
    }

    private var dataSection: some View {
        CardView {
            VStack(spacing: 12) {
                SecondaryActionButton(title: "Voir disclaimer", systemImage: "exclamationmark.shield", role: nil) {
                    isDisclaimerPresented = true
                }

                SecondaryActionButton(title: "Supprimer historique", systemImage: "trash", role: .destructive) {
                    isClearHistoryPresented = true
                }

                #if DEBUG
                SecondaryActionButton(title: "Charger données démo", systemImage: "shippingbox", role: nil) {
                    appState.seedDemoHistory()
                }
                #endif

                if let storageError = appState.storageErrorMessage {
                    SafetyWarningView(
                        warning: SafetyWarning(
                            title: "Stockage local",
                            message: storageError,
                            severity: .caution
                        )
                    )
                }
            }
        }
    }

    private var hasBlockingProfileWarnings: Bool {
        InputValidationRules.profileWarnings(viewModel.profile).contains { $0.severity == .critical }
    }

    private var hasUnsavedChanges: Bool {
        viewModel.profile != appState.profile
    }

    @ViewBuilder
    private var saveStatusView: some View {
        if hasUnsavedChanges {
            StatusCapsule(title: "Modifications non enregistrées", systemImage: "pencil.circle", color: AppTheme.warning)
        } else if let saveStatusMessage {
            StatusCapsule(title: saveStatusMessage, systemImage: "checkmark.circle.fill", color: AppTheme.positive)
        }
    }

    private func saveProfile(showConfirmation: Bool) {
        appState.saveProfile(viewModel.profile)

        guard showConfirmation else { return }
        saveStatusMessage = "Réglages enregistrés"
        saveFeedbackTrigger += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @ViewBuilder
    private var profileValidationWarnings: some View {
        let warnings = InputValidationRules.profileWarnings(viewModel.profile).filter {
            $0.title != "Limite de dose à vérifier"
        }

        if !warnings.isEmpty {
            VStack(spacing: 10) {
                ForEach(warnings) { warning in
                    SafetyWarningView(warning: warning)
                }
            }
        }
    }

    @ViewBuilder
    private var profileDoseLimitWarning: some View {
        if let warning = InputValidationRules.profileWarnings(viewModel.profile).first(where: { $0.title == "Limite de dose à vérifier" }) {
            SafetyWarningView(warning: warning)
        }
    }
}
