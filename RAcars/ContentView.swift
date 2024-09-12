import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Bienvenue dans l'application AR")
                    .font(.largeTitle)
                    .padding()

                NavigationLink(destination: ARViewContainer()) {
                    Text("Démarrer AR")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}
