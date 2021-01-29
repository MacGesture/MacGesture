//
//  AppleScriptsList.m
//  MacGesture
//
//  Created by iMac on 3/19/16.
//  Copyright © 2016 Codefalling. All rights reserved.
//

#import "AppleScriptsList.h"

@implementation AppleScriptsList

// From http://stackoverflow.com/questions/7997594/singleton-with-arc
+ (AppleScriptsList *)sharedAppleScriptsList {
    static dispatch_once_t pred;
    static AppleScriptsList *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[super alloc] init];
    });
    return sharedInstance;
}

- (void)reInit {
    [_appleScriptsList removeAllObjects];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSData *data;
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        data = [userDefaults objectForKey:@"appleScripts"];
        _appleScriptsList = [[NSMutableArray alloc] initWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
        if (_appleScriptsList == nil) {
            _appleScriptsList = [[NSMutableArray alloc] init];
        }
    }

    return self;
}

- (NSData *)nsData {
    return [NSKeyedArchiver archivedDataWithRootObject:_appleScriptsList];
}

- (void)save {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.nsData forKey:@"appleScripts"];
    [userDefaults synchronize];
}

- (NSInteger)count {
    return [_appleScriptsList count];
}

- (NSString *)titleAtIndex:(NSUInteger)index {
    return _appleScriptsList[index][@"title"];
}

- (NSString *)scriptAtIndex:(NSUInteger)index {
    return _appleScriptsList[index][@"script"];
}

- (NSString *)idAtIndex:(NSUInteger)index {
    return _appleScriptsList[index][@"id"];
}

- (NSString *)getScriptById:(NSString *)id {
    for (NSMutableDictionary *dict in _appleScriptsList) {
        if ([dict[@"id"] isEqualToString:id]) {
            return dict[@"script"];
        }
    }
    return @"";
}

- (NSInteger)getIndexById:(NSString *)id {
    NSInteger i = 0;
    for (NSMutableDictionary *dict in _appleScriptsList) {
        if ([dict[@"id"] isEqualToString:id]) {
            return i;
        }
        i++;
    }
    return -1;
}

- (void)setScriptAtIndex:(NSUInteger)index script:(NSString *)script {
    _appleScriptsList[index][@"script"] = script;
}

- (void)setTitleAtIndex:(NSUInteger)index title:(NSString *)title {
    _appleScriptsList[index][@"title"] = title;
}

- (void)addAppleScript:(NSString *)title
                script:(NSString *)script {
    NSMutableDictionary *array = [[NSMutableDictionary alloc] init];
    array[@"title"] = title;
    array[@"script"] = script;
    array[@"id"] = [[NSProcessInfo processInfo] globallyUniqueString];
    [_appleScriptsList addObject:array];
}

- (void)removeAtIndex:(NSUInteger)index {
    [_appleScriptsList removeObjectAtIndex:index];
}

@end
