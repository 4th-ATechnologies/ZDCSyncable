/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

import Foundation
import ZDCSyncable

struct SimpleStruct: ZDCSyncable, Equatable {
	
	@Syncable var someString: String
	@Syncable var someInteger: Int
	
	static func == (lhs: SimpleStruct, rhs: SimpleStruct) -> Bool {
		
		return
			(lhs.someString == rhs.someString) &&
			(lhs.someInteger == rhs.someInteger)
	}
}
