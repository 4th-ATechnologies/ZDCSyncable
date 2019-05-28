/**
 * Syncable
 * <GitHub URL goes here>
**/

import Foundation

/**
 * ZDCObject is a simple base class with a small, but very useful, set of functionality:
 *
 * - an object can be made immutable, via the `makeImmutable` method
 * - once immutable, attempts to change properties on the object will throw an exception
 *
 * You may even find it useful outside the context of syncing.
 */
open class ZDCObject: NSObject, NSCopying {

	private var _isImmutable: Bool = false
	private var _observerContext: UnsafeMutableRawPointer?
	
	private var _hasChanges: Bool = false
	private var _monitoredProperties: Set<String>?
	
	required override public init() {
		super.init()
		
		// Turn on KVO for object.
		// We do this so we can get notified if the user is about to make changes to one of the object's properties.
		//
		// Don't worry, this doesn't create a retain cycle.
		//
		// Note: It's important use a unique observer context.
		// We've seen several related crashes on iOS 11.
		//
		// https://forums.developer.apple.com/thread/70097
		// https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOBasics.html
		
		_observerContext = UnsafeMutableRawPointer(ZDCSwiftWorkarounds.address(of: self));
		
		self.addObserver(self, forKeyPath: "isImmutable",
		                          options: NSKeyValueObservingOptions(rawValue: 0),
		                          context: _observerContext)
	}
	
