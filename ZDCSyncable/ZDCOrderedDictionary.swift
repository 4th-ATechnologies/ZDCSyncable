/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

import Foundation

public struct ZDCOrderedDictionary<Key: Hashable & Codable, Value: Equatable & Codable>: ZDCSyncable, Codable, Collection, Equatable {
	
	public typealias Element = Dictionary<Key, Value>.Element
	
	enum ChangesetKeys: String {
		case refs = "refs"
		case values = "values"
		case indexes = "indexes"
		case deleted = "deleted"
	}
	
	struct ZDCChangeset_OrderedDictionary {
		let refs: [Key: ZDCChangeset]
		let values: [Key: Any]
		let indexes: [Key: Int]
		let deleted: [Key: Int]
	}
	
	struct DictionaryCodingKey: CodingKey {
		let intValue: Int?
		let stringValue: String
		
		init(intValue: Int) {
			self.intValue = intValue
			self.stringValue = "\(intValue)"
		}
		
		init(stringValue: String) {
			self.stringValue = stringValue
			self.intValue = Int(stringValue) // in case encoder ignored our intValue
		}
	}
	
	private var dict: Dictionary<Key, Value>
	private var order: Array<Key>
	
	private var originalValues = Dictionary<Key, Any>()
	private var originalIndexes = Dictionary<Key, Int>()
	private var deletedIndexes = Dictionary<Key, Int>()
	
	// ====================================================================================================
	// MARK: Init
	// ====================================================================================================
	
	public init() {
		
		dict = Dictionary()
		order = Array()
	}

	public init(minimumCapacity: Int) {
		
		dict = Dictionary(minimumCapacity: minimumCapacity)
		order = Array()
	}

	public init<S>(uniqueKeysWithValues keysAndValues: S) where S : Sequence, S.Element == (Key, Value) {
		
		// From Apple's docs for Dictionary.init(uniqueKeysWithValues:)
		//
		// > "Passing a sequence with duplicate keys to this initializer results in a runtime error."
		//
		dict = Dictionary(uniqueKeysWithValues: keysAndValues)
		order = Array()
		
		for (key, _) in keysAndValues {
			order.append(key)
		}
	}
	
	public init(copy source: ZDCOrderedDictionary<Key, Value>, retainChangeTracking: Bool) {
		
		self.dict = source.dict
		self.order = source.order
		
		if retainChangeTracking {
			self.originalValues = source.originalValues
			self.originalIndexes = source.originalIndexes
			self.deletedIndexes = source.deletedIndexes
		}
	}
	
	// ====================================================================================================
	// MARK: Codable
	// ====================================================================================================
	
	// In an ideal world, we would simply encode the data as a dictionary.
	//
	// For example:
	// {"_": "peaches","a": "apple", "b": "banana"}
	//
	// But alas!
	// Swift BREAKS this for us since it REFUSES to give us access to the ordered keys in this container.
	//
	// For example, if we asked for container.allKeys, they might give us:
	// ["a", "b", "_"]
	//
	// But this is NOT the order in which the items were encoded !!!
	// So we're forced to use an alternate approach.

	
/* This approach doesn't work because `container.allKeys` doesn't give us keys
	in the actual order in which they are encoded.

	public init(from decoder: Decoder) throws {
		
		// Implementation is inspired by Swift's own Dictionary.init(from:) implementation:
		// https://github.com/apple/swift/blob/master/stdlib/public/core/Codable.swift
		
		self.init()
		
		if Key.self == String.self {
			
			let container = try decoder.container(keyedBy: DictionaryCodingKey.self)
			for key in container.allKeys { // <== BUG: `container.allKeys` doesn't retain order of keys !!!!!!!!!!
				
				let value = try container.decode(Value.self, forKey: key)
				self[key.stringValue as! Key] = value
			}
			
		} else if Key.self == Int.self {
			
			let container = try decoder.container(keyedBy: DictionaryCodingKey.self)
			for key in container.allKeys { // <== BUG: `container.allKeys` doesn't retain order of keys !!!!!!!!!!
				
				guard let keyAsIntValue = key.intValue else {
					// DictionaryCodingKey.init(intValue) was not used.
					// DictionaryCodingKey.init(strinvValue) was used,
					// and we could not parse the string as an int.
					
					var codingPath = decoder.codingPath
					codingPath.append(key)
					
					let context = DecodingError.Context(
					  codingPath: codingPath,
					  debugDescription: "Expected Int key but found String key instead."
					)
					
					throw DecodingError.typeMismatch(Int.self, context)
				}
				
				let value = try container.decode(Value.self, forKey: key)
				self[keyAsIntValue as! Key] = value
			}
		
		} else {
			
			var container = try decoder.unkeyedContainer()

			if let count = container.count {
				
				guard count % 2 == 0 else {
					
					let context = DecodingError.Context(
						codingPath: decoder.codingPath,
						debugDescription: "Expected collection of key-value pairs; encountered odd-length array instead."
					)
					
					throw DecodingError.dataCorrupted(context)
				}
			}
			
			while !container.isAtEnd {
				
				let key = try container.decode(Key.self)
				
				guard !container.isAtEnd else {
					
					let context = DecodingError.Context(
						codingPath: decoder.codingPath,
						debugDescription: "Unkeyed container reached end before value in key-value pair."
					)
					
					throw DecodingError.dataCorrupted(context)
				}
				
				let value = try container.decode(Value.self)
				self[key] = value
			}
		}
		
		self.clearChangeTracking()
	}
	
	public func encode(to encoder: Encoder) throws {
		
		// From Apple's docs on Dictionary.encode(to:)
		//
		// > If the dictionary uses `String` or `Int` keys, the contents are encoded
		// > in a keyed container. Otherwise, the contents are encoded as alternating
		// > key-value pairs in an unkeyed container.
		//
		// Implementation is inspired by Swift's own Dictionary.encode(to:) implementation:
		// https://github.com/apple/swift/blob/master/stdlib/public/core/Codable.swift
		
		if Key.self == String.self {
			
			var container = encoder.container(keyedBy: DictionaryCodingKey.self)
		  	for key in order {
				let value = dict[key]
				let codingKey = DictionaryCodingKey(stringValue: key as! String)
				try container.encode(value, forKey: codingKey)
			}
		
		} else if Key.self == Int.self {
			
			var container = encoder.container(keyedBy: DictionaryCodingKey.self)
			for key in order {
				let value = dict[key]
				let codingKey = DictionaryCodingKey(intValue: key as! Int)
				try container.encode(value, forKey: codingKey)
			}
		
		} else {
			
			var container = encoder.unkeyedContainer()
			for key in order {
				let value = dict[key]
				try container.encode(key)
				try container.encode(value)
			}
		}
	}
*/
	public init(from decoder: Decoder) throws {
		
		// We're currently forced to do it this way until Swift bug is fixed.
		// See discussion above.
		
		self.init()
		
		var container = try decoder.unkeyedContainer()

		if let count = container.count {
			
			guard count % 2 == 0 else {
				
				let context = DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription: "Expected collection of key-value pairs; encountered odd-length array instead."
				)
				
				throw DecodingError.dataCorrupted(context)
			}
		}
		
