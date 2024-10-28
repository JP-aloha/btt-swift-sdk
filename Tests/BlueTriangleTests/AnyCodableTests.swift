//
//  AnyCodableTests.swift
//
//  Created by Mathew Gacy on 1/26/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import XCTest

final class AnyCodableTests: XCTestCase {
    let key = "key"
    let array: [String] = ["a", "b", "c"]
    let bool: Bool = true
    let date = Date(timeIntervalSince1970: 1670000000)
    let double: Double = 9.99
    let float: Float = 11.11
    let int: Int = 9
    let int64: Int64 = .max
    let string: String = "String"
    let uint64: UInt64 = .max
    let url: URL = "https://example.com/foo"

    var dictionary: [String: Any] {
        [
            "string": string,
            "bool": bool,
            "double": double,
            "int": int,
            "array": array,
            "nested": [
                "foo": "bar"
            ]
        ]
    }

    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    func encodeAndDecode<T: Codable>(_ value: Any) throws -> T? {
        let anyCodable = try AnyCodable(value)
        let encoded = try encoder.encode(anyCodable)
        let decoded = try decoder.decode(AnyCodable.self, from: encoded)
        return decoded.anyValue as? T
    }
}

// MARK: - Type -> Encoded -> Decoded -> Any -> Type
extension AnyCodableTests {
    func testArrayOfDoublesCoding() throws {
        let expectedValue: [Double] = [1.1, 2.22, 3.333]
        let actualValue: [Double]? = try encodeAndDecode(expectedValue)
        XCTAssertEqual(actualValue, expectedValue)
    }

    func testArrayOfStringsCoding() throws {
        let expectedValue = ["a", "b", "c"]
        let actualValue: [String]? = try encodeAndDecode(expectedValue)
        XCTAssertEqual(actualValue, expectedValue)
    }

    func testBoolCoding() throws {
        let expectedValue = true
        let actualValue: Bool? = try encodeAndDecode(expectedValue)
        XCTAssertEqual(actualValue, expectedValue)
    }

    func testDateCoding() throws {
        let expectedValue = Date(timeIntervalSince1970: 1670000000)
        let actualValue: Date? = try encodeAndDecode(expectedValue)
        XCTAssertEqual(actualValue, expectedValue)
    }

    func testDictionaryCoding() throws {
        let expectedValue = ["foo": "bar"]
        let actualValue: [String: String]? = try encodeAndDecode(expectedValue)
        XCTAssertEqual(actualValue, expectedValue)
    }

    func testDictionaryOfAnyCoding() throws {
        let initialValue: [String: Any] = [
            "string": string,
            "bool": bool,
            "int": int,
            "double": double,
            "array": array,
            "dictionary": [
                "foo": 11
            ]
        ]

        let anyCodable = try AnyCodable(initialValue)

        let encoded = try encoder.encode(anyCodable)
        let decoded = try decoder.decode(AnyCodable.self, from: encoded)
        let anyDictionary = decoded.anyValue as! [String: Any]

        XCTAssertEqual(anyDictionary["string"] as! String , string)
        XCTAssertEqual(anyDictionary["int"] as! Int , int)
        XCTAssertEqual(anyDictionary["double"] as! Double , double)
        XCTAssertEqual(anyDictionary["bool"] as! Bool , bool)
        XCTAssertEqual(anyDictionary["array"] as! [String] , array)

        let nestedDictionary = anyDictionary["dictionary"] as! [String: Any]
        XCTAssertEqual(nestedDictionary["foo"] as! Int, 11)
    }

    func testDoubleCoding() throws {
        let expectedValue: Double = 9.99
        let actualValue: Double? = try encodeAndDecode(expectedValue)
        XCTAssertEqual(actualValue, expectedValue)
    }

    func testIntCoding() throws {
        let expectedValue: Int = 9
        let actualValue: Int? = try encodeAndDecode(expectedValue)
        XCTAssertEqual(actualValue, expectedValue)
    }

    func testInt64Coding() throws {
        let expectedValue: Int64 = Int64.max
        let actualValue: Int? = try encodeAndDecode(expectedValue)
        XCTAssertEqual(actualValue, Int(expectedValue))
    }

    func testNilCoding() throws {
        let expectedValue: String? = nil
        let actualValue: String? = try encodeAndDecode(expectedValue as Any)
        XCTAssertEqual(actualValue, expectedValue)
    }

    func testStringCoding() throws {
        let expectedValue = "Example string"
        let actualValue: String? = try encodeAndDecode(expectedValue)
        XCTAssertEqual(actualValue, expectedValue)
    }

