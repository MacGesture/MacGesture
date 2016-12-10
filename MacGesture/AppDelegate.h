#import <Cocoa/Cocoa.h>

@class RulesList;


@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate>

@property(assign) IBOutlet NSWindow *window;

@property(readwrite, retain) IBOutlet NSMenu *menu;
@property(readwrite, retain) NSStatusItem *statusItem;

+ (AppDelegate *)appDelegate;
- (void)updateStatusBarItem;
- (void)receiveOpenPreferencesNotification:(NSNotification *)notification;
- (void)setEnabled:(BOOL)enabled;

@end