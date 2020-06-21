
#import <Foundation/Foundation.h>

NSString *frontBundleName(void);

bool wildcardArray(NSString *bundleName, NSArray *wildFilters, BOOL ignoreCase);

bool wildcardString(NSString *bundleName, NSString *wildFilter, BOOL ignoreCase);


@interface LoginServicesHelper : NSObject

+ (BOOL)isLoginItem;
+ (void)makeLoginItemActive:(BOOL)active;

@end
