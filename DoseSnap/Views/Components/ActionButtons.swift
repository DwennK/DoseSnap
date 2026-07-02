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
                        .font(.headline.weight(.bold))
                }

                Text(title)
                    .font(.headline.weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .padding(.horizontal, 14)
            .foregroundStyle(isDisabled ? AppTheme.mutedInk : .white)
            .background(
                isDisabled
                    ? AnyShapeStyle(AppTheme.disabledSurface)
                    : AnyShapeStyle(AppTheme.primaryGradient),
                in: RoundedRectangle(cornerRadius: 19, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(Color.white.opacity(isDisabled ? 0 : 0.20), lineWidth: 1)
            )
            .shadow(color: isDisabled ? .clear : AppTheme.accent.opacity(0.30), radius: 14, x: 0, y: 7)
        }
        .buttonStyle(PressableButtonStyle())
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
            .foregroundStyle(tintColor)
            .background(AppTheme.warmSurface, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(tintColor.opacity(0.22), lineWidth: 1.2)
            )
            .shadow(color: AppTheme.ink.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
    }
}
