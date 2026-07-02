import SwiftUI

enum AppTheme {
    static let accent = Color(red: 1.00, green: 0.40, blue: 0.10)
    static let secondaryAccent = Color(red: 1.00, green: 0.68, blue: 0.18)
    static let navy = Color(red: 0.05, green: 0.17, blue: 0.31)
    static let deepNavy = Color(red: 0.03, green: 0.10, blue: 0.20)
    static let cream = Color(red: 1.00, green: 0.93, blue: 0.86)
    static let warmSurface = Color(red: 1.00, green: 0.98, blue: 0.94)
    static let mint = Color(red: 0.08, green: 0.68, blue: 0.46)
    static let ink = Color(red: 0.06, green: 0.10, blue: 0.16)
    static let mutedInk = Color(red: 0.30, green: 0.27, blue: 0.24)
    static let softBlue = Color(red: 0.13, green: 0.36, blue: 0.58)
    static let sage = Color(red: 0.38, green: 0.58, blue: 0.42)
    static let positive = Color(red: 0.09, green: 0.62, blue: 0.34)
    static let warning = Color(red: 0.95, green: 0.57, blue: 0.12)
    static let danger = Color(red: 0.86, green: 0.18, blue: 0.18)
    static let lavender = Color(red: 0.47, green: 0.39, blue: 0.91)

    static var background: Color {
        cream
    }

    static var surface: Color {
        warmSurface
    }

    static var elevatedSurface: Color {
        Color(.systemBackground)
    }

    static var disabledSurface: Color {
        Color(red: 0.94, green: 0.92, blue: 0.86)
    }

    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [secondaryAccent, accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var navyGradient: LinearGradient {
        LinearGradient(
            colors: [navy, deepNavy],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var softGradient: LinearGradient {
        LinearGradient(
            colors: [
                sage.opacity(0.18),
                cream,
                secondaryAccent.opacity(0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                cream,
                warmSurface,
                sage.opacity(0.12),
                secondaryAccent.opacity(0.10)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var subtleStroke: Color {
        navy.opacity(0.10)
    }

    static var softShadow: Color {
        navy.opacity(0.06)
    }
}

struct AppBackground: View {
    var body: some View {
        AppTheme.backgroundGradient
            .ignoresSafeArea()
    }
}
