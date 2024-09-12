import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configurer la session AR sans dépendre des surfaces détectées
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]  // Détection des surfaces horizontales
        arView.session.run(configuration)
        
        // Ajout des gestes pour déplacer le modèle
        context.coordinator.addGestures(to: arView)
        
        // Positionner le modèle à 1 mètre devant la caméra
        placeModelInFrontOfCamera(arView: arView)
        
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Fonction pour positionner le modèle à 1 mètre devant la caméra
    func placeModelInFrontOfCamera(arView: ARView) {
        do {
            // Charger le modèle 3D
            let modelEntity = try ModelEntity.loadModel(named: "toycar.usdz")  // Remplace "toycar" par le nom de ton modèle
            
            // Ajuster l'échelle du modèle pour qu'il soit visible
            modelEntity.scale = SIMD3<Float>(0.1, 0.1, 0.1)  // Ajuster la taille du modèle
            
            // Créer une ancre virtuelle à 1 mètre devant la caméra
            let cameraAnchor = AnchorEntity(world: [0, -1, -3])  // Positionner à 1 mètre devant la caméra
            cameraAnchor.addChild(modelEntity)  // Ajouter le modèle à l'ancre
            
            // Ajouter l'ancre avec le modèle à la scène AR
            arView.scene.addAnchor(cameraAnchor)
            print("Modèle ajouté à 1 mètre devant la caméra.")
        } catch {
            print("Erreur lors du chargement du modèle : \(error)")
        }
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer

        init(_ parent: ARViewContainer) {
            self.parent = parent
        }

        // Ajouter des gestes pour déplacer et interagir avec le modèle
        func addGestures(to arView: ARView) {
            // Pan Gesture (glisser pour déplacer le modèle)
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            arView.addGestureRecognizer(panGesture)
            
            // Pinch Gesture (pincer pour redimensionner)
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            arView.addGestureRecognizer(pinchGesture)
            
            // Rotation Gesture (tourner pour faire pivoter le modèle)
            let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
            arView.addGestureRecognizer(rotationGesture)
        }
        
        // Gestion des gestes
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            let location = gesture.location(in: arView)
            let hits = arView.hitTest(location, types: .existingPlaneUsingExtent)
            
            if let firstHit = hits.first {
                let transform = firstHit.worldTransform
                let newPosition = SIMD3(x: transform.columns.3.x, y: transform.columns.3.y, z: transform.columns.3.z)
                
                // Récupérer l'entité à déplacer et mettre à jour sa position
                if let modelEntity = arView.scene.findEntity(named: "toycar") as? ModelEntity {
                    modelEntity.position = newPosition
                    print("Modèle déplacé à la nouvelle position.")
                }
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            
            if let modelEntity = arView.scene.findEntity(named: "toycar") as? ModelEntity {
                let scale = Float(gesture.scale)
                modelEntity.scale = SIMD3<Float>(repeating: scale)
                gesture.scale = 1.0  // Réinitialiser après chaque pincement
            }
        }

        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            
            if let modelEntity = arView.scene.findEntity(named: "toycar") as? ModelEntity {
                let rotation = Float(gesture.rotation)
                modelEntity.orientation = simd_quatf(angle: rotation, axis: [0, 1, 0])
                gesture.rotation = 0  // Réinitialiser après chaque rotation
            }
        }

        // ARSessionDelegate - appelé lorsqu'une nouvelle surface est détectée
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            // Gestion des surfaces détectées (si besoin)
        }
    }
}
