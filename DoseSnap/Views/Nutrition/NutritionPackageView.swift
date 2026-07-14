import PhotosUI
import SwiftUI
import UIKit

struct NutritionPackageView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NutritionPackageViewModel()
    @StateObject private var resultViewModel = ScanViewModel()
    @State private var photoItem: PhotosPickerItem?
    @State private var isBarcodeScannerPresented = false
    @State private var isLabelCameraPresented = false
    @State private var hasCreatedResult = false
    @State private var duplicateMeal: MealEntry?
    @State private var pendingMeal: MealEntry?

    private static let resultAnchorID = "nutrition-result"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenHeader(
                        eyebrow: "Emballage",
                        title: "Lisez l'étiquette produit.",
                        subtitle: "Code-barres, OCR ou saisie directe : le calcul reste basé sur vos valeurs.",
                        systemImage: "barcode.viewfinder"
                    )

                    labelSection
                    barcodeSection
                    nutritionFields
                    calculatedPreview

                    if hasCreatedResult {
                        ResultView(
                            viewModel: resultViewModel,
                            profile: appState.profile,
                            onSave: saveMeal,
                            onCancel: { dismiss() }
                        )
                        .id(Self.resultAnchorID)
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background(AppBackground())
            .navigationTitle("Emballage")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDoneButton()
            .sheet(isPresented: $isBarcodeScannerPresented) {
                BarcodeScannerView { code in
                    isBarcodeScannerPresented = false
                    Task {
                        await viewModel.setBarcode(code)
                    }
                } onCancel: {
                    isBarcodeScannerPresented = false
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $isLabelCameraPresented) {
                CameraPicker { image in
                    Task {
                        await viewModel.setLabelImage(image)
                    }
                }
                .ignoresSafeArea()
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }

                Task {
                    let data = try? await newItem.loadTransferable(type: Data.self)
                    await viewModel.setLabelImageData(data)
                }
            }
            .onChange(of: hasCreatedResult) { _, hasResult in
                scrollToResultIfNeeded(hasResult: hasResult, proxy: proxy)
            }
            .duplicateMealAlert(duplicateMeal: $duplicateMeal) {
                commitPendingMeal()
            }
        }
    }

    private var barcodeSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Code-barres", subtitle: "Scannez un produit pour pré-remplir le nom, les glucides et parfois la portion.")

                HStack(spacing: 10) {
                    TextField("Code-barres", text: $viewModel.barcode)
                        .keyboardType(.numberPad)
                        .textInputAutocapitalization(.never)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .padding(14)
                        .background(AppTheme.fieldSurface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(AppTheme.subtleStroke, lineWidth: 1)
                        )

                    Button {
                        isBarcodeScannerPresented = true
                    } label: {
                        Group {
                            if viewModel.isLookingUpBarcode {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.title3.weight(.semibold))
                            }
                        }
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.white)
                        .background(AppTheme.primaryGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: AppTheme.accent.opacity(0.28), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(viewModel.isLookingUpBarcode)
                    .accessibilityLabel("Scanner un code-barres")
                }

                TextField("Nom du produit ou repas", text: $viewModel.productName)
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(AppTheme.fieldSurface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(AppTheme.subtleStroke, lineWidth: 1)
                    )
            }
        }
    }

    private var labelSection: some View {
        let labelTitle = viewModel.isReadingLabel ? "Lecture" : "Photos"

        return CardView(padding: 14, cornerRadius: 26) {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Étiquette nutritionnelle", subtitle: "Photographiez la zone glucides ou importez une image nette.")

                if let image = viewModel.labelImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 178)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                        )
                } else {
                    ZStack(alignment: .bottomLeading) {
                        Image("ProductScanHero")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 178)
                            .clipped()

                        LinearGradient(
                            colors: [.clear, AppTheme.deepNavy.opacity(0.72)],
                            startPoint: .center,
                            endPoint: .bottom
                        )

                        Label("Produit ou étiquette", systemImage: "text.viewfinder")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.deepNavy.opacity(0.78), in: Capsule())
                            .padding(14)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 178)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }

                LazyVGrid(columns: labelActionColumns, spacing: 10) {
                    labelCameraButton
                    labelPhotoButton(title: labelTitle)
                }

                if let statusMessage = viewModel.statusMessage {
                    Label(statusMessage, systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var labelActionColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }

    private var labelCameraButton: some View {
        Button {
            isLabelCameraPresented = true
        } label: {
            Self.labelAction(title: "Caméra", systemImage: "camera.fill", color: AppTheme.accent)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(viewModel.isReadingLabel)
    }

    private func labelPhotoButton(title: String) -> some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            Self.labelAction(title: title, systemImage: "text.viewfinder", color: AppTheme.secondaryAccent)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(viewModel.isReadingLabel)
    }

    nonisolated private static func labelAction(title: String, systemImage: String, color: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .padding(.horizontal, 12)
            .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(color.opacity(0.18), lineWidth: 1)
            )
    }

    private var nutritionFields: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Glucides et portion", subtitle: "Le calcul utilise uniquement les valeurs que vous vérifiez.")

                Picker("Mode", selection: $viewModel.basis) {
                    ForEach(NutritionCarbBasis.allCases) { basis in
                        Text(basis.title).tag(basis)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.basis == .per100g {
                    DecimalField(
                        title: "Glucides pour 100 g",
                        unit: "g",
                        placeholder: "Ex. 33",
                        text: $viewModel.carbsPer100gText
                    )

                    DecimalField(
                        title: "Portion consommée",
                        unit: "g",
                        placeholder: "Ex. 50",
                        text: $viewModel.portionGramsText
                    )
                } else {
                    DecimalField(
                        title: "Glucides par portion",
                        unit: "g",
                        placeholder: "Ex. 25",
                        text: $viewModel.carbsPerServingText
                    )

                    DecimalField(
                        title: "Nombre de portions",
                        unit: "x",
                        placeholder: "Ex. 1",
                        text: $viewModel.servingCountText
                    )
                }
            }
        }
    }

    private var calculatedPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let carbs = viewModel.calculatedCarbs {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Glucides calculés")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(DoseFormatter.carbs(carbs))
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                    }

                    Spacer()
                }

                PrimaryActionButton(title: "Vérifier la suggestion", systemImage: "checkmark.seal") {
                    viewModel.apply(to: resultViewModel, profile: appState.profile)
                    hasCreatedResult = true
                }
            } else {
                SafetyWarningView(
                    warning: SafetyWarning(
                        title: "Portion à compléter",
                        message: "Saisissez les glucides de l'emballage et la portion consommée pour calculer les glucides.",
                        severity: .caution
                    )
                )
            }
        }
        .padding(20)
        .background(AppTheme.softGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.14), lineWidth: 1)
        )
    }

    private func saveMeal() {
        resultViewModel.recalculate(profile: appState.profile)

        guard let meal = resultViewModel.makeMealEntry(profile: appState.profile) else { return }
        if let duplicate = appState.likelyDuplicateMeal(for: meal) {
            pendingMeal = meal
            duplicateMeal = duplicate
            return
        }

        commitMeal(meal)
    }

    private func commitPendingMeal() {
        guard let pendingMeal else { return }
        commitMeal(pendingMeal)
    }

    private func commitMeal(_ meal: MealEntry) {
        appState.addMeal(meal)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        pendingMeal = nil
        dismiss()
    }

    private func scrollToResultIfNeeded(hasResult: Bool, proxy: ScrollViewProxy) {
        guard hasResult else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                proxy.scrollTo(Self.resultAnchorID, anchor: .top)
            }
        }
    }
}
