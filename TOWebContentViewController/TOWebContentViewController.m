//
//  TOWebContentViewController.m
//
//  Copyright 2018-2022 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TOWebContentViewController.h"

#import <WebKit/WebKit.h>
#import <SafariServices/SFSafariViewController.h>

NSString * const kTOWebContentTemplateOpenTag = @"{{";
NSString * const kTOWebContentTemplateCloseTag = @"}}";
NSInteger const kTOWebContentMaximumTagLength = 36;

@interface TOWebContentViewController () <WKNavigationDelegate,
                                            UIGestureRecognizerDelegate,
                                            UIViewControllerTransitioningDelegate>

// Views
@property (nonatomic, strong, readwrite) WKWebView *webView;
@property (nonatomic, strong) UIView *loadingBackgroundView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

// Content Information
@property (nonatomic, strong) NSString *htmlString;      // A local HTML string
@property (nonatomic, strong, readwrite) NSURL *URL;     // The original URL shown
@property (nonatomic, strong, readwrite) NSURL *baseURL; // Local files base URL

// Internal state Tracking
@property (nonatomic, assign) BOOL isLoaded;    // The initial URL has been loaded
@property (nonatomic, assign) BOOL isLocalFile; // If the supplied URL was a local file
@property (nonatomic, assign) CGPoint lastTappedPoint;

// Native template properties
@property (nonatomic, strong) NSMutableDictionary *defaultTemplateTags;

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

- (instancetype)initWithHTMLString:(NSString *)htmlString baseURL:(nullable NSURL *)baseURL
{
    if (self = [super init]) {
        _isLocalFile = YES;
        _htmlString = htmlString;
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
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth
                                    | UIViewAutoresizingFlexibleHeight;
    self.webView.navigationDelegate = self;
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.webView];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(tapRecognized:)];
    tapRecognizer.delegate = self;
    [self.webView.scrollView addGestureRecognizer:tapRecognizer];

    // Add the observer for the title if it was set before we were presented
    if (self.setsTitleFromContent) {
        [self.webView addObserver:self forKeyPath:@"title"
                          options:NSKeyValueObservingOptionNew
                          context:nil];
    }

    // Set up the activity indicator
    UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleWhiteLarge;
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
    self.activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
                                                | UIViewAutoresizingFlexibleLeftMargin |
    UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.activityIndicator.center = self.view.center;
    self.activityIndicator.hidesWhenStopped = YES;

    // Set up the background view which will be overlaid on top of the web view
    self.loadingBackgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.loadingBackgroundView.backgroundColor = self.view.backgroundColor;
    self.loadingBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth
                                                    | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.loadingBackgroundView];
    [self.loadingBackgroundView addSubview:self.activityIndicator];
}

- (void)createTemplateDictionary
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy";

    // Load the default template tags
    self.defaultTemplateTags = [NSMutableDictionary dictionary];
    NSDictionary *mainBundleDictionary = NSBundle.mainBundle.infoDictionary;
    self.defaultTemplateTags[@"AppName"] = mainBundleDictionary[(NSString *)kCFBundleNameKey];
    self.defaultTemplateTags[@"AppVersion"] = mainBundleDictionary[@"CFBundleShortVersionString"];
    self.defaultTemplateTags[@"AppBuildNumber"] = mainBundleDictionary[(NSString *)kCFBundleVersionKey];
    self.defaultTemplateTags[@"AppCurrentYear"] = [formatter stringFromDate:[NSDate date]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_isLoaded) { return; }

    // If a local file, load the HTML and pass it to the web view
    if (self.isLocalFile) {
        // Load the HTML from disk, and then pass it to the web view
        @autoreleasepool {
            NSString *fileData = self.htmlString;
            if (self.URL) {
                fileData = [NSString stringWithContentsOfURL:self.URL
                                                    encoding:NSUTF8StringEncoding error:nil];
            }

            [self setBackgroundColorForHTMLString:fileData];
            [self injectTagTemplateValuesIntoHTMLString:fileData
                                             completion:^(NSString *htmlData) {
                [self.webView loadHTMLString:htmlData baseURL:self.baseURL];
            }];
        }

        // Hide the web view and start showing a loading indicator
        self.loadingBackgroundView.alpha = 1.0f;
    }
    else {
        // Depending on the background color, set the activity indicator color
        [self updateActivityIndicatorForBackgroundColor];

        // Load from the website
        NSURLRequest *request = [NSURLRequest requestWithURL:self.URL];
        [self.webView loadRequest:request];

        // Hide the web view so it will fade in
        self.loadingBackgroundView.alpha = 1.0f;

        // Show the spinning icon
        [self.activityIndicator startAnimating];
    }

    // Ensure the content isn't loaded again if this is triggered by returning from another view controller
    _isLoaded = YES;
}

#pragma mark - Content Management -

