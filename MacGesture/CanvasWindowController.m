//
//  CanvasWindowController.m
//  MouseGesture
//
//  Created by keakon on 11-11-18.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import "CanvasWindowController.h"
#import "CanvasWindow.h"
#import "CanvasView.h"
#import "RulesList.h"

@implementation CanvasWindowController

- (void)reinitWindow {
    if (self.window != NULL) {
        [self.window close];
    }

    NSRect frame = NSScreen.mainScreen.frame;
    NSWindow *window = [[CanvasWindow alloc] initWithContentRect:frame];
    NSView *view = [[CanvasView alloc] initWithFrame:frame];
    window.contentView = view;
    
    window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
    self.window = window;
    [window orderFront:self];
}

- (id)init {
    self = [super init];
    if (self) {
        [self reinitWindow];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleScreenParametersChange:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
    }
    return self;
}

- (BOOL)enable {
    return enable;
}

- (void)setEnable:(BOOL)shouldEnable {
    enable = shouldEnable;
    if (shouldEnable) {
        [self.window orderFront:self];
    } else {
        [self.window orderOut:self];
    }
    [(CanvasView *) self.window.contentView setEnable:shouldEnable];
}

- (void)handleMouseEvent:(NSEvent *)event {
    NSPoint point = [NSEvent mouseLocation];
    if (!NSPointInRect(point, self.window.frame)) {
        NSArray<NSScreen *> *screens = [NSScreen screens];
        for (NSScreen * screen in screens) {
            if (NSPointInRect(point, [screen frame])) {
                [self.window setFrame:[screen frame] display:NO];
                NSRect curFrame = [screen frame];
                // See pr #91
                curFrame.origin.x = 0;
                curFrame.origin.y = 0;
                [(CanvasView *) self.window.contentView resizeTo:curFrame];
                break;
            }
        }
    }
    switch (event.type) {
        case NSRightMouseDown:
            [self.window.contentView mouseDown:event];
            break;
        case NSRightMouseDragged:
            [self.window.contentView mouseDragged:event];
            break;
        case NSRightMouseUp:
            [self.window.contentView mouseUp:event];
            break;
        default:
            break;
    }
}

- (void)handleScreenParametersChange:(NSNotification *)notification {
    NSRect frame = NSScreen.mainScreen.frame;
    [self.window setFrame:frame display:NO];
    // See pr #91
    frame.origin.x = 0;
    frame.origin.y = 0;
    [(CanvasView *) self.window.contentView resizeTo:frame];
}



- (void)writeDirection:(NSString *)directionStr; {
    [(CanvasView *) self.window.contentView writeDirection:directionStr];
}

@end
