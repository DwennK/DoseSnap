import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                actions
                latestEstimate
                profileCard
                recentHistory
            }
            .padding(20)
            .padding(.bottom, 150)
        }
        .background(AppBackground())
        .navigationTitle("DoseSnap")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.refresh(profile: appState.profile, meals: appState.mealHistory)
        }
        .onChange(of: appState.mealHistory) { _, meals in
            viewModel.refresh(profile: appState.profile, meals: meals)
        }
        .onChange(of: appState.profile) { _, profile in
            viewModel.refresh(profile: profile, meals: appState.mealHistory)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DoseSnap")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("Repas, glucides, suggestion.")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(AppTheme.mutedInk)
                }

                Spacer()

                IconBadge(systemImage: "camera.viewfinder", color: AppTheme.accent, isProminent: true)
            }

            NavigationLink {
                ScanView()
            } label: {
                HomeHeroCard(
                    ratio: "1 U / \(DoseFormatter.carbs(appState.profile.insulinToCarbRatio))",
                    limit: DoseFormatter.dose(appState.profile.maxSuggestedDose)
                )
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var actions: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: actionColumns, spacing: 12) {
                manualAction
                packageAction
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var actionColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var manualAction: some View {
        NavigationLink {
            ManualEntryView()
        } label: {
            QuickActionTile(
                title: "Manuel",
                subtitle: "Glucides connus",
                systemImage: "square.and.pencil",
                color: AppTheme.navy
            )
        }
    }

    private var packageAction: some View {
        NavigationLink {
            NutritionPackageView()
        } label: {
            QuickActionTile(
                title: "Emballage",
                subtitle: "Etiquette produit",
                systemImage: "barcode.viewfinder",
                color: AppTheme.accent
            )
        }
    }

    @ViewBuilder
    private var latestEstimate: some View {
        SectionHeader(title: "Derniere estimation", subtitle: nil)

        if let meal = viewModel.latestMeal {
            CardView {
                HStack(spacing: 16) {
                    MealThumbnailView(data: meal.thumbnailData, size: 72)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(meal.estimatedMealName)
                            .font(.headline)
                            .lineLimit(2)

                        Text("\(DoseFormatter.carbs(meal.confirmedCarbs)) · \(DoseFormatter.dose(meal.suggestedDose)) indicatif")
                            .font(.subheadline.weight(.medium))

                        Text(meal.date, style: .relative)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            CardView {
                HStack(spacing: 12) {
                    IconBadge(systemImage: "tray", color: AppTheme.secondaryAccent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pret pour le premier scan")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(AppTheme.navy)
                        Text("Votre derniere estimation apparaitra ici.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.mutedInk)
                    }
                }
            }
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Profil du jour", subtitle: "Modifiable dans Reglages")

            CardView {
                VStack(spacing: 12) {
                    MetricRow(title: "Ratio", value: "1 U / \(DoseFormatter.carbs(appState.profile.insulinToCarbRatio))", systemImage: "scalemass")
                    MetricRow(title: "Cible", value: DoseFormatter.glucose(appState.profile.targetGlucose, unit: appState.profile.glucoseUnit), systemImage: "scope")
                    MetricRow(title: "Limite", value: DoseFormatter.dose(appState.profile.maxSuggestedDose), systemImage: "lock")
                }
            }
        }
        .padding(.top, 8)
    }

    private var recentHistory: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Historique recent", subtitle: nil)

            if viewModel.recentMeals.isEmpty {
                CardView {
                    HStack(spacing: 12) {
                        IconBadge(systemImage: "clock.arrow.circlepath", color: AppTheme.lavender)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Aucun repas recent")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(AppTheme.navy)
                            Text("Les repas sauvegardes apparaitront ici.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.mutedInk)
                        }
                    }
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.recentMeals) { meal in
                        CardView {
                            HStack(spacing: 12) {
                                MealThumbnailView(data: meal.thumbnailData, size: 46)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(meal.estimatedMealName)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1)
                                    Text("\(DoseFormatter.carbs(meal.confirmedCarbs)) · \(DoseFormatter.dose(meal.suggestedDose))")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct HomeHeroCard: View {
    var ratio: String
    var limit: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("MealHero")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(minHeight: 244)
                .clipped()

            LinearGradient(
                colors: [
                    AppTheme.deepNavy.opacity(0.18),
                    AppTheme.deepNavy.opacity(0.48),
                    AppTheme.deepNavy.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption2.weight(.bold))
                        Text("ANALYSE PHOTO")
                            .font(.caption2.weight(.bold))
                            .tracking(1.2)
                    }
                    .foregroundStyle(AppTheme.secondaryAccent)

                    Text("Scanner le repas")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    Text("Photo, vérification, sauvegarde.")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    HeroMetric(title: "Ratio", value: ratio)
                    HeroMetric(title: "Limite", value: limit)

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.right")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.deepNavy)
                        .frame(width: 44, height: 44)
                        .background(.white, in: Circle())
                        .shadow(color: .black.opacity(0.20), radius: 8, x: 0, y: 4)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 244)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: AppTheme.deepNavy.opacity(0.25), radius: 24, x: 0, y: 14)
    }
}

private struct HeroMetric: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))

            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(.white.opacity(0.14), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
    }
}

private struct QuickActionTile: View {
    var title: String
    var subtitle: String
    var systemImage: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                IconBadge(systemImage: systemImage, color: color)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(color)
                    .frame(width: 26, height: 26)
                    .background(color.opacity(0.10), in: Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(subtitle)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(AppTheme.mutedInk)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 24)
    }
}
