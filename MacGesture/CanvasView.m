//
//  CanvasView.m
//  MouseGesture
//
//  Created by keakon on 11-11-14.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import "CanvasView.h"
#import "RulesList.h"

@implementation CanvasView

static NSImage* leftImage;
static NSImage* rightImage;
static NSImage* upImage;
static NSImage* downImage;

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];

    leftImage = [NSImage imageNamed:@"left.png"];
    rightImage = [NSImage imageNamed:@"right.png"];
    downImage = [NSImage imageNamed:@"down.png"];
    upImage = [NSImage imageNamed:@"up.png"];

    if (self) {
		color = [NSColor blueColor];
        points = [[NSMutableArray alloc] init];
        directionToDraw = @"";
		radius = 2;
	}

	return self;
}

- (void)drawDirection{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showGesturePreview"]){
        return;
    }

    // This should be called in drawRect
    CGRect screenRect = [[NSScreen mainScreen] frame];
    NSInteger y = (screenRect.size.height - leftImage.size.height) / 2;
    NSInteger beginx = (screenRect.size.width - leftImage.size.width * directionToDraw.length) / 2;
    for(NSInteger i = 0;i<directionToDraw.length;i++){
        NSImage *image = nil;
        switch([directionToDraw characterAtIndex:i]){
            case 'L':
                image = leftImage;
                break;
            case 'R':
                image = rightImage;
                break;
            case 'U':
                image = upImage;
                break;
            case 'D':
                image = downImage;
                break;
            default:
                break;
        }

        [image drawAtPoint:NSMakePoint(beginx+i*leftImage.size.width,y) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }

}
- (void)drawNote{
    // This should be called in drawRect
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"showGestureNote"]){
        return;
    }
    NSInteger index = [[RulesList sharedRulesList] suitedRuleWithGesture:directionToDraw];
    NSString* note = @"";
    if(index == -1)
        return;
    else
        note = [[RulesList sharedRulesList] noteAtIndex:index];
    if(![note isEqualToString:@""]){

        CGRect screenRect = [[NSScreen mainScreen] frame];

        NSFont *font = [NSFont fontWithName:@"Palatino-Roman" size:88.0];

        NSDictionary *textAttributes = @{NSFontAttributeName: font};

        CGSize size = [note sizeWithAttributes:textAttributes];
        int x = ((screenRect.size.width - size.width) / 2);
        int y = ((screenRect.size.height - size.height) / 3 *2);

        [note drawAtPoint:NSMakePoint(x, y) withAttributes:textAttributes];
    }



}

- (void)drawRect:(NSRect)dirtyRect
{
	// draw mouse line
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"disableMousePath"]) {
        for (int i = 0; i < points.count; i += 2) {
            NSBezierPath *path = [NSBezierPath bezierPath];
            path.lineWidth = radius * 2;
            [color setStroke];
            [path moveToPoint:[points[i] pointValue]];
            [path lineToPoint:[points[i + 1] pointValue]];
            [path stroke];
        }
    }

    //[textImage drawInRect:NSScreen.mainScreen.frame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [self drawDirection];
    [self drawNote];

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

    [points addObject:[NSValue valueWithPoint:point1]];
    [points addObject:[NSValue valueWithPoint:point2]];
    self.needsDisplay = YES;
}

- (void)clear {
    [points removeAllObjects];
    directionToDraw = @"";
    self.needsDisplay = YES;
}

- (void)resizeTo:(NSRect)frame {
	self.frame = frame;

	self.needsDisplay = YES;
}

- (void)setEnable:(BOOL)shouldEnable {
/*
	if (!shouldEnable) {
		image = nil;
	} else if (image == nil) {
		image = [[NSImage alloc] initWithSize:NSScreen.mainScreen.frame.size];
	}
*/
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

    directionToDraw = directionStr;

    self.needsDisplay = YES;
}

@end
