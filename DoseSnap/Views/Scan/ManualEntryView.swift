import SwiftUI
import UIKit

struct ManualEntryView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ScanViewModel()
    @State private var duplicateMeal: MealEntry?
    @State private var pendingMeal: MealEntry?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    eyebrow: "Saisie rapide",
                    title: "Entrez les glucides, puis contrôlez la suggestion.",
                    subtitle: "Utile quand la photo n'apporte rien ou que vous connaissez déjà la portion.",
                    systemImage: "square.and.pencil"
                )

                ResultView(
                    viewModel: viewModel,
                    profile: appState.profile,
                    onSave: saveMeal,
                    onCancel: { dismiss() }
                )
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppBackground())
        .navigationTitle("Saisie")
        .navigationBarTitleDisplayMode(.inline)
        .keyboardDoneButton()
        .onAppear {
            if viewModel.analysis == nil {
                viewModel.configureManualEntry()
                viewModel.recalculate(profile: appState.profile)
            }
        }
        .duplicateMealAlert(duplicateMeal: $duplicateMeal) {
            commitPendingMeal()
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
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        pendingMeal = nil
        dismiss()
    }
}
