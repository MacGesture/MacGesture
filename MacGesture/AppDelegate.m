//
//  AppDelegate.m
//  MouseGesture
//
//  Created by keakon on 11-11-9.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//
#include <Carbon/Carbon.h>
#import "AppDelegate.h"
#import "CanvasWindowController.h"

@implementation AppDelegate


typedef struct {
	UniCharCount length;
	UniChar *string;
} UnicodeStruct;

static CanvasWindowController *windowController;
static CGEventRef mouseDownEvent, mouseDraggedEvent;
static const unsigned int MAX_DIRECTIONS = 128;

static char directionstr[MAX_DIRECTIONS] = "";

static NSPoint lastLocation;
static CFMachPortRef mouseEventTap;
static bool isEnable;

static inline pid_t getFrontProcessPID() {
	ProcessSerialNumber psn;
	pid_t pid;
	if (GetFrontProcess(&psn) == noErr && GetProcessPID(&psn, &pid) == noErr) {
		return pid;
	}
	return -1;
}

static inline NSString *getFrontProcessName() {
	ProcessSerialNumber psn;
	CFStringRef nameRef;
	if (GetFrontProcess(&psn) == noErr && CopyProcessName(&psn, &nameRef) == noErr) {
		NSString *name = [[(NSString *)nameRef copy] autorelease];
		CFRelease(nameRef);
		return name;
	}
	return nil;
}


static inline void pressKey(CGKeyCode virtualKey) {
	CGEventRef event = CGEventCreateKeyboardEvent(NULL, virtualKey, true);
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
	
	event = CGEventCreateKeyboardEvent(NULL, virtualKey, false);
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
}

static inline void pressKeyWithFlags(CGKeyCode virtualKey, CGEventFlags flags) {
	CGEventRef event = CGEventCreateKeyboardEvent(NULL, virtualKey, true);
	CGEventSetFlags(event, flags);
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
	
	event = CGEventCreateKeyboardEvent(NULL, virtualKey, false);
	CGEventSetFlags(event, flags);
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
}

static inline void typeSting(UnicodeStruct *unicodeStruct) {
	CGEventRef event = CGEventCreateKeyboardEvent(NULL, 0, true);
	CGEventKeyboardSetUnicodeString(event, unicodeStruct->length, unicodeStruct->string);
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
	
	event = CGEventCreateKeyboardEvent(NULL, 0, false); // not sure whether it's needed
	CGEventKeyboardSetUnicodeString(event, unicodeStruct->length, unicodeStruct->string);
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
}


static void updateDirections(NSEvent* event) {
	// not thread safe
	NSPoint newLocation = event.locationInWindow;
	float deltaX = newLocation.x - lastLocation.x;
	float deltaY = newLocation.y - lastLocation.y;
	float absX = fabs(deltaX);
	float absY = fabs(deltaY);
	if (absX + absY < 20) {
        
		return; // ignore short distance
	}
	
    unsigned long length = strlen(directionstr);
	if (length == MAX_DIRECTIONS - 1) {
		return; // ignore more directions
	}
    char lastDirectionChar = directionstr[length-1];

#define MAYBE(x) if (lastDirectionChar != x[0]) {strcat(directionstr,x);return;}
	if (absX > absY) {
		if (deltaX > 0) {
            MAYBE("R");
		} else{
            MAYBE("L");
        }
	} else {
		if (deltaY > 0) {
            MAYBE("U");
        } else {
            MAYBE("D");
        }
	}
}

static bool handleGesture() {
	// not thread safe

#define IF_DIR(x) if(strcmp(directionstr,x) == 0)
    
    IF_DIR("UR"){   // switch right tab
        pressKeyWithFlags(kVK_ANSI_RightBracket, kCGEventFlagMaskShift | kCGEventFlagMaskCommand);
        return true;
    }
    IF_DIR("UL"){   // switch left tab
        pressKeyWithFlags(kVK_ANSI_LeftBracket, kCGEventFlagMaskShift | kCGEventFlagMaskCommand);
        return true;
    }
    IF_DIR("DR"){   // close tab
        pressKeyWithFlags(kVK_ANSI_W, kCGEventFlagMaskCommand);
        return true;
    }
    IF_DIR("DL"){   // toggle maxize
        pressKeyWithFlags(kVK_ANSI_F, kCGEventFlagMaskCommand | kCGEventFlagMaskControl);
        return true;
    }
    
    IF_DIR("L"){
        pressKeyWithFlags(kVK_LeftArrow, kCGEventFlagMaskCommand);
        return true;
    }
    
    IF_DIR("R"){
        pressKeyWithFlags(kVK_RightArrow, kCGEventFlagMaskCommand);
        return true;
    }
    
#undef IF_DIR
    return false;
}

