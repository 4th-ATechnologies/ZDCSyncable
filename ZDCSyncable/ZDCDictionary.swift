/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

import Foundation

/// ZDCDictionary provides a replacement for Swift's Dictionary.
/// It maintains a similar API, and keeps the same value semantics (by also being a struct).
///
/// ZDCDictionary adds the following:
/// - change tracking
/// - undo/redo support
/// - ability to merge changes from remote sources
///
public struct ZDCDictionary<Key: Hashable & Codable, Value: Equatable & Codable>: ZDCSyncable, Codable, Collection, Equatable {
	
	enum ChangesetKeys: String {
		case refs = "refs"
		case added = "added"
		case modified = "modified"
	}
	
	public struct ZDCChangeset_Dictionary {
		public let refs: [Key: ZDCChangeset]
		public let added: Set<Key>
		public let modified: [Key: Value]
	}
	
	private var dict: Dictionary<Key, Value>
	
	private var addedValues: Set<Key> = Set()
	private var originalValues: Dictionary<Key, Value> = Dictionary()
	
	// ====================================================================================================
	// MARK: Init
	// ====================================================================================================

	/// Creates an empty dictionary.
	///
	public init() {
		dict = Dictionary()
	}

	public init(minimumCapacity: Int) {
		dict = Dictionary(minimumCapacity: minimumCapacity)
	}

	public init<S>(uniqueKeysWithValues keysAndValues: S) where S : Sequence, S.Element == (Key, Value) {
		dict = Dictionary(uniqueKeysWithValues: keysAndValues)
	}

	public init(copy source: ZDCDictionary<Key, Value>, retainChangeTracking: Bool) {
		
		dict = source.dict
		
		if retainChangeTracking {
			self.addedValues = source.addedValues
			self.originalValues = source.originalValues
		}
	}
	
	// ====================================================================================================
	// MARK: Codable
	// ====================================================================================================
	
	// We encode using the same format as a normal dictionary.
	// This makes it easier to use as a drop-in replacement.
	//
	// Changesets are different, and should be stored separately.
	
	public init(from decoder: Decoder) throws {
		
		dict = try Dictionary(from: decoder)
	}
	
	public func encode(to encoder: Encoder) throws {
		
		try dict.encode(to: encoder)
	}

	// ====================================================================================================
	// MARK: Properties
	// ====================================================================================================

	/// Returns a copy of the underlying value being wrapped.
	/// Changes to the returned copy will not be reflected in this instance.
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
	
	// ====================================================================================================
	// MARK: Reading
	// ====================================================================================================
	
	public func randomElement() -> (key: Key, value: Value)? {
		
		return dict.randomElement()
	}
	
	// ====================================================================================================
	// MARK: Writing
	// ====================================================================================================

	public mutating func removeValue(forKey key: Key) -> Value? {
		
		let value = dict[key]
		if value != nil {
			self._willRemove(forKey: key)
			dict[key] = nil
		}
		
		return value
	}

	public mutating func removeAll() {
		
		for key in dict.keys {
			self._willRemove(forKey: key)
			dict[key] = nil
		}
	}

	// ====================================================================================================
	// MARK: Subscripts
	// ====================================================================================================
	
	public subscript(key: Key) -> Value? {
		
		get {
			return dict[key]
		}
		
		set(newValue) {
		
			if let newValue = newValue {
				
				if let existingValue = dict[key] {
					
					if existingValue != newValue {
						self._willUpdate(key: key, newValue: newValue)
					}
					
				} else {
					self._willInsert(key: key, newValue: newValue)
				}
				
				dict[key] = newValue
				
			} else { // newValue == nil
		
				if dict[key] != nil {
					self._willRemove(forKey: key)
					dict[key] = nil
				}
		
			}
		}
	}

	public subscript(position: Dictionary<Key, Value>.Index) -> Dictionary<Key, Value>.Element {
		get {
			return dict[position]
		}
	}

	// ====================================================================================================
	// MARK: Enumeration
	// ====================================================================================================
	
	public var startIndex: Dictionary<Key, Value>.Index {
		return dict.startIndex
	}
	
