import UIKit
import NetLogger

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    /// Performs application startup tasks and configures the main window.
    /// 
    /// Starts the shared NetLogger instance, creates the main UIWindow, assigns its root view controller, and makes the window visible.
    /// - Parameters:
    ///   - application: The singleton app object.
    ///   - launchOptions: A dictionary indicating the reason the app was launched, if any.
    /// - Returns: `true` if the app finished launching successfully, `false` otherwise.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Start NetLogger
        NetLogger.shared.start()
        
        // Create window and root view controller
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        
        return true
    }
}