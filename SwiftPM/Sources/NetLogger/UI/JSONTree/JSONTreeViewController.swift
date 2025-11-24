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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = requestPath
        view.backgroundColor = .systemBackground
        
        setupTableView()
        parseJSON()
    }
    
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
    
    private func parseJSON() {
        do {
            rootNodes = try JSONTreeParser.parse(jsonString: jsonString)
            rebuildVisibleNodes()
            tableView.reloadData()
        } catch {
            showError(error)
        }
    }
    
    private func rebuildVisibleNodes() {
        visibleNodes = []
        for rootNode in rootNodes {
            collectVisibleNodes(node: rootNode)
        }
    }
    
    private func collectVisibleNodes(node: JSONTreeNode) {
        visibleNodes.append(node)
        
        if node.isExpanded {
            for child in node.children {
                collectVisibleNodes(node: child)
            }
        }
    }
    
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleNodes.count
    }
    
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        toggleNode(at: indexPath.row)
    }
}
