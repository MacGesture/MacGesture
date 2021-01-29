
#import "AppDelegate.h"
#import "AppPrefsWindowController.h"
#import "CanvasWindowController.h"
#import "BlockAllowFilter.h"
#import "RulesList.h"
#import "utils.h"

@interface AppDelegate () <AppPrefsDelegate>

@property (strong) IBOutlet NSMenu *statusItemMenu;
@property (strong) NSStatusItem *statusItem;

@end

@implementation AppDelegate

static CanvasWindowController *windowController;
static CGEventRef mouseDownEvent, mouseDraggedEvent;
static NSMutableString *direction;
static NSPoint lastLocation;
static CFMachPortRef mouseEventTap;
static AppPrefsWindowController *_preferencesWindowController;
static NSTimeInterval lastMouseWheelEventTime = 0;
static BOOL eventTriggered;
static NSUserDefaults *defaults;

+ (AppDelegate *)appDelegate {
    return (AppDelegate *) [[NSApplication sharedApplication] delegate];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {

    defaults = [NSUserDefaults standardUserDefaults];
    NSBundle *bundle = [NSBundle mainBundle];

//#warning Debugging first app launch
//    [defaults removePersistentDomainForName:bundle.bundleIdentifier];
//    [defaults synchronize];

    NSArray<NSRunningApplication *> *apps =
        [NSRunningApplication runningApplicationsWithBundleIdentifier:bundle.bundleIdentifier];
    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    NSString *name = @"MacGestureOpenPreferences";

    // Check whether MacGesture isn't running already.
    // In case it is, notify the earlier instance to open Preferences window and finish execution.
    if (apps.count > 1)
    {
        [center postNotificationName:name object:nil userInfo:nil deliverImmediately:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSApp terminate:self];
        });
        return;
    }

    // Defaults registration

    BOOL hasRunBefore = [defaults boolForKey:@"hasRunBefore"];

    NSURL *defaultPrefsFile = [bundle URLForResource:@"DefaultPreferences" withExtension:@"plist"];
    NSDictionary *defaultPrefs = [NSDictionary dictionaryWithContentsOfURL:defaultPrefsFile];
    [defaults registerDefaults:defaultPrefs];
    [defaults synchronize];

    // README prompt

    if (!hasRunBefore) {
        [defaults setBool:YES forKey:@"hasRunBefore"];

        NSString *text = NSLocalizedString(@"Welcome to MacGesture! 🎉", nil);
        NSString *info = NSLocalizedString(@"A brief information about how MacGesture works "
             "is available in README. A copy of README is also included in About section "
             "of MacGesture's Preferences.", nil);

        NSAlert *alert = [NSAlert new];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = text;
        alert.informativeText = info;
        [alert addButtonWithTitle:NSLocalizedString(@"Open README", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Skip", nil)];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            NSURL *readmeURL = [bundle URLForResource:@"README" withExtension:@"html"];
            [[NSWorkspace sharedWorkspace] openURL:readmeURL];
        }
    }

    // Accessibility permission check & alert

    CGEventMask eventMask = CGEventMaskBit(kCGEventRightMouseDown) | CGEventMaskBit(kCGEventRightMouseDragged) |
                            CGEventMaskBit(kCGEventRightMouseUp) | CGEventMaskBit(kCGEventLeftMouseDown) |
                            CGEventMaskBit(kCGEventScrollWheel);
    mouseEventTap = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, eventMask, mouseEventCallback, NULL);

    const void * keys[] = { kAXTrustedCheckOptionPrompt };
    const void * values[] = { kCFBooleanTrue };

    CFDictionaryRef options = CFDictionaryCreate(
        kCFAllocatorDefault, keys, values, sizeof(keys) / sizeof(*keys),
        &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions(options);
    
    if (accessibilityEnabled) {
        CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, mouseEventTap, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        CFRelease(mouseEventTap);
        CFRelease(runLoopSource);
    } else {
        NSAlert *alert = [NSAlert new];
        alert.alertStyle = NSAlertStyleWarning;
        alert.messageText = NSLocalizedString(
            @"MacGesture processes your mouse events, thus requires "
             "the Accessibility permission to work properly", nil);
        alert.informativeText = [NSString stringWithFormat:@"%@\n\n%@",
            NSLocalizedString(@"Please navigate to System Preferences → Security & "
                "Privacy → Privacy → Accessibility section to enable it for MacGesture.", nil),
            NSLocalizedString(@"If it's already enabled but gestures aren't "
                "working properly, please re-open MacGesture.", nil)];
        __unused NSModalResponse response = [alert runModal];
        // FIXME: Dynamic checking & registration to events
    }

    windowController = [CanvasWindowController new];
    direction = [NSMutableString string];
    _enabled = YES;

    [BWFilter compatibleProcedureWithPreviousVersionBlockRules];

    [self updateStatusBarItem];

    [center setSuspended:NO];
    [center addObserver:self selector:@selector(receiveOpenPreferencesNotification:)
        name:name object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

    // The application is an ordinary app that appears in the Dock and may
    // have a user interface.
//    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    // The application does not appear in the Dock and does not have a menu
    // bar, but it may be activated programmatically or by clicking on one
    // of its windows.
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

    // Open preferences on startup
    if (!hasRunBefore || [defaults boolForKey:@"openPrefOnStartup"]) {
        [self openPreferences:self];
    }
}

- (void)updateStatusBarItem {
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];

    if ([defaults boolForKey:@"showIconInStatusBar"]) {
        NSStatusItem *item = [statusBar statusItemWithLength:NSVariableStatusItemLength];

        NSImage *menuIcon = [NSImage imageNamed:@"menubar_icon"];
        if (@available(macOS 11.0, *)) menuIcon = [NSImage imageNamed:@"menubar_icon-big_sur"];
        menuIcon.template = YES;

        item.image = menuIcon;
//        item.alternateImage = highlightIcon;
        item.menu = self.statusItemMenu;
        item.highlightMode = YES;
        self.statusItem = item;
    } else {
        if (self.statusItem) {
            [statusBar removeStatusItem:self.statusItem];
            self.statusItem = nil;
        }
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void)showPreferences {
    [NSApp activateIgnoringOtherApps:YES];

    // Instantiate Preferences window controller
    if (!_preferencesWindowController) {
        _preferencesWindowController = [[AppPrefsWindowController alloc] initWithWindowNibName:@"Preferences"];
        _preferencesWindowController.delegate = self;
        [_preferencesWindowController showWindow:self];
    } else [_preferencesWindowController.window orderFront:self];
}

- (void)appPrefsDidClose {
    _preferencesWindowController = nil;
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    if ([self statusItem]) {
        NSString *menuIconName = @"menubar_icon-disabled";
        if (enabled) menuIconName = @"menubar_icon";
        if (@available(macOS 11.0, *)) menuIconName = [menuIconName stringByAppendingString:@"-big_sur"];
        NSImage *menuIcon = [NSImage imageNamed:menuIconName];
        [[self statusItem] setImage:menuIcon];
    }
}

- (IBAction)openPreferences:(id)sender {
    [self showPreferences];
}

- (void)receiveOpenPreferencesNotification:(NSNotification *)notification {
    if ([notification.name isEqualToString:@"MacGestureOpenPreferences"])
        [self showPreferences];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    // This event can be triggered when switching desktops in Sierra. See BUG #37
    if ((![defaults boolForKey:@"openPrefOnStartup"]
         && ![defaults boolForKey:@"showIconInStatusBar"])
        || [defaults boolForKey:@"openPrefOnActivate"]) {
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
    double threshold = [defaults doubleForKey:@"directionDetectionThreshold"];
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

    if (![[AppDelegate appDelegate] isEnabled])
        return event;

    NSEvent *mouseEvent;
    switch (type) {
        case kCGEventRightMouseDown:
            // not thread safe, but it's always called on main thread
            // check blocker apps
            //    if(wildLike(frontBundleName(), [defaults stringForKey:@"blockFilter"])){
            if (true)
            {
                NSString *frontBundle = frontBundleName();
                if (![BWFilter shouldHookMouseEventForApp:frontBundle] || (![defaults boolForKey:@"showUIInWhateverApp"] && ![[RulesList sharedRulesList] appSuitedRule:frontBundle])) {
//                        CGEventPost(kCGSessionEventTap, mouseDownEvent);
//                        if (mouseDraggedEvent) {
//                            CGEventPost(kCGSessionEventTap, mouseDraggedEvent);
//                        }
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
            mouseEvent = [NSEvent eventWithCGEvent:event];
            double delta = CGEventGetDoubleValueField(event, kCGScrollWheelEventDeltaAxis1);
//            BOOL unnaturalDirection = mouseEvent.isDirectionInvertedFromDevice;
//            if (unnaturalDirection) delta *= -1;
            // NSLog(@"scrollWheel delta:%f", delta);
            
            NSTimeInterval current = [NSDate timeIntervalSinceReferenceDate];
            if (current - lastMouseWheelEventTime > 0.3) {
                if (delta > 0) {
                    // NSLog(@"Traditional scroll wheel up!");
                    addDirection('u', true);
                    eventTriggered = YES;
                } else if (delta < 0){
                    // NSLog(@"Traditional scroll wheel down!");
                    addDirection('d', true);
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
