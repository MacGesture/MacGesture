//
//  AppPrefsWindowController.h
//

#import <Cocoa/Cocoa.h>
#import "DBPrefsWindowController.h"
#import "SRRecorderControl.h"
#import "AppPickerWindowController.h"
#import <Sparkle/Sparkle.h>

@class LaunchAtLoginController;

@interface AppPrefsWindowController : DBPrefsWindowController <NSTableViewDelegate, NSTableViewDataSource, SRRecorderControlDelegate, NSTextFieldDelegate, AppPickerCallback>

@property(strong, nonatomic) IBOutlet NSView *generalPreferenceView;
@property(strong, nonatomic) IBOutlet NSView *rulesPreferenceView;
@property(strong, nonatomic) IBOutlet NSView *playbackPreferenceView;
@property(strong, nonatomic) IBOutlet NSView *updatesPreferenceView;
@property(strong, nonatomic) IBOutlet NSView *aboutPreferenceView;

@property(weak) IBOutlet NSTableView *rulesTableView;

@property(weak) IBOutlet NSButton *openPreOnStartup;
@property(weak) IBOutlet NSTextField *blockFilter;

@property(weak) IBOutlet NSButton *disableMousePathBtn;

@property(weak) IBOutlet NSButton *showGestureNote;
@property(weak) IBOutlet NSButton *showGesturePreview;
@property(weak) IBOutlet NSButton *autoCheckUpdate;
@property(weak) IBOutlet NSButton *autoDownUpdate;
@property(strong) IBOutlet SUUpdater *updater;

@property(weak) IBOutlet NSButton *autoStartAtLogin;

@property(weak) IBOutlet NSTextField *versionCode;
@property(weak) IBOutlet NSButton *blackListModeRadio;
@property(weak) IBOutlet NSButton *whiteListModeRadio;
@property(unsafe_unretained) IBOutlet NSTextView *blackListTextView;
@property(unsafe_unretained) IBOutlet NSTextView *whiteListTextView;
@property(strong) IBOutlet NSView *filtersPrefrenceView;
@property(weak) IBOutlet NSButton *changeRulesWindowSizeButton;
@property(weak) IBOutlet NSButton *changeFiltersWindowSizeButton;

@property(weak) IBOutlet NSColorWell *lineColorWell;

- (void)rulePickCallback:(NSString *)rulesStringSplitedByStick atIndex:(NSInteger)index;
@end
