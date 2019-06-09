/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

import Foundation

public class ZDCDictionary<Key: Hashable & Codable, Value: Equatable & Codable>: ZDCObject, ZDCSyncable, Codable, Collection {
	
	enum CodingKeys: String, CodingKey {
		case dict = "dict"
	}
	
	enum ChangesetKeys: String {
		case refs = "refs"
		case values = "values"
	}
	
	private var dict: Dictionary<Key, Value>
	
	lazy private var originalValues: Dictionary<Key, Any> = Dictionary()
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Init
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public required init() {
		dict = Dictionary()
		super.init()
	}
	
	public init(minimumCapacity: Int) {
		dict = Dictionary(minimumCapacity: minimumCapacity)
		super.init()
	}
	
	public init<S>(uniqueKeysWithValues keysAndValues: S) where S : Sequence, S.Element == (Key, Value) {
		dict = Dictionary(minimumCapacity: keysAndValues.underestimatedCount)
		super.init()
		
		for (key, value) in keysAndValues {
			
			self[key] = value
		}
	}
	
	public init(zdc source: ZDCDictionary<Key, Value>, copyValues: Bool = false) {
		
		dict = Dictionary(minimumCapacity: source.count)
		super.init()
		
		for (key, value) in source {
			
			var copied = false
			if copyValues, let value = value as? NSCopying {
				
				if let copiedValue = value.copy(with: nil) as? Value {
					self[key] = copiedValue
					copied = true
				}
			}
			
			if !copied {
				self[key] = value
			}
		}
	}
	
