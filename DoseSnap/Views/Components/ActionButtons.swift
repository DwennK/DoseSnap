import SwiftUI

struct PrimaryActionButton: View {
    var title: String
    var systemImage: String
    var isLoading = false
    var isDisabled = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: systemImage)
                }

                Text(title)
                    .font(.headline.weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .padding(.horizontal, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isDisabled ? AppTheme.navy : .white)
        .background(
            LinearGradient(
                colors: isDisabled ? [AppTheme.disabledSurface, AppTheme.disabledSurface] : [AppTheme.secondaryAccent, AppTheme.accent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isDisabled ? AppTheme.subtleStroke : Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: isDisabled ? .clear : AppTheme.accent.opacity(0.10), radius: 10, x: 0, y: 5)
        .disabled(isDisabled || isLoading)
    }
}

struct SecondaryActionButton: View {
    var title: String
    var systemImage: String
    var role: ButtonRole?
    var action: () -> Void

    var body: some View {
        let tintColor = role == .destructive ? AppTheme.danger : AppTheme.accent

        Button(role: role, action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .frame(width: 20)
                Text(title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, 14)
        }
        .buttonStyle(.plain)
        .foregroundStyle(tintColor)
        .background(AppTheme.warmSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tintColor.opacity(0.18), lineWidth: 1)
        )
    }
}
