import UIKit

/// A transparent overlay window that shows a draggable "NL" button
/// Tapping the button shows/hides the network request list
class OverlayWindow: UIWindow {
    
    private var floatingButton: UIButton!
    private var isShowingRequestList = false
    
    convenience init() {
        self.init(frame: UIScreen.main.bounds)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupWindow()
        setupFloatingButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupWindow() {
        backgroundColor = .clear
        windowLevel = .statusBar + 100  // Above most UI
        
        // Need a root VC for presenting modals
        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .clear
        rootViewController = rootVC
    }
    
    private func setupFloatingButton() {
        floatingButton = UIButton(type: .custom)
        floatingButton.setTitle("NL", for: .normal)
        floatingButton.backgroundColor = .black
        floatingButton.setTitleColor(.white, for: .normal)
        floatingButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        floatingButton.layer.cornerRadius = 25
        floatingButton.frame = CGRect(x: 20, y: 100, width: 50, height: 50)
        
        // Tap to show/hide request list
        floatingButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        // Drag to move around
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrag))
        floatingButton.addGestureRecognizer(panGesture)
        
        rootViewController?.view.addSubview(floatingButton)
    }
    
    // MARK: - Actions
    
    @objc private func buttonTapped() {
        if isShowingRequestList {
            hideRequestList()
        } else {
            showRequestList()
        }
    }
    
    private func showRequestList() {
        guard let rootVC = rootViewController else { return }
        
        let listVC = RequestListViewController()
        let navController = UINavigationController(rootViewController: listVC)
        navController.modalPresentationStyle = .fullScreen
        
        rootVC.present(navController, animated: true)
        isShowingRequestList = true
    }
    
    private func hideRequestList() {
        rootViewController?.dismiss(animated: true) {
            self.isShowingRequestList = false
        }
    }
    
    @objc private func handleDrag(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: rootViewController?.view)
        
        guard let button = gesture.view else { return }
        button.center = CGPoint(
            x: button.center.x + translation.x,
            y: button.center.y + translation.y
        )
        
        gesture.setTranslation(.zero, in: rootViewController?.view)
    }
    
    // MARK: - Show/Hide
    
    func show() {
        isHidden = false
    }
    
    func hide() {
        isHidden = true
    }
    
    // MARK: - Touch Handling
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // If showing request list, accept all touches
        if isShowingRequestList {
            return super.point(inside: point, with: event)
        }
        
        // Otherwise only accept touches on the button
        return floatingButton.frame.contains(point)
    }
}
