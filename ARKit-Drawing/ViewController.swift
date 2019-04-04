import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()

    /// Node selected by user
    var selectedNode: SCNNode?
    
    /// Nodes placed by user
    var placedNodes = [SCNNode]()
    
    /// Vusialization planes when detecting planes
    var planeNodes = [SCNNode]()
    
    enum ObjectPlacementMode {
        case freeform, plane, image
    }
    
    var objectMode: ObjectPlacementMode = .freeform
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    @IBAction func changeObjectMode(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            objectMode = .freeform
        case 1:
            objectMode = .plane
        case 2:
            objectMode = .image
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showOptions" {
            let optionsViewController = segue.destination as! OptionsContainerViewController
            optionsViewController.delegate = self
        }
    }
}

extension ViewController: OptionsViewControllerDelegate {
    
    func objectSelected(node: SCNNode) {
        dismiss(animated: true, completion: nil)
        selectedNode = node
        
    }
    
    func togglePlaneVisualization() {
        dismiss(animated: true, completion: nil)
    }
    
    func undoLastObject() {
        
    }
    
    func resetScene() {
        dismiss(animated: true, completion: nil)
    }
}

//  MARK: - Touches
extension ViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let touch = touches.first else { return }
        guard let node = selectedNode else { return }
        switch objectMode {
        case .freeform:
            addNodeInFront(node)
        case .plane:
            break
        case .image:
            break
        }
    }
}

// MARK: - Placement Methods
extension ViewController {
    
    func addNode(_ node: SCNNode, to parentNode:SCNNode) {
        let cloneNode = node.clone()
        parentNode.addChildNode(cloneNode)
        placedNodes.append(cloneNode)
    }
    
    func addNodeInFront(_ node: SCNNode) {
        guard let currentFrame = sceneView.session.currentFrame else { return }
        
        var translation = matrix_identity_float4x4
        
        // сдвиг на 20 сантиметров от камеры
        translation.columns.3.z = -0.2
        node.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
        addNodeToSceneRoot(node)
    }
    
    //Клонирует и добавляет объект определенной ноды на сцену
    func addNodeToSceneRoot(_ node: SCNNode) {
        let rootNode = sceneView.scene.rootNode
        addNode(node, to: rootNode)
        
        let cloneNode = node.clone()
        sceneView.scene.rootNode.addChildNode(cloneNode)
        placedNodes += [cloneNode]
    }
    
    func nodeAdded(_ node: SCNNode, for anchor: ARPlaneAnchor) {
        
    }
    
    func nodeAdded(_ node: SCNNode, for anchor: ARImageAnchor) {
        print(#function, #line)
        guard let selectedNode = selectedNode else { return }
        addNode(selectedNode, to: node)
    }
}

// SCNSceneRenderer
extension ViewController {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print(#function, #line)

        if let planeAnchor = anchor as? ARPlaneAnchor {
            nodeAdded(node, for: planeAnchor)
        } else if let imageAnchor = anchor as? ARImageAnchor {
            nodeAdded(node, for: imageAnchor)
        }
    }
}

/// Configurations methods
extension ViewController {
    func reloadConfiguration() {
        let images = ARReferenceImage.referenceImages(inGroupNamed: "AR Resourses", bundle: nil)
        
        configuration.detectionImages = objectMode == .image ? images : nil
    
        sceneView.session.run(configuration)
    }
}
