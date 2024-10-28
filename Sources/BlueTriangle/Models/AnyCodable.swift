//
//  AnyCodable.swift
//
//  Created by Mathew Gacy on 1/26/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

/// A wrapper for `Codable` values.
public enum AnyCodable: Codable, Equatable, Hashable {

    /// An error that occurs when trying to wrap a value in an ``AnyCodable`` instance.
    public struct AnyCodableError: Error {
        /// The reason for the error.
        public let reason: String
    }

    /// A case representing a `nil` value.
    case none
    /// A case wrapping a `Bool` value.
    case bool(Bool)
    /// A case wrapping a `Double` value.
    case double(Double)
    /// A case wrapping an `Int` value.
    case int(Int)
    /// A case wrapping an `Int64` value.
    ///
    /// > Note: once encoded, `Int64` values will be decoded as `Int`s.
    case int64(Int64)
    /// A case wrapping a `UInt64` value.
    ///
    /// > Note: once encoded, `UInt64` values that fall within the range of allowable `Int64`
    /// values will be decoded as `Int64`.
    case uint64(UInt64)
    /// A case wrapping a `Date` value.
    ///
    /// > Note: date values should be encoded and decoded using an `iso8601` date encoding /
    /// decoding strategy.
    case date(Date)
    /// A case wrapping a `URL` value.
    ///
    /// > Note: once encoded, `URL` values will be decoded as `String`s.
    case url(URL)
    /// A case wrapping a `String` value.
    case string(String)
    /// A case wrapping an `Array` of `AnyCodable` values.
    case array([AnyCodable])
    /// A case wrapping a `Dictionary` value.
    case dictionary([String: AnyCodable])

    /// Creates a new instance by wrapping the given NSNumber.
    /// - Parameter value: The number to wrap.
    public init(_ value: NSNumber) throws {
        switch value.numberType() {
        case .bool(let value):
            self = .bool(value)
        case .double(let value):
            self = .double(value)
        case .int(let value):
            self = .int(value)
        case .unknown:
            throw AnyCodableError(reason: "Unable to wrap \(String(describing: value))")
        }
    }

    /// Creates a new instance by wrapping the given value.
    /// - Parameter value: The value to wrap.
    public init(_ value: Any) throws {
        switch value {
        case Optional<Any>.none:
            self = .none
        case let bool as Bool:
            self = .bool(bool)
        case let double as Double:
            self = .double(double)
        case let int as Int:
            self = .int(int)
        case let int64 as Int64:
            self = .int64(int64)
        case let uint64 as UInt64:
            self = .uint64(uint64)
        case let date as Date:
            self = .date(date)
        case let url as URL:
            self = .url(url)
        case let string as String:
            self = .string(string)
        case let array as [Any]:
            self = .array(try array.map(Self.init))
        case let dictionary as [String: Any]:
            self = .dictionary(try dictionary.mapValues(Self.init))
        case let anyCodable as AnyCodable:
            self = anyCodable
        default:
            throw AnyCodableError(reason: "Unable to wrap \(String(describing: value))")
        }
    }

    /// Creates a new instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .none
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let uint64 = try? container.decode(UInt64.self) {
            self = .uint64(uint64)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let date = try? container.decode(Date.self) {
            self = .date(date)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([Self].self) {
            self =  .array(array)
        } else if let dictionary = try? container.decode([String: Self].self) {
            self = .dictionary(dictionary)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode JSON")
        }
    }

    /// Encodes this value into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .none:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .int64(let value):
            try container.encode(value)
        case .uint64(let value):
            try container.encode(value)
        case .date(let value):
            try container.encode(value)
        case .url(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        }
    }
}

// MARK: - Associated Value Access
public extension AnyCodable {
    /// The type-erased wrapped value.
    var anyValue: Any {
        switch self {
        case .none:
            return Optional<Any>.none as Any
        case .bool(let bool):
            return bool as Any
        case .double(let double):
            return double as Any
        case .int(let int):
            return int as Any
        case .int64(let int64):
            return int64 as Any
        case .uint64(let uint64):
            return uint64 as Any
        case .date(let date):
            return date as Any
        case .url(let url):
            return url as Any
        case .string(let string):
            return string as Any
        case .array(let array):
            return array.compactMap { $0.anyValue } as Any
        case .dictionary(let dictionary):
            return dictionary.compactMapValues { $0.anyValue } as Any
        }
    }

    /// The wrapped array if one exists.
    var arrayValue: [AnyCodable]? {
        switch self {
        case .array(let array): return array
        default: return nil
        }
    }

    /// The wrapped Boolean if one exists.
    var boolValue: Bool? {
        switch self {
        case .bool(let bool): return bool
        default: return nil
        }
    }

    /// The wrapped date if one exists.
    var dateValue: Date? {
        switch self {
        case .date(let date): return date
        default: return nil
        }
    }

    /// The wrapped dictionary if one exists.
    var dictionaryValue: [String: AnyCodable]? {
        switch self {
        case .dictionary(let dictionary): return dictionary
        default: return nil
        }
    }

    /// The wrapped double if one exists.
    var doubleValue: Double? {
        switch self {
        case .double(let double): return double
        default: return nil
        }
    }

    /// The wrapped integer if one exists.
    var intValue: Int? {
        switch self {
        case .int(let int): return int
        default: return nil
        }
    }

    /// The wrapped `Int64` if one exists.
    var int64Value: Int64? {
        switch self {
        case .int64(let int64): return int64
        default: return nil
        }
    }

    /// The wrapped string if one exists.
    var stringValue: String? {
        switch self {
        case .string(let string): return string
        default: return nil
        }
    }

    /// The wrapped `UIint64` if one exists.
    var uint64Value: UInt64? {
        switch self {
        case .uint64(let uint64): return uint64
        default: return nil
        }
    }

