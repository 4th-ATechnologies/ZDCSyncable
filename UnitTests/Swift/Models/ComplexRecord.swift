/**
 * ZDCSyncable
 * <GitHub URL goes here>
**/

import Foundation
import ZDCSyncable

/**
 * Sample class - used for unit testing.
 *
 * Goal: Test a subclass of ZDCRecord with a bit more complexity.
 *       Here we have a record that also contains an ZDCDictionary & ZDCSet.
 *       So changes to these objects should also be included in `changeset`, etc.
 */
class ComplexRecord: SimpleRecord {
	
	dynamic let dict: ZDCDictionary<String, String> = ZDCDictionary()
	
	override open func copy(with zone: NSZone? = nil) -> Any {
		
		let copy = super.copy(with: zone) as! ComplexRecord
		
		for (key, value) in self.dict {
			copy.dict[key] = value
		}
		
		return copy
	}
	
	override public func isEqual(_ object: Any?) -> Bool {
		
		if let another = object as? ComplexRecord {
			return isEqualToComplexRecord(another)
		}
		else {
			return false
		}
	}
	
	public func isEqualToComplexRecord(_ another: ComplexRecord) -> Bool {
		
		if !self.isEqualToSimpleRecord(another) { return false }
		if self.dict != another.dict { return false }
		
		return true
	}
	
	// MARK: ZDCObject
	
	override public func makeImmutable() {
		
		super.makeImmutable()
		dict.makeImmutable()
	}
	
	override public var hasChanges: Bool {
		get {
			if super.hasChanges {
				return true
			}
			
			return dict.hasChanges
		}
	}
	
	override public func clearChangeTracking() {
		
		super.clearChangeTracking()
		dict.clearChangeTracking()
	}
}