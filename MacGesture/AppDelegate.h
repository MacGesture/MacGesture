
#import <Cocoa/Cocoa.h>
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, UNUserNotificationCenterDelegate>

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new  UNAVAILABLE_ATTRIBUTE;
+ (AppDelegate *)appDelegate;

- (void)updateStatusBarItem;
- (void)showPreferences;

@end
