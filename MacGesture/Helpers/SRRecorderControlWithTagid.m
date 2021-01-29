//
// Created by codefalling on 15/10/17.
// Copyright (c) 2015 MacGesture. All rights reserved.
//

#import "SRRecorderControlWithTagid.h"

@interface MGSRRecorderControlStyle: SRRecorderControlStyle

@property (atomic) CGFloat heightDiff;

@end

@implementation MGSRRecorderControlStyle

- (NSEdgeInsets)alignmentRectInsets {
    NSEdgeInsets insets = [super alignmentRectInsets];
    insets.top += _heightDiff/2;
    return insets;
}

- (NSEdgeInsets)focusRingInsets {
    NSEdgeInsets insets = [super focusRingInsets];
    insets.top -= _heightDiff/2;
    return insets;
}

@end

@implementation SRRecorderControlWithTagid
    
@synthesize tagid = tagis_;

- (instancetype)init
{
    if (self = [super init])
    {
        self.style = [MGSRRecorderControlStyle new];
    }

    return self;
}

- (void)setFrame:(NSRect)frame
{
    CGFloat defaultHeight = 26;
    [super setFrame:frame];
    MGSRRecorderControlStyle *style = (id)self.style;
    style.heightDiff = frame.size.height - defaultHeight;
}

@end
