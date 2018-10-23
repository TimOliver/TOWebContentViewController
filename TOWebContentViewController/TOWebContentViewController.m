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

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.suppressesIncrementalRendering = YES;

    // Set up the webview
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.navigationDelegate = self;
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_isLoaded) { return; }

    // If a local file, load the HTML and pass it to the web view
    if (self.isLocalFile) {

        // Load the HTML from disk, and then pass it to the web view
        @autoreleasepool {
            NSString *fileData = [NSString stringWithContentsOfURL:self.URL encoding:NSUTF8StringEncoding error:nil];
            [self setBackgroundColorForHTMLString:fileData];
            [self.webView loadHTMLString:fileData baseURL:self.baseURL];
        }

        // Hide the web view and start showing a loading indicator
        self.webView.alpha = 0.0f;
    }
    else {
        // Depending on the background color, set the activity indicator color
        [self updateActivityIndicatorForBackgroundColor];
    }

    // Ensure the content isn't loaded again if this is triggered by returning from another view controller
    _isLoaded = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (object != self.webView) { return; }

    // Update view controller title if we received a change alert
    if ([keyPath isEqualToString:@"title"]) {
        self.title = self.webView.title;
    }
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

- (void)setBackgroundColorForHTMLString:(NSString *)html
{
    // Don't set the color if the controller has a color explicitly set
    if (self.defaultBackgroundColor) { return; }

    // Try and locate the attribute in the HTML string
    NSString *colorAttribute = @"data-bgcolor";
    NSRange startRange = [html rangeOfString:colorAttribute options:NSCaseInsensitiveSearch];
    if (startRange.location == NSNotFound) { return; }

    // Assuming the format is data-bgcolor="#ffffff", extract the hex data
    startRange.location += startRange.length + 3; // skip the `="#` portion
    char hexArray[6];
    memset(hexArray, 0, 6);

    for (NSInteger i = 0; i < 6; i++) {
        char character = [html characterAtIndex:i+startRange.location];
        if (character == '"') { break; }
        hexArray[i] = character;
    }

    // Convert the string to a UIColor
    NSString *hexString = [NSString stringWithCString:(const char *)hexArray encoding:NSUTF8StringEncoding];
    UIColor *color = [self colorForHexString:hexString];
    if (!color) { return; }

    // Update the view with the new color
    self.view.backgroundColor = color;
    [self updateActivityIndicatorForBackgroundColor];
}

- (UIColor *)colorForHexString:(NSString *)hexString
{
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0
                           green:((rgbValue & 0xFF00) >> 8)/255.0
                            blue:(rgbValue & 0xFF)/255.0
                           alpha:1.0];
}

- (void)transitionToWebView
{
    if (self.webView.alpha > FLT_EPSILON) { return; }

    // Once the page has sufficiently loaded, fade in the web view
    if (self.webView.alpha < FLT_EPSILON) {
        [UIView animateWithDuration:0.4f
                              delay:0.0f
                            options:0
                         animations:^{
            self.webView.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [self.activityIndicator stopAnimating];
        }];
    }
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
    // When loading remote sites, start showing the web view once the server has responded
    if (self.isLocalFile) { return; }
    [self transitionToWebView];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    // When loading local files, wait until the who file has loaded before displaying
    if (!self.isLocalFile) { return; }
    [self transitionToWebView];
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
    NSBundle *resourceBundle = self.resourceBundle;

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

    NSString *title = NSLocalizedStringFromTableInBundle(@"TOWebContentViewController.Share.OpenIn", @"TOWebContentViewControllerLocalizable", resourceBundle, @"");
    UIAlertAction *showAction = [UIAlertAction actionWithTitle:title
                                                         style:UIAlertActionStyleDefault
                                                       handler:showActionHandler];
    [alertController addAction:showAction];

    // Action for copying the URL
    id copyLinkHandler = ^(UIAlertAction *action) {

    };
    title = NSLocalizedStringFromTableInBundle(@"TOWebContentViewController.Share.CopyLink", @"TOWebContentViewControllerLocalizable", resourceBundle, @"");
    UIAlertAction *copyLinkAction = [UIAlertAction actionWithTitle:title
                                                             style:UIAlertActionStyleDefault
                                                           handler:copyLinkHandler];
    [alertController addAction:copyLinkAction];

    title = NSLocalizedStringFromTableInBundle(@"TOWebContentViewController.Share.Cancel", @"TOWebContentViewControllerLocalizable", resourceBundle, @"");
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:title
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alertController addAction:cancelAction];

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

- (NSBundle *)resourceBundle
{
    NSBundle *resourceBundle = nil;

    NSBundle *classBundle = [NSBundle bundleForClass:self.class];
    NSURL *resourceBundleURL = [classBundle URLForResource:@"TOWebContentViewControllerBundle" withExtension:@"bundle"];
    if (resourceBundleURL) {
        resourceBundle = [[NSBundle alloc] initWithURL:resourceBundleURL];
    }
    else {
        resourceBundle = classBundle;
    }

    return resourceBundle;
}

@end

