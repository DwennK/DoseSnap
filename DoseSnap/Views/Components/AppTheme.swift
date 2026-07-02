import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.95, green: 0.33, blue: 0.13)
    static let secondaryAccent = Color(red: 1.00, green: 0.62, blue: 0.22)
    static let navy = Color(red: 0.10, green: 0.14, blue: 0.20)
    static let deepNavy = Color(red: 0.05, green: 0.08, blue: 0.13)
    static let cream = Color(red: 0.97, green: 0.955, blue: 0.935)
    static let warmSurface = Color.white
    static let mint = Color(red: 0.05, green: 0.63, blue: 0.41)
    static let ink = Color(red: 0.09, green: 0.12, blue: 0.17)
    static let mutedInk = Color(red: 0.42, green: 0.45, blue: 0.50)
    static let softBlue = Color(red: 0.18, green: 0.42, blue: 0.66)
    static let sage = Color(red: 0.42, green: 0.60, blue: 0.47)
    static let positive = Color(red: 0.05, green: 0.63, blue: 0.41)
    static let warning = Color(red: 0.93, green: 0.58, blue: 0.10)
    static let danger = Color(red: 0.85, green: 0.22, blue: 0.20)
    static let lavender = Color(red: 0.44, green: 0.42, blue: 0.90)

    static var background: Color {
        cream
    }

    static var surface: Color {
        warmSurface
    }

    static var elevatedSurface: Color {
        Color(red: 0.975, green: 0.97, blue: 0.96)
    }

    static var fieldSurface: Color {
        Color(red: 0.965, green: 0.958, blue: 0.945)
    }

    static var disabledSurface: Color {
        Color(red: 0.91, green: 0.90, blue: 0.885)
    }

    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.00, green: 0.55, blue: 0.20),
                accent
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var navyGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.14, green: 0.19, blue: 0.28),
                deepNavy
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var softGradient: LinearGradient {
        LinearGradient(
            colors: [
                secondaryAccent.opacity(0.14),
                Color.white,
                accent.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.985, green: 0.972, blue: 0.955),
                cream
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var subtleStroke: Color {
        ink.opacity(0.06)
    }

    static var softShadow: Color {
        ink.opacity(0.06)
    }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient

            Circle()
                .fill(AppTheme.secondaryAccent.opacity(0.10))
                .frame(width: 380, height: 380)
                .blur(radius: 90)
                .offset(x: 160, y: -330)

            Circle()
                .fill(AppTheme.accent.opacity(0.06))
                .frame(width: 340, height: 340)
                .blur(radius: 100)
                .offset(x: -170, y: 360)
        }
        .ignoresSafeArea()
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension View {
    func cardSurface(cornerRadius: CGFloat = 24) -> some View {
        self
            .background(AppTheme.warmSurface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.subtleStroke, lineWidth: 1)
            )
            .shadow(color: AppTheme.ink.opacity(0.04), radius: 3, x: 0, y: 1)
            .shadow(color: AppTheme.ink.opacity(0.07), radius: 22, x: 0, y: 12)
    }
}
