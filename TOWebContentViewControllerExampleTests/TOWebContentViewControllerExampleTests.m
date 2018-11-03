//
//  TOWebContentViewControllerExampleTests.m
//  TOWebContentViewControllerExampleTests
//
//  Created by Tim Oliver on 3/11/18.
//  Copyright © 2018 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TOWebContentViewController.h"

@interface TOWebContentViewControllerExampleTests : XCTestCase

@end

@implementation TOWebContentViewControllerExampleTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testViewControllerCreation
{
    NSString *testHTML = @"<html></html>";
    TOWebContentViewController *vc = [[TOWebContentViewController alloc] initWithHTMLString:testHTML baseURL:nil];
    UIView *view = vc.view;
    XCTAssertNotNil(view);
}

@end
