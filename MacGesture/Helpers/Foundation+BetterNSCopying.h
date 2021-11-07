//
//  Foundation+BetterNSCopying.h
//
//  Created by Michal Zelinka on 11/03/2021.
//  Copyright © 2021 Michal Zelinka. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSValue (BetterNSCopying)

- (instancetype)copy;

@end

@interface NSString (BetterNSCopying)

- (NSString *)copy;
- (NSMutableString *)mutableCopy;

@end

@interface NSDictionary<KeyType, ObjectType> (BetterNSCopying)

- (NSDictionary<KeyType, ObjectType> *)copy;
- (NSMutableDictionary<KeyType, ObjectType> *)mutableCopy;

@end

@interface NSArray<ObjectType> (BetterNSCopying)

- (NSArray<ObjectType> *)copy;
- (NSMutableArray<ObjectType> *)mutableCopy;

@end

@interface NSSet<__covariant ObjectType> (BetterNSCopying)

- (NSSet<ObjectType> *)copy;
- (NSMutableSet<ObjectType> *)mutableCopy;

@end

@interface NSData (BetterNSCopying)

- (NSData *)copy;
- (NSMutableData *)mutableCopy;

@end

NS_ASSUME_NONNULL_END
