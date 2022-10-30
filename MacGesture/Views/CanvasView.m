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

@interface CanvasView ()

@property (nonatomic, weak) NSUserDefaults *defaults;

@property (nonatomic, strong) NSColor *lineColor;
@property (nonatomic, strong) NSColor *noteColor;
@property (nonatomic, strong) NSColor *noteBgColor;
@property (nonatomic, strong) NSColor *previewColor;
@property (nonatomic, strong) NSColor *previewBgColor;

@end

@implementation CanvasView

static NSImage *leftImage;
static NSImage *rightImage;
static NSImage *upImage;
static NSImage *downImage;
static NSImage *scrollImage;
static NSImage *cursorImage;

static CGFloat screenInset = 32;
static CGFloat previewPadding = 16;
static CGFloat notePadding = 10;
static CGFloat previewNoteGap = 32;
static CGFloat previewCornerRadius = 16;
static CGFloat noteCornerRadius = 16;

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

- (instancetype)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _points = @[ ];
        _directionToDraw = @"";
        _radius = 2;

        [self refreshColors];
        [self refreshImages];

        _defaults = [NSUserDefaults standardUserDefaults];

        [[NSNotificationCenter defaultCenter] addObserverForName:@"PrefsDidClose" object:nil
          queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [self reload];
        }];

    }

    return self;
}

- (void)refreshColors
{
    _lineColor = [MGOptionsDefine getLineColor];
    _noteColor = [MGOptionsDefine getNoteColor];
    _noteBgColor = [MGOptionsDefine getNoteBgColor];
    _previewColor = [MGOptionsDefine getPreviewColor];
    _previewBgColor = [MGOptionsDefine getPreviewBgColor];
    if (self.superview) self.needsDisplay = YES;
}

- (void)refreshImages
{
    NSColor *color = _previewColor;
    leftImage = [self convertImage:[NSImage imageNamed:@"gesture-icon-left"] toSpecifiedColor:color];
    rightImage = [self convertImage:[NSImage imageNamed:@"gesture-icon-right"] toSpecifiedColor:color];
    downImage = [self convertImage:[NSImage imageNamed:@"gesture-icon-down"] toSpecifiedColor:color];
    upImage = [self convertImage:[NSImage imageNamed:@"gesture-icon-up"] toSpecifiedColor:color];
    scrollImage = [self convertImage:[NSImage imageNamed:@"gesture-icon-scroll"] toSpecifiedColor:color];
    cursorImage = [self convertImage:[NSImage imageNamed:@"gesture-icon-mouse"] toSpecifiedColor:color];
    if (self.superview) self.needsDisplay = YES;
}

- (void)reload
{
    [self refreshColors];
    [self refreshImages];
}

- (float)getGestureImageScale
{
    return [_defaults floatForKey:@"gestureSize"] / 100 * 1.25;
}



- (NSRect)rawPreviewRectWithElementWidth:(CGFloat)elmWidth elementHeight:(CGFloat)elmHeight
                           elementsCount:(NSUInteger)elmsCount paddingReserve:(CGFloat)paddingReserve
{

    MGPreviewPosition position = [MGOptionsDefine getPreviewPosition];

    // Screen elements
    CGSize screenSize = self.window.frame.size;
    CGFloat menuBarHeight = 25;

    // Width + Height
    CGFloat width = elmsCount * elmWidth + (elmsCount - 1) * paddingReserve;
    CGFloat height = elmHeight;

    // X position
    CGFloat x = (screenSize.width - width) / 2; // centered

    if (position & MGPreviewPositionOptionLeft || position & MGPreviewPositionOptionRight) {
        x = screenInset + paddingReserve;
        if (position & MGPreviewPositionOptionRight)
            x = screenSize.width - width - paddingReserve - x;
    }

    // Y position
    CGFloat y = (screenSize.height - height) / 2; // centered

    if (position & MGPreviewPositionOptionTop || position & MGPreviewPositionOptionBottom) {
        y = screenInset + paddingReserve;
        if (position & MGPreviewPositionOptionTop)
            y = screenSize.height - height - y - menuBarHeight;
    }

    return NSMakeRect(x, y, width, height);
}

- (NSRect)positionedNoteSize:(CGSize)noteSize elementHeight:(CGFloat)elmHeight
              paddingReserve:(CGFloat)paddingReserve elementPaddingReserve:(CGFloat)elementPaddingReserve
{
    MGPreviewPosition position = [MGOptionsDefine getPreviewPosition];

    // Screen elements
    CGSize screenSize = self.window.frame.size;
    CGFloat menuBarHeight = 25;

    // Width + Height
    CGFloat width = noteSize.width;
    CGFloat height = noteSize.height;

    // X position
    CGFloat x = (screenSize.width - width) / 2; // centered

    if (position & MGPreviewPositionOptionLeft || position & MGPreviewPositionOptionRight) {
        x = screenInset + paddingReserve;
        if (position & MGPreviewPositionOptionRight)
            x = screenSize.width - width - paddingReserve - x;
    }

    // Y position
    CGFloat y = (screenSize.height - height) / 2; // centered, above preview
    CGFloat yPreviewShift = elmHeight + elementPaddingReserve + previewNoteGap;

    if (position & MGPreviewPositionOptionTop || position & MGPreviewPositionOptionBottom) {
        y = screenInset + paddingReserve;
        if (position & MGPreviewPositionOptionTop) {
            y = screenSize.height - height - y - menuBarHeight;
            yPreviewShift *= -1;
        }
    } else yPreviewShift += (height - elmHeight)/2;

    y += yPreviewShift;

    return NSMakeRect(x, y, width, height);
}

