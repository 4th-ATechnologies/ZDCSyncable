//
//  AnyCodable.swift
//
//  Created by Andrew on 11/16/17.
//  Copyright © 2017 Readdle. All rights reserved.
//

import Foundation

public struct AnyCodable: Codable {
	
	private typealias AnyEncodableClosure = (Any, inout KeyedEncodingContainer<CodingKeys>) throws -> Void
	private typealias AnyDecodableClosure = (KeyedDecodingContainer<CodingKeys>) throws -> Any
	
	private struct CodableClosure {
		
		let typeName: String
		let encoder: AnyEncodableClosure
		let decoder: AnyDecodableClosure
	}
    
	private static let ArrayTypeName = "Array"
	private static let SetTypeName = "Set"
	private static let DictionaryTypeName = "Dictionary"
	
	private static var codableQueue = DispatchQueue(label: "AnyCodable")
	private static var codableClosures: [String: CodableClosure] = StandardClosurePairs()
	
	private static func CodableClosureGenerator<T: Codable>(_ type: T.Type, typeName: String? = nil) -> CodableClosure {
		
		let name = typeName ?? String(describing: type)
		let encoder: AnyEncodableClosure = {(value, container) in
			let castedType: T = value as! T
			try container.encode(castedType, forKey: .value)
		}
		let decoder: AnyDecodableClosure = {(container) in
			try container.decode(T.self, forKey: .value)
		}
		
		return CodableClosure(typeName: name, encoder: encoder, decoder: decoder)
	}
	
	private static func StandardClosurePairs() -> [String: CodableClosure] {
		
		var standards: [CodableClosure] = [
			CodableClosureGenerator(Int.self),
			CodableClosureGenerator(String.self),
			CodableClosureGenerator(Int.self),
			CodableClosureGenerator(Int8.self),
			CodableClosureGenerator(Int16.self),
			CodableClosureGenerator(Int32.self),
			CodableClosureGenerator(Int64.self),
			CodableClosureGenerator(UInt.self),
			CodableClosureGenerator(UInt8.self),
			CodableClosureGenerator(UInt16.self),
			CodableClosureGenerator(UInt32.self),
			CodableClosureGenerator(UInt64.self),
			CodableClosureGenerator(Float.self),
			CodableClosureGenerator(Double.self),
			CodableClosureGenerator(Bool.self),
			CodableClosureGenerator(Data.self),
			CodableClosureGenerator(Date.self),
			CodableClosureGenerator(URL.self),
		]
		
		// Array
		do {
			let encoder: AnyEncodableClosure = {(value, container) in
				var unkeyedContainer = container.nestedUnkeyedContainer(forKey: .value)
				try AnyCodable.encodeAnyArray(value as! [Any], to: &unkeyedContainer)
			}
			let decoder: AnyDecodableClosure = {(container) in
				var unkeyedContainer = try container.nestedUnkeyedContainer(forKey: .value)
				return try AnyCodable.decodeAnyArray(from: &unkeyedContainer)
			}
		
			standards.append(CodableClosure(typeName: ArrayTypeName, encoder: encoder, decoder: decoder))
		}
		
		// Set
		do {
			let encoder: AnyEncodableClosure = {(value, container) in
				var unkeyedContainer = container.nestedUnkeyedContainer(forKey: .value)
				try AnyCodable.encodeAnySet(value as! Set<AnyHashable>, to: &unkeyedContainer)
		 	}
			let decoder: AnyDecodableClosure = {(container) in
				var unkeyedContainer = try container.nestedUnkeyedContainer(forKey: .value)
				return try AnyCodable.decodeAnySet(from: &unkeyedContainer)
		 	}
			
			standards.append(CodableClosure(typeName: SetTypeName, encoder: encoder, decoder: decoder))
		}
		
		// Dictionary
		do {
			let encoder: AnyEncodableClosure = {(value, container) in
				var unkeyedContainer = container.nestedUnkeyedContainer(forKey: .value)
				try AnyCodable.encodeAnyDictionary(value as! [AnyHashable: Any], to: &unkeyedContainer)
		 	}
			let decoder: AnyDecodableClosure = {(container) in
				var unkeyedContainer = try container.nestedUnkeyedContainer(forKey: .value)
				return try AnyCodable.decodeAnyDictionary(from: &unkeyedContainer)
		 	}
			
			standards.append(CodableClosure(typeName: DictionaryTypeName, encoder: encoder, decoder: decoder))
		}
		
		// ZDCNull
		standards.append(CodableClosureGenerator(ZDCNull.self))
		
		var result: [String: CodableClosure] = [:]
		for standard in standards {
			result[standard.typeName] = standard
		}
		 
		return result
	}
	
