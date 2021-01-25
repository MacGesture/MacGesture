
#import <Foundation/Foundation.h>

#define OPTIONS_LINE_COLOR_ID @"lineColor"
#define OPTIONS_PREVIEW_COLOR_ID @"previewColor"
#define OPTIONS_PREVIEW_BG_COLOR_ID @"previewBgColor"
#define OPTIONS_NOTE_COLOR_ID @"noteColor"
#define OPTIONS_NOTE_BG_COLOR_ID @"noteBgColor"

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

+ (void)resetColors;

@end

NS_ASSUME_NONNULL_END
