import UIKit

class RequestDetailViewController: UIViewController {
    
    private let request: HTTPRequestLog
    private var scrollView: UIScrollView!
    private var contentStackView: UIStackView!
    
    init(request: HTTPRequestLog) {
        self.request = request
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Request Details"
        
        setupScrollView()
        displayRequestDetails()
    }
    
    /// Configures the scrolling container and its content stack for the request details view.
    /// 
    /// Creates a vertically-bouncing `UIScrollView` pinned to the view's safe area and a vertical `UIStackView` inside it used to host all detail content. The stack view is given 20pt spacing, 16pt content insets from the scroll view edges, and a width constraint that matches the scroll view width minus the horizontal insets.
    private func setupScrollView() {
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    private func displayRequestDetails() {
        // Request Section
        addSectionHeader("REQUEST")
        addInfoRow("URL", value: request.url?.absoluteString ?? "N/A")
        addInfoRow("Method", value: request.method ?? "GET")
        addInfoRow("Time", value: formatDate(request.date))
        
        if let duration = request.duration {
            addInfoRow("Duration", value: String(format: "%.3f seconds", duration))
        }
        
        // Request Headers
        if let headers = request.headers, !headers.isEmpty {
            addSectionHeader("REQUEST HEADERS")
            addHeadersTable(headers)
        }
        
        // Request Body
        if let body = request.body {
            addSectionHeader("REQUEST BODY")
            addCodeBlock(formatData(body))
        }
        
        // Response Section
        if let response = request.response {
            addSectionHeader("RESPONSE")
            
            let statusColor: UIColor
            if response.statusCode >= 200 && response.statusCode < 300 {
                statusColor = .systemGreen
            } else if response.statusCode >= 400 {
                statusColor = .systemRed
            } else {
                statusColor = .systemOrange
            }
            
            addInfoRow("Status Code", value: "\(response.statusCode)", valueColor: statusColor)
            addInfoRow("Time", value: formatDate(response.date))
            
            // Response Headers
            if let headers = response.headers, !headers.isEmpty {
                addSectionHeader("RESPONSE HEADERS")
                addHeadersTable(headers)
            }
            
            // Response Body
            if let body = response.body {
                addSectionHeader("RESPONSE BODY")
                addCodeBlock(formatData(body))
            }
        }
        
        // Error Section
        if let error = request.error {
            addSectionHeader("ERROR")
            addInfoRow("Description", value: error.localizedDescription)
            addInfoRow("Domain", value: error.domain)
            addInfoRow("Code", value: "\(error.code)")
        }
    }
    
    private func addSectionHeader(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = .secondaryLabel
        contentStackView.addArrangedSubview(label)
        
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        contentStackView.addArrangedSubview(separator)
    }
    
    private func addInfoRow(_ label: String, value: String, valueColor: UIColor = .label) {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        labelView.textColor = .secondaryLabel
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let valueView = UILabel()
        valueView.text = value
        valueView.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        valueView.textColor = valueColor
        valueView.numberOfLines = 0
        valueView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(labelView)
        containerView.addSubview(valueView)
        
        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: containerView.topAnchor),
            labelView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            labelView.widthAnchor.constraint(equalToConstant: 100),
            
            valueView.topAnchor.constraint(equalTo: containerView.topAnchor),
            valueView.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 12),
            valueView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            valueView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        contentStackView.addArrangedSubview(containerView)
    }
    
    private func addHeadersTable(_ headers: [String: String]) {
        let tableContainer = UIView()
        tableContainer.backgroundColor = .secondarySystemBackground
        tableContainer.layer.cornerRadius = 8
        tableContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 1
        stackView.translatesAutoresizingMaskIntoConstraints = false
        tableContainer.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: tableContainer.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: tableContainer.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: tableContainer.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: tableContainer.bottomAnchor, constant: -12)
        ])
        
        for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
            let rowView = createHeaderRow(key: key, value: value)
            stackView.addArrangedSubview(rowView)
        }
        
        contentStackView.addArrangedSubview(tableContainer)
    }
    
    private func createHeaderRow(key: String, value: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let keyLabel = UILabel()
        keyLabel.text = key
        keyLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
        keyLabel.textColor = .label
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        keyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        valueLabel.textColor = .secondaryLabel
        valueLabel.numberOfLines = 0
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(keyLabel)
        containerView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            keyLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            keyLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            keyLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -4),
            
            valueLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: keyLabel.trailingAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
        ])
        
        return containerView
    }
    
    /// Adds a monospaced, read-only code block showing `text` and a pair of action buttons to the view's content stack.
    /// - Parameter text: The string to display in the code block. If the string contains JSON, the "View JSON Tree" action will present a JSON tree viewer for this content; the "Copy JSON" action copies the string to the system pasteboard and presents a confirmation alert. The created views are appended to `contentStackView`.
    private func addCodeBlock(_ text: String) {
        let textView = UITextView()
        textView.text = text
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 8
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        let viewJsonButton = UIButton(primaryAction: UIAction { _ in
            self.showJsonTree(for: text)
        })
        viewJsonButton.setImage(UIImage(systemName: "list.bullet.indent"), for: .normal)
        viewJsonButton.tintColor = .white
        viewJsonButton.backgroundColor = .systemPink
        viewJsonButton.layer.cornerRadius = 4
        viewJsonButton.translatesAutoresizingMaskIntoConstraints = false
        
        let copyJsonButton = UIButton(primaryAction: UIAction { _ in
            UIPasteboard.general.string = text
            
            let alertController = UIAlertController(title: "Copied!", message: "The JSON string is now in your pasteboard.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alertController, animated: true)
        })
        copyJsonButton.setImage(UIImage(systemName: "doc.on.clipboard"), for: .normal)
        copyJsonButton.tintColor = .white
        copyJsonButton.backgroundColor = .systemTeal
        copyJsonButton.layer.cornerRadius = 4
        copyJsonButton.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonStackView = UIStackView(arrangedSubviews: [UIView(), viewJsonButton, copyJsonButton])
        buttonStackView.spacing = 4
        buttonStackView.alignment = .fill
        buttonStackView.distribution = .fill
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            viewJsonButton.widthAnchor.constraint(equalToConstant: 40),
            viewJsonButton.heightAnchor.constraint(equalToConstant: 40),
            copyJsonButton.widthAnchor.constraint(equalToConstant: 40),
            copyJsonButton.heightAnchor.constraint(equalToConstant: 40),
            buttonStackView.heightAnchor.constraint(equalToConstant: 40),
        ])
        
        contentStackView.addArrangedSubview(buttonStackView)
        contentStackView.setCustomSpacing(2, after: buttonStackView)
        contentStackView.addArrangedSubview(textView)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Formats raw data for display, preferring pretty-printed JSON, then UTF-8 text, and finally a hex representation.
    /// - Parameter data: The raw data to format for presentation.
    /// - Returns: A string containing pretty-printed JSON if `data` is JSON, a UTF-8 decoded string if it is valid text, or a space-separated hex byte sequence as a last resort.
    private func formatData(_ data: Data) -> String {
        // Try to parse as JSON first
        if let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }
        
        // Otherwise, just show as string
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        // Last resort: show as hex
        return data.map { String(format: "%02x", $0) }.joined(separator: " ")
    }
    
    /// Presents a JSON tree viewer configured with the current request's URL path and the provided JSON string, and pushes it onto the navigation stack.
    /// - Parameter json: The JSON string to display in the JSON tree viewer.
    private func showJsonTree(for json: String) {
        let path = request.url?.path ?? "Unknown"
        
        let viewController = JSONTreeViewController(
            requestPath: path,
            jsonString: json
        )
        navigationController?.pushViewController(viewController, animated: true)
    }
}