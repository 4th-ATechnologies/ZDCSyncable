/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for plain objects in Swift.

import Foundation

public struct ZDCArray<Element: Codable & Equatable> : ZDCSyncableCollection, Codable, Collection, Equatable {
	
	enum CodingKeys: String, CodingKey {
		case array = "array"
	}
	
	enum ChangesetKeys: String {
		case added = "added"
		case moved = "moved"
		case deleted = "deleted"
	}
	
	private var array: Array<Element>
	
	private var added: IndexSet = IndexSet()                     // [{ currentIndex }]
	private var moved: Dictionary<Int, Int> = Dictionary()       // key={currentIndex}, value={previousIndex}
	private var deleted: Dictionary<Int, Element> = Dictionary() // key={previousIndex}, value={object}
	
	// ====================================================================================================
	// MARK: Init
	// ====================================================================================================
	
	public init() {
		
		array = Array()
	}
	
	public init<S>(_ sequence: S) where S : Sequence, Element == S.Element {
		
		array = Array()
		
		array.reserveCapacity(sequence.underestimatedCount)
		for item in sequence {
			
		//	self.append(item) // not tracking changes during init
			array.append(item)
		}
	}
	
	public init(copy source: ZDCArray<Element>, retainChangeTracking: Bool) {
		
		self.array = source.array
		
		if retainChangeTracking {
			self.added = source.added
			self.moved = source.moved
			self.deleted = source.deleted
		}
	}
	
	// ====================================================================================================
	// MARK: Properties
	// ====================================================================================================
	
	/// Returns a reference to the underlying Array being wrapped.
	/// This is a read-only copy - changes to the returned array will not be reflected in the ZDCArray instance.
	///
	public var rawArray: Array<Element> {
		get {
			let copy = self.array;
			return copy;
		}
	}
	
	public var isEmpty: Bool {
		get {
			return array.isEmpty
		}
	}
	
	public var count: Int {
		get {
			return array.count
		}
	}
	
	public var capacity: Int {
		get {
			return array.capacity
		}
	}
	
	public mutating func reserveCapacity(_ minimumCapacity: Int) {
		
		array.reserveCapacity(minimumCapacity)
	}
	
	// ====================================================================================================
	// MARK: Reading
	// ====================================================================================================
	
	public var first: Element? {
		get {
			return array.first
		}
	}
	
	public var last: Element? {
		get {
			return array.last
		}
	}
	
	public func firstIndex(of element: Element) -> Int? {
		return array.firstIndex(of: element)
	}
	
	public func contains(_ member: Element) -> Bool {
		return array.contains(member)
	}
	
	// ====================================================================================================
	// MARK: Writing
	// ====================================================================================================

	public mutating func append(_ item: Element) {
		
		self._willInsert(at: array.count)
		array.append(item)
	}
	
	public mutating func insert(_ item: Element, at index: Int) {
		
		let idx = (index > array.count) ? array.count : index
		
		self._willInsert(at: idx)
		array.insert(item, at: idx)
	}
	
	public mutating func move(fromIndex oldIndex: Int, toIndex newIndex: Int) {
		
		precondition(oldIndex < array.count, "Index out of range (oldIndex)")
		
		let oldIdx = oldIndex
		let newIdx = (newIndex >= array.count) ? array.count - 1 : newIndex
		//                                       ^^^^^^^^^^^^^^^
		//                                       because we remove the item FIRST, and THEN re-insert it
		
		if (oldIdx == newIdx) {
			return
		}
		
		let item = array[oldIdx]
		self._willMove(fromIndex: oldIdx, toIndex: newIdx)
		
		array.remove(at: oldIdx)
		array.insert(item, at: newIdx)
	}
	
	public mutating func remove(_ item: Element) {
		
		self.removeAll(where: {
			$0 == item
		})
	}
	
	public mutating func remove(at index: Int) {
		
		if index >= array.count {
			return
		}
		
		self._willRemove(at: index)
		array.remove(at: index)
	}
	
	public mutating func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows {
		
		var indexSet = IndexSet()
		var idx = 0
		for item in array {
			if try shouldBeRemoved(item) {
				indexSet.insert(idx)
			}
			idx += 1
		}
		
		for idx in indexSet.reversed() {
			
			self._willRemove(at: idx)
			array.remove(at: idx)
		}
	}
	
	public mutating func removeAll() {
		
		while array.count > 0 {
			
			self._willRemove(at: 0)
			array.remove(at: 0)
		}
	}
	
	// ====================================================================================================
	// MARK: Subscripts
	// ====================================================================================================
	
	public subscript(index: Int) -> Element {
		get {
			return array[index]
		}
		set(item) {
			self.remove(at: index)
			self.insert(item, at: index)
		}
	}
	
	// ====================================================================================================
	// MARK: Enumeration
	// ====================================================================================================
	
