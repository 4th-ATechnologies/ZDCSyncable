/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

import Foundation

public struct ZDCSet<Element: Hashable & Codable> : ZDCSyncable, Codable, Collection, Equatable {
	
	enum ChangesetKeys: String {
		case added = "added"
		case deleted = "deleted"
	}
	
	public struct ZDCChangeset_Set {
		public let added: Set<Element>
		public let deleted: Set<Element>
	}
	
	private var set: Set<Element>
	
	private var added: Set<Element> = Set()
	private var deleted: Set<Element> = Set()
	
	// ====================================================================================================
	// MARK: Init
	// ====================================================================================================

	public init() {
		set = Set()
	}
	
	public init(minimumCapacity: Int) {
		set = Set(minimumCapacity: minimumCapacity)
	}
	
	public init<S>(_ sequence: S) where S : Sequence, Element == S.Element {
		set = Set(sequence)
	}

	public init(copy source: ZDCSet<Element>, retainChangeTracking: Bool) {
		
		self.set = source.set
		
		if retainChangeTracking {
			self.added = source.added
			self.deleted = source.deleted
		}
	}
	
	// ====================================================================================================
	// MARK: Codable
	// ====================================================================================================
	
	// We encode using the same format as a normal set.
	// This makes it easier to use as a drop-in replacement.
	//
	// Changesets are different, and should be stored separately.
	
	public init(from decoder: Decoder) throws {
		
		set = try Set(from: decoder)
	}
	
	public func encode(to encoder: Encoder) throws {
		
		try set.encode(to: encoder)
	}
	
	// ====================================================================================================
	// MARK: Properties
	// ====================================================================================================

	/// Returns a reference to the underlying Set being wrapped.
	/// Changes to the returned copy will not be reflected in this instance.
	///
	public var rawSet: Set<Element> {
		get {
			let copy = self.set
			return copy
		}
	}
	
	public var isEmpty: Bool {
		get {
			return set.isEmpty
		}
	}
	
	public var count: Int {
		get {
			return set.count
		}
	}
	
	public var capacity: Int {
		get {
			return set.capacity
		}
	}
	
	public mutating func reserveCapacity(_ minimumCapacity: Int) {
	
		set.reserveCapacity(minimumCapacity)
	}

	// ====================================================================================================
	// MARK: Reading
	// ====================================================================================================

	public func contains(_ member: Element) -> Bool {
		return set.contains(member)
	}

	// ====================================================================================================
	// MARK: Writing
	// ====================================================================================================

	@discardableResult
	public mutating func insert(_ item: Element) -> Bool {
		
		if set.contains(item) {
			return false
		}
		else {
			self._willInsert(item)
			
			let (inserted, _) = set.insert(item)
			return inserted
		}
	}

	@discardableResult
	public mutating func remove(_ item: Element) -> Element? {
		
		if set.contains(item) {
			self._willRemove(item)
			return set.remove(item)
		}
		else {
			return nil
		}
	}

	public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
		
		for item in set {
			self._willRemove(item)
		}
		