- (NSString *)HTMLStringWithTemplateTagsForHTMLString:(NSString *)htmlString
{
    // Create a dictionary of default template values
    [self createTemplateDictionary];

    // Merge the default templates with the user specified ones
    NSMutableDictionary *templateTags = self.defaultTemplateTags.mutableCopy;
    if (self.templateTags) { [templateTags addEntriesFromDictionary:self.templateTags]; }

    NSRange searchRange = NSMakeRange(0, 0);
    NSString *string = htmlString;

    while (YES) {
        // Sanity check the range of the search because it will trigger an exception out of bounds
        searchRange.length = string.length - searchRange.location;

        //Search for '{{'
        NSRange tagRange = [string rangeOfString:kTOWebContentTemplateOpenTag
                                         options:NSLiteralSearch
                                           range:searchRange];
        if (tagRange.location == NSNotFound) { break; } // If not found, break out of the loop

        NSInteger startIndex = tagRange.location;

        // Search for the ending '}}'
        tagRange.length = MIN(kTOWebContentMaximumTagLength, string.length - tagRange.location);
        tagRange = [string rangeOfString:kTOWebContentTemplateCloseTag
                                 options:NSLiteralSearch range:tagRange];
        if (tagRange.location == NSNotFound) {
            @throw [NSException exceptionWithName:@"InconsistencyException"
                                           reason:@"Closing }} tag not found. Tags must be <= 32 characters"
                                         userInfo:nil];
        }

        // Extract the key name
        NSRange tagNameRange = NSMakeRange(startIndex+2, tagRange.location - (startIndex+2));
        NSString *tagName = [string substringWithRange:tagNameRange];

        // See if it's a tag we support
        NSString *tagValue = templateTags[tagName];
        if (tagValue == nil) {
            searchRange.location = tagRange.location + 2;
            continue;
        }

        // If it is, perform a replacement
        NSRange replaceRange = NSMakeRange(startIndex, (tagRange.location + 2) - startIndex);
        string = [string stringByReplacingCharactersInRange:replaceRange withString:tagValue];

        // Increment the search range for next iteration
        searchRange.location = replaceRange.location + tagValue.length;
    }

    return string;
}

- (void)injectTagTemplateValuesIntoHTMLString:(NSString *)html completion:(void (^)(NSString *))completion
{
    id block = ^{
        NSString *htmlString = nil;
        @autoreleasepool {
            htmlString = [self HTMLStringWithTemplateTagsForHTMLString:html];
        }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(htmlString); });
        htmlString = nil;
    };

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), block);
}

#pragma mark - View Management -

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    if (object != self.webView) { return; }

    // Update view controller title if we received a change alert
    if ([keyPath isEqualToString:@"title"]) {
        self.title = self.webView.title;
    }
}

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
    NSString *hexString = [NSString stringWithCString:(const char *)hexArray
                                             encoding:NSUTF8StringEncoding];
    UIColor *color = [self colorForHexString:hexString];
    if (!color) { return; }

    // Update the views with the new color
    self.view.backgroundColor = color;
    self.loadingBackgroundView.backgroundColor = color;

    // Refresh the loading indicator
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
    if (self.loadingBackgroundView.alpha < FLT_EPSILON) { return; }

    // Once the page has sufficiently loaded, fade in the web view
    [UIView animateWithDuration:0.4f
                          delay:0.0f
                        options:0
                     animations:^{
        self.loadingBackgroundView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.activityIndicator stopAnimating];
    }];
}

#pragma mark - Navigation Delegate -
- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
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
    // When loading local files, wait until the whole file has loaded before displaying
    if (!self.isLocalFile) { return; }
    [self transitionToWebView];
}

#pragma mark - URL Handling -
- (void)performActionForNavigationAction:(WKNavigationAction *)navigationAction
{
    NSURL *URL = navigationAction.request.URL;
    if (URL == nil) { return; }

    // If the delegate was set, see if it wants to handle this particular URL
    if (self.delegate && [self.delegate respondsToSelector:@selector(webContentViewController:performActionForURL:tappedAtPoint:)]) {
        if ([self.delegate webContentViewController:self performActionForURL:URL tappedAtPoint:self.lastTappedPoint]) {
            return;
        }
    }

    // Depend on the scheme, perform a variety of default actions
    NSString *scheme = URL.scheme.lowercaseString;

    // Show an SFSafariViewController for web pages
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        [self presentWebSiteSheetWithURL:URL];
    }
    else if ([scheme isEqualToString:@"twitter"]) {
        NSDictionary *twitterSchemes = @{ @"Tweetbot": @"tweetbot:///user_profile/%@",
                                          @"Twitter": @"twitter://user?screen_name=%@" };
        [self presentSocialMediaAccountSheetWithHost:@"twitter.com"
                                          userHandle:URL.host
                                          appSchemes:twitterSchemes];
    }
    else if ([scheme isEqualToString:@"facebook"]) {
        NSDictionary *facebookScheme = @{ @"Facebook": @"fb://profile/%@" };
        [self presentSocialMediaAccountSheetWithHost:@"facebook.com"
                                          userHandle:URL.host
                                          appSchemes:facebookScheme];
    }
    else if ([scheme isEqualToString:@"instagram"]) {
        NSDictionary *instagramScheme = @{ @"Instagram": @"instagram://user?username=%@" };
        [self presentSocialMediaAccountSheetWithHost:@"instagram.com"
                                          userHandle:URL.host
                                          appSchemes:instagramScheme];
    }
}

