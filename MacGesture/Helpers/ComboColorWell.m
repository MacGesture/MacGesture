//
//  ComboColorWell.m
//  MacGesture
//
//  Created by Michal Zelinka on 24/01/2021.
//  Copyright © 2021 MacGesture. All rights reserved.
//

#import "ComboColorWell.h"

@implementation ComboColorWell
@dynamic color;

- (instancetype)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        _showsColorWellButton = YES;
        _cornerRadius = 6;
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        _showsColorWellButton = YES;
        _cornerRadius = 6;
    }

    return self;
}

- (void)drawRect:(NSRect)cellFrame
{
    BOOL drawButtonArea = _showsColorWellButton && cellFrame.size.width >= 2*cellFrame.size.height;

    __auto_type fillPath = ^(NSBezierPath *path, NSColor *color) {
        if (!color) color = [NSColor controlColor];
        [color setFill];
        [path fill];
    };

    __auto_type fillPathGradient = ^(NSBezierPath *path, NSGradient *gradient) {
        [gradient drawInBezierPath:path angle:90.0];
    };

    NSGradient * buttonGradient = [[NSGradient alloc] initWithStartingColor:
        [NSColor blueColor] endingColor:[NSColor systemBlueColor]];
//        [NSColor altColorWithRed:17 green:103 blue:255 alpha:1] endingColor:
//        [NSColor altColorWithRed:95 green:165 blue:255 alpha:1]];

    [[[NSColor blackColor] colorWithAlphaComponent:0.25] setStroke];

    NSRect smoothRect = NSInsetRect(cellFrame, 0.5, 0.5);

    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:smoothRect xRadius:_cornerRadius yRadius:_cornerRadius];
    path.lineWidth = 0.5;

    if (self.isActive) {
        fillPathGradient(path, buttonGradient);
    } else {
        fillPath(path, nil);
    }

    __auto_type colorArea = ^CGRect(BOOL smoothed) {
        CGRect frame = cellFrame;
        if (smoothed) frame = NSInsetRect(cellFrame, 0.5, 0.5);
        frame.size.width -= frame.size.height;
        return frame;
    };

    __auto_type buttonArea = ^CGRect(BOOL smoothed) {
        CGRect frame = cellFrame;
        if (smoothed) frame = NSInsetRect(frame, 0.5, 0.5);
        frame.origin.x += (frame.size.width - frame.size.height);
        frame.size.width = frame.size.height;
        return frame;
    };

    [path stroke];

    if (drawButtonArea) {
        NSRect imageRect = NSInsetRect(buttonArea(YES), 3, 3);
        [[NSImage imageNamed:NSImageNameColorPanel] drawInRect:imageRect];
        [NSBezierPath clipRect:colorArea(NO)];
    } else {
        CGFloat adjustedRadius = _cornerRadius * ((cellFrame.size.height - 3) / cellFrame.size.height);
        NSRect smoothRect = NSInsetRect(cellFrame, 3.0, 3.0);
        path = [NSBezierPath bezierPathWithRoundedRect:smoothRect xRadius:adjustedRadius yRadius:adjustedRadius];
    }

    if (self.color.alphaComponent < 1) {
        fillPath(path, [NSColor whiteColor]);
        NSRect area = colorArea(NO);
        NSBezierPath *blackPath = [NSBezierPath new];
        CGPoint point = area.origin;
        [blackPath moveToPoint:point];
        point = NSMakePoint(area.size.width, area.size.height);
        [blackPath lineToPoint:point];
        point.x = area.origin.x;
        [blackPath lineToPoint:point];
        [blackPath closePath];
        [path addClip];
        fillPath(blackPath, [NSColor blackColor]);
    }
    fillPath(path, self.color);

    [path setClip];
    [path stroke];

    if (!self.isEnabled)
        fillPath(path, [NSColor colorWithCalibratedWhite:1.0 alpha:0.25]);

    [self applyActive];
}

- (void)applyActive
{
    NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];

    if (self.isActive)
        colorPanel.showsAlpha = _allowsClearColor;
    else [colorPanel close];
}

@end
