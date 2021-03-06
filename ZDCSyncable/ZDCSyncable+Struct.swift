/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

import Foundation

fileprivate enum ChangesetKeys: String {
	case refs = "refs"
	case values = "values"
}

public struct ZDCChangeset_Struct {
	public let refs: [String: ZDCChangeset]
	public let values: [String: Any]
}

extension ZDCSyncable {
	
	private func enumerateSyncable(_ block: (_ propertyName: String, _ value: Any?, _ stop: inout Bool) -> Void) {
		
		var stop: Bool = false
		
		var _mirror: Mirror? = Mirror(reflecting: self)
		outerLoop: while let mirror = _mirror {
			
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
	
	private func syncableValue(key: String) -> Any? {
		
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
	
	private func setSyncableValueFailed(for key: String) {
		
		let message = """
		Contract Violation!
		A call to setSyncableValue(_:for:) failed for: \(key).
		You must implement the function setSyncableProperty(_:for:),
		and ensure you properly handle all syncable properties.
		"""
		
		preconditionFailure(message)
	}
	
	// ====================================================================================================
	// MARK: ZDCSyncable Protocol
	// ====================================================================================================

	public var hasChanges: Bool {
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

	public mutating func clearChangeTracking() {
		
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
	
				if !self.setSyncableValue(zdc_struct, for: propertyName) {
					
					setSyncableValueFailed(for: propertyName)
				}
			}
		}
	}

	public func peakChangeset() -> ZDCChangeset? {
		
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
		
		var refs: [String: ZDCChangeset] = [:]
		var values: [String: Any] = [:]
		
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
						values[key] = ZDCNull()
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
		
		var changeset: ZDCChangeset = [:]
		if (refs.count > 0) {
			changeset[ChangesetKeys.refs.rawValue] = AnyCodable(refs)
		}
		if (values.count > 0) {
			changeset[ChangesetKeys.values.rawValue] = AnyCodable(values)
		}
		
		return changeset
	}
	
	public static func parseChangeset(_ changeset: ZDCChangeset) -> ZDCChangeset_Struct? {
		
		// changeset: {
		//   refs: AnyCodable({
		//     <key: String> : <changeset: ZDCChangeset>, ...
		//   }),
		//   values: AnyCodable({
		//     <key: String> : <oldValue: ZDCNull|Any>, ...
		//   })
		// }
		
		var refs: [String: ZDCChangeset] = [:]
		var values: [String: Any] = [:]
		
		// refs
		if let wrapped_refs = changeset[ChangesetKeys.refs.rawValue] {
			
			guard let unwrapped_refs = wrapped_refs.value as? [String: ZDCChangeset] else {
				return nil // malformed
			}
			
			refs = unwrapped_refs
		}
		
		// values
		if let wrapped_values = changeset[ChangesetKeys.values.rawValue] {
			
			guard let unwrapped_values = wrapped_values.value as? [String: Any] else {
				return nil // malformed
			}
			
			values = unwrapped_values
		}
		
		// looks good (not malformed)
		return ZDCChangeset_Struct(refs: refs, values: values)
	}
	
	public func parseChangeset(_ changeset: ZDCChangeset) -> ZDCChangeset_Struct? {
		
		return type(of: self).parseChangeset(changeset)
	}
	
	private mutating func _undo(_ changeset: ZDCChangeset_Struct) throws {
		
		for (key, container_changeset) in changeset.refs {
			
			let value = syncableValue(key: key)
			
			if let zdc_obj = value as? ZDCSyncableClass {
				
				try zdc_obj.performUndo(container_changeset)
				
			} else if var zdc_struct = value as? ZDCSyncableStruct {
		
				try zdc_struct.performUndo(container_changeset)
				
				// struct value semantics means we need to write the modified value back to self
				
				if !setSyncableValue(zdc_struct, for: key) {
					
					setSyncableValueFailed(for: key)
				}
				
			} else {
				
				throw ZDCSyncableError.mismatchedChangeset
			}
		}
		
		for (key, oldValue) in changeset.values {
			
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
		
		var orderedParsedChangesets: [ZDCChangeset_Struct] = []
		
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

	public mutating func merge(cloudVersion: ZDCSyncable,
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
		
		var parsedChangesets: [ZDCChangeset_Struct] = []
		
		for changeset in pendingChangesets {
			
			if let parsedChangeset = parseChangeset(changeset) {
				parsedChangesets.append(parsedChangeset)
			} else {
				throw ZDCSyncableError.malformedChangeset
			}
		}
		
		let local_type = type(of: self)
		let cloud_type = type(of: cloudVersion)
		
		if local_type != cloud_type {
			throw ZDCSyncableError.incorrectType
		}
		
		// Step 1 of 3:
		//
		// We need to determine which keys have been changed locally, and what the original versions were.
		// We'll need this information when comparing to the cloudVersion.
		
		var merged_originalValues: [String: Any] = [:]
		
		for parsedChangeset in parsedChangesets {
			
			for (key, oldValue) in parsedChangeset.values {
					
				if merged_originalValues[key] == nil {
					merged_originalValues[key] = oldValue
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
				
				return objA.isEqual?(objB) ?? false
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
		
		for parsedChangeset in parsedChangesets {
			
			for (key, _) in parsedChangeset.refs {
				
				if merged_originalValues[key] == nil {
					
					refs.insert(key)
				}
			}
		}
		
		for key in refs {
			
			let local_value = self.syncableValue(key: key)
			let cloud_value = cloudVersion.syncableValue(key: key)
			
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
				let _ = try local_obj.merge(cloudVersion: cloud_obj, pendingChangesets: pendingChangesets_ref)
			}
			else if var local_struct = local_value as? ZDCSyncableStruct,
			        let cloud_struct = cloud_value as? ZDCSyncableStruct
			{
				let _ = try local_struct.merge(cloudVersion: cloud_struct, pendingChangesets: pendingChangesets_ref)
				
				// struct value semantics means we need to write the modified value back to self
				
				if !setSyncableValue(local_struct, for: key) {
					
					setSyncableValueFailed(for: key)
				}
			}
		}
		
		return self.changeset() ?? [:]
	}
}
