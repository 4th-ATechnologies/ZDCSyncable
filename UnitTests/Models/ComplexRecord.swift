/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

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
	
	var dict = ZDCDictionary<String, String>()
	
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
	
	/// You must implement this function IFF you have ZDCSyncable properties such as:
	/// - ZDCDictionary
	/// - ZDCOrderedDictionary
	/// - ZDCSet
	/// - ZDCOrderedSet
	/// - ZDCArray
	///
	override func setSyncableValue(_ value: Any?, for key: String) -> Bool {
		
		var result = false
		switch key {
		case "dict":
			
			if let value = value as? ZDCDictionary<String, String> {
				dict = value
				result = true
			}
			
		default: break
		}
		
		return result ? true : super.setSyncableValue(value, for: key)
	}
}
