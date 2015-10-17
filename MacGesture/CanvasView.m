//
//  CanvasView.m
//  MouseGesture
//
//  Created by keakon on 11-11-14.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import "CanvasView.h"

@implementation CanvasView

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		color = [NSColor blueColor];
		image = [[NSImage alloc] initWithSize:frame.size];
        textImage = [[NSImage alloc] initWithSize:frame.size];
		radius = 2;
	}

	return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[image drawInRect:NSScreen.mainScreen.frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[textImage drawInRect:NSScreen.mainScreen.frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

}

- (void)drawCircleAtPoint:(NSPoint)point
{
    /*
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [image lockFocus];
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(point.x - radius, point.y - radius, radius * 2, radius * 2)];
        [color set];
        [path fill];

        [image unlockFocus];
    });*/

}

- (void)drawLineFromPoint:(NSPoint)point1 toPoint:(NSPoint)point2 {

    [image lockFocus];
    NSBezierPath *path = [NSBezierPath bezierPath];
    path.lineWidth = radius * 2;
    [color setStroke];
    [path moveToPoint:point1];
    [path lineToPoint:point2];
    [path stroke];
    [image unlockFocus];

    [self setNeedsDisplay:true];

}

- (void)clear {
	image = [[NSImage alloc] initWithSize:NSScreen.mainScreen.frame.size];
  	textImage = [[NSImage alloc] initWithSize:NSScreen.mainScreen.frame.size];
    self.needsDisplay = YES;
}

- (void)resizeTo:(NSRect)frame {
	self.frame = frame;
	image.size = frame.size;
	self.needsDisplay = YES;
}

- (void)setEnable:(BOOL)shouldEnable {

	if (!shouldEnable) {
		image = nil;
	} else if (image == nil) {
		image = [[NSImage alloc] initWithSize:NSScreen.mainScreen.frame.size];
	}
}

- (void)mouseDown:(NSEvent *)event {
	lastLocation = event.locationInWindow;NSScreen.mainScreen;
	[self drawCircleAtPoint:lastLocation];
}

- (void)mouseDragged:(NSEvent *)event
{

	@autoreleasepool {
		NSPoint newLocation = event.locationInWindow;
		[self drawCircleAtPoint:newLocation];
		[self drawLineFromPoint:lastLocation toPoint:newLocation];
		[self setNeedsDisplayInRect:NSMakeRect(fmin(lastLocation.x - radius, newLocation.x - radius),
											   fmin(lastLocation.y - radius, newLocation.y - radius),
											   abs(newLocation.x - lastLocation.x) + radius * 2,
											   abs(newLocation.y - lastLocation.y) + radius * 2)];
		lastLocation = newLocation;
	}

}

- (void)mouseUp:(NSEvent *)event
{
	[self clear];
}

- (void)writeDirection:(NSString *)directionStr;
{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showGesturePreview"]){
        return;
    }
    directionStr = [directionStr stringByReplacingOccurrencesOfString:@"U" withString:@"↑"];
    directionStr = [directionStr stringByReplacingOccurrencesOfString:@"D" withString:@"↓"];
    directionStr = [directionStr stringByReplacingOccurrencesOfString:@"L" withString:@"←"];
    directionStr = [directionStr stringByReplacingOccurrencesOfString:@"R" withString:@"→"];

    textImage = [[NSImage alloc] initWithSize:NSScreen.mainScreen.frame.size];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [textImage lockFocus];

        CGRect screenRect = [[NSScreen mainScreen] frame];


        NSFont *font = [NSFont fontWithName:@"Palatino-Roman" size:60.0];

        NSDictionary *textAttributes = @{NSFontAttributeName : font};
        CGSize size = [directionStr sizeWithAttributes:textAttributes];
        int x = ((screenRect.size.width - size.width) / 2);
        int y = ((screenRect.size.height - size.height) / 2);

        [directionStr drawAtPoint:NSMakePoint(x, y) withAttributes:textAttributes];

        [textImage unlockFocus];
        [self setNeedsDisplay:true];
    });

}

@end
