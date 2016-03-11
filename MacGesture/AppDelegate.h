#import <Cocoa/Cocoa.h>

@class RulesList;


@interface AppDelegate : NSObject <NSApplicationDelegate>

@property(assign) IBOutlet NSWindow *window;

@property(readwrite, retain) IBOutlet NSMenu *menu;
@property(readwrite, retain) IBOutlet NSStatusItem *statusItem;

+ (AppDelegate *)appDelegate;

@end