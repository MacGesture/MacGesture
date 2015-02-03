//
//  MenuController.m
//  MouseGesture
//
//  Created by keakon on 11-11-18.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import "MenuController.h"
#import "AppDelegate.h"

@implementation MenuController

@synthesize statusMenu;

static LSSharedFileListItemRef itemRefInLoginItems() {
	LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItemsRef == NULL) {
		return NULL;
	}
	
	LSSharedFileListItemRef itemRef = NULL;
	CFURLRef itemUrlRef = NULL;
	NSURL *appUrl = [NSURL fileURLWithPath:NSBundle.mainBundle.bundlePath];
	CFArrayRef loginItems = LSSharedFileListCopySnapshot(loginItemsRef, NULL);
	CFIndex length = CFArrayGetCount(loginItems);
	for (CFIndex i = 0; i < length; ++i) {
		LSSharedFileListItemRef currentItemRef = (LSSharedFileListItemRef)CFArrayGetValueAtIndex(loginItems, i);
		if (LSSharedFileListItemResolve(currentItemRef, 0, &itemUrlRef, NULL) == noErr) {
			if ([(NSURL *)itemUrlRef isEqual:appUrl]) {
				CFRelease(itemUrlRef);
				itemRef = currentItemRef;
				CFRetain(itemRef);
				break;
			}
			CFRelease(itemUrlRef);
		}
	}
	
	CFRelease(loginItems);
	CFRelease(loginItemsRef);
	
	return itemRef;
}

- (void)awakeFromNib {
	statusItem = [[NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength] retain];
	NSBundle *bundle = NSBundle.mainBundle;
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"enable" ofType:@"png"]];
	statusItem.image = image;
	[image release];
	image = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"highlight" ofType:@"png"]];
	statusItem.alternateImage = image;
	[image release];
	statusItem.menu = statusMenu;
	statusItem.toolTip = @"Mouse Gesture";
	statusItem.highlightMode = YES;

	toggleEnableItem = [statusMenu itemAtIndex:0];
	toggleEnableItem.state = NSOnState;

	toggleLaunchAtStartupItem = [statusMenu itemAtIndex:1];
	LSSharedFileListItemRef itemRef = itemRefInLoginItems();
	if (itemRef != NULL) {
		CFRelease(itemRef);
		isLaunchAtStartup = true;
		toggleLaunchAtStartupItem.state = NSOnState;
	} else {
		toggleLaunchAtStartupItem.state = NSOffState;
	}
}

- (void)dealloc {
	[super dealloc];
	[statusMenu release];
	[statusItem release];
}

- (IBAction)toggleEnable:(id)sender {
	BOOL isEnable = [(AppDelegate *)NSApplication.sharedApplication.delegate toggleEnable];
	toggleEnableItem.state = isEnable ? NSOnState : NSOffState;
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:[NSBundle.mainBundle pathForResource:isEnable ? @"enable" : @"disable" ofType:@"png"]];
	statusItem.image = image;
	[image release];
}

- (IBAction)toggleLaunchAtStartup:(id)sender {
	LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItemsRef == NULL) {
		return;
	}
	
	isLaunchAtStartup = !isLaunchAtStartup;
	if (isLaunchAtStartup) {
		CFURLRef appUrl = (CFURLRef)[NSURL fileURLWithPath:NSBundle.mainBundle.bundlePath];
		LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, appUrl, NULL, NULL);
		CFRelease(itemRef);
	} else {
		LSSharedFileListItemRef itemRef = itemRefInLoginItems();
		if (itemRef != NULL) {
			LSSharedFileListItemRemove(loginItemsRef, itemRef);
			CFRelease(itemRef);
		}
	}
	CFRelease(loginItemsRef);
	toggleLaunchAtStartupItem.state = isLaunchAtStartup ? NSOnState : NSOffState;
}

@end
