//
//  CanvasView.m
//  MouseGesture
//
//  Created by keakon on 11-11-14.
//  Copyright (c) 2011年 keakon.net. All rights reserved.
//

#import "CanvasWindow.h"

@implementation CanvasWindow

- (id)initWithContentRect:(NSRect)contentRect
{
	self = [super initWithContentRect:contentRect styleMask:(NSBorderlessWindowMask) backing:NSBackingStoreBuffered defer:NO];
	if (self) {
		self.backgroundColor = NSColor.clearColor;
		self.level = CGShieldingWindowLevel();
		self.opaque = NO;
		self.hasShadow = NO;
		self.hidesOnDeactivate = NO;
	}

	return self;
}

@end
