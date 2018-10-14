//
//  TOWebContentViewController.m
//  TOWebContentViewControllerExample
//
//  Created by Tim Oliver on 14/10/18.
//  Copyright © 2018 Tim Oliver. All rights reserved.
//

#import "TOWebContentViewController.h"
#import "TOWebContentView.h"

@interface TOWebContentViewController () <WKNavigationDelegate>

// Views
@property (nonatomic, strong, readwrite) TOWebContentView *webView;

// Content Information
@property (nonatomic, strong, readwrite) NSURL *URL;
@property (nonatomic, strong, readwrite) NSURL *baseURL;

// State
@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL isLocalFile;

@end

@implementation TOWebContentViewController

#pragma mark - Class Lifecycle -

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        _URL = URL;
    }

    return self;
}

- (instancetype)initWithFileURL:(NSURL *)fileURL baseURL:(NSURL *)baseURL
{
    if (self = [super init]) {
        _isLocalFile = YES;
        _URL = fileURL;
        _baseURL = baseURL;
    }

    return self;
}

#pragma mark - View Creation -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[TOWebContentView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_isLoaded) { return; }

    if (self.isLocalFile) {
        NSString *fileData = [NSString stringWithContentsOfURL:self.URL encoding:NSUTF8StringEncoding error:nil];
        [self.webView loadHTMLString:fileData baseURL:self.baseURL];
    }
}

#pragma mark - Navigation Delegate -
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == WKNavigationTypeOther) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }


}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"Done!");
}

@end

