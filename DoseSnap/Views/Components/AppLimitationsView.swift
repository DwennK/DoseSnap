import SwiftUI

struct AppLimitationsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    limitationSection(
                        title: "Rôle de DoseSnap",
                        lines: [
                            "DoseSnap fournit des estimations de glucides et des suggestions indicatives basées sur vos réglages saisis.",
                            "L'app ne remplace pas un avis médical, un lecteur de glycémie, une pompe, un professionnel de santé ou vos consignes personnelles."
                        ]
                    )

                    limitationSection(
                        title: "Limites importantes",
                        lines: [
                            "Une photo peut mal identifier un aliment, une portion, une sauce, une boisson ou un ingrédient caché.",
                            "Une étiquette nutritionnelle peut être mal lue. Vérifiez toujours la valeur glucides et la portion.",
                            "La suggestion peut être masquée si le profil est incomplet, si l'aliment est incertain ou si une glycémie basse est saisie."
                        ]
                    )

                    limitationSection(
                        title: "Avant sauvegarde",
                        lines: [
                            "Confirmez les glucides avec votre propre jugement, une pesée, une étiquette ou vos repères habituels.",
                            "Confirmez toujours avec vos réglages médicaux et votre plan de soins."
                        ]
                    )
                }
                .padding(20)
            }
            .background(AppBackground())
            .navigationTitle("Limites de l'app")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func limitationSection(title: String, lines: [String]) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)

                ForEach(lines, id: \.self) { line in
                    Label(line, systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.mutedInk)
                        .labelStyle(.titleAndIcon)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
