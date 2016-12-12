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
static BOOL isEnabled;
static AppPrefsWindowController *_preferencesWindowController;
static NSTimeInterval lastMouseWheelEventTime;

+ (AppDelegate *)appDelegate {
    return (AppDelegate *) [[NSApplication sharedApplication] delegate];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    NSString *name = @"MacGestureOpenPreferences";
    if ([apps count] > 1)
    {
        [center postNotificationName:name object:nil userInfo:nil deliverImmediately:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSApp terminate:self];
        });
        return ;
    }
    
    windowController = [[CanvasWindowController alloc] init];

    CGEventMask eventMask = CGEventMaskBit(kCGEventRightMouseDown) | CGEventMaskBit(kCGEventRightMouseDragged) | CGEventMaskBit(kCGEventRightMouseUp) | CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventScrollWheel);
    mouseEventTap = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, mouseEventCallback, NULL);
    CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, mouseEventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CFRelease(mouseEventTap);
    CFRelease(runLoopSource);

    direction = [NSMutableString string];
    isEnabled = YES;
    
    NSURL *defaultPrefsFile = [[NSBundle mainBundle]
                               URLForResource:@"DefaultPreferences" withExtension:@"plist"];
    NSDictionary *defaultPrefs =
        [NSDictionary dictionaryWithContentsOfURL:defaultPrefsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRunBefore"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRunBefore"];
    }

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRun_2.0.4_Before"]) {
        [[NSBundle mainBundle] addToLoginItems];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRun_2.0.4_Before"];
    }

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRun_2.0.5_Before"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showGestureNote"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRun_2.0.5_Before"];
    }

    [BWFilter compatibleProcedureWithPreviousVersionBlockRules];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"openPrefOnStartup"]) {
        [self openPreferences:self];
    }
    
    [self updateStatusBarItem];
    
    [center setSuspended:NO];
    [center addObserver:self selector:@selector(receiveOpenPreferencesNotification:) name:name object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    lastMouseWheelEventTime = 0;
}

- (void)updateStatusBarItem {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"showIconInStatusBar"]) {
        [self setStatusItem:[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength]];
        
        NSImage *menuIcon = [NSImage imageNamed:@"Menu Icon Enabled"];
        //NSImage *highlightIcon = [NSImage imageNamed:@"Menu Icon"]; // Yes, we're using the exact same image asset.
        //[highlightIcon setTemplate:YES]; // Allows the correct highlighting of the icon when the menu is clicked.
        [menuIcon setTemplate:YES];
        [[self statusItem] setImage:menuIcon];
        //    [[self statusItem] setAlternateImage:highlightIcon];
        [[self statusItem] setMenu:[self menu]];
        [[self statusItem] setHighlightMode:YES];
    } else {
        if ([self statusItem]) {
            [[NSStatusBar systemStatusBar] removeStatusItem:[self statusItem]];
            [self setStatusItem:nil];
        }
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification{
    return YES;
}

- (void)showPreferences {
    [NSApp activateIgnoringOtherApps:YES];
    
    //instantiate preferences window controller
    if (!_preferencesWindowController) {
        _preferencesWindowController = [[AppPrefsWindowController alloc] initWithWindowNibName:@"Preferences"];
        [_preferencesWindowController showWindow:self];
    } else {
       [[_preferencesWindowController window] orderFront:self];
    }
}

- (void)setEnabled:(BOOL)enabled {
    isEnabled = enabled;
    if ([self statusItem]) {
        NSImage *menuIcon;
        if (isEnabled) {
            menuIcon = [NSImage imageNamed:@"Menu Icon Enabled"];
        } else {
            menuIcon = [NSImage imageNamed:@"Menu Icon Disabled"];
        }
        [[self statusItem] setImage:menuIcon];
    }
}

- (IBAction)openPreferences:(id)sender {
    [self showPreferences];
}

- (void)receiveOpenPreferencesNotification:(NSNotification *)notification {
    [self showPreferences];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self showPreferences];
}

static void addDirection(unichar dir, bool allowSameDirection) {
    unichar lastDirectionChar;
    if (direction.length > 0) {
        lastDirectionChar = [direction characterAtIndex:direction.length - 1];
    } else {
        lastDirectionChar = ' ';
    }
    
    if (dir != lastDirectionChar || allowSameDirection) {
        NSString *temp = [NSString stringWithCharacters:&dir length:1];
        [direction appendString:temp];
        [windowController writeDirection:direction];
    }
}

