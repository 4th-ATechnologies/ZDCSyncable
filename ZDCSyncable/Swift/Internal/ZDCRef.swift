/**
 * Syncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

import Foundation

/**
 * ZDCRef is used within changesets.
 *
 * Where it's used:
 *   In changeset dictionaries, ZDCRef is used as a placeholder to indicate the referenced
 *   object conforms to the ZDCSyncable protocol, and has its own changeset.
 *
 * ZDCRef is a singleton.
 */
internal class ZDCRef: NSObject, NSCoding, NSCopying {
	
	static let _sharedInstance = ZDCRef()
	
	public class func sharedInstance() -> ZDCRef {
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
		return "<ZDCRef>"
	}
	
	override var debugDescription: String {
		return "<ZDCRef>"
	}
}