    func testUInt64Coding() throws {
        let expectedLargeValue: UInt64 = UInt64.max
        let actualLargeValue: UInt64? = try encodeAndDecode(expectedLargeValue)
        XCTAssertEqual(actualLargeValue, expectedLargeValue)

        // Values within the range of possibile values of `Int64` will be decoded as such
        let smallValue: UInt64 = 5
        let actualSmallValue: UInt64? = try encodeAndDecode(smallValue)
        XCTAssertNil(actualSmallValue)
    }

    func testURLCoding() throws {
        let urlString = "https://example.com"
        let expectedValue = URL(string: urlString)!
        let actualValue: String? = try encodeAndDecode(expectedValue)
        XCTAssertEqual(actualValue, urlString)
    }
}

// MARK: - Bridged Types
extension AnyCodableTests {
    func testArrayBridging() throws {
        let nsArray = NSArray(array: ["a", "b", "c"])
        let anyCodable = try AnyCodable(nsArray)
        XCTAssertEqual(anyCodable, .array(["a", "b", "c"]))
        XCTAssertEqual(anyCodable.anyValue as? NSArray, nsArray)
    }

    func testDateBridging() throws {
        let nsDate = NSDate(timeIntervalSince1970: 1670000000)
        let anyCodable = try AnyCodable(nsDate)
        XCTAssertEqual(anyCodable, .date(date))
        XCTAssertEqual(anyCodable.anyValue as? NSDate, nsDate)
    }

    func testDictionaryBridging() throws {
        let nsDictionary: NSDictionary = [
            "foo": "bar",
            "array": [2.0, 3.0, 4.0]
        ]
        let anyCodable = try AnyCodable(nsDictionary)
        XCTAssertEqual(anyCodable, ["foo": .string("bar"), "array": [.double(2.0), .double(3.0), .double(4.0)]])
        XCTAssertEqual(anyCodable.anyValue as? NSDictionary, nsDictionary)
    }

    func testNumberBridging() throws {
        let nsBool = NSNumber(value: bool)
        let wrappedBool = try AnyCodable(nsBool)
        XCTAssertEqual(wrappedBool, .bool(bool))
        XCTAssertEqual(wrappedBool.anyValue as? NSNumber, nsBool)

        let nsDouble = NSNumber(value: double)
        let wrappedDouble = try AnyCodable(nsDouble)
        XCTAssertEqual(wrappedDouble, .double(double))
        XCTAssertEqual(wrappedDouble.anyValue as? NSNumber, nsDouble)

        let nsFloat = NSNumber(value: float)
        let wrappedFloat = try AnyCodable(nsFloat)
        XCTAssertEqual(wrappedFloat, .double(Double(float)))
        XCTAssertEqual(wrappedFloat.anyValue as? NSNumber, nsFloat)

        let nsInt = NSNumber(value: int)
        let wrappedInt = try AnyCodable(nsInt)
        XCTAssertEqual(wrappedInt, .int(int))
        XCTAssertEqual(wrappedInt.anyValue as? NSNumber, nsInt)
    }

    func testStringBridging() throws {
        let nsString = NSString(string: string)
        let anyCodable = try AnyCodable(nsString)
        XCTAssertEqual(anyCodable, .string(string))
        XCTAssertEqual(anyCodable.anyValue as? NSString, nsString)
    }
}

// MARK: - Associated Value Access
extension AnyCodableTests {
    func testArrayValue() throws {
        let expectedValue: [AnyCodable] = ["a", "b", "c"]
        let sut = try AnyCodable(array)
        let actualValue = sut.arrayValue
        XCTAssertEqual(actualValue, expectedValue)
    }

    func testBoolValue() throws {
        let sut = try AnyCodable(bool)
        let actualValue = sut.boolValue
        XCTAssertEqual(actualValue, bool)
    }

    func testDateValue() throws {
        let sut = try AnyCodable(date)
        let actualValue = sut.dateValue
        XCTAssertEqual(actualValue, date)
    }

    func testDictionaryValue() throws {
        let sut = try AnyCodable(dictionary)
        let actualValue = sut.dictionaryValue!

        XCTAssertEqual(actualValue["string"], .string(string))
        XCTAssertEqual(actualValue["bool"], .bool(bool))
        XCTAssertEqual(actualValue["double"], .double(double))
        XCTAssertEqual(actualValue["int"], .int(int))
        XCTAssertEqual(actualValue["array"], .array(["a", "b", "c"]))
        XCTAssertEqual(actualValue["nested"], .dictionary(["foo": "bar"]))
    }

    func testDoubleValue() throws {
        let sut = try AnyCodable(double)
        let actualValue = sut.doubleValue
        XCTAssertEqual(actualValue, double)
    }

    func testIntValue() throws {
        let sut = try AnyCodable(int)
        let actualValue = sut.intValue
        XCTAssertEqual(actualValue, int)
    }

