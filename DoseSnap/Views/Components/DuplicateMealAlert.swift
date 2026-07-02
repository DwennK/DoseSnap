import SwiftUI

struct DuplicateMealAlertModifier: ViewModifier {
    @Binding var duplicateMeal: MealEntry?
    var onConfirm: () -> Void

    func body(content: Content) -> some View {
        content.alert(
            "Repas similaire deja sauvegarde",
            isPresented: Binding(
                get: { duplicateMeal != nil },
                set: { isPresented in
                    if !isPresented {
                        duplicateMeal = nil
                    }
                }
            ),
            presenting: duplicateMeal
        ) { _ in
            Button("Sauvegarder quand meme", role: .destructive) {
                onConfirm()
                duplicateMeal = nil
            }

            Button("Annuler", role: .cancel) {
                duplicateMeal = nil
            }
        } message: { meal in
            Text("Un repas proche a ete sauvegarde il y a moins de 2 minutes : \(meal.estimatedMealName), \(DoseFormatter.carbs(meal.confirmedCarbs)). Confirmez uniquement si c'est volontaire.")
        }
    }
}

extension View {
    func duplicateMealAlert(duplicateMeal: Binding<MealEntry?>, onConfirm: @escaping () -> Void) -> some View {
        modifier(DuplicateMealAlertModifier(duplicateMeal: duplicateMeal, onConfirm: onConfirm))
    }
}
