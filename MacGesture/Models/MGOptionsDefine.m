
#import "MGOptionsDefine.h"
#import "utils.h"

@implementation MGColorTransformer

+ (NSArray<Class> *)allowedTopLevelClasses {
    return @[ NSColor.class ];
}

@end

@implementation MGOptionsDefine

static NSUserDefaults *defaults;

+ (void)load
{
    defaults = [NSUserDefaults standardUserDefaults];
    [NSValueTransformer setValueTransformer:[MGColorTransformer new] forName:@"MGColorTransformer"];
}

+ (void)setLineColor:(NSColor *)color {
    NSData *colorData = MGArchive(color);
    [defaults setObject:colorData forKey:OPTIONS_LINE_COLOR_ID];
}

+ (NSColor *)getLineColor {
    NSData *colorData = [defaults objectForKey:OPTIONS_LINE_COLOR_ID];
    if (!colorData) return [self defaultColor];
    NSColor *color = MGUnarchive(colorData, NSColor.class);
    return color ?: [self defaultColor];
}

+ (void)setPreviewColor:(NSColor *)color {
    NSData *colorData = MGArchive(color);
    [defaults setObject:colorData forKey:OPTIONS_PREVIEW_COLOR_ID];
}

+ (NSColor *)getPreviewColor {
    NSData *colorData = [defaults objectForKey:OPTIONS_PREVIEW_COLOR_ID];
    if (!colorData) return [self defaultColor];
    NSColor *color = MGUnarchive(colorData, NSColor.class);
    return color ?: [self defaultColor];
}

+ (void)setPreviewBgColor:(NSColor *)color {
    NSData *colorData = MGArchive(color);
    [defaults setObject:colorData forKey:OPTIONS_PREVIEW_BG_COLOR_ID];
}

+ (NSColor *)getPreviewBgColor {
    NSData *colorData = [defaults objectForKey:OPTIONS_PREVIEW_BG_COLOR_ID];
    if (!colorData) return [self defaultBgColor];
    NSColor *color = MGUnarchive(colorData, NSColor.class);
    return color ?: [self defaultBgColor];
}

+ (void)setNoteColor:(NSColor *)color {
    NSData *colorData = MGArchive(color);
    [defaults setObject:colorData forKey:OPTIONS_NOTE_COLOR_ID];
}

+ (NSColor *)getNoteColor {
    NSData *colorData = [defaults objectForKey:OPTIONS_NOTE_COLOR_ID];
    if (!colorData) return [self defaultColor];
    NSColor *color = MGUnarchive(colorData, NSColor.class);
    return color ?: [self defaultColor];
}

+ (void)setNoteBgColor:(NSColor *)color {
    NSData *colorData = MGArchive(color);
    [defaults setObject:colorData forKey:OPTIONS_NOTE_BG_COLOR_ID];
}

+ (NSColor *)getNoteBgColor {
    NSData *colorData = [defaults objectForKey:OPTIONS_NOTE_BG_COLOR_ID];
    if (!colorData) return [self defaultBgColor];
    NSColor *color = MGUnarchive(colorData, NSColor.class);
    return color ?: [self defaultBgColor];
}

+ (void)setPreviewPosition:(MGPreviewPosition)position {
    [defaults setInteger:position forKey:OPTIONS_PREVIEW_POSITION];
}

+ (MGPreviewPosition)getPreviewPosition {
    MGPreviewPosition position = [defaults integerForKey:OPTIONS_PREVIEW_POSITION];
    return (position != 0) ? position : MGPreviewPositionVeryCenter;
}

+ (void)restoreDefaults {
    NSColor *defaultColor = [self defaultColor];
    NSColor *defaultBgColor = [self defaultBgColor];
    [self setLineColor:defaultColor];
    [self setPreviewColor:defaultColor];
    [self setPreviewBgColor:defaultBgColor];
    [self setNoteColor:defaultColor];
    [self setNoteBgColor:defaultBgColor];
    [self setPreviewPosition:MGPreviewPositionVeryCenter];
}

+ (NSColor *)defaultColor {
    return [NSColor textColor];
}

+ (NSColor *)defaultBgColor {
    return [[NSColor textColor] colorWithAlphaComponent:0.1];
}

@end
