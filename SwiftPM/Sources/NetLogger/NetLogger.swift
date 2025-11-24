import UIKit

@MainActor
public class NetLogger {
    public static let shared = NetLogger()
    
    private var overlayWindow: OverlayWindow?
    
    private init() {
        URLSession.startSwizzling()
    }
    
    public func start() {
        show()
    }
    
    // Show the logger UI
    public func show() {
        if overlayWindow == nil {
            overlayWindow = OverlayWindow()
        }
        overlayWindow?.show()
    }
    
    // Hide and cleanup
    public func hide() {
        overlayWindow?.hide()
        overlayWindow = nil
    }
}