		while !container.isAtEnd {
			
			let key = try container.decode(Key.self)
			
			guard !container.isAtEnd else {
				
				let context = DecodingError.Context(
					codingPath: decoder.codingPath,
					debugDescription: "Unkeyed container reached end before value in key-value pair."
				)
				
				throw DecodingError.dataCorrupted(context)
			}
			
			let value = try container.decode(Value.self)
			self[key] = value
		}
		
		self.clearChangeTracking()
	}
	
	public func encode(to encoder: Encoder) throws {
		
		// We're currently forced to do it this way until Swift bug is fixed.
		// See discussion above.
		
		var container = encoder.unkeyedContainer()
		for key in order {
			let value = dict[key]
			try container.encode(key)
			try container.encode(value)
		}
	}
	
	// ====================================================================================================
	// MARK: Properties
	// ====================================================================================================

	/// Returns a copy of the underlying dictionary being wrapped.
	/// Changes to the returned copy will not be reflected in this instance.
	///
	public var rawDictionary: Dictionary<Key, Value> {
		get {
			let copy = self.dict
			return copy
		}
	}

	/// Returns a copy of the underlying array being wrapped.
	/// Changes to the returned copy will not be reflected in this instance.
	///
	public var rawOrder: Array<Key> {
		get {
			let copy = self.order
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

	public func keyAtIndex(_ index: Int) -> Key? {
		
		if index < order.count {
			return order[index]
		}
		
		return nil
	}
	
	public func valueAtIndex(_ index: Int) -> Value? {
		
		if index < order.count {
			let key = order[index]
			return dict[key]
		}
		
		return nil
	}
	
	public func index(ofKey key: Key) -> Int? {
		
		if (dict[key] == nil) {
			return nil
		}
		
		return order.firstIndex(of: key)
	}
	
	public func randomElement() -> (key: Key, value: Value)? {
		
		return dict.randomElement()
	}
	
	// ====================================================================================================
	// MARK: Writing
	// ====================================================================================================

	@discardableResult
	public mutating func insert(_ value: Value, forKey key: Key, atIndex requestedIdx: Int) -> Int {
		
		if let idx = self.index(ofKey: key) {
			
			self._willUpdate(forKey: key)
			
			dict[key] = value
			
			return idx
		}
		else {
			
			let idx = (requestedIdx < order.count) ? requestedIdx : order.count
		
			self._willInsert(atIndex: idx, withKey: key)
			
			dict[key] = value
			order.insert(key, at: idx)
			
			return idx
		}
	}

	public mutating func move(fromIndex oldIndex: Int, toIndex newIndex: Int) {
		
		precondition(oldIndex < order.count, "Index out of range (oldIndex)")
		
		let oldIdx = oldIndex
		let newIdx = (newIndex >= order.count) ? order.count - 1 : newIndex
		//                                         ^^^^^^^^^^^^^^^
		//                                         because we remove the item FIRST, and THEN re-insert it
		
		if oldIdx == newIdx {
			return
		}
		
		let key = order[oldIdx]
		self._willMove(fromIndex: oldIdx, toIndex: newIdx, withKey: key)
		
		order.remove(at: oldIdx)
		order.insert(key, at: newIdx)
	}

	@discardableResult
	public mutating func removeValue(forKey key: Key) -> Value? {
		
		let value = dict[key]
		if value != nil,
			let idx = order.firstIndex(of: key)
		{
			self._willRemove(atIndex: idx, withKey: key)
			
			dict[key] = nil
			order.remove(at: idx)
		}

		return value
	}

	@discardableResult
	public mutating func remove(at index: Int) -> Value {
		
		let key = order[index]
		let value = dict[key]!
		self._willRemove(atIndex: index, withKey: key)
		
		dict[key] = nil
		order.remove(at: index)
		
		return value
	}
	
	public mutating func removeAll() {

		while order.count > 0 {
			
			let key = order[0]
			self._willRemove(atIndex: 0, withKey: key)
			
			dict[key] = nil
			order.remove(at: 0)
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
				
				if dict[key] != nil {
					
					self._willUpdate(forKey: key)
					
					dict[key] = newValue
				}
				else
				{
					let idx = order.count
					self._willInsert(atIndex: idx, withKey: key)
					
					dict[key] = newValue
					order.append(key)
				}
				
			} else { // newValue == nil
				
				if let _ = dict[key], // <- faster lookup than order
					let idx = order.firstIndex(of: key)
				{
					self._willRemove(atIndex: idx, withKey: key)
					
					dict[key] = nil
					order.remove(at: idx)
				}
			}
		}
	}

	// This code is problematic:
	//
	// - The compiler whines when we try to use this method: "Ambiguous use of 'subscript"
	// - Because what happens if one does this: let dict = ZDCOrderedDictionary<Int, Int>
	//
//	public subscript(index: Int) -> Value {
//
//		get {
//			let key = order[index]
//			return dict[key]!
//		}
//
//		set(newValue) {
//
//			if index < order.count {
//
//				let key = order[index]
//				self._willUpdate(forKey: key)
//
//				dict[key] = newValue
//
//			} else {
//
//				let _ = order[index] // <- should throw an "index out-of-bounds" exception
//			}
//		}
//	}
	
	public subscript(position: Array<Key>.Index) -> Dictionary<Key, Value>.Element {
		get {
			let key = order[position]
			let dict_position = dict.index(forKey: key)!
			let result = dict[dict_position]
			return result
		}
	}

	// ====================================================================================================
	// MARK: Enumeration
	// ====================================================================================================
	
	public var startIndex: Array<Key>.Index {
		
		return order.startIndex
	}
	
	public var endIndex: Array<Key>.Index {
		
		return order.endIndex
	}
	
	public func index(after i: Array<Key>.Index) -> Array<Key>.Index {
		
		return order.index(after: i)
	}
	
	// ====================================================================================================
	// MARK: Equality
	// ====================================================================================================

	// Compares only the underlying rawDictionary and rawOrder for equality.
	// The changeset information isn't part of the comparison.
	//
	public static func == (lhs: ZDCOrderedDictionary<Key, Value>, rhs: ZDCOrderedDictionary<Key, Value>) -> Bool {

		return (lhs.order == rhs.order) && (lhs.dict == rhs.dict)
	}
	
	// ====================================================================================================
	// MARK: Change Tracking Internals
	// ====================================================================================================
	
	private mutating func _willUpdate(forKey key: Key) {
		
		if originalValues[key] == nil {
			originalValues[key] = dict[key]
		}
	}
	
	private mutating func _willInsert(atIndex idx: Int, withKey key: Key) {
		
		precondition(idx <= order.count)
		
		// INSERT: Step 1 of 2:
		//
		// Update originalValues as needed.
		
		if originalValues[key] == nil {
			originalValues[key] = ZDCNull()
		}
		
		// INSERT: Step 2 of 2:
		//
		// If we're re-adding an item that was deleted within this changeset,
		// then we need to remove it from the deleted list.
		
		deletedIndexes[key] = nil
	}
	
	private mutating func _willRemove(atIndex idx: Int, withKey key: Key) {
		
		precondition(idx < order.count)
		
		// REMOVE: 1 of 3
		//
		// Update originalValues as needed.
		// And check to see if we're deleting a item that was added within changeset.
		
		var wasAddedThenDeleted = false
		
		let originalValue = originalValues[key]
		if originalValue == nil {
			
			originalValues[key] = dict[key]
		}
		else if originalValue is ZDCNull {
			
			// Value was added within snapshot, and is now being removed
			wasAddedThenDeleted = true
			originalValues[key] = nil
		}
		
		// If we're deleting an item that was also added within this changeset,
		// then the two actions cancel each other out.
		//
		// Otherwise, this is a legitamate delete, and we need to record it.
		
		if !wasAddedThenDeleted
		{
			// REMOVE: Step 2 of 3:
			//
			// Add the item to deletedIndexes.
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
			
			if let oIdx = originalIndexes[key] {
				
				// Shortcut - we've already tracked & calculated the originalIndex.
				//
				// Actually, this is more than just a shortcut.
				// Since the item being deleted is already in originalIndexes,
				// this would throw off our calculations below.
				
				originalIdx = oIdx
			}
			else {
				
				var originalOrder = Array<Key>()
				originalOrder.reserveCapacity(order.count)
				
				for key in order {
					
					if (originalIndexes[key] == nil) && !(originalValues[key] is ZDCNull) {
						
						originalOrder.append(key)
					}
				}
				
				let sortedOriginalIndexes = originalIndexes.sorted(by: {
					$0.value < $1.value
				})
				
				for (key, prvIdx) in sortedOriginalIndexes {
					
					originalOrder.insert(key, at: prvIdx)
				}
				
				if let oIdx = originalOrder.firstIndex(of: key) {
					originalIdx = oIdx
				}
				else {
					assert(false, "")
				}
			}
			
			originalIdx_addMoveOnly = originalIdx
			
			do { // Check items that were deleted within this changeset
				
				var sortedDeletedIndexes = Array(deletedIndexes.values)
				sortedDeletedIndexes.sort()
				
				for deletedIdx in sortedDeletedIndexes {
					
					if deletedIdx <= originalIdx {
						
						// An item was deleted in front of us within this changeset. (front=lower_index)
						originalIdx += 1
					}
				}
			}
			
		#if DEBUG
			self.checkeDeletedIndexes(originalIdx)
		#endif
			deletedIndexes[key] = originalIdx

			// REMOVE: Step 3 of 3:
			//
			// Remove deleted item from originalIndexes.
			//
			// And recall that we undo deletes AFTER we undo moves.
			// So we need to fixup the originalIndexes so everything works as expected.

			originalIndexes[key] = nil

			for altKey in originalIndexes.keys {
				
				let altIdx = originalIndexes[altKey]!
				if altIdx >= originalIdx_addMoveOnly {
					originalIndexes[altKey] = (altIdx - 1);
				}
			}

		#if DEBUG
			self.checkOriginalIndexes()
		#endif
		}
	}
	
	private mutating func _willMove(fromIndex oldIdx: Int, toIndex newIdx: Int, withKey key: Key) {
		
		precondition(oldIdx < order.count)
		precondition(newIdx <= order.count)
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
		
		if (originalIndexes[key] == nil) && !(originalValues[key] is ZDCNull) {
			
			var originalOrder = Array<Key>()
			originalOrder.reserveCapacity(order.count)
			
			for key in order {
				
				if (originalIndexes[key] == nil) && !(originalValues[key] is ZDCNull) {
					
					originalOrder.append(key)
				}
			}
			
			let sortedOriginalIndexes = originalIndexes.sorted(by: {
				$0.value < $1.value
			})
			
			for (key, prvIdx) in sortedOriginalIndexes {
				
				originalOrder.insert(key, at: prvIdx)
			}
			
			if let originalIdx = originalOrder.firstIndex(of: key) {
				
			#if DEBUG
				self.checkOriginalIndexes(originalIdx)
			#endif
				originalIndexes[key] = originalIdx
			}
			else {
				assert(false, "Unable to find moved item in originalOrder !")
			}
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// MARK: Sanity Checks
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	#if DEBUG
	
	private func checkOriginalIndexes() {
		
		var existing = IndexSet()
		
		for (_, idx) in originalIndexes {
			
			assert(idx != NSNotFound, "Calculated originalIdx is wrong (within originalIndexes)")
			
			if existing.contains(idx) {
				assert(false, "Modified originalIndexes is wrong (within originalIndexes)")
			}
			
			existing.insert(idx)
		}
	}
	
	private func checkOriginalIndexes(_ originalIdx: Int) {
		
		assert(originalIdx != NSNotFound, "Calculated originalIdx is wrong (for originalIndexes)")
		
		for (_, existingIdx) in originalIndexes {
			
			if existingIdx == originalIdx {
				assert(false, "Calculated originalIdx is wrong (for originalIndexes)")
			}
		}
	}
	
	private func checkeDeletedIndexes(_ originalIdx: Int) {
		
		assert(originalIdx != NSNotFound, "Calculated originalIdx is wrong (for deletedIndexes)")
		
		for (_, existingIdx) in deletedIndexes {
			
			if existingIdx == originalIdx {
				assert(false, "Calculated originalIdx is wrong (for deletedIndexes)")
			}
		}
	}

	#endif
	// ====================================================================================================
	// MARK: ZDCSyncable Protocol
	// ====================================================================================================

	public var hasChanges: Bool {
		
		get {
			
			if (originalValues.count  > 0) ||
			   (originalIndexes.count > 0) ||
				(deletedIndexes.count  > 0)
			{
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
		
		originalValues.removeAll()
		originalIndexes.removeAll()
		deletedIndexes.removeAll()
		
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
		
		var changeset: ZDCChangeset = [:]
		
		// changeset: {
		//   refs: AnyCodable({
		//     <key: Key> : <changeset: ZDCChangeset>, ...
		//   }),
		//   values: AnyCodable({
		//     <key: Key> : <oldValue: ZDCNull|Any>, ...
		//   }),
		//   indexes: AnyCodable({
		//     <key: Key> : <oldIndex: Int>, ...
		//   }),
		//   deleted: AnyCodable({
		//     <key: Key> : <oldIndex: Int>, ...
		//   })
		// }
		
		var refs: [Key: ZDCChangeset] = [:]
		
		for (key, value) in dict {
			
			// We're looking for syncable collection types:
			//
			// - ZDCSyncableClass
			// - ZDCSyncableStruct
			
			if let zdc_obj = value as? ZDCSyncableClass {
			
				// ZDCSyncableClass => reference semantics
				//
				// - If value was added, then originalValue will be ZDCNull.
				//   If this is the case, we should not add to refs.
				//
				// - If value was swapped out, then originalValue will be some other value.
				//   If this is the case, we should not add to refs.
				
				let originalValue = originalValues[key]
				
				let wasAdded = (originalValue is ZDCNull)
				let wasSwapped = (originalValue as AnyObject?) !== (value as AnyObject)
			
				if !wasAdded && !wasSwapped {
					
					var value_changeset = zdc_obj.peakChangeset()
					if value_changeset == nil {
						
						// Edge case:
						//   If the value was modified, but ultimately unchanged,
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
				// - If value was added, then originalValue will be ZDCNull.
				//   If this is the case, we should not add to refs.
				
				let originalValue = originalValues[key]
				
				let wasAdded = (originalValue is ZDCNull)
				
				if !wasAdded {
					
					var value_changeset = zdc_struct.peakChangeset()
					if (value_changeset == nil) {
						
						// Edge case:
						//   If the value was modified, but ultimately unchanged,
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
		}
		
		if refs.count > 0 {
			changeset[ChangesetKeys.refs.rawValue] = AnyCodable(refs)
		}
		
		//
		// values
		//
		
		if originalValues.count > 0 {
			
			var values: [Key: Any] = [:]
		
			for (key, originalValue) in originalValues {
		
				if refs[key] == nil {
		
					if let originalValue = originalValue as? Value {
		
						if let originalValue = originalValue as? NSCopying {
							values[key] = originalValue.copy() as! Value
						}
						else {
							values[key] = originalValue
						}
		
					} else if let originalValue = originalValue as? ZDCNull {
		
						values[key] = originalValue
					}
				}
			}
		
			if values.count > 0 {
				changeset[ChangesetKeys.values.rawValue] = AnyCodable(values)
			}
		}
		
		//
		// indexes
		//
		
		if originalIndexes.count > 0 {
			
			var changeset_indexes: [Key: Int] = [:]
			
			for (key, oldIdx) in originalIndexes {
				
				if let _ = self.index(ofKey: key) {
					changeset_indexes[key] = oldIdx
				}
			}
			
			if changeset_indexes.count > 0 {
				changeset[ChangesetKeys.indexes.rawValue] = AnyCodable(changeset_indexes)
			}
		}
		
		//
		// deleted
		//
		
		if deletedIndexes.count > 0 {
			
			var changeset_deleted: [Key: Int] = [:]
			
			for (key, oldIdx) in deletedIndexes {
				changeset_deleted[key] = oldIdx
			}
			
			changeset[ChangesetKeys.deleted.rawValue] = AnyCodable(changeset_deleted)
		}
		
		return changeset
	}

	private func parseChangeset(_ changeset: ZDCChangeset) -> ZDCChangeset_OrderedDictionary? {
		
		// changeset: {
		//   refs: AnyCodable({
		//     <key: Key> : <changeset: ZDCChangeset>, ...
		//   }),
		//   values: AnyCodable({
		//     <key: Key> : <oldValue: ZDCNull|Any>, ...
		//   }),
		//   indexes: AnyCodable({
		//     <key: Key> : <oldIndex: Int>, ...
		//   }),
		//   deleted: AnyCodable({
		//     <key: Key> : <oldIndex: Int>, ...
		//   })
		// }
		
		var refs: [Key: ZDCChangeset] = [:]
		var values: [Key: Any] = [:]
		var indexes: [Key: Int] = [:]
		var deleted: [Key: Int] = [:]
		
		// refs
		if let wrapped_refs = changeset[ChangesetKeys.refs.rawValue] {
		
			guard let unwrapped_refs = wrapped_refs.value as? [Key: ZDCChangeset] else {
				return nil // malformed !
			}
			
			refs = unwrapped_refs
		}
		
		// values
		if let wrapped_values = changeset[ChangesetKeys.values.rawValue] {
			
			guard let unwrapped_values = wrapped_values.value as? [Key: Any] else {
				return nil // malformed
			}
			
			for (key, value) in unwrapped_values {
				
				if (value is ZDCNull) || (value is Value) {
					values[key] = value
				} else {
					return nil // malformed
				}
			}
		}
		
		// indexes
		if let wrapped_indexes = changeset[ChangesetKeys.indexes.rawValue] {
			
			guard let unwrapped_indexes = wrapped_indexes.value as? [Key: Int] else {
				return nil // malformed
			}
			
			indexes = unwrapped_indexes
		}
		
		// deleted
		if let wrapped_deleted = changeset[ChangesetKeys.deleted.rawValue] {
			
			guard let unwrapped_deleted = wrapped_deleted.value as? [Key: Int] else {
				return nil // malformed
			}
			
			deleted = unwrapped_deleted
		}
		
		// Looks good (not malformed)
		return ZDCChangeset_OrderedDictionary(refs: refs, values: values, indexes: indexes, deleted: deleted)
	}

	private mutating func _undo(_ changeset: ZDCChangeset_OrderedDictionary) throws {
		
		// This method is called from both `undo::` & `importChangesets::`.
		//
		// When called from `undo::`, there aren't any existing changes,
		// and we can simplify (+optimize) some of our code.
		//
		// However that's sometimes not the case when called from `importChangesets::`.
		// So we have to guard for that situation.
		
		let isSimpleUndo = !self.hasChanges
		
		// Change tracking algorithm:
		//
		// We have 3 sources of information to apply:
		//
		// - Changed items
		//
		//     For each item that was changed (within the changeset period),
		//     we have the 'key', an 'oldValue', and a 'newValue'.
		//
		//     If an item was added, then the 'oldValue' will be ZDCNull.
		//     If an item was deleted, then the 'newValue' will be ZDCNull.
		//
		// - Moved items
		//
		//     For each item that was moved (within the change-period),
		//     we have the 'key' and 'oldIndex'.
		//
		// - Deleted items
		//
		//     For each item that was deleted (within the change period),
		//     we have the 'key' and 'oldIndex'.
		//
		//     Recall that the 'oldValue' can be found within the 'Changed items' section.
		//
		//
		// In order for the algorithm to work, the 3 sources of information MUST be
		// applied 1-at-a-time, and in a specific order. Moving backwards,
		// from [current state] to [previous state] the order is:
		//
		//                       direction    <=       this      <=     in      <=      read
		// [previous state] <= (undo deletes) <= (reverse moves) <= (undo adds) <= [current state]
		
		// Step 1 of 4:
		//
		// Undo changes to objects that conform to ZDCSyncable protocol
		
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
		
		// Step 2 of 4:
		//
		// Undo added objects & restore previous values.
		
		for (key, oldValue) in changeset.values {
			
			if dict[key] != nil {
				
				if oldValue is ZDCNull {
					self[key] = nil
				}
				else if let oldValue = oldValue as? Value {
					self[key] = oldValue
				}
			}
		}
		
		// Step 3 of 4:
		//
		// Undo move operations
		
		do {
			
			// We have a list of keys, and their originalIndexes.
			// So for each key, we need to:
			// - remove it from it's currentIndex
			// - add it back in it's originalIndex
			//
			// And we need to keep track of the changeset (originalIndexes) as we're doing this.
			
			let changeset_moved = changeset.indexes
			
			var moved_keys = Array<Key>()
			var moved_indexes = IndexSet()
			
			moved_keys.reserveCapacity(changeset_moved.count)
			
			for (key, _) in changeset_moved {
				
				if let idx = self.index(ofKey: key) {
					
					if (isSimpleUndo)
					{
					#if DEBUG
						self.checkOriginalIndexes(idx)
					#endif
						originalIndexes[key] = idx
					}
					
					moved_keys.append(key)
					moved_indexes.insert(idx)
				}
			}
			
			if (!isSimpleUndo)
			{
				var originalOrder: [Key] = []
				originalOrder.reserveCapacity(order.count)
				
				for key in order {
					
					if (originalIndexes[key] == nil) && !(originalValues[key] is ZDCNull) {
						
						originalOrder.append(key)
					}
				}
				
				let sortedOriginalIndexes = originalIndexes.sorted(by: {
					$0.value < $1.value
				})
				
				for (key, prvIdx) in sortedOriginalIndexes {
					
					originalOrder.insert(key, at: prvIdx)
				}
				
				for moved_key in moved_keys {
					
					if (originalIndexes[moved_key] == nil)
					{
						if let originalIdx = originalOrder.firstIndex(of: moved_key) {
							
						#if DEBUG
							self.checkOriginalIndexes(originalIdx)
						#endif
							originalIndexes[moved_key] = originalIdx
						}
						else {
							
							// Might be the case during an `importChanges::` operation,
							// where an item was added in changeset_A, and moved in changeset_B.
						}
					}
				}
			} // end: if (!isSimpleUndo)
			
			for movedIdx in moved_indexes.reversed() {
				
				order.remove(at: movedIdx)
			}
			
			// Sort keys by targetIdx (originalIdx).
			// We want to add them from lowest idx to highest idx.
			moved_keys.sort(by: {
				
				let idx1 = changeset_moved[$0]!
				let idx2 = changeset_moved[$1]!
				
				return idx1 < idx2
			})
			
			for moved_key in moved_keys {
				
				let idx = changeset_moved[moved_key]!
				if (idx > order.count) {
					throw ZDCSyncableError.mismatchedChangeset
				}
				
				order.insert(moved_key, at: idx)
			}
		}

		// Step 4 of 4:
		//
		// Undo deleted objects.
		
		do {
			
			let sorted = changeset.deleted.sorted(by: {
				
				return $0.value < $1.value
			})
			
			for (key, idx) in sorted {
				
				if (idx > self.count) {
					throw ZDCSyncableError.mismatchedChangeset
				}
				
				if let old_value = changeset.values[key] as? Value {
					
					self.insert(old_value, forKey: key, atIndex: idx)
				}
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
		
		var orderedParsedChangesets: [ZDCChangeset_OrderedDictionary] = []
		
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

	/// Calculates the original order from the given changesets.
	///
	private static func originalOrder(from inOrder: [Key], pendingChangesets: [ZDCChangeset_OrderedDictionary])
		-> [Key]?
	{
		var order = inOrder
		
		for changeset in pendingChangesets.reversed() {
			
			// All of this code comes from the `_undo:` method.
			// But it's been changed to include only stuff that affects the order.
			
			// Step 1 of 3:
			//
			// Undo added keys
			
			for (key, oldValue) in changeset.values {
			
				if oldValue is ZDCNull {
					
					if let idx = order.firstIndex(of: key) {
						
						order.remove(at: idx)
					}
				}
			}
			
			// Step 2 of 3:
			//
			// Undo moved keys
			
			if changeset.indexes.count > 0 {
				
				// We have a list of keys, and their originalIndexes.
				// So for each key, we need to:
				// - remove it from it's currentIndex
				// - add it back in it's originalIndex
				
				let changeset_moves = changeset.indexes
				
				var moved_keys = Array<Key>()
				var moved_indexes = IndexSet()
				
				moved_keys.reserveCapacity(changeset_moves.count)
				
				for (key, _) in changeset_moves {
					
					if let idx = order.firstIndex(of: key) {
						
						moved_keys.append(key)
						moved_indexes.insert(idx)
					}
				}
				
				for movedIdx in moved_indexes.reversed() {
					
					order.remove(at: movedIdx)
				}
				
				// Sort keys by targetIdx (originalIdx).
				// We want to add them from lowest idx to highest idx.
				moved_keys.sort(by: {
					
					let idx1 = changeset_moves[$0]!
					let idx2 = changeset_moves[$1]!
					
					return idx1 < idx2
				})
				
				for moved_key in moved_keys {
					
					let idx = changeset_moves[moved_key]!
					if (idx > order.count) {
						return nil
					}
					
					order.insert(moved_key, at: idx)
				}
			}
			
			// Step 3 of 3:
			//
			// Undo deleted objects
			
			if changeset.deleted.count > 0 {
				
				let sorted = changeset.deleted.sorted(by: {
					
					return $0.value < $1.value
				})
				
				for (key, idx) in sorted {
					
					if (idx > order.count) {
						return nil
					}
					
					if let _ = changeset.values[key] as? Value {
						
						order.insert(key, at: idx)
					}
				}
			}
		}
	
		return order
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
		
		var parsedChangesets: [ZDCChangeset_OrderedDictionary] = []
		
		for changeset in pendingChangesets {
			
			if let parsedChangeset = parseChangeset(changeset) {
				parsedChangesets.append(parsedChangeset)
			} else {
				throw ZDCSyncableError.malformedChangeset
			}
		}
		
		guard let cloudVersion = inCloudVersion as? ZDCOrderedDictionary<Key, Value> else {
			throw ZDCSyncableError.incorrectType
		}
		
		// Step 1 of 8:
		//
		// If there are pending changes, calculate the original order.
		// This will be used later on during the merge process.
		//
		// Note:
		//   We don't care about the original values here.
		//   Just the original order.
		//
		// Important:
		//   We need to do this in the beginning, because we need an unmodified `order`.
		
		var originalOrder: Array<Key>? = nil
		if parsedChangesets.count > 0 {
			
			originalOrder = type(of: self).originalOrder(from: order, pendingChangesets: parsedChangesets)
			if (originalOrder == nil) {
				
				throw ZDCSyncableError.mismatchedChangeset
			}
		}
		
		// Step 2 of 8:
		//
		// We need to determine which keys have been changed locally, and what the original versions were.
		// We'll need this information when comparing to the cloudVersion.
		
		var merged_originalValues = Dictionary<Key, Any>()
		
		for parsedChangeset in parsedChangesets {
			
			for (key, oldValue) in parsedChangeset.values {
				
				if merged_originalValues[key] == nil {
					
					merged_originalValues[key] = oldValue
				}
			}
		}
		
		// Step 3 of 8:
		//
		// Next, we're going to enumerate what values are in the cloud.
		// This will tell us what was added & modified by remote devices.
		
		var movedKeys_remote = Set<Key>()
		
		for (key, cloudValue) in cloudVersion {
		
			let currentLocalValue = self.dict[key]
			var originalLocalValue = merged_originalValues[key]
			
			let modifiedValueLocally = (originalLocalValue != nil)
			if (originalLocalValue is ZDCNull) {
				originalLocalValue = nil
			}
			
			if !modifiedValueLocally {
				
				if ((currentLocalValue is ZDCSyncableClass) && (cloudValue is ZDCSyncableClass)) ||
				   ((currentLocalValue is ZDCSyncableStruct) && (cloudValue is ZDCSyncableStruct)) {
					
					continue // handled by refs
				}
			}
			
			var mergeRemoteValue = false
			
			if cloudValue != currentLocalValue { // remote & (current) local values differ
				
				if modifiedValueLocally {
					
					if let originalLocalValue = originalLocalValue as? Value,
						originalLocalValue == cloudValue {
						// modified by local only
					}
					else {
						mergeRemoteValue = true // added/modified by local & remote - remote wins
					}
				}
				else { // we have not modified the value locally
					
					mergeRemoteValue = true // added/modified by remote
				}
			}
			else // remote & local values match
			{
				if modifiedValueLocally {
					
					// Possible future optimization.
					// There's no need to push this particular change since cloud already has it.
				}
			}
			
			if mergeRemoteValue {
				
				self[key] = cloudValue;
				movedKeys_remote.insert(key)
			}
		}
		
		// Step 4 of 8:
		//
		// Next we need to determine if any values were deleted by remote devices.
		do {
			
			var baseKeys = Set<Key>(dict.keys)
			
			for (key, item) in merged_originalValues {
				
				if item is ZDCNull { // Null => we added this tuple.
					baseKeys.remove(key) // So it's not part of the set the cloud is expected to have.
				} else {
					baseKeys.insert(key) // For items that we may have deleted (no longer in dict.keys)
				}
			}
			
			for key in baseKeys {
				
				let remoteValue = cloudVersion[key]
				if (remoteValue == nil)
				{
					// The remote key/value pair was deleted
					
					self.removeValue(forKey: key)
				}
			}
		}
		
		// Step 5 of 8:
		//
		// Merge the ZDCSyncable properties
		
		var refs = Set<Key>()
		
		for parsedChangeset in parsedChangesets {
			
			for (key, _) in parsedChangeset.refs {
				
				if merged_originalValues[key] == nil {
					
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
		
		// Step 6 of 8:
		//
		// Prepare to merge the order.
		//
		// At this point, we've added every key/value pair that was in the cloudVersion, but not in our localVersion.
		// And we've deleted key/value pairs that have been deleted from the cloudVersion.
		//
		// Another change we need to take into consideration are key/value pairs we've deleted locally.
		//
		// Our aim here is to derive 2 arrays, one from cloudVersion->order, and another from self->order.
		// Both of these arrays will have the same count, and contain the same keys, but possibly in a different order.
		
		var order_localVersion: Array<Key>
		var order_cloudVersion: Array<Key>
		
		do {
			
			var merged_keys = Set<Key>(self.order)
			merged_keys.formIntersection(cloudVersion.order)
			
			order_localVersion = self.order.filter({
				return merged_keys.contains($0)
			})
			
			order_cloudVersion = cloudVersion.order.filter({
				return merged_keys.contains($0)
			})
			
			assert(order_localVersion.count == order_cloudVersion.count)
		}
		
		// Step 7 of 8:
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
		
		if pendingChangesets.count == 0 {
			
			movedKeys_remote.formUnion(cloudVersion.order)
		}
		else { // pendingChangesets.count > 0
		
			var merged_keys = Set<Key>(originalOrder ?? Array())
			merged_keys.formIntersection(cloudVersion.order)
			
			let order_originalVersion = originalOrder!.filter({
				return merged_keys.contains($0)
			})
			
			let order_cloudVersion = cloudVersion.order.filter({
				return merged_keys.contains($0)
			})
			
			assert(order_originalVersion.count == order_cloudVersion.count)
			
			do {
				// Make educated guest as to what items may have been moved:
				let estimate = try ZDCOrder.estimateChangeset(from: order_originalVersion, to: order_cloudVersion)
				
				movedKeys_remote.formUnion(estimate)
			}
			catch {
				movedKeys_remote.formUnion(cloudVersion.order)
			}
		}
		
		// Step 8 of 8:
		//
		// We have all the information we need to merge the order now.
		
		assert(order_localVersion.count == order_cloudVersion.count)
		
		for i in 0 ..< order_cloudVersion.count {
			
			let key_remote = order_cloudVersion[i]
			let key_local = order_localVersion[i]
			
			if key_remote != key_local {
				
				let changed_remote = movedKeys_remote.contains(key_remote)
				if (changed_remote)
				{
					// Remote wins.
					
					let key = key_remote
					
					// Move key into proper position (within order_localVersion)
					do {
					
						var idx: Int? = nil
						for s in stride(from: i+1, to: order_localVersion.count, by: 1) {
							
							if order_localVersion[s] == key {
								idx = s
								break
							}
						}
						
						if let idx = idx {
							
							order_localVersion.remove(at: idx)
							order_localVersion.insert(key, at: i)
						}
					}
					
					// Move key into proper position (within self)
					//
					// Note:
					//   We already added all the keys that were added by remote devices.
					//   And we already deleted all the keys that were deleted by remote devices.
					
					if let oldIdx = self.index(ofKey: key) {
						
						var newIdx = 0
						if i > 0 {
							
							let prvKey = order_localVersion[i-1]
							if let prvIdx = self.order.firstIndex(of: prvKey) {
								newIdx = prvIdx + 1
							}
						}
						
						self.move(fromIndex: oldIdx, toIndex: newIdx)
					}
				}
				else
				{
					// Local wins.
					
					let key = key_local
					
					// Move remote into proper position (with changed_remote)
					
					var idx: Int? = nil
					for s in stride(from: i+1, to: order_cloudVersion.count, by: 1) {
						
						if order_cloudVersion[s] == key {
							idx = s
							break
						}
					}
					
					if let idx = idx {
						
						order_cloudVersion.remove(at: idx)
						order_cloudVersion.insert(key, at: i)
					}
				}
			}
		}
		
		return self.changeset() ?? Dictionary()
	}

}

extension ZDCOrderedDictionary: Hashable where Key: Hashable, Value: Hashable {
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.rawDictionary)
		hasher.combine(self.rawOrder)
	}
}