	public var startIndex: Array<Element>.Index {
		return array.startIndex
	}
	
	public var endIndex: Array<Element>.Index {
		return array.endIndex
	}
	
	public func index(after i: Array<Element>.Index) -> Array<Element>.Index {
		return array.index(after: i)
	}
	
	// ====================================================================================================
	// MARK: Equality
	// ====================================================================================================
	
	// Compares only the underlying rawSet for equality.
	// The changeset information isn't part of the comparison.
	//
	public static func == (lhs: ZDCArray<Element>, rhs: ZDCArray<Element>) -> Bool {
		
		return (lhs.array == rhs.array)
	}
	
	// ====================================================================================================
	// MARK: Change Tracking Internals
	// ====================================================================================================
	
	private mutating func _willInsert(at insertionIdx: Int) {
		
		precondition(insertionIdx <= array.count)
		
		// ADD: Step 1 of 2
		//
		// Update the 'added' indexSet.
		
		self.shiftAddedIndexes(startingAt: insertionIdx, by:1)
		
		assert(!added.contains(insertionIdx))
		added.insert(insertionIdx)
		
		// ADD: Step 2 of 2
		//
		// The currentIndex of some items may be increasing.
		// So we need to update the 'moved' dictionary accordingly.
		
		self.incrementMovedCurrentIndexes(startingAt: insertionIdx)
	}
	
	private mutating func _willRemove(at deletionIdx: Int) {
		
		precondition(deletionIdx < array.count)
		
		// REMOVE: Step 1 of 4:
		//
		// Determine if this will be counted as a deletion, or a simply undoing a previous add/insert.
		
		let wasAddedThenDeleted = added.contains(deletionIdx)
		
		if wasAddedThenDeleted {
			
			// The currentIndex of some items may be decreasing
			
			self.decrementMovedCurrentIndexes(startingAt: deletionIdx)
			
		#if DEBUG
			self.checkMoved()
		#endif

		}
		else // if (!wasAddedThenDeleted)
		{
			// REMOVE: Step 2 of 4:
			//
			// Add the item to `deleted`.
			// And to do so, we need to know the correct originalIndex (which may not be deletionIndex).
			//
			// Remember that our goal is to create a changeset that can be used to undo this change.
			// So it's important to understand the order in which the undo operation operates:
			//
			//                       direction    <=       this      <=     in      <=      read
			// [previous state] <= (undo deletes) <= (reverse moves) <= (undo adds) <= [current state]
			//
			// We can see that undoing delete operations is the last step.
			// So we need to take this into account by taking into consideration moves, adds & previous deletes.
		
			let deletedItem = array[deletionIdx];
			
			var originalIdx = deletionIdx
			var originalIdx_addMoveOnly = deletionIdx
		
			do { // scoping
				
				var originalArray: Array<Element> = Array()
				originalArray.reserveCapacity(array.count)
				
				for idx in 0 ..< array.count {
					
					if !added.contains(idx) && (moved[idx] == nil) {
						
						originalArray.append(array[idx])
					}
				}
				
				let moved_sortedByPreviousIdx = moved.sorted(by: {
					$0.value < $1.value
				})
				
				for (currentIdx, _) in moved_sortedByPreviousIdx {
					
					let item = array[currentIdx]
					let previousIdx = moved[currentIdx]!
					
					originalArray.insert(item, at: previousIdx)
				}
				
				if let oidx = originalArray.firstIndex(of: deletedItem) {
					originalIdx_addMoveOnly = oidx
				} else {
					assert(false)
				}
			
				let deleted_sortedKeys = deleted.keys.sorted { (num1: Int, num2: Int) -> Bool in
					
					return num1 < num2
				}
				
				for previousIdx in deleted_sortedKeys {
					
					let item = deleted[previousIdx]!
					
					originalArray.insert(item, at: previousIdx)
				}
				
				if let oidx = originalArray.firstIndex(of: deletedItem) {
					originalIdx = oidx
				} else {
					assert(false)
				}
			}
			
		#if DEBUG
			self.checkDeleted(originalIdx)
		#endif
			deleted[originalIdx] = deletedItem
		
			// REMOVE: Step 3 of 4:
			//
			// Remove deleted item from 'moved'.
			//
			// Recall that we undo deletes AFTER we undo moves.
			// So we need to fixup the 'moved' dictionary so everything works as expected.
			do {
			
				moved[deletionIdx] = nil
				
				let moved_sorted = moved.sorted(by: {
					$0.key < $1.key
				})
				
				for (currentIdx, previousIdx) in moved_sorted {
					
					if (currentIdx > deletionIdx) || (previousIdx > originalIdx_addMoveOnly)
					{
						moved[currentIdx] = nil
						
						let _currentIdx = (currentIdx > deletionIdx)
							? currentIdx - 1
							: currentIdx
						
						let _previousIdx = (previousIdx > originalIdx_addMoveOnly)
							? previousIdx - 1
							: previousIdx
						
						moved[_currentIdx] = _previousIdx
					}
				}
			
			#if DEBUG
				self.checkMoved()
			#endif
			}
		}
		
		// REMOVE: Step 4 of 4
		//
		// Update the 'added' set.
		//
		// Recall that 'added' is just an IndexSet which is supposed to point
		// to the items that were added within this changeset.
		// The removal of this item may have changed the indexes of some items,
		// so we need to update the indexes that were affected.
	
		added.remove(deletionIdx)
		self.shiftAddedIndexes(startingAt: deletionIdx, by: -1)
	}
	
