
#import <Cocoa/Cocoa.h>

#define OPTIONS_LINE_COLOR_ID @"lineColor"
#define OPTIONS_PREVIEW_COLOR_ID @"previewColor"
#define OPTIONS_PREVIEW_BG_COLOR_ID @"previewBgColor"
#define OPTIONS_NOTE_COLOR_ID @"noteColor"
#define OPTIONS_NOTE_BG_COLOR_ID @"noteBgColor"
#define OPTIONS_PREVIEW_POSITION @"previewPosition"

typedef NS_OPTIONS(NSUInteger, MGPreviewPositionOption) {
    MGPreviewPositionOptionNone   =      0,
    MGPreviewPositionOptionLeft   = 1 << 0, // 1
    MGPreviewPositionOptionCenter = 1 << 1, // 2
    MGPreviewPositionOptionRight  = 1 << 2, // 4
    MGPreviewPositionOptionTop    = 1 << 3, // 8
    MGPreviewPositionOptionMiddle = 1 << 4, // 16
    MGPreviewPositionOptionBottom = 1 << 5, // 32
};

typedef NS_ENUM(NSInteger, MGPreviewPosition) {
    MGPreviewPositionCenter       = MGPreviewPositionOptionMiddle | MGPreviewPositionOptionCenter, // 18
    MGPreviewPositionTopLeft      = MGPreviewPositionOptionTop    | MGPreviewPositionOptionLeft,   // 9
    MGPreviewPositionTopCenter    = MGPreviewPositionOptionTop    | MGPreviewPositionOptionCenter, // 10
    MGPreviewPositionTopRight     = MGPreviewPositionOptionTop    | MGPreviewPositionOptionRight,  // 12
    MGPreviewPositionBottomLeft   = MGPreviewPositionOptionBottom | MGPreviewPositionOptionLeft,   // 33
    MGPreviewPositionBottomCenter = MGPreviewPositionOptionBottom | MGPreviewPositionOptionCenter, // 34
    MGPreviewPositionBottomRight  = MGPreviewPositionOptionBottom | MGPreviewPositionOptionRight,  // 36
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
