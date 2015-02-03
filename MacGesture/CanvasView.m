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
		color = [NSColor.blueColor retain];
		image = [[NSImage alloc] initWithSize:frame.size];
		radius = 2;
	}
	
	return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[image drawInRect:NSScreen.mainScreen.frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)drawCircleAtPoint:(NSPoint)point
{
	[image lockFocus];
	NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(point.x - radius, point.y - radius, radius * 2, radius * 2)];
	[color set];
	[path fill];
	[image unlockFocus];
}

- (void)drawLineFromPoint:(NSPoint)point1 toPoint:(NSPoint)point2
{
	[image lockFocus];
	NSBezierPath *path = [NSBezierPath bezierPath];
	path.lineWidth = radius * 2;
	[color setStroke];
	[path moveToPoint:point1];
	[path lineToPoint:point2];
	[path stroke];
	[image unlockFocus];
}

- (void)clear {
	[color release];
	[image release];
	image = [[NSImage alloc] initWithSize:NSScreen.mainScreen.frame.size];
	self.needsDisplay = YES;
}

- (void)resizeTo:(NSRect)frame {
	self.frame = frame;
	image.size = frame.size;
	self.needsDisplay = YES;
}

- (void)setEnable:(BOOL)shouldEnable {
	if (!shouldEnable) {
		[image release];
		image = nil;
	} else if (image == nil) {
		image = [[NSImage alloc] initWithSize:NSScreen.mainScreen.frame.size];
	}
}

- (void)mouseDown:(NSEvent *)event {
	lastLocation = event.locationInWindow;
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

- (void)dealloc
{
	[super dealloc];
	[color release];
	[image release];
}

@end