		set.removeAll(keepingCapacity: keepCapacity)
	}

	// ====================================================================================================
	// MARK: Subscripts
	// ====================================================================================================

	public subscript(position: Set<Element>.Index) -> Set<Element>.Element {
		get {
			return set[position]
		}
	}

	// ====================================================================================================
	// MARK: Enumeration
	// ====================================================================================================

	public var startIndex: Set<Element>.Index {
		return set.startIndex
	}
	
	public var endIndex: Set<Element>.Index {
		return set.endIndex
	}
	
	public func index(after i: Set<Element>.Index) -> Set<Element>.Index {
		return set.index(after: i)
	}

	// ====================================================================================================
	// MARK: Equality
	// ====================================================================================================
	
	// Compares only the underlying rawSet for equality.
	// The changeset information isn't part of the comparison.
	//
	public static func == (lhs: ZDCSet<Element>, rhs: ZDCSet<Element>) -> Bool {
		
		return (lhs.set == rhs.set)
	}
	
	// ====================================================================================================
	// MARK: Change Tracking Internals
	// ====================================================================================================

	private mutating func _willInsert(_ item: Element) {
		
		if deleted.contains(item) {
			
			// Deleted & then later re-added within same changeset.
			// The two actions cancel each other out.
			
			deleted.remove(item)
		}
		else {
			added.insert(item)
		}
	}
	
	private mutating func _willRemove(_ item: Element) {
		
		if added.contains(item) {
			
			// Added & then later removed within same changeset.
			// The two actions cancel each other out.
			
			added.remove(item)
		}
		else {
			deleted.insert(item)
		}
	}

	// ====================================================================================================
	// MARK: ZDCSyncable Protocol
	// ====================================================================================================

	public var hasChanges: Bool {
		get {
			
			if (added.count > 0) || (deleted.count > 0) {
				return true
			}
			
			for item in set {
				
				if let zdc_obj = item as? ZDCSyncableClass {
					if zdc_obj.hasChanges {
						return true
					}
				}
				else if let zdc_struct = item as? ZDCSyncableStruct {
					if zdc_struct.hasChanges {
						return true
					}
				}
			}
			
			return false
		}
	}

	public mutating func clearChangeTracking() {
		
		added.removeAll()
		deleted.removeAll()
		
		var changes_old = Array<Element>()
		var changes_new = Array<Element>()
		
		for item in set {
			
			if let zdc_obj = item as? ZDCSyncableClass {
				
				zdc_obj.clearChangeTracking()
			}
			else if var zdc_struct = item as? ZDCSyncableStruct {
				
				// struct value semantics means we need to write the modified value back to the set
				
				changes_old.append(zdc_struct as! Element)
				zdc_struct.clearChangeTracking()
				changes_new.append(zdc_struct as! Element)
			}
		}
		
		for i in 0 ..< changes_old.count {
			
			let item_old = changes_old[i]
			let item_new = changes_new[i]
			
			set.remove(item_old)
			set.insert(item_new)
		}
	}

	public func peakChangeset() -> ZDCChangeset? {
		
		if !self.hasChanges {
			return nil
		}
		
		// changeset: {
		//   added: AnyCodable([
		//     Element
		//   ]),
		//   deleted: AnyCodable([
		//     Element
		//   ])
		// }
		
		var changeset: ZDCChangeset = Dictionary(minimumCapacity: 2)
		
		if added.count > 0 {
			
			var changeset_added: [Element] = []
			
			for item in added {
				
				if let item = item as? NSCopying {
					changeset_added.append(item.copy() as! Element)
				}
				else {
					changeset_added.append(item)
				}
			}
			
			changeset[ChangesetKeys.added.rawValue] = AnyCodable(changeset_added)
		}
	
		if deleted.count > 0 {
			
			var changeset_deleted: [Element] = []
			
			for item in deleted {
				
				if let item = item as? NSCopying {
					changeset_deleted.append(item.copy() as! Element)
				}
				else {
					changeset_deleted.append(item)
				}
			}
			
			changeset[ChangesetKeys.deleted.rawValue] = AnyCodable(changeset_deleted)
		}
	
		return changeset
	}

	public static func parseChangeset(_ changeset: ZDCChangeset) -> ZDCChangeset_Set? {
		
		// changeset: {
		//   added: AnyCodable([
		//     Element
		//   ]),
		//   deleted: AnyCodable([
		//     Element
		//   ])
		// }
	
		var added = Set<Element>()
		var deleted = Set<Element>()
		
		// added
		if let wrapped_added = changeset[ChangesetKeys.added.rawValue] {
			
			guard let unwrapped_added = wrapped_added.value as? [Element] else {
				return nil // malformed
			}
			
			added = Set(unwrapped_added)
		}
		
		// deleted
		if let wrapped_deleted = changeset[ChangesetKeys.deleted.rawValue] {
			
			guard let unwrapped_deleted = wrapped_deleted.value as? [Element] else {
				return nil // malformed
			}
			
			deleted = Set(unwrapped_deleted)
		}
		
		// Make sure there's no overlap between added & removed.
		// That is, items in changeset_added cannot also be in changeset_removed.
		//
		// Set.isDisjoint:
		// Returns true is the set has no members in common with the given sequence.
		
		if !added.isDisjoint(with: deleted) {
			return nil // malformed
		}
	
		// looks good (not malformed)
		return ZDCChangeset_Set(added: added, deleted: deleted)
	}
	
	public func parseChangeset(_ changeset: ZDCChangeset) -> ZDCChangeset_Set? {
		
		return type(of: self).parseChangeset(changeset)
	}

	private mutating func _undo(_ changeset: ZDCChangeset_Set) throws {
		
		// Step 1 of 2:
		//
		// Undo added objects.
		
		for item in changeset.added {
			self.remove(item)
		}
		
		// Step 2 of 2:
		//
		// Undo removed operations
		
		for item in changeset.deleted {
			self.insert(item)
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
		
		var orderedParsedChangesets: [ZDCChangeset_Set] = []
		
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
				break;
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
				
				break;
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
		
		var parsedChangesets: [ZDCChangeset_Set] = []
		
		for changeset in pendingChangesets {
			
			if let parsedChangeset = parseChangeset(changeset) {
				parsedChangesets.append(parsedChangeset)
			} else {
				throw ZDCSyncableError.malformedChangeset
			}
		}
		
		guard let cloudVersion = inCloudVersion as? ZDCSet<Element> else {
			throw ZDCSyncableError.incorrectType
		}
		
		// Step 1 of 3:
		//
		// Determine which objects have been added & deleted (locally, based on pendingChangesets)
		
		var local_added = Set<Element>()
		var local_deleted = Set<Element>()
		
		for parsedChangeset in parsedChangesets {
			
			for item in parsedChangeset.added {
				
				if local_deleted.contains(item) {
					local_deleted.remove(item)
				}
				else {
					local_added.insert(item)
				}
			}
			
			for item in parsedChangeset.deleted {
				
				if local_added.contains(item) {
					local_added.remove(item)
				}
				else {
					local_deleted.insert(item)
				}
			}
		}
		
		// Step 2 of 3:
		//
		// Add objects that were added by remote devices.
		
		for item in cloudVersion.set {
			
			if !self.set.contains(item) {
				
				// Object exists in cloudVersion, but not in localVersion.
				
				if local_deleted.contains(item) {
					// We've deleted the object locally, but haven't pushed changes to cloud yet.
				}
				else {
					// Object added by remote device.
					self.insert(item)
				}
			}
		}
		
		// Step 3 of 3:
		//
		// Delete objects that were deleted by remote devices.
		
		var deleteMe = Array<Element>()
		
		for item in self.set { // enumerating self.set => cannot be modified during enumeration
		
			if !cloudVersion.set.contains(item) {
				
				// Object exists in localVersion, but not in cloudVersion.
				
				if local_added.contains(item) {
					// We've added the object locally, but haven't pushed changes to cloud yet.
				}
				else {
					// Object deleted by remote device.
					
					deleteMe.append(item)
				}
			}
		}
		
		for item in deleteMe {
			self.remove(item)
		}
		
		return self.changeset() ?? Dictionary()
	}
}

extension ZDCSet: Hashable where Element: Hashable {
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.rawSet)
	}
}
