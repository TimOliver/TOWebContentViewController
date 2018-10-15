//
//  TOWebContentViewController.m
//  TOWebContentViewControllerExample
//
//  Created by Tim Oliver on 14/10/18.
//  Copyright © 2018 Tim Oliver. All rights reserved.
//

#import "TOWebContentViewController.h"

@interface TOWebContentViewController () <WKNavigationDelegate>

// Views
@property (nonatomic, strong, readwrite) WKWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

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

    // If set, copy the default background color to the view background
    self.view.backgroundColor = self.defaultBackgroundColor ?: [UIColor whiteColor];

    // Set up the webview
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];

    // Add the observer for the title if it was set before we were presented
    if (self.setsTitleFromContent) {
        [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    }

    // Set up the activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.activityIndicator.center = self.view.center;
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view insertSubview:self.activityIndicator atIndex:0];

    // Depending on the background color, set the activity indicator color
    [self updateActivityIndicatorForBackgroundColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_isLoaded) { return; }

    // If a local file, load the HTML and pass it to the web view
    if (self.isLocalFile) {
        NSString *fileData = [NSString stringWithContentsOfURL:self.URL encoding:NSUTF8StringEncoding error:nil];
        [self.webView loadHTMLString:fileData baseURL:self.baseURL];

        // Hide the web view and start showing a loading indicator
        self.webView.alpha = 0.0f;
        [self.activityIndicator startAnimating];
    }

    // Ensure the content isn't loaded again if this is triggered by returning from another view controller
    _isLoaded = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (object != self.webView) { return; }
    self.title = self.webView.title;
}

#pragma mark - View Management -

- (void)updateActivityIndicatorForBackgroundColor
{
    UIColor *backgroundColor = self.view.backgroundColor;

    // Work out the brightness of the background color
    // https://stackoverflow.com/questions/2509443/check-if-uicolor-is-dark-or-bright
    CGFloat colorBrightness = 0.0f;

    CGColorSpaceRef colorSpace = CGColorGetColorSpace(backgroundColor.CGColor);
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(colorSpace);
    if(colorSpaceModel == kCGColorSpaceModelRGB){
        const CGFloat *componentColors = CGColorGetComponents(backgroundColor.CGColor);
        colorBrightness = (componentColors[0] * 299);
        colorBrightness += (componentColors[1] * 587);
        colorBrightness += (componentColors[2] * 114);
        colorBrightness /= 1000.0f;
    }
    else {
        [backgroundColor getWhite:&colorBrightness alpha:NULL];
    }

    self.activityIndicator.color = (colorBrightness < 0.5f) ? nil : [UIColor grayColor];
}

#pragma mark - Navigation Delegate -
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == WKNavigationTypeOther) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    // Once the page starts loading, fade in the web view
    if (self.webView.alpha < FLT_EPSILON) {
        [UIView animateWithDuration:0.4f animations:^{
            self.webView.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [self.activityIndicator stopAnimating];
        }];
    }
}

#pragma mark - Accessors -
- (void)setDefaultBackgroundColor:(UIColor *)defaultBackgroundColor
{
    if (defaultBackgroundColor == _defaultBackgroundColor) { return; }
    _defaultBackgroundColor = defaultBackgroundColor;

    if (self.viewLoaded) {
        self.view.backgroundColor = _defaultBackgroundColor;
        [self updateActivityIndicatorForBackgroundColor];
    }
}

- (void)setSetsAllowTitleFromContent:(BOOL)setsTitleFromContent
{
    if (setsTitleFromContent == _setsTitleFromContent) { return; }

    // If it was already enabled, remove it before we change the value
    if (_setsTitleFromContent && self.webView) {
        [self.webView removeObserver:self forKeyPath:@"title"];
    }

    _setsTitleFromContent = setsTitleFromContent;

    // If the new value is to add it, do so
    if (_setsTitleFromContent && self.webView) {
        [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    }
}

@end

