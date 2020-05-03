/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

import Foundation

/// Provides default implementations for some protocol functions.
///
extension ZDCSyncable {
	
	public mutating func changeset() -> ZDCChangeset? {
		
		let changeset = self.peakChangeset()
		self.clearChangeTracking()
		
		return changeset
	}
	
	public mutating func undo(_ changeset: ZDCChangeset) throws -> ZDCChangeset {
		
		try self.performUndo(changeset)
		
		// Undo successful - generate redo changeset
		let reverseChangeset = self.changeset()
		return reverseChangeset ?? [:]
	}
	
	public mutating func rollback() {
		
		if let changeset = self.changeset() {
			
			do {
				let _ = try self.undo(changeset)
				
			} catch {
				// Ignoring errors here.
				// There's nothing we can do at this point - we're in a bad state.
			}
		}
	}
	
	public mutating func mergeChangesets(_ orderedChangesets: [ZDCChangeset])
		throws -> ZDCChangeset
	{
		try self.importChangesets(orderedChangesets)
		
		let mergedChangeset = self.changeset()
		return mergedChangeset ?? Dictionary()
	}
	
	/// See description in ZDCSyncable.swift
	///
	public mutating func setSyncableValue(_ value: Any?, for key: String) -> Bool {
		//
		// Do NOT change this code !
		return false
		//
		// You MUST property implement this method within your own struct !
	}
}
