//
//  TOWebContentViewController.h
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

#import <UIKit/UIKit.h>

@class WKWebView;
@class TOWebContentViewController;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(WebContentViewControllerDelegate)
@protocol TOWebContentViewControllerDelegate <NSObject>

@optional
/**
 Whenever a link is tapped in the web content view controller, this gives the
 delegate an opportunity to intercept that link and perform any desired
 custom logic in response. For example, a link URL such as "myapp://"
 could be used to trigger a transition to a different view controller.

 @param webContentViewController The web content view controller that triggered the delegate
 @param URL The complete URL of the link that was tapped
 @param tapPoint If needed the coordinates of where the link was tapped in the view controller space.
 @return Return NO if the view controller should perform its default behaviour, or YES if the app handled the URL.
 */
- (BOOL)webContentViewController:(TOWebContentViewController *)webContentViewController
             performActionForURL:(NSURL *)URL
                   tappedAtPoint:(CGPoint)tapPoint;

@end

/**
 `TOWebContentViewController` is a view controller for displaying arbitrary
 web content, either from a local or online source in instances where spending
 the time to implement an equivalent native UI wouldn't be worth it (ie open source
 license acknowledgements, privacy policies)

 ---

 For local content, `TOWebContentController` also implements a very bare-bones version
 of the mustache templating system (https://mustache.github.io/) to allow basic injection
 of dynamic information before the content is displayed.

 While more values can be added manually, the following tags are natively provided:

 {{AppName}} - The short name of this app
 {{AppVersion}} - The version string of this app
 {{AppBuildNumber}} - The build number of this app.
 {{AppCurrentYear}} - The current year

*/

NS_SWIFT_NAME(WebContentViewController)
@interface TOWebContentViewController : UIViewController

/** A delegate object that can respond to user-triggered actions in the web content view controller */
@property (nonatomic, weak, nullable) id<TOWebContentViewControllerDelegate> delegate;

/** The WKWebView used to display the HTML content*/
@property (nonatomic, strong, readonly) WKWebView *webView;

/** The URL of the content currently being displayed. Can be a file URL, or an online one. */
@property (nonatomic, strong, readonly) NSURL *URL;

/** For local URLs, this is the folder that is used for relative file path references in the HTML code. */
@property (nonatomic, strong, readonly) NSURL *baseURL;

/** Before any web content is displayed, this is the default background color of the view controller */
@property (nonatomic, strong, nullable) UIColor *defaultBackgroundColor;

/** Once the web content is loaded, the view controller's title is set to be the same as the <title> tag. (Default is NO) */
@property (nonatomic, assign) BOOL setsTitleFromContent;

/** For local content, additional template tags that can be injected at load time.
 For example, setting {"AppTheme" : "Dark"} -> {{AppTheme}}
 */
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *templateTags;

/**
 Initializes and returns a new view controller object, configured to display
 content from a local HTML file.

 @param fileURL The local file path to the HTML file to display.
 @param baseURL The file path to the directory that will be used for all relative file references.
 @return A new instance of `TOWebContentViewController`.
 */
- (instancetype)initWithFileURL:(NSURL *)fileURL baseURL:(NSURL *)baseURL;


/**
 Initializes and returns a new view controller object, configured to display
 content from a pre-loaded HTML string.

 @param htmlString The HTML string to display
 @param baseURL If needed, a base URL to use for relative file paths.
 @return A new instance of `TOWebContentViewController`.
 */
- (instancetype)initWithHTMLString:(NSString *)htmlString baseURL:(nullable NSURL *)baseURL;

/**
 Initializes and returns a new view controller object, configured to display
 HTML content from an online URL.

 @param URL The URL of the remote web content to display.
 @return A new instance of `TOWebContentViewController`.
 */
- (instancetype)initWithURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
