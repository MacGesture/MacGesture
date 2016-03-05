
#import "AppDelegate.h"
#import "AppPrefsWindowController.h"
#import "CanvasWindowController.h"
#import "RulesList.h"
#import "utils.h"
#import "NSBundle+LoginItem.h"
#import "BlackWhiteFilter.h"


@implementation AppDelegate


static CanvasWindowController *windowController;
static CGEventRef mouseDownEvent, mouseDraggedEvent;
static NSMutableString *direction;
static NSPoint lastLocation;
static CFMachPortRef mouseEventTap;
static bool isEnable;
static AppPrefsWindowController *_preferencesWindowController;

+ (AppDelegate *)appDelegate
{

    return (AppDelegate *)[[NSApplication sharedApplication] delegate];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {

    windowController = [[CanvasWindowController alloc] init];

    CGEventMask eventMask = CGEventMaskBit(kCGEventRightMouseDown) | CGEventMaskBit(kCGEventRightMouseDragged) | CGEventMaskBit(kCGEventRightMouseUp);
    mouseEventTap = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, mouseEventCallback, NULL);
    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, mouseEventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CFRelease(mouseEventTap);
    CFRelease(runLoopSource);

    direction = [NSMutableString string];
    isEnable = true;

    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRunBefore"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"openPrefOnStartup"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showGesturePreview"];

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRunBefore"];
    }

    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRun_2.0.4_Before"]){
        [[NSBundle mainBundle] addToLoginItems];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRun_2.0.4_Before"];
    }

    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRun_2.0.5_Before"]){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showGestureNote"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRun_2.0.5_Before"];
    }

    [BWFilter compatibleProcedureWithPreviousVersionBlockRules];


    if([[NSUserDefaults standardUserDefaults] boolForKey:@"openPrefOnStartup"]){
        [self openPreferences:self];
    }
}

- (BOOL)toggleEnable {
    windowController.enable = isEnable = !isEnable;

    CGEventTapEnable(mouseEventTap, isEnable);
    return isEnable;
}

- (void)awakeFromNib {
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    NSImage *menuIcon = [NSImage imageNamed:@"Menu Icon"];
    //NSImage *highlightIcon = [NSImage imageNamed:@"Menu Icon"]; // Yes, we're using the exact same image asset.
    //[highlightIcon setTemplate:YES]; // Allows the correct highlighting of the icon when the menu is clicked.
    [menuIcon setTemplate:YES];
    [[self statusItem] setImage:menuIcon];
//    [[self statusItem] setAlternateImage:highlightIcon];
    [[self statusItem] setMenu:[self menu]];
    [[self statusItem] setHighlightMode:YES];


}

- (IBAction)openPreferences:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [_preferencesWindowController close];
    //instantiate preferences window controller
    if (_preferencesWindowController) {
        _preferencesWindowController = nil;
    }
    //init from nib but the real initialization happens in the
    //PreferencesWindowController setupToolbar method
    _preferencesWindowController = [[AppPrefsWindowController alloc] initWithWindowNibName:@"Preferences"];

    [_preferencesWindowController showWindow:self];
}

static void updateDirections(NSEvent* event) {
    
    if (![[RulesList sharedRulesList] frontAppSuitedRule]) {
        return ;
    }
    
    // not thread safe
    NSPoint newLocation = event.locationInWindow;
    double deltaX = newLocation.x - lastLocation.x;
    double deltaY = newLocation.y - lastLocation.y;
    double absX = fabs(deltaX);
    double absY = fabs(deltaY);
    if (absX + absY < 20) {

        return; // ignore short distance
    }


    unichar lastDirectionChar;
    if(direction.length>0) {
        lastDirectionChar = [direction characterAtIndex:direction.length - 1];
    }else{
        lastDirectionChar = ' ';
    }
    lastLocation = event.locationInWindow;


    if (absX> absY) {
        if (deltaX> 0) {
            if (lastDirectionChar != [@"R" characterAtIndex:0]) {
                [direction appendString:@"R"];
                [windowController writeDirection:direction];
                return;
            }
        } else{
            if (lastDirectionChar != [@"L" characterAtIndex:0]) {
                [direction appendString:@"L"];
                [windowController writeDirection:direction];
                return;
            }
        }
    } else {
        if (deltaY> 0) {
            if (lastDirectionChar != [@"U" characterAtIndex:0]) {
                [direction appendString:@"U"];
                [windowController writeDirection:direction];
                return;
            }
        } else {
            if (lastDirectionChar != [@"D" characterAtIndex:0]) {
                [direction appendString:@"D"];
                [windowController writeDirection:direction];
                return;
            }
        }
    }

}

static bool handleGesture() {
    return [[RulesList sharedRulesList] handleGesture:direction];
}

void resetDirection(){
    [direction setString:@""];
}




static CGEventRef mouseEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    // not thread safe, but it's always called in main thread
    // check blocker apps
//    if(wildLike(frontBundleName(), [[NSUserDefaults standardUserDefaults] stringForKey:@"blockFilter"])){
    if(![BWFilter willHookRightClickForApp:frontBundleName()]){
//        CGEventPost(kCGSessionEventTap, mouseDownEvent);
//        if (mouseDraggedEvent) {
//            CGEventPost(kCGSessionEventTap, mouseDraggedEvent);
//        }
        CGEventPost(kCGSessionEventTap, event);
        return NULL;
    }

    NSEvent *mouseEvent;
    switch (type) {
        case kCGEventRightMouseDown:
            if (mouseDownEvent) { // mouseDownEvent may not release when kCGEventTapDisabledByTimeout
                resetDirection();
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
            [windowController reinitWindow];
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
            resetDirection();
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

@end