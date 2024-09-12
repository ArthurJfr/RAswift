import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    let selectedModel: String  // Modèle sélectionné

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configurer la session AR avec la détection des surfaces horizontales
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration)
        
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

    // Fonction pour positionner le modèle sélectionné à 1 mètre devant la caméra
    func placeModelInFrontOfCamera(arView: ARView) {
        do {
            // Charger dynamiquement le modèle 3D sélectionné
            let modelEntity = try ModelEntity.loadModel(named: "\(selectedModel).usdz")
            modelEntity.name = selectedModel  // Assigner le nom du modèle

            // Ajuster l'échelle du modèle pour qu'il soit adapté à l'environnement
            modelEntity.scale = SIMD3<Float>(0.05, 0.05, 0.05)  // Réduire l'échelle du modèle

            // Créer une ancre virtuelle à 1 mètre devant la caméra
            let cameraAnchor = AnchorEntity(world: [0, -1, -3])
            cameraAnchor.addChild(modelEntity)

            // Ajouter l'ancre avec le modèle à la scène AR
            arView.scene.addAnchor(cameraAnchor)
            print("Modèle \(selectedModel) ajouté à 1 mètre devant la caméra.")
        } catch {
            print("Erreur lors du chargement du modèle : \(error)")
        }
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        var arView: ARView?  // Référence à ARView pour accéder à la scène
        var initialScale: SIMD3<Float>? = nil
        var initialRotation: simd_quatf? = nil  // Conserver la rotation initiale

        init(_ parent: ARViewContainer) {
            self.parent = parent
        }

        // Ajouter des gestes pour déplacer, redimensionner et faire pivoter le modèle
        func addGestures(to arView: ARView) {
            self.arView = arView  // Stocker une référence à ARView

            // Pan Gesture (glisser pour déplacer le modèle librement)
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            arView.addGestureRecognizer(panGesture)
            
            // Pinch Gesture (pincer pour redimensionner le modèle)
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            arView.addGestureRecognizer(pinchGesture)
            
            // Rotation Gesture (tourner pour faire pivoter le modèle à 360 degrés)
            let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
            arView.addGestureRecognizer(rotationGesture)
        }
        
        // Gérer le déplacement libre du modèle
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView = arView else { return }
            let location = gesture.location(in: arView)
            
            // Déplacement libre : ajuster X et Z en fonction du déplacement
            if let modelEntity = arView.scene.findEntity(named: parent.selectedModel) as? ModelEntity {
                let translation = gesture.translation(in: arView)
                let currentPosition = modelEntity.position
                let newPosition = SIMD3<Float>(
                    currentPosition.x + Float(translation.x * 0.001),  // Ajustement de la vitesse du déplacement
                    currentPosition.y,  // Garder la position Y pour la fixation automatique
                    currentPosition.z + Float(translation.y * 0.001)
                )
                
                modelEntity.position = newPosition
                gesture.setTranslation(.zero, in: arView)  // Réinitialiser la translation pour éviter un cumul
            }
        }

        // Gérer la détection de la surface plane et la fixation automatique
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    print("Surface plane détectée : \(planeAnchor)")
                    
                    // Fixer le modèle à la surface plane détectée
                    if let arView = arView, let modelEntity = arView.scene.findEntity(named: parent.selectedModel) as? ModelEntity {
                        let modelPosition = modelEntity.position
                        modelEntity.position = SIMD3<Float>(modelPosition.x, Float(planeAnchor.transform.columns.3.y), modelPosition.z)
                        print("Modèle fixé à la surface plane détectée.")
                    }
                }
            }
        }

        // Gérer le redimensionnement du modèle avec le geste de pincement
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let arView = arView else { return }
            
            if let modelEntity = arView.scene.findEntity(named: parent.selectedModel) as? ModelEntity {
                if gesture.state == .began {
                    // Enregistrer l'échelle initiale lors du début du geste
                    initialScale = modelEntity.scale
                }
                
                if let initialScale = initialScale {
                    // Ajuster l'échelle proportionnellement au geste
                    let scaleFactor = Float(gesture.scale)
                    modelEntity.scale = initialScale * scaleFactor
                }
                
                // Réinitialiser l'échelle du geste après chaque modification
                if gesture.state == .ended {
                    gesture.scale = 1.0
                }
            }
        }

        // Gérer la rotation du modèle à 360 degrés
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let arView = arView else { return }
            
            if let modelEntity = arView.scene.findEntity(named: parent.selectedModel) as? ModelEntity {
                if gesture.state == .began {
                    // Enregistrer la rotation initiale lors du début du geste
                    initialRotation = modelEntity.orientation
                }
                
                if let initialRotation = initialRotation {
                    // Appliquer une rotation supplémentaire basée sur le geste
                    let rotationAngle = Float(gesture.rotation)
                    let additionalRotation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
                    modelEntity.orientation = additionalRotation * initialRotation
                }

                // Réinitialiser la rotation du geste après chaque modification
                if gesture.state == .ended {
                    gesture.rotation = 0
                }
            }
        }
    }
}
