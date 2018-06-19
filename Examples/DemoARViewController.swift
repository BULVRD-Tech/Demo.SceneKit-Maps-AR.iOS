import Foundation
import UIKit
import SceneKit
import ARKit
import MapboxSceneKit
import Parse
//import ParseLiveQuery

//let liveQueryClient = ParseLiveQuery.Client()
/**
 Demonstrates placing a Mapbox TerrainNode in AR. The acual Mapbox SDK logic is in the `insert` function, while the rest
 is the boilerplate code needed to start up an AR session, enable plane tracking, place objects, and support gestures.
 **/
final class DemoARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, UIGestureRecognizerDelegate {
    @IBOutlet private weak var arView: ARSCNView?
    @IBOutlet private weak var placeButton: UIButton?
    @IBOutlet private weak var moveImage: UIImageView?
    @IBOutlet private weak var messageView: UIVisualEffectView?
    @IBOutlet private weak var messageLabel: UILabel?

    private weak var terrain: SCNNode?
    private var planes: [UUID: SCNNode] = [UUID: SCNNode]()
//    fileprivate var subscription: Subscription<PFObject>?
    
    var objectsArray:Array = [PFObject]()
    var centerPoint:PFGeoPoint = PFGeoPoint.init(latitude: 38.958726, longitude: -77.358596)
//    var messagesQuery: PFQuery<PFObject> {
//        return (PFObject.query()?
//            .whereKey("visible", equalTo: true)
//            .whereKey("location", nearGeoPoint: self.centerPoint, withinKilometers: 7)
//            .order(byAscending: "createdAt")) as! PFQuery<PFObject>
//    }
    override func viewDidLoad() {
        super.viewDidLoad()

        arView!.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        arView!.session.delegate = self
        arView!.delegate = self
        if let camera = arView?.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
        }

        arView!.isUserInteractionEnabled = false
        setupGestures()
    }
    
