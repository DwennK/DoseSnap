import SwiftUI
import UIKit

struct MealThumbnailView: View {
    var data: Data?
    var size: CGFloat = 56

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "fork.knife")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.accent.opacity(0.12))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.ink.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: AppTheme.ink.opacity(0.08), radius: 5, x: 0, y: 2)
    }
}
