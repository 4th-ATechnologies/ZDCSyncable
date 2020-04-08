/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
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
	
	let dict: ZDCDictionary<String, String> = ZDCDictionary()
	
	override init() {
		super.init()
	}
	
	init(copy source: ComplexRecord) {
		
		for (key, value) in source.dict {
			self.dict[key] = value
		}
		
		super.init(copy: source)
	}
	
	static func == (lhs: ComplexRecord, rhs: ComplexRecord) -> Bool {
		
		guard (lhs as SimpleRecord) == (rhs as SimpleRecord) else {
			return false
		}
		
		return lhs.dict == rhs.dict
	}
	
	// MARK: ZDCRecord
	
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
