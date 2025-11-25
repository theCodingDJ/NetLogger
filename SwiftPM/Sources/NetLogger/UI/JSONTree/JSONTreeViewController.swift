//
//  JSONTreeViewController.swift
//  NetLogger
//
//  Created by Lyubomir Marinov on 24.11.25.
//

import UIKit

final class JSONTreeViewController: UIViewController {
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorStyle = .singleLine
        table.rowHeight = 44
        return table
    }()
    
    private var rootNodes: [JSONTreeNode] = []
    private var visibleNodes: [JSONTreeNode] = []
    
    private let requestPath: String
    private let jsonString: String
    
    init(
        requestPath: String,
        jsonString: String
    ) {
        self.requestPath = requestPath
        self.jsonString = jsonString
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Performs initial view setup: sets the view title and background, configures the table view, and parses the JSON to build the visible tree.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = requestPath
        view.backgroundColor = .systemBackground
        
        setupTableView()
        parseJSON()
    }
    
    /// Configures and installs the table view into the controller's view hierarchy.
    /// 
    /// Adds `tableView` to the view, pins its edges to the view's safe area, registers
    /// `JSONTreeCell` for reuse, and assigns the view controller as the table's data source
    /// and delegate.
    private func setupTableView() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        tableView.register(JSONTreeCell.self, forCellReuseIdentifier: JSONTreeCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    /// Parses `jsonString` into the controller's tree model and updates the table view.
    /// Attempts to parse `jsonString` into `rootNodes`, rebuilds `visibleNodes`, and reloads `tableView`. On parse failure presents an error alert via `showError(_:)`.
    private func parseJSON() {
        do {
            rootNodes = try JSONTreeParser.parse(jsonString: jsonString)
            rebuildVisibleNodes()
            tableView.reloadData()
        } catch {
            showError(error)
        }
    }
    
    /// Rebuilds the flat list of nodes currently visible in the table view.
    /// 
    /// Clears `visibleNodes` and appends nodes by traversing `rootNodes`, including a node's children only when that node is expanded.
    private func rebuildVisibleNodes() {
        visibleNodes = []
        for rootNode in rootNodes {
            collectVisibleNodes(node: rootNode)
        }
    }
    
    /// Adds the given node to `visibleNodes` and, if the node is expanded, also adds its expanded descendant nodes in depth-first order.
    /// - Parameter node: The starting `JSONTreeNode` to append; its children are included only when `node.isExpanded` is true.
    private func collectVisibleNodes(node: JSONTreeNode) {
        visibleNodes.append(node)
        
        if node.isExpanded {
            for child in node.children {
                collectVisibleNodes(node: child)
            }
        }
    }
    
    /// Toggles the expansion state of the node shown at the given visible row and updates the table view to reflect the change.
    /// 
    /// Expands or collapses the node at `index`, updates the visible node list, inserts or deletes the affected rows with a fade animation, and reloads the toggled row to update its disclosure indicator.
    /// - Parameters:
    ///   - index: The row index in `visibleNodes` / the table view corresponding to the node to toggle.
    private func toggleNode(at index: Int) {
        let node = visibleNodes[index]
        
        guard node.hasChildren else { return }
        
        node.isExpanded.toggle()
        
        let oldVisibleCount = visibleNodes.count
        rebuildVisibleNodes()
        let newVisibleCount = visibleNodes.count
        
        /// Calculate affected rows.
        let addedCount = newVisibleCount - oldVisibleCount
        
        if addedCount > 0 {
            /// Expanding - insert rows.
            let indexPaths = (1...addedCount).map { offset in
                IndexPath(row: index + offset, section: 0)
            }
            tableView.insertRows(at: indexPaths, with: .fade)
        } else if addedCount < 0 {
            /// Collapsing - delete rows.
            let indexPaths = (1...abs(addedCount)).map { offset in
                IndexPath(row: index + offset, section: 0)
            }
            tableView.deleteRows(at: indexPaths, with: .fade)
        }
        
        /// Reload the toggled cell to update chevron.
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
    
    /// Presents an alert titled "JSON Parse Error" displaying the given error's localized description with an "OK" button.
    /// - Parameters:
    ///   - error: The error whose `localizedDescription` will be shown in the alert message.
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "JSON Parse Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension JSONTreeViewController: UITableViewDataSource {
    /// Provides the number of rows for the table view based on the currently visible JSON tree nodes.
    /// - Returns: The count of `visibleNodes`, representing how many rows should be displayed.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleNodes.count
    }
    
    /// Provides a table view cell configured for the JSON tree node at the specified index path.
    /// - Parameters:
    ///   - tableView: The table view requesting the cell.
    ///   - indexPath: The index path identifying the row to display.
    /// - Returns: A `UITableViewCell` configured for the corresponding `JSONTreeNode` from `visibleNodes`; returns a default `UITableViewCell` if dequeuing the custom `JSONTreeCell` fails.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: JSONTreeCell.reuseIdentifier,
            for: indexPath
        ) as? JSONTreeCell else {
            return UITableViewCell()
        }
        
        let node = visibleNodes[indexPath.row]
        cell.configure(with: node)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension JSONTreeViewController: UITableViewDelegate {
    /// Handles selection of a table row by toggling the corresponding JSON tree node's expansion state.
    /// - Parameters:
    ///   - tableView: The table view containing the selected row.
    ///   - indexPath: The index path of the selected row.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        toggleNode(at: indexPath.row)
    }
}