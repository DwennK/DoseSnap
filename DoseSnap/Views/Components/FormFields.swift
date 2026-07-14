import SwiftUI
import UIKit

struct DecimalField: View {
    var title: String
    var unit: String?
    var placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.mutedInk)

            HStack {
                TextField(placeholder, text: $text)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.plain)
                    .font(.body.weight(.semibold))
                    .layoutPriority(1)

                if let unit {
                    Text(unit)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.mutedInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }
            }
            .padding(15)
            .background(AppTheme.fieldSurface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(AppTheme.subtleStroke, lineWidth: 1)
            )
        }
    }
}

struct NumericProfileField: View {
    var title: String
    var unit: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.mutedInk)

            HStack {
                TextField(title, value: $value, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .font(.body.weight(.semibold))
                    .layoutPriority(1)

                Text(unit)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.mutedInk)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .multilineTextAlignment(.trailing)
            }
            .padding(15)
            .background(AppTheme.fieldSurface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(AppTheme.subtleStroke, lineWidth: 1)
            )
        }
    }
}

struct MetricRow: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(systemImage: systemImage, size: 36)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .multilineTextAlignment(.trailing)
        }
    }
}

extension View {
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("OK") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
                .fontWeight(.semibold)
            }
        }
    }
}