//    func setupLiveQuery(){
//        self.subscription = liveQueryClient
//            .subscribe(self.messagesQuery)
//            .handle(Event.created) { _, PFObject in
////                self.printMessage(message)
//        }
//    }
//
//    func disconnectFromChatRoom() {
//        liveQueryClient.unsubscribe(self.messagesQuery, handler: subscription!)
//    }
    
    func addLocations(to terrainNode: TerrainNode){
        let queryAttr = PFQuery(className: "data");
        queryAttr.whereKey("location", nearGeoPoint: self.centerPoint, withinKilometers: 3)
        queryAttr.whereKey("visible", equalTo: true);
        queryAttr.findObjectsInBackground{
            (objects: [PFObject]??, error: Error?) -> Void in
            if error != nil || objects == nil {
                print("Query Failed")
            } else {
                for item in (objects as? [PFObject])! {
                    
                    print(item["type"] as! String);
                    let point = item["location"] as! PFGeoPoint;
                    let clLoc = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                    
                    if(item["type"] as! String == "Construction"){
                        
                        let location: CLLocation = CLLocation(coordinate: clLoc, altitude: 165, horizontalAccuracy: 100, verticalAccuracy: 100, timestamp: Date())
                        let newNode = self.collada2SCNNode(filepath: "construction_cone/model_copy.scn");
                        newNode.position = terrainNode.convertPosition(terrainNode.positionForLocation(location), to: nil)
//                        self.arView?.scene.rootNode.addChildNode(newNode)
                        terrainNode.addChildNode(newNode)
                    }else if(item["type"] as! String == "Pothole"){
                        
                        let location: CLLocation = CLLocation(coordinate: clLoc, altitude: 165, horizontalAccuracy: 100, verticalAccuracy: 100, timestamp: Date())
                        let particles = SCNParticleSystem(named: "Reactorer", inDirectory: nil);
                        particles?.particleSize = 25;
                        particles?.particleColor = UIColor.blue
                        let cone = SCNCone.init(topRadius: 15, bottomRadius: 1, height: 110);
                        particles?.emitterShape = cone;
                        let sphere = SCNNode()
                        sphere.addParticleSystem(particles!);
                        sphere.position = terrainNode.convertPosition(terrainNode.positionForLocation(location), to: nil)
                        terrainNode.addChildNode(sphere)
                        
                    }else if(item["type"] as! String == "Hazard"){
                        
                        let location: CLLocation = CLLocation(coordinate: clLoc, altitude: 165, horizontalAccuracy: 100, verticalAccuracy: 100, timestamp: Date())
                        let particles = SCNParticleSystem(named: "Reactorer", inDirectory: nil);
                        particles?.particleSize = 25;
                        particles?.particleColor = UIColor.red
                        let cone = SCNCone.init(topRadius: 15, bottomRadius: 1, height: 120);
                        particles?.emitterShape = cone;
                        let sphere = SCNNode()
                        sphere.addParticleSystem(particles!);
                        sphere.position = terrainNode.convertPosition(terrainNode.positionForLocation(location), to: nil)
                        terrainNode.addChildNode(sphere)
                        
                    }else if(item["type"] as! String == "Police"){
                        
                        let location: CLLocation = CLLocation(coordinate: clLoc, altitude: 159, horizontalAccuracy: 100, verticalAccuracy: 100, timestamp: Date())
                        let newNode = self.collada2SCNNode(filepath: "1396_Police_Car/1396_Police_Car_copy.scn");
                        newNode.position = terrainNode.convertPosition(terrainNode.positionForLocation(location), to: nil)
                        terrainNode.addChildNode(newNode)
                        
                    }else if(item["type"] as! String == "Accident"){
                        
                        let location: CLLocation = CLLocation(coordinate: clLoc, altitude: 165, horizontalAccuracy: 100, verticalAccuracy: 100, timestamp: Date())
                        let particles = SCNParticleSystem(named: "Smoker", inDirectory: nil);
                        particles?.particleSize = 25;
                        particles?.particleColor = UIColor.white
                        let cone = SCNCone.init(topRadius: 10, bottomRadius: 2, height: 120);
                        particles?.emitterShape = cone;
                        let sphere = SCNNode()
                        sphere.addParticleSystem(particles!);
                        sphere.position = terrainNode.convertPosition(terrainNode.positionForLocation(location), to: nil)
                        terrainNode.addChildNode(sphere)
                        
                    }else{
                        let location: CLLocation = CLLocation(coordinate: clLoc, altitude: 150, horizontalAccuracy: 100, verticalAccuracy: 100, timestamp: Date())
                        let text = SCNText(string: item["type"] as! String, extrusionDepth: 3.5)
                        let font = UIFont(name: "Futura", size: 35)
                        text.font = font
                        text.alignmentMode = kCAAlignmentCenter
                        text.firstMaterial?.diffuse.contents = UIColor.white
                        text.firstMaterial?.specular.contents = UIColor.red
                        text.firstMaterial?.isDoubleSided = true
                        text.chamferRadius = 0.01
                        let (minBound, maxBound) = text.boundingBox
                        let textNode = SCNNode(geometry: text)
                        textNode.position = terrainNode.convertPosition(terrainNode.positionForLocation(location), to: nil)
                        terrainNode.addChildNode(textNode)
                    }
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        restartTracking()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        arView?.session.pause()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - SCNSceneRendererDelegate

    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
        }
    }

    // MARK: - IBActions

    @IBAction func place(_ sender: AnyObject?) {
        let tapPoint = screenCenter
        var result = arView?.smartHitTest(tapPoint)
        if result == nil {
            result = arView?.smartHitTest(tapPoint, infinitePlane: true)
        }

        guard result != nil, let anchor = result?.anchor, let plane = planes[anchor.identifier] else {
            return
        }

        insert(on: plane, from: result!)
        arView?.debugOptions = []

        self.placeButton?.isHidden = true
    }

    private func insert(on plane: SCNNode, from hitResult: ARHitTestResult) {
        //Set up initial terrain and materials
        let terrainNode = TerrainNode(minLat: 38.880178, maxLat: 39.041381,
                                      minLon:-77.434754, maxLon: -77.204184)

        //Note: Again, you don't have to do this loading in-scene. If you know the area of the node to be fetched, you can
        //do this in the background while AR plane detection is still working so it is ready by the time
        //your user selects where to add the node in the world.

        //We're going to scale the node dynamically based on the size of the node and how far away the detected plane is
        let scale = Float(0.333 * hitResult.distance) / terrainNode.boundingSphere.radius
        terrainNode.transform = SCNMatrix4MakeScale(scale, scale, scale)
        terrainNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        terrainNode.geometry?.materials = defaultMaterials()
        arView!.scene.rootNode.addChildNode(terrainNode)
        terrain = terrainNode

        terrainNode.fetchTerrainHeights(minWallHeight: 50.0, enableDynamicShadows: true, progress: { _, _ in }, completion: {
            NSLog("Terrain load complete")
            self.addLocations(to: terrainNode);
        })

        terrainNode.fetchTerrainTexture("mapbox/navigation-preview-night-v2", zoom: 14, progress: { _, _ in }, completion: { image in
            NSLog("Texture load complete")
            terrainNode.geometry?.materials[4].diffuse.contents = image
        })

        arView!.isUserInteractionEnabled = true
    }

    private func defaultMaterials() -> [SCNMaterial] {
        let groundImage = SCNMaterial()
        groundImage.diffuse.contents = UIColor.darkGray
        groundImage.name = "Ground texture"

        let sideMaterial = SCNMaterial()
        sideMaterial.diffuse.contents = UIColor.darkGray
        //TODO: Some kind of bug with the normals for sides where not having them double-sided has them not show up
        sideMaterial.isDoubleSided = true
        sideMaterial.name = "Side"

        let bottomMaterial = SCNMaterial()
        bottomMaterial.diffuse.contents = UIColor.black
        bottomMaterial.name = "Bottom"

        return [sideMaterial, sideMaterial, sideMaterial, sideMaterial, groundImage, bottomMaterial]
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.isHidden = true
        node.addChildNode(planeNode)

        planes[anchor.identifier] = planeNode

        DispatchQueue.main.async {
            self.setMessage("")
            if self.terrain == nil {
                self.placeButton?.isHidden = false
                self.moveImage?.isHidden = true
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        planeNode.simdPosition = float3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)

        planes[anchor.identifier] = planeNode
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        node.removeFromParentNode()
        planes.removeValue(forKey: anchor.identifier)

        if planes.isEmpty {
            DispatchQueue.main.async {
                self.terrain?.removeFromParentNode()
                self.moveImage?.isHidden = false
                self.arView?.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
            }
        }
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }

    // MARK: - ARSessionObserver

    func sessionWasInterrupted(_ session: ARSession) {
        setMessage("Session was interrupted")
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        setMessage("Session interruption ended")

        restartTracking()
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        setMessage("Session failed: \(error.localizedDescription)")

        restartTracking()
    }

    // MARK: - Focus Square

    var focusSquare: FocusSquare?

    func setupFocusSquare() {
        focusSquare?.isHidden = true
        focusSquare?.removeFromParentNode()
        focusSquare = FocusSquare()
        arView?.scene.rootNode.addChildNode(focusSquare!)
    }

    func updateFocusSquare() {
        guard let arView = arView else { return }

        if !arView.isUserInteractionEnabled, let result = arView.smartHitTest(screenCenter, infinitePlane: true), let planeAnchor = result.anchor as? ARPlaneAnchor {
            let position: SCNVector3 = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
            focusSquare?.update(for: position, planeAnchor: planeAnchor, camera: arView.session.currentFrame?.camera)
            focusSquare?.unhide()
        } else {
            focusSquare?.hide()
        }
    }

    // MARK: - Message Helpers

    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        let message: String

        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            message = "Move the device around to detect flat surfaces."

        case .notAvailable:
            message = "Tracking unavailable."

        case .limited(.excessiveMotion):
            message = "Move the device more slowly."

        case .limited(.insufficientFeatures):
            message = "Point the device at an area with visible surface detail, or improve lighting conditions."

        case .limited(.initializing):
            message = "Initializing AR session."

        default:
            message = ""
        }

        setMessage(message)
    }

    private func setMessage(_ message: String) {
        self.messageLabel?.text = message
        self.messageView?.isHidden = message.isEmpty
    }


    // MARK: - UIGestureRecognizer

    private func setupGestures() {
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotate.delegate = self
        arView?.addGestureRecognizer(rotate)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        arView?.addGestureRecognizer(pinch)
        let drag = UIPanGestureRecognizer(target: self, action: #selector(handleDrag(_:)))
        drag.delegate = self
        drag.minimumNumberOfTouches = 1
        drag.maximumNumberOfTouches = 1
        arView?.addGestureRecognizer(drag)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.numberOfTouches == otherGestureRecognizer.numberOfTouches
    }

    private var lastDragResult: ARHitTestResult?
    @objc fileprivate func handleDrag(_ gesture: UIRotationGestureRecognizer) {
        guard let terrain = terrain else {
            return
        }

        let point = gesture.location(in: gesture.view!)
        if let result = arView?.smartHitTest(point, infinitePlane: true) {
            if let lastDragResult = lastDragResult {
                let vector: SCNVector3 = SCNVector3(result.worldTransform.columns.3.x - lastDragResult.worldTransform.columns.3.x,
                                                    result.worldTransform.columns.3.y - lastDragResult.worldTransform.columns.3.y,
                                                    result.worldTransform.columns.3.z - lastDragResult.worldTransform.columns.3.z)
                terrain.position += vector
            }
            lastDragResult = result
        }

        if gesture.state == .ended {
            self.lastDragResult = nil
        }
    }

    @objc fileprivate func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let terrain = terrain else {
            return
        }
        var normalized = (terrain.eulerAngles.y - Float(gesture.rotation)).truncatingRemainder(dividingBy: 2 * .pi)
        normalized = (normalized + 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi)
        if normalized > .pi {
            normalized -= 2 * .pi
        }
        terrain.eulerAngles.y = normalized
        gesture.rotation = 0
    }

    private var startScale: Float?
    @objc fileprivate func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let terrain = terrain else {
            return
        }
        if gesture.state == UIGestureRecognizerState.began {
            startScale = terrain.scale.x
        }
        guard let startScale = startScale else {
            return
        }
        let newScale: Float = startScale * Float(gesture.scale)
        terrain.scale = SCNVector3(newScale, newScale, newScale)
        if gesture.state == .ended {
            self.startScale = nil
        }
    }

    //MARK: - Misc Helpers

    private func restartTracking() {
        terrain?.removeFromParentNode()
        for (_, plane) in planes {
            plane.removeFromParentNode()
        }
        planes.removeAll()

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true

        arView?.session.run(configuration, options: [.removeExistingAnchors])
        arView?.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        arView?.isUserInteractionEnabled = false
        placeButton?.isHidden = true
        moveImage?.isHidden = false

        setupFocusSquare()

        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    private var screenCenter: CGPoint {
        let bounds = arView!.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }

    private var session: ARSession {
        return arView!.session
    }
    
    func collada2SCNNode(filepath:String) -> SCNNode {
        var node = SCNNode()
        let scene = SCNScene(named: filepath)
        var nodeArray = scene!.rootNode.childNodes
        
        for childNode in nodeArray {
            node.addChildNode(childNode as SCNNode)
        }
        return node
    }
}