	public var endIndex: Dictionary<Key, Value>.Index {
		return dict.endIndex
	}
	
	public func index(after i: Dictionary<Key, Value>.Index) -> Dictionary<Key, Value>.Index {
		return dict.index(after: i)
	}

	// ====================================================================================================
	// MARK: Equality
	// ====================================================================================================

	// Compares only the underlying rawDictionary for equality.
	// The changeset information isn't part of the comparison.
	//
	public static func == (lhs: ZDCDictionary<Key, Value>, rhs: ZDCDictionary<Key, Value>) -> Bool {

		return (lhs.dict == rhs.dict)
	}
	
	// ====================================================================================================
	// MARK: Change Tracking Internals
	// ====================================================================================================

	private mutating func _willUpdate(key: Key, newValue: Value) {
		
		let wasAdded = addedValues.contains(key)
		if !wasAdded {
			
			if let originalValue = originalValues[key] {
				
				if originalValue == newValue {
					// Reverting value to its original.
					originalValues[key] = nil
				}
				
			} else {
				originalValues[key] = dict[key]
			}
		}
	}

	private mutating func _willInsert(key: Key, newValue: Value) {
		
		if let originalValue = originalValues[key] {
			
			if originalValue == newValue {
				// Reverting value to its original.
				originalValues[key] = nil
			}
			
		} else {
			
			addedValues.insert(key)
		}
	}

	private mutating func _willRemove(forKey key: Key) {
		
		let wasAdded = addedValues.contains(key)
		if wasAdded {
			
			// Value was added within snapshot, and is now being removed
			addedValues.remove(key)
		
		} else {
			
			let originalValue = originalValues[key]
			if originalValue == nil {
				
				originalValues[key] = dict[key]
			}
		}
	}
	
	// ====================================================================================================
	// MARK: ZDCSyncable Protocol
	// ====================================================================================================
	
	public var hasChanges: Bool {
		
		get {
			
			if addedValues.count > 0 || originalValues.count  > 0 {
				return true
			}
			
			for (_, value) in dict {
				
				if let zdc_obj = value as? ZDCSyncableClass {
					if zdc_obj.hasChanges {
						return true
					}
				}
				else if let zdc_struct = value as? ZDCSyncableStruct {
					if zdc_struct.hasChanges {
						return true
					}
				}
			}
			
			return false
		}
	}

	public mutating func clearChangeTracking() {
		
		addedValues.removeAll()
		originalValues.removeAll()
		
		var changes: Dictionary<Key, Value>? = nil
		for (key, value) in dict {
			
			if let zdc_obj = value as? ZDCSyncableClass {
				
				zdc_obj.clearChangeTracking()
			}
			else if var zdc_struct = value as? ZDCSyncableStruct {
				
				zdc_struct.clearChangeTracking()
				
				// struct value semantics means we need to write the modified value back to the dictionary
				
				if changes == nil {
					changes = Dictionary()
				}
				changes![key] = (zdc_struct as! Value)
			}
		}
		
		if let changes = changes {
			
			for (key, value) in changes {
				dict[key] = value
			}
		}
	}

