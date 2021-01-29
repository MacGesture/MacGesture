//
//  AppleScriptsList.h
//  MacGesture
//
//  Created by iMac on 3/19/16.
//  Copyright © 2016 Codefalling. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppleScriptsList : NSObject

+ (AppleScriptsList *)sharedAppleScriptsList;

- (void)addAppleScript:(NSString *)title
                      script:(NSString *)script;

- (void)reInit;

- (void)save;

- (NSInteger)count;

- (NSString *)titleAtIndex:(NSUInteger)index;

- (NSString *)scriptAtIndex:(NSUInteger)index;

- (NSString *)idAtIndex:(NSUInteger)index;

- (NSString *)getScriptById:(NSString *)id;

- (NSInteger)getIndexById:(NSString *)id;

- (void)setScriptAtIndex:(NSUInteger)index script:(NSString *)script;

- (void)setTitleAtIndex:(NSUInteger)index title:(NSString *)title;

- (void)removeAtIndex:(NSUInteger)index;

@property (strong, atomic) NSMutableArray<NSMutableDictionary *> *appleScriptsList;

@end
