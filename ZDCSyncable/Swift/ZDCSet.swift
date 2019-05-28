/**
 * Syncable
 * <GitHub URL goes here>
**/

import Foundation

public class ZDCSet<Element: Hashable & Codable> : ZDCObject, ZDCSyncable, Codable, Collection {
	
	enum CodingKeys: String, CodingKey {
		case set = "set"
	}
	
	enum ChangesetKeys: String {
		case added = "added"
		case deleted = "deleted"
	}
	
	private var set: Set<Element>
	
	lazy private var added: Set<Element> = Set()
	lazy private var deleted: Set<Element> = Set()
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Init
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public required init() {
		set = Set()
		super.init()
	}
	
	public init(minimumCapacity: Int) {
		set = Set(minimumCapacity: minimumCapacity)
		super.init()
	}
	
	public init<S>(_ sequence: S, copyValues: Bool = false) where S : Sequence, Element == S.Element {
		set = Set(minimumCapacity: sequence.underestimatedCount)
		super.init()
		
		for item in sequence {
			
			var copied = false
			if copyValues, let item = item as? NSCopying {
				
				if let copiedItem = item.copy(with: nil) as? Element {
					self.insert(copiedItem)
					copied = true
				}
			}
			
			if !copied {
				self.insert(item)
			}
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Properties
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Returns a reference to the underlying Set being wrapped.
	 * This is a read-only copy - changes to the returned set will not be reflected in the ZDCSet instance.
	 */
	public var rawSet: Set<Element> {
		get {
			let copy = self.set;
			return copy;
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
	
	public func reserveCapacity(_ minimumCapacity: Int) {
	
		set.reserveCapacity(minimumCapacity)
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: NSCopying
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public override func copy(with zone: NSZone? = nil) -> Any {
		
		let copy = super.copy(with: zone) as! ZDCSet<Element>
		
		copy.set = self.set
		copy.added = self.added
		copy.deleted = self.deleted
		
		return copy
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Reading
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public func contains(_ member: Element) -> Bool {
		return set.contains(member)
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Writing
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	@discardableResult
	public func insert(_ item: Element) -> Bool {
		
		if (self.isImmutable) {
			ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
		}
		
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
	public func remove(_ item: Element) -> Element? {
		
		if (self.isImmutable) {
			ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
		}
		
		if set.contains(item) {
			self._willRemove(item)
			return set.remove(item)
		}
		else {
			return nil
		}
	}
	
	public func removeAll(keepingCapacity keepCapacity: Bool = false) {
		
		if (self.isImmutable) {
			ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
		}
		
		for item in set {
			self._willRemove(item)
		}
		
		set.removeAll(keepingCapacity: keepCapacity)
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Subscripts
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public subscript(position: Set<Element>.Index) -> Set<Element>.Element {
		get {
			return set[position]
		}
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Enumeration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public var startIndex: Set<Element>.Index {
		return set.startIndex
	}
	
	public var endIndex: Set<Element>.Index {
		return set.endIndex
	}
	
	public func index(after i: Set<Element>.Index) -> Set<Element>.Index {
		return set.index(after: i)
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
//	static func == (lhs: ZDCSet<Element>, rhs: ZDCSet<Element>) -> Bool {
//
//		return (lhs.set == rhs.set)
//	}
	
	override public func isEqual(_ object: Any?) -> Bool {

		if let another = object as? ZDCSet<Element> {
			return isEqualToSet(another)
		}
		else {
			return false
		}
	}

	public func isEqualToSet(_ another: ZDCSet<Element>) -> Bool {

		return (set == another.set)
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Change Tracking Internals
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private func _willInsert(_ item: Element) {
		
		if deleted.contains(item) {
			
			// Deleted & then later re-added within same changeset.
			// The two actions cancel each other out.
			
			deleted.remove(item)
		}
		else {
			added.insert(item)
		}
	}
	
	private func _willRemove(_ item: Element) {
		
		if added.contains(item) {
			
			// Added & then later removed within same changeset.
			// The two actions cancel each other out.
			
			added.remove(item)
		}
		else {
			deleted.insert(item)
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: ZDCObject
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	override public func makeImmutable() {
		
		super.makeImmutable()
		
		for item in set {
			
			if let zdc_item = item as? ZDCObject {
				zdc_item.makeImmutable()
			}
		}
	}
	
	override public var hasChanges: Bool {
		get {
			if super.hasChanges {
				return true
			}
			
			if (added.count > 0) || (deleted.count > 0) {
				return true
			}
			
			for item in set {
				
				if let zdc_item = item as? ZDCObject {
					if zdc_item.hasChanges {
						return true
					}
				}
			}
			
			return false
		}
	}
	
	override public func clearChangeTracking() {
		
		super.clearChangeTracking()
		
		added.removeAll()
		deleted.removeAll()
		
		for item in set {
			
			if let zdc_item = item as? ZDCObject {
				zdc_item.clearChangeTracking()
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
	
	public func peakChangeset() -> Dictionary<String, Any>? {
		
		let changeset = self._changeset()
		return changeset
	}
	
	private func isMalformedChangeset(_ changeset: Dictionary<String, Any>) -> Bool {
		
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
	
	private func _undo(_ changeset: Dictionary<String, Any>) throws {
		
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
	
	public func undo(_ changeset: Dictionary<String, Any>) throws -> Dictionary<String, Any> {
		
		try self.performUndo(changeset)
		
		// Undo successful - generate redo changeset
		let reverseChangeset = self.changeset()
		return reverseChangeset ?? Dictionary<String, Any>()
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
	
	public func rollback() {
		
		if let changeset = self.changeset() {
			
			do {
				let _ = try self.undo(changeset)
			
			} catch {
				// Ignoring errors here.
				// There's nothing we can do at this point - we're in a bad state.
			}
		}
	}
	
	public func mergeChangesets(_ orderedChangesets: Array<Dictionary<String, Any>>) throws -> Dictionary<String, Any> {
		
		try self.importChangesets(orderedChangesets)
		
		let mergedChangeset = self.changeset()
		return mergedChangeset ?? Dictionary()
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
		
		guard let cloudVersion = inCloudVersion as? ZDCSet<Element> else {
			throw ZDCSyncableError.incorrectObjectClass
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