    func testInt64Value() throws {
        let sut = try AnyCodable(int64)
        let actualValue = sut.int64Value
        XCTAssertEqual(actualValue, int64)
    }

    func testStringValue() throws {
        let sut = try AnyCodable(string)
        let actualValue = sut.stringValue
        XCTAssertEqual(actualValue, string)
    }

    func testUInt64Value() throws {
        let sut = try AnyCodable(uint64)
        let actualValue = sut.uint64Value
        XCTAssertEqual(actualValue, uint64)
    }

    func testURLValue() throws {
        let sut = try AnyCodable(url)
        let actualValue = sut.urlValue
        XCTAssertEqual(actualValue, url)
    }
}

// MARK: - ExpressibleBy
extension AnyCodableTests {
    func testArrayExpressibility() {
        let sut: AnyCodable = ["a", "b", "c"]
        XCTAssertEqual(sut, .array([.string("a"), .string("b"), .string("c")]))
    }

    func testBooleanExpressibility() {
        let sut: AnyCodable = true
        XCTAssertEqual(sut, .bool(true))
    }

    func testDictionaryExpressibility() {
        let sut: AnyCodable = ["foo": "bar"]
        XCTAssertEqual(sut, .dictionary(["foo": .string("bar")]))
    }

    func testFloatExpressibility() {
        let sut: AnyCodable = 9.99
        XCTAssertEqual(sut, .double(9.99))
    }

    func testIntegerExpressibility() {
        let sut: AnyCodable = 9
        XCTAssertEqual(sut, .int(9))
    }

    func testNilExpressibility() {
        let sut: AnyCodable = nil
        XCTAssertEqual(sut, .none)
    }

    func testStringExpressibility() {
        let sut: AnyCodable = "String"
        XCTAssertEqual(sut, .string("String"))
    }

    func testStringInterpolationExpressibility() {
        let value = 4
        let sut: AnyCodable = "The value is \(value)"
        XCTAssertEqual(sut, .string("The value is 4"))
    }
}

// MARK: - Subscripts
extension AnyCodableTests {
    func testGetArraySubscript() {
        let expectedValue: [AnyCodable] = [.string("a"), .string("b"), .string("c")]

        let sut: [String: AnyCodable] = [
            key: .array(expectedValue),
            "other": "another value"
        ]

        XCTAssertEqual(sut[array: key], expectedValue)
    }

    func testSetArraySubscript() {
        let expectedValue: [AnyCodable] = [.string("a"), .string("b"), .string("c")]

        var sut: [String: AnyCodable] = [:]

        sut[array: key] = expectedValue
        XCTAssertEqual(sut, [key: .array(expectedValue)])

        sut[array: key] = nil
        XCTAssertEqual(sut, [:])
    }

    func testGetBoolSubscript() {
        let expectedValue = bool

        let sut: [String: AnyCodable] = [
            key: .bool(expectedValue),
            "other": "another value"
        ]

        XCTAssertEqual(sut[bool: key], expectedValue)
    }

    func testSetBoolSubscript() {
        let expectedValue = bool

        var sut: [String: AnyCodable] = [:]

        sut[bool: key] = expectedValue
        XCTAssertEqual(sut, [key: .bool(expectedValue)])

        sut[bool: key] = nil
        XCTAssertEqual(sut, [:])
    }

    func testGetDateSubscript() {
        let expectedValue = date

        let sut: [String: AnyCodable] = [
            key: .date(expectedValue),
            "other": "another value"
        ]

        XCTAssertEqual(sut[date: key], expectedValue)
    }

    func testSetDateSubscript() {
        let expectedValue = date

        var sut: [String: AnyCodable] = [:]

        sut[date: key] = expectedValue
        XCTAssertEqual(sut, [key: .date(expectedValue)])

        sut[date: key] = nil
        XCTAssertEqual(sut, [:])
    }

    func testGetDictionarySubscript() {
        let expectedValue: [AnyCodable] = [.string("a"), .string("b"), .string("c")]

        let sut: [String: AnyCodable] = [
            key: .array(expectedValue),
            "other": "another value"
        ]

        XCTAssertEqual(sut[array: key], expectedValue)
    }

    func testSetDictionarySubscript() {
        let expectedValue: [String: AnyCodable] = ["a": .string("a"), "b": .string("b"), "c": .string("c")]

        var sut: [String: AnyCodable] = [:]

        sut[dictionary: key] = expectedValue
        XCTAssertEqual(sut, [key: .dictionary(expectedValue)])

        sut[dictionary: key] = nil
        XCTAssertEqual(sut, [:])
    }

