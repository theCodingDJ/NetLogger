import UIKit

@MainActor
class ExternalDisplayManager {
    private var externalWindow: UIWindow?
    
    func setup(screen: UIScreen) {
        guard externalWindow == nil else { return }
        
        // Find the window scene for this screen
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.screen == screen }) else {
            print("[NetLogger] Could not find window scene for external screen")
            return
        }
        
        let window = UIWindow(windowScene: windowScene)
        
        // Show request list on external display
        let listVC = RequestListViewController()
        let navController = UINavigationController(rootViewController: listVC)
        
        window.rootViewController = navController
        window.isHidden = false
        
        externalWindow = window
    }
    
    func teardown() {
        externalWindow?.isHidden = true
        externalWindow = nil
    }
    
    var isActive: Bool {
        externalWindow != nil
    }
}