	private mutating func _willMove(fromIndex oldIdx: Int, toIndex newIdx: Int) {
		
		precondition(oldIdx < array.count)
		precondition(newIdx <= array.count)
		precondition(oldIdx != newIdx)
		
		// Note: we don't have to concern ourselves with deletes here.
		// This is because of the order in which the undo operation operates:
		//
		//                       direction    <=       this      <=     in      <=       read
		// [previous state] <= (undo deletes) <= (reverse moves) <= (undo adds) <= [current state]
		//
		// We will undo moves before we undo deletes.
		
		// MOVE: Step 1 of 6
		//
		// Are we moving an item that was added within this changeset ?
		// If so, then the change is consolidated into the add/insert action.
		
		let wasAdded = added.contains(oldIdx)
		var originalIdx = 0
		
		if !wasAdded {
			
			// MOVE: Step 2 of 6:
			//
			// Calculate the originalIndex of the object within the array (at the beginning of the changeset).
			//
			// Remember, we cannot simply use oldIdx.
			// Previous moves/inserts within the changeset may have skewed the oldIdx such that it's no longer accurate.
			
			if let oidx = moved[oldIdx] {
				
				originalIdx = oidx
			}
			else {
				
				var originalArray: Array<Element> = Array()
				originalArray.reserveCapacity(array.count)
				
				for idx in 0 ..< array.count {
					
					if !added.contains(idx) && (moved[idx] == nil) {
						
						originalArray.append(array[idx])
					}
				}
				
				let moved_sortedByPreviousIdx = moved.sorted(by: {
					$0.value < $1.value
				})
				
				for (currentIdx, _) in moved_sortedByPreviousIdx {
					
					let item = array[currentIdx]
					let previousIdx = moved[currentIdx]!
					
					originalArray.insert(item, at: previousIdx)
				}
				
				let targetItem = array[oldIdx];
				
				if let oidx = originalArray.firstIndex(of: targetItem) {
					originalIdx = oidx
				} else {
					assert(false)
				}
			}
			
			// MOVE: Step 3 of 6
			//
			// If the item has been moved before (within the context of this changeset),
			// then remove the old entry. It will be replaced with a new entry momentarily.
			
			moved[oldIdx] = nil
		}
		
		// MOVE: Step 4 of 6
		//
		// The items within the 'moved' array map from `current_index` to `previous_index`.
		// But we're about to move items around, which could change the current_index of many items.
		// So we need to update the 'moved' dictionary.
		//
		// In particular, we need to change the keys (which represent the `current_index`),
		// for any items whose current_index will be changed due to the move.
		
		if oldIdx < newIdx {
			
			// The currentIndex of some items may be decreasing
			
			let sorted = moved.sorted(by: {
				
				$0.key < $1.key // sort in ascending order
			})
			
			for (idx, previousIdx) in sorted {
				
				if (idx > oldIdx) && (idx <= newIdx) {
					
					moved[idx] = nil
					moved[idx-1] = previousIdx
				}
			}
		}
		else if oldIdx > newIdx {
			
			// The currentIndex of some items may be increasing
			
			let sorted = moved.sorted(by: {
				
				$1.key < $0.key // sort in descending order
			})
			
			for (idx, previousIdx) in sorted {
				
				if (idx < oldIdx) && (idx >= newIdx) {
					
					moved[idx] = nil
					moved[idx+1] = previousIdx
				}
			}
		}
		
		if !wasAdded {
			
			// MOVE: Step 5 of 6
			//
			// Insert the entry that reflects this move action.
			
			moved[newIdx] = originalIdx
		#if DEBUG
			self.checkMoved()
		#endif
		}

		// MOVE: Step 6 of 6
		//
		// Update the 'added' set.
		//
		// Recall that 'added' is just a NSMutableIndexSet which is supposed to point
		// to the items that were added within this changeset.
		// The removal of this item may have changed the indexes of some items,
		// so we need to update the indexes that were affected.

		if wasAdded {
			
			added.remove(oldIdx)
			self.shiftAddedIndexes(startingAt: oldIdx, by: -1)
			
			self.shiftAddedIndexes(startingAt: newIdx, by: 1)
			added.insert(newIdx)
		}
		else {
			
			self.shiftAddedIndexes(startingAt: oldIdx, by: -1)
			self.shiftAddedIndexes(startingAt: newIdx, by: 1)
		}
	}