	public required init(copy source: ZDCObject) {
		
		if let source = source as? ZDCDictionary<Key, Value> {
			
			self.dict = source.dict
			super.init(copy: source)
			
			self.originalValues = source.originalValues
		}
		else {
			
			fatalError("init(copy:) invoked with invalid source")
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Properties
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	/// Returns a copy of the underlying Array being wrapped.
	/// This is a read-only copy - changes to the returned copy will not be reflected in this instance.
	///
	public var rawDictionary: Dictionary<Key, Value> {
		get {
			let copy = self.dict
			return copy
		}
	}
	
	public var isEmpty: Bool {
		get {
			return dict.isEmpty
		}
	}
	
	public var count: Int {
		get {
			return dict.count
		}
	}
	
	public var capacity: Int {
		get {
			return dict.capacity
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Reading
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public func randomElement() -> (key: Key, value: Value)? {
		
		return dict.randomElement()
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Writing
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public func removeValue(forKey key: Key) -> Value? {
		
		let value = dict[key]
		if (value != nil) {
			self._willRemove(forKey: key)
			dict[key] = nil
		}
		
		return value
	}
	
	public func removeAll() {
		
		if (self.isImmutable) {
			ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
		}
		
		for key in dict.keys {
			self._willRemove(forKey: key)
			dict[key] = nil
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Subscripts
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public subscript(key: Key) -> Value? {
		
		get {
			return dict[key]
		}
		
		set(value) {
			
			if (self.isImmutable) {
				ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
			}
			
			if (value == nil)
			{
				if dict[key] != nil {
					self._willRemove(forKey: key)
					dict[key] = nil
				}
			}
			else
			{
				if dict[key] == nil {
					self._willInsert(forKey: key)
				} else {
					self._willUpdate(forKey: key)
				}
				dict[key] = value
			}
		}
	}
	
	public subscript(position: Dictionary<Key, Value>.Index) -> Dictionary<Key, Value>.Element {
		get {
			return dict[position]
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Enumeration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public var startIndex: Dictionary<Key, Value>.Index {
		return dict.startIndex
	}
	
	public var endIndex: Dictionary<Key, Value>.Index {
		return dict.endIndex
	}
	
	public func index(after i: Dictionary<Key, Value>.Index) -> Dictionary<Key, Value>.Index {
		return dict.index(after: i)
	}
		
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Equality
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// Tricky pitfall:
	//
	// This function won't get called because this is a subclass of NSObject.
	// There's a good description of the technical reasons why here:
	// https://stackoverflow.com/questions/42283715/overload-for-custom-class-is-not-always-called
	//
	// The solution is to override isEqual() instead.
	//
//	static func == (lhs: ZDCDictionary<Key, Value>, rhs: ZDCDictionary<Key, Value>) -> Bool {
//
//		return (lhs.dict == rhs.dict)
//	}
	
	override public func isEqual(_ object: Any?) -> Bool {
		
		if let another = object as? ZDCDictionary<Key, Value> {
			return isEqualToDictionary(another)
		}
		else {
			return false
		}
	}
	
	public func isEqualToDictionary(_ another: ZDCDictionary<Key, Value>) -> Bool {
		
		// Nope, this doesn't work:
		//	return (self == another)
		//           ^^ FAIL
		// This actually calls isEqual() again, leading to an infinite loop :(
		
		return (self.dict == another.dict)
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Change Tracking Internals
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private func _willUpdate(forKey key: Key) {
		
		if (originalValues[key] == nil) {
			originalValues[key] = dict[key]
		}
	}
	
	private func _willInsert(forKey key: Key) {
		
		if (originalValues[key] == nil) {
			originalValues[key] = ZDCNull.sharedInstance()
		}
	}
	
	private func _willRemove(forKey key: Key) {
		
		let originalValue = originalValues[key]
		if (originalValue == nil)
		{
			originalValues[key] = dict[key];
		}
		else if (originalValue is ZDCNull)
		{
			// Value was added within snapshot, and is now being removed
			originalValues[key] = nil
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: ZDCObject
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	override public func makeImmutable() {
		
		super.makeImmutable()

		for (_, value) in dict {
			
			if let zdc_value = value as? ZDCObject {
				zdc_value.makeImmutable()
			}
		}
	}
	
	override public var hasChanges: Bool {
		
		get {
			if super.hasChanges {
				return true
			}
			
			if (originalValues.count  > 0) {
				return true
			}
			
			for (_, value) in dict {
				
				if let zdc_value = value as? ZDCObject {
					if zdc_value.hasChanges {
						return true
					}
				}
			}
			
			return false
		}
	}
	
	override public func clearChangeTracking() {
		
		super.clearChangeTracking()
		
		originalValues.removeAll()
		
		for (_, value) in dict {
			
			if let zdc_value = value as? ZDCObject {
				
				zdc_value.clearChangeTracking()
			}
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: ZDCSyncable
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private func _changeset() -> Dictionary<String, Any>? {
		
		if !self.hasChanges {
			return nil
		}
		
		var changeset = Dictionary<String, Any>(minimumCapacity: 2)
		
		// changeset: {
		//   refs: {
		//     key: changeset, ...
		//   },
		//   ...
		// }
		
		var refs = Dictionary<Key, Dictionary<String, Any>>()
		
		for (key, value) in dict {
			
			if let zdc_value = value as? ZDCSyncable {
				
				let originalValue = originalValues[key]
				
				// Several possibilities:
				//
				// - If value was added, then originalValue will be ZDCNull.
				//   If this is the case, we should not add to refs.
				//
				// - If value was swapped out, then originalValue will be some other value.
				//   If this is the case, we should not add to refs.
				//
				// - If value was simply modified, then originalValue wll be the same as value.
				//   And only then should we add a changeset to refs.
				
				let wasAdded = (originalValue is ZDCNull)
				var wasSwapped = false
				
				if let originalValue = originalValue as? Value {
					wasSwapped = (originalValue != value)
				}
				
				if !wasAdded && !wasSwapped {
					
					var value_changeset = zdc_value.peakChangeset()
					if (value_changeset == nil) {
						
						let wasModified = originalValue != nil
						if wasModified {
							
							value_changeset = Dictionary()
						}
					}
					
					if let value_changeset = value_changeset {
						refs[key] = value_changeset
					}
				}
			}
		}
		
		if refs.count > 0 {
			changeset[ChangesetKeys.refs.rawValue] = refs
		}
		
		if originalValues.count > 0 {
			
			// changeset: {
			//   values: {
			//     key: oldValue, ...
			//   },
			//   ...
			// }
			
			var values = Dictionary<Key, Any>()
			
			for (key, originalValue) in originalValues {
				
				if refs[key] != nil {
					values[key] = ZDCRef.sharedInstance()
				}
				else if let originalValue = originalValue as? NSCopying {
					values[key] = originalValue.copy()
				}
				else {
					values[key] = originalValue;
				}
			}
			
			changeset[ChangesetKeys.values.rawValue] = values
		}
		
		return changeset
	}
	
	public func peakChangeset() -> Dictionary<String, Any>? {
		
		let changeset = self._changeset()
		return changeset
	}
	
	private func isMalformedChangeset(_ changeset: Dictionary<String, Any>) -> Bool {
		
		if changeset.count == 0 {
			return false
		}
		
		// changeset: {
		//   refs: {
		//     <key: Key> : <changeset: Dictionary<String, Any>>, ...
		//   },
		//   values: {
		//     <key: Any> : <oldValue: ZDCNull|ZDCRef|Value>, ...
		//   }
		// }
		
		do { // refs
			
			if let changeset_refs = changeset[ChangesetKeys.refs.rawValue] {
			
				if let _ = changeset_refs as? Dictionary<Key, Dictionary<String, Any>> {
					// ok
				} else {
					return true // malformed !
				}
			}
		}
	
		do { // values
				
			if let changeset_values = changeset[ChangesetKeys.values.rawValue] {
	
				if let changeset_values = changeset_values as? Dictionary<Key, Any> {
	
					for (_, value) in changeset_values {
						
						if (value is ZDCNull) || (value is ZDCRef) || (value is Value) {
							// ok
						} else {
							return true // malformed !
						}
					}
				}
				else {
					return true // malformed !
				}
			}
		}
		
		// Looks good (not malformed)
		return false
	}
	
	private func _undo(_ changeset: Dictionary<String, Any>) throws {
		
		// Important: `isMalformedChangeset:` must be called before invoking this method.
		
		if let changeset_refs = changeset[ChangesetKeys.refs.rawValue] as? Dictionary<Key, Dictionary<String, Any>> {
		
			for (key, changeset) in changeset_refs {
				
				let value = dict[key]
				
				if let zdc_value = value as? ZDCSyncable {
					
					try zdc_value.performUndo(changeset)
				}
				else {
					throw ZDCSyncableError.mismatchedChangeset
				}
			}
		}
		
		if let changeset_values = changeset[ChangesetKeys.values.rawValue] as? Dictionary<Key, Any> {
		
			for (key, oldValue) in changeset_values {
				
				if oldValue is ZDCNull {
					self[key] = nil
				}
				else if let oldValue = oldValue as? Value {
					self[key] = oldValue
				}
			}
		}
	}
	
	public func performUndo(_ changeset: Dictionary<String, Any>) throws {
		
		if (self.isImmutable) {
			ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
		}
		
		if self.hasChanges {
			// You cannot invoke this method if the object currently has changes.
			// The code doesn't know what you want to happen.
			// Are you asking us to throw away the current changes ?
			// Are you expecting us to magically merge everything ?
			throw ZDCSyncableError.hasChanges
		}
		
		if self.isMalformedChangeset(changeset) {
			throw ZDCSyncableError.malformedChangeset
		}
		
		do {
			try self._undo(changeset)
			
		} catch {
			
			// Abandon botched undo attempt - revert to original state
			self.rollback()
			throw error
		}
	}
	
	public func importChangesets(_ orderedChangesets: Array<Dictionary<String, Any>>) throws {
		
		if self.isImmutable {
			ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
		}
		
		if self.hasChanges {
			// You cannot invoke this method if the object currently has changes.
			// The code doesn't know what you want to happen.
			// Are you asking us to throw away the current changes ?
			// Are you expecting us to magically merge everything ?
			throw ZDCSyncableError.hasChanges
		}
		
		// Check for malformed changesets.
		// It's better to detect this early on, before we start modifying the object.
		//
		for changeset in orderedChangesets {
			
			if self.isMalformedChangeset(changeset) {
				throw ZDCSyncableError.malformedChangeset
			}
		}
		
		if orderedChangesets.count == 0 {
			return
		}
		
		var result_error: Error?
		var changesets_redo = Array<Dictionary<String, Any>>()
		
		for changeset in orderedChangesets.reversed() {
			
			do {
				try self._undo(changeset)
				
				if let redo = self.changeset() {
					changesets_redo.append(redo)
				}
				
			} catch {
				
				result_error = error
				
				// Abort botched attempt - Revert to original state (before current `_undo:`)
				self.rollback()
				
				// We still need to revert previous `_undo:` calls
				break;
			}
		}
		
		for redo in changesets_redo.reversed()	{
			
			do {
				try self._undo(redo)
				
			} catch {
				
				// Not much we can do here - we're in a bad state
				if result_error == nil {
					result_error = error
				}
				
				break;
			}
		}
		
		if (result_error != nil) {
			throw result_error!
		}
	}
	
	public func merge(cloudVersion inCloudVersion: ZDCSyncable,
	                  pendingChangesets: Array<Dictionary<String, Any>>) throws -> Dictionary<String, Any> {
		
		if self.isImmutable {
			ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
		}
		
		if self.hasChanges {
			// You cannot invoke this method if the object currently has changes.
			// The code doesn't know what you want to happen.
			// Are you asking us to throw away the current changes ?
			// Are you expecting us to magically merge everything ?
			throw ZDCSyncableError.hasChanges
		}
		
		// Check for malformed changesets.
		// It's better to detect this early on, before we start modifying the object.
		//
		for changeset in pendingChangesets {
			
			if self.isMalformedChangeset(changeset) {
				throw ZDCSyncableError.malformedChangeset
			}
		}
		
		guard let cloudVersion = inCloudVersion as? ZDCDictionary<Key, Value> else {
			throw ZDCSyncableError.incorrectObjectClass
		}
		
		// Step 1 of 4:
		//
		// We need to determine which keys have been changed locally, and what the original versions were.
		// We'll need this information when comparing to the cloudVersion.
		
		var merged_originalValues = Dictionary<Key, Any>()
		
		for changeset in pendingChangesets {
			
			if let changeset_originalValues = changeset[ChangesetKeys.values.rawValue] as? Dictionary<Key, Any> {
				
				for (key, oldValue) in changeset_originalValues {
					
					if (merged_originalValues[key] == nil) {
						
						merged_originalValues[key] = oldValue
					}
				}
			}
		}
		
		// Step 2 of 4:
		//
		// Next, we're going to enumerate what values are in the cloud.
		// This will tell us what was added & modified by remote devices.
		
		for (key, cloudValue) in cloudVersion {
			
			let currentLocalValue = self.dict[key]
			var originalLocalValue = merged_originalValues[key]
			
			let modifiedValueLocally = (originalLocalValue != nil)
			if originalLocalValue is ZDCNull {
				originalLocalValue = nil
			}
			
			if !modifiedValueLocally && (currentLocalValue is ZDCSyncable) && (cloudValue is ZDCSyncable) {
				
				continue // handled by refs
			}
			
			var mergeRemoteValue = false
			
			if let currentLocalValue = currentLocalValue,
				currentLocalValue == cloudValue
			{
				// remote & local values match
			}
			else
			{
				// remote & (current) local values differ
				
				if modifiedValueLocally {
					
					if let originalLocalValue = originalLocalValue as? Value,
						originalLocalValue == cloudValue
					{
						// modified by local only
					}
					else
					{
						// Value was added/modified by local & remote.
						// Remote wins.
						mergeRemoteValue = true
					}
					
				} else {
					
					// We have not modified the value locally.
					// Therefore the value was added/modified by remote.
					mergeRemoteValue = true
				}
			}
			
			if (mergeRemoteValue)
			{
				self[key] = cloudValue;
			}
		}
		
		// Step 3 of 4:
		//
		// Next we need to determine if any values were deleted by remote devices.
		do {
			var baseKeys = Set<Key>(dict.keys)
			
			for (key, originalValue) in merged_originalValues {
				
				if originalValue is ZDCNull { // Null => we added this tuple.
					baseKeys.remove(key)       // So it's not part of the set the cloud is expected to have.
				}
				else {
					baseKeys.insert(key)       // For items that we may have deleted (no longer in dict.keys)
				}
			}
			
			for key in baseKeys {
				
				let remoteValue = cloudVersion[key]
				if (remoteValue == nil)
				{
					// The remote key/value pair was deleted
					
					self[key] = nil
				}
			}
		}
		
		// Step 4 of 4:
		//
		// Merge the ZDCSyncable properties
		
		var refs = Set<Key>()
		
		for changeset in pendingChangesets {
			
			if let changeset_refs = changeset[ChangesetKeys.refs.rawValue] as? Dictionary<Key, Dictionary<String, Any>> {
			
				for (key, _) in changeset_refs {
					
					let originalValue = merged_originalValues[key]
					if (originalValue == nil) || (originalValue is ZDCRef) {
						
						refs.insert(key)
					}
				}
			}
		}
		
		for key in refs {
			
			let localRef = self.dict[key]
			let cloudRef = cloudVersion.dict[key]
			
			if let localRef = localRef as? ZDCSyncable,
			   let cloudRef = cloudRef as? ZDCSyncable
			{
				var pendingChangesets_ref = Array<Dictionary<String, Any>>()
				pendingChangesets_ref.reserveCapacity(pendingChangesets.count)
				
				for changeset in pendingChangesets {
					
					let changeset_refs = changeset[ChangesetKeys.refs.rawValue]
					
					if let changeset_refs = changeset_refs as? Dictionary<Key, Dictionary<String, Any>>,
					   let changeset_ref = changeset_refs[key]
					{
						pendingChangesets_ref.append(changeset_ref)
					}
				}
				
				let _ = try localRef.merge(cloudVersion: cloudRef, pendingChangesets: pendingChangesets_ref)
			}
		}
		
		return self.changeset() ?? Dictionary()
	}
}
