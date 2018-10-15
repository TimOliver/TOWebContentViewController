//
//  TOWebContentViewController.m
//  TOWebContentViewControllerExample
//
//  Created by Tim Oliver on 14/10/18.
//  Copyright © 2018 Tim Oliver. All rights reserved.
//

#import "TOWebContentViewController.h"
#import <SafariServices/SFSafariViewController.h>

@interface TOWebContentViewController () <WKNavigationDelegate,
                                            UIGestureRecognizerDelegate,
                                            UIViewControllerTransitioningDelegate>

// Views
@property (nonatomic, strong, readwrite) WKWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

// Content Information
@property (nonatomic, strong, readwrite) NSURL *URL;     // The original URL shown
@property (nonatomic, strong, readwrite) NSURL *baseURL; // Local files base URL

// Internal state Tracking
@property (nonatomic, assign) BOOL isLoaded;    // The initial URL has been loaded
@property (nonatomic, assign) BOOL isLocalFile; // If the supplied URL was a local file
@property (nonatomic, assign) CGPoint lastTappedPoint;

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

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized:)];
    tapRecognizer.delegate = self;
    [self.webView.scrollView addGestureRecognizer:tapRecognizer];

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

    // If the brightness is less than half, keep the indicator white, else make it gray
    self.activityIndicator.color = (colorBrightness < 0.5f) ? nil : [UIColor grayColor];
}

#pragma mark - Navigation Delegate -
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == WKNavigationTypeOther) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }

    // Perform any possible actions on the navigation action
    [self performActionForNavigationAction:navigationAction];

    // Always deny the web view progressing away from its initial page
    // (Other web links should be presented in a proper web view controller)
    decisionHandler(WKNavigationActionPolicyCancel);
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

#pragma mark - URL Handling -
- (void)performActionForNavigationAction:(WKNavigationAction *)navigationAction
{
    NSURL *URL = navigationAction.request.URL;
    if (URL == nil) { return; }

    // Depend on the scheme, perform a variety of default actions
    NSString *scheme = URL.scheme.lowercaseString;

    // Show an SFSafariViewController for web pages
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        [self presentWebViewControllerForURL:URL navigationAction:navigationAction];
    }
    else if ([scheme isEqualToString:@"twitter"]) {
        [self presentSocialMediaAccountWithHost:@"twitter.com" userHandle:URL.host];
    }
    else if ([scheme isEqualToString:@"facebook"]) {
        [self presentSocialMediaAccountWithHost:@"facebook.com" userHandle:URL.host];
    }
    else if ([scheme isEqualToString:@"instagram"]) {
        [self presentSocialMediaAccountWithHost:@"instagram.com" userHandle:URL.host];
    }
}

- (void)presentWebViewControllerForURL:(NSURL *)URL navigationAction:(WKNavigationAction *)navigationAction
{
    CGPoint tapPoint = self.lastTappedPoint;
    CGRect tapRect = (CGRect){tapPoint, {1,1}};

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:URL.absoluteString message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alertController.modalPresentationStyle = UIModalPresentationPopover;

    // Action for displaying the address in a safari view controller
    id showActionHandler = ^(UIAlertAction *action) {
        SFSafariViewController *safariController = [[SFSafariViewController alloc] initWithURL:URL];
        safariController.transitioningDelegate = self; // Don't push like a navigation controller
        [self presentViewController:safariController animated:YES completion:nil];
    };
    UIAlertAction *showAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"TOWebContentViewController.Share.OpenIn", @"")
                                                         style:UIAlertActionStyleDefault
                                                       handler:showActionHandler];
    [alertController addAction:showAction];

    // Action for copying the URL
    id copyLinkHandler = ^(UIAlertAction *action) {

    };
    UIAlertAction *copyLinkAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"TOWebContentViewController.Share.CopyLink", @"")
                                                             style:UIAlertActionStyleDefault
                                                           handler:copyLinkHandler];
    [alertController addAction:copyLinkAction];




    UIPopoverPresentationController *popoverController = alertController.popoverPresentationController;
    popoverController.sourceRect = tapRect;
    popoverController.sourceView = self.view;
    popoverController.permittedArrowDirections = UIPopoverArrowDirectionDown;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)presentSocialMediaAccountWithHost:(NSString *)host userHandle:(NSString *)handle
{
//    NSString *URLString = [NSString stringWithFormat:@"https://%@/%@", host, handle];
//    [self presentWebViewControllerForURL:[NSURL URLWithString:URLString]];
}

#pragma mark - Gesture Recognizer -
- (void)tapRecognized:(UIGestureRecognizer *)recognizer
{
    self.lastTappedPoint = [recognizer locationInView:self.view];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
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

