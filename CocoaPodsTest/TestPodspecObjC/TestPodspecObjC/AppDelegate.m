#import "AppDelegate.h"

#import <ZDCSyncable/ZDCSyncable.h>
#import <ZDCSyncable/ZDCDictionary.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	ZDCDictionary<NSString*, NSString*> *dict = [[ZDCDictionary alloc] init];
	dict[@"foo"] = @"bar";
}

@end
