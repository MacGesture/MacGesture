#import "CanvasWindow.h"

@implementation CanvasWindow

- (id)initWithContentRect:(NSRect)contentRect {
    self = [super initWithContentRect:contentRect styleMask:(NSBorderlessWindowMask) backing:NSBackingStoreBuffered defer:NO];
    if (self) {
        self.backgroundColor = [NSColor clearColor];

        self.level = CGShieldingWindowLevel();
        self.opaque = NO;
        self.hasShadow = NO;
        self.hidesOnDeactivate = NO;
        self.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
    }

    return self;
}

@end
