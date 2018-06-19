import UIKit
import SceneKit
import MapKit
import MapboxSceneKit
import Parse

/**
 Demonstrates annotating a `TerrainNode` with other SCNShapes given a series of lat/lons.
 
 Can extend this to do more complex annotations like a tube representing a user's hike.
 **/
class DemoPlacementViewController: UIViewController {
    @IBOutlet private weak var sceneView: SCNView?
    @IBOutlet private weak var progressView: UIProgressView?
    
    var objectsArray:Array = [PFObject]()
    var centerPoint:PFGeoPoint = PFGeoPoint.init(latitude: 38.958726, longitude: -77.358596)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let sceneView = sceneView else {
            return
        }
        
        let scene = TerrainDemoScene()
        sceneView.scene = scene
        
        //Add the default camera controls for iOS 11
        sceneView.pointOfView = scene.cameraNode
        sceneView.defaultCameraController.pointOfView = sceneView.pointOfView
        sceneView.defaultCameraController.interactionMode = .orbitTurntable
        sceneView.defaultCameraController.inertiaEnabled = true
        sceneView.showsStatistics = true
        
        //Set up initial terrain and materials
        let terrainNode = TerrainNode(minLat: 38.880178, maxLat: 39.041381,
                                      minLon:-77.434754, maxLon: -77.204184)
        terrainNode.position = SCNVector3(0, 500, 0)
        terrainNode.geometry?.materials = defaultMaterials()
        scene.rootNode.addChildNode(terrainNode)
        
        //Now that we've set up the terrain, lets place the lighting and camera in nicer positions
        scene.directionalLight.constraints = [SCNLookAtConstraint(target: terrainNode)]
        scene.directionalLight.position = SCNVector3Make(terrainNode.boundingBox.max.x, 5000, terrainNode.boundingBox.max.z)
        scene.cameraNode.position = SCNVector3(terrainNode.boundingBox.max.x * 2, 9000, terrainNode.boundingBox.max.z * 2)
        scene.cameraNode.look(at: terrainNode.position)
        
        //Time to hit the web API and load Mapbox data for the terrain node
        //Note, you can also wait to place the node until after this fetch has completed. It doesn't have to be in-scene to fetch.
        
        self.progressView?.progress = 0.0
        self.progressView?.isHidden = false
        
        //Progress handler is a helper to aggregate progress through the three stages causing user wait: fetching heightmap images, calculating/rendering the heightmap, fetching the texture images
        let progressHandler = ProgressCompositor(updater: { [weak self] progress in
            self?.progressView?.progress = progress
            }, completer: { [weak self] in
                self?.progressView?.isHidden = true
        })
        
        let terrainRendererHandler = progressHandler.registerForProgress()
        progressHandler.updateProgress(handlerID: terrainRendererHandler, progress: 0, total: 1)
        let terrainFetcherHandler = progressHandler.registerForProgress()
        terrainNode.fetchTerrainHeights(minWallHeight: 50.0, enableDynamicShadows: true, progress: { progress, total in
            progressHandler.updateProgress(handlerID: terrainFetcherHandler, progress: progress, total: total)
            
        }, completion: {
            progressHandler.updateProgress(handlerID: terrainRendererHandler, progress: 1, total: 1)
            
            self.addUserPath(to: terrainNode)
            NSLog("Terrain load complete")
        })
        
        let textureFetchHandler = progressHandler.registerForProgress()
        terrainNode.fetchTerrainTexture("mapbox/navigation-preview-night-v2", zoom: 15, progress: { progress, total in
            progressHandler.updateProgress(handlerID: textureFetchHandler, progress: progress, total: total)
            
        }, completion: { image in
            NSLog("Texture load complete")
            terrainNode.geometry?.materials[4].diffuse.contents = image
        })
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
    
    private func addUserPath(to terrainNode: TerrainNode) {
        
        let queryAttr = PFQuery(className: "data");
        queryAttr.whereKey("location", nearGeoPoint: self.centerPoint, withinKilometers: 16)
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
                        newNode.position = terrainNode.convertPosition(terrainNode.positionForLocation(location), to: newNode)
                        self.sceneView?.scene?.rootNode.addChildNode(newNode)
                        
                    }else if(item["type"] as! String == "Pothole"){
                        
                        let location: CLLocation = CLLocation(coordinate: clLoc, altitude: 165, horizontalAccuracy: 100, verticalAccuracy: 100, timestamp: Date())
                        let particles = SCNParticleSystem(named: "Reactorer", inDirectory: nil);
                        particles?.particleSize = 25;
                        particles?.particleColor = UIColor.blue
                        let cone = SCNCone.init(topRadius: 15, bottomRadius: 1, height: 110);
                        particles?.emitterShape = cone;
                        let sphere = SCNNode()
                        sphere.addParticleSystem(particles!);
                        sphere.position = terrainNode.convertPosition(terrainNode.positionForLocation(location), to: sphere)
                        self.sceneView?.scene?.rootNode.addChildNode(sphere)
                        
                    }else if(item["type"] as! String == "Hazard"){
                        
                        let location: CLLocation = CLLocation(coordinate: clLoc, altitude: 165, horizontalAccuracy: 100, verticalAccuracy: 100, timestamp: Date())
                        let particles = SCNParticleSystem(named: "Reactorer", inDirectory: nil);
                        particles?.particleSize = 25;
                        particles?.particleColor = UIColor.red
                        let cone = SCNCone.init(topRadius: 15, bottomRadius: 1, height: 120);
                        particles?.emitterShape = cone;
                        let sphere = SCNNode()
                        sphere.addParticleSystem(particles!);
                        sphere.position = terrainNode.convertPosition(terrainNode.positionForLocation(location), to: sphere)
                        self.sceneView?.scene?.rootNode.addChildNode(sphere)
                        
                    }else if(item["type"] as! String == "Police"){
                        
                        let location: CLLocation = CLLocation(coordinate: clLoc, altitude: 159, horizontalAccuracy: 100, verticalAccuracy: 100, timestamp: Date())
                        let newNode = self.collada2SCNNode(filepath: "1396_Police_Car/1396_Police_Car_copy.scn");
                        newNode.position = terrainNode.convertPosition(terrainNode.positionForLocation(location), to: newNode)
                        self.sceneView?.scene?.rootNode.addChildNode(newNode)
                        
                    }else if(item["type"] as! String == "Accident"){
                        
                        let location: CLLocation = CLLocation(coordinate: clLoc, altitude: 165, horizontalAccuracy: 100, verticalAccuracy: 100, timestamp: Date())
                        let particles = SCNParticleSystem(named: "Smoker", inDirectory: nil);
                        particles?.particleSize = 25;
                        particles?.particleColor = UIColor.white
                        let cone = SCNCone.init(topRadius: 10, bottomRadius: 2, height: 120);
                        particles?.emitterShape = cone;
                        let sphere = SCNNode()
                        sphere.addParticleSystem(particles!);
                        sphere.position = terrainNode.convertPosition(terrainNode.positionForLocation(location), to: sphere)
                        self.sceneView?.scene?.rootNode.addChildNode(sphere)
                        
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
                        textNode.position = terrainNode.convertPosition(terrainNode.positionForLocation(location), to: textNode)
                        self.sceneView?.scene?.rootNode.addChildNode(textNode)
                    }
                    
                }
            }
        }
    }
    
    func currentTimeMillis() -> Int64{
        let nowDouble = NSDate().timeIntervalSince1970
        return Int64(nowDouble*1000)
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
