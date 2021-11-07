
#import "CanvasWindow.h"

@implementation CanvasWindow

- (instancetype)initWithContentRect:(NSRect)contentRect
{
    if (self = [super initWithContentRect:contentRect
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO])
    {
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