	public func peakChangeset() -> ZDCChangeset? {
		
		if !self.hasChanges {
			return nil
		}
		
		// changeset: {
		//   refs: AnyCodable({
		//     <key: Key> : <changeset: ZDCChangeset>, ...
		//   }),
		//   added: AnyCodable([
		//     <key: Key>, ...
		//   ]),
		//   modified: AnyCodable({
		//     <key: Key> : <oldValue: Value>, ...
		//   })
		// }
		
		var refs: [Key: ZDCChangeset] = [:]
		
		for (key, value) in dict {
			
			// We're looking for syncable types:
			//
			// - ZDCSyncableClass
			// - ZDCSyncableStruct
			
			if let zdc_obj = value as? ZDCSyncableClass {
				
				// ZDCSyncableClass => reference semantics
				//
				// - If value was added, then key is in addedValues.
				//   If this is the case, we should not add to refs.
				//
				// - If value was swapped out, then originalValue will be some other value.
				//   If this is the case, we should not add to refs.
				
				let originalValue = originalValues[key]
				
				let wasAdded = addedValues.contains(key)
				let wasSwapped = (originalValue as AnyObject?) !== (value as AnyObject)
				
				if !wasAdded && !wasSwapped {
					
					var value_changeset = zdc_obj.peakChangeset()
					if value_changeset == nil {
						
						// Edge case:
						//   We add to originalValues dictionary based on equality test (old != new).
						//   We add to refs based on changeset result.
						//   But these queries may not be in agreement.
						//   This would be the case if the equality test included non-synced properties.
						//   So, as a guard, if the value was "modified", but is reporting no changeset,
						//   then we add an empty dictionary to refs,
						//   in order to prevent it from going into values.
						//
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
			else if let zdc_struct = value as? ZDCSyncableStruct {
				
				// ZDCSyncableStruct => value semantics
				//
				// - If value was added, then key is in addedValues.
				//   If this is the case, we should not add to refs.
				
				let wasAdded = addedValues.contains(key)
				if !wasAdded {
					
					var value_changeset = zdc_struct.peakChangeset()
					if value_changeset == nil {
						
						// Edge case:
						//   We add to originalValues dictionary based on equality test (old != new).
						//   We add to refs based on changeset result.
						//   But these queries may not be in agreement.
						//   This would be the case if the equality test included non-synced properties.
						//   So, as a guard, if the value was "modified", but is reporting no changeset,
						//   then we add an empty dictionary to refs,
						//   in order to prevent it from going into values.
						//
						
						let originalValue = originalValues[key]
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
		
		let added = Array<Key>(addedValues)
		
		var modified: [Key: Any] = [:]
		for (key, originalValue) in originalValues {
			
			if refs[key] == nil {
				
				if let originalValue = originalValue as? NSCopying {
					modified[key] = originalValue.copy() as! Value
				}
				else {
					modified[key] = originalValue
				}
			}
		}
		
		var changeset: ZDCChangeset = Dictionary(minimumCapacity: 3)
		if refs.count > 0 {
			changeset[ChangesetKeys.refs.rawValue] = AnyCodable(refs)
		}
		if added.count > 0 {
			changeset[ChangesetKeys.added.rawValue] = AnyCodable(added)
		}
		if modified.count > 0 {
			changeset[ChangesetKeys.modified.rawValue] = AnyCodable(modified)
		}
		
		return changeset
	}
	
	public static func parseChangeset(_ changeset: ZDCChangeset) -> ZDCChangeset_Dictionary? {
		
		// changeset: {
		//   refs: AnyCodable({
		//     <key: Key> : <changeset: ZDCChangeset>, ...
		//   }),
		//   added: AnyCodable([
		//     <key: Key>, ...
		//   ]),
		//   modified: AnyCodable({
		//     <key: Key> : <oldValue: Value>, ...
		//   })
		// }
		
		var refs: [Key: ZDCChangeset] = [:]
		var added = Set<Key>()
		var modified: [Key: Value] = [:]
		
		// refs
		if let wrapped_refs = changeset[ChangesetKeys.refs.rawValue] {
		
			guard let unwrapped_refs = wrapped_refs.value as? [Key: ZDCChangeset] else {
				return nil // malformed
			}
			
			refs = unwrapped_refs
		}
	
		// added
		if let wrapped_added = changeset[ChangesetKeys.added.rawValue] {
			
			guard let unwrapped_added = wrapped_added.value as? [Key] else {
				return nil // malformed
			}
			
			added = Set(unwrapped_added)
		}
		
		// modified
		if let wrapped_modified = changeset[ChangesetKeys.modified.rawValue] {
		
			guard let unwrapped_modified = wrapped_modified.value as? [Key: Value] else {
				return nil // malformed
			}
			
			modified = unwrapped_modified
		}
		
		// Make sure there's no overlap between added & removed.
		// That is, items in changeset_added cannot also be in changeset_removed.
		//
		// Set.isDisjoint:
		// Returns true is the set has no members in common with the given sequence.
		
		let modifiedKeys = Set<Key>(modified.keys)
		
		if !added.isDisjoint(with: modifiedKeys) {
			return nil // malformed
		}
		
		// Looks good (not malformed)
		return ZDCChangeset_Dictionary(refs: refs, added: added, modified: modified)
	}
	
	public func parseChangeset(_ changeset: ZDCChangeset) -> ZDCChangeset_Dictionary? {
		
		return type(of: self).parseChangeset(changeset)
	}

	private mutating func _undo(_ changeset: ZDCChangeset_Dictionary) throws {
		
		for (key, changeset) in changeset.refs {
			
			let value = dict[key]
			
			if let zdc_obj = value as? ZDCSyncableClass {
				
				try zdc_obj.performUndo(changeset)
			}
			else if var zdc_struct = value as? ZDCSyncableStruct {
				
				try zdc_struct.performUndo(changeset)
				
				// struct value semantics means we need to write the modified value back to the dictionary
				
				self.dict[key] = (zdc_struct as! Value)
			}
			else {
				throw ZDCSyncableError.mismatchedChangeset
			}
		}
		
		for key in changeset.added {
			
			self[key] = nil
		}
		
		for (key, oldValue) in changeset.modified {
			
			self[key] = oldValue
		}
	}
	
	public mutating func performUndo(_ changeset: ZDCChangeset) throws {
		
		if self.hasChanges {
			// You cannot invoke this method if the object currently has changes.
			// The code doesn't know what you want to happen.
			// Are you asking us to throw away the current changes ?
			// Are you expecting us to magically merge everything ?
			throw ZDCSyncableError.hasChanges
		}
		
		guard let parsedChangeset = parseChangeset(changeset) else {
			throw ZDCSyncableError.malformedChangeset
		}
		
		do {
			try self._undo(parsedChangeset)
			
		} catch {
			
			// Abandon botched undo attempt - revert to original state
			self.rollback()
			throw error
		}
	}

	public mutating func importChangesets(_ orderedChangesets: [ZDCChangeset]) throws {
		
		if self.hasChanges {
			// You cannot invoke this method if the object currently has changes.
			// The code doesn't know what you want to happen.
			// Are you asking us to throw away the current changes ?
			// Are you expecting us to magically merge everything ?
			throw ZDCSyncableError.hasChanges
		}
		
		// Check for malformed changesets.
		// It's better to detect this early on, before we start modifying the object.
		
		var orderedParsedChangesets: [ZDCChangeset_Dictionary] = []
		
		for changeset in orderedChangesets {
			
			if let parsedChangeset = parseChangeset(changeset) {
				orderedParsedChangesets.append(parsedChangeset)
			} else {
				throw ZDCSyncableError.malformedChangeset
			}
		}
		
		if orderedParsedChangesets.count == 0 {
			return
		}
		
		var result_error: Error?
		var changesets_redo: [ZDCChangeset] = []
		
		for parsedChangeset in orderedParsedChangesets.reversed() {
			
			do {
				try self._undo(parsedChangeset)
				
				if let redo = self.changeset() {
					changesets_redo.append(redo)
				}
				
			} catch {
				
				result_error = error
				
				// Abort botched attempt - Revert to original state (before current `_undo:`)
				self.rollback()
				
				// We still need to revert previous `_undo:` calls
				break
			}
		}
		
		for redo in changesets_redo.reversed()	{
			
			do {
				if let parsedRedo = parseChangeset(redo) {
					try self._undo(parsedRedo)
				}
				
			} catch {
				
				// Not much we can do here - we're in a bad state
				if result_error == nil {
					result_error = error
				}
				
				break
			}
		}
		
		if (result_error != nil) {
			throw result_error!
		}
	}

	public mutating func merge(cloudVersion inCloudVersion: ZDCSyncable,
	                                     pendingChangesets: [ZDCChangeset])
		throws -> ZDCChangeset
	{
		if self.hasChanges {
			// You cannot invoke this method if the object currently has changes.
			// The code doesn't know what you want to happen.
			// Are you asking us to throw away the current changes ?
			// Are you expecting us to magically merge everything ?
			throw ZDCSyncableError.hasChanges
		}
		
		// Check for malformed changesets.
		// It's better to detect this early on, before we start modifying the object.
		
		var parsedChangesets: [ZDCChangeset_Dictionary] = []
		
		for changeset in pendingChangesets {
			
			if let parsedChangeset = parseChangeset(changeset) {
				parsedChangesets.append(parsedChangeset)
			} else {
				throw ZDCSyncableError.malformedChangeset
			}
		}
		
		guard let cloudVersion = inCloudVersion as? ZDCDictionary<Key, Value> else {
			throw ZDCSyncableError.incorrectType
		}
		
		// Step 1 of 4:
		//
		// We need to determine which keys have been changed locally, and what the original versions were.
		// We'll need this information when comparing to the cloudVersion.
		
		var merged_addedValues = Set<Key>()
		var merged_originalValues = Dictionary<Key, Value>()
		
		for parsedChangeset in parsedChangesets {
			
			for key in parsedChangeset.added {
				
				if merged_originalValues[key] == nil {
					merged_addedValues.insert(key)
				}
			}
			for (key, oldValue) in parsedChangeset.modified {
				
				if !merged_addedValues.contains(key) &&
				    merged_originalValues[key] == nil
				{
					merged_originalValues[key] = oldValue
				}
			}
		}
		
		// Step 2 of 4:
		//
		// Next, we're going to enumerate what values are in the cloud.
		// This will tell us what was added & modified by remote devices.
		
		for (key, cloudValue) in cloudVersion {
			
			let currentLocalValue = self.dict[key]
			
			let wasLocalAdded = merged_addedValues.contains(key)
			let originalLocalValue = merged_originalValues[key]
			
			let modifiedValueLocally = wasLocalAdded || (originalLocalValue != nil)
			
			if !modifiedValueLocally {
				
				if ((currentLocalValue is ZDCSyncableClass) && (cloudValue is ZDCSyncableClass)) ||
				   ((currentLocalValue is ZDCSyncableStruct) && (cloudValue is ZDCSyncableStruct)) {
					
					continue // handled by refs
				}
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
					
					if let originalLocalValue = originalLocalValue,
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
				self[key] = cloudValue
			}
		}
		
		// Step 3 of 4:
		//
		// Next we need to determine if any values were deleted by remote devices.
		
		do {
			var baseKeys = Set<Key>(dict.keys)
			
			for key in merged_addedValues {
				
				// We added this key.
				// So it's not part of the set the cloud is expected to have.
				baseKeys.remove(key)
			}
			for (key, _) in merged_originalValues {
				
				// For items that we may have deleted (no longer in dict.keys)
				baseKeys.insert(key)
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
		
		for parsedChangeset in parsedChangesets {
		
			for (key, _) in parsedChangeset.refs {
				
				let wasAdded = merged_addedValues.contains(key)
				let originalValue = merged_originalValues[key]
				if !wasAdded && originalValue == nil {
					
					refs.insert(key)
				}
			}
		}
		
		for key in refs {
			
			let local_value = self.dict[key]
			let cloud_value = cloudVersion.dict[key]
			
			var pendingChangesets_ref: [ZDCChangeset] = []
			pendingChangesets_ref.reserveCapacity(pendingChangesets.count)
			
			for parsedChangeset in parsedChangesets {
				
				if let changeset_ref = parsedChangeset.refs[key] {
					pendingChangesets_ref.append(changeset_ref)
				}
			}
			
			if let local_obj = local_value as? ZDCSyncableClass,
			   let cloud_obj = cloud_value as? ZDCSyncableClass
			{
				let _ = try local_obj.merge(cloudVersion: cloud_obj,
				                       pendingChangesets: pendingChangesets_ref)
			}
			else if var local_struct = local_value as? ZDCSyncableStruct,
			        let cloud_struct = cloud_value as? ZDCSyncableStruct
			{
				let _ = try local_struct.merge(cloudVersion: cloud_struct,
				                          pendingChangesets: pendingChangesets_ref)
				
				// struct value semantics means we need to write the modified value back to the dictionary
				
				self.dict[key] = (local_struct as! Value)
			}
		}
		
		return self.changeset() ?? Dictionary()
	}
}

extension ZDCDictionary: Hashable where Key: Hashable, Value: Hashable {
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.rawDictionary)
	}
}
