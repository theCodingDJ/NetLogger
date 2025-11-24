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
    static func parse(jsonString: String) throws -> [JSONTreeNode] {
        guard let data = jsonString.data(using: .utf8) else {
            throw NSError(domain: "JSONTreeParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid UTF-8 string"])
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        return parseValue(jsonObject, key: nil, level: 0)
    }
    
    private static func parseValue(_ value: Any, key: String?, level: Int) -> [JSONTreeNode] {
        if let dict = value as? [String: Any] {
            return parseDictionary(dict, key: key, level: level)
        } else if let array = value as? [Any] {
            return parseArray(array, key: key, level: level)
        } else {
            return [parsePrimitive(value, key: key, level: level)]
        }
    }
    
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

