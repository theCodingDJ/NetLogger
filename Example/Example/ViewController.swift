import UIKit
import NetLogger

class ViewController: UIViewController {
    
    private var statusLabel: UILabel!
    
    /// Performs initial view controller setup.
    /// 
    /// Sets the view's background color and configures the view hierarchy and controls by calling `setupUI()`.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        setupUI()
    }
    
    /// Configures the view controller's user interface by creating and laying out the main stack and its child views.
    /// 
    /// Adds a centered vertical stack view and populates it with a title label, a status label (assigned to `statusLabel`), two separators, four request buttons (GET success, POST success, GET 404, error), and a primary "Show NetLogger" button. Constraints ensure the stack is centered with horizontal padding.
    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "NetLogger Example"
        titleLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        stackView.addArrangedSubview(titleLabel)
        
        // Status
        statusLabel = UILabel()
        statusLabel.text = "Ready"
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(statusLabel)
        
        // Separator
        let separator1 = createSeparator()
        stackView.addArrangedSubview(separator1)
        
        // Request buttons
        let getButton = createButton(title: "GET Request (Success)", action: #selector(getRequestTapped))
        stackView.addArrangedSubview(getButton)
        
        let postButton = createButton(title: "POST Request (Success)", action: #selector(postRequestTapped))
        stackView.addArrangedSubview(postButton)
        
        let get404Button = createButton(title: "GET Request (404)", action: #selector(get404Tapped))
        stackView.addArrangedSubview(get404Button)
        
        let errorButton = createButton(title: "Request with Error", action: #selector(errorRequestTapped))
        stackView.addArrangedSubview(errorButton)
        
        // Separator
        let separator2 = createSeparator()
        stackView.addArrangedSubview(separator2)
        
        // Show NetLogger button
        let showButton = createButton(title: "Show NetLogger", action: #selector(showNetLoggerTapped), isPrimary: true)
        stackView.addArrangedSubview(showButton)
    }
    
    private func createButton(title: String, action: Selector, isPrimary: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        if isPrimary {
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 10
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        } else {
            button.backgroundColor = .systemGray6
            button.setTitleColor(.systemBlue, for: .normal)
            button.layer.cornerRadius = 10
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray4.cgColor
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        }
        
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.widthAnchor.constraint(equalToConstant: 200).isActive = true
        return separator
    }
    
    @objc private func getRequestTapped() {
        performRequest(url: "https://jsonplaceholder.typicode.com/posts/1")
    }
    
    @objc private func postRequestTapped() {
        performRequest(url: "https://jsonplaceholder.typicode.com/posts", method: "POST", body: ["title": "foo", "body": "bar", "userId": 1])
    }
    
    @objc private func get404Tapped() {
        performRequest(url: "https://jsonplaceholder.typicode.com/posts/999999")
    }
    
    /// Triggers a network request using an intentionally invalid URL to simulate a failure.
    /// 
    /// This action is intended for the UI button; it performs a request that will fail and causes the view controller to update its status label with the resulting error.
    @objc private func errorRequestTapped() {
        performRequest(url: "https://invalid-url-that-fails.com")
    }
    
    /// Displays the NetLogger interface when the "Show NetLogger" button is tapped.
    /// Also logs a test message to the console.
    @objc private func showNetLoggerTapped() {
        print("[TEST] Show NetLogger button tapped")
        NetLogger.shared.show()
    }
    
    private func performRequest(url: String, method: String = "GET", body: [String: Any]? = nil) {
        guard let url = URL(string: url) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        statusLabel.text = "Requesting \(method) \(url.lastPathComponent)..."
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.statusLabel.text = "Error: \(error.localizedDescription)"
                } else if let response = response as? HTTPURLResponse {
                    self?.statusLabel.text = "Response: \(response.statusCode)"
                }
            }
        }.resume()
    }
}