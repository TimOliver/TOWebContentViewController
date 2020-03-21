//
//  TOWebContentViewControllerExampleTests.m
//  TOWebContentViewControllerExampleTests
//
//  Created by Tim Oliver on 3/11/18.
//  Copyright © 2018 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TOWebContentViewController.h"

@interface TOWebContentViewController ()
- (NSString *)HTMLStringWithTemplateTagsForHTMLString:(NSString *)htmlString;
@end

@interface TOWebContentViewControllerTests : XCTestCase

@end

@implementation TOWebContentViewControllerTests

- (void)testViewControllerCreation
{
    NSString *testHTML = @"<html></html>";
    TOWebContentViewController *vc = [[TOWebContentViewController alloc] initWithHTMLString:testHTML baseURL:nil];
    UIView *view = vc.view;
    XCTAssertNotNil(view);
}

- (void)testBackgroundColorDetection
{
    NSString *testHTML = @"<html><body data-bgcolor=\"#000000\"></body</html>";
    TOWebContentViewController *vc = [[TOWebContentViewController alloc] initWithHTMLString:testHTML baseURL:nil];
    [vc viewWillAppear:YES];
    UIColor *backgroundColor = vc.view.backgroundColor;

    CGFloat whiteValue = 1.0f;
    [backgroundColor getWhite:&whiteValue alpha:NULL];

    XCTAssert(whiteValue < FLT_EPSILON);
}

- (void)testTagDetection
{
    NSString *testHTML = @"<html><body>{{Greeting}}{{Greeting}}</body</html>";
    NSString *expectedHTML = @"<html><body>Hello World!Hello World!</body</html>";
    TOWebContentViewController *vc = [[TOWebContentViewController alloc] initWithHTMLString:testHTML baseURL:nil];
    vc.templateTags = @{@"Greeting" : @"Hello World!"};
    NSString *html = [vc HTMLStringWithTemplateTagsForHTMLString:testHTML];
    XCTAssertTrue([expectedHTML isEqualToString:html]);
}

@end
