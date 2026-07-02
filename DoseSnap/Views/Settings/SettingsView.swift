import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = SettingsViewModel(profile: .default)
    @State private var isDisclaimerPresented = false
    @State private var isClearHistoryPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    eyebrow: "Reglages",
                    title: "Gardez les valeurs critiques sous controle.",
                    subtitle: "Profil, calibration, securite et donnees locales sont modifiables ici.",
                    systemImage: "slider.horizontal.3"
                )

                profileSection
                analysisProviderSection
                calibrationSection
                safetySection
                dataSection
            }
            .padding(20)
            .padding(.bottom, 150)
        }
        .background(AppBackground())
        .navigationTitle("Reglages")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Enregistrer") {
                    appState.saveProfile(viewModel.profile)
                }
                .fontWeight(.semibold)
                .disabled(hasBlockingProfileWarnings)
            }
        }
        .onAppear {
            viewModel.profile = appState.profile
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
                    Text("Unite glycemie")
                        .font(.subheadline)
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

                NumericProfileField(title: "Ratio insuline/glucides", unit: "g pour 1 U", value: $viewModel.profile.insulinToCarbRatio)
                NumericProfileField(title: "Facteur de correction", unit: viewModel.profile.glucoseUnit.title + " par 1 U", value: $viewModel.profile.correctionFactor)
                NumericProfileField(title: "Glycemie cible", unit: viewModel.profile.glucoseUnit.title, value: $viewModel.profile.targetGlucose)

                profileValidationWarnings
            }
        }
    }

    private var calibrationSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    title: "Calibration alimentaire",
                    subtitle: "Utilisee uniquement pour detecter une incoherence et ajuster legerement les estimations."
                )

                NumericProfileField(title: "Snickers standard", unit: "U", value: $viewModel.profile.calibration.snickersUnits)
                NumericProfileField(title: "Menu Big Mac", unit: "U", value: $viewModel.profile.calibration.bigMacMenuUnits)
                NumericProfileField(title: "Pizza moyenne", unit: "U", value: $viewModel.profile.calibration.mediumPizzaUnits)
                NumericProfileField(title: "Bol de pates", unit: "U", value: $viewModel.profile.calibration.pastaBowlUnits)

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
                    subtitle: "Le backend evite d'exposer une cle IA dans l'app iOS."
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
                            message: "Renseignez une URL backend valide avant d'utiliser l'analyse IA reelle.",
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
                    title: "Calibration incomplete",
                    message: "Renseignez au moins deux reperes pour activer un diagnostic de coherence.",
                    severity: .info
                )
            )
        case .coherent(let factor):
            SafetyWarningView(
                warning: SafetyWarning(
                    title: "Calibration coherente",
                    message: factor == 1 ? "Aucun ajustement alimentaire n'est applique." : "Un ajustement prudent de \(factor.formatted(.number.precision(.fractionLength(2))))x peut etre applique aux estimations.",
                    severity: .info
                )
            )
        case .needsReview:
            SafetyWarningView(
                warning: SafetyWarning(
                    title: "Calibration a verifier",
                    message: "Vos reponses semblent incoherentes avec votre ratio. Verifiez vos reglages medicaux avant de vous fier aux estimations.",
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
                        message: "Les resultats restent des estimations et suggestions indicatives a verifier avec vos consignes medicales.",
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
                SecondaryActionButton(title: "Charger donnees demo", systemImage: "shippingbox", role: nil) {
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

    @ViewBuilder
    private var profileValidationWarnings: some View {
        let warnings = InputValidationRules.profileWarnings(viewModel.profile).filter {
            $0.title != "Limite de dose a verifier"
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
        if let warning = InputValidationRules.profileWarnings(viewModel.profile).first(where: { $0.title == "Limite de dose a verifier" }) {
            SafetyWarningView(warning: warning)
        }
    }
}
