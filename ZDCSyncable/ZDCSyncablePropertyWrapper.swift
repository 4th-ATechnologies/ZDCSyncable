/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

import Foundation

@propertyWrapper
public struct Syncable<T>: ZDCSyncableProperty where T: Equatable {
	
	private var _ref: SyncableRef<T>
	
	public init(wrappedValue: T) {
		_ref = SyncableRef<T>(originalValue: wrappedValue)
	}
	
	/// The @propertyWrapper protocol for getter/setter.
	///
	public var wrappedValue: T {
		get {
			return _ref.value
		}
		set {
			// Important:
			// We are purposefully NOT using copy-on-write here.
			// Doing so would completely break this implementation.
			//
			_ref = SyncableRef(value: newValue,
			           originalValue: _ref.originalValue,
			              hasChanges: true)
		}
	}
	
	/// Returns true if the value has been changed,
	/// and the currentValue != originalValue.
	///
	public var hasChanges: Bool {
		get {
			return _ref.hasChanges && (_ref.value != _ref.originalValue)
		}
	}
	
	/// Returns the originalValue.
	/// In particular, the value passed to `init(wrappedValue: T)`.
	///
	/// Note:
	///   If your type<T> is an optional, such as `@Synced var str: String?`,
	///   the Swift compiler automatically calls `_str.init(wrappedValue: nil)`
	///   BEFORE your init method is invoked. If you need to work around this
	///   problem, then call `_str.clearChangeTracking()` as needed. For example,
	///   you might call this after assigning `str` with the value you consider
	///   to be the originalValue.
	///
	public var originalValue: T {
		get {
			return _ref.originalValue
		}
	}
	
	/// Allows you to clear the internal change tracking information.
	/// 
	public func clearChangeTracking() {
	
		_ref.originalValue = _ref.value
		_ref.hasChanges = false
	}
	
	internal func getCurrentValue() -> Any? {
		return self.wrappedValue
	}
	
	internal func getOriginalValue() -> Any? {
		return self.originalValue
	}
	
	internal func trySetValue(_ value: Any?) -> Bool {
		
		if let prop = value as? ZDCSyncableProperty {
			if let cast_value = prop.getCurrentValue() as? T {
				_ref.value = cast_value
				_ref.hasChanges = true
				return true
			}
		}
		else if let cast_value = value as? T {
			_ref.value = cast_value
			_ref.hasChanges = true
			return true
		}
		
		return false
	}
	
	internal func isValueEqual(_ value: Any) -> Bool {
		
		if let prop = value as? ZDCSyncableProperty {
			if let value = prop.getCurrentValue() as? T {
				return _ref.value == value
			}
		}
		else if let value = value as? T {
			return _ref.value == value
		}
		
		return false
	}
}

fileprivate class SyncableRef<T> where T: Equatable {
	var value: T
	var originalValue: T
	var hasChanges: Bool
	
	init(value: T, originalValue: T, hasChanges: Bool) {
		self.value = value
		self.originalValue = originalValue
		self.hasChanges = hasChanges
	}
	
	init(originalValue: T) {
		self.value = originalValue
		self.originalValue = originalValue
		self.hasChanges = false
	}
}
