/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & objects in pure Swift.

import Foundation
import ZDCSyncable

/**
 * Sample class - used for unit testing.
 *
 * Goal: test a simple subclass of ZDCRecord.
 */
class SimpleRecord: ZDCRecord, Equatable {

	@Syncable var someString: String?
	@Syncable var someInteger: Int
	
	override init() {
		someString = nil
		someInteger = 0
		
		super.init()
	}
	
	init(copy source: SimpleRecord) {
		self.someString = source.someString
		self.someInteger = source.someInteger
		
		super.init()
	}
	
	static func == (lhs: SimpleRecord, rhs: SimpleRecord) -> Bool {
		
		return
			lhs.someString == rhs.someString &&
			lhs.someInteger == rhs.someInteger
	}
}
