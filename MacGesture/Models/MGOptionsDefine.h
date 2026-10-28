
#import <Cocoa/Cocoa.h>

#define OPTIONS_LINE_COLOR_ID @"lineColor"
#define OPTIONS_PREVIEW_COLOR_ID @"previewColor"
#define OPTIONS_PREVIEW_BG_COLOR_ID @"previewBgColor"
#define OPTIONS_NOTE_COLOR_ID @"noteColor"
#define OPTIONS_NOTE_BG_COLOR_ID @"noteBgColor"
#define OPTIONS_PREVIEW_POSITION @"previewPosition"

typedef NS_OPTIONS(NSUInteger, MGPreviewPosition) {
    MGPreviewPositionNone   =      0,
    MGPreviewPositionLeft   = 1 << 0, // 1
    MGPreviewPositionCenter = 1 << 1, // 2
    MGPreviewPositionRight  = 1 << 2, // 4
    MGPreviewPositionTop    = 1 << 3, // 8
    MGPreviewPositionMiddle = 1 << 4, // 16
    MGPreviewPositionBottom = 1 << 5, // 32
    // Helpers
    MGPreviewPositionVeryCenter   = MGPreviewPositionMiddle | MGPreviewPositionCenter, // 18
    MGPreviewPositionTopLeft      = MGPreviewPositionTop    | MGPreviewPositionLeft,   // 9
    MGPreviewPositionTopCenter    = MGPreviewPositionTop    | MGPreviewPositionCenter, // 10
    MGPreviewPositionTopRight     = MGPreviewPositionTop    | MGPreviewPositionRight,  // 12
    MGPreviewPositionBottomLeft   = MGPreviewPositionBottom | MGPreviewPositionLeft,   // 33
    MGPreviewPositionBottomCenter = MGPreviewPositionBottom | MGPreviewPositionCenter, // 34
    MGPreviewPositionBottomRight  = MGPreviewPositionBottom | MGPreviewPositionRight,  // 36
};

NS_ASSUME_NONNULL_BEGIN

@interface MGOptionsDefine : NSObject

+ (void)setLineColor:(nullable NSColor *)color;
+ (NSColor *)getLineColor;

+ (void)setPreviewColor:(nullable NSColor *)color;
+ (NSColor *)getPreviewColor;

+ (void)setPreviewBgColor:(nullable NSColor *)color;
+ (NSColor *)getPreviewBgColor;

+ (void)setNoteColor:(nullable NSColor *)color;
+ (NSColor *)getNoteColor;

+ (void)setNoteBgColor:(nullable NSColor *)color;
+ (NSColor *)getNoteBgColor;

+ (void)setPreviewPosition:(MGPreviewPosition)position;
+ (MGPreviewPosition)getPreviewPosition;

+ (void)restoreDefaults;

@end

NS_ASSUME_NONNULL_END
