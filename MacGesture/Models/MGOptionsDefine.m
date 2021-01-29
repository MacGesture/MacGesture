
#import "MGOptionsDefine.h"

@implementation MGOptionsDefine

static NSUserDefaults *defaults;

+ (void)load
{
    defaults = [NSUserDefaults standardUserDefaults];
}

+ (void)setLineColor:(NSColor *)color {
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
    [defaults setObject:colorData forKey:OPTIONS_LINE_COLOR_ID];
}

+ (NSColor *)getLineColor {
    NSData *colorData = [defaults objectForKey:OPTIONS_LINE_COLOR_ID];
    if (!colorData) return [self defaultColor];
    NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    return color ?: [self defaultColor];
}

+ (void)setPreviewColor:(NSColor *)color {
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
    [defaults setObject:colorData forKey:OPTIONS_PREVIEW_COLOR_ID];
}

+ (NSColor *)getPreviewColor {
    NSData *colorData = [defaults objectForKey:OPTIONS_PREVIEW_COLOR_ID];
    if (!colorData) return [self defaultColor];
    NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    return color ?: [self defaultColor];
}

+ (void)setPreviewBgColor:(NSColor *)color {
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
    [defaults setObject:colorData forKey:OPTIONS_PREVIEW_BG_COLOR_ID];
}

+ (NSColor *)getPreviewBgColor {
    NSData *colorData = [defaults objectForKey:OPTIONS_PREVIEW_BG_COLOR_ID];
    if (!colorData) return [self defaultColor];
    NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    return color ?: [self defaultBgColor];
}

+ (void)setNoteColor:(NSColor *)color {
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
    [defaults setObject:colorData forKey:OPTIONS_NOTE_COLOR_ID];
}

+ (NSColor *)getNoteColor {
    NSData *colorData = [defaults objectForKey:OPTIONS_NOTE_COLOR_ID];
    if (!colorData) return [self defaultColor];
    NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    return color ?: [self defaultColor];
}

+ (void)setNoteBgColor:(NSColor *)color {
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:color];
    [defaults setObject:colorData forKey:OPTIONS_NOTE_BG_COLOR_ID];
}

+ (NSColor *)getNoteBgColor {
    NSData *colorData = [defaults objectForKey:OPTIONS_NOTE_BG_COLOR_ID];
    if (!colorData) return [self defaultColor];
    NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
    return color ?: [self defaultBgColor];
}

+ (void)setPreviewPosition:(MGPreviewPosition)position {
    [defaults setInteger:position forKey:OPTIONS_PREVIEW_POSITION];
}

+ (MGPreviewPosition)getPreviewPosition {
    MGPreviewPosition position = [defaults integerForKey:OPTIONS_PREVIEW_POSITION];
    return (position != 0) ? position : MGPreviewPositionCenter;
}

+ (void)restoreDefaults {
    NSColor *defaultColor = [self defaultColor];
    NSColor *defaultBgColor = [self defaultBgColor];
    [self setLineColor:defaultColor];
    [self setPreviewColor:defaultColor];
    [self setPreviewBgColor:defaultBgColor];
    [self setNoteColor:defaultColor];
    [self setNoteBgColor:defaultBgColor];
    [self setPreviewPosition:MGPreviewPositionCenter];
}

+ (NSColor *)defaultColor {
    return [NSColor textColor];
}

+ (NSColor *)defaultBgColor {
    return [[NSColor textColor] colorWithAlphaComponent:0.1];
}

@end
