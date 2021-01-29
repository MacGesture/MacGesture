#import "AppDelegate.h"
#import "AppPrefsWindowController.h"
#import "CanvasWindowController.h"
#import "RulesList.h"
#import "utils.h"
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
static BOOL eventTriggered;

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
    
    //AXIsProcessTrustedWithOptions(CFDictionaryCreate(NULL, (const void*[]){ kAXTrustedCheckOptionPrompt }, (const void*[]){ kCFBooleanTrue }, 1, NULL, NULL));
    
    windowController = [[CanvasWindowController alloc] init];
    
    CGEventMask eventMask = CGEventMaskBit(kCGEventRightMouseDown) | CGEventMaskBit(kCGEventRightMouseDragged) | CGEventMaskBit(kCGEventRightMouseUp) | CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventScrollWheel);
    mouseEventTap = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, mouseEventCallback, NULL);
    

    const void * keys[] = { kAXTrustedCheckOptionPrompt };
    const void * values[] = { kCFBooleanTrue };
    
    CFDictionaryRef options = CFDictionaryCreate(
                                                 kCFAllocatorDefault,
                                                 keys,
                                                 values,
                                                 sizeof(keys) / sizeof(*keys),
                                                 &kCFCopyStringDictionaryKeyCallBacks,
                                                 &kCFTypeDictionaryValueCallBacks);
    
    BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions(options);
    
    if (accessibilityEnabled) {
        CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, mouseEventTap, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        CFRelease(mouseEventTap);
        CFRelease(runLoopSource);
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:NSLocalizedString(@"On macOS Mojave(10.14) and later, you must manually enable Accessibility permission for MacGesture to work.\n Please goto System Preferences -> Security & Privacy -> Privacy -> Accessibility to enable it for MacGesture.\nIf is is already enabled but MacGesture is still not working, please re-open MacGesture.", nil)];
        
        [alert runModal];
        
    }

    direction = [NSMutableString string];
    isEnabled = YES;
    
    NSURL *defaultPrefsFile = [[NSBundle mainBundle]
                               URLForResource:@"DefaultPreferences" withExtension:@"plist"];
    NSDictionary *defaultPrefs =
    [NSDictionary dictionaryWithContentsOfURL:defaultPrefsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRunBefore"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRunBefore"];
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Open README in browser", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Skip", nil)];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert setMessageText:NSLocalizedString(@"Much information is elaborated in README. A copy of README is included in 'About & Help'.", nil)];
        NSModalResponse result = [alert runModal];
        if (result == NSAlertFirstButtonReturn) {
            NSString *readme = [[NSBundle mainBundle] pathForResource:@"README" ofType:@"html"];
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@", readme]]];
        }
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasRun_2.0.4_Before"]) {
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
    // This event can be triggered when switching desktops in Sierra. See BUG #37
    if ((![[NSUserDefaults standardUserDefaults] boolForKey:@"openPrefOnStartup"]
         && ![[NSUserDefaults standardUserDefaults] boolForKey:@"showIconInStatusBar"])
        || [[NSUserDefaults standardUserDefaults] boolForKey:@"openPrefOnActivate"]) {
        [self openPreferences:self];
    }
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
        handleGesture(NO);
    }
}

static void updateDirections(NSEvent *event) {
    // not thread safe
    NSPoint newLocation = event.locationInWindow;
    double deltaX = newLocation.x - lastLocation.x;
    double deltaY = newLocation.y - lastLocation.y;
    double absX = fabs(deltaX);
    double absY = fabs(deltaY);
    double threshold = [[NSUserDefaults standardUserDefaults] doubleForKey:@"directionDetectionThreshold"];
    if (absX + absY < threshold) {
        return; // ignore short distance
    }
    
    lastLocation = event.locationInWindow;
    
    
    if (absX > absY) {
        if (deltaX > 0) {
            addDirection('R', false);
            eventTriggered = YES;
            return;
        } else {
            addDirection('L', false);
            eventTriggered = YES;
            return;
        }
    } else {
        if (deltaY > 0) {
            addDirection('U', false);
            eventTriggered = YES;
            return;
        } else {
            addDirection('D', false);
            eventTriggered = YES;
            return;
        }
    }
    
}

