/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & objects in pure Swift.

import Foundation

/// The typealias is used internally to explicitly differentiate between structs vs class instances.
///
typealias ZDCSyncableStruct = ZDCSyncable

/// The ZDCSyncable protocol defines the common methods for:
/// - tracking changes
/// - performing undo & redo
/// - merging changes from external sources
/// 
public protocol ZDCSyncable {
	
	/**
	 * Returns whether or not there are any changes to the object.
	 */
	var hasChanges: Bool { get }
	
	/**
	 * Resets the hasChanges property to false, and clears all internal change tracking information.
	 * Use this to wipe the slate, and restart change tracking from the current state.
	 */
	mutating func clearChangeTracking()
	
	/**
	 * Returns a changeset that contains information about changes that were made to the object.
	 *
	 * This changeset can then be used to undo the changes (via the `undo::` method).
	 * If syncing the object to the cloud, this changeset may be needed to
	 * properly merge local & remote changes.
	 *
	 * The changeset will inclue all changes since the last time either
	 * `changeset` or `clearChangeTracking()` was called.
	 *
	 * - Note:
	 *     This method is the equivalent of calling `peakChangeset`
	 *     followed by `clearChangeTracking()`.
	 *
	 * - Note:
	 *     If you simply want to know if an object has changes,
	 *     use the `hasChanges` property.
	 *
	 * - Return:
	 *     A changeset dictionary, or nil if there are no changes.
	 */
	mutating func changeset() -> Dictionary<String, Any>?
	
	/**
	 * Returns the current changeset without clearing the changes from the object.
	 * This is primarily used for debugging.
	 *
	 * - Note:
	 *     If you simply want to know if an object has changes,
	 *     use the `hasChanges()` property.
	 *
	 * - Returns:
	 *     A changeset dictionary, or nil if there are no changes.
	 */
	func peakChangeset() -> Dictionary<String, Any>?
	
	/**
	 * Moves the state of the object backwards in time, undoing the changes represented in the changeset.
	 *
	 * If an error occurs when attempting to undo the changes, then the undo attempt is aborted,
	 * and the previous state of the object will be restored.
	 *
	 * - Note:
	 *     This method is the equivalent of calling `performUndo()`
	 *     followed by `changeset()`, and returning that changeset.
	 *
	 * - Parameter changeset:
	 *     A valid changeset previously returned via the `changeset` function.
	 *
	 * - Returns:
	 *     A changeset dictionary if the undo was successful (which can be used to redo the changes).
	 *     Otherwise throws with an error explaining what went wrong.
	 */
	mutating func undo(_ changeset: Dictionary<String, Any>) throws -> Dictionary<String, Any>

	/**
	 * Moves the state of the object backwards in time, undoing the changes represented in the changeset.
	 *
	 * If an error occurs when attempting to undo the changes, then the undo attempt is aborted,
	 * and the previous state of the object will be restored.
	 *
	 * - Parameter changeset:
	 *     A valid changeset previously returned via the `changeset` method.
	 *
	 * - Returns:
	 *     Returns nil on success, otherwise returns an error explaining what went wrong.
	 */
	mutating func performUndo(_ changeset: Dictionary<String, Any>) throws
	
	/**
	 * Performs an undo for all changes that have occurred since the last time either
	 * `changeset` or `clearChangeTracking` was called.
	 */
	mutating func rollback()
	
	/**
	 * This method is used to merge multiple changesets.
	 *
	 * You pass in an ordered list of changesets, and when the method completes:
	 * - the state of the object is the same as it was before
	 * - a changeset is returned which represents a consolidated version of the given list
	 *
	 * - Note:
	 *     This method is the equivalent of calling `importChangesets:`
	 *     followed by `changeset`, and returning that changeset.
	 *
	 * - Parameter orderedChangesets:
	 *     An ordered list of changesets, with oldest at index 0.
	 *
	 * - Returns
	 *     On success, returns a changeset dictionary which represents a
	 *     consolidated version of the given list.
	 *     Otherwise throws with an error explaining what went wrong.
	 */
	mutating func mergeChangesets(_ orderedChangesets: Array<Dictionary<String, Any>>)
		throws -> Dictionary<String, Any>
	
	/**
	 * This method is used to merge multiple changesets.
	 *
	 * You pass in an ordered list of changesets, and when the method completes:
	 * - the state of the object is the same as it was before
	 * - but calling `hasChanges` will now return YES
	 * - and calling `changeset` will now return a merged changeset
	 *
	 * - Parameter orderedChangesets:
	 *     An ordered list of changesets, with oldest at index 0.
	 */
	mutating func importChangesets(_ orderedChangesets: Array<Dictionary<String, Any>>) throws
	
	/**
	 * - Returns:
	 *     On success, returns a changeset dictionary that can be used to undo the changes.
	 *     Otherwise throws with an error explaining what went wrong.
	 */
	mutating func merge(cloudVersion: ZDCSyncable,
	               pendingChangesets: Array<Dictionary<String, Any>>)
		throws -> Dictionary<String, Any>
	
	
	/// The process of undo/redo may require updating collections (which are structs, with value semantics).
	/// For example:
	/// ```
	/// struct Foobar: ZDCSyncable {
	///     var dict: ZDCDictionary<String, Float>
	/// }
	/// ```
	///
	/// When methods such as undo need to apply changes to something like a ZDCDictionary,
	/// the method will invoke setSyncableValue(_:for:) in order to apply a change.
	///
	/// You must implement this function IFF you have ZDCSyncable properties such as:
	/// - ZDCDictionary
	/// - ZDCOrderedDictionary
	/// - ZDCSet
	/// - ZDCOrderedSet
	/// - ZDCArray
	/// 
	mutating func setSyncableValue(_ value: Any?, for key: String) -> Bool
}
