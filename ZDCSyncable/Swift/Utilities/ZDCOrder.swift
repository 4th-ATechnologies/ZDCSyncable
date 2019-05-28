/**
 * ZDCSyncable
 * <GitHub URL goes here>
**/

import Foundation

enum ZDCOrderError: Error {
	
	case DifferingLengthArrays
	
	case DifferingSetOfItems
}

/// Utility methods for estimating the changes made to an array.
///
public class ZDCOrder {
	
	/// The ZDCSyncable protocol is focused on syncing changes with the cloud.
	/// This gives us a focused set of constraints.
	/// In particular, the cloud does NOT store an ordered list of every change that ever modified an object.
	/// Instead it simply stores the current version of the object.
	///
	/// This can be seen as a tradeoff. It minimizes cloud storage & bandwidth,
	/// in exchange for losing a small degree of information concerning changes to an object.
	///
	/// One difficulty we see with this tradeoff has to do with changes made to an ordered list.
	/// For example, if a list is re-ordered, we don't know the exact items that were moved.
	/// And it's not possible to calculate the information,
	/// as multiple sets of changes could lead to the same end result.
	///
	/// So our workaround is to estimate the changeset as best as possible.
	/// This method performs that task using a simple deterministic algorithm
	/// to arrive at a close-to-minimal changeset.
	///
	/// @note The changeset is generally close-to-minimal, but not guaranteed to be the minimum.
	///       If you're a math genius, you're welcome to try your hand at solving this problem.
	///
	public static func estimateChangeset<T: Equatable>(from src: Array<T>, to dst: Array<T>) throws -> Array<T> {
		
		let count = src.count
		
		// Sanity check #1:
		// The arrays need to have the same count.
		//
		if count != dst.count {
			
			
			// If this is NOT true, we're going to end up with an exception below anyway...
			throw ZDCOrderError.DifferingLengthArrays
		}
		
		// Sanity check #2:
		// The arrays need to have the same set of items.
		//
		do {
			
			var mismatch = false
			var dstCopy = dst
			
			for item in src {
				
				if let idx = dstCopy.firstIndex(of: item) {
					
					dstCopy.remove(at: idx)
				}
				else {
					mismatch = true
					break
				}
			}
			
			if mismatch {
				throw ZDCOrderError.DifferingSetOfItems
			}
		}
		
		// Algorithm:
		//
		// 1. Compare src vs dst, moving from FIRST to LAST (index 0 to index last).
		//    When a difference is discovered, change src by swapping the correct key into place,
		//    and recording the swapped key in changes_firstToLast.
		//
		// 2. Compare src vs dst, moving from LAST to FIRST (index last to index 0).
		//    When a difference is discovered, change src by swapping the correct key into place,
		//    and recording the swapped key in changes_lastToFirst.
		//
		// 3. If the arrays match (changes_x.count == 0), you're done.
		//
		// 4. Otherwise, compare the counts of changes_firstToLast vs change_lastToFirst.
		//    Pick the one with the shortest count.
		//    And execute the first change in its list.
		//
		// 5. Repeat steps 1-4 until done.
		
		var loopSrc = src
		
		var moved_items = Array<T>()
		
		var changes_firstToLast = Array<T>()
		var changes_lastToFirst = Array<T>()
		
		var idx_firstToLast_remove = 0
		var idx_firstToLast_insert = 0
		
		var idx_lastToFirst_remove = 0
		var idx_lastToFirst_insert = 0
		
		var done = false
		repeat {
			
			// Step 1: Compare: First to Last
			do {
				var src = loopSrc
				
				for i in 0 ..< dst.count {
					
					let item_src = src[i]
					let item_dst = dst[i]
					
					if item_src != item_dst {
						
						var idx: Int?
						for s in stride(from: i+1, to: count, by: 1) {
							
							if src[s] == item_dst {
								idx = s
								break
							}
						}
						
						if let idx = idx {
						
							src.remove(at: idx)
							src.insert(item_dst, at: i)
							
							if changes_firstToLast.count == 0 {
								
								idx_firstToLast_remove = idx
								idx_firstToLast_insert = i
							}
							
							changes_firstToLast.append(item_dst)
						}
					}
				}
			}
			
			// Step 2: Compare: Last to First
			//
			if changes_firstToLast.count > 0 {
				
				var src = loopSrc
				
				for j in stride(from: count, to: 0, by: -1) {
					
					let i = j-1
					
					let item_src = src[i]
					let item_dst = dst[i]
					
					if item_src != item_dst {
						
						var idx: Int?
						for s in stride(from: 0, to: i, by: 1) {
							
							if src[s] == item_dst {
								idx = s
								break
							}
						}
						
						if let idx = idx {
							
							src.remove(at: idx)
							src.insert(item_dst, at: i)
						
							if changes_lastToFirst.count == 0 {
								
								idx_lastToFirst_remove = idx
								idx_lastToFirst_insert = i
							}
						
							changes_lastToFirst.append(item_dst)
						}
					}
				}
			}
			else // if (changes_firstToLast.count == 0)
			{
				done = true
			}
			
			if !done {
				
				if (changes_firstToLast.count <= changes_lastToFirst.count)
				{
					let item = changes_firstToLast[0]
					moved_items.append(item)

					loopSrc.remove(at: idx_firstToLast_remove)
					loopSrc.insert(item, at: idx_firstToLast_insert)
				}
				else
				{
					let item = changes_lastToFirst[0]
					moved_items.append(item)

					loopSrc.remove(at: idx_lastToFirst_remove)
					loopSrc.insert(item, at: idx_lastToFirst_insert)
				}

				changes_firstToLast.removeAll()
				changes_lastToFirst.removeAll()
			}
			
		} while (!done)
		
		return moved_items
	}
}
