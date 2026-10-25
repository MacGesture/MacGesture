//
//  MacGestureTests.m
//  MacGestureTests
//

#import <XCTest/XCTest.h>
#import <Cocoa/Cocoa.h>
#import "../MacGesture/Helpers/utils.h"

@interface MacGestureTests : XCTestCase
@end

@implementation MacGestureTests

- (void)testWildcardMatching
{
    XCTAssertTrue(wildcardString(@"com.google.Chrome", @"*safari|*chrome", YES));
    XCTAssertFalse(wildcardString(@"com.google.Chrome", @"*safari|*chrome", NO));
    XCTAssertFalse(wildcardString(@"com.apple.finder", @"*safari|*chrome", YES));
    XCTAssertFalse(wildcardString(@"com.apple.Safari", @"*\n!com.apple.safari", YES));
    XCTAssertTrue(wildcardString(@"UDR", @"U*R", NO));
}

- (void)testArchiveRoundTrip
{
    NSMutableArray *rules = [@[ [@{ @"direction": @"UR", @"enabled": @YES } mutableCopy] ] mutableCopy];
    NSMutableArray *decoded = MGUnarchive(MGArchive(rules), NSMutableArray.class);
    XCTAssertEqualObjects(decoded, rules);
    XCTAssertNoThrow(decoded.firstObject[@"note"] = @"mutable");

    NSColor *color = [NSColor colorWithSRGBRed:0.1 green:0.2 blue:0.3 alpha:1];
    XCTAssertEqualObjects(MGUnarchive(MGArchive(color), NSColor.class), color);
    XCTAssertNil(MGUnarchive(nil, NSColor.class));
}

@end
