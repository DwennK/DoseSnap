import SwiftUI

struct CardView<Content: View>: View {
    private let content: Content
    private let padding: CGFloat
    private let cornerRadius: CGFloat

    init(padding: CGFloat = 18, cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface(cornerRadius: cornerRadius)
    }
}

struct SectionHeader: View {
    var title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.86)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedInk)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ScreenHeader: View {
    var eyebrow: String
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))

                Text(eyebrow.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(AppTheme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(AppTheme.accent.opacity(0.10), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(AppTheme.accent.opacity(0.14), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.74)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(AppTheme.mutedInk)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct IconBadge: View {
    var systemImage: String
    var color: Color = AppTheme.accent
    var isProminent = false
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(isProminent ? .white : color)
            .frame(width: size, height: size)
            .background(
                isProminent ? AnyShapeStyle(AppTheme.primaryGradient) : AnyShapeStyle(color.opacity(0.11)),
                in: RoundedRectangle(cornerRadius: size * 0.36, style: .continuous)
            )
            .shadow(color: isProminent ? color.opacity(0.30) : .clear, radius: 8, x: 0, y: 4)
    }
}

struct StatusCapsule: View {
    var title: String
    var systemImage: String
    var color: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(color.opacity(0.11), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.16), lineWidth: 1)
            )
            .lineLimit(1)
            .minimumScaleFactor(0.76)
    }
}
