//
//  CanvasView.h
//  MouseGesture
//
//  Created by keakon on 11-11-14.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CanvasView : NSView

@property (atomic) NSPoint lastLocation;
@property (atomic) NSUInteger radius;
@property (nonatomic, copy) NSArray<NSValue *> *points; // `NSPoint`
@property (nonatomic, copy) NSString *directionToDraw;

- (void)clear;

- (void)resizeTo:(NSRect)frame;

- (void)setEnable:(BOOL)shouldEnable;

- (void)writeDirection:(NSString *)directionStr;

- (void)reload;

@end