	deinit {
		if _observerContext != nil {
			self.removeObserver(self, forKeyPath: "isImmutable", context: _observerContext)
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: NSCopying
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public func copy(with zone: NSZone? = nil) -> Any {
		
		// Subclasses should call this method via super.copy(with: zone)
		// For example:
		//
		//   var copy: MySubclass = super.copy(with: zone)
		//   copy.ivar1 = ivar1
		//   copy.ivar2 = ivar2
		//   return copy
		
		let copy = type(of: self).init()
		copy._isImmutable = false
		copy._hasChanges = _hasChanges
		
		return copy
	}
	
	public func immutableCopy() -> Any {
		let copy: ZDCObject = self.copy() as! ZDCObject
		
		// This code is wrong:
	//	copy.isImmutable = true
		//
		// Because the `makeImmutable` method may be overriden by subclasses,
		// and we need to go through this method for proper immutability.
		//
		copy.makeImmutable()
		
		return copy
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Class Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	/// This method returns a list of all properties that should be monitored.
	/// That is, properties that should be considered immutable once makeImmutable() has been invoked.
	///
	/// By default this method returns a list of all properties in each subclass in the
	/// hierarchy leading up to ZDCObject.
	///
	/// However, this is not always exactly what you want.
	/// For example, you may have properties which are simply used for caching:
	///
	/// ```
	/// public var avatarImage: UIImage
	/// public var cachedTransformedAvatarImage: UIImage
	/// ```
	///
	/// In this example, you store the user's plain avatar image.
	/// However, your code transforms the avatar in various ways for display in the UI.
	/// So to reduce overhead, you'd like to cache these transformed images in the user object.
	/// Thus the 'cachedTransformedAvatarImage' property doesn't actually mutate the user object.
	/// It's just a temp cache.
	///
	/// So your subclass would override this method like so:
	///
	/// ```
	/// override class func monitoredProperties() -> Set<String> {
	///
	///   Set<String> monitoredProperties = super.monitoredProperties()
	///   monitoredProperties.remove("cachedTransformedAvatarImage")
	///
	///   return monitoredProperties
	/// }
	/// ```
	///
	open class func monitoredProperties() -> Set<String> {
		
		var properties: Set<String> = Set.init()
		
		let rootClass: AnyClass = ZDCObject.self
		var subClass: AnyClass = self
		
		while (subClass != rootClass)
		{
			var propertyListCount: UInt32 = 0
			let propertyList: UnsafeMutablePointer<objc_property_t>? = class_copyPropertyList(subClass, &propertyListCount)

			if let propertyList = propertyList {

				for i in (0..<propertyListCount) {

					let cName: UnsafePointer<Int8> = property_getName(propertyList[Int(i)])
					let propertyName = String(cString: cName)
					
					properties.insert(propertyName)
				}
				
				free(propertyList)
			}
			
			subClass = subClass.superclass()!
		}
		
		return properties
	}
	
	/**
	 * Generally you should NOT override this function.
	 * Just override the class version of this function (above).
	 */
	public func monitoredProperties() -> Set<String> {
		
		if let monitoredProperties = _monitoredProperties {
			return monitoredProperties
		}

		_monitoredProperties = type(of: self).monitoredProperties();
		return _monitoredProperties!
	}
	
	/**
	 * Override this method if your class includes 'dynamic' monitored properties.
	 * That is, properties that should be monitored, but don't have dedicated property declarations.
	 *
	 * - Important:
	 *     If a property (localKey) is not included in the 'monitoredProperties' set,
	 *     then the class will be unable to automatically register for KVO notifications concerning the value.
	 *     This means that you MUST manually invoke [self willChangeValueForKey:] & [self didChangeValueForKey:],
	 *     in order to run the code for the corresponding methods in this class.
	 */
	public func isMonitoredProperty(_ key: String) -> Bool {
	
		return self.monitoredProperties().contains(key);
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Immutability
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public var isImmutable : Bool {
		get {
			return _isImmutable;
		}
	}
	
	public func makeImmutable() {
		
		if !_isImmutable {
			// Set immutable flag
			_isImmutable = true
		}
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Monitoring
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	public var hasChanges: Bool {
		get {
			return _hasChanges
		}
	}
	
	public func clearChangeTracking() {
		
		_hasChanges = false
	}
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: KVO
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	override open class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
		if key == "isImmutable" {
			return true
		}
		else {
			return super.automaticallyNotifiesObservers(forKey: key)
		}
	}
	
	override open class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {

		// In order for the KVO magic to work, we specify that the isImmutable property is dependent
		// upon all other properties in the class that should become immutable.
		//
		// The code below ** attempts ** to do this automatically.
		// It does so by creating a list of all the properties in the class.
		//
		// Obviously this will not work for every situation.
		// In particular:
		//
		// - if you have custom setter methods that aren't specified as properties
		// - if you have other custom methods that modify the object
		//
		// To cover these edge cases, simply add code like the following at the beginning of such methods:
		//
		// func recalculateFoo() {
		//     if (self.isImmutable) {
		//         @throw [self immutableExceptionForKey:@"foo"];
		//     }
		//
		//     // ... normal code that modifies foo ivar ...
		// }

		if key == "isImmutable" {
			return self.monitoredProperties()
		}
		else {
			return super.keyPathsForValuesAffectingValue(forKey: key)
		}
	}
	
	override open func observeValue(forKeyPath keyPath: String?,
	                                           of object: Any?,
	                                              change: [NSKeyValueChangeKey : Any]?,
	                                             context: UnsafeMutableRawPointer?)
	{
		// Nothing to do (but function is required to exist)
	}
	
	override open func willChangeValue(forKey key: String) {
		
		if self.isMonitoredProperty(key) {
			
			if _isImmutable {
				ZDCSwiftWorkarounds.throwImmutableException(type(of: self), forKey: key)
			}
			
			self._willChangeValue(forKey: key)
		}
		
		super.willChangeValue(forKey: key)
	}
	
	func _willChangeValue(forKey key: String) {
		
		// Subclass hook - Override me
	}
	
	override open func didChangeValue(forKey key: String) {
		
		if self.isMonitoredProperty(key) {
			
			if !_hasChanges {
				_hasChanges = true
			}
			
			self._didChangeValue(forKey: key)
		}
		
		super.didChangeValue(forKey: key)
	}
	
	func _didChangeValue(forKey key: String) {
		
		// Subclass hook - Override me
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: NSCoding Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	private static let kPlistKey_Version        = "version"
	private static let kPlistKey_BookmarkData   = "bookmarkData"
	private static let kPlistKey_PathComponents = "pathComponents"
	
	public class func serializeFileURL(_ fileURL: URL) -> Data? {
	
		var bookmarkData: Data? = nil
		do {
			bookmarkData = try fileURL.bookmarkData(options: URL.BookmarkCreationOptions.suitableForBookmarkFile,
			                 includingResourceValuesForKeys: nil,
			                                     relativeTo: nil)
		} catch {}
	
		if bookmarkData != nil {
			return bookmarkData
		}
		
		// Failed to create bookmark data.
		// This is usually because the file doesn't exist.
		// As a backup plan, we're going to get a bookmark of the closest parent directory that does exist.
		// And combine it with the relative path after that point.
		
		if !fileURL.isFileURL {
			return nil
		}
		
		var lastURL: URL = fileURL
		var parentURL: URL = lastURL.deletingLastPathComponent()
		
		var pathComponents: [String] = []
		pathComponents.append(lastURL.lastPathComponent)
		
		while parentURL != lastURL {
			
			do {
				bookmarkData = try parentURL.bookmarkData(options: URL.BookmarkCreationOptions.suitableForBookmarkFile,
				                   includingResourceValuesForKeys: nil,
				                                       relativeTo: nil)
			} catch {}
			
			if (bookmarkData != nil) {
				break;
			}
			else
			{
				lastURL = parentURL;
				parentURL = lastURL.deletingLastPathComponent()
				
				pathComponents.append(lastURL.lastPathComponent)
			}
		}
		
		if bookmarkData != nil {
			
			let plistDict: [String : Any] = [
				kPlistKey_Version: 1,
				kPlistKey_BookmarkData: bookmarkData!,
				kPlistKey_PathComponents: pathComponents
			]
			
			var plistData: Data? = nil
			do {
				plistData = try PropertyListSerialization.data(
				                  fromPropertyList: plistDict,
				                            format: PropertyListSerialization.PropertyListFormat.binary,
				                           options: 0)
			} catch {}
			
			return plistData;
		}
		else {
			return nil
		}
	}
	
	public class func deserializeFileURL(fromData data: Data) -> URL? {
		
		if data.count == 0 {
			return nil
		}
		
		var isBookmarkData: Bool = false
		var isPlistData: Bool = false
		
		if (!isBookmarkData)
		{
			let magic: Data? = "book".data(using: String.Encoding.ascii)
			
			if (magic != nil) && (data.count > magic!.count) {
				isBookmarkData = data.starts(with: magic!)
			}
		}
		
		if (!isBookmarkData)
		{
			let magic: Data? = "bplist".data(using: String.Encoding.ascii)
			
			if (magic != nil) && (data.count > magic!.count) {
				isPlistData = data.starts(with: magic!)
			}
		}
		
		let isUnknown: Bool = !isBookmarkData && !isPlistData
		
		if isBookmarkData || isUnknown {
			
			var url: URL? = nil
			do {
				var ignore: Bool = false
				url = try URL.init(resolvingBookmarkData: data,
				                                 options: URL.BookmarkResolutionOptions.withoutUI,
				                              relativeTo: nil,
				                     bookmarkDataIsStale: &ignore)
				
			} catch {}
			
			if url != nil {
				return url;
			}
		}
		
		if isPlistData || isUnknown {
			
			var plistObj: Any? = nil
			do {
				plistObj = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
				
			} catch {}
			
			if let plistObj = plistObj as? Dictionary<String, Any> {
				
				let data: Any? = plistObj[kPlistKey_BookmarkData]
				let comp: Any? = plistObj[kPlistKey_PathComponents]
				
				if let data = data as? Data, let comp = comp as? Array<String> {
					
					var url: URL? = nil
					do {
						var ignore: Bool = false
						url = try URL.init(resolvingBookmarkData: data,
						                                 options: URL.BookmarkResolutionOptions.withoutUI,
						                              relativeTo: nil,
						                     bookmarkDataIsStale: &ignore)
					} catch {}
					
					if let url = url {
						
						let path = comp.joined(separator: "/")
						
						return URL.init(string: path, relativeTo: url)
					}
				}
			}
		}
	
		return nil
	}
}