static bool handleGesture(BOOL lastGesture) {
    return [[RulesList sharedRulesList] handleGesture:direction isLastGesture:lastGesture];
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
                if (![BWFilter shouldHookMouseEventForApp:frontBundle] || (![[NSUserDefaults standardUserDefaults] boolForKey:@"showUIInWhateverApp"] && ![[RulesList sharedRulesList] appSuitedRule:frontBundle])) {
                    //        CGEventPost(kCGSessionEventTap, mouseDownEvent);
                    //        if (mouseDraggedEvent) {
                    //            CGEventPost(kCGSessionEventTap, mouseDraggedEvent);
                    //        }
                    shouldShow = NO;
                    return event;
                }
                shouldShow = YES;
                eventTriggered = NO;
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
                CGEventRef event_up = CGEventCreateMouseEvent(NULL, kCGEventRightMouseUp, location, kCGMouseButtonRight);
                CGEventPost(kCGSessionEventTap, event_up);
                CFRelease(event_up);
                mouseDownEvent = mouseDraggedEvent = NULL;
            }
            mouseEvent = [NSEvent eventWithCGEvent:event];
            mouseDownEvent = event;
            CFRetain(mouseDownEvent);
            
            [windowController handleMouseEvent:mouseEvent];
            lastLocation = mouseEvent.locationInWindow;
            break;
        case kCGEventRightMouseDragged:
            if (!shouldShow){
                return event;
            }
            
            if (mouseDownEvent) {
                mouseEvent = [NSEvent eventWithCGEvent:event];
                
                // Hack when Synergy is started after MacGesture
                // -- when dragging to a client, the mouse point resets to (server_screenwidth/2+rnd(-1,1),server_screenheight/2+rnd(-1,1))
                if (mouseDraggedEvent) {
                    NSPoint lastPoint = CGEventGetLocation(mouseDraggedEvent);
                    NSPoint currentPoint = [mouseEvent locationInWindow];
                    // FIXME: use which screen?
                    NSRect screen = [[NSScreen mainScreen] frame];
                    float d1 = fabs(lastPoint.x - screen.origin.x), d2 = fabs(lastPoint.x - screen.origin.x - screen.size.width);
                    float d3 = fabs(lastPoint.y - screen.origin.y), d4 = fabs(lastPoint.y - screen.origin.y - screen.size.height);
                    
                    float d5 = fabs(currentPoint.x - screen.origin.x - screen.size.width/2), d6 = fabs(currentPoint.y - screen.origin.y - screen.size.height/2);
                    
                    const float threshold = 30.0;
                    if ((d1 < threshold || d2 < threshold || d3 < threshold || d4 < threshold) &&
                        d5 < threshold && d6 < threshold) {
                        CFRelease(mouseDraggedEvent);
                        CFRelease(mouseDownEvent);
                        mouseDownEvent = mouseDraggedEvent = NULL;
                        shouldShow = NO;
                        resetDirection();
                        break;
                    }
                    
                }
                
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
                if (handleGesture(true)) {
                    eventTriggered = YES;
                }
                
                if (!eventTriggered) {
                    CGEventPost(kCGSessionEventTap, mouseDownEvent);
                    //if (mouseDraggedEvent) {
                    //    CGEventPost(kCGSessionEventTap, mouseDraggedEvent);
                    //}
                    
                    // Fix issue #70 dunno why here
                    usleep(1000);
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
            
            // NSLog(@"scrollWheel delta:%f", delta);
            
            NSTimeInterval current = [NSDate timeIntervalSinceReferenceDate];
            if (current - lastMouseWheelEventTime > 0.3) {
                if (delta > 0) {
                    // NSLog(@"scrollWheel Down!");
                    addDirection('d', true);
                    eventTriggered = YES;
                } else if (delta < 0){
                    // NSLog(@"scrollWheel Up!");
                    addDirection('u', true);
                    eventTriggered = YES;
                }
                lastMouseWheelEventTime = current;
            }
            break;
        }
        case kCGEventTapDisabledByUserInput:
        case kCGEventTapDisabledByTimeout:
            CGEventTapEnable(mouseEventTap, true); // re-enable
            // windowController.enable = isEnable;
            break;
        case kCGEventLeftMouseDown: {
            if (!shouldShow || !mouseDownEvent) {
                return event;
            }
            addDirection('Z', true);
            eventTriggered = YES;
            break;
        }
        default:
            return event;
    }
    
    return NULL;
}

@end