	@discardableResult
	public static func RegisterType<T: Codable>(_ type: T.Type, typeName: String? = nil) -> Bool {
		
		let wrapper = CodableClosureGenerator(type, typeName: typeName)
		
		var result = false
		codableQueue.sync {
			
			if self.codableClosures[wrapper.typeName] == nil {
				self.codableClosures[wrapper.typeName] = wrapper
				result = true
			} else {
				// typeName already registered
				result = false
			}
		}
		
		return result
	}
    
	private enum CodingKeys: String, CodingKey {
		case typeName = "T"
		case value = "v"
	}
	
	public let typeName: String
	public let value: Any
	
	public init(_ value: Codable) {
		
		self.value = value
		
		switch value {
		case is Array<Any>:
			self.typeName = AnyCodable.ArrayTypeName
			
		case is Dictionary<AnyHashable, Any>:
			self.typeName = AnyCodable.DictionaryTypeName
			
		case is Set<AnyHashable>:
			self.typeName = AnyCodable.SetTypeName
			
		default:
			let typeName = String(describing: type(of: value))
			self.typeName = typeName
		}
	}
    
	public init(_ value: Array<Any>) {
		
		self.value = value
		self.typeName = AnyCodable.ArrayTypeName
	}
    
	public init(_ value: Dictionary<AnyHashable, Any>) {
		
		self.value = value
		self.typeName = AnyCodable.DictionaryTypeName
	}
	
	public init(_ value: Set<AnyHashable>) {
		
		self.value = value
		self.typeName = AnyCodable.SetTypeName
	}
    
	public init(from decoder: Decoder) throws {
		
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let typeName = try container.decode(String.self, forKey: .typeName)
		
		guard let closure = AnyCodable.codableClosures[typeName] else {
			
			let context = DecodingError.Context(
				codingPath: decoder.codingPath,
				debugDescription: "Type not registered with AnyCodable: \(typeName)"
			)
			throw DecodingError.dataCorrupted(context)
		}
		
		self.typeName = typeName
		self.value = try closure.decoder(container)
	}
	
	public func encode(to encoder: Encoder) throws {
		
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(typeName, forKey: .typeName)
		
		guard let closure = AnyCodable.codableClosures[typeName] else {
			
			let context = EncodingError.Context(
				codingPath: encoder.codingPath,
				debugDescription: "Type not registered with AnyCodable: \(typeName)"
			)
			throw EncodingError.invalidValue(value, context)
		}
		
		try closure.encoder(value, &container)
	}
    
	private static func encodeAnyArray(_ array: [Any], to container: inout UnkeyedEncodingContainer) throws {
		
		for value in array {
			if let codableValue = value as? Set<AnyHashable> {
				try container.encode(AnyCodable(codableValue))
			}
			else if let codableValue = value as? Array<Any> {
				try container.encode(AnyCodable(codableValue))
			}
			else if let codableValue = value as? Dictionary<AnyHashable, Any> {
				try container.encode(AnyCodable(codableValue))
			}
			else if let codableValue = value as? Codable {
				try container.encode(AnyCodable(codableValue))
			}
			else {
				
				let context = EncodingError.Context(
					codingPath: container.codingPath,
					debugDescription: "Non-codable type encountered in Array: \(type(of: value))"
				)
				throw EncodingError.invalidValue(value, context)
			}
		}
	}
	
	private static func decodeAnyArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
		
