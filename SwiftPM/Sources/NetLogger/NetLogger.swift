import UIKit

@MainActor
public class NetLogger {
    public static let shared = NetLogger()
    
    private var overlayWindow: OverlayWindow?
    
    private init() {
        URLSession.startSwizzling()
    }
    
    /// Starts the network logger and presents its overlay window.
    /// 
    /// Displays the logger overlay, creating the overlay window if one does not already exist.
    public func start() {
        show()
    }
    
    /// Ensures an overlay window exists and presents the logger UI.
    /// If no `overlayWindow` is present, allocates and stores a new `OverlayWindow`, then presents it.
    public func show() {
        if overlayWindow == nil {
            overlayWindow = OverlayWindow()
        }
        overlayWindow?.show()
    }
    
    /// Hides the logger overlay UI and clears the internal overlay window reference.
    /// 
    /// If an overlay is currently presented, it is dismissed and the internal `overlayWindow` is set to `nil`, allowing it to be deallocated. If no overlay is present, this method does nothing.
    public func hide() {
        overlayWindow?.hide()
        overlayWindow = nil
    }
}