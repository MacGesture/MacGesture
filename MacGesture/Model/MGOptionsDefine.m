#import "MGOptionsDefine.h"

@implementation MGOptionsDefine
+ (void)setLineColor:(NSColor *)color {
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
    [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:OPTIONS_LINE_COLOR_ID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSColor *)getLineColor {
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:OPTIONS_LINE_COLOR_ID];
    NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    return color ? color : [NSColor blueColor];
}
@end