- (void)drawPreview
{
    BOOL merge = [_defaults boolForKey:@"mergeConsecutiveIdenticalGestures"];

    NSString *direction = _directionToDraw;
    NSUInteger numberToDraw = direction.length;

    if (merge) {
        for (NSUInteger i = 0; i < direction.length; i++) {
            numberToDraw++;
            char ch = [direction characterAtIndex:i];
            if (ch == 'u' || ch == 'd' || ch == 'Z') {
                for (; i < direction.length && [direction characterAtIndex:i] == ch; i++);
                i--;
            }
        }
    }

    if (numberToDraw < 1) return;

    CGFloat scale = [self getGestureImageScale];
    CGFloat scaledHeight = scale * leftImage.size.height;
    CGFloat scaledWidth = scale * leftImage.size.width;

    CGFloat bgPadding = previewPadding;
    NSRect rawRect = [self rawPreviewRectWithElementWidth:scaledWidth
        elementHeight:scaledHeight elementsCount:numberToDraw paddingReserve:bgPadding];
    NSRect bgRect = NSInsetRect(rawRect, -bgPadding, -bgPadding);

    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];

    NSBezierPath *bgPath = [NSBezierPath bezierPathWithRoundedRect:
        bgRect xRadius:previewCornerRadius yRadius:previewCornerRadius];
    NSColor *bgColor = _previewBgColor;
    [bgColor setFill];
    [bgPath fill];

    NSInteger y = rawRect.origin.y;
    NSInteger beginx = rawRect.origin.x;
    int index = 0;

    for (NSInteger i = 0; i < direction.length; i++) {
        NSImage *image = nil;
        char ch = [direction characterAtIndex:i];
        switch (ch) {
            case 'L': image = leftImage; break;
            case 'R': image = rightImage; break;
            case 'U':
            case 'u': image = upImage; break;
            case 'D':
            case 'd': image = downImage; break;
            case 'Z': image = cursorImage; break; // [[NSCursor arrowCursor] image]
            default:  break;
        }

        if (merge) {
            int count = 0;
            for (; i < direction.length && [direction characterAtIndex:i] == ch; i++) {
                count++;
            }
            i--;
        }

        if (ch == 'u' || ch == 'd') {
            double frac = 0.65;

//            if (count > 1) {
//                [[NSString stringWithFormat:@"%d", count] drawWithRect:
//                    NSMakeRect(beginx + index * scaledWidth, y - (frac - 0.5)*scaledHeight,
//                               scaledWidth*(1-frac), scaledHeight*(1-frac)
//                    ) options:NSStringDrawingUsesFontLeading attributes: nil context: nil];
//            }

            [scrollImage drawInRect:NSMakeRect(
                beginx + index * (scaledWidth + bgPadding) + frac * scaledWidth, y - (frac - 0.5) * scaledHeight,
                scaledWidth * (1 - frac), scaledHeight * (1 - frac)
            ) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
        }

        [image drawInRect:NSMakeRect(beginx + index * (scaledWidth + bgPadding), y, scaledWidth, scaledHeight)
            fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];

        index++;
    }

    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawNote
{
    NSString *direction = _directionToDraw;

    NSInteger index = [[RulesList sharedRulesList] suitedRuleWithGesture:direction];
    NSString *note = @"";
    if (index == -1)
        return;
    else
        note = [[RulesList sharedRulesList] noteAtIndex:index];

    if (![note isEqualToString:@""]) {

        NSString *fontName = [_defaults objectForKey:@"noteFontName"];
        double fontSize = [_defaults doubleForKey:@"noteFontSize"];

        if (!fontName) return;

        NSFont *font = [NSFont fontWithName:fontName size:fontSize];
        NSColor *fontColor = _noteColor;

        if (!font) {

            NSDictionary<NSString *, NSNumber *> *systemFonts = @{
                @".SFNS-Ultralight":   @(NSFontWeightUltraLight), // 100
                @".SFNS-Thin":         @(NSFontWeightThin),       // 200
                @".SFNS-Light":        @(NSFontWeightLight),      // 300
                @".SFNS-Regular":      @(NSFontWeightRegular),    // 400
                @".SFNS-Medium":       @(NSFontWeightMedium),     // 500
                @".SFNS-Semibold":     @(NSFontWeightSemibold),   // 600
                @".SFNS-Bold":         @(NSFontWeightBold),       // 700
                @".SFNS-Heavy":        @(NSFontWeightHeavy),      // 800
                @".SFNS-Black":        @(NSFontWeightBlack),      // 900
            };

            NSAssert(systemFonts[fontName], @"No font found for '%@' name", fontName);

            NSFontWeight fontWeight = systemFonts[fontName].unsignedIntegerValue ?: NSFontWeightMedium;

            font = [NSFont systemFontOfSize:fontSize weight:fontWeight];
        }

//        NSLog(@"%p %p", font, noteColor);
        NSDictionary *textAttributes = @{
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: fontColor,
        };

        CGSize size = [note sizeWithAttributes:textAttributes];
        size.width += fontSize/2;

        CGFloat previewBgPadding = previewPadding;
        CGFloat noteBgPadding = notePadding;
        CGFloat imageScale = [self getGestureImageScale];
        CGFloat scaledImageHeight = imageScale * leftImage.size.height;
        NSRect textRect = [self positionedNoteSize:size elementHeight:
            scaledImageHeight paddingReserve:noteBgPadding elementPaddingReserve:previewBgPadding];

        CGFloat x = textRect.origin.x;
        CGFloat y = textRect.origin.y;

        NSRect bgRect = NSInsetRect(textRect, -noteBgPadding, -noteBgPadding);
        CGFloat bgRadius = MIN(noteCornerRadius, MIN(bgRect.size.width/2, bgRect.size.height/2));
        NSBezierPath *bgPath = [NSBezierPath bezierPathWithRoundedRect:bgRect xRadius:bgRadius yRadius:bgRadius];
        NSColor *bgColor = _noteBgColor;
        [bgColor setFill];
        [bgPath fill];

        x += fontSize/4;

        [note drawAtPoint:NSMakePoint(x, y) withAttributes:textAttributes];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Draw mouse line
    if (![_defaults boolForKey:@"disableMousePath"])
        [self drawMouseLine];

    // Draw gesture preview
    if ([_defaults boolForKey:@"showGesturePreview"])
        [self drawPreview];

    // Draw gesture note
    if ([_defaults boolForKey:@"showGestureNote"])
        [self drawNote];
}

- (void)drawMouseLine {
    NSBezierPath *path = [NSBezierPath bezierPath];
    path.lineWidth = _radius * 2;
    path.lineCapStyle = NSLineCapStyleRound;
    path.lineJoinStyle = NSLineJoinStyleRound;
    [_lineColor setStroke];

    NSArray<NSValue *> *points = [_points copy];

    if (points.count < 2) return;

    for (NSValue *pValue in points) {
        NSPoint point = [pValue pointValue];
        if (pValue == points.firstObject)
            [path moveToPoint:point];
        else [path lineToPoint:point];
    }

    [path stroke];
}

- (void)drawLineFromPoint:(NSPoint)point1 toPoint:(NSPoint)point2 {
    NSMutableArray<NSValue *> *points = [_points mutableCopy];
    [points addObject:[NSValue valueWithPoint:point1]];
    [points addObject:[NSValue valueWithPoint:point2]];
    _points = [points copy];
    self.needsDisplay = YES;
}

- (void)clear {
    _points = @[ ];
    _directionToDraw = @"";
    self.needsDisplay = YES;
}

- (void)resizeTo:(NSRect)frame {
    self.frame = frame;
    self.needsDisplay = YES;
}

- (void)mouseDown:(NSEvent *)event {
//    // Debugging
//    [self refreshColors];
//    [self refreshImages];

    _lastLocation = [NSEvent mouseLocation];
    NSWindow *w = self.window;
    _lastLocation.x -= w.frame.origin.x;
    _lastLocation.y -= w.frame.origin.y;
#ifdef DEBUG
//    NSLog(@"mouseDown frame:%@, window:%@, screen:%@, point:%@",
//          NSStringFromRect(self.frame), NSStringFromRect(w.frame),
//          NSStringFromRect(s.frame), NSStringFromPoint(lastLocation));
#endif
    _points = @[ [NSValue valueWithPoint:_lastLocation] ];

#ifdef DEBUG
    NSLog(@"%@", NSStringFromPoint(_lastLocation));
#endif
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint newLocation = event.locationInWindow;
    NSWindow *w = self.window;
    newLocation.x -= w.frame.origin.x;
    newLocation.y -= w.frame.origin.y;

#ifdef DEBUG
//    NSLog(@"mouseDragged frame:%@, window:%@, screen:%@, point:%@",
//          NSStringFromRect(self.frame), NSStringFromRect(w.frame),
//          NSStringFromRect(s.frame), NSStringFromPoint(newLocation));
#endif

    _points = [_points arrayByAddingObject:[NSValue valueWithPoint:newLocation]];
    _lastLocation = newLocation;

    self.needsDisplay = YES;
}

- (void)setEnable:(BOOL)shouldEnable {
    // No-op. Suppress warning and avoid possible selector not found errors.
}

- (void)mouseUp:(NSEvent *)event {
    [self clear];
}

- (void)writeDirection:(NSString *)directionStr {
    _directionToDraw = directionStr;
    self.needsDisplay = YES;
}

@end
