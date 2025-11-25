//
//  JSONTreeParser.swift
//  NetLogger
//
//  Created by Lyubomir Marinov on 24.11.25.
//

import UIKit

enum JSONNodeType {
    case object
    case array
    case string
    case number
    case boolean
    case null
    
    var displayName: String {
        switch self {
        case .object: return "Object"
        case .array: return "Array"
        case .string: return "String"
        case .number: return "Number"
        case .boolean: return "Bool"
        case .null: return "Null"
        }
    }
    
    var color: UIColor {
        switch self {
        case .object: return .systemBlue
        case .array: return .systemPurple
        case .string: return .systemGreen
        case .number: return .systemOrange
        case .boolean: return .systemPink
        case .null: return .systemGray
        }
    }
}

final class JSONTreeNode {
    let key: String?
    let value: Any?
    let type: JSONNodeType
    let level: Int
    var isExpanded: Bool
    let children: [JSONTreeNode]

    init(key: String? = nil, value: Any?, type: JSONNodeType, level: Int, children: [JSONTreeNode] = []) {
        self.key = key
        self.value = value
        self.type = type
        self.level = level
        self.isExpanded = false
        self.children = children
    }

    var hasChildren: Bool {
        !children.isEmpty
    }

    var displayValue: String {
        if hasChildren {
            let count = children.count
            switch type {
            case .object:
                return "{\(count) \(count == 1 ? "key" : "keys")}"
            case .array:
                return "[\(count) \(count == 1 ? "item" : "items")]"
            default:
                return ""
            }
        }

        switch type {
        case .string:
            return "\"\(value as? String ?? "")\""
        case .number:
            return "\(value ?? "")"
        case .boolean:
            return "\(value as? Bool ?? false)"
        case .null:
            return "null"
        default:
            return ""
        }
    }
}

final class JSONTreeParser {
    /// Parse a JSON string into a hierarchical array of `JSONTreeNode` representing the top-level JSON structure.
    /// - Parameter jsonString: A UTF-8 encoded JSON text to parse.
    /// - Returns: An array of `JSONTreeNode` representing the parsed JSON tree (one or more root nodes).
    /// - Throws: An `NSError` with domain "JSONTreeParser" if the input cannot be converted to UTF-8 data; any error thrown by `JSONSerialization.jsonObject(with:)` for invalid JSON.
    static func parse(jsonString: String) throws -> [JSONTreeNode] {
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "JSONTreeParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 string"])
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        return parseValue(jsonObject, key: nil, level: 0)
    }
    
    /// Creates JSON tree nodes for a decoded JSON value, dispatching to the appropriate parser based on the value's runtime type.
    /// - Parameters:
    ///   - value: A decoded JSON value (Dictionary, Array, or primitive) to convert into tree node(s).
    ///   - key: Optional key associated with the value; used as the node's key when provided.
    ///   - level: Depth level for the generated node(s) in the tree.
    /// - Returns: An array of `JSONTreeNode` representing the parsed value. For objects and arrays this is a single parent node containing child nodes; for primitives this is a single leaf node.
    private static func parseValue(_ value: Any, key: String?, level: Int) -> [JSONTreeNode] {
        if let dict = value as? [String: Any] {
            return parseDictionary(dict, key: key, level: level)
        } else if let array = value as? [Any] {
            return parseArray(array, key: key, level: level)
        } else {
            return [parsePrimitive(value, key: key, level: level)]
        }
    }
    
    /// Creates a single object node representing `dict` and its parsed children.
    /// - Parameters:
    ///   - dict: The dictionary representing a JSON object to convert into a tree node.
    ///   - key: An optional key to assign to the created node (nil for root-level objects).
    ///   - level: The depth level of the created node within the tree (root is 0).
    /// - Returns: An array containing the object `JSONTreeNode` whose children are the parsed entries of `dict`, ordered by key.
    private static func parseDictionary(_ dict: [String: Any], key: String?, level: Int) -> [JSONTreeNode] {
        let children = dict.sorted { $0.key < $1.key }.flatMap { kvp in
            parseValue(kvp.value, key: kvp.key, level: level + 1)
        }
        
        let node = JSONTreeNode(
            key: key,
            value: dict,
            type: .object,
            level: level,
            children: children
        )
        
        return [node]
    }
    
    /// Creates a `JSONTreeNode` representing the given JSON array and parses its elements into child nodes.
    /// - Parameters:
    ///   - array: The JSON array to convert into a tree node.
    ///   - key: Optional key for the created node (for example `"[0]"` when used as a child); may be `nil` for root arrays.
    ///   - level: Depth level of the created node in the JSON tree.
    /// - Returns: An array containing a single `JSONTreeNode` for the provided array whose children are the parsed elements (each child is keyed by its index in the form `"[index]"`).
    private static func parseArray(_ array: [Any], key: String?, level: Int) -> [JSONTreeNode] {
        let children = array.enumerated().flatMap { index, element in
            parseValue(element, key: "[\(index)]", level: level + 1)
        }
        
        let node = JSONTreeNode(
            key: key,
            value: array,
            type: .array,
            level: level,
            children: children
        )
        
        return [node]
    }
    
    /// Creates a JSONTreeNode representing a primitive JSON value (string, number, boolean, or null).
    /// - Parameters:
    ///   - value: The primitive value to convert into a node. `NSNumber` values are interpreted as `boolean` when they are actual booleans, otherwise as `number`.
    ///   - key: The optional key associated with this value in its parent container.
    ///   - level: The depth level of the node in the tree.
    /// - Returns: A `JSONTreeNode` whose `key`, `value`, `type`, and `level` reflect the given inputs.
    private static func parsePrimitive(_ value: Any, key: String?, level: Int) -> JSONTreeNode {
        let type: JSONNodeType
        
        if value is String {
            type = .string
        } else if value is NSNumber {
            // Check if it's a boolean (NSNumber can represent both numbers and booleans)
            let number = value as! NSNumber
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                type = .boolean
            } else {
                type = .number
            }
        } else if value is NSNull {
            type = .null
        } else {
            type = .null
        }
        
        return JSONTreeNode(
            key: key,
            value: value,
            type: type,
            level: level
        )
    }
}
