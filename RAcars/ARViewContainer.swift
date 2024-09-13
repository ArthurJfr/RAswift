import SwiftUI
import RealityKit
import ARKit

// Cette structure représente la vue AR avec les interactions liées aux modèles 3D.
struct ARViewContainer: UIViewRepresentable {
    let selectedModel: String  // Modèle sélectionné
    @Binding var arView: ARView  // Lien avec la vue AR pour pouvoir la passer à SwiftUI

    func makeUIView(context: Context) -> ARView {
        if arView.frame == .zero {
            arView = ARView(frame: UIScreen.main.bounds)  // S'assurer que l'ARView a un cadre plein écran
        }

        // Configurer la session AR avec la détection des surfaces horizontales
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration)

        // Ajouter une lumière directionnelle pour améliorer l'éclairage
        addDirectionalLight(to: arView)

        // Ajouter les gestes pour déplacer, redimensionner et faire pivoter le modèle
        context.coordinator.addGestures(to: arView)
        
        // Positionner le modèle sélectionné à 1 mètre devant la caméra
        placeModelInFrontOfCamera(arView: arView)
        
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Ajouter une lumière directionnelle pour éclairer les modèles
    func addDirectionalLight(to arView: ARView) {
        let light = DirectionalLight()
        light.light.intensity = 1000  // Ajuster l'intensité de la lumière
        light.light.color = .white
        light.light.isRealWorldProxy = true  // Utiliser la lumière comme une proxy du monde réel
        light.orientation = simd_quatf(angle: -.pi / 4, axis: [1, 0, 0])  // Ajuster l'angle de la lumière

        let lightAnchor = AnchorEntity(world: [0, 0, 0])
        lightAnchor.addChild(light)

        arView.scene.addAnchor(lightAnchor)
    }

    // Fonction pour positionner le modèle sélectionné à 1 mètre devant la caméra
    func placeModelInFrontOfCamera(arView: ARView) {
        do {
            let modelEntity = try ModelEntity.loadModel(named: "\(selectedModel).usdz")
            modelEntity.name = selectedModel

            // Ajuster l'échelle du modèle pour qu'il soit visible dans l'environnement
            modelEntity.scale = SIMD3<Float>(0.05, 0.05, 0.05)

            let cameraAnchor = AnchorEntity(world: [0, -1, -3])
            cameraAnchor.addChild(modelEntity)
            arView.scene.addAnchor(cameraAnchor)
            print("Modèle \(selectedModel) ajouté à 1 mètre devant la caméra.")
        } catch {
            print("Erreur lors du chargement du modèle : \(error)")
        }
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        var arView: ARView?

        init(_ parent: ARViewContainer) {
            self.parent = parent
        }

        func addGestures(to arView: ARView) {
            self.arView = arView
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            arView.addGestureRecognizer(panGesture)
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            arView.addGestureRecognizer(pinchGesture)
            let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
            arView.addGestureRecognizer(rotationGesture)
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = arView else { return }
            let location = gesture.location(in: arView)
            if let modelEntity = arView.scene.findEntity(named: parent.selectedModel) as? ModelEntity {
                let translation = gesture.translation(in: arView)
                let currentPosition = modelEntity.position
                let newPosition = SIMD3<Float>(
                    currentPosition.x + Float(translation.x * 0.001),
                    currentPosition.y,
                    currentPosition.z + Float(translation.y * 0.001)
                )
                modelEntity.position = newPosition
                gesture.setTranslation(.zero, in: arView)
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let arView = arView else { return }
            if let modelEntity = arView.scene.findEntity(named: parent.selectedModel) as? ModelEntity {
                let scaleFactor = Float(gesture.scale)
                modelEntity.scale *= scaleFactor
                gesture.scale = 1.0
            }
        }

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let arView = arView else { return }
            if let modelEntity = arView.scene.findEntity(named: parent.selectedModel) as? ModelEntity {
                let rotationAngle = Float(gesture.rotation)
                let additionalRotation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
                modelEntity.orientation = additionalRotation * modelEntity.orientation
                gesture.rotation = 0
            }
        }
    }
}

// Vue SwiftUI pour contrôler le modèle avec un bouton pour faire pivoter
struct ARControlView: View {
    @Binding var arView: ARView
    let selectedModel: String

    var body: some View {
        VStack {
            Spacer()

            Button(action: {
                rotateModelWithAnimation()
            }) {
                Text("Tourner")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }

    // Fonction pour faire pivoter le modèle avec une animation fluide
    func rotateModelWithAnimation() {
        if let modelEntity = arView.scene.findEntity(named: selectedModel) as? ModelEntity {
            let newOrientation = simd_quatf(angle: .pi/4, axis: [0, 1, 0]) * modelEntity.orientation
            modelEntity.move(to: Transform(rotation: newOrientation), relativeTo: modelEntity, duration: 1.0)
        }
    }
}

// Vue SwiftUI avec un contrôle pour faire pivoter le modèle
struct ARViewWithControl: View {
    let selectedModel: String
    @State private var arView = ARView(frame: .zero)

    var body: some View {
        ZStack {
            ARViewContainer(selectedModel: selectedModel, arView: $arView)
                .edgesIgnoringSafeArea(.all)
            ARControlView(arView: $arView, selectedModel: selectedModel)
        }
    }
}
