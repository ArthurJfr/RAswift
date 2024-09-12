import SwiftUI

struct ContentView: View {
    @State private var selectedModelIndex = 0  // Indice du modèle sélectionné
    // Dictionnaire associant chaque emoji à son nom de fichier modèle
    let modelData = [
        "🚗": "toycar",
        "🪑": "chair_swan",
        "📻": "gramophone",
        "☕️": "cup_saucer_set"
    ]

    var body: some View {
        NavigationView {
            VStack {
                Text("Bienvenue dans l'application AR")
                    .font(.largeTitle)
                    .padding()

                // Slider de sélection de modèle
                TabView(selection: $selectedModelIndex) {
                    ForEach(Array(modelData.keys).indices, id: \.self) { index in
                        let emoji = Array(modelData.keys)[index]  // Obtenir l'emoji
                        let modelName = modelData[emoji]!  // Récupérer le nom du modèle
                        VStack {
                            Text(emoji)  // Affiche l'emoji
                                .font(.system(size: 100))  // Ajuster la taille de l'emoji
                                .padding()

                            // Afficher le nom du modèle sous l'emoji
                            Text(modelName)
                                .font(.headline)
                                .padding()
                        }
                        .padding()
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))  // Pagination
                .frame(height: 300)

                // Lien vers la vue AR avec le nom de fichier du modèle sélectionné
                let selectedEmoji = Array(modelData.keys)[selectedModelIndex]
                let selectedModelName = modelData[selectedEmoji]!

                NavigationLink(destination: ARViewContainer(selectedModel: selectedModelName)) {
                    Text("Démarrer AR")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}
