//
//  JSONTreeCell.swift
//  NetLogger
//
//  Created by Lyubomir Marinov on 24.11.25.
//

import UIKit

final class JSONTreeCell: UITableViewCell {
    
    static let reuseIdentifier = "JSONTreeCell"
    
    private let nodeIndentationWidth: CGFloat = 20
    private let chevronSize: CGFloat = 20
    
    private lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var keyLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var typeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var leadingConstraint: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .systemBackground
        
        contentView.addSubview(chevronImageView)
        contentView.addSubview(keyLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(typeLabel)
        
        leadingConstraint = chevronImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        
        NSLayoutConstraint.activate([
            leadingConstraint,
            chevronImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: chevronSize),
            chevronImageView.heightAnchor.constraint(equalToConstant: chevronSize),
            
            keyLabel.leadingAnchor.constraint(equalTo: chevronImageView.trailingAnchor, constant: 8),
            keyLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            keyLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 150),
            
            valueLabel.leadingAnchor.constraint(equalTo: keyLabel.trailingAnchor, constant: 8),
            valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            valueLabel.trailingAnchor.constraint(lessThanOrEqualTo: typeLabel.leadingAnchor, constant: -8),
            
            typeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            typeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            typeLabel.widthAnchor.constraint(equalToConstant: 60),
            typeLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with node: JSONTreeNode) {
        /// Set indentation.
        let indentation = CGFloat(node.level) * nodeIndentationWidth
        leadingConstraint.constant = 12 + indentation
        
        /// Set chevron.
        if node.hasChildren {
            let chevronImage = node.isExpanded ?
                UIImage(systemName: "chevron.down") :
                UIImage(systemName: "chevron.right")
            chevronImageView.image = chevronImage
            chevronImageView.isHidden = false
        } else {
            chevronImageView.isHidden = true
        }
        
        /// Set key.
        if let key = node.key {
            keyLabel.text = key
            keyLabel.isHidden = false
        } else {
            keyLabel.isHidden = true
        }
        
        /// Set value.
        valueLabel.text = node.displayValue
        
        // Set type badge
        typeLabel.text = node.type.displayName
        typeLabel.textColor = .white
        typeLabel.backgroundColor = node.type.color
    }
}
