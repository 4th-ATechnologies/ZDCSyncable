/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & objects in pure Swift.

import Foundation

public struct ZDCSet<Element: Hashable & Codable> : ZDCSyncable, Codable, Collection, Equatable {
	
	enum CodingKeys: String, CodingKey {
		case set = "set"
	}
	
	enum ChangesetKeys: String {
		case added = "added"
		case deleted = "deleted"
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
		set = Set(minimumCapacity: sequence.underestimatedCount)
		
		for item in sequence {
			
		//	self.insert(item) // not tracking changes during init
			set.insert(item)
		}
	}

	public init(copy source: ZDCSet<Element>, retainChangeTracking: Bool) {
		
		self.set = source.set
		
		if retainChangeTracking {
			self.added = source.added
			self.deleted = source.deleted
		}
	}
	
	// ====================================================================================================
	// MARK: Properties
	// ====================================================================================================

	/// Returns a reference to the underlying Set being wrapped.
	/// This is a read-only copy - changes to the returned set will not be reflected in the ZDCSet instance.
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
		
		var changeset: ZDCChangeset = Dictionary(minimumCapacity: 2)
		
		if added.count > 0 {
			
			// changeset: {
			//   added: [{
			//     obj, ...
			//   }],
			//   ...
			// }
			
			var changeset_added = Set<Element>(minimumCapacity: added.count)
			
			for item in added {
				
				if let item = item as? NSCopying {
					changeset_added.insert(item.copy() as! Element)
				}
				else {
					changeset_added.insert(item)
				}
			}
			
			changeset[ChangesetKeys.added.rawValue] = changeset_added
		}
	
		if deleted.count > 0 {
			
			// changeset: {
			//   deleted: [{
			//     obj, ...
			//   }],
			//   ...
			// }
			
			var changeset_deleted = Set<Element>(minimumCapacity: deleted.count)
			
			for item in deleted {
				
				if let item = item as? NSCopying {
					changeset_deleted.insert(item.copy() as! Element)
				}
				else {
					changeset_deleted.insert(item)
				}
			}
			
			changeset[ChangesetKeys.deleted.rawValue] = changeset_deleted
		}
	
		return changeset
	}

	private func isMalformedChangeset(_ changeset: ZDCChangeset) -> Bool {
		
		if changeset.count == 0 {
			return false
		}
		
		// changeset: {
		//   added: [{
		//     <obj: Any>, ...
		//   }],
		//   deleted: [{
		//     <obj: Any>, ...
		//   }]
		// }
	
		// added
	
		var changeset_added: Set<Element>? = nil
		do {
			
			let _added = changeset[ChangesetKeys.added.rawValue]
			if (_added != nil) {
		
				if let _added = _added as? Set<Element> {
					changeset_added = _added
				}
				else {
					return true // malformed !
				}
			}
		}
		
		// deleted
		
		var changeset_deleted: Set<Element>? = nil
		do {
		
			let _deleted = changeset[ChangesetKeys.deleted.rawValue]
			if (_deleted != nil) {
		
				if let _deleted = _deleted as? Set<Element> {
					changeset_deleted = _deleted
				}
				else {
					return true // malformed !
				}
			}
		}
		
		// Make sure there's no overlap between added & removed.
		// That is, items in changeset_added cannot also be in changeset_removed.
	
		if ((changeset_added != nil) && (changeset_deleted != nil)) {
			
			if !changeset_added!.isDisjoint(with: changeset_deleted!) {
				return true // malformed !
			}
		}
	
		// looks good (not malformed)
		return false
	}

	private mutating func _undo(_ changeset: ZDCChangeset) throws {
		
		// Important: `isMalformedChangeset:` must be called before invoking this method.
		
		// Step 1 of 2:
		//
		// Undo added objects.
		
		if let changeset_added = changeset[ChangesetKeys.added.rawValue] as? Set<Element> {
			
			for item in changeset_added {
				self.remove(item)
			}
		}
		
		// Step 2 of 2:
		//
		// Undo removed operations
		
		if let changeset_deleted = changeset[ChangesetKeys.deleted.rawValue] as? Set<Element> {
			
			for item in changeset_deleted {
				self.insert(item)
			}
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
		var changesets_redo: [ZDCChangeset] = []
		
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
		//
		for changeset in pendingChangesets {
			
			if self.isMalformedChangeset(changeset) {
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
		
		for changeset in pendingChangesets {
			
			if let changeset_added = changeset[ChangesetKeys.added.rawValue] as? Set<Element> {
				
				for obj in changeset_added {
					
					if local_deleted.contains(obj) {
						local_deleted.remove(obj)
					}
					else {
						local_added.insert(obj)
					}
				}
			}
			
			if let changeset_deleted = changeset[ChangesetKeys.deleted.rawValue] as? Set<Element> {
			
				for obj in changeset_deleted {
					
					if local_added.contains(obj) {
						local_added.remove(obj)
					}
					else {
						local_deleted.insert(obj)
					}
				}
			}
		}
		
		// Step 2 of 3:
		//
		// Add objects that were added by remote devices.
		
		for obj in cloudVersion.set {
			
			if !self.set.contains(obj) {
				
				// Object exists in cloudVersion, but not in localVersion.
				
				if local_deleted.contains(obj) {
					// We've deleted the object locally, but haven't pushed changes to cloud yet.
				}
				else {
					// Object added by remote device.
					self.insert(obj)
				}
			}
		}
		
		// Step 3 of 3:
		//
		// Delete objects that were deleted by remote devices.
		
		var deleteMe = Array<Element>()
		
		for obj in self.set { // enumerating self.set => cannot be modified during enumeration
		
			if !cloudVersion.set.contains(obj) {
				
				// Object exists in localVersion, but not in cloudVersion.
				
				if local_added.contains(obj) {
					// We've added the object locally, but haven't pushed changes to cloud yet.
				}
				else {
					// Object deleted by remote device.
					
					deleteMe.append(obj)
				}
			}
		}
		
		for obj in deleteMe {
			self.remove(obj)
		}
		
		return self.changeset() ?? Dictionary()
	}
}