static CGEventRef mouseEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
	// not thread safe, but it's always called in main thread
	NSEvent *mouseEvent;
	switch (type) {
		case kCGEventRightMouseDown:
			if (mouseDownEvent) { // mouseDownEvent may not release when kCGEventTapDisabledByTimeout
                strcpy(directionstr,"");
				CGPoint location = CGEventGetLocation(mouseDownEvent);
				CGEventPost(kCGSessionEventTap, mouseDownEvent);
				CFRelease(mouseDownEvent);
				if (mouseDraggedEvent) {
					location = CGEventGetLocation(mouseDraggedEvent);
					CGEventPost(kCGSessionEventTap, mouseDraggedEvent);
					CFRelease(mouseDraggedEvent);
				}
				CGEventRef event = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, location, kCGMouseButtonRight);
				CGEventPost(kCGSessionEventTap, event);
				CFRelease(event);
				mouseDownEvent = mouseDraggedEvent = NULL;
			}
			
			mouseEvent = [NSEvent eventWithCGEvent:event];
			[windowController handleMouseEvent:mouseEvent];
			mouseDownEvent = event;
			CFRetain(mouseDownEvent);
			lastLocation = mouseEvent.locationInWindow;
			break;
		case kCGEventRightMouseDragged:
			if (mouseDownEvent) {
				mouseEvent = [NSEvent eventWithCGEvent:event];
				[windowController handleMouseEvent:mouseEvent];
				if (mouseDraggedEvent) {
					CFRelease(mouseDraggedEvent);
				}
				mouseDraggedEvent = event;
				CFRetain(mouseDraggedEvent);
				updateDirections(mouseEvent);
			}
			break;
		case kCGEventRightMouseUp: {
			if (mouseDownEvent) {
				mouseEvent = [NSEvent eventWithCGEvent:event];
				[windowController handleMouseEvent:mouseEvent];
				updateDirections(mouseEvent);
				if (!handleGesture()) {
					CGEventPost(kCGSessionEventTap, mouseDownEvent);
					if (mouseDraggedEvent) {
						CGEventPost(kCGSessionEventTap, mouseDraggedEvent);
					}
					CGEventPost(kCGSessionEventTap, event);
				}
				CFRelease(mouseDownEvent);
			}
			if (mouseDraggedEvent) {
				CFRelease(mouseDraggedEvent);
			}
			mouseDownEvent = mouseDraggedEvent = NULL;
            strcpy(directionstr,"");
			break;
		}
		case kCGEventTapDisabledByTimeout:
			CGEventTapEnable(mouseEventTap, isEnable); // re-enable
			windowController.enable = isEnable;
			break;
		default:
			return event;
	}
	
	return NULL;
}

- (BOOL)toggleEnable {
	windowController.enable = isEnable = !isEnable;
	CGEventTapEnable(mouseEventTap, isEnable);
	return isEnable;
}

- (void)dealloc
{
	[super dealloc];
	[windowController release];
	[menuController release];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

	windowController = [[CanvasWindowController alloc] init];
	
	CGEventMask eventMask = CGEventMaskBit(kCGEventRightMouseDown) | CGEventMaskBit(kCGEventRightMouseDragged) | CGEventMaskBit(kCGEventRightMouseUp);
	mouseEventTap = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, mouseEventCallback, NULL);
	CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, mouseEventTap, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
	CFRelease(mouseEventTap);
	CFRelease(runLoopSource);
	isEnable = true;
	
	getFrontProcessPID();
}

@end
