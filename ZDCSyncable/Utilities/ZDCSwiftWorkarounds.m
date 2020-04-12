/**
 * Syncable
 * https://github.com/4th-ATechnologies/ZDCSyncable
**/

#import "ZDCSwiftWorkarounds.h"

@implementation ZDCSwiftWorkarounds

+ (void *)addressOf:(id)value
{
	if (value)
		return (__bridge void *)(value);
	else
		return 0;
}

+ (void)throwImmutableException:(Class)class
{
	[self throwImmutableException:class forKey:nil];
}

+ (void)throwImmutableException:(Class)class forKey:(nullable NSString *)key
{
	NSString *reason;
	if (key) {
		reason = [NSString stringWithFormat:
		    @"Attempting to mutate immutable object. Class = %@, property = %@", NSStringFromClass(class), key];
	}
	else {
		reason = [NSString stringWithFormat:
		    @"Attempting to mutate immutable object. Class = %@", NSStringFromClass(class)];
	}
	
	NSDictionary *userInfo = @{
		NSLocalizedRecoverySuggestionErrorKey:
			@"To make modifications you should create a copy of the object."
			@" You may then make changes to the copy before saving it back to the database."
	};
	
	@throw [NSException exceptionWithName:@"ZDCSyncableException" reason:reason userInfo:userInfo];
}

+ (void)throwRecordException:(Class)class forKey:(NSString *)key
{
	NSString *reason = [NSString stringWithFormat:
		@"Call to setSyncableProperty(_:for:) failed. Class = %@, property = %@", NSStringFromClass(class), key];
	
	NSDictionary *userInfo = @{
		NSLocalizedRecoverySuggestionErrorKey:
			@"Ensure you override the function setSyncableProperty(_:for:) in your subclasses,"
			@" and that you properly handle all syncable properties."
	};
	
	@throw [NSException exceptionWithName:@"ZDCRecordException" reason:reason userInfo:userInfo];
}

@end
