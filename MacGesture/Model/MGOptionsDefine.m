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
        [self resetColors];
        return [self defaultLineColor];
    }
}
+ (void)setNoteColor:(NSColor *)color {
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
    [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:OPTIONS_NOTE_COLOR_ID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSColor *)getNoteColor {
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:OPTIONS_NOTE_COLOR_ID];
    if (colorData) {
        NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
        return color ? color : [self defaultNoteColor];
    } else {
        [self resetColors];
        return [self defaultNoteColor];
    }
}

+ (void)resetColors {
    [self setLineColor:[self defaultLineColor]];
    [self setNoteColor:[self defaultNoteColor]];
}

+ (NSColor *)defaultLineColor {
    return [NSColor hx_colorWithHexRGBAString:[[NSUserDefaults standardUserDefaults] stringForKey:@"defaultLineColor"]];
}
+ (NSColor *)defaultNoteColor {
    return [NSColor hx_colorWithHexRGBAString:[[NSUserDefaults standardUserDefaults] stringForKey:@"defaultNoteColor"]];
}
@end
