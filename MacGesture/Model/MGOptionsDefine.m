#import "MGOptionsDefine.h"
#import "HexColors.h"

@implementation MGOptionsDefine
+ (void)setLineColor:(NSColor *)color {
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
    [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:OPTIONS_LINE_COLOR_ID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSColor *)getLineColor {
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:OPTIONS_LINE_COLOR_ID];
    if (colorData) {
        NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
        return color ? color : [self defaultLineColor];
    } else {
        [self resetColor];
        return [self defaultLineColor];
    }
}

+ (void)resetColor {
    [self setLineColor:[self defaultLineColor]];
}

+ (NSColor *)defaultLineColor {
    return [NSColor hx_colorWithHexRGBAString:[[NSUserDefaults standardUserDefaults] stringForKey:@"defaultLineColor"]];
}
@end