static void updateDirections(NSEvent *event) {
    // not thread safe
    NSPoint newLocation = event.locationInWindow;
    double deltaX = newLocation.x - lastLocation.x;
    double deltaY = newLocation.y - lastLocation.y;
    double absX = fabs(deltaX);
    double absY = fabs(deltaY);
    if (absX + absY < 20) {
        return; // ignore short distance
    }
    
    lastLocation = event.locationInWindow;


    if (absX > absY) {
        if (deltaX > 0) {
            addDirection('R', false);
            return;
        } else {
            addDirection('L', false);
            return;
        }
    } else {
        if (deltaY > 0) {
            addDirection('U', false);
            return;
        } else {
            addDirection('D', false);
            return;
        }
    }

}

static bool handleGesture() {
    return [[RulesList sharedRulesList] handleGesture:direction];
}

void resetDirection() {
    [direction setString:@""];
}

// See https://developer.apple.com/library/mac/documentation/Carbon/Reference/QuartzEventServicesRef/#//apple_ref/c/tdef/CGEventTapCallBack
static CGEventRef mouseEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    static BOOL shouldShow;
    
    if (!isEnabled) {
        return event;
    }
    
    NSEvent *mouseEvent;
    switch (type) {
        case kCGEventRightMouseDown:
            // not thread safe, but it's always called in main thread
            // check blocker apps
            //    if(wildLike(frontBundleName(), [[NSUserDefaults standardUserDefaults] stringForKey:@"blockFilter"])){
            if (true)
            {
                NSString *frontBundle = frontBundleName();
                if (![BWFilter shouldHookMouseEventForApp:frontBundle] || !([[NSUserDefaults standardUserDefaults] boolForKey:@"showUIInWhateverApp"] || [[RulesList sharedRulesList] appSuitedRule:frontBundle])) {
                //        CGEventPost(kCGSessionEventTap, mouseDownEvent);
                //        if (mouseDraggedEvent) {
                //            CGEventPost(kCGSessionEventTap, mouseDraggedEvent);
                //        }
                    shouldShow = NO;
                    return event;
                }
                shouldShow = YES;
            }
            
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
            mouseDownEvent = event;
            CFRetain(mouseDownEvent);

            [windowController reinitWindow];
            [windowController handleMouseEvent:mouseEvent];
            lastLocation = mouseEvent.locationInWindow;
            break;
        case kCGEventRightMouseDragged:
            if (!shouldShow){
                return event;
            }
            
            if (mouseDownEvent) {
                mouseEvent = [NSEvent eventWithCGEvent:event];
                if (mouseDraggedEvent) {
                    CFRelease(mouseDraggedEvent);
                }
                mouseDraggedEvent = event;
                CFRetain(mouseDraggedEvent);
                
                [windowController handleMouseEvent:mouseEvent];
                updateDirections(mouseEvent);
            }
            break;
        case kCGEventRightMouseUp: {
            if (!shouldShow){
                return event;
            }
            
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
            shouldShow = NO;
            
            resetDirection();
            break;
        }
        case kCGEventScrollWheel: {
            if (!shouldShow || !mouseDownEvent) {
                return event;
            }
            double delta = CGEventGetDoubleValueField(event, kCGScrollWheelEventDeltaAxis1);

            NSTimeInterval current = [NSDate timeIntervalSinceReferenceDate];
            if (current - lastMouseWheelEventTime > 0.3) {
                if (delta > 0) {
                    // NSLog(@"Down!");
                    addDirection('d', true);
                } else if (delta < 0){
                    // NSLog(@"Up!");
                    addDirection('u', true);
                }
                lastMouseWheelEventTime = current;
            }
            break;
        }
        case kCGEventTapDisabledByTimeout:
            CGEventTapEnable(mouseEventTap, true); // re-enable
            // windowController.enable = isEnable;
            break;
        case kCGEventLeftMouseDown: {
            if (!shouldShow || !mouseDownEvent) {
                return event;
            }
            [direction appendString:@"Z"];
            [windowController writeDirection:direction];
            break;
        }
        default:
            return event;
    }

    return NULL;
}

@end