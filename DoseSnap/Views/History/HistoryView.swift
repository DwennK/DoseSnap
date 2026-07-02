import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    eyebrow: "Historique local",
                    title: "Vos repas sauvegardes, prets a comparer.",
                    subtitle: "Les donnees restent sur cet iPhone et gardent le contexte du calcul.",
                    systemImage: "clock.arrow.circlepath"
                )

                if viewModel.entries.isEmpty {
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            IconBadge(systemImage: "clock.arrow.circlepath", color: AppTheme.lavender)

                            Text("Aucun repas sauvegarde")
                                .font(.headline.weight(.bold))

                            Text("Les estimations sauvegardees depuis le scan ou la saisie manuelle apparaitront ici.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.entries) { meal in
                            HistoryMealCard(meal: meal, glucoseUnit: appState.profile.glucoseUnit) { usefulness in
                                var updated = meal
                                updated.usefulness = usefulness
                                appState.updateMeal(updated)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 150)
        }
        .background(AppBackground())
        .navigationTitle("Historique")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.refresh(meals: appState.mealHistory)
        }
        .onChange(of: appState.mealHistory) { _, meals in
            viewModel.refresh(meals: meals)
        }
    }
}

private struct HistoryMealCard: View {
    var meal: MealEntry
    var glucoseUnit: GlucoseUnit
    var onUsefulnessChange: (MealUsefulness) -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    MealThumbnailView(data: meal.thumbnailData, size: 58)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.estimatedMealName)
                            .font(.headline.weight(.bold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.86)

                        Text(meal.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }

                    Spacer()
                }

                VStack(spacing: 10) {
                    MetricRow(title: "Glucides confirmes", value: DoseFormatter.carbs(meal.confirmedCarbs), systemImage: "chart.bar")
                    MetricRow(title: "Fourchette", value: "\(DoseFormatter.carbs(meal.carbsRangeLow))-\(DoseFormatter.carbs(meal.carbsRangeHigh))", systemImage: "arrow.left.and.right")
                    MetricRow(title: "Suggestion indicative", value: DoseFormatter.dose(meal.suggestedDose), systemImage: "drop")

                    if let glucose = meal.glucoseValue {
                        MetricRow(title: "Glycemie saisie", value: DoseFormatter.glucose(glucose, unit: glucoseUnit), systemImage: "waveform.path.ecg")
                    }
                }

                if !meal.notes.isEmpty {
                    Text(meal.notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Menu {
                    ForEach(MealUsefulness.allCases) { usefulness in
                        Button(usefulness.title) {
                            onUsefulnessChange(usefulness)
                        }
                    }
                } label: {
                    Label(meal.usefulness.title, systemImage: "hand.thumbsup")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.accent.opacity(0.1), in: Capsule())
                }
            }
        }
    }
}
