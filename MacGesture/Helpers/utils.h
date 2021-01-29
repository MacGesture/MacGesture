
#import <Foundation/Foundation.h>

NSString *frontBundleName(void);

bool wildcardArray(NSString *bundleName, NSArray *wildFilters, BOOL ignoreCase);

bool wildcardString(NSString *bundleName, NSString *wildFilter, BOOL ignoreCase);

@interface NSArray<ObjectType> (Utils)

- (NSArray<__kindof NSObject *> *)mappedArrayUsingBlock:(__kindof NSObject *(NS_NOESCAPE ^)(ObjectType obj, NSUInteger idx))block;

@end

@interface LoginServicesHelper : NSObject

+ (BOOL)isLoginItem;
+ (void)makeLoginItemActive:(BOOL)active;

@end
