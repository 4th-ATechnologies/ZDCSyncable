/**
 * ZDCSyncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

import Foundation

public class ZDCOrderedSet<Element: Hashable & Codable>: ZDCObject, ZDCSyncable, Codable, Collection {
	
	enum CodingKeys: String, CodingKey {
		case set = "set"
		case order = "order"
	}
	
	enum ChangesetKeys: String {
		case added = "added"
		case deleted = "deleted"
		case indexes = "indexes"
	}
	
	private var set: Set<Element>
	private var order: Array<Element>
	
	lazy private var added: Set<Element> = Set()
	lazy private var deletedIndexes: Dictionary<Element, Int> = Dictionary()
	lazy private var originalIndexes: Dictionary<Element, Int> = Dictionary()
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Init
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public required init() {
		set = Set()
		order = Array()
		super.init()
	}
	
	public init(minimumCapacity: Int) {
		set = Set(minimumCapacity: minimumCapacity)
		order = Array()
		super.init()
	}
	
	public init<S>(_ sequence: S, copyValues: Bool = false) where S : Sequence, Element == S.Element {
		set = Set(minimumCapacity: sequence.underestimatedCount)
		order = Array()
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
	
	/// Returns a copy of the underlying Set being wrapped.
	/// This is a read-only copy - changes to the returned copy will not be reflected in this instance.
	///
	public var rawSet: Set<Element> {
		get {
			let copy = self.set
			return copy
		}
	}
	
	/// Returns a copy of the underlying Array being wrapped.
	/// This is a read-only copy - changes to the returned copy will not be reflected in this instance.
	///
	public var rawOrder: Array<Element> {
		get {
			let copy = self.order
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
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: NSCopying
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public override func copy(with zone: NSZone? = nil) -> Any {
		
		let copy = super.copy(with: zone) as! ZDCOrderedSet<Element>
		
		copy.set = self.set
		copy.order = self.order
		copy.added = self.added
		copy.deletedIndexes = self.deletedIndexes
		
		return copy
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Reading
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public func contains(_ member: Element) -> Bool {
		return set.contains(member)
	}
	
	public func index(of member: Element) -> Int? {
		
		return order.firstIndex(of: member)
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
			self._willInsert(item, atIndex: set.count)
			
			set.insert(item)
			order.append(item)
			return true
		}
	}
	
	@discardableResult
	public func insert(_ item: Element, at index: Int) -> Bool {
		
		if (self.isImmutable) {
			ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
		}
		
		if set.contains(item) {
			return false
		}
		else {
			
			var idx: Int!
			if index <= set.count {
				idx = index
			}
			else {
				idx = set.count
			}
			
			self._willInsert(item, atIndex: idx)
			
			set.insert(item)
			order.insert(item, at: idx)
			return true
		}
	}
	
	public func move(fromIndex oldIndex: Int, toIndex newIndex: Int) {
		
		if self.isImmutable {
			ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
		}
		
		precondition(oldIndex < order.count, "Index out of range (oldIndex)")
		
		let oldIdx = oldIndex
		let newIdx = (newIndex >= order.count) ? order.count - 1 : newIndex
		//                                       ^^^^^^^^^^^^^^^
		//                                       because we remove the item FIRST, and THEN re-insert it
		
		if (oldIdx == newIdx) {
			return
		}
		
		let item = order[oldIdx]
		self._willMove(item, fromIndex: oldIdx, toIndex: newIdx)
		
		order.remove(at: oldIdx)
		order.insert(item, at: newIdx)
	}
	
	@discardableResult
	public func remove(_ item: Element) -> Element? {
		
		if (self.isImmutable) {
			ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
		}
		
		if !set.contains(item) { // set.contains() is O(1); order.firstIndex() is O(n);
			return nil
		}
		
		if let idx = order.firstIndex(of: item) {
		
			self._willRemove(item, atIndex: idx)
			
			let result = set.remove(item)
			order.remove(at: idx)
			return result
		}
		else {
			return nil // this shouldn't ever happen
		}
	}
	
	@discardableResult
	public func remove(at idx: Int) -> Element? {
		
		if (self.isImmutable) {
			ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
		}
		
		if idx >= order.count {
			return nil
		}
		else {
			let item = order[idx]
			self._willRemove(item, atIndex: idx)
			
			set.remove(item)
			order.remove(at: idx)
			
			return item
		}
	}
	
	public func removeAll() {
		
		if (self.isImmutable) {
			ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
		}
		
		while order.count > 0 {
			
			let item = order[0]
			
			self._willRemove(item, atIndex: 0)
			
			set.remove(item)
			order.remove(at: 0)
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Subscripts
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public subscript(index: Int) -> Element {
		get {
			return order[index]
		}
		set(item) {
			self.remove(at: index)
			self.insert(item, at: index)
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Enumeration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public var startIndex: Array<Element>.Index {
		return order.startIndex
	}
	
	public var endIndex: Array<Element>.Index {
		return order.endIndex
	}
	
	public func index(after i: Array<Element>.Index) -> Array<Element>.Index {
		return order.index(after: i)
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
//	static func == (lhs: ZDCOrderedSet<Element>, rhs: ZDCOrderedSet<Element>) -> Bool {
//
//		return (lhs.set == rhs.set) && (lhs.order == rhs.order)
//	}
	
	override public func isEqual(_ object: Any?) -> Bool {

		if let another = object as? ZDCOrderedSet<Element> {
			return isEqualToOrderedSet(another)
		}
		else {
			return false
		}
	}

	public func isEqualToOrderedSet(_ another: ZDCOrderedSet<Element>) -> Bool {

		// Nope, this doesn't work:
	//	return (self == another)
		//           ^^ FAIL
		// This actually calls isEqual() again, leading to an infinite loop :(
		
		return (self.order == another.order)
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Change Tracking Internals
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private func _willInsert(_ item: Element, atIndex idx: Int) {
		
		precondition(idx <= set.count)
		
		// INSERT: Step 1 of 2:
		//
		// Update added as needed.
		
		added.insert(item)
		
		// INSERT: Step 2 of 2:
		//
		// If we're re-adding an item that was deleted within this changeset,
		// then we need to remove it from the deleted list.
		
		deletedIndexes.removeValue(forKey: item)
	}
	
	private func _willRemove(_ item: Element, atIndex idx: Int) {
		
		precondition(idx < set.count)
		
		// REMOVE: 1 of 3
		//
		// Update `added` as needed.
		// And check to see if we're deleting a item that was added within changeset.
	
		var wasAddedThenDeleted = false
	
		if added.contains(item) {
			
			// Item was added within snapshot, and is now being removed
			wasAddedThenDeleted = true
			added.remove(item)
		}
		
		// If we're deleting an item that was also added within this changeset,
		// then the two actions cancel each other out.
		//
		// Otherwise, this is a legitamate delete, and we need to record it.
	
		if !wasAddedThenDeleted {
			
			// REMOVE: Step 2 of 3:
			//
			// Add the item to `removedIndexes`.
			// And to do so, we need to know the correct originalIndex.
			//
			// Remember that our goal is to create a changeset that can be used to undo this change.
			// So it's important to understand the order in which the undo operation operates:
			//
			//                       direction    <=       this      <=     in      <=      read
			// [previous state] <= (undo deletes) <= (reverse moves) <= (undo adds) <= [current state]
			//
			// We can see that undoing delete operations is the last step.
			// So we need to take this into account by taking into consideration moves, adds & previous deletes.
			
			var originalIdx = idx
			var originalIdx_addMoveOnly = idx
			
			// Check items that were moved/added within this changeset
			
			if let oIdx = originalIndexes[item] {
				
				// Shortcut - we've already tracked & calculated the originalIndex.
				//
				// Actually, this is more than just a shortcut.
				// Since the item being deleted is already in originalIndexes,
				// this would throw off our calculations below.
				
				originalIdx = oIdx
			}
			else {
				
				var originalOrder = Array<Element>()
				for item in order {
					
					if (originalIndexes[item] == nil) && !added.contains(item) {
						
						originalOrder.append(item)
					}
				}

				let sortedOriginalIndexes = originalIndexes.sorted(by: {
					$0.value < $1.value
				})
				
				for (key, prvIdx) in sortedOriginalIndexes {
					
					originalOrder.insert(key, at: prvIdx)
				}
				
				if let oIdx = originalOrder.firstIndex(of: item) {
					originalIdx = oIdx
				}
				else {
					assert(false, "")
				}
			}
			
			originalIdx_addMoveOnly = originalIdx

			do { // Check items that were deleted within this changeset

				let sortedDeletedIndexes = deletedIndexes.sorted(by: {
					$0.value < $1.value
				})
				
				for (_, deletedIdx) in sortedDeletedIndexes {
					
					if deletedIdx <= originalIdx {
						
						// An item was deleted in front of us within this changeset. (front=lower_index)
						originalIdx += 1
					}
				}
			}
			
		#if DEBUG
			self.checkDeletedIndexes(originalIdx)
		#endif
			deletedIndexes[item] = originalIdx

			// REMOVE: Step 3 of 3:
			//
			// Remove deleted item from originalIndexes.
			//
			// And recall that we undo deletes AFTER we undo moves.
			// So we need to fixup the originalIndexes so everything works as expected.

			originalIndexes[item] = nil

			for altKey in originalIndexes.keys {
				
				let altIdx = originalIndexes[altKey]!
				if altIdx >= originalIdx_addMoveOnly {
					originalIndexes[altKey] = (altIdx - 1)
				}
			}

		#if DEBUG
			self.checkOriginalIndexes()
		#endif
		}
	}
	
	private func _willMove(_ item: Element, fromIndex oldIdx: Int, toIndex newIdx: Int)	{
		
		precondition(oldIdx < set.count)
		precondition(newIdx <= set.count)
		precondition(oldIdx != newIdx)
		
		// MOVE: Step 1 of 1:
		//
		// We need to add the item to originalIndexes (if it's not already listed).
		// And to do so, we need to know the correct originalIndex.
		//
		// However, we cannot simply use oldIdx.
		// Previous moves within the changeset may have scewed the oldIdx such that's it's no longer accurate.
		//
		// Also, remember that we don't have to concern ourselves with deletes.
		// This is because of the order in which the undo operation operates:
		//
		//                       direction    <=       this      <=     in      <=       read
		// [previous state] <= (undo deletes) <= (reverse moves) <= (undo adds) <= [current state]
		//
		// We will undo moves before we undo deletes.
		
		if (originalIndexes[item] == nil) && !added.contains(item) {
			
			var originalIdx = oldIdx
			
			var originalOrder: Array<Element> = Array()
			for item in order {
				
				if (originalIndexes[item] == nil) && !added.contains(item) {
					
					originalOrder.append(item)
				}
			}
			
			let sorted = originalIndexes.sorted(by: {
				$0.value < $1.value
			})
			
			for (item, prvIdx) in sorted {
				
				originalOrder.insert(item, at: prvIdx)
			}
			
			if let oIdx = originalOrder.firstIndex(of: item) {
				originalIdx = oIdx
			}
			
		#if DEBUG
			self.checkOriginalIndexes(originalIdx)
		#endif
			originalIndexes[item] = originalIdx
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Sanity Checks
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#if DEBUG
	
	private func checkOriginalIndexes() {
		
		var existing = IndexSet()
		
		for (_, originalIdx) in originalIndexes {
			
			assert(originalIdx != NSNotFound, "Calculated originalIdx is wrong (within originalIndexes)")
			
			if existing.contains(originalIdx) {
				assert(false, "Modified originalIndexes is wrong (within originalIndexes)");
			}
			
			existing.insert(originalIdx)
		}
	}
	
	private func checkOriginalIndexes(_ originalIdx: Int) {
		
		assert(originalIdx != NSNotFound, "Calculated originalIdx is wrong (for originalIndexes)");
	
		for (_, existingIdx) in originalIndexes {
			
			if existingIdx == originalIdx {
				assert(false, "Calculated originalIdx is wrong (for originalIndexes)")
			}
		}
	}
	
	private func checkDeletedIndexes(_ originalIdx: Int) {
		
		assert(originalIdx != NSNotFound, "Calculated originalIdx is wrong (for deletedIndexes)")
		
		for (_, existingIdx) in deletedIndexes {
			
			if existingIdx == originalIdx {
				assert(false, "Calculated originalIdx is wrong (for deletedIndexes)");
			}
		}
	}
	
#endif
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
			
			if (added.count > 0) || (deletedIndexes.count > 0) || (originalIndexes.count > 0) {
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
		deletedIndexes.removeAll()
		originalIndexes.removeAll()
		
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
		
		var changeset: Dictionary<String, Any> = Dictionary()
		
		if (added.count > 0)
		{
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
		
		if (originalIndexes.count > 0)
		{
			// changeset: {
			//   indexes: {
			//     obj: oldIndex, ...
			//   },
			//   ...
			// }
			
			var changeset_indexes: Dictionary<Element, Int> = Dictionary()
			
			for (item, oldIdx) in originalIndexes {
				
				if self.contains(item) {
					changeset_indexes[item] = oldIdx
				}
			}
			
			if (changeset_indexes.count > 0) {
				changeset[ChangesetKeys.indexes.rawValue] = changeset_indexes
			}
		}
		
		if (deletedIndexes.count > 0)
		{
			// changeset: {
			//   deleted: {
			//     obj: oldIndex, ...
			//   },
			//   ...
			// }
			//
			// Note: The object is being used as the key in a dictionary.
			
			changeset[ChangesetKeys.deleted.rawValue] = deletedIndexes
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
		
		do { // scoping: added
			
			if let changeset_added = changeset[ChangesetKeys.added.rawValue] {
				
				if let _ = changeset_added as? Set<Element> {
					// ok
				} else {
					return true // malformed !
				}
			}
		}
		
		do { // scoping: indexes
				
			if let changeset_indexes = changeset[ChangesetKeys.indexes.rawValue] {
				
				if let _ = changeset_indexes as? Dictionary<Element, Int> {
					// ok
				} else {
					return true // malformed !
				}
			}
		}
		
		do { // scoping: deleted
			
			if let changeset_deleted = changeset[ChangesetKeys.deleted.rawValue] {
				
				if let _ = changeset_deleted as? Dictionary<Element, Int> {
					// ok
				} else {
					return true // malformed !
				}
			}
		}
		
		// Looks good (not malformed)
		return false
	}
	
	private func _undo(_ changeset: Dictionary<String, Any>) throws {
		
		// Important: `isMalformedChangeset:` must be called before invoking this method.
		
		// This method is called from both `undo()` & `importChangesets()`.
		//
		// When called from `undo()`, there aren't any existing changes,
		// and we can simplify (+optimize) some of our code.
		//
		// However that's sometimes not the case when called from `importChangesets()`.
		// So we have to guard for that situation.
		
		let isSimpleUndo = !self.hasChanges
		
		// Change tracking algorithm:
		//
		// We have 3 sources of information to apply:
		//
		// - Added items
		//
		//     Each item that was added will be represented in the respective set.
		//
		// - Moved items
		//
		//     For each item that was moved, we have the 'obj' and 'oldIndex'.
		//
		// - Deleted items
		//
		//     For each item that was deleted, we have the 'obj' and 'oldIndex'.
		//
		//
		// In order for the algorithm to work, the 3 sources of information MUST be
		// applied 1-at-a-time, and in a specific order. Moving backwards,
		// from [current state] to [previous state] the order is:
		//
		//                       direction    <=       this      <=     in      <=      read
		// [previous state] <= (undo deletes) <= (reverse moves) <= (undo adds) <= [current state]
		
		// Step 1 of 3:
		//
		// Undo added objects & restore previous values.
		
		if let changeset_added = changeset[ChangesetKeys.added.rawValue] as? Set<Element> {
			
			for item in changeset_added {
				
				if self.contains(item) {
					self.remove(item)
				}
			}
		}
		
		// Step 2 of 3:
		//
		// Undo move operations
		
		if let changeset_moves = changeset[ChangesetKeys.indexes.rawValue] as? Dictionary<Element, Int> {
			
			// We have a list of objects, and their originalIndexes.
			// So for each object, we need to:
			// - remove it from it's currentIndex
			// - add it back in it's originalIndex
			//
			// And we need to keep track of the changeset (originalIndexes) as we're doing this.
			
			var moved_items = Array<Element>()
			var moved_indexes = IndexSet()
			
			for (item, _) in changeset_moves {
				
				if let idx = self.index(of: item) {
					
					if (isSimpleUndo)
					{
					#if DEBUG
						self.checkOriginalIndexes(idx)
					#endif
						originalIndexes[item] = idx
					}

					moved_items.append(item)
					moved_indexes.insert(idx)
				}
			}
			
			if (!isSimpleUndo)
			{
				var originalOrder: Array<Element> = Array()
				for item in order {
					
					if (originalIndexes[item] == nil) && !added.contains(item) {
						
						originalOrder.append(item)
					}
				}
				
				let sorted = originalIndexes.sorted(by: {
					$0.value < $1.value
				})
				
				for (item, prvIdx) in sorted {
					
					originalOrder.insert(item, at: prvIdx)
				}
				
				for moved_item in moved_items {
					
					if (originalIndexes[moved_item] == nil)
					{
						if let originalIdx = originalOrder.firstIndex(of: moved_item) {
							
						#if DEBUG
							self.checkOriginalIndexes(originalIdx)
						#endif
							originalIndexes[moved_item] = originalIdx
						}
						else {
							
							// Might be the case during an `importChanges::` operation,
							// where an item was added in changeset_A, and moved in changeset_B.
						}
					}
				}
			}

			for movedIdx in moved_indexes.reversed() {
				
				order.remove(at: movedIdx)
			}

			// Sort keys by targetIdx (originalIdx).
			// We want to add them from lowest idx to highest idx.
			moved_items.sort(by: {
				
				let idx1 = changeset_moves[$0]!
				let idx2 = changeset_moves[$1]!
				
				return idx1 < idx2
			})

			for moved_item in moved_items {
				
				let idx = changeset_moves[moved_item]!
				if (idx > order.count) {
					throw ZDCSyncableError.mismatchedChangeset
				}
				
				order.insert(moved_item, at: idx)
			}
		}

		// Step 3 of 3:
		//
		// Undo deleted objects.
		
		if let changeset_deleted = changeset[ChangesetKeys.deleted.rawValue] as? Dictionary<Element, Int> {
			
			let sorted = changeset_deleted.sorted(by: {
				
				return $0.value < $1.value
			})
			
			for (item, idx) in sorted {
				
				if (idx > self.count) {
					throw ZDCSyncableError.mismatchedChangeset
				}
				self.insert(item, at: idx)
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
	
	/// Calculates the original order from the changesets.
	///
	private static func originalOrder(from inOrder: Array<Element>, pendingChangesets: Array<Dictionary<String, Any>>)
		-> Array<Element>?
	{
		// Important: `isMalformedChangeset:` must be called before invoking this method.
		
		var order = inOrder
		
		for changeset in pendingChangesets.reversed() {
			
			// IMPORTANT:
			//
			// All of this code comes from the `_undo()` function.
			// It's been changed to modify only the `order` ivar.
			//
			// For documentation & discussion of this code & logic,
			// please see the `_undo()` function.
			
			// Step 1 of 3:
			//
			// Undo added objects.
			
			if let changeset_added = changeset[ChangesetKeys.added.rawValue] as? Set<Element> {
			
				for item in changeset_added {
					
					if let idx = order.firstIndex(of: item) {
						order.remove(at: idx)
					}
				}
			}
			
			// Step 2 of 3:
			//
			// Undo move operations
			
			if let changeset_moves = changeset[ChangesetKeys.indexes.rawValue] as? Dictionary<Element, Int> {
			
				// We have a list of objects, and their originalIndexes.
				// So for each object, we need to:
				// - remove it from it's currentIndex
				// - add it back in it's originalIndex
				
				var moved_items: Array<Element> = Array()
				var moved_indexes = IndexSet()
				
				for (item, _) in changeset_moves {
					
					if let idx = order.firstIndex(of: item) {
						
						moved_items.append(item)
						moved_indexes.insert(idx)
					}
				}
				
				for movedIdx in moved_indexes.reversed() {
					
					order.remove(at: movedIdx)
				}
				
				// Sort keys by targetIdx (originalIdx).
				// We want to add them from lowest idx to highest idx.
				moved_items.sort(by: {
					
					let idx1 = changeset_moves[$0]!
					let idx2 = changeset_moves[$1]!
					
					return idx1 < idx2
				})
				
				for moved_item in moved_items {
					
					let idx = changeset_moves[moved_item]!
					if (idx > order.count) {
						return nil
					}
					
					order.insert(moved_item, at: idx)
				}
			}
			
			// Step 3 of 3:
			//
			// Undo deleted objects.
			
			if let changeset_deleted = changeset[ChangesetKeys.deleted.rawValue] as? Dictionary<Element, Int> {
				
				let sorted = changeset_deleted.sorted(by: {
					
					return $0.value < $1.value
				})
				
				for (item, idx) in sorted {
					
					if (idx > order.count) {
						return nil
					}
					order.insert(item, at: idx)
				}
			}
		}
		
		return order
	}
	
	public func merge(cloudVersion inCloudVersion: ZDCSyncable,
	                  pendingChangesets: Array<Dictionary<String, Any>>)
		throws -> Dictionary<String, Any>
	{
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
		
		guard let cloudVersion = inCloudVersion as? ZDCOrderedSet<Element> else {
			throw ZDCSyncableError.incorrectObjectClass
		}
		
		// Step 1 of 7:
		//
		// If there are pending changes, calculate the original order.
		// This will be used later on during the merge process.
		//
		// Important:
		//   We need to do this in the beginning, because we need an unmodified `orderedSet`.
		
		var originalOrder: Array<Element>? = nil
		if pendingChangesets.count > 0 {
			
			originalOrder = type(of: self).originalOrder(from: order, pendingChangesets: pendingChangesets)
			if (originalOrder == nil) {
				
				throw ZDCSyncableError.mismatchedChangeset
			}
		}
		
		// Step 2 of 7:
		//
		// Determine which objects have been added & deleted (locally, based on pendingChangesets)
		
		var local_added = Set<Element>()
		var local_deleted = Set<Element>()
		
		for changeset in pendingChangesets {
			
			if let changeset_added = changeset[ChangesetKeys.added.rawValue] as? Set<Element> {
				
				for item in changeset_added {
					
					if local_deleted.contains(item) {
						local_deleted.remove(item)
					} else {
						local_added.insert(item)
					}
				}
			}
			if let changeset_deleted = changeset[ChangesetKeys.deleted.rawValue] as? Dictionary<Element, Int> {
				
				for (item, _) in changeset_deleted {
					
					if local_added.contains(item) {
						local_added.remove(item)
					} else {
						local_deleted.insert(item)
					}
				}
			}
		}
		
		// Step 3 of 7:
		//
		// Add objects that were added by remote devices.
		
		for item in cloudVersion.order {
			
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
		
		// Step 4 of 7:
		//
		// Delete objects that were deleted by remote devices.
		
		var deleteMe = Array<Element>()
		
		for item in self.order { // enumerating self.order => cannot be modified during enumeration
			
			if !cloudVersion.contains(item) {
				
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
		
		// Step 5 of 7:
		//
		// Prepare to merge the order.
		//
		// At this point, we've added every obj that was in the cloudVersion, but not in our localVersion.
		// And we've deleted every obj that was deleted from the cloudVersion.
		//
		// Another change we need to take into consideration are obj's that we've deleted locally.
		//
		// Our aim here is to derive 2 arrays, one from cloudVersion->order, and another from self->order.
		// Both of these arrays will have the same count, and contain the same objs,
		// but possibly in a different order.
		
		var order_localVersion: Array<Element>!
		var order_cloudVersion: Array<Element>!
		
		do {
			
			var merged = Set<Element>(self.order)
			merged.formIntersection(cloudVersion.order)
			
			order_localVersion = self.order.filter({
				return merged.contains($0)
			})
			
			order_cloudVersion = cloudVersion.order.filter({
				return merged.contains($0)
			})
			
			assert(order_localVersion.count == order_cloudVersion.count)
		}
		
		// Step 6 of 7:
		//
		// So now we have a 2 lists of items that we can compare: local vs cloud.
		// But when we detect a difference between the lists, what does that tell us ?
		//
		// It could mean:
		// - the location was changed remotely
		// - the location was changed locally
		// - or both (in which case remote wins)
		//
		// So we're going to need to make an "educated guess" as to which items
		// might have been moved by a remote device.
		
		var movedItems_remote = Set<Element>()
		
		if pendingChangesets.count == 0 {
			
			movedItems_remote.formUnion(cloudVersion.set)
		}
		else {
			
			var merged = Set<Element>(originalOrder!)
			merged.formIntersection(cloudVersion.order)
			
			let order_originalVersion = originalOrder!.filter({
				return merged.contains($0)
			})
			
			let order_cloudVersion = cloudVersion.order.filter({
				return merged.contains($0)
			})
			
			assert(order_originalVersion.count == order_cloudVersion.count)
			
			do {
				// Make educated guest as to what items may have been moved:
				let estimate = try ZDCOrder.estimateChangeset(from: order_originalVersion, to: order_cloudVersion)
				
				movedItems_remote.formUnion(estimate)
			}
			catch {
				movedItems_remote.formUnion(cloudVersion.set)
			}
		}
		
		// Step 7 of 7:
		//
		// We have all the information we need to merge the order now.
		
		assert(order_localVersion.count == order_cloudVersion.count)
		
		for i in 0 ..< order_cloudVersion.count {
			
			let item_remote = order_cloudVersion[i]
			let item_local  = order_localVersion[i]
			
			if item_remote != item_local {
				
				let changed_remote: Bool = movedItems_remote.contains(item_remote)
				if changed_remote {
					
					// Remote wins.
					
					let item = item_remote
					
					// Move key into proper position (within order_localVersion)
					do {
					
						var idx: Int? = nil
						for s in stride(from: i+1, to: order_localVersion.count, by: 1) {
							
							if order_localVersion[s] == item {
								idx = s
								break
							}
						}
						
						if let idx = idx {
							
							order_localVersion.remove(at: idx)
							order_localVersion.insert(item, at: i)
						}
					}
					
					// Move key into proper position (within self)
					//
					// Note:
					//   We already added all the objects that were added by remote devices.
					//   And we already deleted all the objects that were deleted by remote devices.
					
					if let oldIdx = self.order.firstIndex(of: item) {
							
						var newIdx = 0
						if i > 0 {
							
							let prvItem = order_localVersion[i-1]
							if let prvIdx = self.order.firstIndex(of: prvItem) {
								newIdx = prvIdx + 1
							}
						}
						
						self.move(fromIndex: oldIdx, toIndex: newIdx)
					}
					
				}
				else {
					
					// Local wins.
					
					let item = item_local
					
					// Move remote into proper position (with changed_remote)
					
					var idx: Int? = nil
					for s in stride(from: i+1, to: order_cloudVersion.count, by: 1) {
						
						if order_cloudVersion[s] == item {
							idx = s
							break
						}
					}
					
					if let idx = idx {
						
						order_cloudVersion.remove(at: idx)
						order_cloudVersion.insert(item, at: i)
					}
				}
			}
		}
		
		return self.changeset() ?? Dictionary()
	}
}
