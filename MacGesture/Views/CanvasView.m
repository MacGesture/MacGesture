//
//  CanvasView.m
//  MouseGesture
//
//  Created by keakon on 11-11-14.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import "CanvasView.h"
#import "RulesList.h"
#import "MGOptionsDefine.h"
#import <CoreImage/CoreImage.h>

@interface CanvasView () {
    NSColor *noteColor;
}

@end

@implementation CanvasView

static NSImage *leftImage;
static NSImage *rightImage;
static NSImage *upImage;
static NSImage *downImage;
static NSImage *scrollImage;
static NSImage *cursorImage;

static NSColor *loadedColor;

- (NSImage *)convertImage:(NSImage *)image toSpecifiedColor:(NSColor *)col {
    NSColorSpace *colSpace = [[self window] colorSpace] ?: [NSColorSpace deviceRGBColorSpace];
    col = [col colorUsingColorSpace:colSpace];
    CIImage *ciImage = [[CIImage alloc] initWithData:[image TIFFRepresentation]];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorMatrix"];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    [filter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:0] forKey:@"inputRVector"];
    [filter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:0] forKey:@"inputGVector"];
    [filter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:0] forKey:@"inputBVector"];
    [filter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:1] forKey:@"inputAVector"];
    [filter setValue:[CIVector vectorWithX:col.redComponent Y:col.greenComponent Z:col.blueComponent W:0] forKey:@"inputBiasVector"];

    CIImage *output = filter.outputImage;

    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:output fromRect:[output extent]];
    NSImage *result = [[NSImage alloc] initWithCGImage:cgImage size:output.extent.size];
    CGImageRelease(cgImage);

    return result;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    noteColor = [MGOptionsDefine getNoteColor];
    if (![noteColor isEqualTo:loadedColor]) {
        leftImage = [self convertImage:[NSImage imageNamed:@"gesture-icon-left"] toSpecifiedColor:noteColor];
        rightImage = [self convertImage:[NSImage imageNamed:@"gesture-icon-right"] toSpecifiedColor:noteColor];
        downImage = [self convertImage:[NSImage imageNamed:@"gesture-icon-down"] toSpecifiedColor:noteColor];
        upImage = [self convertImage:[NSImage imageNamed:@"gesture-icon-up"] toSpecifiedColor:noteColor];
        scrollImage = [self convertImage:[NSImage imageNamed:@"gesture-icon-scroll"] toSpecifiedColor:noteColor];
        cursorImage = [self convertImage:[NSImage imageNamed:@"gesture-icon-mouse"] toSpecifiedColor:noteColor];
        loadedColor = noteColor;
    }

    if (self) {
        color = [MGOptionsDefine getLineColor];
        points = [[NSMutableArray alloc] init];
        directionToDraw = @"";
        radius = 2;
    }

    return self;
}

- (float)getGestureImageScale {
    return [[NSUserDefaults standardUserDefaults] floatForKey:@"gestureSize"] / 100 * 1.25;
}