	// ====================================================================================================
	// MARK: Sanity Checks
	// ====================================================================================================
	#if DEBUG

	private func checkDeleted(_ originalIdx: Int) {
		
		assert(originalIdx != NSNotFound, "Calculated originalIdx is invalid (for 'deleted')")
		
		assert(deleted[originalIdx] == nil, "Calculated originalIdx is wrong (for 'deleted')")
	}
	
	private func checkMoved() {
		
		// The 'moved' dictionary:
		// - key   : currentIndex
		// - value : previousIndex
		//
		// If everything is accurate, then a given 'previousIndex' value should
		// only be represented ONCE in the dictionary.
		
		var existing = IndexSet()
		
		for (_, idx) in moved {
			
			if existing.contains(idx) {
				assert(false, "Calculated previousIdx is wrong (for 'moved')")
			}
			
			existing.insert(idx)
		}
	}

	#endif
	// ====================================================================================================
	// MARK: Utilities
	// ====================================================================================================
	
	private mutating func incrementMovedCurrentIndexes(startingAt offset: Int) {
		
		let sortedKeys = moved.keys.sorted { (num1: Int, num2: Int) -> Bool in
			return num2 < num1 // sort in descending order
		}
		
		for idx in sortedKeys {
			
			if idx >= offset {
				
				let previousIdx = moved[idx]!
				
				moved[idx] = nil
				moved[idx+1] = previousIdx
			}
		}
	}
	
	private mutating func decrementMovedCurrentIndexes(startingAt offset: Int) {
		
		let sortedKeys = moved.keys.sorted { (num1: Int, num2: Int) -> Bool in
			return num1 < num2 // sort in ascending order
		}
		
		for idx in sortedKeys {
			
			if idx >= offset {
				
				let previousIdx = moved[idx]!
				
				moved[idx] = nil
				moved[idx-1] = previousIdx
			}
		}
	}
	
	private mutating func shiftAddedIndexes(startingAt offset: Int, by shift: Int) {
		
		precondition(shift == 1 || shift == -1)
		
		// There are some UGLY bugs in NSMutableIndexSet.
		//
		// Bug example #1:
		//
		// [added addIndex:1];
		// [added shiftIndexesStartingAtIndex:2 by:-1];
		//
		// Result:
		//   Empty frigging set.
		//   It straight up deleted our frigging index. WTF.
		//
		// Apparently, there are plenty more bugs in NSMutableIndexSet to be aware of:
		// - https://openradar.appspot.com/14707836
		// - http://ootips.org/yonat/workaround-for-bug-in-nsindexset-shiftindexesstartingatindex/
		// - https://www.mail-archive.com/cocoa-dev@lists.apple.com/msg44062.html
		//
		// So we're just going to do this the long way - which is at least reliable.
		
		let copy = added
		added.removeAll()
		
		for idx in copy {
			
			if idx < offset {
				added.insert(idx)
			}
			else {
				added.insert(idx + shift)
			}
		}
	}
	
	// ====================================================================================================
	// MARK: ZDCSyncableCollection
	// ====================================================================================================
	
	public var hasChanges: Bool {
		get {
			
			if (added.count > 0) || (moved.count > 0) || (deleted.count > 0) {
				return true
			}
			
			for item in array {
				
				if let zdc_obj = item as? ZDCSyncableObject {
					if zdc_obj.hasChanges {
						return true
					}
				}
				else if let zdc_prop = item as? ZDCSyncableProperty {
					if zdc_prop.hasChanges {
						return true
					}
				}
				else if let zdc_collection = item as? ZDCSyncableCollection {
					if zdc_collection.hasChanges {
						return true
					}
				}
			}
			
			return false
		}
	}
	
	public mutating func clearChangeTracking() {
		
		added.removeAll()
		moved.removeAll()
		deleted.removeAll()
		
		var changed_idx = Array<Int>()
		var changed_new = Array<Element>()
		
		for (idx, item) in array.enumerated() {
			
			if let zdc_obj = item as? ZDCSyncableObject {
				
				zdc_obj.clearChangeTracking()
			}
			else if let zdc_prop = item as? ZDCSyncableProperty {
				
				zdc_prop.clearChangeTracking()
			}
			else if var zdc_collection = item as? ZDCSyncableCollection {
				
				// zdc_collection is a struct,
				// so we need to write the modified value back to the set.
				
				changed_idx.append(idx)
				zdc_collection.clearChangeTracking()
				changed_new.append(zdc_collection as! Element)
			}
		}
		
		for i in 0 ..< changed_idx.count {
			
			let idx = changed_idx[i]
			let item_new = changed_new[i]
			
			array[idx] = item_new
		}
	}
	