    func testGetDoubleSubscript() {
        let expectedValue = double

        let sut: [String: AnyCodable] = [
            key: .double(expectedValue),
            "other": "another value"
        ]

        XCTAssertEqual(sut[double: key], expectedValue)
    }

    func testSetDoubleSubscript() {
        let expectedValue = double

        var sut: [String: AnyCodable] = [:]

        sut[double: key] = expectedValue
        XCTAssertEqual(sut, [key: .double(expectedValue)])

        sut[double: key] = nil
        XCTAssertEqual(sut, [:])
    }

    func testGetIntSubscript() {
        let expectedValue = int

        let sut: [String: AnyCodable] = [
            key: .int(expectedValue),
            "other": "another value"
        ]

        XCTAssertEqual(sut[int: key], expectedValue)
    }

    func testSetIntSubscript() {
        let expectedValue = int

        var sut: [String: AnyCodable] = [:]

        sut[int: key] = expectedValue
        XCTAssertEqual(sut, [key: .int(expectedValue)])

        sut[int: key] = nil
        XCTAssertEqual(sut, [:])
    }

    func testGetInt64Subscript() {
        let expectedValue = int64

        let sut: [String: AnyCodable] = [
            key: .int64(expectedValue),
            "other": "another value"
        ]

        XCTAssertEqual(sut[int64: key], expectedValue)
    }

    func testSetInt64Subscript() {
        let expectedValue = int64

        var sut: [String: AnyCodable] = [:]

        sut[int64: key] = expectedValue
        XCTAssertEqual(sut, [key: .int64(expectedValue)])

        sut[int64: key] = nil
        XCTAssertEqual(sut, [:])
    }

    func testGetStringSubscript() {
        let expectedValue = string

        let sut: [String: AnyCodable] = [
            key: .string(expectedValue),
            "other": "another value"
        ]

        XCTAssertEqual(sut[string: key], expectedValue)
    }

    func testSetStringSubscript() {
        let expectedValue = string

        var sut: [String: AnyCodable] = [:]

        sut[string: key] = expectedValue
        XCTAssertEqual(sut, [key: .string(expectedValue)])

        sut[string: key] = nil
        XCTAssertEqual(sut, [:])
    }

    func testGetUInt64Subscript() {
        let expectedValue = uint64

        let sut: [String: AnyCodable] = [
            key: .uint64(expectedValue),
            "other": "another value"
        ]

        XCTAssertEqual(sut[uint64: key], expectedValue)
    }

    func testSetUInt64Subscript() {
        let expectedValue = uint64

        var sut: [String: AnyCodable] = [:]

        sut[uint64: key] = expectedValue
        XCTAssertEqual(sut, [key: .uint64(expectedValue)])

        sut[uint64: key] = nil
        XCTAssertEqual(sut, [:])
    }

    func testGetURLSubscript() {
        let expectedValue = url

        let sut: [String: AnyCodable] = [
            key: .url(expectedValue),
            "other": "another value"
        ]

        XCTAssertEqual(sut[url: key], expectedValue)
    }

    func testSetURLSubscript() {
        let expectedValue = url

        var sut: [String: AnyCodable] = [:]

        sut[url: key] = expectedValue
        XCTAssertEqual(sut, [key: .url(expectedValue)])

        sut[url: key] = nil
        XCTAssertEqual(sut, [:])
    }
}

extension AnyCodableTests {
    func testInitialzeWithAnyCodable() throws {
        let inner = try AnyCodable(string)
        let outer = try AnyCodable(inner)
        XCTAssertEqual(outer, inner)
    }

    func testAnyInt64Value() throws {
        let sut = try AnyCodable(int64)
        let actual = sut.anyValue as? Int64
        XCTAssertEqual(actual, int64)
    }

    func testAnyURLValue() throws {
        let sut = try AnyCodable(url)
        let actual = sut.anyValue as? URL
        XCTAssertEqual(actual, url)
    }

    func testAnyValueOfAnyCodableDictionary() throws {
        let sut: [String: AnyCodable] = [
            "string": "String",
            "bool": true,
            "double": 9.99,
            "int": 9,
            "array": ["a", "b", "c"],
            "nested": [
                "foo": "bar"
            ]
        ]

        let actualValue = sut.anyValues

        XCTAssertEqual(actualValue["string"] as? String, string)
        XCTAssertEqual(actualValue["bool"] as? Bool, bool)
        XCTAssertEqual(actualValue["double"] as? Double, double)
        XCTAssertEqual(actualValue["int"] as? Int, int)
        XCTAssertEqual(actualValue["array"] as? [String], ["a", "b", "c"])
        XCTAssertEqual(actualValue["nested"] as? [String: String], ["foo": "bar"])
    }
}
