import UIKit
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.statusBarStyle = .lightContent
        let configuration = ParseClientConfiguration {
            $0.applicationId = ""
            $0.clientKey = ""
            $0.server = ""
            $0.isLocalDatastoreEnabled = true;
        }
        Parse.initialize(with: configuration)
        return true
    }
}

