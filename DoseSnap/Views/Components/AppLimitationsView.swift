import SwiftUI

struct AppLimitationsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Role de DoseSnap") {
                    Text("DoseSnap fournit des estimations de glucides et des suggestions indicatives basees sur vos reglages saisis.")
                    Text("L'app ne remplace pas un avis medical, un lecteur de glycemie, une pompe, un professionnel de sante ou vos consignes personnelles.")
                }

                Section("Limites importantes") {
                    Text("Une photo peut mal identifier un aliment, une portion, une sauce, une boisson ou un ingredient cache.")
                    Text("Une etiquette nutritionnelle peut etre mal lue. Verifiez toujours la valeur glucides et la portion.")
                    Text("La suggestion peut etre masquee si le profil est incomplet, si l'aliment est incertain ou si une glycemie basse est saisie.")
                }

                Section("Avant sauvegarde") {
                    Text("Confirmez les glucides avec votre propre jugement, une pesee, une etiquette ou vos reperes habituels.")
                    Text("Confirmez toujours avec vos reglages medicaux et votre plan de soins.")
                }
            }
            .navigationTitle("Limites de l'app")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
