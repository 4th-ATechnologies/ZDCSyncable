/// ZDCSyncable
/// https://github.com/4th-ATechnologies/ZDCSyncable
///
/// Undo, redo & merge capabilities for structs & classes in pure Swift.

#import "ZDCSwiftWorkarounds.h"

@implementation ZDCSwiftWorkarounds

+ (void)throwSyncableException:(nullable Class)class forKey:(NSString *)key
{
	NSString *details;
	if (class) {
		details = [NSString stringWithFormat:@"class = %@, key = %@", NSStringFromClass(class), key];
	} else {
		details = [NSString stringWithFormat:@"key = %@", key];
	}
	
	NSString *reason = [NSString stringWithFormat:
		@"Call to setSyncableProperty(_:for:) failed: %@. Did you remember to implement this function?", details];
	
	NSDictionary *userInfo = @{
		NSLocalizedRecoverySuggestionErrorKey:
			@"Ensure you override the function setSyncableProperty(_:for:) in your subclasses,"
			@" and that you properly handle all syncable properties."
	};
	
	@throw [NSException exceptionWithName:@"ZDCRecordException" reason:reason userInfo:userInfo];
}

@end
