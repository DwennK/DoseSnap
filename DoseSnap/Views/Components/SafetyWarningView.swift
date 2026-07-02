import SwiftUI

struct SafetyWarningView: View {
    var warning: SafetyWarning

    private var color: Color {
        switch warning.severity {
        case .info:
            AppTheme.softBlue
        case .caution:
            AppTheme.warning
        case .critical:
            AppTheme.danger
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: warning.severity == .critical ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color, in: Circle())
                .shadow(color: color.opacity(0.30), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 3) {
                Text(warning.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.ink)

                Text(warning.message)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
    }
}
