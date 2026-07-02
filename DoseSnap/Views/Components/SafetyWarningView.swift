import SwiftUI

struct SafetyWarningView: View {
    var warning: SafetyWarning

    private var color: Color {
        switch warning.severity {
        case .info:
            AppTheme.accent
        case .caution:
            AppTheme.warning
        case .critical:
            AppTheme.danger
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: warning.severity == .critical ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color, in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(warning.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.navy)

                Text(warning.message)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.warmSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
    }
}
