import UIKit

class RequestListViewController: UIViewController {
    
    private var tableView: UITableView!
    private var searchController: UISearchController!
    private var requests: [HTTPRequestLog] = []
    private var filteredRequests: [HTTPRequestLog] = []
    
    private var isSearching: Bool {
        searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        setupSearchController()
        setupNavigationBar()
        setupTableView()
        loadRequests()
        
        /// Listen for new network requests.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(requestsDidChange),
            name: NSNotification.Name("NetLoggerRequestsChanged"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search requests..."
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func setupNavigationBar() {
        title = "Network Requests"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(clearTapped)
        )
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RequestCell")
        tableView.separatorInset = .zero
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    // MARK: - Data
    
    private func loadRequests() {
        requests = NetRecorder.shared.requests
        filterRequests()
    }
    
    private func filterRequests() {
        if isSearching, let searchText = searchController.searchBar.text?.lowercased() {
            // Filter by URL, method, or status code
            filteredRequests = requests.filter { request in
                let url = request.url?.absoluteString.lowercased() ?? ""
                let method = request.method?.lowercased() ?? ""
                let statusCode = request.response.map { String($0.statusCode) } ?? ""
                
                return url.contains(searchText) || 
                       method.contains(searchText) || 
                       statusCode.contains(searchText)
            }
        } else {
            filteredRequests = requests
        }
        tableView.reloadData()
    }
    
    @objc private func requestsDidChange() {
        DispatchQueue.main.async {
            self.loadRequests()
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true) {
            NetLogger.shared.hide()
            NetLogger.shared.show()
        }
    }
    
    @objc private func clearTapped() {
        NetRecorder.shared.clear()
        loadRequests()
    }
}


// MARK: - Table View

extension RequestListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredRequests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath)
        let request = filteredRequests[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        
        // Main text: "GET /posts/1"
        let method = request.method ?? "GET"
        let path = request.url?.path ?? "Unknown"
        config.text = "\(method) \(path)"
        
        // Secondary text: status code or error
        if let response = request.response {
            let statusText = "\(response.statusCode)"
            let color = statusColor(for: response.statusCode)
            
            cell.backgroundColor = color.withAlphaComponent(0.12)

            config.secondaryText = statusText
            config.secondaryTextProperties.color = config.textProperties.color.withAlphaComponent(0.6)
        } else if request.error != nil {
            config.secondaryText = "Error"
            config.secondaryTextProperties.color = .systemRed
        } else {
            config.secondaryText = "Loading..."
            config.secondaryTextProperties.color = .systemGray
        }
        
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let request = filteredRequests[indexPath.row]
        let detailVC = RequestDetailViewController(request: request)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // Helper to get color for status code
    private func statusColor(for code: Int) -> UIColor {
        switch code {
        case 200..<300: return .systemGreen
        case 400...: return .systemRed
        default: return .systemOrange
        }
    }
}

// MARK: - Search

extension RequestListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterRequests()
    }
}
