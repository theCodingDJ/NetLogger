import UIKit

public enum PresentationMode {
    case overlay            // Floating button overlay
    case externalDisplay    // Show on external screen if available
}

@MainActor
public class NetLogger {
    public static let shared = NetLogger()
    
    // When mode changes, update how we're displaying
    public var mode: PresentationMode = .overlay {
        didSet { updatePresentation() }
    }
    
    private var overlayWindow: OverlayWindow?
    private var externalDisplayManager = ExternalDisplayManager()
    
    private init() {
        // Watch for external displays being connected/disconnected
        observeExternalDisplays()
    }
    
    // Call this in your AppDelegate to start logging network requests
    public func start() {
        URLSession.startSwizzling()
    }
    
    // Show the logger UI
    public func show() {
        updatePresentation()
    }
    
    // Hide and cleanup
    public func hide() {
        overlayWindow?.hide()
        overlayWindow = nil
        externalDisplayManager.teardown()
    }
    
    // MARK: - Private
    
    private func updatePresentation() {
        switch mode {
        case .overlay:
            // Clean up external display if it was active
            externalDisplayManager.teardown()
            
            // Create overlay window if needed
            if overlayWindow == nil {
                overlayWindow = OverlayWindow()
            }
            overlayWindow?.show()
            
        case .externalDisplay:
            // Try to use external screen, fallback to overlay if not available
            if let externalScreen = UIScreen.screens.first(where: { $0 != UIScreen.main }) {
                overlayWindow?.hide()
                overlayWindow = nil
                externalDisplayManager.setup(screen: externalScreen)
            } else {
                // No external display found, use overlay instead
                print("[NetLogger] No external display found, using overlay")
                externalDisplayManager.teardown()
                if overlayWindow == nil {
                    overlayWindow = OverlayWindow()
                }
                overlayWindow?.show()
            }
        }
    }
    
    private func observeExternalDisplays() {
        // When external display connects
        NotificationCenter.default.addObserver(
            forName: UIScreen.didConnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if self?.mode == .externalDisplay {
                self?.updatePresentation()
            }
        }
        
        // When external display disconnects
        NotificationCenter.default.addObserver(
            forName: UIScreen.didDisconnectNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePresentation()
        }
    }
}
