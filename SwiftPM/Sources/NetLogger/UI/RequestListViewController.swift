import UIKit

class RequestListViewController: UIViewController {
    
    private var tableView: UITableView!
    private var searchController: UISearchController!
    private var requests: [HTTPRequestLog] = []
    private var filteredRequests: [HTTPRequestLog] = []
    
    private var isSearching: Bool {
        searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    
    /// Performs initial UI and data setup after the view is loaded.
    /// Configures the background, search controller, navigation bar, and table view, loads stored requests, and registers for `NetLoggerRequestsChanged` notifications to refresh data when requests change.
    
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
    
    /// Configures, registers, and adds the table view used to display the list of network requests.
    /// 
    /// Sets the table view's delegate and data source, registers the reusable cell with identifier
    /// "RequestCell", disables automatic resizing mask translation, removes separator inset, and
    /// pins the table view to the view's safe area using Auto Layout constraints.
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
    
    /// Dismisses this view controller and refreshes NetLogger's visibility.
    /// 
    /// Called by the close action; dismisses the view controller and toggles NetLogger (hide then show) to refresh its UI/state.
    
    @objc private func closeTapped() {
        dismiss(animated: true) {
            NetLogger.shared.hide()
            NetLogger.shared.show()
        }
    }
    
    /// Clears all recorded network requests and refreshes the displayed list.
    /// 
    /// Removes every entry from the shared NetRecorder and reloads the controller's request data so the UI reflects the cleared state.
    @objc private func clearTapped() {
        NetRecorder.shared.clear()
        loadRequests()
    }
}


// MARK: - Table View

extension RequestListViewController: UITableViewDelegate, UITableViewDataSource {
    
    /// Provides the number of rows for the table view's section.
    /// - Parameter section: The section index (ignored; this list uses a single section).
    /// - Returns: The number of filtered requests to display as rows.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredRequests.count
    }
    
    /// Configure and return a table view cell representing the HTTP request at the given index path.
    /// 
    /// The cell's main text is the request method and URL path (e.g., "GET /posts/1"). The secondary text shows the response status code, `"Error"` if the request failed, or `"Loading..."` if the request is in progress. When a response is present the cell receives a lightly tinted background color derived from the status code and the secondary text color is drawn with reduced opacity.
    /// - Returns: A configured `UITableViewCell` for the request at `indexPath`.
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