	private func _changeset() -> Dictionary<String, Any>? {
		
		if !self.hasChanges {
			return nil
		}
		
		var changeset = Dictionary<String, Any>(minimumCapacity: 3)
		
		// Reminder: ivars look like this:
		//
		// - added: IndexSet
		// - moved: Dictionary<Int, Int>
		// - deleted: Dictionary<Int, Element>
		
		if added.count > 0 {
			
			// changeset: {
			//   added: [
			//     idx, ...
			//   ],
			//   ...
			// }
			
			let added_copy = added
			changeset[ChangesetKeys.added.rawValue] = added_copy
		}
		
		if deleted.count > 0 {
			
			// changeset: {
			//   deleted: {
			//     idx: obj, ...
			//   },
			//   ...
			// }
			
			let deleted_copy = deleted
			changeset[ChangesetKeys.deleted.rawValue] = deleted_copy
		}
		
		if moved.count > 0 {
			
			// changeset: {
			//   moved: {
			//     idx: idx, ...
			//   },
			//   ...
			// }
			
			let moved_copy = moved
			changeset[ChangesetKeys.moved.rawValue] = moved_copy
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
		//   added: IndexSet,
		//   ...
		// }
		
		if let changeset_added = changeset[ChangesetKeys.added.rawValue] {
			
			if let _ = changeset_added as? IndexSet {
				// ok
			} else {
				return true // malformed !
			}
		}
		
		// changeset: {
		//   deleted: {
		//     idx: obj, ...
		//   },
		//   ...
		// }
		
		if let changeset_deleted = changeset[ChangesetKeys.deleted.rawValue] {
			
			if let _ = changeset_deleted as? Dictionary<Int, Element> {
				// ok
			} else {
				return true // malformed !
			}
		}
		
		// changeset: {
		//   moved: {
		//     idx: idx, ...
		//   },
		//   ...
		// }
		
		if let changeset_moved = changeset[ChangesetKeys.moved.rawValue] {
			
			if let _ = changeset_moved as? Dictionary<Int, Int> {
				// ok
			} else {
				return true // malformed !
			}
		}
		
		// Looks good (not malformed)
		return false
	}
	
	private mutating func _undo(_ changeset: Dictionary<String, Any>) throws {
		
		// Important: `isMalformedChangeset:` must be called before invoking this method.
		
		// This method is called from both `undo` & `importChangesets`.
		//
		// When called from `undo`, there aren't any existing changes,
		// and we can simplify (+optimize) some of our code.
		//
		// However that's sometimes not the case when called from `importChangesets`.
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
		//     For each item that was moved, we have the 'newIndex' and 'oldIndex'.
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
		// Undo added objects.
		
		let changeset_added = changeset[ChangesetKeys.added.rawValue] as? IndexSet
		if let changeset_added = changeset_added {
			
			for idx in changeset_added.reversed() {
			
				self.remove(at: idx)
			}
		}
		
		// Step 2 of 3:
		//
		// Undo move operations
		
		if var changeset_moved = changeset[ChangesetKeys.moved.rawValue] as? Dictionary<Int, Int> {
			
			// We need to fix the `changeset_moved` dictionary.
			//
			// Here's the deal:
			// We're trying to track both items that were added, and items that were moved.
			// To accomplish this task, we use 2 data structures:
			//
			// - added: IndexSet = IndexSet()                // [{ currentIndex }]
			// - moved: Dictionary<Int, Int> = Dictionary()  // key={currentIndex}, value={previousIndex}
			//
			// OK, but wait...
			// The currentIndex of items within the 'moved' dictionary could represent either:
			//
			// Option A: the currentIndex of items BEFORE undoing added objects
			// Option B: the currentIndex of items AFTER undoing added objects
			//
			// It turns out that option B is MUCH EASIER to work with.
			// It only requires this fixup operation here,
			// to update the currentIndex to match the current state (since we just undid add operations).
			
			if let changeset_added = changeset_added {
				
				var fixup = Dictionary<Int, Int>(minimumCapacity: changeset_moved.count)
				
				for (currentIndex, previousIndex) in changeset_moved {
					
					var currentIdx = currentIndex
					for addedIdx in changeset_added.reversed() {
						
						if (currentIdx > addedIdx) {
							currentIdx -= 1
						}
					}
					
					fixup[currentIdx] = previousIndex
				}
				
				changeset_moved = fixup
			}
			
			// We have a list of tuples representing {currentIndex, previousIndex}.
			// So for each object, we need to:
			// - remove it from it's currentIndex
			// - add it back in it's previousIndex
			//
			// And we need to keep track of the changeset as we're doing this.
			
			var indexesToRemove = IndexSet()
			var tuplesToReAdd = Array<(previousIdx: Int, item: Element)>()
			
			for (currentIdx, previousIdx) in changeset_moved {
				
				if (isSimpleUndo)
				{
					moved[previousIdx] = currentIdx // just flip-flopping the values
				}
				
				indexesToRemove.insert(currentIdx)
				
				if currentIdx >= array.count {
					throw ZDCSyncableError.mismatchedChangeset
				}
				
				let item = array[currentIdx]
				tuplesToReAdd.append((previousIdx: previousIdx, item: item))
			}
			
			tuplesToReAdd.sort(by: {
				return $0.previousIdx < $1.previousIdx
			})
			
			if (!isSimpleUndo)
			{
				// We're importing changesets - aka merging multiple changesets into one changeset
				
				// Import: 1 of 5
				//
				// Calculate the originalArray (excluding delete operations)

				var originalArray: Array<Element> = Array()
				originalArray.reserveCapacity(array.count)
				
				for idx in 0 ..< array.count {
					
					if !added.contains(idx) && (moved[idx] == nil) {
						
						originalArray.append(array[idx])
					}
				}
				
				let moved_sortedByPreviousIdx = moved.sorted(by: {
					$0.value < $1.value
				})
				
				for (currentIdx, _) in moved_sortedByPreviousIdx {
					
					let item = array[currentIdx]
					let previousIdx = moved[currentIdx]!
					
					originalArray.insert(item, at: previousIdx)
				}
				
				// Import: 2 of 5
				//
				// We're about to move a bunch of items around.
				// This means we need to fixup the `added` & `moved` indexes.
				//
				// Start by removing all the target items from the `moved` dictionary.
				// We're going to replace them momentarily with updated keys.
				
				var wasAdded = IndexSet()
				
				for (currentIdx, _) in changeset_moved {
					
					moved[currentIdx] = nil // remove current value, will replace next
					
					if added.contains(currentIdx) {
						
						added.remove(currentIdx)
						wasAdded.insert(currentIdx)
					}
				}

				// Import: 3 of 5
				//
				// Fixup the `added` & `moved` indexes.
				
				for idxToRemove in indexesToRemove.reversed() {
					
					self.shiftAddedIndexes(startingAt: idxToRemove, by: -1)
					self.decrementMovedCurrentIndexes(startingAt: idxToRemove)
				}
				
				for tuple in tuplesToReAdd {
					
					let idxToAdd = tuple.previousIdx
					
					self.shiftAddedIndexes(startingAt: idxToAdd, by: 1)
					self.incrementMovedCurrentIndexes(startingAt: idxToAdd)
				}
				
				// Import: 4 of 5
				//
				// For all the items we're moving, add them into the `moved` dictionary.
				
				for (currentIdx, targetIdx) in changeset_moved {
					
					// currentIdx :
					//   Where item is in current state of array.
					//   However:
					//   - current state of array doesn't represent original state of array
					//   - current state of array doesn't represent final state of array
					// targetIdx :
					//   Where we're going to put the item (i.e. it's currentIdx AFTER we've performed moves)
					
					if wasAdded.contains(currentIdx) {
						
						added.insert(targetIdx)
					}
					else {
						
						let targetItem = array[currentIdx]
						
						if let originalIdx = originalArray.firstIndex(of: targetItem) {
							moved[targetIdx] = originalIdx
						}
					}
				}
			}

			// Import: 5 of 5
			//
			// Perform the actual move (within the underlying array).
			
			for idx in indexesToRemove.reversed() {
				
				array.remove(at: idx)
			}
			
			for tuple in tuplesToReAdd { // tuplesToReAdd is already sorted (see above)
				
				let idx = tuple.previousIdx
				let item = tuple.item
				
				if idx > array.count {
					throw ZDCSyncableError.mismatchedChangeset
				}
				
				array.insert(item, at: idx)
			}
		}

		// Step 3 of 3:
		//
		// Undo deleted objects.
		
		if let changeset_deleted = changeset[ChangesetKeys.deleted.rawValue] as? Dictionary<Int, Element> {
			
			let sorted = changeset_deleted.sorted(by: {
				
				$0.key < $1.key
			})
			
			for (idx, item) in sorted {
				
				self.insert(item, at: idx)
			}
		}
	}
	
	public mutating func performUndo(_ changeset: Dictionary<String, Any>) throws {
		
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
	
	public mutating func importChangesets(_ orderedChangesets: Array<Dictionary<String, Any>>) throws {
		
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
		-> (originalOrder: Array<Element>, added: Array<Element>, deleted: Array<Element>)?
	{
		// Important: `isMalformedChangeset:` must be called before invoking this method.
	
		var order = inOrder
		var added = Array<Element>()
		var deleted = Array<Element>()
		
		for changeset in pendingChangesets.reversed() {
			
			// IMPORTANT:
			//
			// All of this code comes from the `_undo:` method.
			// It's been changed to modify only the `order` ivar.
			//
			// For documentation & discussion of this code & logic,
			// please see the `_undo:` method.
			
			// Step 1 of 3:
			//
			// Undo added objects.
			
			let changeset_added = changeset[ChangesetKeys.added.rawValue] as? IndexSet
			if let changeset_added = changeset_added {
				
				for idx in changeset_added {
					
					if (idx >= order.count) {
						return nil
					}
					
					let item = order[idx]
					if let matchingIdx = deleted.firstIndex(of: item) {
						
						// This item is deleted in a later changeset.
						// So the two actions cancel each other out.
						deleted.remove(at: matchingIdx)
					}
					else {
						
						added.append(item)
					}
					
					order.remove(at: idx)
				}
			}
			
			// Step 2 of 3:
			//
			// Undo move operations
			
			if var changeset_moved = changeset[ChangesetKeys.moved.rawValue] as? Dictionary<Int, Int> {
				
				if let changeset_added = changeset_added {
					
					var fixup = Dictionary<Int, Int>(minimumCapacity: changeset_moved.count)
					
					for (currentIndex, previousIdx) in changeset_moved {
						
						var currentIdx = currentIndex
						for addedIdx in changeset_added.reversed() {
							
							if (currentIdx > addedIdx) {
								currentIdx -= 1
							}
						}
						
						fixup[currentIdx] = previousIdx
					}
					
					changeset_moved = fixup
				}
				
				var indexesToRemove = IndexSet()
				var tuplesToReAdd = Array<(previousIdx: Int, item: Element)>()
				
				for (currentIdx, previousIdx) in changeset_moved {
					
					indexesToRemove.insert(currentIdx)
					
					if currentIdx >= order.count {
						return nil // mismatchedChangeset
					}
					
					let item = order[currentIdx]
					tuplesToReAdd.append((previousIdx: previousIdx, item: item))
				}
				
				tuplesToReAdd.sort(by: {
					return $0.previousIdx < $1.previousIdx
				})
				
				for idx in indexesToRemove.reversed() {
					
					order.remove(at: idx)
				}
				
				for tuple in tuplesToReAdd { // tuplesToReAdd is already sorted (see above)
					
					let idx = tuple.previousIdx
					let item = tuple.item
					
					if idx > order.count {
						return nil // mismatchedChangeset
					}
					
					order.insert(item, at: idx)
				}
			}
			
			// Step 3 of 3:
			//
			// Undo deleted objects.
			
			if let changeset_deleted = changeset[ChangesetKeys.deleted.rawValue] as? Dictionary<Int, Element> {
			
				let sorted_keys = changeset_deleted.keys.sorted(by: {
					
					$0 < $1
				})
				
				for idx in sorted_keys {
					
					if (idx > order.count) {
						return nil // mismatchedChangeset
					}
					
					let item = changeset_deleted[idx]!
					
					if let matchingIdx = added.firstIndex(of: item) {
						
						// This object gets re-added in a later changeset.
						// So the two actions cancel each other out.
						added.remove(at: matchingIdx)
					}
					else {
						
						deleted.append(item)
					}
					
					order.insert(item, at: idx)
				}
			}
		}
		
		return (originalOrder: order, added: added, deleted: deleted)
	}
	
	public mutating func merge(cloudVersion inCloudVersion: ZDCSyncableCollection,
	                                     pendingChangesets: Array<Dictionary<String, Any>>)
		throws -> Dictionary<String, Any>
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
		
		guard let cloudVersion = inCloudVersion as? ZDCArray<Element> else {
			throw ZDCSyncableError.incorrectObjectClass
		}
		
		// Step 1 of 6:
		//
		// If there are pending changes, calculate the original order.
		// This will be used later on during the merge process.
		//
		// We also get the list of added & removed objects while we're at it.
		//
		// Important:
		//   We need to do this in the beginning, because we need an unmodified `array`.
		
		var originalOrder = Array<Element>()
		var local_added   = Array<Element>()
		var local_deleted = Array<Element>()
		
		if pendingChangesets.count > 0 {
			
			if let results = type(of: self).originalOrder(from: array, pendingChangesets: pendingChangesets) {
				
				originalOrder = results.originalOrder
				local_added = results.added
				local_deleted = results.deleted
			}
			else {
				throw ZDCSyncableError.mismatchedChangeset
			}
		}
		
		// Step 2 of 6:
		//
		// Add objects that were added by remote devices.
		
		let preAddedCount = array.count
		do {
			
			var localArray = self.array
			
			for item in cloudVersion.array {
				
				if let localIdx = localArray.firstIndex(of: item) {
					
					localArray.remove(at: localIdx)
				}
				else {
					
					// Object exists in cloudVersion, but not in localVersion.
					
					if let idx = local_deleted.firstIndex(of: item) {
						// We've deleted the object locally, but haven't pushed changes to cloud yet.
						local_deleted.remove(at: idx)
					}
					else {
						// Object added by remote device.
						self.append(item)
					}
				}
			}
		}
		
		// Step 3 of 6:
		//
		// Delete objects that were deleted by remote devices.
		do {
			
			var cloudArray = cloudVersion.array
			var i = 0
			
			for _ in 0 ..< preAddedCount {
				
				let item = array[i]
				
				if let cloudIdx = cloudArray.firstIndex(of: item) {
					
					cloudArray.remove(at: cloudIdx)
					i += 1
				}
				else {
					
					// Object exists in localVersion, but not in cloudVersion.
					
					if let idx = local_added.firstIndex(of: item) {
						// We've added the object locally, but haven't pushed changes to cloud yet.
						local_added.remove(at: idx)
						i += 1
					}
					else {
						// Object deleted by remote device.
						self.remove(at: i)
					}
				}
			}
		}
		
		// Step 4 of 6:
		//
		// Prepare to merge the order.
		//
		// At this point, we've added every item that was in the cloudVersion, but not in our localVersion.
		// And we've deleted every item that was deleted from the cloudVersion.
		//
		// Another change we need to take into consideration are items that we've deleted locally.
		//
		// Our aim here is to derive 2 arrays, one from cloudVersion, and another from self.
		// Both of these arrays will have the same count, and contain the same items, but possibly in a different order.
		
		var order_localVersion = Array<Element>()
		var order_cloudVersion = Array<Element>()
		
		order_localVersion.reserveCapacity(array.count)
		order_cloudVersion.reserveCapacity(array.count)
		
		do {
			var cloudArray = cloudVersion.array
			
			for item in self.array {
				
				if let idx = cloudArray.firstIndex(of: item) {
					
					cloudArray.remove(at: idx)
					order_localVersion.append(item)
				}
			}
		}
		do {
			var localArray = self.array
			
			for item in cloudVersion.array {
				
				if let idx = localArray.firstIndex(of: item) {
					
					localArray.remove(at: idx)
					order_cloudVersion.append(item)
				}
			}
		}
		
		assert(order_localVersion.count == order_cloudVersion.count, "Logic error")
		
		// Step 5 of 6:
		//
		// So now we have a 2 lists of items that we can compare: local vs cloud.
		// But when we detect a difference between the lists, what does that tell us ?
		//
		// It could mean:
		// - the location was changed remotely
		// - the location was changed locally
		// - or both (in which case remote wins)
		//
		// So we're going to need to make an educated guess as to which items
		// might have been moved by a remote device.
		
		var movedItems_remote = Array<Element>()
		
		if pendingChangesets.count == 0 {
			
			// We don't have any pending changesets, which means we didn't move anything.
			// Thus every item may have potentially been moved by a remote device.
			
			movedItems_remote = cloudVersion.array
		}
		else { // pendingChangesets.count > 0
		
			var order_originalVersion = Array<Element>()
			var order_cloudVersion = Array<Element>()
			
			order_originalVersion.reserveCapacity(originalOrder.count)
			order_cloudVersion.reserveCapacity(originalOrder.count)
			
			do {
				var cloudArray = cloudVersion.array
				
				for item in originalOrder {
					
					if let idx = cloudArray.firstIndex(of: item) {
						
						cloudArray.remove(at: idx)
						order_originalVersion.append(item)
					}
				}
			}
			do {
				var localOriginalArray = originalOrder
				
				for item in cloudVersion.array {
					
					if let idx = localOriginalArray.firstIndex(of: item) {
						
						localOriginalArray.remove(at: idx)
						order_cloudVersion.append(item)
					}
				}
			}
			
			assert(order_originalVersion.count == order_cloudVersion.count, "Logic error")
			
			do {
				movedItems_remote = try ZDCOrder.estimateChangeset(from: order_originalVersion, to: order_cloudVersion)
				
			} catch {
				
				movedItems_remote = cloudVersion.array
			}
		}
		
		// Step 6 of 6:
		//
		// We have all the information we need to merge the order now.
		
		assert(order_localVersion.count == order_cloudVersion.count)
		
		for i in 0 ..< order_cloudVersion.count {
			
			let item_remote = order_cloudVersion[i]
			let item_local  = order_localVersion[i]
			
			if item_remote != item_local {
			
				var changed_remote = false
				if let idx = movedItems_remote.firstIndex(of: item_remote) {
					
					changed_remote = true
					movedItems_remote.remove(at: idx)
				}
				
				if changed_remote {
					
					// Remote wins.
					
					let item = item_remote
					
					// Move item into proper position (with order_localVersion)
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
					
					// Move item into proper position (within self)
					//
					// Note:
					//   We already added all the objects that were added by remote devices.
					//   And we already deleted all the objects that were deleted by remote devices.
					
					if let oldIdx = self.array.firstIndex(of: item) {
						
						var newIdx = 0
						if i > 0 {
							
							let prvItem = order_localVersion[i-1]
							if let prvIdx = self.array.firstIndex(of: prvItem) {
								newIdx = prvIdx + 1
							}
						}
						
						self.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
				else
				{
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
