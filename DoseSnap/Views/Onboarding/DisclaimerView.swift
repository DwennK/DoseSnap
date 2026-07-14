import SwiftUI

struct DisclaimerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SafetyPoint(
                systemImage: "waveform.path.ecg",
                title: "Pas un avis médical",
                message: "DoseSnap fournit une estimation de glucides et une suggestion indicative. Ce n'est pas une app médicale certifiée."
            )

            SafetyPoint(
                systemImage: "checkmark.shield",
                title: "Vérification obligatoire",
                message: "Vérifiez toujours avec votre propre jugement, votre matériel et vos consignes médicales."
            )

            SafetyPoint(
                systemImage: "person.crop.circle.badge.exclamationmark",
                title: "Vous gardez la décision",
                message: "L'app ne doit jamais remplacer vos réglages prescrits ni votre plan de soins."
            )
        }
    }
}

private struct SafetyPoint: View {
    var systemImage: String
    var title: String
    var message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(AppTheme.primaryGradient, in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}
