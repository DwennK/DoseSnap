import SwiftUI
import PhotosUI

struct ScanView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ScanViewModel()
    @State private var photoItem: PhotosPickerItem?
    @State private var isCameraPresented = false
    @State private var duplicateMeal: MealEntry?
    @State private var pendingMeal: MealEntry?

    var body: some View {
        GeometryReader { geometry in
            let contentWidth = max(0, geometry.size.width - 40)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ScreenHeader(
                        eyebrow: "Scan repas",
                        title: "Photographiez votre repas.",
                        subtitle: "Cadrez l'assiette, lancez l'analyse, puis confirmez les glucides avant toute sauvegarde.",
                        systemImage: "camera.viewfinder"
                    )

                    imageCard(width: contentWidth)
                    analyzeArea

                    if viewModel.analysis != nil || viewModel.calculation != nil {
                        ResultView(
                            viewModel: viewModel,
                            profile: appState.profile,
                            onSave: saveMeal,
                            onCancel: { dismiss() }
                        )
                    }
                }
                .frame(width: contentWidth, alignment: .leading)
                .padding(20)
                .padding(.bottom, 150)
            }
            .background(AppBackground())
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isCameraPresented) {
                CameraPicker { image in
                    viewModel.setCameraImage(image)
                }
                .ignoresSafeArea()
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }

                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        viewModel.setImageData(data)
                    }
                }
            }
            .duplicateMealAlert(duplicateMeal: $duplicateMeal) {
                commitPendingMeal()
            }
        }
    }

    private func imageCard(width: CGFloat) -> some View {
        let previewWidth = max(0, width - 28)

        return CardView(padding: 12, cornerRadius: 26) {
            VStack(spacing: 10) {
                if let image = viewModel.selectedImage {
                    selectedMealPreview(image, width: previewWidth)
                } else {
                    emptyMealPreview(width: previewWidth)
                }

                LazyVGrid(columns: photoActionColumns, spacing: 10) {
                    cameraButton
                    photosButton
                }
            }
        }
        .frame(width: width)
    }

    private var photoActionColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }

    private func selectedMealPreview(_ image: UIImage, width: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: width)
                .frame(height: 200)
                .clipped()

            LinearGradient(
                colors: [.clear, AppTheme.deepNavy.opacity(0.72)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                StatusCapsule(title: "Photo prete", systemImage: "checkmark.circle.fill", color: AppTheme.positive)
                    .background(AppTheme.warmSurface, in: Capsule())

                Text("Verifiez que toute l'assiette est visible.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .frame(width: width)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
    }

    private func emptyMealPreview(width: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image("MealHero")
                .resizable()
                .scaledToFill()
                .frame(width: width)
                .frame(height: 200)
                .clipped()

            LinearGradient(
                colors: [AppTheme.deepNavy.opacity(0.16), AppTheme.deepNavy.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 10) {
                IconBadge(systemImage: "camera.aperture", color: AppTheme.secondaryAccent, isProminent: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ajoutez une photo nette")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text("Assiette entiere, lumiere stable, boissons incluses si elles comptent.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
        }
        .frame(width: width)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var cameraButton: some View {
        Button {
            isCameraPresented = true
        } label: {
            Self.photoActionLabel(title: "Camera", systemImage: "camera.fill", color: AppTheme.accent)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var photosButton: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            Self.photoActionLabel(title: "Photos", systemImage: "photo.fill", color: AppTheme.secondaryAccent)
        }
        .buttonStyle(PressableButtonStyle())
    }

    nonisolated private static func photoActionLabel(title: String, systemImage: String, color: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 46)
            .padding(.horizontal, 12)
            .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(color.opacity(0.18), lineWidth: 1)
            )
    }

    private var analyzeArea: some View {
        VStack(spacing: 12) {
            photoQualityWarningList

            PrimaryActionButton(
                title: viewModel.isAnalyzing ? "Analyse en cours" : "Analyser",
                systemImage: "sparkles",
                isLoading: viewModel.isAnalyzing,
                isDisabled: !viewModel.hasImage || viewModel.requiresPhotoQualityConfirmation
            ) {
                Task {
                    await viewModel.analyze(profile: appState.profile)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                SafetyWarningView(
                    warning: SafetyWarning(
                        title: "Analyse indisponible",
                        message: errorMessage,
                        severity: .caution
                    )
                )
            }

            #if DEBUG
            SecondaryActionButton(title: "Simuler Snickers", systemImage: "shippingbox", role: nil) {
                viewModel.simulateSnickers(profile: appState.profile)
            }
            #endif
        }
    }

    @ViewBuilder
    private var photoQualityWarningList: some View {
        if !viewModel.photoQualityWarnings.isEmpty {
            VStack(spacing: 10) {
                ForEach(viewModel.photoQualityWarnings) { warning in
                    SafetyWarningView(warning: warning)
                }

                if viewModel.requiresPhotoQualityConfirmation {
                    SecondaryActionButton(title: "J'ai verifie la photo", systemImage: "checkmark.seal", role: nil) {
                        viewModel.confirmPhotoQualityForAnalysis()
                    }
                }
            }
        }
    }

    private func saveMeal() {
        viewModel.recalculate(profile: appState.profile)

        guard let meal = viewModel.makeMealEntry(profile: appState.profile) else { return }
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
        pendingMeal = nil
        dismiss()
    }
}
