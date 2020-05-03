/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & objects in pure Swift.

import Foundation

/// ZDCRecord is a base class the implements ZDCSyncableClass, and is designed to be subclassed.
///
/// Note: If you want to use a struct (rather than a class), see the file ZDCStruct.swift.
///
/// It provides the following set of features for your subclass:
/// - instances can be made immutable (via `ZDCRecord.makeImmutable()` function)
/// - it implements the ZDCSyncable protocol and thus:
/// - it tracks all changes and can provide a changeset (which encodes the changes info)
/// - it supports undo & redo
/// - it supports merge operations
///
open class ZDCRecord: ZDCSyncableClass {
	
	private enum ChangesetKeys: String {
		case refs = "refs"
		case values = "values"
	}
	
	// ====================================================================================================
	// MARK: Init
	// ====================================================================================================
	
	public init() {
		// Nothing to do here, but required by Swift compiler.
	}
	
	// ====================================================================================================
	// MARK: Utilities
	// ====================================================================================================
	
	open func enumerateSyncable(_ block: (_ propertyName: String, _ value: Any?, _ stop: inout Bool) -> Void) {
		
		var stop: Bool = false
		
		var _mirror: Mirror? = Mirror(reflecting: self)
		outerLoop: while let mirror = _mirror {
		
			if mirror.subjectType == ZDCRecord.self {
				break
			}
			
			for property in mirror.children {
		
				if let label = property.label {
					
					if let zdc_prop = property.value as? ZDCSyncableProperty  {
						
						block(label, zdc_prop, &stop)
					}
					else if let zdc_obj = property.value as? ZDCSyncableClass {
					
						block(label, zdc_obj, &stop)
					}
					else if let zdc_struct = property.value as? ZDCSyncableStruct {
						
						block(label, zdc_struct, &stop)
					}
				}
				
				if stop {
					break outerLoop
				}
			}
		
			_mirror = mirror.superclassMirror
		}
	}
	
	open func syncableValue(key: String) -> Any? {
		
		var result: Any? = nil
		var _result: Any? = nil
		
		enumerateSyncable { (label, value, stop) in
			
			if label == key {
				result = value
				_result = nil
				stop = true
			}
			else if label == ("_"+key) { // @Wrapper var foo: Bar => var _foo: Wrapper<Bar>
				_result = value
			}
		}
		
		return result ?? _result
	}
	
	// ====================================================================================================
	// MARK: ZDCSyncableClass Protocol
	// ====================================================================================================
	
	open func setSyncableValue(_ value: Any?, for key: String) -> Bool {
		
		return false
	}
	
	open var hasChanges: Bool {
		get {
			
			var hasChanges = false
			enumerateSyncable { (propertyName, value, stop) in
				
				if let zdc_obj = value as? ZDCSyncableClass {
					if zdc_obj.hasChanges {
						hasChanges = true
						stop = true
					}
				}
				else if let zdc_prop = value as? ZDCSyncableProperty {
					if zdc_prop.hasChanges {
						hasChanges = true
						stop = true
					}
				}
				else if let zdc_struct = value as? ZDCSyncableStruct {
					if zdc_struct.hasChanges {
						hasChanges = true
						stop = true
					}
				}
			}
			
			return hasChanges
		}
	}

	open func clearChangeTracking() {
		
		self.enumerateSyncable { (propertyName, value, _) in
			
			if let zdc_obj = value as? ZDCSyncableClass {
				
				zdc_obj.clearChangeTracking()
			}
			else if let zdc_prop = value as? ZDCSyncableProperty {
				
				zdc_prop.clearChangeTracking()
			}
			else if var zdc_struct = value as? ZDCSyncableStruct {
				
				zdc_struct.clearChangeTracking()
				
				// struct value semantics means we need to write the modified value back to self
				
				if !setSyncableValue(zdc_struct, for: propertyName) {
					ZDCSwiftWorkarounds.throwSyncableException(type(of: self), forKey: propertyName)
				}
			}
		}
	}
	
