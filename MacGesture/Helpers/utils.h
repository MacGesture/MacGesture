
#import <Foundation/Foundation.h>
#import "Foundation+BetterNSCopying.h"

NSString *frontBundleName(void);

BOOL wildcardArray(NSString *bundleName, NSArray *wildFilters, BOOL ignoreCase);

BOOL wildcardString(NSString *bundleName, NSString *wildFilter, BOOL ignoreCase);

@interface NSArray<ObjectType> (Utils)

- (NSArray<__kindof NSObject *> *)mappedArrayUsingBlock:(__kindof NSObject *(NS_NOESCAPE ^)(ObjectType obj, NSUInteger idx))block;

@end

@interface NSObject (Utils)

- (id)parsedKindOf:(Class)class;

@end

@interface LoginServicesHelper : NSObject

+ (BOOL)isLoginItem;
+ (void)makeLoginItemActive:(BOOL)active;

@end