fileprivate extension ARSCNView {
    func smartHitTest(_ point: CGPoint,
                      infinitePlane: Bool = false,
                      objectPosition: float3? = nil,
                      allowedAlignments: [ARPlaneAnchor.Alignment] = [.horizontal]) -> ARHitTestResult? {

        // Perform the hit test.
        let results: [ARHitTestResult]!
        if #available(iOS 11.3, *) {
            results = hitTest(point, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
        } else {
            results = hitTest(point, types: [.estimatedHorizontalPlane])
        }

        // 1. Check for a result on an existing plane using geometry.
        if #available(iOS 11.3, *) {
            if let existingPlaneUsingGeometryResult = results.first(where: { $0.type == .existingPlaneUsingGeometry }),
                let planeAnchor = existingPlaneUsingGeometryResult.anchor as? ARPlaneAnchor, allowedAlignments.contains(planeAnchor.alignment) {
                return existingPlaneUsingGeometryResult
            }
        }

        if infinitePlane {
            // 2. Check for a result on an existing plane, assuming its dimensions are infinite.
            //    Loop through all hits against infinite existing planes and either return the
            //    nearest one (vertical planes) or return the nearest one which is within 5 cm
            //    of the object's position.
            let infinitePlaneResults = hitTest(point, types: .existingPlane)

            for infinitePlaneResult in infinitePlaneResults {
                if let planeAnchor = infinitePlaneResult.anchor as? ARPlaneAnchor, allowedAlignments.contains(planeAnchor.alignment) {
                    // For horizontal planes we only want to return a hit test result
                    // if it is close to the current object's position.
                    if let objectY = objectPosition?.y {
                        let planeY = infinitePlaneResult.worldTransform.translation.y
                        if objectY > planeY - 0.05 && objectY < planeY + 0.05 {
                            return infinitePlaneResult
                        }
                    } else {
                        return infinitePlaneResult
                    }
                }
            }
        }

        // 3. As a final fallback, check for a result on estimated planes.
        return results.first(where: { $0.type == .estimatedHorizontalPlane })
    }
}

fileprivate extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
     */
    var translation: float3 {
        get {
            let translation = columns.3
            return float3(translation.x, translation.y, translation.z)
        }
        set(newValue) {
            columns.3 = float4(newValue.x, newValue.y, newValue.z, columns.3.w)
        }
    }

    /**
     Factors out the orientation component of the transform.
     */
    var orientation: simd_quatf {
        return simd_quaternion(self)
    }

    /**
     Creates a transform matrix with a uniform scale factor in all directions.
     */
    init(uniformScale scale: Float) {
        self = matrix_identity_float4x4
        columns.0.x = scale
        columns.1.y = scale
        columns.2.z = scale
    }
}

