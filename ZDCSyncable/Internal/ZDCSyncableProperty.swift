/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.
/// 

import Foundation

internal protocol ZDCSyncableProperty {
	
	/// Returns whether or not the property has been changed.
	///
	var hasChanges: Bool { get }
	
	/// Clears the internal flags that signal changes to the wrapped value.
	///
	func clearChangeTracking()
	
	/// A type-erased version of Syncable<T>.wrappedValue.
	///
	func getCurrentValue() -> Any?
	
	/// A type-erased version of Syncable<T>.originalValue, wrapped in RegisteredCodable.
	/// 
	func getOriginalValue() -> RegisteredCodable?
	
	/// Changes the wrapped value of the struct, without mutating the struct.
	/// This is used by the various undo methods.
	///
	func trySetValue(_ value: Any?) -> Bool
	
	
	func isValueEqual(_ value: Any) -> Bool
}
