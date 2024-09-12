import SwiftUI

struct ContentView: View {
    @State private var selectedModelIndex = 0  // Indice du modèle sélectionné
    let models = ["toycar", "chair_swan", "gramophone"]  // Liste des noms des modèles disponibles

    var body: some View {
        NavigationView {
            VStack {
                Text("Bienvenue dans l'application AR")
                    .font(.largeTitle)
                    .padding()

                // Slider de sélection de modèle
                TabView(selection: $selectedModelIndex) {
                    ForEach(0..<models.count, id: \.self) { index in
                        VStack {
                            Text(models[index])  // Affiche le nom du modèle
                                .font(.headline)
                                .padding()

                            // Ici, tu pourrais ajouter une image ou un rendu simplifié du modèle 3D
                            // En l'absence d'image, on montre simplement un rectangle
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: 200, height: 200)
                                .cornerRadius(10)
                                .overlay(Text("Modèle \(index + 1)").foregroundColor(.white))
                        }
                        .padding()
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))  // Pagination
                .frame(height: 300)

                // Lien vers la vue AR avec le modèle sélectionné
                NavigationLink(destination: ARViewContainer(selectedModel: models[selectedModelIndex])) {
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