    /// The wrapped URL if one exists.
    var urlValue: URL? {
        switch self {
        case .url(let url): return url
        default: return nil
        }
    }
}

// MARK: - ExpressibleBy Protocols
extension AnyCodable: ExpressibleByArrayLiteral {
    /// Creates an instance initialized with the given elements.
    /// - Parameter elements: The elements of the new instance.
    public init(arrayLiteral elements: AnyCodable...) {
        self = .array(elements)
    }
}

extension AnyCodable: ExpressibleByBooleanLiteral {
    /// Creates an instance initialized to the given Boolean value.
    /// - Parameter value: The value of the new instance.
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension AnyCodable: ExpressibleByDictionaryLiteral {
    /// Creates an instance initialized with the given key-value pairs.
    /// - Parameter elements: The key-value pairs of the new instance.
    public init(dictionaryLiteral elements: (String, AnyCodable)...) {
        self = .dictionary(.init(elements, uniquingKeysWith: { first, _ in first }))
    }
}

extension AnyCodable: ExpressibleByFloatLiteral {
    /// Creates an instance initialized to the specified floating-point value.
    /// - Parameter value: The value to create.
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension AnyCodable: ExpressibleByIntegerLiteral {
    /// Creates an instance initialized to the specified integer value.
    /// - Parameter value: The value to create.
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension AnyCodable: ExpressibleByNilLiteral {
    /// Creates an instance initialized with `nil`.
    public init(nilLiteral: ()) {
        self = .none
    }
}

extension AnyCodable: ExpressibleByStringLiteral {
    /// Creates an instance initialized to the given string value.
    /// - Parameter value: The value of the new instance.
    public init(stringLiteral value: String) {
        self = .string(value)
    }

    /// Creates an instance initialized to the given value.
    /// - Parameter value: The value of the new instance.
    public init(unicodeScalarLiteral value: String) {
        self = .string(value)
    }

    /// Creates an instance initialized to the given value.
    /// - Parameter value: The value of the new instance.
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .string(value)
    }
}

extension AnyCodable: ExpressibleByStringInterpolation {}

// MARK: - Dictionary+Utils
public extension Dictionary where Value == AnyCodable {
    /// A dictionary containing the underlying values that were wrapped in ``AnyCodable``.
    var anyValues: [Key: Any] {
        mapValues { $0.anyValue }
    }

    /// Accesses the array associated with the given key for reading and writing.
    subscript(array key: Key) -> [AnyCodable]? {
        get {
            self[key]?.arrayValue
        }
        set {
            switch newValue {
            case .some(let wrapped):
                self[key] = AnyCodable.array(wrapped)
            case .none:
                self[key] = nil
            }
        }
    }

    /// Accesses the Boolean associated with the given key for reading and writing.
    subscript(bool key: Key) -> Bool? {
        get {
            self[key]?.boolValue
        }
        set {
            switch newValue {
            case .some(let wrapped):
                self[key] = AnyCodable.bool(wrapped)
            case .none:
                self[key] = nil
            }
        }
    }

    /// Accesses the date associated with the given key for reading and writing.
    subscript(date key: Key) -> Date? {
        get {
            self[key]?.dateValue
        }
        set {
            switch newValue {
            case .some(let wrapped):
                self[key] = AnyCodable.date(wrapped)
            case .none:
                self[key] = nil
            }
        }
    }

    /// Accesses the dictionary associated with the given key for reading and writing.
    subscript(dictionary key: Key) -> [String: AnyCodable]? {
        get {
            self[key]?.dictionaryValue
        }
        set {
            switch newValue {
            case .some(let wrapped):
                self[key] = AnyCodable.dictionary(wrapped)
            case .none:
                self[key] = nil
            }
        }
    }

    /// Accesses the double associated with the given key for reading and writing.
    subscript(double key: Key) -> Double? {
        get {
            self[key]?.doubleValue
        }
        set {
            switch newValue {
            case .some(let wrapped):
                self[key] = AnyCodable.double(wrapped)
            case .none:
                self[key] = nil
            }
        }
    }

    /// Accesses the integer associated with the given key for reading and writing.
    subscript(int key: Key) -> Int? {
        get {
            self[key]?.intValue
        }
        set {
            switch newValue {
            case .some(let wrapped):
                self[key] = AnyCodable.int(wrapped)
            case .none:
                self[key] = nil
            }
        }
    }

    /// Accesses the 64-bit signed integer associated with the given key for reading and writing.
    subscript(int64 key: Key) -> Int64? {
        get {
            self[key]?.int64Value
        }
        set {
            switch newValue {
            case .some(let wrapped):
                self[key] = AnyCodable.int64(wrapped)
            case .none:
                self[key] = nil
            }
        }
    }

    /// Accesses the string associated with the given key for reading and writing.
    subscript(string key: Key) -> String? {
        get {
            self[key]?.stringValue
        }
        set {
            switch newValue {
            case .some(let wrapped):
                self[key] = AnyCodable.string(wrapped)
            case .none:
                self[key] = nil
            }
        }
    }

    /// Accesses the 64-bit unsigned integer associated with the given key for reading and writing.
    subscript(uint64 key: Key) -> UInt64? {
        get {
            self[key]?.uint64Value
        }
        set {
            switch newValue {
            case .some(let wrapped):
                self[key] = AnyCodable.uint64(wrapped)
            case .none:
                self[key] = nil
            }
        }
    }

    /// Accesses the URL associated with the given key for reading and writing.
    subscript(url key: Key) -> URL? {
        get {
            self[key]?.urlValue
        }
        set {
            switch newValue {
            case .some(let wrapped):
                self[key] = AnyCodable.url(wrapped)
            case .none:
                self[key] = nil
            }
        }
    }
}
