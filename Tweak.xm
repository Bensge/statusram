#import <mach/mach.h>
#import <mach/mach_host.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>



enum StatusBarAlignment
{
	StatusBarAlignmentLeft = 1,
	StatusBarAlignmentRight = 2,
	StatusBarAlignmentCenter = 4
};


// only LSStatusBarItem (API) methods are considered public.

@interface LSStatusBarItem : NSObject
{
@private
	NSString* _identifier;
	NSMutableDictionary* _properties;
	NSMutableSet* _delegates;
	BOOL _manualUpdate;
}

@end


// Supported API

@interface LSStatusBarItem (API)

- (id) initWithIdentifier: (NSString*) identifier alignment: (StatusBarAlignment) alignment;

// bitmasks (e.g. left or right) are not supported yet
@property (nonatomic, readonly) StatusBarAlignment alignment;

@property (nonatomic, getter=isVisible) BOOL visible;

// useful only with left/right alignment - will throw error for center alignment
@property (nonatomic, assign) NSString* imageName;

// useful only with center alignment - will throw error otherwise
// will not be visible on the lockscreen
@property (nonatomic, assign) NSString* titleString;

// set to NO and manually call update if you need to make multiple changes
@property (nonatomic, getter=isManualUpdate) BOOL manualUpdate;

// manually call if manualUpdate = YES
- (void) update;

@end


///////////////////////////////
//Helper stuff
///////////////////////////////

static int freeRam() {
	vm_size_t pageSize;
	host_page_size(mach_host_self(), &pageSize);
	struct vm_statistics vmStats;
	mach_msg_type_number_t infoCount = sizeof(vmStats);
	host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
	int availMem = vmStats.free_count + vmStats.inactive_count;
	return (availMem * pageSize) / 1024 / 1024;
}

////////////////////////////////////////////////////////////////
////////////////////code starts here!///////////////////////////
////////////////////////////////////////////////////////////////



static LSStatusBarItem *ramItem;



@interface SBAwayController : NSObject
-(void)unlockWithSound:(BOOL)sound;
@end


%hook SBAwayController
-(void)unlockWithSound:(BOOL)sound{
	%orig;
	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateFreeRamStatusBarItem) userInfo:nil repeats:YES];
	return;
}


%new(@:@)
-(void)updateFreeRamStatusBarItem{
	if (!ramItem){
		ramItem = [[objc_getClass("LSStatusBarItem") alloc] initWithIdentifier:@"com.bensge.statusram.ramitem" alignment:StatusBarAlignmentCenter];
	}
	[ramItem setTitleString:[NSString stringWithFormat:@"%i mb",freeRam()]];
}

%end






/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
*/
