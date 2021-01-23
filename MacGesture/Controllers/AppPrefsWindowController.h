//
//  AppPrefsWindowController.h
//

#import <Cocoa/Cocoa.h>
#import <Webkit/Webkit.h>
#import "DBPrefsWindowController.h"
#import "SRRecorderControl.h"
#import "AppPickerWindowController.h"
#import <Sparkle/Sparkle.h>

@interface AppPrefsWindowController : DBPrefsWindowController <NSTableViewDelegate, NSTableViewDataSource, SRRecorderControlDelegate, NSTextFieldDelegate, AppPickerCallback, NSComboBoxDataSource, NSWindowDelegate>

@property(strong, nonatomic) IBOutlet NSView *generalPreferenceView;
@property(strong, nonatomic) IBOutlet NSView *rulesPreferenceView;
@property(strong, nonatomic) IBOutlet NSView *appleScriptPreferenceView;
@property(strong, nonatomic) IBOutlet NSView *aboutPreferenceView;
@property(strong, nonatomic) IBOutlet NSView *filtersPrefrenceView;

@property(weak) IBOutlet NSTableView *rulesTableView;

@property(weak) IBOutlet NSTextField *blockFilter;
@property(strong) IBOutlet SUUpdater *updater;

@property(weak) IBOutlet NSButton *autoStartAtLogin;

@property(weak) IBOutlet NSTextField *versionCode;
@property(weak) IBOutlet NSButton *blockListModeRadio;
@property(weak) IBOutlet NSButton *allowListModeRadio;
@property(unsafe_unretained) IBOutlet NSTextView *blockListTextView;
@property(unsafe_unretained) IBOutlet NSTextView *allowListTextView;
@property(weak) IBOutlet NSButton *changeRulesWindowSizeButton;
@property(weak) IBOutlet NSButton *changeFiltersWindowSizeButton;
@property(weak) IBOutlet NSButton *editInExternalEditorButton;
@property(weak) IBOutlet NSPopUpButton *loadAppleScriptExampleButton;
@property(weak) IBOutlet NSButton *addAppleScriptButton;
@property(weak) IBOutlet NSButton *removeAppleScriptButton;
@property(weak) IBOutlet NSTextField *fontNameTextField;
@property(weak) IBOutlet NSTextField *fontSizeTextField;
@property(weak) IBOutlet NSTextField *gestureSizeTextField;
@property(weak) IBOutlet NSSlider *gestureSizeSlider;
@property(weak) IBOutlet NSTableView *appleScriptTableView;
@property(weak) IBOutlet NSTextField *appleScriptTextField;
@property(weak) IBOutlet NSButton *showIconInStatusBarButton;
@property(weak) IBOutlet NSComboBox *languageComboBox;

@property(weak) IBOutlet NSColorWell *lineColorWell;

@property(assign) IBOutlet WKWebView *webView;

- (void)rulePickCallback:(NSString *)rulesStringSplitedByStick atIndex:(NSInteger)index;
@end