		var array = [Any]()
		while !container.isAtEnd {
			let value = try container.decode(AnyCodable.self).value
			array.append(value)
		}
		return array
	}
    
	private static func encodeAnySet(_ set: Set<AnyHashable>, to container: inout UnkeyedEncodingContainer) throws {
		
		for value in set {
			if let codableValue = value as? Set<AnyHashable> {
				try container.encode(AnyCodable(codableValue))
			}
			else if let codableValue = value as? Array<Any> {
				try container.encode(AnyCodable(codableValue))
			}
			else if let codableValue = value as? Dictionary<AnyHashable, Any> {
				try container.encode(AnyCodable(codableValue))
			}
			else if let codableValue = value as? Codable {
				try container.encode(AnyCodable(codableValue))
			}
			else {
				
				let context = EncodingError.Context(
					codingPath: container.codingPath,
					debugDescription: "Non-codable type encountered in Set: \(type(of: value))"
				)
				throw EncodingError.invalidValue(value, context)
			}
		}
	}
	
	private static func decodeAnySet(from container: inout UnkeyedDecodingContainer) throws -> Set<AnyHashable> {
		
		var set = Set<AnyHashable>()
		while !container.isAtEnd {
			
			let value = try container.decode(AnyCodable.self).value
			if let anyHashableValue = value as? AnyHashable {
				set.insert(anyHashableValue)
			}
			else {
				
				throw DecodingError.dataCorruptedError(
					in: container,
					debugDescription: "Non-hashable type encountered in Set: \(type(of: value))"
				)
			}
		}
		return set
	}
	
	private static func encodeAnyDictionary(_ dict: [AnyHashable: Any], to container: inout UnkeyedEncodingContainer) throws {
		
		for (key, value) in dict {
			
			guard let codableKey = key.base as? Codable else {
				
				let context = EncodingError.Context(
					codingPath: container.codingPath,
					debugDescription: "Non-codable key encountered in Dictionary: \(type(of: key.base))"
				)
				throw EncodingError.invalidValue(key.base, context)
			}
			
			try container.encode(AnyCodable(codableKey))
			
			if let codableValue = value as? Set<AnyHashable> {
				try container.encode(AnyCodable(codableValue))
			}
			else if let codableValue = value as? Array<Any> {
				try container.encode(AnyCodable(codableValue))
			}
			else if let codableValue = value as? Dictionary<AnyHashable, Any> {
				try container.encode(AnyCodable(codableValue))
			}
			else if let codableValue = value as? Codable {
				try container.encode(AnyCodable(codableValue))
			}
			else {
				
				let context = EncodingError.Context(
					codingPath: container.codingPath,
					debugDescription: "Non-codable value encountered in Dictionary: \(type(of: value))"
				)
				throw EncodingError.invalidValue(value, context)
			}
		}
	}
    
    private static func decodeAnyDictionary(from container: inout UnkeyedDecodingContainer) throws -> [AnyHashable: Any] {
		
		// We're expecting to get pairs.
		// If the container has a known count, it must be even.
		//
		if let count = container.count {
			guard count % 2 == 0 else {
				
				let msg =
				  "While decoding Dictionary: Expected array of key-value pairs; Encountered odd-length array instead."
				
				throw DecodingError.dataCorruptedError(
					in: container,
					debugDescription: msg
				)
			}
		}
		
		var dict = [AnyHashable: Any]()
		while !container.isAtEnd {
		
			let wrappedKey = try container.decode(AnyCodable.self)
			guard let key = wrappedKey.value as? AnyHashable else {
				
				throw DecodingError.dataCorruptedError(
					in: container,
					debugDescription: "Non-hashable key encountered in Dictionary: \(type(of: wrappedKey))")
			}
			
			guard !container.isAtEnd else {
				
				throw DecodingError.dataCorruptedError(
					in: container,
					debugDescription: "While decoding Dictionary: Unkeyed container has odd-length array."
				)
			}
			
			let value = try container.decode(AnyCodable.self).value
			
			dict[key] = value
		}
		
		return dict
	}
}