	public func peakChangeset() -> Dictionary<String, Any>? {
		
		if !self.hasChanges {
			return nil
		}
		
		// changeset: {
		//   refs: {
		//     key: changeset, ...
		//   },
		//   values: {
		//     key: oldValue, ...
		//   },
		//   ...
		// }
		
		var refs = Dictionary<String, Any>()
		var values = Dictionary<String, Any>()
		
		self.enumerateSyncable { (key, value, _) in
			
			if let zdc_obj = value as? ZDCSyncableClass {
				
				if let changeset = zdc_obj.peakChangeset() {
					
					refs[key] = changeset
				}
			}
			else if let zdc_prop = value as? ZDCSyncableProperty {
				
				if zdc_prop.hasChanges {
					
					let originalValue = zdc_prop.getOriginalValue()
					
					if originalValue == nil {
						values[key] = ZDCNull.sharedInstance()
					} else {
						values[key] = originalValue
					}
				}
			}
			else if let zdc_struct = value as? ZDCSyncableStruct {
				
				if let changeset = zdc_struct.peakChangeset() {
					
					refs[key] = changeset
				}
			}
		}
		
		var changeset = Dictionary<String, Any>()
		if (refs.count > 0) {
			changeset[ChangesetKeys.refs.rawValue] = refs
		}
		if (values.count > 0) {
			changeset[ChangesetKeys.values.rawValue] = values
		}
		
		return changeset
	}
	
	private func isMalformedChangeset(_ changeset: Dictionary<String, Any>) -> Bool {
		
		if changeset.count == 0 {
			return false
		}
		
		// changeset: {
		//   refs: {
		//     <key: Any> : <changeset: Dictionary>, ...
		//   },
		//   values: {
		//     <key: NSString*> : <oldValue: ZDCNull|Any>, ...
		//   }
		// }
		
		do { // refs
			
			let changeset_refs = changeset[ChangesetKeys.refs.rawValue]
			if (changeset_refs != nil) {
				
				guard changeset_refs is Dictionary<String, Dictionary<String, Any>> else {
					return true // malformed
				}
			}
		}
		
		do { // values
				
			let changeset_values = changeset[ChangesetKeys.values.rawValue]
			if (changeset_values != nil) {
				
				guard changeset_values is Dictionary<String, Any> else {
					return true // malformed
				}
			}
		}
		
		// looks good (not malformed)
		return false
	}
	
	private func _undo(_ changeset: Dictionary<String, Any>) throws {
		
		// Important: `isMalformedChangeset:` must be called before invoking this method.
		
		if let changeset_refs = changeset[ChangesetKeys.refs.rawValue] as? Dictionary<String, Dictionary<String, Any>> {
		
			for (key, container_changeset) in changeset_refs {
				
				let value = syncableValue(key: key)
				
				if let zdc_obj = value as? ZDCSyncableClass {
					
					try zdc_obj.performUndo(container_changeset)
					
				} else if var zdc_struct = value as? ZDCSyncableStruct {
			
					try zdc_struct.performUndo(container_changeset)
					
					// struct value semantics means we need to write the modified value back to self
					
					if !setSyncableValue(zdc_struct, for: key) {
						ZDCSwiftWorkarounds.throwSyncableException(type(of: self), forKey: key)
					}
					
				} else {
					
					throw ZDCSyncableError.mismatchedChangeset
				}
			}
		}
		
		if let changeset_values = changeset[ChangesetKeys.values.rawValue] as? Dictionary<String, Any> {
			
			for (key, oldValue) in changeset_values {
				
				var success = false
				if let zdc_prop = self.syncableValue(key: key) as? ZDCSyncableProperty {
					
					if (oldValue is ZDCNull) {
						success = zdc_prop.trySetValue(nil)
					}
					else {
						success = zdc_prop.trySetValue(oldValue)
					}
				}
				
				if !success {
					throw ZDCSyncableError.mismatchedChangeset
				}
			}
		}
	}
	
