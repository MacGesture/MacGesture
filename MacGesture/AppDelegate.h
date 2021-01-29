
#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate>

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;
+ (AppDelegate *)appDelegate;

- (void)updateStatusBarItem;
- (void)showPreferences;

@end
