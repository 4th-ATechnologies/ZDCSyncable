/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

import Foundation

/**
 * ZDCNull is used internally to represent nil/null.
 * Do NOT use it directly. If you want to store null, then you should use NSNull.
 *
 * Why:
 *   We needed our own special version because we needed a way to differentiate from NSNull.
 *
 * Where it's used:
 *   In changeset dictionaries, ZDCNull is used as a placeholder to represent the absence of value.
 *   For example, if the originalValue of an object is ZDCNull, this would mean the object was added.
 *
 * ZDCNull is a singleton.
 */
internal class ZDCNull: NSObject, NSCoding, NSCopying {
	
	static let _sharedInstance = ZDCNull()
	
	public class func sharedInstance() -> ZDCNull {
		return _sharedInstance
	}
	
	private override init() {}
	
	required init?(coder decoder: NSCoder) {
		// Do nothing.
		// We're going to substitute the sharedInstance via awakeAfter(usingDecoder)
	}
	
	override func awakeAfter(using decoder: NSCoder) -> Any? {
		return type(of: self).sharedInstance()
	}
	
	func encode(with coder: NSCoder) {
		// Nothing internal to encode.
		// NSCoder will record the class (S4Null) automatically.
	}
	
	func copy(with zone: NSZone? = nil) -> Any {
		return type(of: self).sharedInstance()
	}
	
	override var description: String {
		return "<ZDCNull>"
	}
	
	override var debugDescription: String {
		return "<ZDCNull>"
	}
}