	public func performUndo(_ changeset: Dictionary<String, Any>) throws {
		
	//	if (self.isImmutable) {
	//		ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
	//	}
		
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
		
	//	if self.isImmutable {
	//		throw ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
	//	}
		
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
	
	public func merge(cloudVersion inCloudVersion: ZDCSyncableClass,
	                            pendingChangesets: Array<Dictionary<String, Any>>)
		throws -> Dictionary<String, Any>
	{
	//	if self.isImmutable {
	//		ZDCSwiftWorkarounds.throwImmutableException(type(of: self))
	//	}
		
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
		
		
		guard let cloudVersion = inCloudVersion as? ZDCRecord else {
			throw ZDCSyncableError.incorrectType
		}
		
		// Step 1 of 3:
		//
		// We need to determine which keys have been changed locally, and what the original versions were.
		// We'll need this information when comparing to the cloudVersion.
		
		var merged_originalValues = Dictionary<String, Any>()
		
		for changeset in pendingChangesets {
			
			if let changeset_originalValues = changeset[ChangesetKeys.values.rawValue] as? Dictionary<String, Any> {
			
				for (key, oldValue) in changeset_originalValues {
					
					if (merged_originalValues[key] == nil) {
						merged_originalValues[key] = oldValue
					}
				}
			}
		}
	
		// Step 2 of 3:
		//
		// Next, we're going to enumerate what values are in the cloud.
		// This will tell us what was added & modified by remote devices.
		
		let IsEqualOrBothNil = {(_ a: Any?, _ b: Any?) -> Bool in
			
			guard let a = a else {
				return (b == nil)
			}
			guard let b = b else {
				return false
			}
			
			if let propA = a as? ZDCSyncableProperty {
				
				return propA.isValueEqual(b)
			
			} else {
				
				let objA = a as AnyObject
				let objB = b as AnyObject
				
				return objA.isEqual(objB)
			}
		}
		
		var isMalformedChangeset = false
		
		cloudVersion.enumerateSyncable({ (key, cloudValue, _) in
			
			let currentLocalValue = self.syncableValue(key: key)
			var originalLocalValue = merged_originalValues[key]
			
			let modifiedValueLocally = (originalLocalValue != nil)
			if originalLocalValue is ZDCNull {
				originalLocalValue = nil
			}
			
			if !modifiedValueLocally {
				
				if ((currentLocalValue is ZDCSyncableClass) && (cloudValue is ZDCSyncableClass)) ||
				   ((currentLocalValue is ZDCSyncableStruct) && (cloudValue is ZDCSyncableStruct)) {
					
					// continue - handled by refs
					return // from block
				}
			}
			
			var mergeRemoteValue = false
			
			if !IsEqualOrBothNil(cloudValue, currentLocalValue) { // remote & (current) local values differ
			
				if modifiedValueLocally {
					
					if IsEqualOrBothNil(cloudValue, originalLocalValue) {
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
			else { // remote & local values match
			
				if modifiedValueLocally { // we've modified the value locally
				
					// Possible future optimization.
					// There's no need to push this particular change since cloud already has it.
				}
			}
			
			if mergeRemoteValue {
				if let zdc_prop = currentLocalValue as? ZDCSyncableProperty {
					if !zdc_prop.trySetValue(cloudValue) {
						isMalformedChangeset = true
					}
				} else {
					isMalformedChangeset = true
				}
			}
		})
		
		if isMalformedChangeset {
			throw ZDCSyncableError.malformedChangeset
		}
		
		// Step 3 of 3:
		//
		// Merge the ZDCSyncable properties
		
		var refs = Set<String>()
		
		for changeset in pendingChangesets {
			
			if let changeset_refs = changeset[ChangesetKeys.refs.rawValue] as? Dictionary<String, Dictionary<String, Any>> {
				
				for (key, _) in changeset_refs {
					
					if merged_originalValues[key] == nil {
						
						refs.insert(key)
					}
				}
			}
		}
		
		for key in refs {
			
			let local_value = self.syncableValue(key: key)
			let cloud_value = cloudVersion.syncableValue(key: key)
			
			var pendingChangesets_ref = Array<Dictionary<String, Any>>()
			pendingChangesets_ref.reserveCapacity(pendingChangesets.count)
			
			for changeset in pendingChangesets {
				
				let changeset_refs = changeset[ChangesetKeys.refs.rawValue] as? Dictionary<String, Dictionary<String, Any>>
				let changeset_ref = changeset_refs?[key]
				
				if let changeset_ref = changeset_ref {
					
					pendingChangesets_ref.append(changeset_ref)
				}
			}
			
			if let local_obj = local_value as? ZDCSyncableClass,
			   let cloud_obj = cloud_value as? ZDCSyncableClass
			{
				let _ = try local_obj.merge(cloudVersion: cloud_obj, pendingChangesets: pendingChangesets_ref)
			}
			else if var local_struct = local_value as? ZDCSyncableStruct,
			        let cloud_struct = cloud_value as? ZDCSyncableStruct
			{
				let _ = try local_struct.merge(cloudVersion: cloud_struct, pendingChangesets: pendingChangesets_ref)
				
				// struct value semantics means we need to write the modified value back to self
				
				if !setSyncableValue(local_struct, for: key) {
					ZDCSwiftWorkarounds.throwSyncableException(type(of: self), forKey: key)
				}
			}
		}
		
		return (self.changeset() ?? Dictionary())
	}
}
