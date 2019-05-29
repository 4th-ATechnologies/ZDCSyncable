/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

import Foundation
import ZDCSyncable

/**
 * Sample class - used for unit testing.
 *
 * Goal: test a simple subclass of ZDCRecord.
 */
class SimpleRecord: ZDCRecord {

	@objc dynamic var someString: String?
	@objc dynamic var someInteger: Int = 0

	override open func copy(with zone: NSZone? = nil) -> Any {
		
		let copy = super.copy(with: zone) as! SimpleRecord
		
		copy.someString = self.someString
		copy.someInteger = self.someInteger
		
		return copy;
	}
	
	override public func isEqual(_ object: Any?) -> Bool {
		
		if let another = object as? SimpleRecord {
			return isEqualToSimpleRecord(another)
		}
		else {
			return false
		}
	}
	
	public func isEqualToSimpleRecord(_ another: SimpleRecord) -> Bool {
	
		if (self.someString != another.someString) { return false }
		if (self.someInteger != another.someInteger) { return false }
		
		return true
	}
}
