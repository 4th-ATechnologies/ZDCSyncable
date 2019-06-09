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

	required init() {
		super.init()
	}
	
	required init(copy source: ZDCObject) {
		
		if let source = source as? SimpleRecord {
			
			self.someString = source.someString
			self.someInteger = source.someInteger
			super.init(copy: source)
			
		} else {
			
			fatalError("init(copy:) invoked with invalid source")
		}
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
