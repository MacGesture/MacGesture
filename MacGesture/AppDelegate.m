//
//  AppDelegate.m
//  MouseGesture
//
//  Created by keakon on 11-11-9.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//
#include <Carbon/Carbon.h>

#import <lua.h>
#import <lualib.h>
#import <lauxlib.h>

#import "AppDelegate.h"
#import "CanvasWindowController.h"

#define PRINT_LUA_ERR(errcode)\
    if((errcode) !=0){\
        alertLuaErr(lua_tostring(getLuaVM(), -1));\
        lua_pop(getLuaVM(), 1);\
    }

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

static void alertLuaErr(const char* msg){
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"MacGesture Lua Error"];
    [alert setInformativeText:[NSString stringWithUTF8String:msg]];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];

}

static void setLuaCPath( lua_State* L, const char* path )    // should like ";/usr/local"
{
    lua_getglobal( L, "package" );
    lua_getfield( L, -1, "cpath" );
    lua_pop( L, 1 );
    lua_pushstring( L, path );
    lua_setfield( L, -2, "cpath" );
    lua_pop( L, 1 );
}


static lua_State* initLuaVM(bool reset){
    static lua_State *L = NULL;    // for lua vm
    if(reset == true && L!=NULL){
        lua_close(L);
        L = NULL;
        initLuaVM(false);
    }
    if(L == NULL){
        NSBundle *mainBundle = [NSBundle mainBundle];
        L = luaL_newstate();
        luaL_openlibs(L);
        
        NSString *search_path = [@";" stringByAppendingString:[mainBundle pathForResource: @"LibHandle" ofType: @"dylib"]];
        
        setLuaCPath(L, [search_path UTF8String]);

        // load utils.lua
        NSString *path = [mainBundle pathForResource: @"utils" ofType: @"lua"];
        PRINT_LUA_ERR(luaL_dofile(L, [path UTF8String]));
        
        //load handle.lua
        path = [mainBundle pathForResource: @"handle" ofType: @"lua"];
        PRINT_LUA_ERR(luaL_dofile(L, [path UTF8String]));
    }
    return L;
}

- (void) reloadLuaVM
{
    initLuaVM(true);
}

static lua_State* getLuaVM(){
    return initLuaVM(false);
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
    lastLocation = event.locationInWindow;
#define MAYBE(x)\
    puts(x);\
    if (lastDirectionChar != x[0]) { \
        strcat(directionstr,x);\
        [windowController writeDirection:[NSString stringWithCString:directionstr encoding:NSASCIIStringEncoding]];\
        return;\
    }
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
    char luacode[MAX_DIRECTIONS + 20];
    sprintf(luacode,"handleGesture('%s')",directionstr);
    
    PRINT_LUA_ERR(luaL_dostring(getLuaVM(),luacode));
    bool result = lua_toboolean(getLuaVM(),-1);
    lua_pop(getLuaVM(),-1); // pop return value
    return result;

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
    lua_close(getLuaVM());
    free(getLuaVM());

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

}

@end
