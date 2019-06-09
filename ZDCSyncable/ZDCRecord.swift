/**
 * Syncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

import Foundation

/**
 * The ZDCRecord class is designed to be subclassed.
 *
 * It provides the following set of features for your subclass:
 * - instances can be made immutable (via `ZDCObject.makeImmutable()` function)
 * - it implements the ZDCSyncable protocol and thus:
 * - it tracks all changes and can provide a changeset (which encodes the changes info)
 * - it supports undo & redo
 * - it supports merge operations
 */
open class ZDCRecord: ZDCObject, ZDCSyncable {
	
	enum ChangesetKeys: String {
		case refs = "refs"
		case values = "values"
	}
	
	lazy private var originalValues: Dictionary<String, Any> = Dictionary()
	
	public required init() {
		super.init()
	}
	
	public required init(copy source: ZDCObject) {
		
		if let source = source as? ZDCRecord {
			
			super.init()
			self.originalValues = source.originalValues
		}
		else {
			
			fatalError("init(copy:) invoked with invalid source")
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	open func enumerateProperties(_ block: (_ propertyName: String, _ value: Any?) -> Void) {
		
		let propertyNames = self.monitoredProperties()
		for propertyName in propertyNames {
			
			let value = self.value(forKey: propertyName)
			block(propertyName, value)
		}
		
		var _mirror: Mirror? = Mirror(reflecting: self)
		while let mirror = _mirror {
		
			if mirror.subjectType == ZDCRecord.self {
				break
			}
			
			for property in mirror.children {
		
				if let label = property.label, !propertyNames.contains(label) {
		
					if let zdc_value = property.value as? ZDCSyncable {
		
						block(label, zdc_value)
					}
		
				//	if case Optional<Any>.some(let value) = property.value {
				//		// property.value is not nil
				//		block(label, value)
				//	}
				//	else {
				//		// property.value is nil
				//		block(label, nil)
				//	}
				}
			}
		
			_mirror = mirror.superclassMirror
		}
	}
	
	override open func value(forKey key: String) -> Any? {

		let propertyNames = self.monitoredProperties()
		if propertyNames.contains(key) {
			return super.value(forKey: key)
		}
		
		var _mirror: Mirror? = Mirror(reflecting: self)
		while let mirror = _mirror {
			
			if mirror.subjectType == ZDCRecord.self {
				break
			}
			
			for property in mirror.children {
				
				if let label = property.label {
					
					if label == key {
						
						if let zdc_value = property.value as? ZDCSyncable {
							
							return zdc_value
						}
					}
				}
			}
			
			_mirror = mirror.superclassMirror
		}
		
		return super.value(forKey: key) // Crash? Did you forget to add required "@objc"?
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: ZDCObject Overrides
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	override open func makeImmutable() {
		
		super.makeImmutable()
		
		self.enumerateProperties { (propertyName, value) in
		
			if let zdc_value = value as? ZDCObject {
				zdc_value.makeImmutable()
			}
		}
	}
	
	override open var hasChanges: Bool {
		get {
			if super.hasChanges {
				return true
			}
			
			if originalValues.count > 0 {
				return true
			}
			
			var hasChanges = false
			self.enumerateProperties { (propertyName, value) in
				
				if let zdc_value = value as? ZDCObject {
					if zdc_value.hasChanges {
						hasChanges = true
					}
				}
			}
			
			return hasChanges
		}
	}

	override open func clearChangeTracking() {
		
		super.clearChangeTracking()
		
		originalValues.removeAll()
		
		self.enumerateProperties { (propertyName, value) in
			
			if let zdc_value = value as? ZDCObject {
				zdc_value.clearChangeTracking()
			}
		}
	}
	
	/// ZDCObject hook - notifies us that a property is being changed
	///
	override func _willChangeValue(forKey key: String) {
		
		if originalValues[key] == nil {
			
			let originalValue = self.value(forKey: key)
			if originalValue != nil {
				originalValues[key] = originalValue!
			}
			else {
				originalValues[key] = ZDCNull.sharedInstance()
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
		
		var changeset = Dictionary<String, Any>()
		
		// changeset: {
		//   refs: {
		//     key: changeset, ...
		//   },
		//   ...
		// }
		
		var refs = Dictionary<String, Any>()
		
		self.enumerateProperties { (key, value) in
			
			if let zdcValue = value as? ZDCSyncable {
				
				let originalValue = originalValues[key]
				let originalZdcValue = originalValue as? ZDCSyncable
				
				let obj = value as? NSObject
				let originalObj = originalValue as? NSObject
				
				// Several possibilities:
				//
				// - If obj was added, then originalValue will be ZDCNull.
				//   If this is the case, we should not add to refs.
				//
				// - If obj was swapped out, then originalValue will be some other obj.
				//   If this is the case, we should not add to refs.
				//
				// - If obj was simply modified, then originalValue wll be the same as obj.
				//   And only then should we add a changeset to refs.
		
				let wasAdded: Bool = originalValue is ZDCNull
				let wasSwapped: Bool = (originalZdcValue != nil) &&
				                       (originalObj != nil) && (obj != nil ) && (originalObj! !== obj!)
			
				if (!wasAdded && !wasSwapped)
				{
					var obj_changeset = zdcValue.peakChangeset()
					if (obj_changeset == nil)
					{
						let wasModified = originalValue != nil
						if (wasModified) {
							obj_changeset = Dictionary()
						}
					}
					
					if (obj_changeset != nil) {
						refs[key] = obj_changeset!;
					}
				}
			}
		}
		
		if (refs.count > 0) {
			changeset[ChangesetKeys.refs.rawValue] = refs
		}
		
		if originalValues.count > 0 {
			
			// changeset: {
			//   values: {
			//     key: oldValue, ...
			//   },
			//   ...
			// }
			
			var values = Dictionary<String, Any>()
			
			for (key, originalValue) in originalValues {
				
				if (refs[key] != nil) {
					values[key] = ZDCRef.sharedInstance()
				}
				else {
					values[key] = originalValue
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
		//     <key: Any> : <changeset: Dictionary>, ...
		//   },
		//   values: {
		//     <key: NSString*> : <oldValue: ZDCNull|ZDCRef|Any>, ...
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
		
			for (key, obj_changeset) in changeset_refs {
				
				let obj = self.value(forKey: key) // Crash? Is your property missing required "@objc"?
				
				if let zdc_obj = obj as? ZDCSyncable {
				
					try zdc_obj.performUndo(obj_changeset)
				}
				else
				{
					throw ZDCSyncableError.mismatchedChangeset
				}
			}
		}
		
		if let changeset_values = changeset[ChangesetKeys.values.rawValue] as? Dictionary<String, Any> {
			
			for (key, oldValue) in changeset_values {
				
				if (oldValue is ZDCNull) {
					self.setValue(nil, forKey: key)
				}
				else if !(oldValue is ZDCRef) {
					self.setValue(oldValue, forKey: key)
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
							pendingChangesets: Array<Dictionary<String, Any>>) throws -> Dictionary<String, Any>
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
		
		guard let cloudVersion = inCloudVersion as? ZDCRecord else {
			throw ZDCSyncableError.incorrectObjectClass
		}
		
		// Step 1 of 4:
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
		
		// Step 2 of 4:
		//
		// Next, we're going to enumerate what values are in the cloud.
		// This will tell us what was added & modified by remote devices.
		
		let IsEqualOrBothNil = {(_ objA: Any?, _ objB: Any?) -> Bool in
			
			if (objA == nil)
			{
				return (objB == nil)
			}
			else if (objB == nil)
			{
				return false
			}
			else
			{
				let a = objA as AnyObject
				let b = objB as AnyObject
				
				return a.isEqual(b)
			}
		}
		
		cloudVersion.enumerateProperties({ (key, cloudValue) in
			
			let currentLocalValue = self.value(forKey: key)
			var originalLocalValue = merged_originalValues[key]
			
			let modifiedValueLocally = (originalLocalValue != nil)
			if originalLocalValue is ZDCNull {
				originalLocalValue = nil
			}
			
			if (!modifiedValueLocally && (currentLocalValue is ZDCSyncable) && (cloudValue is ZDCSyncable))
			{
				// continue - handled by refs
				return; // from block
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
				self.setValue(cloudValue, forKey: key)
			}
		})
		
		// Step 3 of 4:
		//
		// Next we need to determine if any values were deleted by remote devices.
		do {
			
			var baseKeys = self.monitoredProperties()
			
			for (key, value) in merged_originalValues {
				
				if value is ZDCNull {    // Null => we added this tuple.
					baseKeys.remove(key)  // So it's not part of the set the cloud is expected to have.
				} else {
					baseKeys.insert(key)  // For items that we may have deleted (no longer in [self allKeys])
				}
			}
			
			for key in baseKeys {
				
				let remoteValue = cloudVersion.value(forKey: key)
				if remoteValue == nil {
					
					// The remote key/value pair was deleted
					
					self.setValue(nil, forKey: key)
				}
			}
		}
		
		// Step 4 of 4:
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
			
			let localRef = self.value(forKey: key)
			let cloudRef = cloudVersion.value(forKey: key)
			
			if let localRef = localRef as? ZDCSyncable,
			   let cloudRef = cloudRef as? ZDCSyncable
			{
				var pendingChangesets_ref = Array<Dictionary<String, Any>>()
				pendingChangesets_ref.reserveCapacity(pendingChangesets.count)
				
				for changeset in pendingChangesets {
					
					let changeset_refs = changeset[ChangesetKeys.refs.rawValue] as? Dictionary<String, Dictionary<String, Any>>
					let changeset_ref = changeset_refs?[key]
					
					if let changeset_ref = changeset_ref {
						
						pendingChangesets_ref.append(changeset_ref)
					}
				}
				
				let _ = try localRef.merge(cloudVersion: cloudRef, pendingChangesets: pendingChangesets_ref)
			}
		}
		
		return (self.changeset() ?? Dictionary())
	}
}
