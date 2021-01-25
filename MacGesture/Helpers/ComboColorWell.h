//
//  ComboColorWell.h
//  MacGesture
//
//  Created by Michal Zelinka on 24/01/2021.
//  Copyright © 2021 MacGesture. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

IB_DESIGNABLE
@interface ComboColorWell : NSColorWell

@property (copy) IBInspectable NSColor *color;
@property (nonatomic, assign) IBInspectable BOOL allowsClearColor;
@property (nonatomic, assign) IBInspectable BOOL showsColorWellButton;
@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;

@end

NS_ASSUME_NONNULL_END