- (void)presentWebViewControllerForURL:(NSURL *)URL
{
    SFSafariViewController *safariController = [[SFSafariViewController alloc] initWithURL:URL];
    safariController.transitioningDelegate = self; // Don't push like a navigation controller
    [self presentViewController:safariController animated:YES completion:nil];
}

- (void)presentWebSiteSheetWithURL:(NSURL *)URL
{
    NSArray *actions = [self alertActionsForWebPageWithURL:URL];
    [self presentActionViewControllerWithTitle:URL.absoluteString actions:actions];
}

- (void)presentSocialMediaAccountSheetWithHost:(NSString *)host
                                    userHandle:(NSString *)handle
                                    appSchemes:(NSDictionary<NSString *, NSString *> *)schemes
{
    NSBundle *resourceBundle = self.resourceBundle;
    NSString *URLString = [NSString stringWithFormat:@"https://%@/%@", host, handle];

    NSMutableArray *actions = [NSMutableArray array];

    // For each scheme, generate a title "Open In Scheme" and then set the URL to open that app
    for (NSString *appName in schemes) {
        // Generate the app specific URL link
        NSString *actionURLString = [NSString stringWithFormat:schemes[appName], handle];
        NSURL *actionURL = [NSURL URLWithString:actionURLString];

        // Make sure we can open that URL
        if ([UIApplication.sharedApplication canOpenURL:actionURL] == NO) { continue; }

        // Generate the 'Open In' string
        NSString *openInTemplate = NSLocalizedStringFromTableInBundle(@"TOWebContentViewController.Share.OpenIn",
                                                                      @"TOWebContentViewControllerLocalizable",
                                                                      resourceBundle, @"");
        NSString *openInTitle = [NSString stringWithFormat:openInTemplate, appName];

        // Configure the action with both
        UIAlertAction *appLinkAction = [UIAlertAction actionWithTitle:openInTitle
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
            NSURL *URL = [NSURL URLWithString:actionURLString];
            if (@available(iOS 10.0, *)) {
                [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
            }
            else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [UIApplication.sharedApplication openURL:URL];
#pragma clang diagnostic pop
            }
        }];
        [actions addObject:appLinkAction];
    }

    // Add the "Open Web Page" and "Copy Link" actions
    [actions addObjectsFromArray:[self alertActionsForWebPageWithURL:[NSURL URLWithString:URLString]]];

    // Present the action sheet
    [self presentActionViewControllerWithTitle:URLString actions:actions];
}

- (NSArray *)alertActionsForWebPageWithURL:(NSURL *)URL
{
    NSBundle *resourceBundle = self.resourceBundle;
    NSMutableArray *actions = [NSMutableArray array];

    // Show the 'Open in Web' button
    NSString *showPageTitle = NSLocalizedStringFromTableInBundle(@"TOWebContentViewController.Share.ShowWebPage",
                                                                 @"TOWebContentViewControllerLocalizable",
                                                                 resourceBundle, @"");
    UIAlertAction *openLinkAction = [UIAlertAction actionWithTitle:showPageTitle
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
        [self presentWebViewControllerForURL:URL];
    }];
    [actions addObject:openLinkAction];

    // Show the copy link action
    NSString *copyLinkTitle = NSLocalizedStringFromTableInBundle(@"TOWebContentViewController.Share.CopyLink",
                                                                 @"TOWebContentViewControllerLocalizable",
                                                                 resourceBundle, @"");
    UIAlertAction *copyLinkAction = [UIAlertAction actionWithTitle:copyLinkTitle
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
        UIPasteboard.generalPasteboard.string = URL.absoluteString;
    }];
    [actions addObject:copyLinkAction];

    return actions;
}

- (void)presentActionViewControllerWithTitle:(NSString *)title actions:(NSArray<UIAlertAction *> *)actions
{
    NSBundle *resourceBundle = self.resourceBundle;

    CGPoint tapPoint = self.lastTappedPoint;
    CGRect tapRect = (CGRect){tapPoint, {1,1}};

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    alertController.modalPresentationStyle = UIModalPresentationPopover;

    // Add each action to the sheet
    for (UIAlertAction *action in actions) {
        [alertController addAction:action];
    }

    // Add a cancel button for all cases
    title = NSLocalizedStringFromTableInBundle(@"TOWebContentViewController.Share.Cancel",
                                               @"TOWebContentViewControllerLocalizable",
                                               resourceBundle, @"");
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

#pragma mark - Gesture Recognizer -
- (void)tapRecognized:(UIGestureRecognizer *)recognizer
{
    self.lastTappedPoint = [recognizer locationInView:self.view];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
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
        self.loadingBackgroundView.backgroundColor = _defaultBackgroundColor;
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