- (void)drawDirection {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"showGesturePreview"]) {
        return;
    }

    // This should be called in drawRect
    float scale = [self getGestureImageScale];
    float scaledHeight = scale * leftImage.size.height;
    float scaledWidth = scale * leftImage.size.width;

    // Can be more efficient, though
    NSUInteger numberToDraw = 0;
    bool merge = [[NSUserDefaults standardUserDefaults] boolForKey:@"mergeConsecutiveIdenticalGestures"];

    if (merge) {
        for (NSUInteger i = 0; i < directionToDraw.length; i++) {
            numberToDraw++;
            char ch = [directionToDraw characterAtIndex:i];
            if (ch == 'u' || ch == 'd' || ch == 'Z') {
                for (; i < directionToDraw.length && [directionToDraw characterAtIndex:i] == ch; i++);
                i--;
            }
        }
    } else {
        numberToDraw = directionToDraw.length;
    }

    CGRect screenRect = [self.window frame];
    NSInteger y = (screenRect.size.height - scaledHeight) / 2;
    NSInteger beginx = (screenRect.size.width - scaledWidth * numberToDraw) / 2;

    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
    int index = 0;
    for (NSInteger i = 0; i < directionToDraw.length; i++) {
        NSImage *image = nil;
        char ch = [directionToDraw characterAtIndex:i];
        switch (ch) {
            case 'L':
                image = leftImage;
                break;
            case 'R':
                image = rightImage;
                break;
            case 'U':
            case 'u':
                image = upImage;
                break;
            case 'D':
            case 'd':
                image = downImage;
                break;
            case 'Z':
                image = cursorImage; // [[NSCursor arrowCursor] image]
            default:
                break;
        }

        if (merge) {
            int count = 0;
            for (; i < directionToDraw.length && [directionToDraw characterAtIndex:i] == ch; i++) {
                count++;
            }
            i--;
        }

        if (ch == 'u' || ch == 'd') {
            double frac = 0.65;

            /*
             if (count > 1) {
             [[NSString stringWithFormat:@"%d", count] drawWithRect: NSMakeRect(beginx + index * scaledWidth, y - (frac - 0.5)*scaledHeight, scaledWidth*(1-frac), scaledHeight*(1-frac))
             options: NSStringDrawingUsesFontLeading
             attributes: nil
             context: nil];
             }
             */

            [scrollImage drawInRect:NSMakeRect(beginx + index * scaledWidth + frac * scaledWidth, y - (frac - 0.5) * scaledHeight, scaledWidth * (1 - frac), scaledHeight * (1 - frac)) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];

        }
        [image drawInRect:NSMakeRect(beginx + index * scaledWidth, y, scaledWidth, scaledHeight) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
        index++;
    }
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawNote {
    // This should be called in drawRect
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"showGestureNote"]) {
        return;
    }
    NSInteger index = [[RulesList sharedRulesList] suitedRuleWithGesture:directionToDraw];
    NSString *note = @"";
    if (index == -1)
        return;
    else
        note = [[RulesList sharedRulesList] noteAtIndex:index];
    if (![note isEqualToString:@""]) {

        CGRect screenRect = [self.window frame];

        NSString *fontName = [[NSUserDefaults standardUserDefaults] objectForKey:@"noteFontName"];
        double fontSize = [[NSUserDefaults standardUserDefaults] doubleForKey:@"noteFontSize"];

        NSFont *font = [NSFont fontWithName:fontName size:fontSize];
        NSColor *fontColor = noteColor ?: [MGOptionsDefine getNoteColor];

//        NSLog(@"%p %p", font, noteColor);
        NSDictionary *textAttributes = @{
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: fontColor,
        };

        CGSize size = [note sizeWithAttributes:textAttributes];
        size.width += fontSize/2;
        CGFloat x = ((screenRect.size.width - size.width) / 2);
        CGFloat y = ((screenRect.size.height + leftImage.size.height * [self getGestureImageScale]) / 2);

        CGContextRef context = [NSGraphicsContext currentContext].CGContext;
        CGContextSetRGBFillColor(context, 0, 0, 0, 0.1);
        CGContextFillRect(context, CGRectMake(x, y, size.width, size.height));

        x += fontSize/4;

        [note drawAtPoint:NSMakePoint(x, y) withAttributes:textAttributes];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    // draw mouse line

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"disableMousePath"]) {
        NSBezierPath *path = [NSBezierPath bezierPath];
        path.lineWidth = radius * 2;
        [color setStroke];
        if (points.count >= 1) {
            [path moveToPoint:[points[0] pointValue]];
        }
        for (int i = 1; i < points.count; i++) {
            [path lineToPoint:[points[i] pointValue]];
        }

        [path stroke];
    }

    //[textImage drawInRect:NSScreen.mainScreen.frame fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [self drawDirection];
    [self drawNote];

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


- (void)mouseDown:(NSEvent *)event {
    lastLocation = [NSEvent mouseLocation];
    NSWindow *w = self.window;
    lastLocation.x -= w.frame.origin.x;
    lastLocation.y -= w.frame.origin.y;
#ifdef DEBUG
    //NSLog(@"mouseDown frame:%@, window:%@, screen:%@, point:%@", NSStringFromRect(self.frame), NSStringFromRect(w.frame), NSStringFromRect(s.frame), NSStringFromPoint(lastLocation));
#endif
    [points removeAllObjects];
    [points addObject:[NSValue valueWithPoint:lastLocation]];

    NSLog(@"%@", NSStringFromPoint([points[0] pointValue]));
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint newLocation = event.locationInWindow;
    NSWindow *w = self.window;
    newLocation.x -= w.frame.origin.x;
    newLocation.y -= w.frame.origin.y;

#ifdef DEBUG
    //NSLog(@"mouseDragged frame:%@, window:%@, screen:%@, point:%@", NSStringFromRect(self.frame), NSStringFromRect(w.frame), NSStringFromRect(s.frame), NSStringFromPoint(newLocation));
#endif

    //		[self drawCircleAtPoint:newLocation];
    [points addObject:[NSValue valueWithPoint:newLocation]];
    self.needsDisplay = YES;
    //		[self setNeedsDisplayInRect:NSMakeRect(fmin(lastLocation.x - radius, newLocation.x - radius),
    //											   fmin(lastLocation.y - radius, newLocation.y - radius),
    //											   abs(newLocation.x - lastLocation.x) + radius * 2,
    //											   abs(newLocation.y - lastLocation.y) + radius * 2)];
    lastLocation = newLocation;
}

- (void)setEnable:(BOOL)shouldEnable {
    // No op. Supress warning and avoid possible selector not found errors.
}

- (void)mouseUp:(NSEvent *)event {
    [self clear];
}

- (void)writeDirection:(NSString *)directionStr {
    directionToDraw = directionStr;

    self.needsDisplay = YES;
}

@end
