/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

import Foundation


public protocol RegisteredCodableType {
	
	func decode(container: SingleValueDecodingContainer) -> Any?
	func encode(value: Any, container: inout SingleValueEncodingContainer) throws -> Bool
}

public struct RegisteredCodableGenerator<T: Codable>: RegisteredCodableType {
	
	public func decode(container: SingleValueDecodingContainer) -> Any? {
		return try? container.decode(T.self)
	}
	
	public func encode(value: Any, container: inout SingleValueEncodingContainer) throws -> Bool {
		if let value = value as? T {
			try container.encode(value)
			return true
		}
		return false
	}
}

/// RegisteredCodable is a type-erased wrapper around a Codable type.
///
/// Motivation:
/// A changeset contains an unknown set of values.
/// Essentially a dictionary with type [String: Any<T: Codable>].
/// But this isn't supported by Swift's strongly typed system.
/// So our solution is to provide a wrapper that allows any type register for encoding & decoding support.
///
public struct RegisteredCodable: Codable {
	let value: Any
	
	init<T: Codable>(_ value: T) {
		self.value = value
	}
	
	static var registered: [RegisteredCodableType] = RegisteredCodable.defaultRegistered()
	
	static func defaultRegistered() -> [RegisteredCodableType] {
		var list: [RegisteredCodableType] = Array()
		
		list.append(RegisteredCodableGenerator<Bool>())
		list.append(RegisteredCodableGenerator<Int>())
		list.append(RegisteredCodableGenerator<Int8>())
		list.append(RegisteredCodableGenerator<Int16>())
		list.append(RegisteredCodableGenerator<Int32>())
		list.append(RegisteredCodableGenerator<Int64>())
		list.append(RegisteredCodableGenerator<UInt>())
		list.append(RegisteredCodableGenerator<UInt8>())
		list.append(RegisteredCodableGenerator<UInt16>())
		list.append(RegisteredCodableGenerator<UInt32>())
		list.append(RegisteredCodableGenerator<UInt64>())
		list.append(RegisteredCodableGenerator<Float>())
		list.append(RegisteredCodableGenerator<Double>())
		list.append(RegisteredCodableGenerator<String>())
		list.append(RegisteredCodableGenerator<[String: RegisteredCodable]>())
		list.append(RegisteredCodableGenerator<[Int: RegisteredCodable]>())
		list.append(RegisteredCodableGenerator<[RegisteredCodable]>())
	//	list.append(RegisteredCodableGenerator<ZDCNull>())
		
		return list
	}
	
	static func register(_ item: RegisteredCodableType) {
		
		registered.append(item)
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		var decoded: Any? = nil
		for item in RegisteredCodable.registered {
			if let value = item.decode(container: container) {
				decoded = value
				break
			}
		}
		
		if let decoded = decoded {
			self.value = decoded
		}
		else {
			
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "RegisteredCodable value cannot be decoded."
			)
		}
		
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		
		var encoded = false
		for item in RegisteredCodable.registered {
			if try item.encode(value: value, container: &container) {
				encoded = true
				break
			}
		}
		
		if !encoded {
			
			let dynamicType = type(of: value)
			let context = EncodingError.Context(
				codingPath: container.codingPath,
				debugDescription: "RegisteredCodable value cannot be encoded. Type = \(dynamicType)"
			)
			throw EncodingError.invalidValue(value, context)
		}
	}
}

extension RegisteredCodable: CustomStringConvertible {
	
	public var description: String {
		switch value {
		case is Void:
			return String(describing: nil as Any?)
		case let value as CustomStringConvertible:
			return value.description
		default:
			return String(describing: value)
		}
	}
}

extension RegisteredCodable: CustomDebugStringConvertible {
	
	public var debugDescription: String {
		switch value {
		case let value as CustomDebugStringConvertible:
			return "RegisteredCodable(\(value.debugDescription))"
		default:
			return "RegisteredCodable(\(description))"
		}
	}
}
